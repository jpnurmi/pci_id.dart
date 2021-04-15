import 'package:pci_id/pci_id.dart';
import 'package:test/test.dart';

void main() {
  test('vendors', () {
    final subsystem1 = PciSubsystem(
      vendorId: 1,
      deviceId: 2,
      name: 'Subsystem 1',
    );
    final subsystem2 = PciSubsystem(
      vendorId: 3,
      deviceId: 4,
      name: 'Subsystem 2',
    );
    expect(subsystem1, equals(subsystem1));
    expect(subsystem1, isNot(equals(subsystem2)));
    expect(
      subsystem1.toString(),
      matches(
        r'PciSubsystem\(1, 2, Subsystem 1\)',
      ),
    );

    final device1 = PciDevice(
      id: 1,
      name: 'Device 1',
      subsystems: [subsystem1, subsystem2],
    );
    final device2 = PciDevice(
      id: 2,
      name: 'Device 2',
      subsystems: [subsystem2, subsystem1],
    );
    expect(device1, equals(device1));
    expect(device1, isNot(equals(device2)));
    expect(
      device1.toString(),
      matches(
        r'PciDevice\(1, Device 1, \[.*\]\)',
      ),
    );

    final vendor1 = PciVendor(
      id: 1,
      name: 'Vendor 1',
      devices: [device1, device2],
    );
    final vendor2 = PciVendor(
      id: 2,
      name: 'Vendor 2',
      devices: [device2, device1],
    );
    expect(vendor1, equals(vendor1));
    expect(vendor1, isNot(equals(vendor2)));
    expect(
      vendor1.toString(),
      matches(
        r'PciVendor\(1, Vendor 1\, \[.*\]\)',
      ),
    );
  });

  test('device classes', () {
    final programmingInterface1 = PciProgrammingInterface(
      id: 1,
      name: 'Programming interface 1',
    );
    final programmingInterface2 = PciProgrammingInterface(
      id: 2,
      name: 'Programming interface 2',
    );
    expect(programmingInterface1, equals(programmingInterface1));
    expect(programmingInterface1, isNot(equals(programmingInterface2)));
    expect(
      programmingInterface1.toString(),
      matches(
        r'PciProgrammingInterface\(1, Programming interface 1\)',
      ),
    );

    final subclass1 = PciSubclass(
      id: 1,
      name: 'Subclass 1',
      programmingInterfaces: [programmingInterface1, programmingInterface2],
    );
    final subclass2 = PciSubclass(
      id: 2,
      name: 'Subclass 2',
      programmingInterfaces: [programmingInterface2, programmingInterface1],
    );
    expect(subclass1, equals(subclass1));
    expect(subclass1, isNot(equals(subclass2)));
    expect(
      subclass1.toString(),
      matches(
        r'PciSubclass\(1, Subclass 1, \[.*\]\)',
      ),
    );

    final deviceClass1 = PciDeviceClass(
      id: 1,
      name: 'Device class 1',
      subclasses: [subclass1, subclass2],
    );
    final deviceClass2 = PciDeviceClass(
      id: 2,
      name: 'Device class 2',
      subclasses: [subclass2, subclass1],
    );
    expect(deviceClass1, equals(deviceClass1));
    expect(deviceClass1, isNot(equals(deviceClass2)));
    expect(
      deviceClass1.toString(),
      matches(
        r'PciDeviceClass\(1, Device class 1, \[.*\]\)',
      ),
    );
  });
}
