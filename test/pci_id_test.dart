import 'package:pci_id/pci_id.dart';
import 'package:test/test.dart';

void main() {
  test('vendor', () {
    final vendor = PciId.findVendor(0x1ae0);
    expect(vendor, isNotNull);
    expect(vendor!.id, 0x1ae0);
    expect(vendor.name, 'Google, Inc.');
    expect(vendor.devices, hasLength(2));
  });
}
