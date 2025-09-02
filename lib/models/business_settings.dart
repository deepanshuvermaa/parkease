enum PaperSize {
  mm58,
  mm80;

  String get displayName {
    switch (this) {
      case PaperSize.mm58:
        return '58mm';
      case PaperSize.mm80:
        return '80mm';
    }
  }

  int get width {
    switch (this) {
      case PaperSize.mm58:
        return 32;
      case PaperSize.mm80:
        return 48;
    }
  }
}

class BusinessSettings {
  final String businessName;
  final String address;
  final String city;
  final String contactNumber;
  final bool showContactOnReceipt;
  final PaperSize paperSize;
  final bool autoPrint;
  final String? primaryPrinterId;
  final bool showQrCode;

  BusinessSettings({
    required this.businessName,
    required this.address,
    required this.city,
    required this.contactNumber,
    this.showContactOnReceipt = true,
    this.paperSize = PaperSize.mm58,
    this.autoPrint = false,
    this.primaryPrinterId,
    this.showQrCode = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'businessName': businessName,
      'address': address,
      'city': city,
      'contactNumber': contactNumber,
      'showContactOnReceipt': showContactOnReceipt,
      'paperSize': paperSize.toString().split('.').last,
      'autoPrint': autoPrint,
      'primaryPrinterId': primaryPrinterId,
      'showQrCode': showQrCode,
    };
  }

  factory BusinessSettings.fromJson(Map<String, dynamic> json) {
    return BusinessSettings(
      businessName: json['businessName'],
      address: json['address'],
      city: json['city'],
      contactNumber: json['contactNumber'],
      showContactOnReceipt: json['showContactOnReceipt'] ?? true,
      paperSize: json['paperSize'] != null
          ? PaperSize.values.firstWhere(
              (size) => size.toString().split('.').last == json['paperSize'],
              orElse: () => PaperSize.mm58,
            )
          : PaperSize.mm58,
      autoPrint: json['autoPrint'] ?? false,
      primaryPrinterId: json['primaryPrinterId'],
      showQrCode: json['showQrCode'] ?? false,
    );
  }

  factory BusinessSettings.defaultSettings() {
    return BusinessSettings(
      businessName: 'ParkEase Parking',
      address: 'Main Street',
      city: 'City',
      contactNumber: '1234567890',
      showContactOnReceipt: true,
      paperSize: PaperSize.mm58,
      autoPrint: false,
    );
  }

  BusinessSettings copyWith({
    String? businessName,
    String? address,
    String? city,
    String? contactNumber,
    bool? showContactOnReceipt,
    PaperSize? paperSize,
    bool? autoPrint,
    String? primaryPrinterId,
    bool? showQrCode,
  }) {
    return BusinessSettings(
      businessName: businessName ?? this.businessName,
      address: address ?? this.address,
      city: city ?? this.city,
      contactNumber: contactNumber ?? this.contactNumber,
      showContactOnReceipt: showContactOnReceipt ?? this.showContactOnReceipt,
      paperSize: paperSize ?? this.paperSize,
      autoPrint: autoPrint ?? this.autoPrint,
      primaryPrinterId: primaryPrinterId ?? this.primaryPrinterId,
      showQrCode: showQrCode ?? this.showQrCode,
    );
  }
}