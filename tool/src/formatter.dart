import 'item.dart';

extension PciVendorFormatter on PciVendor {
  String formatKey() => '_vendor_${id.toHex(4)}';

  String formatValue() {
    final i = id.print(4);
    final n = name.print();
    final d = devices.map((device) => device.formatKey(id)).join(', ');
    return 'PciVendor(id: $i, name: $n, devices: <PciDevice>[$d],)';
  }

  String formatVariable() => 'const ${formatKey()} = ${formatValue()};';

  String formatMapEntry() => '${id.print(4)}: ${formatKey()},';
}

extension PciDeviceFormatter on PciDevice {
  String formatKey(int vendorId) {
    final v = vendorId.toHex(4);
    final i = id.toHex(4);
    return '_device_${v}_$i';
  }

  String formatValue(int vendorId) {
    final i = id.print(4);
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
    return '${id.print(4)}: ${formatKey(vendorId)},';
  }
}

extension PciSubsystemFormatter on PciSubsystem {
  String formatKey(int vendorId, int deviceId) {
    final v1 = vendorId.toHex(4);
    final d1 = deviceId.toHex(4);
    final v2 = this.vendorId.toHex(4);
    final d2 = this.deviceId.toHex(4);
    return '_subsystem_${v1}_${d1}_${v2}_$d2';
  }

  String formatValue() {
    final v = vendorId.print(4);
    final d = deviceId.print(4);
    final n = name.print();
    return 'PciSubsystem(vendorId: $v, deviceId: $d, name: $n,)';
  }

  String formatVariable(int vendorId, int deviceId) {
    return 'const ${formatKey(vendorId, deviceId)} = ${formatValue()};';
  }
}

extension PciDeviceClassFormatter on PciDeviceClass {
  String formatKey() => '_device_class_${id.toHex(2)}';

  String formatValue() {
    final i = id.print(2);
    final n = name.print();
    final s = subclasses.map((subclass) => subclass.formatKey(id)).join(', ');
    return 'PciDeviceClass(id: $i, name: $n, subclasses: <PciSubclass>[$s],)';
  }

  String formatVariable() => 'const ${formatKey()} = ${formatValue()};';

  String formatMapEntry() => '${id.print(2)}: ${formatKey()},';
}

extension PciSubclassFormatter on PciSubclass {
  String formatKey(int deviceClassId) {
    final d = deviceClassId.toHex(2);
    final i = id.toHex(2);
    return '_subclass_${d}_$i';
  }

  String formatValue(int deviceClassId) {
    final i = id.print(2);
    final n = name.print();
    final p = programmingInterfaces
        .map((pi) => pi.formatKey(deviceClassId, id))
        .join(', ');
    return 'PciSubclass(id: $i, name: $n, programmingInterfaces: <PciProgrammingInterface>[$p],)';
  }

  String formatVariable(int deviceClassId) {
    return 'const ${formatKey(deviceClassId)} = ${formatValue(deviceClassId)};';
  }

  String formatMapEntry(int deviceClassId) {
    return '${id.print(2)}: ${formatKey(deviceClassId)},';
  }
}

extension PciProgrammingInterfaceFormatter on PciProgrammingInterface {
  String formatKey(int deviceClassId, int subclassId) {
    final d = deviceClassId.toHex(2);
    final s = subclassId.toHex(2);
    final i = id.toHex(2);
    return '_programming_interface_${d}_${s}_$i';
  }

  String formatValue() {
    final i = id.print(2);
    final n = name.print();
    return 'PciProgrammingInterface(id: $i, name: $n,)';
  }

  String formatVariable(int deviceClassId, int subclassId) {
    return 'const ${formatKey(deviceClassId, subclassId)} = ${formatValue()};';
  }
}

extension PciIntFormatter on int {
  String print(int length) => '0x${toHex(length)}';
  String toHex(int length) => toRadixString(16).padLeft(length, '0');
}

extension PciStringFormatter on String {
  String print() => '\'${escape()}\'';
  String escape() => replaceAll('\'', '\\\'');
}
