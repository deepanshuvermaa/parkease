import 'pricing_tier.dart';

class CustomVehicleType {
  final String id;
  final String name;
  final String displayName;
  final String icon;
  final List<PricingTier> pricingTiers;
  final bool isActive;
  final int sortOrder;
  final bool requiresVehicleNumber;

  CustomVehicleType({
    required this.id,
    required this.name,
    required this.displayName,
    required this.icon,
    required this.pricingTiers,
    this.isActive = true,
    this.sortOrder = 0,
    this.requiresVehicleNumber = true, // Default to true for all except cycle
  });

  double calculateAmount(Duration duration) {
    // Find applicable tier
    final applicableTier = pricingTiers.firstWhere(
      (tier) => tier.isApplicableFor(duration),
      orElse: () => pricingTiers.last, // Use last tier as fallback
    );

    final hours = (duration.inMinutes / 60).ceil();
    return hours * applicableTier.ratePerHour;
  }

  String get currentRateDisplay {
    if (pricingTiers.isEmpty) return 'Rs.0';
    if (pricingTiers.length == 1) {
      return 'Rs.${pricingTiers.first.ratePerHour.toStringAsFixed(0)}/hr';
    }
    return 'Rs.${pricingTiers.first.ratePerHour.toStringAsFixed(0)}+ /hr';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'displayName': displayName,
      'icon': icon,
      'pricingTiers': pricingTiers.map((tier) => tier.toJson()).toList(),
      'isActive': isActive,
      'sortOrder': sortOrder,
      'requiresVehicleNumber': requiresVehicleNumber,
    };
  }

  factory CustomVehicleType.fromJson(Map<String, dynamic> json) {
    return CustomVehicleType(
      id: json['id'],
      name: json['name'],
      displayName: json['displayName'],
      icon: json['icon'],
      pricingTiers: (json['pricingTiers'] as List)
          .map((tier) => PricingTier.fromJson(tier))
          .toList(),
      isActive: json['isActive'] ?? true,
      sortOrder: json['sortOrder'] ?? 0,
      requiresVehicleNumber: json['requiresVehicleNumber'] ?? true,
    );
  }

  CustomVehicleType copyWith({
    String? id,
    String? name,
    String? displayName,
    String? icon,
    List<PricingTier>? pricingTiers,
    bool? isActive,
    int? sortOrder,
    bool? requiresVehicleNumber,
  }) {
    return CustomVehicleType(
      id: id ?? this.id,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      icon: icon ?? this.icon,
      pricingTiers: pricingTiers ?? this.pricingTiers,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      requiresVehicleNumber: requiresVehicleNumber ?? this.requiresVehicleNumber,
    );
  }
}

// Default vehicle types for backward compatibility
class DefaultVehicleTypes {
  static List<CustomVehicleType> getDefaults() {
    return [
      CustomVehicleType(
        id: 'cycle',
        name: 'cycle',
        displayName: 'Cycle',
        icon: '🚲',
        pricingTiers: [
          PricingTier(
            startHour: 0,
            endHour: null,
            ratePerHour: 20.0,
            displayName: 'Standard Rate',
          ),
        ],
        sortOrder: 1,
        requiresVehicleNumber: false, // Cycles don't require vehicle number
      ),
      CustomVehicleType(
        id: 'twoWheeler',
        name: 'twoWheeler',
        displayName: 'Two Wheeler',
        icon: '🏍️',
        pricingTiers: [
          PricingTier(
            startHour: 0,
            endHour: 2,
            ratePerHour: 30.0,
            displayName: 'First 2 Hours',
          ),
          PricingTier(
            startHour: 2,
            endHour: null,
            ratePerHour: 25.0,
            displayName: 'After 2 Hours',
          ),
        ],
        sortOrder: 2,
      ),
      CustomVehicleType(
        id: 'fourWheeler',
        name: 'fourWheeler',
        displayName: 'Four Wheeler',
        icon: '🚗',
        pricingTiers: [
          PricingTier(
            startHour: 0,
            endHour: 2,
            ratePerHour: 50.0,
            displayName: 'First 2 Hours',
          ),
          PricingTier(
            startHour: 2,
            endHour: 6,
            ratePerHour: 40.0,
            displayName: '2-6 Hours',
          ),
          PricingTier(
            startHour: 6,
            endHour: null,
            ratePerHour: 35.0,
            displayName: 'After 6 Hours',
          ),
        ],
        sortOrder: 3,
      ),
      CustomVehicleType(
        id: 'auto',
        name: 'auto',
        displayName: 'Auto',
        icon: '🛺',
        pricingTiers: [
          PricingTier(
            startHour: 0,
            endHour: null,
            ratePerHour: 40.0,
            displayName: 'Standard Rate',
          ),
        ],
        sortOrder: 4,
      ),
    ];
  }
}