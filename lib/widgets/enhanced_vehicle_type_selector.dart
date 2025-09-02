import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/custom_vehicle_type.dart';
import '../models/enhanced_business_settings.dart';
import '../models/parking_charges.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class EnhancedVehicleTypeSelector extends StatelessWidget {
  final List<CustomVehicleType> vehicleTypes;
  final CustomVehicleType? selectedType;
  final Function(CustomVehicleType) onChanged;
  final bool showPricingTiers;

  const EnhancedVehicleTypeSelector({
    super.key,
    required this.vehicleTypes,
    required this.selectedType,
    required this.onChanged,
    this.showPricingTiers = true,
  });

  @override
  Widget build(BuildContext context) {
    // Get parking charges from settings
    final settings = context.watch<SettingsProvider>().settings;
    ParkingCharges? parkingCharges;
    if (settings is EnhancedBusinessSettings) {
      parkingCharges = settings.parkingCharges;
    }
    
    if (vehicleTypes.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No vehicle types available. Please configure vehicle types in settings.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vehicle Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: vehicleTypes.length > 2 ? 2 : vehicleTypes.length,
                childAspectRatio: 1.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: vehicleTypes.length,
              itemBuilder: (context, index) {
                final vehicleType = vehicleTypes[index];
                final isSelected = selectedType?.id == vehicleType.id;

                return GestureDetector(
                  onTap: () => onChanged(vehicleType),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected 
                          ? AppColors.primary.withOpacity(0.1)
                          : Colors.white,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? AppColors.primary.withOpacity(0.2)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            vehicleType.icon,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          vehicleType.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? AppColors.primary : Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getRateDisplay(parkingCharges, vehicleType),
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected 
                                ? AppColors.primary 
                                : Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            if (showPricingTiers && selectedType != null && parkingCharges != null) ...[
              const SizedBox(height: 16),
              _buildPricingDisplay(selectedType!, parkingCharges),
            ],
          ],
        ),
      ),
    );
  }

  String _getRateDisplay(ParkingCharges? parkingCharges, CustomVehicleType vehicleType) {
    if (parkingCharges == null) {
      return vehicleType.currentRateDisplay;
    }
    
    final rate = parkingCharges.getVehicleRate(vehicleType.name);
    
    switch (parkingCharges.chargeType) {
      case ChargeType.oneTime:
        return 'Rs.${rate.toStringAsFixed(0)}';
      case ChargeType.hourly:
        final duration = parkingCharges.timeUnitDuration;
        final unitName = parkingCharges.timeUnit.shortName;
        if (duration == 1) {
          return 'Rs.${rate.toStringAsFixed(0)}/$unitName';
        } else {
          return 'Rs.${rate.toStringAsFixed(0)}+/$unitName';
        }
      case ChargeType.perDay:
        return 'Rs.${rate.toStringAsFixed(0)}/day';
      case ChargeType.custom:
        return 'Rs.${rate.toStringAsFixed(0)}';
    }
  }
  
  Widget _buildPricingDisplay(CustomVehicleType vehicleType, ParkingCharges parkingCharges) {
    final rate = parkingCharges.getVehicleRate(vehicleType.name);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Pricing Structure',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildPricingInfo(parkingCharges, rate),
        ],
      ),
    );
  }
  
  Widget _buildPricingInfo(ParkingCharges parkingCharges, double rate) {
    switch (parkingCharges.chargeType) {
      case ChargeType.oneTime:
        return Text(
          '• Fixed charge: Rs.${rate.toStringAsFixed(0)}',
          style: const TextStyle(fontSize: 11),
        );
      case ChargeType.hourly:
        final duration = parkingCharges.timeUnitDuration;
        final unitName = parkingCharges.timeUnit.displayName.toLowerCase();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '• Rate: Rs.${rate.toStringAsFixed(0)} per $duration $unitName${duration > 1 ? 's' : ''}',
              style: const TextStyle(fontSize: 11),
            ),
            if (parkingCharges.minimumChargeMinutes > 0)
              Text(
                '• Grace period: ${parkingCharges.minimumChargeMinutes} minutes',
                style: const TextStyle(fontSize: 11),
              ),
          ],
        );
      case ChargeType.perDay:
        return Text(
          '• Daily rate: Rs.${rate.toStringAsFixed(0)}',
          style: const TextStyle(fontSize: 11),
        );
      case ChargeType.custom:
        return Text(
          '• Custom rate: Rs.${rate.toStringAsFixed(0)}',
          style: const TextStyle(fontSize: 11),
        );
    }
  }

}