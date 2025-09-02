import 'custom_vehicle_type.dart';
import 'business_settings.dart';
import 'parking_charges.dart';
import 'ticket_id_settings.dart';
import 'print_customization.dart';

class VehicleNumberConfig {
  final String stateCode;
  final String stateName;
  final bool isEnabled;
  final List<String> districtCodes;
  
  VehicleNumberConfig({
    required this.stateCode,
    required this.stateName,
    this.isEnabled = true,
    this.districtCodes = const [],
  });

  String get displayFormat => '$stateCode-##-##-####';

  Map<String, dynamic> toJson() {
    return {
      'stateCode': stateCode,
      'stateName': stateName,
      'isEnabled': isEnabled,
      'districtCodes': districtCodes,
    };
  }

  factory VehicleNumberConfig.fromJson(Map<String, dynamic> json) {
    return VehicleNumberConfig(
      stateCode: json['stateCode'],
      stateName: json['stateName'],
      isEnabled: json['isEnabled'] ?? true,
      districtCodes: List<String>.from(json['districtCodes'] ?? []),
    );
  }

  VehicleNumberConfig copyWith({
    String? stateCode,
    String? stateName,
    bool? isEnabled,
    List<String>? districtCodes,
  }) {
    return VehicleNumberConfig(
      stateCode: stateCode ?? this.stateCode,
      stateName: stateName ?? this.stateName,
      isEnabled: isEnabled ?? this.isEnabled,
      districtCodes: districtCodes ?? this.districtCodes,
    );
  }
}

class EnhancedBusinessSettings extends BusinessSettings {
  final VehicleNumberConfig? vehicleNumberConfig;
  final List<CustomVehicleType> customVehicleTypes;
  final int minimumParkingMinutes;
  final bool enableGracePeriod;
  final int gracePeriodMinutes;
  final String receiptFooter;
  final String? logoPath;
  final ParkingCharges parkingCharges;
  final TicketIdSettings ticketIdSettings;
  final PrintCustomization printCustomization;

  EnhancedBusinessSettings({
    required String businessName,
    required String address,
    required String city,
    required String contactNumber,
    bool showContactOnReceipt = true,
    PaperSize paperSize = PaperSize.mm58,
    bool autoPrint = false,
    String? primaryPrinterId,
    bool showQrCode = false,
    this.vehicleNumberConfig,
    List<CustomVehicleType>? customVehicleTypes,
    this.minimumParkingMinutes = 30,
    this.enableGracePeriod = true,
    this.gracePeriodMinutes = 15,
    this.receiptFooter = 'Thank you for choosing us!',
    this.logoPath,
    ParkingCharges? parkingCharges,
    TicketIdSettings? ticketIdSettings,
    PrintCustomization? printCustomization,
  }) : customVehicleTypes = customVehicleTypes ?? DefaultVehicleTypes.getDefaults(),
       parkingCharges = parkingCharges ?? ParkingCharges(),
       ticketIdSettings = ticketIdSettings ?? TicketIdSettings(),
       printCustomization = printCustomization ?? PrintCustomization(),
       super(
         businessName: businessName,
         address: address,
         city: city,
         contactNumber: contactNumber,
         showContactOnReceipt: showContactOnReceipt,
         paperSize: paperSize,
         autoPrint: autoPrint,
         primaryPrinterId: primaryPrinterId,
         showQrCode: showQrCode,
       );

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'vehicleNumberConfig': vehicleNumberConfig?.toJson(),
      'customVehicleTypes': customVehicleTypes.map((type) => type.toJson()).toList(),
      'minimumParkingMinutes': minimumParkingMinutes,
      'enableGracePeriod': enableGracePeriod,
      'gracePeriodMinutes': gracePeriodMinutes,
      'receiptFooter': receiptFooter,
      'logoPath': logoPath,
      'parkingCharges': parkingCharges.toJson(),
      'ticketIdSettings': ticketIdSettings.toJson(),
      'printCustomization': printCustomization.toJson(),
    });
    return json;
  }

  factory EnhancedBusinessSettings.fromJson(Map<String, dynamic> json) {
    return EnhancedBusinessSettings(
      businessName: json['businessName'] ?? 'ParkEase Parking',
      address: json['address'] ?? 'Main Street',
      city: json['city'] ?? 'City',
      contactNumber: json['contactNumber'] ?? '1234567890',
      showContactOnReceipt: json['showContactOnReceipt'] ?? true,
      paperSize: json['paperSize'] != null
          ? PaperSize.values.firstWhere(
              (size) => size.toString().split('.').last == json['paperSize'],
              orElse: () => PaperSize.mm58,
            )
          : PaperSize.mm58,
      autoPrint: json['autoPrint'] ?? false,
      primaryPrinterId: json['primaryPrinterId'],
      vehicleNumberConfig: json['vehicleNumberConfig'] != null
          ? VehicleNumberConfig.fromJson(json['vehicleNumberConfig'])
          : null,
      customVehicleTypes: json['customVehicleTypes'] != null
          ? (json['customVehicleTypes'] as List)
              .map((type) => CustomVehicleType.fromJson(type))
              .toList()
          : null,
      minimumParkingMinutes: json['minimumParkingMinutes'] ?? 30,
      enableGracePeriod: json['enableGracePeriod'] ?? true,
      gracePeriodMinutes: json['gracePeriodMinutes'] ?? 15,
      receiptFooter: json['receiptFooter'] ?? 'Thank you for choosing us!',
      showQrCode: json['showQrCode'] ?? false,
      logoPath: json['logoPath'],
      parkingCharges: json['parkingCharges'] != null
          ? ParkingCharges.fromJson(json['parkingCharges'])
          : null,
      ticketIdSettings: json['ticketIdSettings'] != null
          ? TicketIdSettings.fromJson(json['ticketIdSettings'])
          : null,
      printCustomization: json['printCustomization'] != null
          ? PrintCustomization.fromJson(json['printCustomization'])
          : null,
    );
  }

  factory EnhancedBusinessSettings.defaultSettings() {
    return EnhancedBusinessSettings(
      businessName: 'ParkEase Parking',
      address: 'Main Street',
      city: 'City',
      contactNumber: '1234567890',
      showContactOnReceipt: true,
      paperSize: PaperSize.mm58,
      autoPrint: false,
      minimumParkingMinutes: 30,
      enableGracePeriod: true,
      gracePeriodMinutes: 15,
      receiptFooter: 'Thank you for choosing us!',
      showQrCode: false,
      parkingCharges: ParkingCharges(
        chargeType: ChargeType.hourly,
        timeUnit: TimeUnit.hour,
        timeUnitDuration: 1,
        minimumChargeMinutes: 30,
      ),
    );
  }

  EnhancedBusinessSettings copyWith({
    String? businessName,
    String? address,
    String? city,
    String? contactNumber,
    bool? showContactOnReceipt,
    PaperSize? paperSize,
    bool? autoPrint,
    String? primaryPrinterId,
    VehicleNumberConfig? vehicleNumberConfig,
    List<CustomVehicleType>? customVehicleTypes,
    int? minimumParkingMinutes,
    bool? enableGracePeriod,
    int? gracePeriodMinutes,
    String? receiptFooter,
    bool? showQrCode,
    String? logoPath,
    ParkingCharges? parkingCharges,
    TicketIdSettings? ticketIdSettings,
    PrintCustomization? printCustomization,
  }) {
    return EnhancedBusinessSettings(
      businessName: businessName ?? this.businessName,
      address: address ?? this.address,
      city: city ?? this.city,
      contactNumber: contactNumber ?? this.contactNumber,
      showContactOnReceipt: showContactOnReceipt ?? this.showContactOnReceipt,
      paperSize: paperSize ?? this.paperSize,
      autoPrint: autoPrint ?? this.autoPrint,
      primaryPrinterId: primaryPrinterId ?? this.primaryPrinterId,
      vehicleNumberConfig: vehicleNumberConfig ?? this.vehicleNumberConfig,
      customVehicleTypes: customVehicleTypes ?? this.customVehicleTypes,
      minimumParkingMinutes: minimumParkingMinutes ?? this.minimumParkingMinutes,
      enableGracePeriod: enableGracePeriod ?? this.enableGracePeriod,
      gracePeriodMinutes: gracePeriodMinutes ?? this.gracePeriodMinutes,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      showQrCode: showQrCode ?? this.showQrCode,
      logoPath: logoPath ?? this.logoPath,
      parkingCharges: parkingCharges ?? this.parkingCharges,
      ticketIdSettings: ticketIdSettings ?? this.ticketIdSettings,
      printCustomization: printCustomization ?? this.printCustomization,
    );
  }
}

// Indian state codes for vehicle registration
class IndianStateCodes {
  static final Map<String, String> stateCodes = {
    'AP': 'Andhra Pradesh',
    'AR': 'Arunachal Pradesh',
    'AS': 'Assam',
    'BR': 'Bihar',
    'CG': 'Chhattisgarh',
    'GA': 'Goa',
    'GJ': 'Gujarat',
    'HR': 'Haryana',
    'HP': 'Himachal Pradesh',
    'JH': 'Jharkhand',
    'KA': 'Karnataka',
    'KL': 'Kerala',
    'MP': 'Madhya Pradesh',
    'MH': 'Maharashtra',
    'MN': 'Manipur',
    'ML': 'Meghalaya',
    'MZ': 'Mizoram',
    'NL': 'Nagaland',
    'OD': 'Odisha',
    'PB': 'Punjab',
    'RJ': 'Rajasthan',
    'SK': 'Sikkim',
    'TN': 'Tamil Nadu',
    'TG': 'Telangana',
    'TR': 'Tripura',
    'UP': 'Uttar Pradesh',
    'UR': 'Uttarakhand',
    'WB': 'West Bengal',
    'AN': 'Andaman and Nicobar Islands',
    'CH': 'Chandigarh',
    'DL': 'Delhi',
    'JK': 'Jammu and Kashmir',
    'LA': 'Ladakh',
    'LD': 'Lakshadweep',
    'PY': 'Puducherry',
  };

  static List<VehicleNumberConfig> getConfigs() {
    return stateCodes.entries.map((entry) {
      return VehicleNumberConfig(
        stateCode: entry.key,
        stateName: entry.value,
        isEnabled: false,
      );
    }).toList();
  }
}