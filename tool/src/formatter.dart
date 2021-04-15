import 'item.dart';

extension PciVendorFormatter on PciVendor {
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

extension PciDeviceFormatter on PciDevice {
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

extension PciSubsystemFormatter on PciSubsystem {
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

extension PciDeviceClassFormatter on PciDeviceClass {
  String formatKey() => '_device_class_${id.toHex()}';

  String formatValue() {
    final i = id.print();
    final n = name.print();
    final s = subclasses.map((subclass) => subclass.formatKey(id)).join(', ');
    return 'PciDeviceClass(id: $i, name: $n, subclasses: <PciSubclass>[$s],)';
  }

  String formatVariable() => 'const ${formatKey()} = ${formatValue()};';

  String formatMapEntry() => '${id.print()}: ${formatKey()},';
}

extension PciSubclassFormatter on PciSubclass {
  String formatKey(int deviceClassId) {
    final d = deviceClassId.toHex();
    final i = id.toHex();
    return '_subclass_${d}_$i';
  }

  String formatValue(int deviceClassId) {
    final i = id.print();
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
    return '${id.print()}: ${formatKey(deviceClassId)},';
  }
}

extension PciProgrammingInterfaceFormatter on PciProgrammingInterface {
  String formatKey(int deviceClassId, int subclassId) {
    final d = deviceClassId.toHex();
    final s = subclassId.toHex();
    final i = id.toHex();
    return '_programming_interface_${d}_${s}_$i';
  }

  String formatValue() {
    final i = id.print();
    final n = name.print();
    return 'PciProgrammingInterface(id: $i, name: $n,)';
  }

  String formatVariable(int deviceClassId, int subclassId) {
    return 'const ${formatKey(deviceClassId, subclassId)} = ${formatValue()};';
  }
}

extension PciIntFormatter on int {
  String print() => '0x${toHex()}';
  String toHex() => toRadixString(16).padLeft(4, '0');
}

extension PciStringFormatter on String {
  String print() => '\'${escape()}\'';
  String escape() => replaceAll('\'', '\\\'');
}
