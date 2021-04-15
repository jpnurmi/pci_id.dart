import 'package:pci_id/src/pci_types.dart';
export 'package:pci_id/src/pci_types.dart';

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
  int get subid => int.parse(ids.last, radix: 16);
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
    return PciSubsystem(vendorId: id, deviceId: subid, name: name);
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
