import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/vehicle.dart';
import '../models/business_settings.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class ReceiptPreview extends StatelessWidget {
  final Vehicle vehicle;
  final BusinessSettings settings;

  const ReceiptPreview({
    super.key,
    required this.vehicle,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            settings.businessName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            settings.address,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
          Text(
            settings.city,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
          if (settings.showContactOnReceipt) ...[
            const SizedBox(height: 4),
            Text(
              'Mob: ${settings.contactNumber}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
          const Divider(height: 16),
          Text(
            vehicle.ticketId,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildInfoRow('V. Number', vehicle.vehicleNumber),
          _buildInfoRow('V. Type', vehicle.vehicleType.displayName),
          _buildInfoRow('Rate', 'Rs.${vehicle.rate.toStringAsFixed(0)}/-'),
          _buildInfoRow(
            'Entry',
            DateFormat('dd-MMM-yy hh:mm a').format(vehicle.entryTime),
          ),
          if (vehicle.exitTime != null) ...[
            _buildInfoRow(
              'Exit',
              DateFormat('dd-MMM-yy hh:mm a').format(vehicle.exitTime!),
            ),
            _buildInfoRow(
              'Duration',
              Helpers.formatDuration(vehicle.parkingDuration),
            ),
            const Divider(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Payable:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Rs.${vehicle.totalAmount?.toStringAsFixed(0) ?? vehicle.calculateAmount().toStringAsFixed(0)}/-',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Divider(height: 16),
          const Text(
            'Thank you!',
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('dd-MMM-yyyy hh:mm a').format(DateTime.now()),
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}