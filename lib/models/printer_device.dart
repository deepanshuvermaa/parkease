class PrinterDevice {
  final String id;
  final String name;
  final String address;
  final bool isConnected;
  final bool isBonded;
  final bool isDefault;
  final int? rssi; // Signal strength

  PrinterDevice({
    required this.id,
    required this.name,
    required this.address,
    this.isConnected = false,
    this.isBonded = false,
    this.isDefault = false,
    this.rssi,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'isConnected': isConnected,
      'isBonded': isBonded,
      'isDefault': isDefault,
      'rssi': rssi,
    };
  }

  factory PrinterDevice.fromJson(Map<String, dynamic> json) {
    return PrinterDevice(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      isConnected: json['isConnected'] ?? false,
      isBonded: json['isBonded'] ?? false,
      isDefault: json['isDefault'] ?? false,
      rssi: json['rssi'],
    );
  }

  PrinterDevice copyWith({
    String? id,
    String? name,
    String? address,
    bool? isConnected,
    bool? isBonded,
    bool? isDefault,
    int? rssi,
  }) {
    return PrinterDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      isConnected: isConnected ?? this.isConnected,
      isBonded: isBonded ?? this.isBonded,
      isDefault: isDefault ?? this.isDefault,
      rssi: rssi ?? this.rssi,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PrinterDevice && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}