import 'pci_types.dart';

part 'pci_id.g.dart';

class PciId {
  static Iterable<PciVendor> get allVendors => _vendors.values;
  static PciVendor? lookupVendor(int id) => _vendors[id];

  static PciDevice? lookupDevice(int id, {required int vendorId}) {
    return _devices[vendorId]?[id];
  }

  static Iterable<PciDeviceClass> get allDeviceClasses {
    return _device_classes.values;
  }

  static PciDeviceClass? lookupDeviceClass(int id) {
    return _device_classes[id];
  }

  static PciSubclass? lookupSubclass(int id, {required int deviceClassId}) {
    return _subclasses[deviceClassId]?[id];
  }
}
