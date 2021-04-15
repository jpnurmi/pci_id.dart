import 'item.dart';

class PciBuilder {
  static PciBuilder build(Iterable<PciItem> items) {
    final builder = PciBuilder();

    final devices = <PciDevice>[];
    final subsystems = <PciSubsystem>[];

    final vendorStack = <PciItem>[];
    void pushVendor(PciItem item) => vendorStack.add(item);
    void popVendor() {
      if (vendorStack.isEmpty) return;
      final item = vendorStack.removeLast();
      builder.vendors.add(item.toVendor(List<PciDevice>.of(devices)));
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
        case PciType.deviceClass:
          // ### TODO
          break;
        case PciType.subclass:
          // ### TODO
          break;
        case PciType.programmingInterface:
          // ### TODO
          break;
        default:
          throw UnsupportedError(item.type.toString());
      }
    }
    popDevice();
    popVendor();
    return builder;
  }

  final vendors = <PciVendor>[];
  final deviceClasses = <PciDeviceClass>[];
}
