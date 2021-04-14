import 'package:equatable/equatable.dart';

class PciVendor extends Equatable {
  final int id;
  final String name;
  final Iterable<PciDevice> devices;

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

class PciDevice extends Equatable {
  final int id;
  final String name;
  final Iterable<PciSubsystem> subsystems;

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

class PciSubsystem extends Equatable {
  final int vendorId;
  final int deviceId;
  final String name;

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
