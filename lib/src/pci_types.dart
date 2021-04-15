import 'package:equatable/equatable.dart';

/// Describes a PCI vendor and its devices.
class PciVendor extends Equatable {
  /// Holds the ID of the PCI vendor.
  final int id;

  /// Holds the name of the PCI vendor.
  final String name;

  /// Holds the devices of the PCI vendor.
  final Iterable<PciDevice> devices;

  /// Constructs a PCI vendor.
  const PciVendor({
    required this.id,
    required this.name,
    required this.devices,
  });

  @override
  List<Object?> get props => <Object?>[id, name, devices];

  @override
  bool? get stringify => true;
}

/// Describes a PCI device and its subsystems.
class PciDevice extends Equatable {
  /// Holds the ID of the PCI device.
  final int id;

  /// Holds the name of the PCI device.
  final String name;

  /// Holds the subsystems of the PCI device.
  final Iterable<PciSubsystem> subsystems;

  /// Constructs a PCI device.
  const PciDevice({
    required this.id,
    required this.name,
    required this.subsystems,
  });

  @override
  List<Object?> get props => <Object?>[id, name, subsystems];

  @override
  bool? get stringify => true;
}

/// Describes a PCI subsystem.
class PciSubsystem extends Equatable {
  /// Holds the vendor ID of the PCI subsystem.
  final int vendorId;

  /// Holds the device ID of the PCI subsystem.
  final int deviceId;

  /// Holds the name of the PCI subsystem.
  final String name;

  /// Constructs a PCI subsystem.
  const PciSubsystem({
    required this.vendorId,
    required this.deviceId,
    required this.name,
  });

  @override
  List<Object?> get props => <Object?>[vendorId, deviceId, name];

  @override
  bool? get stringify => true;
}

/// Describes a PCI device class and its subclasses.
class PciDeviceClass extends Equatable {
  /// Holds the ID of the PCI device class.
  final int id;

  /// Holds the name of the PCI device class.
  final String name;

  /// Holds the subclasses of the PCI device class.
  final Iterable<PciSubclass> subclasses;

  /// Constructs a PCI device class.
  const PciDeviceClass({
    required this.id,
    required this.name,
    required this.subclasses,
  });

  @override
  List<Object?> get props => <Object?>[id, name, subclasses];

  @override
  bool? get stringify => true;
}

/// Describes a PCI subclass and its programming interfaces.
class PciSubclass extends Equatable {
  /// Holds the ID of the PCI subclass.
  final int id;

  /// Holds the name of the PCI subclass.
  final String name;

  /// Holds the programming interfaces of the PCI subclass.
  final Iterable<PciProgrammingInterface> programmingInterfaces;

  /// Constructs a PCI subclass.
  const PciSubclass({
    required this.id,
    required this.name,
    required this.programmingInterfaces,
  });

  @override
  List<Object?> get props => <Object?>[id, name, programmingInterfaces];

  @override
  bool? get stringify => true;
}

/// Describes a PCI programming interface.
class PciProgrammingInterface extends Equatable {
  /// Holds the ID of the PCI programming interface.
  final int id;

  /// Holds the name of the PCI subclass.
  final String name;

  /// Constructs a PCI programming interface.
  const PciProgrammingInterface({
    required this.id,
    required this.name,
  });

  @override
  List<Object?> get props => <Object?>[id, name];

  @override
  bool? get stringify => true;
}
