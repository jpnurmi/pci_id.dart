import 'item.dart';

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

extension PciComment on String {
  String trimComment() {
    final hash = indexOf('#');
    if (hash == -1) {
      return this;
    }
    return substring(0, hash);
  }
}
