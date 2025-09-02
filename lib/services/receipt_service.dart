import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/vehicle.dart';
import '../models/business_settings.dart';
import '../utils/helpers.dart';

class ReceiptService {
  static final ReceiptService _instance = ReceiptService._internal();
  factory ReceiptService() => _instance;
  ReceiptService._internal();

  /// Generate receipt text for sharing
  String generateReceiptText(Vehicle vehicle, BusinessSettings settings) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln(settings.businessName.toUpperCase());
    if (settings.address.isNotEmpty) {
      buffer.writeln(settings.address);
    }
    if (settings.city.isNotEmpty) {
      buffer.writeln(settings.city);
    }
    if (settings.showContactOnReceipt && settings.contactNumber.isNotEmpty) {
      buffer.writeln('Phone: ${settings.contactNumber}');
    }
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━');
    
    // Receipt Type
    if (vehicle.exitTime == null) {
      buffer.writeln('PARKING RECEIPT');
    } else {
      buffer.writeln('PAYMENT RECEIPT');
    }
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━');
    
    // Vehicle Details
    buffer.writeln('Ticket ID: ${vehicle.ticketId}');
    buffer.writeln('Vehicle No: ${vehicle.vehicleNumber.toUpperCase()}');
    buffer.writeln('Vehicle Type: ${vehicle.vehicleType.displayName}');
    buffer.writeln('Rate: ₹${vehicle.rate.toStringAsFixed(0)}/-');
    buffer.writeln('Entry: ${DateFormat('dd-MMM-yy hh:mm a').format(vehicle.entryTime)}');
    
    // Exit details if available
    if (vehicle.exitTime != null) {
      buffer.writeln('Exit: ${DateFormat('dd-MMM-yy hh:mm a').format(vehicle.exitTime!)}');
      buffer.writeln('Duration: ${Helpers.formatDuration(vehicle.parkingDuration)}');
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━');
      
      final amount = vehicle.totalAmount ?? vehicle.calculateAmount();
      buffer.writeln('TOTAL AMOUNT: ₹${amount.toStringAsFixed(0)}/-');
      buffer.writeln('Payment: ${vehicle.isPaid ? "PAID" : "PENDING"}');
    }
    
    // Footer
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━');
    if (settings.receiptNote.isNotEmpty) {
      buffer.writeln(settings.receiptNote);
    } else {
      buffer.writeln('Thank you for parking!');
    }
    buffer.writeln('Printed: ${DateFormat('dd-MMM-yyyy hh:mm a').format(DateTime.now())}');
    
    return buffer.toString();
  }

  /// Generate PDF receipt
  Future<File> generatePdfReceipt(Vehicle vehicle, BusinessSettings settings) async {
    final pdf = pw.Document();
    
    // Create PDF content
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a7, // Small receipt size
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(10),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Business Header
                pw.Text(
                  settings.businessName.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (settings.address.isNotEmpty)
                  pw.Text(
                    settings.address,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                if (settings.city.isNotEmpty)
                  pw.Text(
                    settings.city,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                if (settings.showContactOnReceipt && settings.contactNumber.isNotEmpty)
                  pw.Text(
                    'Phone: ${settings.contactNumber}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                
                pw.SizedBox(height: 10),
                pw.Divider(),
                
                // Receipt Type
                pw.Text(
                  vehicle.exitTime == null ? 'PARKING RECEIPT' : 'PAYMENT RECEIPT',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                
                pw.Divider(),
                pw.SizedBox(height: 5),
                
                // Vehicle Details
                _buildPdfRow('Ticket ID:', vehicle.ticketId),
                _buildPdfRow('Vehicle No:', vehicle.vehicleNumber.toUpperCase()),
                _buildPdfRow('Type:', vehicle.vehicleType.displayName),
                _buildPdfRow('Rate:', '₹${vehicle.rate.toStringAsFixed(0)}/-'),
                _buildPdfRow('Entry:', DateFormat('dd-MMM hh:mm a').format(vehicle.entryTime)),
                
                // Exit details if available
                if (vehicle.exitTime != null) ...[
                  _buildPdfRow('Exit:', DateFormat('dd-MMM hh:mm a').format(vehicle.exitTime!)),
                  _buildPdfRow('Duration:', Helpers.formatDuration(vehicle.parkingDuration)),
                  pw.Divider(),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 5),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'TOTAL:',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          '₹${(vehicle.totalAmount ?? vehicle.calculateAmount()).toStringAsFixed(0)}/-',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildPdfRow('Payment:', vehicle.isPaid ? 'PAID' : 'PENDING'),
                ],
                
                pw.SizedBox(height: 10),
                pw.Divider(),
                
                // Footer
                pw.Text(
                  settings.receiptNote.isNotEmpty 
                      ? settings.receiptNote 
                      : 'Thank you for parking!',
                  style: const pw.TextStyle(fontSize: 10),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  DateFormat('dd-MMM-yyyy hh:mm a').format(DateTime.now()),
                  style: const pw.TextStyle(fontSize: 8),
                ),
                
                // QR Code (optional)
                if (settings.showQrCode) ...[
                  pw.SizedBox(height: 10),
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: vehicle.ticketId,
                    width: 60,
                    height: 60,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );

    // Save PDF to temporary file
    final output = await getTemporaryDirectory();
    final fileName = 'receipt_${vehicle.ticketId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }

  pw.Widget _buildPdfRow(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
          pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  /// Share receipt as text
  Future<void> shareAsText(Vehicle vehicle, BusinessSettings settings) async {
    final text = generateReceiptText(vehicle, settings);
    await Share.share(
      text,
      subject: 'Parking Receipt - ${vehicle.ticketId}',
    );
  }

  /// Share receipt as PDF
  Future<void> shareAsPdf(Vehicle vehicle, BusinessSettings settings) async {
    try {
      final pdfFile = await generatePdfReceipt(vehicle, settings);
      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        subject: 'Parking Receipt - ${vehicle.ticketId}',
        text: 'Parking receipt for vehicle ${vehicle.vehicleNumber}',
      );
    } catch (e) {
      debugPrint('Error sharing PDF: $e');
      // Fallback to text sharing
      await shareAsText(vehicle, settings);
    }
  }

  /// Show share options dialog
  Future<void> showShareOptions(
    BuildContext context,
    Vehicle vehicle,
    BusinessSettings settings,
  ) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Share Receipt As',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.text_fields, color: Colors.blue),
                title: const Text('Text Message'),
                subtitle: const Text('Share as plain text'),
                onTap: () => Navigator.pop(context, 'text'),
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('PDF Document'),
                subtitle: const Text('Share as PDF file'),
                onTap: () => Navigator.pop(context, 'pdf'),
              ),
              ListTile(
                leading: const Icon(Icons.copy, color: Colors.green),
                title: const Text('Copy to Clipboard'),
                subtitle: const Text('Copy receipt text'),
                onTap: () => Navigator.pop(context, 'copy'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (result != null && context.mounted) {
      switch (result) {
        case 'text':
          await shareAsText(vehicle, settings);
          break;
        case 'pdf':
          await shareAsPdf(vehicle, settings);
          break;
        case 'copy':
          await _copyToClipboard(context, vehicle, settings);
          break;
      }
    }
  }

  Future<void> _copyToClipboard(
    BuildContext context,
    Vehicle vehicle,
    BusinessSettings settings,
  ) async {
    final text = generateReceiptText(vehicle, settings);
    await Clipboard.setData(ClipboardData(text: text));
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Receipt copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

// Add this import at the top
import 'package:flutter/services.dart';