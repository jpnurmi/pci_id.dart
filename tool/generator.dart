import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:pci_id/pci_id.dart';

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

  final input = inputFile.readAsLinesSync();
  final pciIds = parsePciIds(input);

  final output = generatePciIds(pciIds);
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

List<PciIdLine> parsePciIds(List<String> lines) {
  final pciIds = <PciIdLine>[];
  for (final line in lines) {
    if (line.startsWith('C ')) break; // ### TODO: device classes
    final pciId = PciIdLine.parse(line.trimComment());
    if (pciId != null) {
      pciIds.add(pciId);
    }
  }
  return pciIds;
}

String generatePciIds(List<PciIdLine> pciIds) {
  final vendors = buildVendors(pciIds);

  return kOutputTemplate
      .replaceFirst('{{vendors}}', generateVendorMap(vendors))
      .replaceFirst('{{devices}}', generateDeviceMap(vendors))
      .replaceFirst('{{variables}}', generateVariables(vendors));
}

List<PciVendor> buildVendors(List<PciIdLine> pciIds) {
  final vendors = <PciVendor>[];
  final devices = <PciDevice>[];
  final subsystems = <PciSubsystem>[];
  PciIdLine? currentVendor;
  PciIdLine? currentDevice;

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

  for (final pciId in pciIds) {
    switch (pciId.type) {
      case PciIdType.vendor:
        addCurrentDevice();
        addCurrentVendor();
        currentVendor = pciId;
        break;
      case PciIdType.device:
        addCurrentDevice();
        currentDevice = pciId;
        break;
      case PciIdType.subsystem:
        subsystems.add(pciId.toSubsystem());
        break;
      default:
        throw UnsupportedError(pciId.type.toString());
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
    lines.add('${vendor.id.formatId()}: ${vendor.formatName()},');
  }
  lines.add('};');
  return lines.join('\n');
}

String generateDeviceMap(Iterable<PciVendor> vendors) {
  final lines = <String>[];
  lines.add('const _devices = <int, Map<int, PciDevice>>{');
  for (final vendor in vendors) {
    lines.add('${vendor.id.formatId()}: <int, PciDevice>{');
    for (final device in vendor.devices) {
      lines.add('${device.id.formatId()}: ${device.formatName(vendor.id)},');
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

extension PciIdInt on int {
  String toHex() => toRadixString(16).padLeft(4, '0');
  String formatId() => '0x${toHex()}';
}

extension PciIdString on String {
  String trimComment() {
    final hash = indexOf('#');
    if (hash == -1) {
      return this;
    }
    return substring(0, hash);
  }

  String formatName() => '\'${escapeQuotes()}\'';
  String escapeQuotes() => replaceAll('\'', '\\\'');
}

extension PciIdList<T> on List<T> {
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

enum PciIdType { vendor, device, subsystem }

class PciIdLine {
  final PciIdType type;
  final int id;
  final int? subid;
  final String name;

  PciIdLine({
    required this.type,
    required this.id,
    this.subid,
    required this.name,
  });

  static PciIdLine? parse(String line) {
    final trimmed = line.trimComment();
    if (trimmed.isEmpty) return null;
    final indentation = trimmed.indexOf(RegExp(r'[^\t]'));
    final type = PciIdType.values[indentation];
    final tokens = trimmed.substring(indentation).split(RegExp(r'  '));
    assert(tokens.isNotEmpty);
    final ids = tokens.first.split(' ');
    final id = int.parse(ids.first, radix: 16);
    final subid = int.tryParse(ids.secondOrNull ?? '', radix: 16);
    return PciIdLine(type: type, id: id, subid: subid, name: tokens.last);
  }

  PciVendor toVendor(List<PciDevice> devices) {
    return PciVendor(id: id, name: name, devices: devices);
  }

  PciDevice toDevice(List<PciSubsystem> subsystems) {
    return PciDevice(id: id, name: name, subsystems: subsystems);
  }

  PciSubsystem toSubsystem() {
    return PciSubsystem(vendorId: id, deviceId: subid ?? -1, name: name);
  }
}

extension PciVendorFormat on PciVendor {
  String formatName() => '_vendor_${id.toHex()}';

  String formatValue() {
    final i = id.formatId();
    final n = name.formatName();
    final d = devices.map((device) => device.formatName(id)).join(', ');
    return 'PciVendor(id: $i, name: $n, devices: <PciDevice>[$d],)';
  }

  String formatVariable() => 'const ${formatName()} = ${formatValue()};';
}

extension PciDeviceFormat on PciDevice {
  String formatName(int vendorId) {
    final v = vendorId.toHex();
    final i = id.toHex();
    return '_device_${v}_$i';
  }

  String formatValue(int vendorId) {
    final i = id.formatId();
    final n = name.formatName();
    final s = subsystems
        .map((subsystem) => subsystem.formatName(vendorId, id))
        .join(', ');
    return 'PciDevice(id: $i, name: $n, subsystems: <PciSubsystem>[$s],)';
  }

  String formatVariable(int vendorId) {
    return 'const ${formatName(vendorId)} = ${formatValue(vendorId)};';
  }
}

extension PciSubsystemFormat on PciSubsystem {
  String formatName(int vendorId, int deviceId) {
    final v1 = vendorId.toHex();
    final d1 = deviceId.toHex();
    final v2 = this.vendorId.toHex();
    final d2 = this.deviceId.toHex();
    return '_subsystem_${v1}_${d1}_${v2}_$d2';
  }

  String formatValue() {
    final v = vendorId.formatId();
    final d = deviceId.formatId();
    final n = name.formatName();
    return 'PciSubsystem(vendorId: $v, deviceId: $d, name: $n,)';
  }

  String formatVariable(int vendorId, int deviceId) {
    return 'const ${formatName(vendorId, deviceId)} = ${formatValue()};';
  }
}
