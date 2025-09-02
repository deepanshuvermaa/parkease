import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../models/business_settings.dart';
import '../services/receipt_service.dart';
import '../utils/constants.dart';

class ShareButton extends StatelessWidget {
  final Vehicle vehicle;
  final BusinessSettings settings;
  final bool isLarge;
  final bool showOptions;

  const ShareButton({
    super.key,
    required this.vehicle,
    required this.settings,
    this.isLarge = false,
    this.showOptions = true,
  });

  Future<void> _handleShare(BuildContext context) async {
    final receiptService = ReceiptService();
    
    if (showOptions) {
      // Show share options dialog
      await receiptService.showShareOptions(context, vehicle, settings);
    } else {
      // Direct share as PDF (default)
      await receiptService.shareAsPdf(vehicle, settings);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLarge) {
      return ElevatedButton.icon(
        onPressed: () => _handleShare(context),
        icon: const Icon(Icons.share),
        label: const Text('Share Receipt'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
    
    return IconButton(
      onPressed: () => _handleShare(context),
      icon: const Icon(Icons.share),
      color: AppColors.primary,
      tooltip: 'Share Receipt',
      style: IconButton.styleFrom(
        backgroundColor: AppColors.primary.withOpacity(0.1),
      ),
    );
  }
}