import 'package:equatable/equatable.dart';

part 'pci_id.g.dart';

class PciId {
  static Iterable<PciVendor> get allVendors => _vendors.values;
  static PciVendor? lookupVendor(int id) {
    return _vendors[id];
  }

  static PciDevice? lookupDevice(int id, {required int vendorId}) {
    return _devices[vendorId]?[id];
  }
}

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
