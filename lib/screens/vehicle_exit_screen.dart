import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vehicle.dart';
import '../models/vehicle_type.dart';
import '../models/enhanced_business_settings.dart';
import '../models/parking_charges.dart';
import '../providers/vehicle_provider.dart';
import '../providers/bluetooth_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/loading_button.dart';

class VehicleExitScreen extends StatefulWidget {
  final Vehicle? vehicle;
  
  const VehicleExitScreen({super.key, this.vehicle});

  @override
  State<VehicleExitScreen> createState() => _VehicleExitScreenState();
}

class _VehicleExitScreenState extends State<VehicleExitScreen> {
  final _searchController = TextEditingController();
  Vehicle? _selectedVehicle;
  bool _isProcessing = false;
  double? _finalAmount;
  ParkingCharges? _parkingCharges;

  @override
  void initState() {
    super.initState();
    _selectedVehicle = widget.vehicle;
    _loadParkingCharges();
    if (_selectedVehicle != null) {
      _calculateAmount();
    }
  }

  void _loadParkingCharges() {
    final settings = context.read<SettingsProvider>().settings;
    if (settings is EnhancedBusinessSettings) {
      _parkingCharges = settings.parkingCharges;
    } else {
      _parkingCharges = ParkingCharges();
    }
  }

  void _calculateAmount() {
    if (_selectedVehicle != null && _parkingCharges != null) {
      final duration = DateTime.now().difference(_selectedVehicle!.entryTime);
      setState(() {
        // Use the parking charges configuration to calculate the amount
        _finalAmount = _parkingCharges!.calculateCharge(
          _selectedVehicle!.vehicleType.displayName,
          duration,
        );
      });
    } else if (_selectedVehicle != null) {
      // Fallback to default calculation
      setState(() {
        _finalAmount = _selectedVehicle!.calculateAmount();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.vehicleExit),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            if (_selectedVehicle == null) _buildSearchSection(),
            if (_selectedVehicle != null) _buildVehicleDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Enter vehicle number or ticket ID',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ElevatedButton(
          onPressed: _searchVehicle,
          child: const Text('Search Vehicle'),
        ),
      ],
    );
  }

  void _searchVehicle() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    final provider = context.read<VehicleProvider>();
    final vehicle = provider.getVehicleByNumber(query) ??
        provider.activeVehicles.firstWhere(
          (v) => v.ticketId == query,
          orElse: () => Vehicle(
            id: '',
            vehicleNumber: '',
            vehicleType: VehicleType.fourWheeler,
            entryTime: DateTime.now(),
            rate: 0,
            ticketId: '',
          ),
        );

    if (vehicle.id.isNotEmpty) {
      setState(() {
        _selectedVehicle = vehicle;
        _calculateAmount();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vehicle not found'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildVehicleDetails() {
    if (_selectedVehicle == null) return const SizedBox.shrink();

    final duration = _selectedVehicle!.parkingDuration;

    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Center(
                        child: Text(
                          _selectedVehicle!.vehicleType.icon,
                          style: const TextStyle(fontSize: 36),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedVehicle!.vehicleNumber,
                            style: const TextStyle(
                              fontSize: AppFontSize.xxl,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Ticket: ${_selectedVehicle!.ticketId}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            _selectedVehicle!.vehicleType.displayName,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                _buildDetailRow(
                  'Entry Time',
                  Helpers.formatDateTime(_selectedVehicle!.entryTime),
                ),
                _buildDetailRow(
                  'Exit Time',
                  Helpers.formatDateTime(DateTime.now()),
                ),
                const Divider(),
                _buildDetailRow(
                  'Duration',
                  Helpers.formatDuration(duration),
                ),
                if (_parkingCharges != null) _buildDetailRow(
                  'Rate',
                  _buildRateText(),
                ),
                const Divider(),
                if (_parkingCharges != null && 
                    _parkingCharges!.minimumChargeMinutes > 0 &&
                    _finalAmount == 0) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.green.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Grace period applied - No charge for parking under ${_parkingCharges!.minimumChargeMinutes} minutes',
                            style: TextStyle(
                              color: Colors.green.shade800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                _buildDetailRow(
                  'Total Amount',
                  Helpers.formatCurrency(_finalAmount ?? 0),
                  isHighlighted: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        LoadingButton(
          isLoading: _isProcessing,
          onPressed: _processExit,
          child: const Text(
            'Process Payment & Exit',
            style: TextStyle(fontSize: AppFontSize.lg),
          ),
        ),
      ],
    );
  }

  String _buildRateText() {
    if (_parkingCharges == null || _selectedVehicle == null) {
      return 'N/A';
    }
    
    final rate = _parkingCharges!.getVehicleRate(_selectedVehicle!.vehicleType.displayName);
    final rateDisplay = _parkingCharges!.getRateDisplayText(rate);
    
    if (_parkingCharges!.chargeType == ChargeType.oneTime) {
      return Helpers.formatCurrency(rate);
    } else {
      return '${Helpers.formatCurrency(rate)} $rateDisplay';
    }
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isHighlighted ? AppFontSize.lg : AppFontSize.md,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isHighlighted ? AppFontSize.xl : AppFontSize.md,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
              color: isHighlighted ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processExit() async {
    if (_selectedVehicle == null || _finalAmount == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final vehicleProvider = context.read<VehicleProvider>();
      final bluetoothProvider = context.read<BluetoothProvider>();
      final settingsProvider = context.read<SettingsProvider>();

      final exitedVehicle = _selectedVehicle!.copyWith(
        exitTime: DateTime.now(),
        totalAmount: _finalAmount,
        isPaid: true,
      );

      if (settingsProvider.settings.autoPrint && bluetoothProvider.isConnected) {
        await bluetoothProvider.printReceipt(
          exitedVehicle,
          settingsProvider.settings,
        );
      }

      vehicleProvider.exitVehicle(_selectedVehicle!.id, _finalAmount!);

      if (mounted) {
        _showSuccessDialog(exitedVehicle);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showSuccessDialog(Vehicle vehicle) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Exit Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 60,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Payment Received',
              style: TextStyle(
                fontSize: AppFontSize.lg,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              Helpers.formatCurrency(vehicle.totalAmount ?? 0),
              style: TextStyle(
                fontSize: AppFontSize.xxl,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final bluetoothProvider = context.read<BluetoothProvider>();
              final settingsProvider = context.read<SettingsProvider>();
              
              if (bluetoothProvider.isConnected) {
                await bluetoothProvider.printReceipt(
                  vehicle,
                  settingsProvider.settings,
                );
              }
            },
            child: const Text('Print Receipt'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}