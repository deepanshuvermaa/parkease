import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vehicle.dart';
import '../models/vehicle_type.dart';
import '../models/custom_vehicle_type.dart';
import '../models/enhanced_business_settings.dart';
import '../models/parking_charges.dart';
import '../models/ticket_id_settings.dart';
import '../services/ticket_id_generator.dart';
import '../providers/vehicle_provider.dart';
import '../providers/bluetooth_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/enhanced_vehicle_type_selector.dart';
import '../widgets/vehicle_number_input.dart';
import '../widgets/loading_button.dart';

class VehicleEntryScreen extends StatefulWidget {
  const VehicleEntryScreen({super.key});

  @override
  State<VehicleEntryScreen> createState() => _VehicleEntryScreenState();
}

class _VehicleEntryScreenState extends State<VehicleEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleNumberController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  CustomVehicleType? _selectedVehicleType;
  bool _isProcessing = false;
  List<CustomVehicleType> _availableVehicleTypes = [];
  ParkingCharges? _parkingCharges;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVehicleTypes();
    });
  }

  void _loadVehicleTypes() {
    final settings = context.read<SettingsProvider>().settings;
    if (settings is EnhancedBusinessSettings) {
      setState(() {
        _parkingCharges = settings.parkingCharges;
        _availableVehicleTypes = settings.customVehicleTypes
            .where((type) => type.isActive)
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        
        if (_availableVehicleTypes.isNotEmpty) {
          _selectedVehicleType = _availableVehicleTypes.first;
        }
      });
    } else {
      setState(() {
        _parkingCharges = ParkingCharges();
        _availableVehicleTypes = DefaultVehicleTypes.getDefaults();
        _selectedVehicleType = _availableVehicleTypes.first;
      });
    }
  }

  VehicleType _convertToLegacyType(CustomVehicleType customType) {
    switch (customType.name.toLowerCase()) {
      case 'cycle':
        return VehicleType.cycle;
      case 'twowheeler':
        return VehicleType.twoWheeler;
      case 'fourwheeler':
        return VehicleType.fourWheeler;
      case 'auto':
        return VehicleType.auto;
      default:
        return VehicleType.fourWheeler; // Default fallback
    }
  }

  @override
  void dispose() {
    _vehicleNumberController.dispose();
    _ownerNameController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.vehicleEntry),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_parkingCharges?.captureVehicleNumber ?? true)
                _buildVehicleNumberField(),
              if (_parkingCharges?.captureOwnerName ?? false) ...[
                const SizedBox(height: 24),
                _buildOwnerNameField(),
              ],
              if (_parkingCharges?.capturePhoneNumber ?? false) ...[
                const SizedBox(height: 24),
                _buildPhoneNumberField(),
              ],
              const SizedBox(height: 24),
              _buildVehicleTypeSelector(),
              if (_parkingCharges != null) ...[
                const SizedBox(height: 24),
                _buildRateDisplay(),
              ],
              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleNumberField() {
    final requiresNumber = _selectedVehicleType?.requiresVehicleNumber ?? true;
    
    if (!requiresNumber) {
      return Card(
        color: Colors.blue.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vehicle Number (Optional)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'This vehicle type does not require a number. A unique ID will be auto-generated.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Vehicle Number',
              style: TextStyle(
                fontSize: AppFontSize.lg,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(Required)',
              style: TextStyle(
                fontSize: AppFontSize.sm,
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        VehicleNumberInput(
          controller: _vehicleNumberController,
          onChanged: (value) {
            setState(() {});
          },
          errorText: requiresNumber && _vehicleNumberController.text.isEmpty 
              ? 'Vehicle number is required' 
              : null,
        ),
      ],
    );
  }

  Widget _buildOwnerNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Owner Name',
          style: TextStyle(
            fontSize: AppFontSize.lg,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: _ownerNameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Enter owner name',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (_parkingCharges?.captureOwnerName == true && 
                (value == null || value.trim().isEmpty)) {
              return 'Please enter owner name';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPhoneNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phone Number',
          style: TextStyle(
            fontSize: AppFontSize.lg,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: _phoneNumberController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: 'Enter phone number',
            prefixIcon: Icon(Icons.phone),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (_parkingCharges?.capturePhoneNumber == true && 
                (value == null || value.trim().isEmpty)) {
              return 'Please enter phone number';
            }
            if (value != null && value.isNotEmpty && value.length < 10) {
              return 'Please enter a valid phone number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildVehicleTypeSelector() {
    if (_availableVehicleTypes.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Loading vehicle types...',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return EnhancedVehicleTypeSelector(
      vehicleTypes: _availableVehicleTypes,
      selectedType: _selectedVehicleType,
      onChanged: (type) {
        setState(() {
          _selectedVehicleType = type;
        });
      },
      showPricingTiers: true,
    );
  }

  Widget _buildRateDisplay() {
    if (_parkingCharges == null || _selectedVehicleType == null) {
      return const SizedBox.shrink();
    }

    // Find the rate for the selected vehicle type
    final vehicleRate = _parkingCharges!.vehicleRates.firstWhere(
      (rate) => rate.vehicleType.toLowerCase() == _selectedVehicleType!.name.toLowerCase(),
      orElse: () => VehicleRate(
        vehicleType: _selectedVehicleType!.name,
        icon: _selectedVehicleType!.icon,
        capacity: 0,
        rate: 50,
      ),
    );

    String rateText;
    switch (_parkingCharges!.chargeType) {
      case ChargeType.oneTime:
        rateText = '${Helpers.formatCurrency(vehicleRate.rate)} (One Time)';
        break;
      case ChargeType.hourly:
        final duration = _parkingCharges!.timeUnitDuration;
        final unitName = _parkingCharges!.timeUnit.displayName.toLowerCase();
        rateText = '${Helpers.formatCurrency(vehicleRate.rate)} per $duration $unitName${duration > 1 ? 's' : ''}';
        break;
      case ChargeType.perDay:
        rateText = '${Helpers.formatCurrency(vehicleRate.rate)} per day';
        break;
      case ChargeType.custom:
        rateText = '${Helpers.formatCurrency(vehicleRate.rate)} (Custom)';
        break;
    }

    return Card(
      color: AppColors.primary.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(
              Icons.attach_money,
              color: AppColors.primary,
              size: 32,
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Parking ${_parkingCharges!.chargeType.displayName}',
                  style: const TextStyle(
                    fontSize: AppFontSize.sm,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  rateText,
                  style: const TextStyle(
                    fontSize: AppFontSize.xl,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                if (vehicleRate.capacity > 0) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Capacity: ${vehicleRate.capacity} slots',
                    style: TextStyle(
                      fontSize: AppFontSize.sm,
                      color: AppColors.textSecondary.withOpacity(0.8),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return LoadingButton(
      isLoading: _isProcessing,
      onPressed: _handleSubmit,
      child: const Text(
        'Generate Entry Ticket',
        style: TextStyle(fontSize: AppFontSize.lg),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    final requiresNumber = _selectedVehicleType?.requiresVehicleNumber ?? true;
    
    // Validate vehicle number if required
    if (requiresNumber && _vehicleNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vehicle number is required for this vehicle type'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final vehicleProvider = context.read<VehicleProvider>();
      final bluetoothProvider = context.read<BluetoothProvider>();
      final settingsProvider = context.read<SettingsProvider>();

      if (_selectedVehicleType == null) {
        throw Exception('Please select a vehicle type');
      }

      // Convert CustomVehicleType to legacy VehicleType for compatibility
      final legacyVehicleType = _convertToLegacyType(_selectedVehicleType!);
      
      // Get the rate from parking charges settings
      final currentRate = _parkingCharges?.getVehicleRate(_selectedVehicleType!.name) ?? 
                         _selectedVehicleType!.pricingTiers.first.ratePerHour;

      // Generate vehicle number or auto ID
      String vehicleIdentifier = _vehicleNumberController.text;
      if (!requiresNumber && vehicleIdentifier.isEmpty) {
        // Generate auto ID for vehicles without number requirement
        final timestamp = DateTime.now();
        vehicleIdentifier = '${_selectedVehicleType!.displayName.substring(0, 2).toUpperCase()}'
            '-${timestamp.hour.toString().padLeft(2, '0')}'
            '${timestamp.minute.toString().padLeft(2, '0')}'
            '${timestamp.second.toString().padLeft(2, '0')}';
      }

      // Generate ticket ID using the new system
      String ticketId;
      final settings = settingsProvider.settings;
      if (settings is EnhancedBusinessSettings) {
        ticketId = await TicketIdGenerator.generateTicketId(
          settings.ticketIdSettings,
          locationCode: settings.city.substring(0, 3).toUpperCase(),
        );
      } else {
        ticketId = Helpers.generateTicketId(); // Fallback to old method
      }
      
      final vehicle = Vehicle(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        vehicleNumber: Helpers.formatVehicleNumber(vehicleIdentifier),
        vehicleType: legacyVehicleType,
        entryTime: DateTime.now(),
        rate: currentRate,
        ticketId: ticketId,
      );

      vehicleProvider.addVehicle(vehicle);

      if (settingsProvider.settings.autoPrint && bluetoothProvider.isConnected) {
        await bluetoothProvider.printReceipt(
          vehicle,
          settingsProvider.settings,
        );
      }

      if (mounted) {
        _showSuccessDialog(vehicle);
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
        title: const Text('Entry Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Ticket ID', vehicle.ticketId),
            _buildInfoRow('Vehicle', vehicle.vehicleNumber),
            _buildInfoRow('Type', vehicle.vehicleType.displayName),
            _buildInfoRow('Entry Time', Helpers.formatTime(vehicle.entryTime)),
            _buildInfoRow('Rate', _getRateDisplayForDialog(vehicle.rate)),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () async {
              final bluetoothProvider = context.read<BluetoothProvider>();
              final settingsProvider = context.read<SettingsProvider>();
              
              if (bluetoothProvider.isConnected) {
                await bluetoothProvider.printReceipt(
                  vehicle,
                  settingsProvider.settings,
                );
                
                // After printing, clear the form and close dialog
                if (mounted) {
                  Navigator.pop(context);
                  _vehicleNumberController.clear();
                  _ownerNameController.clear();
                  _phoneNumberController.clear();
                  setState(() {
                    _selectedVehicleType = _availableVehicleTypes.isNotEmpty 
                        ? _availableVehicleTypes.first 
                        : null;
                  });
                }
              } else {
                // If not connected, show message
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Printer not connected. Please connect a printer.'),
                      backgroundColor: AppColors.warning,
                    ),
                  );
                  Navigator.pop(context);
                  _vehicleNumberController.clear();
                  _ownerNameController.clear();
                  _phoneNumberController.clear();
                  setState(() {
                    _selectedVehicleType = _availableVehicleTypes.isNotEmpty 
                        ? _availableVehicleTypes.first 
                        : null;
                  });
                }
              }
            },
            icon: const Icon(Icons.print),
            label: const Text('Print Ticket'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _getRateDisplayForDialog(double rate) {
    if (_parkingCharges == null) {
      return '${Helpers.formatCurrency(rate)}/hr';
    }
    
    final rateDisplay = _parkingCharges!.getRateDisplayText(rate);
    
    if (_parkingCharges!.chargeType == ChargeType.oneTime) {
      return '${Helpers.formatCurrency(rate)} (One Time)';
    } else {
      return '${Helpers.formatCurrency(rate)} $rateDisplay';
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}