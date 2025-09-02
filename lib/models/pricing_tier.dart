class PricingTier {
  final int startHour;
  final int? endHour; // null means no limit
  final double ratePerHour;
  final String displayName;

  PricingTier({
    required this.startHour,
    this.endHour,
    required this.ratePerHour,
    required this.displayName,
  });

  bool isApplicableFor(Duration duration) {
    final hours = duration.inHours;
    if (endHour == null) {
      return hours >= startHour;
    }
    return hours >= startHour && hours < endHour!;
  }

  Map<String, dynamic> toJson() {
    return {
      'startHour': startHour,
      'endHour': endHour,
      'ratePerHour': ratePerHour,
      'displayName': displayName,
    };
  }

  factory PricingTier.fromJson(Map<String, dynamic> json) {
    return PricingTier(
      startHour: json['startHour'],
      endHour: json['endHour'],
      ratePerHour: json['ratePerHour'].toDouble(),
      displayName: json['displayName'],
    );
  }

  PricingTier copyWith({
    int? startHour,
    int? endHour,
    double? ratePerHour,
    String? displayName,
  }) {
    return PricingTier(
      startHour: startHour ?? this.startHour,
      endHour: endHour ?? this.endHour,
      ratePerHour: ratePerHour ?? this.ratePerHour,
      displayName: displayName ?? this.displayName,
    );
  }
}