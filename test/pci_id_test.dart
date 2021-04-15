import 'package:pci_id/pci_id.dart';
import 'package:test/test.dart';

void main() {
  test('all vendors', () {
    final vendors = PciId.allVendors;
    expect(vendors, hasLength(2237));
  });

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

  test('all device classes', () {
    final deviceClasses = PciId.allDeviceClasses;
    expect(deviceClasses, hasLength(22));
  });

  test('lookup device class', () {
    final deviceClass = PciId.lookupDeviceClass(0x03);
    expect(deviceClass, isNotNull);
    expect(deviceClass!.id, equals(0x03));
    expect(deviceClass.name, equals('Display controller'));
    expect(deviceClass.subclasses, hasLength(4));
  });

  test('lookup subclass', () {
    final subclass = PciId.lookupSubclass(0x00, deviceClassId: 0x03);
    expect(subclass, isNotNull);
    expect(subclass!.id, equals(0x00));
    expect(subclass.name, equals('VGA compatible controller'));
    expect(subclass.programmingInterfaces, hasLength(2));
  });
}
