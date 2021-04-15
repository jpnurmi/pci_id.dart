import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:pci_id/src/pci_types.dart';

import 'src/builder.dart';
import 'src/formatter.dart';
import 'src/item.dart';
import 'src/parser.dart';

const String kDefaultOutputFileName = 'pci_id.g.dart';

const kVendorIndexTemplate = '''
const _vendors = <int, PciVendor>{
{{entries}}
};
''';

const kDeviceIndexTemplate = '''
const _devices = <int, Map<int, PciDevice>>{
{{entries}}
};
''';

const kDeviceEntryTemplate = '''
{{id}}: <int, PciDevice>{
  {{entries}}
},
''';

const String kOutputTemplate = '''
part of 'pci_id.dart';

{{variables}}

{{index}}
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

String generateDart(Iterable<PciItem> items) {
  final builder = PciBuilder.build(items);
  return kOutputTemplate
      .replaceFirst('{{index}}', generateIndex(builder))
      .replaceFirst('{{variables}}', generateVariables(builder));
}

String generateIndex(PciBuilder builder) {
  final lines = <String>[];
  lines.add(generateVendorIndex(builder.vendors));
  lines.add(generateDeviceIndex(builder.vendors));
  return lines.join('\n');
}

String generateVendorIndex(Iterable<PciVendor> vendors) {
  final lines = <String>[];
  for (final vendor in vendors) {
    lines.add(vendor.formatMapEntry());
  }
  return kVendorIndexTemplate.replaceFirst('{{entries}}', lines.join('\n'));
}

String generateDeviceIndex(Iterable<PciVendor> vendors) {
  final lines = <String>[];
  for (final vendor in vendors) {
    final entries = vendor.devices.map<String>(
      (device) => device.formatMapEntry(vendor.id),
    );
    lines.add(kDeviceEntryTemplate
        .replaceFirst('{{id}}', vendor.id.print())
        .replaceFirst('{{entries}}', entries.join('\n')));
  }
  return kDeviceIndexTemplate.replaceFirst('{{entries}}', lines.join('\n'));
}

String generateVariables(PciBuilder builder) {
  final lines = <String>[];
  lines.addAll(generateVendorVariables(builder.vendors));
  lines.addAll(generateDeviceClassVariables(builder.deviceClasses));
  return lines.join('\n');
}

List<String> generateVendorVariables(Iterable<PciVendor> vendors) {
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
  return lines;
}

List<String> generateDeviceClassVariables(
  Iterable<PciDeviceClass> deviceClasses,
) {
  final lines = <String>[];
  for (final deviceClass in deviceClasses) {
    lines.add(deviceClass.formatVariable());
    for (final subclass in deviceClass.subclasses) {
      lines.add(subclass.formatVariable(deviceClass.id));
      for (final programmingInterface in subclass.programmingInterfaces) {
        lines.add(
          programmingInterface.formatVariable(deviceClass.id, subclass.id),
        );
      }
    }
  }
  return lines;
}
