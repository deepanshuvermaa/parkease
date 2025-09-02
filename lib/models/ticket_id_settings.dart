enum TicketIdFormat {
  simple,      // T001, T002, T003...
  dateTime,    // T20250102-1234
  alphanumeric,// TKT-AB1234
  custom,      // User defined pattern
}

extension TicketIdFormatExtension on TicketIdFormat {
  String get displayName {
    switch (this) {
      case TicketIdFormat.simple:
        return 'Simple Sequential';
      case TicketIdFormat.dateTime:
        return 'Date & Time Based';
      case TicketIdFormat.alphanumeric:
        return 'Alphanumeric';
      case TicketIdFormat.custom:
        return 'Custom Pattern';
    }
  }
  
  String get description {
    switch (this) {
      case TicketIdFormat.simple:
        return 'T001, T002, T003...';
      case TicketIdFormat.dateTime:
        return 'T20250102-1234';
      case TicketIdFormat.alphanumeric:
        return 'TKT-AB1234';
      case TicketIdFormat.custom:
        return 'Define your own pattern';
    }
  }
  
  String get defaultPattern {
    switch (this) {
      case TicketIdFormat.simple:
        return 'T{SEQ:4}';
      case TicketIdFormat.dateTime:
        return 'T{YYYYMMDD}-{SEQ:4}';
      case TicketIdFormat.alphanumeric:
        return 'TKT-{RAND:2A}{SEQ:4}';
      case TicketIdFormat.custom:
        return '{PREFIX}-{YYYY}{MM}{DD}-{SEQ:4}';
    }
  }
}

class TicketIdSettings {
  final TicketIdFormat format;
  final String customPattern;
  final String prefix;
  final int sequenceCounter;
  final bool resetDaily;
  final bool includeLocation;
  
  TicketIdSettings({
    this.format = TicketIdFormat.dateTime,
    this.customPattern = '',
    this.prefix = 'T',
    this.sequenceCounter = 1,
    this.resetDaily = true,
    this.includeLocation = false,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'format': format.index,
      'customPattern': customPattern,
      'prefix': prefix,
      'sequenceCounter': sequenceCounter,
      'resetDaily': resetDaily,
      'includeLocation': includeLocation,
    };
  }
  
  factory TicketIdSettings.fromJson(Map<String, dynamic> json) {
    return TicketIdSettings(
      format: TicketIdFormat.values[json['format'] ?? 1],
      customPattern: json['customPattern'] ?? '',
      prefix: json['prefix'] ?? 'T',
      sequenceCounter: json['sequenceCounter'] ?? 1,
      resetDaily: json['resetDaily'] ?? true,
      includeLocation: json['includeLocation'] ?? false,
    );
  }
  
  TicketIdSettings copyWith({
    TicketIdFormat? format,
    String? customPattern,
    String? prefix,
    int? sequenceCounter,
    bool? resetDaily,
    bool? includeLocation,
  }) {
    return TicketIdSettings(
      format: format ?? this.format,
      customPattern: customPattern ?? this.customPattern,
      prefix: prefix ?? this.prefix,
      sequenceCounter: sequenceCounter ?? this.sequenceCounter,
      resetDaily: resetDaily ?? this.resetDaily,
      includeLocation: includeLocation ?? this.includeLocation,
    );
  }
}