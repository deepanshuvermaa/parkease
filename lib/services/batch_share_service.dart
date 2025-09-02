import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/vehicle.dart';
import '../models/business_settings.dart';
import '../utils/helpers.dart';

class BatchShareService {
  static final BatchShareService _instance = BatchShareService._internal();
  factory BatchShareService() => _instance;
  BatchShareService._internal();

  /// Generate batch report as text
  String generateBatchText(
    List<Vehicle> vehicles,
    BusinessSettings settings,
    String reportTitle,
  ) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('════════════════════════════════');
    buffer.writeln(settings.businessName.toUpperCase());
    buffer.writeln(reportTitle);
    buffer.writeln('Generated: ${DateFormat('dd-MMM-yyyy hh:mm a').format(DateTime.now())}');
    buffer.writeln('════════════════════════════════');
    buffer.writeln();
    
    // Summary
    final activeVehicles = vehicles.where((v) => v.exitTime == null).toList();
    final completedVehicles = vehicles.where((v) => v.exitTime != null).toList();
    double totalRevenue = 0;
    
    for (var vehicle in completedVehicles) {
      totalRevenue += vehicle.totalAmount ?? vehicle.calculateAmount();
    }
    
    buffer.writeln('SUMMARY');
    buffer.writeln('─────────────────────────────');
    buffer.writeln('Total Vehicles: ${vehicles.length}');
    buffer.writeln('Active: ${activeVehicles.length}');
    buffer.writeln('Completed: ${completedVehicles.length}');
    buffer.writeln('Total Revenue: ₹${totalRevenue.toStringAsFixed(0)}');
    buffer.writeln();
    
    // Active Vehicles
    if (activeVehicles.isNotEmpty) {
      buffer.writeln('ACTIVE VEHICLES (${activeVehicles.length})');
      buffer.writeln('─────────────────────────────');
      for (var vehicle in activeVehicles) {
        buffer.writeln('${vehicle.vehicleNumber} | ${vehicle.vehicleType.displayName}');
        buffer.writeln('Entry: ${DateFormat('dd-MMM hh:mm a').format(vehicle.entryTime)}');
        buffer.writeln('Duration: ${Helpers.formatDuration(vehicle.parkingDuration)}');
        buffer.writeln('─────────────────────────────');
      }
      buffer.writeln();
    }
    
    // Completed Vehicles
    if (completedVehicles.isNotEmpty) {
      buffer.writeln('COMPLETED VEHICLES (${completedVehicles.length})');
      buffer.writeln('─────────────────────────────');
      for (var vehicle in completedVehicles) {
        buffer.writeln('${vehicle.vehicleNumber} | ${vehicle.vehicleType.displayName}');
        buffer.writeln('Entry: ${DateFormat('dd-MMM hh:mm a').format(vehicle.entryTime)}');
        buffer.writeln('Exit: ${DateFormat('dd-MMM hh:mm a').format(vehicle.exitTime!)}');
        buffer.writeln('Amount: ₹${(vehicle.totalAmount ?? vehicle.calculateAmount()).toStringAsFixed(0)}');
        buffer.writeln('─────────────────────────────');
      }
    }
    
    // Footer
    buffer.writeln();
    buffer.writeln('════════════════════════════════');
    buffer.writeln('End of Report');
    
    return buffer.toString();
  }

  /// Generate batch report as PDF
  Future<File> generateBatchPdf(
    List<Vehicle> vehicles,
    BusinessSettings settings,
    String reportTitle,
  ) async {
    final pdf = pw.Document();
    
    // Summary data
    final activeVehicles = vehicles.where((v) => v.exitTime == null).toList();
    final completedVehicles = vehicles.where((v) => v.exitTime != null).toList();
    double totalRevenue = 0;
    
    for (var vehicle in completedVehicles) {
      totalRevenue += vehicle.totalAmount ?? vehicle.calculateAmount();
    }
    
    // First page - Summary
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 2),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      settings.businessName.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      reportTitle,
                      style: const pw.TextStyle(fontSize: 16),
                    ),
                    pw.Text(
                      'Generated: ${DateFormat('dd-MMM-yyyy hh:mm a').format(DateTime.now())}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Summary Card
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'SUMMARY',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    _buildPdfSummaryRow('Total Vehicles:', '${vehicles.length}'),
                    _buildPdfSummaryRow('Active:', '${activeVehicles.length}'),
                    _buildPdfSummaryRow('Completed:', '${completedVehicles.length}'),
                    pw.Divider(),
                    _buildPdfSummaryRow(
                      'Total Revenue:',
                      '₹${totalRevenue.toStringAsFixed(0)}',
                      bold: true,
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Vehicle type breakdown
              if (vehicles.isNotEmpty) ...[
                pw.Text(
                  'Vehicle Type Breakdown',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                ..._buildVehicleTypeBreakdown(vehicles),
              ],
            ],
          );
        },
      ),
    );
    
    // Active vehicles page
    if (activeVehicles.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          build: (pw.Context context) {
            return [
              pw.Text(
                'ACTIVE VEHICLES (${activeVehicles.length})',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      _buildTableHeader('Vehicle No'),
                      _buildTableHeader('Type'),
                      _buildTableHeader('Entry Time'),
                      _buildTableHeader('Duration'),
                    ],
                  ),
                  // Data rows
                  ...activeVehicles.map((vehicle) {
                    return pw.TableRow(
                      children: [
                        _buildTableCell(vehicle.vehicleNumber),
                        _buildTableCell(vehicle.vehicleType.displayName),
                        _buildTableCell(DateFormat('dd-MMM hh:mm a').format(vehicle.entryTime)),
                        _buildTableCell(Helpers.formatDuration(vehicle.parkingDuration)),
                      ],
                    );
                  }),
                ],
              ),
            ];
          },
        ),
      );
    }
    
    // Completed vehicles page
    if (completedVehicles.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          build: (pw.Context context) {
            return [
              pw.Text(
                'COMPLETED VEHICLES (${completedVehicles.length})',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      _buildTableHeader('Vehicle No'),
                      _buildTableHeader('Type'),
                      _buildTableHeader('Entry'),
                      _buildTableHeader('Exit'),
                      _buildTableHeader('Amount'),
                    ],
                  ),
                  // Data rows
                  ...completedVehicles.map((vehicle) {
                    return pw.TableRow(
                      children: [
                        _buildTableCell(vehicle.vehicleNumber),
                        _buildTableCell(vehicle.vehicleType.displayName),
                        _buildTableCell(DateFormat('dd-MMM hh:mm').format(vehicle.entryTime)),
                        _buildTableCell(DateFormat('dd-MMM hh:mm').format(vehicle.exitTime!)),
                        _buildTableCell('₹${(vehicle.totalAmount ?? vehicle.calculateAmount()).toStringAsFixed(0)}'),
                      ],
                    );
                  }),
                ],
              ),
            ];
          },
        ),
      );
    }
    
    // Save PDF
    final output = await getTemporaryDirectory();
    final fileName = 'batch_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }

  pw.Widget _buildPdfSummaryRow(String label, String value, {bool bold = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  List<pw.Widget> _buildVehicleTypeBreakdown(List<Vehicle> vehicles) {
    final typeCount = <String, int>{};
    final typeRevenue = <String, double>{};
    
    for (var vehicle in vehicles) {
      final typeName = vehicle.vehicleType.displayName;
      typeCount[typeName] = (typeCount[typeName] ?? 0) + 1;
      
      if (vehicle.exitTime != null) {
        final amount = vehicle.totalAmount ?? vehicle.calculateAmount();
        typeRevenue[typeName] = (typeRevenue[typeName] ?? 0) + amount;
      }
    }
    
    return typeCount.entries.map((entry) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          children: [
            pw.Expanded(
              child: pw.Text(
                entry.key,
                style: const pw.TextStyle(fontSize: 11),
              ),
            ),
            pw.Text(
              'Count: ${entry.value}',
              style: const pw.TextStyle(fontSize: 11),
            ),
            pw.SizedBox(width: 20),
            pw.Text(
              'Revenue: ₹${(typeRevenue[entry.key] ?? 0).toStringAsFixed(0)}',
              style: const pw.TextStyle(fontSize: 11),
            ),
          ],
        ),
      );
    }).toList();
  }

  pw.Widget _buildTableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _buildTableCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 9),
      ),
    );
  }

  /// Share batch report
  Future<void> shareBatchReport(
    BuildContext context,
    List<Vehicle> vehicles,
    BusinessSettings settings,
    String reportTitle,
  ) async {
    if (vehicles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No vehicles to share'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show options dialog
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Share ${vehicles.length} Vehicles',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.text_fields, color: Colors.blue),
                title: const Text('Share as Text'),
                subtitle: const Text('Simple text format'),
                onTap: () => Navigator.pop(context, 'text'),
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('Share as PDF'),
                subtitle: const Text('Professional PDF report'),
                onTap: () => Navigator.pop(context, 'pdf'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (result != null && context.mounted) {
      try {
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        );

        if (result == 'text') {
          final text = generateBatchText(vehicles, settings, reportTitle);
          await Share.share(text, subject: reportTitle);
        } else if (result == 'pdf') {
          final pdfFile = await generateBatchPdf(vehicles, settings, reportTitle);
          await Share.shareXFiles(
            [XFile(pdfFile.path)],
            subject: reportTitle,
            text: 'Batch report with ${vehicles.length} vehicles',
          );
        }

        // Close loading
        if (context.mounted) {
          Navigator.of(context).pop();
        }
        
      } catch (e) {
        // Close loading on error
        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error sharing report: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}