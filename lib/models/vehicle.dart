import 'vehicle_type.dart';

class Vehicle {
  final String id;
  final String vehicleNumber;
  final VehicleType vehicleType;
  final DateTime entryTime;
  DateTime? exitTime;
  final double rate;
  double? totalAmount;
  bool isPaid;
  final String ticketId;

  Vehicle({
    required this.id,
    required this.vehicleNumber,
    required this.vehicleType,
    required this.entryTime,
    this.exitTime,
    required this.rate,
    this.totalAmount,
    this.isPaid = false,
    required this.ticketId,
  });

  Duration get parkingDuration {
    final end = exitTime ?? DateTime.now();
    return end.difference(entryTime);
  }

  double calculateAmount() {
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
      'vehicleType': vehicleType.toString().split('.').last,
      'entryTime': entryTime.toIso8601String(),
      'exitTime': exitTime?.toIso8601String(),
      'rate': rate,
      'totalAmount': totalAmount,
      'isPaid': isPaid,
      'ticketId': ticketId,
    };
  }

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      vehicleNumber: json['vehicleNumber'],
      vehicleType: VehicleType.fromString(json['vehicleType']),
      entryTime: DateTime.parse(json['entryTime']),
      exitTime: json['exitTime'] != null ? DateTime.parse(json['exitTime']) : null,
      rate: json['rate'].toDouble(),
      totalAmount: json['totalAmount']?.toDouble(),
      isPaid: json['isPaid'] ?? false,
      ticketId: json['ticketId'],
    );
  }

  Vehicle copyWith({
    String? id,
    String? vehicleNumber,
    VehicleType? vehicleType,
    DateTime? entryTime,
    DateTime? exitTime,
    double? rate,
    double? totalAmount,
    bool? isPaid,
    String? ticketId,
  }) {
    return Vehicle(
      id: id ?? this.id,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      vehicleType: vehicleType ?? this.vehicleType,
      entryTime: entryTime ?? this.entryTime,
      exitTime: exitTime ?? this.exitTime,
      rate: rate ?? this.rate,
      totalAmount: totalAmount ?? this.totalAmount,
      isPaid: isPaid ?? this.isPaid,
      ticketId: ticketId ?? this.ticketId,
    );
  }
}