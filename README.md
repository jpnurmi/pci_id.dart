# The PCI ID Repository for Dart

[![pub](https://img.shields.io/pub/v/pci_id.svg)](https://pub.dev/packages/pci_id)
[![license: BSD](https://img.shields.io/badge/license-BSD-yellow.svg)](https://opensource.org/licenses/BSD-3-Clause)
![CI](https://github.com/jpnurmi/pci_id.dart/workflows/CI/badge.svg)

A repository of all known ID's used in PCI devices: ID's of vendors,
devices, subsystems and device classes. This package can be utilized
to display human-readable names instead of cryptic numeric codes.

### Usage

```dart
import 'package:pci_id/pci_id.dart';

void main() {
  final vendor = PciId.lookupVendor(0x1ae0);
  print('Vendor: ${vendor!.name}'); // Google, Inc.

  final device = PciId.lookupDevice(0xabcd, vendorId: vendor.id);
  print('Device: ${device!.name}'); // ... [Pixel Neural Core]
}
```
