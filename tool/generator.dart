import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:pci_id/src/pci_types.dart';

import 'src/builder.dart';
import 'src/formatter.dart';
import 'src/item.dart';
import 'src/parser.dart';

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

String generateDart(Iterable<PciItem> items) {
  final builder = PciBuilder.build(items);
  return kOutputTemplate
      .replaceFirst('{{vendors}}', generateVendorMap(builder.vendors))
      .replaceFirst('{{devices}}', generateDeviceMap(builder.vendors))
      .replaceFirst('{{variables}}', generateVariables(builder.vendors));
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
