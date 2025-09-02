import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/vehicle.dart';
import '../models/enhanced_business_settings.dart';
import '../models/business_settings.dart' as bs;
import '../utils/helpers.dart';

class PdfExportService {
  static Future<File> generateParkingReport({
    required List<Vehicle> vehicles,
    required EnhancedBusinessSettings settings,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final pdf = pw.Document();

    // Calculate summary data
    final totalVehicles = vehicles.length;
    final totalCollection = vehicles.fold<double>(
      0.0,
      (sum, vehicle) => sum + (vehicle.totalAmount ?? 0.0),
    );
    
    final vehicleTypeStats = <String, Map<String, dynamic>>{};
    for (final vehicle in vehicles) {
      final typeName = vehicle.vehicleType.displayName;
      if (vehicleTypeStats.containsKey(typeName)) {
        vehicleTypeStats[typeName]!['count'] += 1;
        vehicleTypeStats[typeName]!['amount'] += vehicle.totalAmount ?? 0.0;
      } else {
        vehicleTypeStats[typeName] = {
          'count': 1,
          'amount': vehicle.totalAmount ?? 0.0,
        };
      }
    }

    // Add cover page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.blue,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      settings.businessName,
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      '${settings.address}, ${settings.city}',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.white,
                      ),
                    ),
                    if (settings.showContactOnReceipt)
                      pw.Text(
                        'Contact: ${settings.contactNumber}',
                        style: const pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.white,
                        ),
                      ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 30),
              
              // Report title
              pw.Text(
                'PARKING REPORT',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              
              pw.SizedBox(height: 10),
              
              // Date range
              pw.Text(
                'Period: ${DateFormat('dd MMM yyyy').format(fromDate)} to ${DateFormat('dd MMM yyyy').format(toDate)}',
                style: const pw.TextStyle(fontSize: 14),
              ),
              
              pw.SizedBox(height: 20),
              
              // Summary cards
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSummaryCard('Total Vehicles', totalVehicles.toString()),
                  _buildSummaryCard('Total Collection', Helpers.formatCurrency(totalCollection)),
                  _buildSummaryCard('Average per Vehicle', 
                    totalVehicles > 0 
                        ? Helpers.formatCurrency(totalCollection / totalVehicles)
                        : 'Rs.0.00'),
                ],
              ),
              
              pw.SizedBox(height: 30),
              
              // Vehicle type breakdown
              pw.Text(
                'Vehicle Type Breakdown',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              
              pw.SizedBox(height: 15),
              
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                children: [
                  // Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _buildTableCell('Vehicle Type', isHeader: true),
                      _buildTableCell('Count', isHeader: true),
                      _buildTableCell('Amount', isHeader: true),
                      _buildTableCell('Average', isHeader: true),
                    ],
                  ),
                  // Data rows
                  ...vehicleTypeStats.entries.map((entry) {
                    final count = entry.value['count'] as int;
                    final amount = entry.value['amount'] as double;
                    final average = count > 0 ? amount / count : 0.0;
                    
                    return pw.TableRow(
                      children: [
                        _buildTableCell(entry.key),
                        _buildTableCell(count.toString()),
                        _buildTableCell(Helpers.formatCurrency(amount)),
                        _buildTableCell(Helpers.formatCurrency(average)),
                      ],
                    );
                  }),
                ],
              ),
              
              pw.Spacer(),
              
              // Footer
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Generated on: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      'ParkEase Manager - Parking Management System',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    // Add detailed transactions page
    if (vehicles.isNotEmpty) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Detailed Transactions',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                
                pw.SizedBox(height: 15),
                
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  columnWidths: {
                    0: const pw.FixedColumnWidth(80),
                    1: const pw.FixedColumnWidth(70),
                    2: const pw.FixedColumnWidth(80),
                    3: const pw.FixedColumnWidth(80),
                    4: const pw.FixedColumnWidth(60),
                    5: const pw.FixedColumnWidth(70),
                  },
                  children: [
                    // Header
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        _buildTableCell('Vehicle No.', isHeader: true),
                        _buildTableCell('Type', isHeader: true),
                        _buildTableCell('Entry Time', isHeader: true),
                        _buildTableCell('Exit Time', isHeader: true),
                        _buildTableCell('Duration', isHeader: true),
                        _buildTableCell('Amount', isHeader: true),
                      ],
                    ),
                    // Data rows
                    ...vehicles.take(50).map((vehicle) { // Limit to 50 for first page
                      return pw.TableRow(
                        children: [
                          _buildTableCell(vehicle.vehicleNumber),
                          _buildTableCell(vehicle.vehicleType.displayName),
                          _buildTableCell(
                            DateFormat('dd/MM hh:mm').format(vehicle.entryTime),
                          ),
                          _buildTableCell(
                            vehicle.exitTime != null
                                ? DateFormat('dd/MM hh:mm').format(vehicle.exitTime!)
                                : 'Active',
                          ),
                          _buildTableCell(
                            vehicle.exitTime != null
                                ? Helpers.formatDuration(vehicle.parkingDuration)
                                : '-',
                          ),
                          _buildTableCell(
                            Helpers.formatCurrency(vehicle.totalAmount ?? 0.0),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
                
                if (vehicles.length > 50)
                  pw.Container(
                    margin: const pw.EdgeInsets.only(top: 20),
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      border: pw.Border.all(color: PdfColors.grey400),
                    ),
                    child: pw.Text(
                      'Note: Only first 50 transactions are shown. Total transactions: ${vehicles.length}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ),
              ],
            );
          },
        ),
      );
    }

    // Save the PDF
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'parking_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
    final file = File('${directory.path}/$fileName');
    
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Container _buildSummaryCard(String title, String value) {
    return pw.Container(
      width: 120,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            title,
            style: const pw.TextStyle(fontSize: 10),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  static pw.Padding _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static Future<void> shareReport(File pdfFile, String reportTitle) async {
    await Share.shareXFiles(
      [XFile(pdfFile.path)],
      text: reportTitle,
    );
  }

  static Future<void> printReport(File pdfFile) async {
    // This would require a printer plugin like printing package
    // For now, we'll just share the file
    await shareReport(pdfFile, 'Parking Report');
  }

  static Future<File> generateVehicleReceipt({
    required Vehicle vehicle,
    required EnhancedBusinessSettings settings,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          settings.paperSize == bs.PaperSize.mm58 ? 58 * PdfPageFormat.mm : 80 * PdfPageFormat.mm,
          200 * PdfPageFormat.mm,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Business header
              pw.Text(
                settings.businessName,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
              
              pw.Text(
                settings.address,
                style: const pw.TextStyle(fontSize: 8),
                textAlign: pw.TextAlign.center,
              ),
              
              pw.Text(
                settings.city,
                style: const pw.TextStyle(fontSize: 8),
                textAlign: pw.TextAlign.center,
              ),
              
              if (settings.showContactOnReceipt)
                pw.Text(
                  'Mob: ${settings.contactNumber}',
                  style: const pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
              
              pw.Container(
                margin: const pw.EdgeInsets.symmetric(vertical: 8),
                child: pw.Text('=' * 32),
              ),
              
              // Ticket ID
              pw.Text(
                vehicle.ticketId,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              
              pw.SizedBox(height: 8),
              
              // Vehicle details
              _buildReceiptRow('V. Number:', vehicle.vehicleNumber),
              _buildReceiptRow('V. Type:', vehicle.vehicleType.displayName),
              _buildReceiptRow('Rate:', 'Rs.${vehicle.rate.toStringAsFixed(0)}/-'),
              _buildReceiptRow(
                'Entry:', 
                DateFormat('dd-MMM-yy hh:mm a').format(vehicle.entryTime),
              ),
              
              if (vehicle.exitTime != null) ...[
                _buildReceiptRow(
                  'Exit:', 
                  DateFormat('dd-MMM-yy hh:mm a').format(vehicle.exitTime!),
                ),
                _buildReceiptRow(
                  'Duration:', 
                  Helpers.formatDuration(vehicle.parkingDuration),
                ),
                
                pw.Container(
                  margin: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Text('-' * 32),
                ),
                
                pw.Container(
                  padding: const pw.EdgeInsets.all(4),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(),
                  ),
                  child: pw.Text(
                    'Payable: Rs.${vehicle.totalAmount?.toStringAsFixed(0) ?? vehicle.calculateAmount().toStringAsFixed(0)}/-',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
              
              pw.Container(
                margin: const pw.EdgeInsets.symmetric(vertical: 8),
                child: pw.Text('=' * 32),
              ),
              
              pw.Text(
                settings.receiptFooter,
                style: const pw.TextStyle(fontSize: 8),
                textAlign: pw.TextAlign.center,
              ),
              
              pw.SizedBox(height: 4),
              
              pw.Text(
                DateFormat('dd-MMM-yyyy hh:mm a').format(DateTime.now()),
                style: const pw.TextStyle(fontSize: 6),
              ),
            ],
          );
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'receipt_${vehicle.ticketId}.pdf';
    final file = File('${directory.path}/$fileName');
    
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Row _buildReceiptRow(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
        pw.Text(value, style: const pw.TextStyle(fontSize: 8)),
      ],
    );
  }
}