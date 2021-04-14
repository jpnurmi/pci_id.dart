import 'package:pci_id/pci_id.dart';
import 'package:test/test.dart';

void main() {
  test('lookup vendor', () {
    final vendor = PciId.lookupVendor(0x1ade);
    expect(vendor, isNotNull);
    expect(vendor!.id, equals(0x1ade));
    expect(vendor.name, equals('Spin Master Ltd.'));
    expect(vendor.devices, hasLength(2));
  });

  test('lookup device', () {
    final device = PciId.lookupDevice(0x3038, vendorId: 0x1ade);
    expect(device, isNotNull);
    expect(device!.id, equals(0x3038));
    expect(device.name, equals('PCIe Video Bridge'));
    expect(device.subsystems, hasLength(2));
  });
}
