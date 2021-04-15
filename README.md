# The PCI ID Repository for Dart

[![pub](https://img.shields.io/pub/v/pci_id.svg)](https://pub.dev/packages/pci_id)
[![license: BSD](https://img.shields.io/badge/license-BSD-yellow.svg)](https://opensource.org/licenses/BSD-3-Clause)
[![style: lint](https://img.shields.io/badge/style-lint-4BC0F5.svg)](https://pub.dev/packages/lint)
![CI](https://github.com/jpnurmi/pci_id.dart/workflows/CI/badge.svg)
[![codecov](https://codecov.io/gh/jpnurmi/pci_id.dart/branch/main/graph/badge.svg)](https://codecov.io/gh/jpnurmi/pci_id.dart)

A repository of all known ID's used in PCI devices: ID's of vendors,
devices, subsystems and device classes. This package can be utilized
to display human-readable names instead of cryptic numeric codes.

### Usage

```dart
import 'package:pci_id/pci_id.dart';

void main() {
  final vendor = PciId.lookupVendor(0x1ae0);
  print('Vendor 0x1ae0:     ${vendor!.name}'); // Google, Inc.

  final device = PciId.lookupDevice(0xabcd, vendorId: vendor.id);
  print('  Device 0xabcd:   ${device!.name}'); // ...Pixel Neural Core...

  final deviceClass = PciId.lookupDeviceClass(0x03);
  print('\nDevice class 0x03: ${deviceClass!.name}'); // Display controller

  final subclass = PciId.lookupSubclass(0x00, deviceClassId: 0x03);
  print('  Subclass 0x00:   ${subclass!.name}'); // VGA compatible controller
}
```
