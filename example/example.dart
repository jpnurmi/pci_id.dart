import 'package:pci_id/pci_id.dart';

void main() {
  final vendor = PciId.lookupVendor(0x1ae0);
  print('Vendor: ${vendor!.name}'); // Google, Inc.

  final device = PciId.lookupDevice(0xabcd, vendorId: vendor.id);
  print('Device: ${device!.name}'); // ... [Pixel Neural Core]
}
