import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bluetooth_provider.dart';
import '../utils/constants.dart';

class ConnectionStatusIndicator extends StatefulWidget {
  final bool showDetails;
  final bool compact;

  const ConnectionStatusIndicator({
    super.key,
    this.showDetails = true,
    this.compact = false,
  });

  @override
  State<ConnectionStatusIndicator> createState() => _ConnectionStatusIndicatorState();
}

class _ConnectionStatusIndicatorState extends State<ConnectionStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BluetoothProvider>(
      builder: (context, bluetoothProvider, child) {
        final isConnected = bluetoothProvider.connectedPrinter != null;
        final isConnecting = bluetoothProvider.isConnecting;
        final printerName = bluetoothProvider.connectedPrinter?.name;

        if (widget.compact) {
          return AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isConnecting
                      ? AppColors.warning.withOpacity(_animation.value)
                      : isConnected
                          ? AppColors.success
                          : AppColors.error,
                  boxShadow: [
                    if (isConnected || isConnecting)
                      BoxShadow(
                        color: (isConnecting ? AppColors.warning : AppColors.success)
                            .withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                  ],
                ),
              );
            },
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isConnecting
                ? AppColors.warning.withOpacity(0.1)
                : isConnected
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isConnecting
                  ? AppColors.warning
                  : isConnected
                      ? AppColors.success
                      : AppColors.error,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Icon(
                    isConnecting
                        ? Icons.bluetooth_searching
                        : isConnected
                            ? Icons.bluetooth_connected
                            : Icons.bluetooth_disabled,
                    color: isConnecting
                        ? AppColors.warning.withOpacity(_animation.value)
                        : isConnected
                            ? AppColors.success
                            : AppColors.error,
                    size: 20,
                  );
                },
              ),
              if (widget.showDetails) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isConnecting
                            ? 'Connecting...'
                            : isConnected
                                ? 'Connected'
                                : 'Not Connected',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isConnecting
                              ? AppColors.warning
                              : isConnected
                                  ? AppColors.success
                                  : AppColors.error,
                        ),
                      ),
                      if (isConnected && printerName != null)
                        Text(
                          printerName,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}