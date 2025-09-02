enum VehicleType {
  cycle,
  twoWheeler,
  fourWheeler,
  auto;

  String get displayName {
    switch (this) {
      case VehicleType.cycle:
        return 'Cycle';
      case VehicleType.twoWheeler:
        return 'Two Wheeler';
      case VehicleType.fourWheeler:
        return 'Four Wheeler';
      case VehicleType.auto:
        return 'Auto';
    }
  }

  double get rate {
    switch (this) {
      case VehicleType.cycle:
        return 20.0;
      case VehicleType.twoWheeler:
        return 30.0;
      case VehicleType.fourWheeler:
        return 50.0;
      case VehicleType.auto:
        return 40.0;
    }
  }

  String get icon {
    switch (this) {
      case VehicleType.cycle:
        return '🚲';
      case VehicleType.twoWheeler:
        return '🏍️';
      case VehicleType.fourWheeler:
        return '🚗';
      case VehicleType.auto:
        return '🛺';
    }
  }

  static VehicleType fromString(String value) {
    return VehicleType.values.firstWhere(
      (type) => type.toString().split('.').last == value,
      orElse: () => VehicleType.fourWheeler,
    );
  }
}