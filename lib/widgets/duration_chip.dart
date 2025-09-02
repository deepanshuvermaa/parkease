import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class DurationChip extends StatelessWidget {
  final Duration duration;
  final bool showIcon;

  const DurationChip({
    super.key,
    required this.duration,
    this.showIcon = true,
  });

  Color _getColor() {
    if (duration.inHours >= 5) {
      return AppColors.error;
    } else if (duration.inHours >= 3) {
      return AppColors.warning;
    } else {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              Icons.access_time,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            Helpers.formatDuration(duration),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}