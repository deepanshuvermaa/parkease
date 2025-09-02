import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../utils/constants.dart';

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String description;
  final IconData? icon;
  final String? lottieAsset;
  final Widget? actionButton;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.description,
    this.icon,
    this.lottieAsset,
    this.actionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (lottieAsset != null)
              SizedBox(
                height: 200,
                child: Lottie.asset(
                  lottieAsset!,
                  fit: BoxFit.contain,
                ),
              )
            else if (icon != null)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 64,
                  color: AppColors.primary,
                ),
              ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionButton != null) ...[
              const SizedBox(height: 32),
              actionButton!,
            ],
          ],
        ),
      ),
    );
  }
}