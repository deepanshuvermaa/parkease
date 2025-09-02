import 'package:intl/intl.dart';
import '../models/vehicle.dart';
import '../models/business_settings.dart';
import '../models/enhanced_business_settings.dart';
import '../models/print_customization.dart';
import '../models/parking_charges.dart';

class ESCPOSCommands {
  static String get INIT => String.fromCharCode(27) + String.fromCharCode(64);
  static String get ALIGN_CENTER => String.fromCharCode(27) + String.fromCharCode(97) + String.fromCharCode(1);
  static String get ALIGN_LEFT => String.fromCharCode(27) + String.fromCharCode(97) + String.fromCharCode(0);
  static String get ALIGN_RIGHT => String.fromCharCode(27) + String.fromCharCode(97) + String.fromCharCode(2);
  static String get BOLD_ON => String.fromCharCode(27) + String.fromCharCode(69) + String.fromCharCode(1);
  static String get BOLD_OFF => String.fromCharCode(27) + String.fromCharCode(69) + String.fromCharCode(0);
  static String get FONT_SIZE_NORMAL => String.fromCharCode(29) + String.fromCharCode(33) + String.fromCharCode(0);
  static String get FONT_SIZE_MEDIUM => String.fromCharCode(29) + String.fromCharCode(33) + String.fromCharCode(16);
  static String get FONT_SIZE_LARGE => String.fromCharCode(29) + String.fromCharCode(33) + String.fromCharCode(17);
  static String get FONT_SIZE_XLARGE => String.fromCharCode(29) + String.fromCharCode(33) + String.fromCharCode(34);
  static String get FONT_SIZE_XXLARGE => String.fromCharCode(29) + String.fromCharCode(33) + String.fromCharCode(51);
  static String get CUT_PAPER => String.fromCharCode(29) + String.fromCharCode(86) + String.fromCharCode(0);
  static String get NEW_LINE => '\n';
  static String get DOUBLE_LINE => '=' * 32 + NEW_LINE;
  static String get SINGLE_LINE => '-' * 32 + NEW_LINE;
  
  // Get font size command based on custom size setting
  static String getFontSize(double size) {
    if (size <= 12) return FONT_SIZE_NORMAL;
    if (size <= 16) return FONT_SIZE_MEDIUM;
    if (size <= 24) return FONT_SIZE_LARGE;
    if (size <= 32) return FONT_SIZE_XLARGE;
    return FONT_SIZE_XXLARGE;
  }
  
  static String generateQRCode(String data) {
    String qr = '';
    
    // QR Code function 165: Set QR code model
    qr += String.fromCharCode(29) + String.fromCharCode(40) + String.fromCharCode(107);
    qr += String.fromCharCode(4) + String.fromCharCode(0); // pL pH (data length)
    qr += String.fromCharCode(49) + String.fromCharCode(65); // cn fn
    qr += String.fromCharCode(50) + String.fromCharCode(0); // model = 2
    
    // QR Code function 167: Set QR code size
    qr += String.fromCharCode(29) + String.fromCharCode(40) + String.fromCharCode(107);
    qr += String.fromCharCode(3) + String.fromCharCode(0); // pL pH
    qr += String.fromCharCode(49) + String.fromCharCode(67); // cn fn
    qr += String.fromCharCode(4); // size = 4
    
    // QR Code function 169: Set QR code error correction level
    qr += String.fromCharCode(29) + String.fromCharCode(40) + String.fromCharCode(107);
    qr += String.fromCharCode(3) + String.fromCharCode(0); // pL pH
    qr += String.fromCharCode(49) + String.fromCharCode(69); // cn fn
    qr += String.fromCharCode(48); // error correction level = L (7%)
    
    // QR Code function 180: Store QR code data
    int dataLen = data.length + 3;
    qr += String.fromCharCode(29) + String.fromCharCode(40) + String.fromCharCode(107);
    qr += String.fromCharCode(dataLen % 256) + String.fromCharCode(dataLen ~/ 256); // pL pH
    qr += String.fromCharCode(49) + String.fromCharCode(80); // cn fn
    qr += String.fromCharCode(48); // m = 0
    qr += data;
    
    // QR Code function 181: Print QR code
    qr += String.fromCharCode(29) + String.fromCharCode(40) + String.fromCharCode(107);
    qr += String.fromCharCode(3) + String.fromCharCode(0); // pL pH
    qr += String.fromCharCode(49) + String.fromCharCode(81); // cn fn
    qr += String.fromCharCode(48); // m = 0
    
    return qr;
  }

  static String formatReceipt(Vehicle vehicle, BusinessSettings settings) {
    // Get print customization settings if available
    PrintCustomization? printCustom;
    ParkingCharges? parkingCharges;
    
    if (settings is EnhancedBusinessSettings) {
      printCustom = settings.printCustomization;
      parkingCharges = settings.parkingCharges;
    }
    printCustom ??= PrintCustomization();
    
    String receipt = INIT;
    
    // Business Header
    receipt += printCustom.centerAlign ? ALIGN_CENTER : ALIGN_LEFT;
    receipt += getFontSize(printCustom.businessNameSize);
    if (printCustom.boldBusinessName) receipt += BOLD_ON;
    receipt += settings.businessName + NEW_LINE;
    if (printCustom.boldBusinessName) receipt += BOLD_OFF;
    
    receipt += getFontSize(printCustom.addressSize);
    receipt += settings.address + NEW_LINE;
    receipt += settings.city + NEW_LINE;
    if (settings.showContactOnReceipt) {
      receipt += 'Mob: ${settings.contactNumber}' + NEW_LINE;
    }
    
    if (printCustom.printDashedLine) receipt += DOUBLE_LINE;
    
    // Receipt Type Header
    receipt += getFontSize(printCustom.labelSize);
    receipt += BOLD_ON;
    receipt += vehicle.exitTime == null ? 'PARKING RECEIPT' : 'PAYMENT RECEIPT';
    receipt += NEW_LINE;
    receipt += BOLD_OFF;
    
    // Ticket ID - LARGE AND PROMINENT
    receipt += getFontSize(printCustom.ticketIdSize);
    if (printCustom.boldTicketId) receipt += BOLD_ON;
    receipt += 'Ticket ID: ${vehicle.ticketId}' + NEW_LINE;
    if (printCustom.boldTicketId) receipt += BOLD_OFF;
    
    if (printCustom.printDashedLine) receipt += SINGLE_LINE;
    
    // Vehicle Details
    receipt += ALIGN_LEFT;
    receipt += getFontSize(printCustom.labelSize);
    receipt += 'Vehicle No: ';
    receipt += getFontSize(printCustom.valueSize);
    receipt += vehicle.vehicleNumber + NEW_LINE;
    
    receipt += getFontSize(printCustom.labelSize);
    receipt += 'Vehicle Type: ';
    receipt += getFontSize(printCustom.valueSize);
    receipt += vehicle.vehicleType.displayName + NEW_LINE;
    
    // Rate display based on parking charges settings
    receipt += getFontSize(printCustom.labelSize);
    receipt += 'Rate: ';
    receipt += getFontSize(printCustom.valueSize);
    
    if (parkingCharges != null) {
      final rate = parkingCharges.getVehicleRate(vehicle.vehicleType.displayName);
      switch (parkingCharges.chargeType) {
        case ChargeType.oneTime:
          receipt += 'Rs.${rate.toStringAsFixed(0)} (One Time)';
          break;
        case ChargeType.hourly:
          final duration = parkingCharges.timeUnitDuration;
          final unitName = parkingCharges.timeUnit.shortName;
          receipt += 'Rs.${rate.toStringAsFixed(0)}/$duration$unitName';
          break;
        case ChargeType.perDay:
          receipt += 'Rs.${rate.toStringAsFixed(0)}/day';
          break;
        case ChargeType.custom:
          receipt += 'Rs.${rate.toStringAsFixed(0)}';
          break;
      }
    } else {
      receipt += 'Rs.${vehicle.rate.toStringAsFixed(0)}/hr';
    }
    receipt += NEW_LINE;
    
    // Entry Time
    receipt += getFontSize(printCustom.labelSize);
    receipt += 'Entry Time: ';
    receipt += getFontSize(printCustom.valueSize);
    receipt += DateFormat('dd-MMM-yy hh:mm a').format(vehicle.entryTime) + NEW_LINE;
    
    // Exit details if available
    if (vehicle.exitTime != null) {
      if (printCustom.printDashedLine) receipt += SINGLE_LINE;
      
      receipt += getFontSize(printCustom.labelSize);
      receipt += 'Exit Time: ';
      receipt += getFontSize(printCustom.valueSize);
      receipt += DateFormat('dd-MMM-yy hh:mm a').format(vehicle.exitTime!) + NEW_LINE;
      
      receipt += getFontSize(printCustom.labelSize);
      receipt += 'Duration: ';
      receipt += getFontSize(printCustom.valueSize);
      receipt += _formatDuration(vehicle.parkingDuration) + NEW_LINE;
      
      if (printCustom.printDashedLine) receipt += SINGLE_LINE;
      
      // Total Amount - LARGE
      receipt += getFontSize(printCustom.totalLabelSize);
      if (printCustom.boldTotal) receipt += BOLD_ON;
      receipt += 'TOTAL AMOUNT: ';
      receipt += getFontSize(printCustom.totalValueSize);
      receipt += 'Rs.${vehicle.totalAmount?.toStringAsFixed(0) ?? vehicle.calculateAmount().toStringAsFixed(0)}' + NEW_LINE;
      if (printCustom.boldTotal) receipt += BOLD_OFF;
      
      if (vehicle.isPaid) {
        receipt += ALIGN_CENTER;
        receipt += getFontSize(printCustom.labelSize);
        receipt += '*** PAID ***' + NEW_LINE;
      }
    }
    
    // Footer
    if (printCustom.printDashedLine) receipt += SINGLE_LINE;
    
    receipt += printCustom.centerAlign ? ALIGN_CENTER : ALIGN_LEFT;
    receipt += getFontSize(printCustom.footerSize);
    
    // Custom footer message
    String footerMessage = 'Thank you for choosing us!';
    if (settings is EnhancedBusinessSettings && settings.receiptFooter.isNotEmpty) {
      footerMessage = settings.receiptFooter;
    }
    receipt += footerMessage + NEW_LINE;
    
    // MANDATORY POWERED BY FOOTER - NON-CHANGEABLE
    receipt += getFontSize(printCustom.poweredBySize);
    receipt += ALIGN_CENTER;
    receipt += 'Powered by Go2 Billing Softwares' + NEW_LINE;
    
    // Date/Time stamp
    receipt += getFontSize(10);
    receipt += DateFormat('dd-MMM-yyyy hh:mm a').format(DateTime.now()) + NEW_LINE;
    
    // Add QR code if enabled
    if (settings.showQrCode) {
      String qrData = 'TICKET:${vehicle.ticketId}|VEHICLE:${vehicle.vehicleNumber}|ENTRY:${vehicle.entryTime.toIso8601String()}';
      receipt += generateQRCode(qrData);
    }
    
    // Paper cut
    receipt += NEW_LINE + NEW_LINE + NEW_LINE;
    receipt += CUT_PAPER;
    
    return receipt;
  }
  
  static String _formatDuration(Duration duration) {
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '$hours hr ${minutes} min';
    } else {
      return '$minutes min';
    }
  }
  
  static String formatTestReceipt(BusinessSettings settings) {
    String receipt = INIT;
    
    receipt += ALIGN_CENTER;
    receipt += FONT_SIZE_LARGE;
    receipt += BOLD_ON;
    receipt += 'TEST PRINT' + NEW_LINE;
    receipt += BOLD_OFF;
    receipt += DOUBLE_LINE;
    
    receipt += FONT_SIZE_NORMAL;
    receipt += settings.businessName + NEW_LINE;
    receipt += settings.address + NEW_LINE;
    receipt += settings.city + NEW_LINE;
    
    receipt += SINGLE_LINE;
    receipt += 'This is a test receipt' + NEW_LINE;
    receipt += 'to verify printer connection' + NEW_LINE;
    receipt += SINGLE_LINE;
    
    receipt += 'Font Sizes Test:' + NEW_LINE;
    receipt += FONT_SIZE_NORMAL + 'Normal Size' + NEW_LINE;
    receipt += FONT_SIZE_MEDIUM + 'Medium Size' + NEW_LINE;
    receipt += FONT_SIZE_LARGE + 'Large Size' + NEW_LINE;
    receipt += FONT_SIZE_XLARGE + 'XLarge Size' + NEW_LINE;
    
    receipt += FONT_SIZE_NORMAL;
    receipt += SINGLE_LINE;
    receipt += 'Alignment Test:' + NEW_LINE;
    receipt += ALIGN_LEFT + 'Left Aligned' + NEW_LINE;
    receipt += ALIGN_CENTER + 'Center Aligned' + NEW_LINE;
    receipt += ALIGN_RIGHT + 'Right Aligned' + NEW_LINE;
    
    receipt += ALIGN_CENTER;
    receipt += DOUBLE_LINE;
    receipt += 'Test Successful!' + NEW_LINE;
    receipt += DateFormat('dd-MMM-yyyy hh:mm a').format(DateTime.now()) + NEW_LINE;
    
    receipt += SINGLE_LINE;
    receipt += FONT_SIZE_NORMAL;
    receipt += 'Powered by Go2 Billing Softwares' + NEW_LINE;
    
    receipt += NEW_LINE + NEW_LINE + NEW_LINE;
    receipt += CUT_PAPER;
    
    return receipt;
  }
}