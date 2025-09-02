import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bluetooth_provider.dart';
import '../utils/constants.dart';

class ScanButton extends StatefulWidget {
  final bool isLarge;
  final String? label;
  final VoidCallback? onScanComplete;

  const ScanButton({
    super.key,
    this.isLarge = false,
    this.label,
    this.onScanComplete,
  });

  @override
  State<ScanButton> createState() => _ScanButtonState();
}

class _ScanButtonState extends State<ScanButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleScan() async {
    final bluetoothProvider = context.read<BluetoothProvider>();
    
    _animationController.repeat();
    
    try {
      await bluetoothProvider.scanForPrinters();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Found ${bluetoothProvider.availablePrinters.length} printer(s)',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
      
      widget.onScanComplete?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scan failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        _animationController.stop();
        _animationController.reset();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BluetoothProvider>(
      builder: (context, bluetoothProvider, child) {
        final isScanning = bluetoothProvider.isScanning;
        
        if (widget.isLarge) {
          return ElevatedButton.icon(
            onPressed: isScanning ? null : _handleScan,
            icon: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _animationController.value * 2 * 3.14159,
                  child: Icon(
                    isScanning ? Icons.radar : Icons.bluetooth_searching,
                  ),
                );
              },
            ),
            label: Text(
              widget.label ?? (isScanning ? 'Scanning...' : 'Scan for Printers'),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
        
        return FloatingActionButton(
          onPressed: isScanning ? null : _handleScan,
          backgroundColor: isScanning ? Colors.grey : AppColors.primary,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _animationController.value * 2 * 3.14159,
                child: Icon(
                  isScanning ? Icons.radar : Icons.bluetooth_searching,
                  color: Colors.white,
                ),
              );
            },
          ),
        );
      },
    );
  }
}