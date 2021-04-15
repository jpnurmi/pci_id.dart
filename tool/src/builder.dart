import 'formatter.dart';
import 'item.dart';

class PciBuilder {
  static PciBuilder build(Iterable<PciItem> items) {
    final builder = PciBuilder();

    final devices = <PciDevice>[];
    final subsystems = <PciSubsystem>[];
    PciItem? currentVendor;
    PciItem? currentDevice;

    void addCurrentVendor() {
      if (currentVendor == null) return;
      builder.vendors.add(currentVendor!.toVendor(List<PciDevice>.of(devices)));
      devices.clear();
      currentVendor = null;
    }

    void addCurrentDevice() {
      if (currentDevice == null) return;
      devices.add(currentDevice!.toDevice(List<PciSubsystem>.of(subsystems)));
      subsystems.clear();
      currentDevice = null;
    }

    for (final item in items) {
      switch (item.type) {
        case PciType.vendor:
          addCurrentDevice();
          addCurrentVendor();
          currentVendor = item;
          break;
        case PciType.device:
          addCurrentDevice();
          currentDevice = item;
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
    addCurrentDevice();
    addCurrentVendor();
    return builder;
  }

  final vendors = <PciVendor>[];
  final deviceClasses = <PciDeviceClass>[];
}
