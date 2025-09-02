class PrintCustomization {
  // Font sizes for different receipt elements
  final double businessNameSize;
  final double addressSize;
  final double ticketIdSize;
  final double labelSize;        // For labels like "Vehicle:", "Entry Time:", etc.
  final double valueSize;        // For values like vehicle number, time, etc.
  final double totalLabelSize;   // For "Total Amount:" label
  final double totalValueSize;   // For the total amount value
  final double footerSize;       // For thank you message
  final double poweredBySize;    // For powered by text
  
  // Additional settings
  final bool boldBusinessName;
  final bool boldTicketId;
  final bool boldTotal;
  final bool centerAlign;
  final bool printDashedLine;
  final int paperWidth; // 58mm or 80mm
  
  PrintCustomization({
    this.businessNameSize = 24,
    this.addressSize = 14,
    this.ticketIdSize = 28,     // Large size for visibility
    this.labelSize = 14,
    this.valueSize = 16,
    this.totalLabelSize = 18,
    this.totalValueSize = 22,
    this.footerSize = 14,
    this.poweredBySize = 12,
    this.boldBusinessName = true,
    this.boldTicketId = true,
    this.boldTotal = true,
    this.centerAlign = true,
    this.printDashedLine = true,
    this.paperWidth = 58,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'businessNameSize': businessNameSize,
      'addressSize': addressSize,
      'ticketIdSize': ticketIdSize,
      'labelSize': labelSize,
      'valueSize': valueSize,
      'totalLabelSize': totalLabelSize,
      'totalValueSize': totalValueSize,
      'footerSize': footerSize,
      'poweredBySize': poweredBySize,
      'boldBusinessName': boldBusinessName,
      'boldTicketId': boldTicketId,
      'boldTotal': boldTotal,
      'centerAlign': centerAlign,
      'printDashedLine': printDashedLine,
      'paperWidth': paperWidth,
    };
  }
  
  factory PrintCustomization.fromJson(Map<String, dynamic> json) {
    return PrintCustomization(
      businessNameSize: (json['businessNameSize'] ?? 24).toDouble(),
      addressSize: (json['addressSize'] ?? 14).toDouble(),
      ticketIdSize: (json['ticketIdSize'] ?? 28).toDouble(),
      labelSize: (json['labelSize'] ?? 14).toDouble(),
      valueSize: (json['valueSize'] ?? 16).toDouble(),
      totalLabelSize: (json['totalLabelSize'] ?? 18).toDouble(),
      totalValueSize: (json['totalValueSize'] ?? 22).toDouble(),
      footerSize: (json['footerSize'] ?? 14).toDouble(),
      poweredBySize: (json['poweredBySize'] ?? 12).toDouble(),
      boldBusinessName: json['boldBusinessName'] ?? true,
      boldTicketId: json['boldTicketId'] ?? true,
      boldTotal: json['boldTotal'] ?? true,
      centerAlign: json['centerAlign'] ?? true,
      printDashedLine: json['printDashedLine'] ?? true,
      paperWidth: json['paperWidth'] ?? 58,
    );
  }
  
  PrintCustomization copyWith({
    double? businessNameSize,
    double? addressSize,
    double? ticketIdSize,
    double? labelSize,
    double? valueSize,
    double? totalLabelSize,
    double? totalValueSize,
    double? footerSize,
    double? poweredBySize,
    bool? boldBusinessName,
    bool? boldTicketId,
    bool? boldTotal,
    bool? centerAlign,
    bool? printDashedLine,
    int? paperWidth,
  }) {
    return PrintCustomization(
      businessNameSize: businessNameSize ?? this.businessNameSize,
      addressSize: addressSize ?? this.addressSize,
      ticketIdSize: ticketIdSize ?? this.ticketIdSize,
      labelSize: labelSize ?? this.labelSize,
      valueSize: valueSize ?? this.valueSize,
      totalLabelSize: totalLabelSize ?? this.totalLabelSize,
      totalValueSize: totalValueSize ?? this.totalValueSize,
      footerSize: footerSize ?? this.footerSize,
      poweredBySize: poweredBySize ?? this.poweredBySize,
      boldBusinessName: boldBusinessName ?? this.boldBusinessName,
      boldTicketId: boldTicketId ?? this.boldTicketId,
      boldTotal: boldTotal ?? this.boldTotal,
      centerAlign: centerAlign ?? this.centerAlign,
      printDashedLine: printDashedLine ?? this.printDashedLine,
      paperWidth: paperWidth ?? this.paperWidth,
    );
  }
  
  // Helper method to get font style based on size and bold setting
  String getFontCommand(double size, bool bold) {
    // ESC/POS commands for font size
    // These will be used in the receipt generation
    final normalizedSize = size.clamp(8, 48);
    
    if (normalizedSize <= 14) {
      return bold ? '\x1B\x21\x08' : '\x1B\x21\x00'; // Small
    } else if (normalizedSize <= 20) {
      return bold ? '\x1B\x21\x18' : '\x1B\x21\x10'; // Medium
    } else if (normalizedSize <= 28) {
      return bold ? '\x1B\x21\x38' : '\x1B\x21\x30'; // Large
    } else {
      return bold ? '\x1B\x21\x78' : '\x1B\x21\x70'; // Extra Large
    }
  }
}