import 'package:flutter/material.dart';
import '../models/printer_device.dart';
import '../utils/constants.dart';

class DeviceListItem extends StatelessWidget {
  final PrinterDevice device;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onConnect;
  final VoidCallback? onSetDefault;

  const DeviceListItem({
    super.key,
    required this.device,
    required this.isSelected,
    required this.onTap,
    this.onConnect,
    this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 4 : 1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: device.isConnected ? AppColors.success : AppColors.primary,
          child: Icon(
            device.isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
            color: Colors.white,
          ),
        ),
        title: Text(
          device.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: device.isConnected ? AppColors.success : AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              device.address,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (device.isConnected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Connected',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (device.isDefault) ...[
                  if (device.isConnected) const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Default',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                if (device.isBonded && !device.isConnected) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Paired',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!device.isDefault && device.isConnected)
              IconButton(
                icon: const Icon(Icons.star_border),
                onPressed: onSetDefault,
                tooltip: 'Set as default',
                color: AppColors.warning,
              ),
            if (!device.isConnected)
              IconButton(
                icon: const Icon(Icons.link),
                onPressed: onConnect,
                tooltip: 'Connect',
                color: AppColors.primary,
              )
            else
              IconButton(
                icon: const Icon(Icons.check_circle),
                onPressed: null,
                color: AppColors.success,
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}