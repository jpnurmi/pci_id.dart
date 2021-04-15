import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:pci_id/src/pci_types.dart';

const String kDefaultOutputFileName = 'pci_id.g.dart';

const kVendorMapTemplate = '''
const _vendors = <int, PciVendor>{
{{entries}}
};
''';

const kDeviceMapTemplate = '''
const _devices = <int, Map<int, PciDevice>>{
{{entries}}
};
''';

const kDeviceMapEntryTemplate = '''
{{id}}: <int, PciDevice>{
  {{entries}}
},
''';

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

  final lines = inputFile.readAsLinesSync();
  final items = PciParser().parse(lines);

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

class PciParser {
  Iterable<PciItem> parse(Iterable<String> lines) {
    for (final line in lines) {
      final trimmed = line.trimComment();
      if (trimmed.isNotEmpty) {
        final item = _parseLine(trimmed);
        _type = item.type;
        _items.add(item);
      }
    }
    return _items;
  }

  PciItem _parseLine(String line) {
    final indentation = line.indexOf(RegExp(r'[^\t]'));
    switch (indentation) {
      case 0:
        if (line.startsWith('C')) {
          return PciItem.deviceClass(line.trim());
        } else {
          return PciItem.vendor(line.trim());
        }
      case 1:
        if (_type == PciType.deviceClass) {
          return PciItem.subclass(line.trim());
        } else {
          return PciItem.device(line.trim());
        }
      case 2:
        if (_type == PciType.subclass) {
          return PciItem.programmingInterface(line.trim());
        } else {
          return PciItem.subsystem(line.trim());
        }
      default:
        throw UnsupportedError('Malformed pci.ids');
    }
  }

  final _items = <PciItem>[];
  PciType _type = PciType.device;
}

String generateDart(Iterable<PciItem> items) {
  final builder = PciBuilder.build(items);
  return kOutputTemplate
      .replaceFirst('{{vendors}}', generateVendorMap(builder.vendors))
      .replaceFirst('{{devices}}', generateDeviceMap(builder.vendors))
      .replaceFirst('{{variables}}', generateVariables(builder.vendors));
}

class PciBuilder {
  static PciBuilder build(Iterable<PciItem> items) {
    final builder = PciBuilder();

    final devices = <PciDevice>[];
    final subsystems = <PciSubsystem>[];
    PciItem? currentVendor;
    PciItem? currentDevice;

    void addCurrentVendor() {
      if (currentVendor == null) return;
      builder.vendors.add(currentVendor!.toVendor(List<PciDevice>.of(devices)));
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
        case PciType.deviceClass:
          // ### TODO
          break;
        case PciType.subclass:
          // ### TODO
          break;
        case PciType.programmingInterface:
          // ### TODO
          break;
        default:
          throw UnsupportedError(item.type.toString());
      }
    }
    addCurrentDevice();
    addCurrentVendor();
    return builder;
  }

  final vendors = <PciVendor>[];
  final deviceClasses = <PciDeviceClass>[];
}

String generateVendorMap(Iterable<PciVendor> vendors) {
  final lines = <String>[];
  for (final vendor in vendors) {
    lines.add(vendor.formatMapEntry());
  }
  return kVendorMapTemplate.replaceFirst('{{entries}}', lines.join('\n'));
}

String generateDeviceMap(Iterable<PciVendor> vendors) {
  final lines = <String>[];
  for (final vendor in vendors) {
    final entries = vendor.devices.map<String>(
      (device) => device.formatMapEntry(vendor.id),
    );
    lines.add(kDeviceMapEntryTemplate
        .replaceFirst('{{id}}', vendor.id.print())
        .replaceFirst('{{entries}}', entries.join('\n')));
  }
  return kDeviceMapTemplate.replaceFirst('{{entries}}', lines.join('\n'));
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

enum PciType {
  vendor,
  device,
  subsystem,
  deviceClass,
  subclass,
  programmingInterface,
}

class PciItem {
  final String line;
  final PciType type;

  PciItem.vendor(this.line) : type = PciType.vendor;
  PciItem.device(this.line) : type = PciType.device;
  PciItem.subsystem(this.line) : type = PciType.subsystem;
  PciItem.deviceClass(this.line) : type = PciType.deviceClass;
  PciItem.subclass(this.line) : type = PciType.subclass;
  PciItem.programmingInterface(this.line) : type = PciType.programmingInterface;

  int get id => int.parse(ids.first, radix: 16);
  int? get subid => int.tryParse(ids.secondOrNull ?? '', radix: 16);
  String get name => tokens.last;

  List<String> get tokens => line.split('  ');
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

  PciDeviceClass toDeviceClass(Iterable<PciSubclass> subclasses) {
    return PciDeviceClass(id: id, name: name, subclasses: subclasses);
  }

  PciSubclass toSubclass(
    Iterable<PciProgrammingInterface> programmingInterfaces,
  ) {
    return PciSubclass(
      id: id,
      name: name,
      programmingInterfaces: programmingInterfaces,
    );
  }

  PciProgrammingInterface toProgrammingInterface() {
    return PciProgrammingInterface(id: id, name: name);
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

  String formatMapEntry() => '${id.print()}: ${formatKey()},';
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

  String formatMapEntry(int vendorId) {
    return '${id.print()}: ${formatKey(vendorId)},';
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
