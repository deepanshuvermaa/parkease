import 'package:flutter/material.dart';
import '../models/vehicle_type.dart';
import '../utils/constants.dart';

class VehicleTypeSelector extends StatelessWidget {
  final VehicleType selectedType;
  final Function(VehicleType) onChanged;

  const VehicleTypeSelector({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
      ),
      itemCount: VehicleType.values.length,
      itemBuilder: (context, index) {
        final type = VehicleType.values[index];
        final isSelected = type == selectedType;
        
        return InkWell(
          onTap: () => onChanged(type),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.divider,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  type.icon,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.displayName,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: AppFontSize.md,
                      ),
                    ),
                    Text(
                      'Rs.${type.rate.toStringAsFixed(0)}/hr',
                      style: TextStyle(
                        color: isSelected ? Colors.white70 : AppColors.textSecondary,
                        fontSize: AppFontSize.sm,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}