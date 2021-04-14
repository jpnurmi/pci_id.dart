import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:pci_id/src/pci_types.dart';

const String kDefaultOutputFileName = 'pci_id.g.dart';

const String kOutputTemplate = '''
part of 'pci_id.dart';

{{variables}}

{{vendors}}

{{devices}}
''';

void main(List<String> args) {
  final parser = ArgParser();
  parser.addOption(
    'output',
    abbr: 'o',
    defaultsTo: kDefaultOutputFileName,
    help: 'The output file or directory',
  );

  final options = parser.parse(args);
  if (options.rest.length != 1) {
    printUsage(parser.usage);
    exit(-1);
  }

  final inputFile = File(options.rest.first);
  if (!inputFile.existsSync()) {
    printError('Cannot find ${inputFile.path}');
    printUsage(parser.usage);
    exit(-1);
  }

  final outputFile = File(resolveOutputFile(options['output']));

  final lines = filterLines(inputFile.readAsLinesSync());
  final items = parseLines(lines);

  final output = generateDart(items);
  outputFile.writeAsStringSync(output);

  print('Generated ${outputFile.path}');
}

void printError(String error) {
  print('ERROR: $error');
}

void printUsage(String usage) {
  final exe = p.basename(Platform.resolvedExecutable);
  final script = p.basename(p.fromUri(Platform.script));
  print('Usage: $exe run $script [options] <pci.ids>');
  print(usage);
}

String resolveOutputFile(String output) {
  if (FileSystemEntity.isDirectorySync(output)) {
    return p.join(output, kDefaultOutputFileName);
  }
  return output;
}

Iterable<String> filterLines(Iterable<String> lines) {
  return lines.map((l) => l.trimComment()).where((l) => l.isNotEmpty);
}

Iterable<PciItem> parseLines(Iterable<String> lines) {
  final items = <PciItem>[];
  for (final line in lines) {
    if (line.startsWith('C ')) break; // ### TODO: device classes
    items.add(PciItem(line));
  }
  return items;
}

String generateDart(Iterable<PciItem> items) {
  final vendors = buildVendors(items);
  return kOutputTemplate
      .replaceFirst('{{vendors}}', generateVendorMap(vendors))
      .replaceFirst('{{devices}}', generateDeviceMap(vendors))
      .replaceFirst('{{variables}}', generateVariables(vendors));
}

Iterable<PciVendor> buildVendors(Iterable<PciItem> items) {
  final vendors = <PciVendor>[];
  final devices = <PciDevice>[];
  final subsystems = <PciSubsystem>[];
  PciItem? currentVendor;
  PciItem? currentDevice;

  void addCurrentVendor() {
    if (currentVendor == null) return;
    vendors.add(currentVendor!.toVendor(List<PciDevice>.of(devices)));
    devices.clear();
    currentVendor = null;
  }

  void addCurrentDevice() {
    if (currentDevice == null) return;
    devices.add(currentDevice!.toDevice(List<PciSubsystem>.of(subsystems)));
    subsystems.clear();
    currentDevice = null;
  }

  for (final item in items) {
    switch (item.type) {
      case PciType.vendor:
        addCurrentDevice();
        addCurrentVendor();
        currentVendor = item;
        break;
      case PciType.device:
        addCurrentDevice();
        currentDevice = item;
        break;
      case PciType.subsystem:
        subsystems.add(item.toSubsystem());
        break;
      default:
        throw UnsupportedError(item.type.toString());
    }
  }
  addCurrentDevice();
  addCurrentVendor();
  return vendors;
}

String generateVendorMap(Iterable<PciVendor> vendors) {
  final lines = <String>[];
  lines.add('const _vendors = <int, PciVendor>{');
  for (final vendor in vendors) {
    lines.add('${vendor.id.print()}: ${vendor.formatKey()},');
  }
  lines.add('};');
  return lines.join('\n');
}

String generateDeviceMap(Iterable<PciVendor> vendors) {
  final lines = <String>[];
  lines.add('const _devices = <int, Map<int, PciDevice>>{');
  for (final vendor in vendors) {
    lines.add('${vendor.id.print()}: <int, PciDevice>{');
    for (final device in vendor.devices) {
      lines.add('${device.id.print()}: ${device.formatKey(vendor.id)},');
    }
    lines.add('},');
  }
  lines.add('};');
  return lines.join('\n');
}

String generateVariables(Iterable<PciVendor> vendors) {
  final lines = <String>[];
  for (final vendor in vendors) {
    lines.add(vendor.formatVariable());
    for (final device in vendor.devices) {
      lines.add(device.formatVariable(vendor.id));
      for (final subsystem in device.subsystems) {
        lines.add(subsystem.formatVariable(vendor.id, device.id));
      }
    }
  }
  return lines.join('\n');
}

extension PciInt on int {
  String print() => '0x${toHex()}';
  String toHex() => toRadixString(16).padLeft(4, '0');
}

extension PciString on String {
  String trimComment() {
    final hash = indexOf('#');
    if (hash == -1) {
      return this;
    }
    return substring(0, hash);
  }

  String print() => '\'${escape()}\'';
  String escape() => replaceAll('\'', '\\\'');
}

extension PciList<T> on List<T> {
  T? get firstOrNull => getOrNull(0);
  T? get secondOrNull => getOrNull(1);
  T? get lastOrNull => getOrNull(length - 1);
  T? getOrNull(int index) {
    if (index < 0 || index >= length) {
      return null;
    }
    return this[index];
  }
}

enum PciType { vendor, device, subsystem }

class PciItem {
  final String line;

  PciItem(this.line);

  PciType get type => PciType.values[indentation];
  int get id => int.parse(ids.first, radix: 16);
  int? get subid => int.tryParse(ids.secondOrNull ?? '', radix: 16);
  String get name => tokens.last;

  int get indentation => line.indexOf(RegExp(r'[^\t]'));
  String get content => line.substring(indentation);
  List<String> get tokens => content.split('  ');
  List<String> get ids => tokens.first.split(' ');

  PciVendor toVendor(Iterable<PciDevice> devices) {
    return PciVendor(id: id, name: name, devices: devices);
  }

  PciDevice toDevice(Iterable<PciSubsystem> subsystems) {
    return PciDevice(id: id, name: name, subsystems: subsystems);
  }

  PciSubsystem toSubsystem() {
    return PciSubsystem(vendorId: id, deviceId: subid ?? -1, name: name);
  }
}

extension PciVendorFormat on PciVendor {
  String formatKey() => '_vendor_${id.toHex()}';

  String formatValue() {
    final i = id.print();
    final n = name.print();
    final d = devices.map((device) => device.formatKey(id)).join(', ');
    return 'PciVendor(id: $i, name: $n, devices: <PciDevice>[$d],)';
  }

  String formatVariable() => 'const ${formatKey()} = ${formatValue()};';
}

extension PciDeviceFormat on PciDevice {
  String formatKey(int vendorId) {
    final v = vendorId.toHex();
    final i = id.toHex();
    return '_device_${v}_$i';
  }

  String formatValue(int vendorId) {
    final i = id.print();
    final n = name.print();
    final s = subsystems
        .map((subsystem) => subsystem.formatKey(vendorId, id))
        .join(', ');
    return 'PciDevice(id: $i, name: $n, subsystems: <PciSubsystem>[$s],)';
  }

  String formatVariable(int vendorId) {
    return 'const ${formatKey(vendorId)} = ${formatValue(vendorId)};';
  }
}

extension PciSubsystemFormat on PciSubsystem {
  String formatKey(int vendorId, int deviceId) {
    final v1 = vendorId.toHex();
    final d1 = deviceId.toHex();
    final v2 = this.vendorId.toHex();
    final d2 = this.deviceId.toHex();
    return '_subsystem_${v1}_${d1}_${v2}_$d2';
  }

  String formatValue() {
    final v = vendorId.print();
    final d = deviceId.print();
    final n = name.print();
    return 'PciSubsystem(vendorId: $v, deviceId: $d, name: $n,)';
  }

  String formatVariable(int vendorId, int deviceId) {
    return 'const ${formatKey(vendorId, deviceId)} = ${formatValue()};';
  }
}
