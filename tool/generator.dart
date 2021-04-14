import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:pci_id/pci_id.dart';

const String kDefaultOutputFileName = 'pci_id.g.dart';

const String kOutputTemplate = '''
part of 'pci_id.dart';

const _vendors = <int, PciVendor>{
{{vendors}}
};
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
  final vendors = buildPciVendors(pciIds);
  final output = formatPciVendors(vendors);
  return kOutputTemplate.replaceFirst('{{vendors}}', output);
}

List<PciVendor> buildPciVendors(List<PciIdLine> pciIds) {
  final vendors = <PciVendor>[];
  final devices = <PciDevice>[];
  final subsystems = <PciSubsystem>[];
  var vendorPciId;
  for (final pciId in pciIds) {
    switch (pciId.type) {
      case PciIdType.vendor:
        if (vendorPciId != null) {
          vendors.add(vendorPciId.toVendor(List<PciDevice>.of(devices)));
          vendorPciId = null;
          devices.clear();
        }
        vendorPciId = pciId;
        break;
      case PciIdType.device:
        devices.add(pciId.toDevice(List<PciSubsystem>.of(subsystems)));
        subsystems.clear();
        break;
      case PciIdType.subsystem:
        subsystems.add(pciId.toSubsystem());
        break;
      default:
        throw UnsupportedError(pciId.type.toString());
    }
  }
  return vendors;
}

String formatPciVendors(List<PciVendor> vendors) {
  final lines = <String>[];
  for (final vendor in vendors) {
    lines.add('  ${vendor.id}: ${vendor.format()},');
  }
  return lines.join('\n');
}

extension PciIdString on String {
  String trimComment() {
    final hash = indexOf('#');
    if (hash == -1) {
      return this;
    }
    return substring(0, hash);
  }

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
  String format() {
    final n = name.escapeQuotes();
    final d = devices.map((device) => device.format()).join(', ');
    return 'PciVendor(id: $id, name: \'$n\', devices: <PciDevice>[$d],)';
  }
}

extension PciDeviceFormat on PciDevice {
  String format() {
    final n = name.escapeQuotes();
    final s = subsystems.map((subsystem) => subsystem.format()).join(', ');
    return 'PciDevice(id: $id, name: \'$n\', subsystems: [$s],)';
  }
}

extension PciSubsystemFormat on PciSubsystem {
  String format() {
    final n = name.escapeQuotes();
    return 'PciSubsystem(vendorId: $vendorId, deviceId: $deviceId, name: \'$n\',)';
  }
}
