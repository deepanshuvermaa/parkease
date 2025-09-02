import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bluetooth_provider.dart';
import '../providers/settings_provider.dart';
import '../models/vehicle.dart';
import '../utils/constants.dart';
import 'loading_button.dart';

class PrintButton extends StatelessWidget {
  final Vehicle vehicle;
  final String label;
  final bool isLarge;
  final VoidCallback? onSuccess;
  final VoidCallback? onError;

  const PrintButton({
    super.key,
    required this.vehicle,
    this.label = 'Print Receipt',
    this.isLarge = false,
    this.onSuccess,
    this.onError,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<BluetoothProvider, SettingsProvider>(
      builder: (context, bluetoothProvider, settingsProvider, child) {
        final isConnected = bluetoothProvider.connectedPrinter != null;
        
        if (isLarge) {
          return LoadingButton(
            onPressed: isConnected
                ? () async {
                    final success = await bluetoothProvider.printReceipt(
                      vehicle,
                      settingsProvider.settings,
                    );
                    if (success) {
                      onSuccess?.call();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Receipt printed successfully'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    } else {
                      onError?.call();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to print receipt'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                : null,
            label: label,
            icon: Icons.print,
            backgroundColor: isConnected ? AppColors.primary : Colors.grey,
          );
        }
        
        return IconButton(
          onPressed: isConnected
              ? () async {
                  final success = await bluetoothProvider.printReceipt(
                    vehicle,
                    settingsProvider.settings,
                  );
                  if (success) {
                    onSuccess?.call();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Receipt printed successfully'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  } else {
                    onError?.call();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to print receipt'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              : null,
          icon: Icon(
            Icons.print,
            color: isConnected ? AppColors.primary : Colors.grey,
          ),
          tooltip: isConnected ? 'Print Receipt' : 'No printer connected',
        );
      },
    );
  }
}