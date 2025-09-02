import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/receipt_service.dart';
import '../models/vehicle.dart';
import '../models/business_settings.dart';

/// Helper service for sharing with comprehensive error handling
class ShareServiceHelper {
  static final ShareServiceHelper _instance = ShareServiceHelper._internal();
  factory ShareServiceHelper() => _instance;
  ShareServiceHelper._internal();

  final ReceiptService _receiptService = ReceiptService();
  
  /// Share receipt with fallback mechanisms
  Future<void> shareReceipt(
    BuildContext context,
    Vehicle vehicle,
    BusinessSettings settings, {
    ShareMode mode = ShareMode.auto,
    bool showOptions = true,
  }) async {
    try {
      // Check if share_plus is available
      final canShare = await _checkShareAvailability();
      if (!canShare && context.mounted) {
        // Fallback to clipboard if share is not available
        await _copyToClipboard(context, vehicle, settings);
        return;
      }

      if (showOptions && context.mounted) {
        // Show share options
        await _receiptService.showShareOptions(context, vehicle, settings);
      } else {
        // Direct share based on mode
        switch (mode) {
          case ShareMode.pdf:
            await _shareAsPdf(context, vehicle, settings);
            break;
          case ShareMode.text:
            await _shareAsText(context, vehicle, settings);
            break;
          case ShareMode.copy:
            await _copyToClipboard(context, vehicle, settings);
            break;
          case ShareMode.auto:
          default:
            await _shareWithFallback(context, vehicle, settings);
            break;
        }
      }
    } catch (e) {
      debugPrint('Share error: $e');
      if (context.mounted) {
        _showErrorSnackBar(context, 'Share failed: ${e.toString()}');
        // Final fallback - copy to clipboard
        await _copyToClipboard(context, vehicle, settings);
      }
    }
  }

  /// Check if sharing is available
  Future<bool> _checkShareAvailability() async {
    try {
      // Try to check if we can share
      // On some devices, share_plus might not be available
      return true; // Assume available, will catch errors if not
    } catch (e) {
      debugPrint('Share availability check failed: $e');
      return false;
    }
  }

  /// Share with automatic fallback
  Future<void> _shareWithFallback(
    BuildContext context,
    Vehicle vehicle,
    BusinessSettings settings,
  ) async {
    try {
      // Try PDF first
      await _shareAsPdf(context, vehicle, settings);
    } catch (e) {
      debugPrint('PDF share failed, falling back to text: $e');
      try {
        // Fallback to text
        await _shareAsText(context, vehicle, settings);
      } catch (e2) {
        debugPrint('Text share failed, falling back to clipboard: $e2');
        // Final fallback to clipboard
        if (context.mounted) {
          await _copyToClipboard(context, vehicle, settings);
        }
      }
    }
  }

  /// Share as PDF with error handling
  Future<void> _shareAsPdf(
    BuildContext context,
    Vehicle vehicle,
    BusinessSettings settings,
  ) async {
    try {
      // Check storage permission for older Android versions
      if (Platform.isAndroid) {
        final status = await Permission.storage.status;
        if (status.isDenied) {
          final result = await Permission.storage.request();
          if (!result.isGranted) {
            throw Exception('Storage permission required for PDF generation');
          }
        }
      }

      // Show loading indicator
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text('Generating PDF...'),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      // Generate PDF
      final pdfFile = await _receiptService.generatePdfReceipt(vehicle, settings);
      
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Check if file exists and is valid
      if (!await pdfFile.exists()) {
        throw Exception('PDF file generation failed');
      }

      final fileSize = await pdfFile.length();
      if (fileSize == 0) {
        throw Exception('Generated PDF is empty');
      }

      // Share the PDF
      final result = await Share.shareXFiles(
        [XFile(pdfFile.path)],
        subject: 'Parking Receipt - ${vehicle.ticketId}',
        text: 'Parking receipt for vehicle ${vehicle.vehicleNumber}',
        sharePositionOrigin: context.mounted 
            ? Rect.fromCenter(
                center: MediaQuery.of(context).size.center(Offset.zero),
                width: 1,
                height: 1,
              )
            : null,
      );

      // Clean up temporary file after sharing
      Future.delayed(const Duration(minutes: 1), () {
        pdfFile.delete().catchError((e) {
          debugPrint('Failed to delete temp PDF: $e');
        });
      });

      if (result.status == ShareResultStatus.success) {
        debugPrint('PDF shared successfully');
      }
    } catch (e) {
      // Close loading dialog if still showing
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      throw e;
    }
  }

  /// Share as text with error handling
  Future<void> _shareAsText(
    BuildContext context,
    Vehicle vehicle,
    BusinessSettings settings,
  ) async {
    try {
      final text = _receiptService.generateReceiptText(vehicle, settings);
      
      final result = await Share.share(
        text,
        subject: 'Parking Receipt - ${vehicle.ticketId}',
        sharePositionOrigin: context.mounted 
            ? Rect.fromCenter(
                center: MediaQuery.of(context).size.center(Offset.zero),
                width: 1,
                height: 1,
              )
            : null,
      );

      if (result.status == ShareResultStatus.success) {
        debugPrint('Text shared successfully');
      }
    } catch (e) {
      debugPrint('Text share error: $e');
      throw e;
    }
  }

  /// Copy to clipboard with feedback
  Future<void> _copyToClipboard(
    BuildContext context,
    Vehicle vehicle,
    BusinessSettings settings,
  ) async {
    try {
      final text = _receiptService.generateReceiptText(vehicle, settings);
      await Clipboard.setData(ClipboardData(text: text));
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt copied to clipboard'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Clipboard error: $e');
      if (context.mounted) {
        _showErrorSnackBar(context, 'Failed to copy to clipboard');
      }
    }
  }

  /// Clean up temporary files
  Future<void> cleanupTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync()
          .whereType<File>()
          .where((file) => file.path.contains('receipt_'));
      
      for (var file in files) {
        try {
          // Delete files older than 1 hour
          final stat = await file.stat();
          final age = DateTime.now().difference(stat.modified);
          if (age.inHours > 1) {
            await file.delete();
            debugPrint('Deleted old temp file: ${file.path}');
          }
        } catch (e) {
          debugPrint('Failed to delete temp file: $e');
        }
      }
    } catch (e) {
      debugPrint('Temp file cleanup error: $e');
    }
  }

  /// Show error snackbar
  void _showErrorSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Share multiple receipts
  Future<void> shareMultipleReceipts(
    BuildContext context,
    List<Vehicle> vehicles,
    BusinessSettings settings,
    String title,
  ) async {
    if (vehicles.isEmpty) {
      _showErrorSnackBar(context, 'No receipts to share');
      return;
    }

    try {
      // For single vehicle, use normal share
      if (vehicles.length == 1) {
        await shareReceipt(context, vehicles.first, settings);
        return;
      }

      // For multiple, generate combined PDF or text
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // Generate combined text
      final buffer = StringBuffer();
      buffer.writeln('═══════════════════════════');
      buffer.writeln(title);
      buffer.writeln('Total Receipts: ${vehicles.length}');
      buffer.writeln('═══════════════════════════\n');
      
      for (var vehicle in vehicles) {
        buffer.writeln(_receiptService.generateReceiptText(vehicle, settings));
        buffer.writeln('\n─────────────────────────\n');
      }
      
      // Share combined text
      await Share.share(
        buffer.toString(),
        subject: title,
      );
      
    } catch (e) {
      debugPrint('Multiple share error: $e');
      if (context.mounted) {
        _showErrorSnackBar(context, 'Failed to share receipts');
      }
    }
  }
}

enum ShareMode {
  auto,
  text,
  pdf,
  copy,
}