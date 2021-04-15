import 'item.dart';

class PciBuilder {
  PciBuilder.build(Iterable<PciItem> items) {
    buildVendors(items);
    buildDeviceClasses(items);
  }

  void buildVendors(Iterable<PciItem> items) {
    final devices = <PciDevice>[];
    final subsystems = <PciSubsystem>[];

    final vendorStack = <PciItem>[];
    void pushVendor(PciItem item) => vendorStack.add(item);
    void popVendor() {
      if (vendorStack.isEmpty) return;
      final item = vendorStack.removeLast();
      vendors.add(item.toVendor(List<PciDevice>.of(devices)));
      devices.clear();
    }

    final deviceStack = <PciItem>[];
    void pushDevice(PciItem item) => deviceStack.add(item);
    void popDevice() {
      if (deviceStack.isEmpty) return;
      final item = deviceStack.removeLast();
      devices.add(item.toDevice(List<PciSubsystem>.of(subsystems)));
      subsystems.clear();
    }

    for (final item in items) {
      switch (item.type) {
        case PciType.vendor:
          popDevice();
          popVendor();
          pushVendor(item);
          break;
        case PciType.device:
          popDevice();
          pushDevice(item);
          break;
        case PciType.subsystem:
          subsystems.add(item.toSubsystem());
          break;
        default:
          break;
      }
    }
    popDevice();
    popVendor();
  }

  void buildDeviceClasses(Iterable<PciItem> items) {
    final subclasses = <PciSubclass>[];
    final programmingInterfaces = <PciProgrammingInterface>[];

    final deviceClassStack = <PciItem>[];
    void pushDeviceClass(PciItem item) => deviceClassStack.add(item);
    void popDeviceClass() {
      if (deviceClassStack.isEmpty) return;
      final item = deviceClassStack.removeLast();
      deviceClasses.add(item.toDeviceClass(List<PciSubclass>.of(subclasses)));
      subclasses.clear();
    }

    final subclassStack = <PciItem>[];
    void pushSubclass(PciItem item) => subclassStack.add(item);
    void popSubclass() {
      if (subclassStack.isEmpty) return;
      final item = subclassStack.removeLast();
      subclasses.add(item
          .toSubclass(List<PciProgrammingInterface>.of(programmingInterfaces)));
      programmingInterfaces.clear();
    }

    for (final item in items) {
      switch (item.type) {
        case PciType.deviceClass:
          popSubclass();
          popDeviceClass();
          pushDeviceClass(item);
          break;
        case PciType.subclass:
          popSubclass();
          pushSubclass(item);
          break;
        case PciType.programmingInterface:
          programmingInterfaces.add(item.toProgrammingInterface());
          break;
        default:
          break;
      }
    }
    popSubclass();
    popDeviceClass();
  }

  final vendors = <PciVendor>[];
  final deviceClasses = <PciDeviceClass>[];
}
