import 'pci_types.dart';

part 'pci_id.g.dart';

/// A repository of all known ID's used in PCI devices: ID's of vendors,
/// devices, subsystems and device classes. This package can be utilized
/// to display human-readable names instead of cryptic numeric codes.
class PciId {
  /// Holds a collection of all PCI vendors.
  static Iterable<PciVendor> get allVendors => _vendors.values;

  /// Looks up a PCI vendor by the [id].
  ///
  /// Returns `null` if not found.
  static PciVendor? lookupVendor(int id) => _vendors[id];

  /// Looks up a PCI device by the [id] and [vendorId].
  ///
  /// Returns `null` if not found.
  static PciDevice? lookupDevice(int id, {required int vendorId}) {
    return _devices[vendorId]?[id];
  }

  /// Holds a collection all PCI device classes.
  static Iterable<PciDeviceClass> get allDeviceClasses {
    return _device_classes.values;
  }

  /// Looks up a PCI device class by the [id].
  ///
  /// Returns `null` if not found.
  static PciDeviceClass? lookupDeviceClass(int id) {
    return _device_classes[id];
  }

  /// Looks up a PCI subclass by the [id] and [deviceClassId].
  ///
  /// Returns `null` if not found.
  static PciSubclass? lookupSubclass(int id, {required int deviceClassId}) {
    return _subclasses[deviceClassId]?[id];
  }
}
