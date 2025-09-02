import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/vehicle.dart';
import '../models/business_settings.dart';
import '../services/receipt_service.dart';
import '../utils/constants.dart';

class QuickShareButton extends StatelessWidget {
  final Vehicle vehicle;
  final BusinessSettings settings;
  final ShareMode mode;
  final VoidCallback? onShareComplete;

  const QuickShareButton({
    super.key,
    required this.vehicle,
    required this.settings,
    this.mode = ShareMode.auto,
    this.onShareComplete,
  });

  Future<void> _handleQuickShare(BuildContext context) async {
    final receiptService = ReceiptService();
    
    try {
      // Show loading indicator
      if (context.mounted) {
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
      }

      switch (mode) {
        case ShareMode.text:
          await receiptService.shareAsText(vehicle, settings);
          break;
        case ShareMode.pdf:
          await receiptService.shareAsPdf(vehicle, settings);
          break;
        case ShareMode.copy:
          final text = receiptService.generateReceiptText(vehicle, settings);
          await Clipboard.setData(ClipboardData(text: text));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Receipt copied to clipboard'),
                duration: Duration(seconds: 2),
              ),
            );
          }
          break;
        case ShareMode.auto:
        default:
          // Try PDF first, fallback to text
          try {
            await receiptService.shareAsPdf(vehicle, settings);
          } catch (e) {
            await receiptService.shareAsText(vehicle, settings);
          }
          break;
      }

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Call completion callback
      onShareComplete?.call();
      
    } catch (e) {
      // Close loading dialog on error
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing receipt: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  IconData get _icon {
    switch (mode) {
      case ShareMode.text:
        return Icons.text_fields;
      case ShareMode.pdf:
        return Icons.picture_as_pdf;
      case ShareMode.copy:
        return Icons.copy;
      case ShareMode.auto:
      default:
        return Icons.share;
    }
  }

  String get _tooltip {
    switch (mode) {
      case ShareMode.text:
        return 'Share as text';
      case ShareMode.pdf:
        return 'Share as PDF';
      case ShareMode.copy:
        return 'Copy to clipboard';
      case ShareMode.auto:
      default:
        return 'Share receipt';
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => _handleQuickShare(context),
      icon: Icon(_icon),
      tooltip: _tooltip,
      color: AppColors.primary,
    );
  }
}

enum ShareMode {
  auto,  // Automatically choose best method
  text,  // Share as plain text
  pdf,   // Share as PDF
  copy,  // Copy to clipboard
}