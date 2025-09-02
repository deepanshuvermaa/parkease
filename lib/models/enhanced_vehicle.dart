import 'vehicle_type.dart';
import 'custom_vehicle_type.dart';

class EnhancedVehicle {
  final String id;
  final String vehicleNumber;
  final VehicleType? legacyVehicleType; // For backward compatibility
  final CustomVehicleType? customVehicleType; // New enhanced type
  final DateTime entryTime;
  DateTime? exitTime;
  final double rate;
  double? totalAmount;
  bool isPaid;
  final String ticketId;

  EnhancedVehicle({
    required this.id,
    required this.vehicleNumber,
    this.legacyVehicleType,
    this.customVehicleType,
    required this.entryTime,
    this.exitTime,
    required this.rate,
    this.totalAmount,
    this.isPaid = false,
    required this.ticketId,
  }) : assert(legacyVehicleType != null || customVehicleType != null,
            'Either legacyVehicleType or customVehicleType must be provided');

  // Getter for vehicle type display name
  String get vehicleTypeDisplayName {
    if (customVehicleType != null) {
      return customVehicleType!.displayName;
    }
    return legacyVehicleType!.displayName;
  }

  // Getter for vehicle type icon
  String get vehicleTypeIcon {
    if (customVehicleType != null) {
      return customVehicleType!.icon;
    }
    return legacyVehicleType!.icon;
  }

  Duration get parkingDuration {
    final end = exitTime ?? DateTime.now();
    return end.difference(entryTime);
  }

  double calculateAmount() {
    if (customVehicleType != null) {
      return customVehicleType!.calculateAmount(parkingDuration);
    }
    
    // Fallback to simple calculation for legacy types
    if (exitTime == null) {
      final duration = DateTime.now().difference(entryTime);
      final hours = (duration.inMinutes / 60).ceil();
      return hours * rate;
    }
    final duration = exitTime!.difference(entryTime);
    final hours = (duration.inMinutes / 60).ceil();
    return hours * rate;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleNumber': vehicleNumber,
      'legacyVehicleType': legacyVehicleType?.toString().split('.').last,
      'customVehicleType': customVehicleType?.toJson(),
      'entryTime': entryTime.toIso8601String(),
      'exitTime': exitTime?.toIso8601String(),
      'rate': rate,
      'totalAmount': totalAmount,
      'isPaid': isPaid,
      'ticketId': ticketId,
    };
  }

  factory EnhancedVehicle.fromJson(Map<String, dynamic> json) {
    return EnhancedVehicle(
      id: json['id'],
      vehicleNumber: json['vehicleNumber'],
      legacyVehicleType: json['legacyVehicleType'] != null
          ? VehicleType.fromString(json['legacyVehicleType'])
          : null,
      customVehicleType: json['customVehicleType'] != null
          ? CustomVehicleType.fromJson(json['customVehicleType'])
          : null,
      entryTime: DateTime.parse(json['entryTime']),
      exitTime: json['exitTime'] != null ? DateTime.parse(json['exitTime']) : null,
      rate: json['rate'].toDouble(),
      totalAmount: json['totalAmount']?.toDouble(),
      isPaid: json['isPaid'] ?? false,
      ticketId: json['ticketId'],
    );
  }

  EnhancedVehicle copyWith({
    String? id,
    String? vehicleNumber,
    VehicleType? legacyVehicleType,
    CustomVehicleType? customVehicleType,
    DateTime? entryTime,
    DateTime? exitTime,
    double? rate,
    double? totalAmount,
    bool? isPaid,
    String? ticketId,
  }) {
    return EnhancedVehicle(
      id: id ?? this.id,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      legacyVehicleType: legacyVehicleType ?? this.legacyVehicleType,
      customVehicleType: customVehicleType ?? this.customVehicleType,
      entryTime: entryTime ?? this.entryTime,
      exitTime: exitTime ?? this.exitTime,
      rate: rate ?? this.rate,
      totalAmount: totalAmount ?? this.totalAmount,
      isPaid: isPaid ?? this.isPaid,
      ticketId: ticketId ?? this.ticketId,
    );
  }

  // Convert to legacy Vehicle for backward compatibility
  Vehicle toLegacyVehicle() {
    VehicleType vehicleType;
    if (legacyVehicleType != null) {
      vehicleType = legacyVehicleType!;
    } else if (customVehicleType != null) {
      // Map custom type to legacy type based on name
      switch (customVehicleType!.name.toLowerCase()) {
        case 'cycle':
          vehicleType = VehicleType.cycle;
          break;
        case 'twowheeler':
          vehicleType = VehicleType.twoWheeler;
          break;
        case 'fourwheeler':
          vehicleType = VehicleType.fourWheeler;
          break;
        case 'auto':
          vehicleType = VehicleType.auto;
          break;
        default:
          vehicleType = VehicleType.fourWheeler; // Default fallback
      }
    } else {
      vehicleType = VehicleType.fourWheeler; // Default fallback
    }

    return Vehicle(
      id: id,
      vehicleNumber: vehicleNumber,
      vehicleType: vehicleType,
      entryTime: entryTime,
      exitTime: exitTime,
      rate: rate,
      totalAmount: totalAmount,
      isPaid: isPaid,
      ticketId: ticketId,
    );
  }

  // Create from CustomVehicleType
  factory EnhancedVehicle.fromCustomType({
    required String vehicleNumber,
    required CustomVehicleType vehicleType,
    required DateTime entryTime,
    required String ticketId,
  }) {
    return EnhancedVehicle(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      vehicleNumber: vehicleNumber,
      customVehicleType: vehicleType,
      entryTime: entryTime,
      rate: vehicleType.pricingTiers.first.ratePerHour,
      ticketId: ticketId,
    );
  }
}

// Import the original Vehicle class
import 'vehicle.dart';