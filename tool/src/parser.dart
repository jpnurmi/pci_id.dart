import 'item.dart';

class PciParser {
  Iterable<PciItem> parse(Iterable<String> lines) {
    for (final line in lines) {
      final trimmed = line.removeComment();
      if (trimmed.isNotEmpty) {
        final item = parseLine(trimmed);
        _type = item.type;
        _items.add(item);
      }
    }
    return _items;
  }

  bool isDeviceClass(String line) {
    return line.startsWith('C ') || _type.index >= PciType.deviceClass.index;
  }

  PciItem parseLine(String line) {
    final indentation = line.indexOf(RegExp(r'[^\t]'));
    switch (indentation) {
      case 0:
        if (isDeviceClass(line)) {
          return PciItem.deviceClass(line.substring(2).trim());
        } else {
          return PciItem.vendor(line.trim());
        }
      case 1:
        if (isDeviceClass(line)) {
          return PciItem.subclass(line.trim());
        } else {
          return PciItem.device(line.trim());
        }
      case 2:
        if (isDeviceClass(line)) {
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
  String removeComment() {
    final hash = indexOf('#');
    if (hash == -1) {
      return this;
    }
    return substring(0, hash);
  }
}
