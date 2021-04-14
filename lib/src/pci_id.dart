import 'pci_types.dart';

part 'pci_id.g.dart';

class PciId {
  static Iterable<PciVendor> get allVendors => _vendors.values;
  static PciVendor? lookupVendor(int id) {
    return _vendors[id];
  }

  static PciDevice? lookupDevice(int id, {required int vendorId}) {
    return _devices[vendorId]?[id];
  }
}
