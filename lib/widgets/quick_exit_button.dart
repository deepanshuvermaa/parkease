import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../utils/constants.dart';

class QuickExitButton extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onPressed;
  final bool isCompact;

  const QuickExitButton({
    super.key,
    required this.vehicle,
    required this.onPressed,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return IconButton(
        onPressed: onPressed,
        icon: const Icon(Icons.exit_to_app),
        color: AppColors.accent,
        tooltip: 'Quick Exit - ${vehicle.vehicleNumber}',
      );
    }

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.exit_to_app, size: 18),
      label: Text(
        'Exit ${vehicle.vehicleNumber}',
        style: const TextStyle(fontSize: 12),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}