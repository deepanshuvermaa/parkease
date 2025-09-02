enum ChargeType {
  oneTime,
  hourly,
  perDay,
  custom,
}

enum TimeUnit {
  minute,
  hour,
  day,
  week,
}

extension TimeUnitExtension on TimeUnit {
  String get displayName {
    switch (this) {
      case TimeUnit.minute:
        return 'Minute';
      case TimeUnit.hour:
        return 'Hour';
      case TimeUnit.day:
        return 'Day';
      case TimeUnit.week:
        return 'Week';
    }
  }
  
  String get shortName {
    switch (this) {
      case TimeUnit.minute:
        return 'min';
      case TimeUnit.hour:
        return 'hr';
      case TimeUnit.day:
        return 'day';
      case TimeUnit.week:
        return 'week';
    }
  }
  
  int get minuteMultiplier {
    switch (this) {
      case TimeUnit.minute:
        return 1;
      case TimeUnit.hour:
        return 60;
      case TimeUnit.day:
        return 1440; // 60 * 24
      case TimeUnit.week:
        return 10080; // 60 * 24 * 7
    }
  }
}

extension ChargeTypeExtension on ChargeType {
  String get displayName {
    switch (this) {
      case ChargeType.oneTime:
        return 'One Time';
      case ChargeType.hourly:
        return 'Time Based';
      case ChargeType.perDay:
        return 'Per Day';
      case ChargeType.custom:
        return 'Custom';
    }
  }

  String get description {
    switch (this) {
      case ChargeType.oneTime:
        return 'Charge once,\ngood for single-use parking.';
      case ChargeType.hourly:
        return 'Charge by time unit,\nideal for flexible parking.';
      case ChargeType.perDay:
        return 'Charge daily,\nbest for long-duration parking.';
      case ChargeType.custom:
        return 'Set your own rates,\nperfect for flexible pricing.';
    }
  }
}

class VehicleRate {
  final String vehicleType;
  final String icon;
  final int capacity;
  final double rate;
  final bool isEnabled;

  VehicleRate({
    required this.vehicleType,
    required this.icon,
    required this.capacity,
    required this.rate,
    this.isEnabled = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'vehicleType': vehicleType,
      'icon': icon,
      'capacity': capacity,
      'rate': rate,
      'isEnabled': isEnabled,
    };
  }

  factory VehicleRate.fromJson(Map<String, dynamic> json) {
    return VehicleRate(
      vehicleType: json['vehicleType'],
      icon: json['icon'],
      capacity: json['capacity'] ?? 0,
      rate: (json['rate'] ?? 0).toDouble(),
      isEnabled: json['isEnabled'] ?? true,
    );
  }

  VehicleRate copyWith({
    String? vehicleType,
    String? icon,
    int? capacity,
    double? rate,
    bool? isEnabled,
  }) {
    return VehicleRate(
      vehicleType: vehicleType ?? this.vehicleType,
      icon: icon ?? this.icon,
      capacity: capacity ?? this.capacity,
      rate: rate ?? this.rate,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

class ParkingCharges {
  final ChargeType chargeType;
  final List<VehicleRate> vehicleRates;
  final TimeUnit timeUnit;
  final int timeUnitDuration; // Number of time units to charge for
  final bool captureVehicleNumber;
  final bool captureOwnerName;
  final bool capturePhoneNumber;
  final int minimumChargeMinutes; // Minimum time before charging starts

  ParkingCharges({
    this.chargeType = ChargeType.oneTime,
    List<VehicleRate>? vehicleRates,
    this.timeUnit = TimeUnit.hour,
    this.timeUnitDuration = 1,
    this.captureVehicleNumber = true,
    this.captureOwnerName = false,
    this.capturePhoneNumber = false,
    this.minimumChargeMinutes = 30,
  }) : vehicleRates = vehicleRates ?? _getDefaultVehicleRates();

  static List<VehicleRate> _getDefaultVehicleRates() {
    return [
      VehicleRate(
        vehicleType: 'Cycle',
        icon: '🚲',
        capacity: 200,
        rate: 20,
      ),
      VehicleRate(
        vehicleType: 'Bike',
        icon: '🏍️',
        capacity: 100,
        rate: 40,
      ),
      VehicleRate(
        vehicleType: 'Car',
        icon: '🚗',
        capacity: 25,
        rate: 50,
      ),
      VehicleRate(
        vehicleType: 'Auto',
        icon: '🛺',
        capacity: 25,
        rate: 50,
      ),
      VehicleRate(
        vehicleType: 'E-Rickshaw',
        icon: '🚐',
        capacity: 50,
        rate: 30,
      ),
      VehicleRate(
        vehicleType: 'Bus',
        icon: '🚌',
        capacity: 5,
        rate: 100,
      ),
      VehicleRate(
        vehicleType: 'Truck',
        icon: '🚚',
        capacity: 5,
        rate: 100,
      ),
    ];
  }

  Map<String, dynamic> toJson() {
    return {
      'chargeType': chargeType.index,
      'vehicleRates': vehicleRates.map((rate) => rate.toJson()).toList(),
      'timeUnit': timeUnit.index,
      'timeUnitDuration': timeUnitDuration,
      'captureVehicleNumber': captureVehicleNumber,
      'captureOwnerName': captureOwnerName,
      'capturePhoneNumber': capturePhoneNumber,
      'minimumChargeMinutes': minimumChargeMinutes,
    };
  }

  factory ParkingCharges.fromJson(Map<String, dynamic> json) {
    return ParkingCharges(
      chargeType: ChargeType.values[json['chargeType'] ?? 0],
      vehicleRates: json['vehicleRates'] != null
          ? (json['vehicleRates'] as List)
              .map((rate) => VehicleRate.fromJson(rate))
              .toList()
          : null,
      timeUnit: TimeUnit.values[json['timeUnit'] ?? 1],
      timeUnitDuration: json['timeUnitDuration'] ?? 1,
      captureVehicleNumber: json['captureVehicleNumber'] ?? true,
      captureOwnerName: json['captureOwnerName'] ?? false,
      capturePhoneNumber: json['capturePhoneNumber'] ?? false,
      minimumChargeMinutes: json['minimumChargeMinutes'] ?? 30,
    );
  }

  ParkingCharges copyWith({
    ChargeType? chargeType,
    List<VehicleRate>? vehicleRates,
    TimeUnit? timeUnit,
    int? timeUnitDuration,
    bool? captureVehicleNumber,
    bool? captureOwnerName,
    bool? capturePhoneNumber,
    int? minimumChargeMinutes,
  }) {
    return ParkingCharges(
      chargeType: chargeType ?? this.chargeType,
      vehicleRates: vehicleRates ?? this.vehicleRates,
      timeUnit: timeUnit ?? this.timeUnit,
      timeUnitDuration: timeUnitDuration ?? this.timeUnitDuration,
      captureVehicleNumber: captureVehicleNumber ?? this.captureVehicleNumber,
      captureOwnerName: captureOwnerName ?? this.captureOwnerName,
      capturePhoneNumber: capturePhoneNumber ?? this.capturePhoneNumber,
      minimumChargeMinutes: minimumChargeMinutes ?? this.minimumChargeMinutes,
    );
  }

  String getRateDisplayText(double rate) {
    switch (chargeType) {
      case ChargeType.oneTime:
        return 'One Time';
      case ChargeType.hourly:
        final duration = timeUnitDuration;
        final unitName = timeUnit.displayName.toLowerCase();
        return 'per $duration $unitName${duration > 1 ? 's' : ''}';
      case ChargeType.perDay:
        return 'per day';
      case ChargeType.custom:
        return 'custom rate';
    }
  }

  double getVehicleRate(String vehicleType) {
    // Normalize the vehicle type for comparison
    String normalizedType = vehicleType.toLowerCase().trim();
    
    // Handle special cases for vehicle type matching
    if (normalizedType == 'two wheeler' || normalizedType == 'twowheeler') {
      normalizedType = 'bike';
    } else if (normalizedType == 'four wheeler' || normalizedType == 'fourwheeler') {
      normalizedType = 'car';
    }
    
    // Find the rate for the vehicle type
    final rate = vehicleRates.firstWhere(
      (r) => r.vehicleType.toLowerCase() == normalizedType && r.isEnabled,
      orElse: () => vehicleRates.firstWhere(
        (r) => r.vehicleType.toLowerCase().contains(normalizedType) && r.isEnabled,
        orElse: () => VehicleRate(
          vehicleType: vehicleType,
          icon: '🚗',
          capacity: 0,
          rate: 50,
        ),
      ),
    );
    
    return rate.rate;
  }

  double calculateCharge(String vehicleType, Duration parkingDuration) {
    // Normalize the vehicle type for comparison
    String normalizedType = vehicleType.toLowerCase().trim();
    
    // Handle special cases for vehicle type matching
    if (normalizedType == 'two wheeler' || normalizedType == 'twowheeler') {
      normalizedType = 'bike';
    } else if (normalizedType == 'four wheeler' || normalizedType == 'fourwheeler') {
      normalizedType = 'car';
    }
    
    // Find the rate for the vehicle type
    VehicleRate? rate = vehicleRates.firstWhere(
      (r) => r.vehicleType.toLowerCase() == normalizedType && r.isEnabled,
      orElse: () => vehicleRates.firstWhere(
        (r) => r.vehicleType.toLowerCase().contains(normalizedType) && r.isEnabled,
        orElse: () => VehicleRate(
          vehicleType: vehicleType,
          icon: '🚗',
          capacity: 0,
          rate: 50,
        ),
      ),
    );

    // Apply grace period - if parking duration is less than grace period, don't charge
    if (parkingDuration.inMinutes <= minimumChargeMinutes) {
      return 0;
    }

    switch (chargeType) {
      case ChargeType.oneTime:
        // Fixed one-time charge regardless of duration
        return rate.rate;
        
      case ChargeType.hourly:
        // Time-based charging
        final totalMinutes = parkingDuration.inMinutes;
        final unitMinutes = timeUnit.minuteMultiplier * timeUnitDuration;
        
        // Calculate how many units have been used (always round up)
        final unitsUsed = (totalMinutes / unitMinutes).ceil();
        
        // Minimum charge is for 1 unit
        return rate.rate * (unitsUsed > 0 ? unitsUsed : 1);
        
      case ChargeType.perDay:
        // Daily charging
        final days = (parkingDuration.inHours / 24).ceil();
        return rate.rate * (days > 0 ? days : 1);
        
      case ChargeType.custom:
        // Custom logic - for now, just charge the base rate
        return rate.rate;
    }
  }
}