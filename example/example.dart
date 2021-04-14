import 'package:pci_id/pci_id.dart';

void main() {
  final vendor = PciId.findVendor(0x1ae0);
  print('Vendor: ${vendor!.name}'); // Google, Inc.

  //final device = PciId.findDevice(vendor.id, 0xabcd);
  //print('Device: ${device.name}'); // ... [Pixel Neural Core]
}
