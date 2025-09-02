import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/parking_charges.dart';
import '../models/enhanced_business_settings.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/loading_button.dart';

class ParkingChargesScreen extends StatefulWidget {
  const ParkingChargesScreen({super.key});

  @override
  State<ParkingChargesScreen> createState() => _ParkingChargesScreenState();
}

class _ParkingChargesScreenState extends State<ParkingChargesScreen> {
  late ParkingCharges _parkingCharges;
  late List<VehicleRate> _vehicleRates;
  late ChargeType _selectedChargeType;
  late TimeUnit _selectedTimeUnit;
  late TextEditingController _timeUnitDurationController;
  late TextEditingController _minimumChargeController;
  late bool _captureVehicleNumber;
  late bool _captureOwnerName;
  late bool _capturePhoneNumber;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final settings = context.read<SettingsProvider>().settings;
    if (settings is EnhancedBusinessSettings) {
      _parkingCharges = settings.parkingCharges;
    } else {
      _parkingCharges = ParkingCharges();
    }

    _vehicleRates = List.from(_parkingCharges.vehicleRates);
    _selectedChargeType = _parkingCharges.chargeType;
    _selectedTimeUnit = _parkingCharges.timeUnit;
    _timeUnitDurationController = TextEditingController(
      text: _parkingCharges.timeUnitDuration.toString(),
    );
    _minimumChargeController = TextEditingController(
      text: _parkingCharges.minimumChargeMinutes.toString(),
    );
    _captureVehicleNumber = _parkingCharges.captureVehicleNumber;
    _captureOwnerName = _parkingCharges.captureOwnerName;
    _capturePhoneNumber = _parkingCharges.capturePhoneNumber;
  }

  @override
  void dispose() {
    _timeUnitDurationController.dispose();
    _minimumChargeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Stand Details',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildParkingChargesHeader(),
            const SizedBox(height: 24),
            _buildChargeTypeSection(),
            if (_selectedChargeType == ChargeType.hourly) ...[
              const SizedBox(height: 24),
              _buildTimeConfiguration(),
            ],
            const SizedBox(height: 24),
            _buildMinimumChargeTime(),
            const SizedBox(height: 32),
            _buildParkingRateSection(),
            const SizedBox(height: 32),
            _buildOtherInformationSection(),
            const SizedBox(height: 32),
            LoadingButton(
              onPressed: _saveSettings,
              isLoading: _isLoading,
              child: const Text('Save Changes'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildParkingChargesHeader() {
    return const Center(
      child: Text(
        'Parking Charges',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildChargeTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Charges Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildChargeTypeGrid(),
      ],
    );
  }

  Widget _buildChargeTypeGrid() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: ChargeType.values.map((type) {
        final isSelected = _selectedChargeType == type;
        return SizedBox(
          width: (MediaQuery.of(context).size.width - 44) / 2,
          height: 100,
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedChargeType = type;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
                color: isSelected ? AppColors.primary.withOpacity(0.05) : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? AppColors.primary : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? Center(
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          type.displayName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? AppColors.primary : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Text(
                      type.description.replaceAll('\n', ' '),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimeConfiguration() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Time Unit Configuration',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Duration input
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Charge per:', style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _timeUnitDurationController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Time unit dropdown
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Unit:', style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<TimeUnit>(
                        value: _selectedTimeUnit,
                        isDense: true,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: TimeUnit.values.map((unit) {
                          return DropdownMenuItem(
                            value: unit,
                            child: Text(unit.displayName, style: const TextStyle(fontSize: 14)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedTimeUnit = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Example: Charge per ${_timeUnitDurationController.text} ${_selectedTimeUnit.displayName.toLowerCase()}${int.tryParse(_timeUnitDurationController.text) != 1 ? 's' : ''}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimumChargeTime() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Grace Period (minutes)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'No charge if exit within this time',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 80,
              child: TextFormField(
                controller: _minimumChargeController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixText: 'min',
                  suffixStyle: const TextStyle(fontSize: 12),
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParkingRateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Parking Rate',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Set parking capacity and rate for each vehicle type',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        ..._vehicleRates.map((rate) => _buildVehicleRateItem(rate)),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: _showAddVehicleDialog,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Vehicle'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleRateItem(VehicleRate rate) {
    final capacityController = TextEditingController(text: rate.capacity.toString());
    final rateController = TextEditingController(text: rate.rate.toStringAsFixed(0));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Checkbox(
                  value: rate.isEnabled,
                  onChanged: (value) {
                    setState(() {
                      final index = _vehicleRates.indexOf(rate);
                      _vehicleRates[index] = rate.copyWith(isEnabled: value);
                    });
                  },
                  activeColor: AppColors.primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                Text(
                  rate.icon,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rate.vehicleType,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (!['Cycle', 'Bike', 'Car', 'Auto', 'E-Rickshaw', 'Bus', 'Truck']
                    .contains(rate.vehicleType))
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () {
                      setState(() {
                        _vehicleRates.remove(rate);
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Capacity',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 2),
                      TextFormField(
                        controller: capacityController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          border: UnderlineInputBorder(),
                        ),
                        style: const TextStyle(fontSize: 14),
                        onChanged: (value) {
                          final index = _vehicleRates.indexOf(rate);
                          _vehicleRates[index] = rate.copyWith(
                            capacity: int.tryParse(value) ?? 0,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rate*',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 2),
                      TextFormField(
                        controller: rateController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          border: UnderlineInputBorder(),
                        ),
                        style: const TextStyle(fontSize: 14),
                        onChanged: (value) {
                          final index = _vehicleRates.indexOf(rate);
                          _vehicleRates[index] = rate.copyWith(
                            rate: double.tryParse(value) ?? 0,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherInformationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Other Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              _buildInfoToggle(
                'Capture vehicle number?',
                _captureVehicleNumber,
                (value) {
                  setState(() {
                    _captureVehicleNumber = value;
                  });
                },
              ),
              const Divider(height: 1),
              _buildInfoToggle(
                'Capture owner name?',
                _captureOwnerName,
                (value) {
                  setState(() {
                    _captureOwnerName = value;
                  });
                },
              ),
              const Divider(height: 1),
              _buildInfoToggle(
                'Capture phone number?',
                _capturePhoneNumber,
                (value) {
                  setState(() {
                    _capturePhoneNumber = value;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoToggle(String title, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => onChanged(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: value ? AppColors.primary : null,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(3),
                        bottomLeft: Radius.circular(3),
                      ),
                    ),
                    child: Text(
                      'Yes',
                      style: TextStyle(
                        fontSize: 12,
                        color: value ? Colors.white : Colors.black87,
                        fontWeight: value ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: Colors.grey.shade300,
                ),
                InkWell(
                  onTap: () => onChanged(false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: !value ? AppColors.primary : null,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(3),
                        bottomRight: Radius.circular(3),
                      ),
                    ),
                    child: Text(
                      'No',
                      style: TextStyle(
                        fontSize: 12,
                        color: !value ? Colors.white : Colors.black87,
                        fontWeight: !value ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddVehicleDialog() {
    final nameController = TextEditingController();
    final iconController = TextEditingController(text: '🚗');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Vehicle Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Vehicle Name',
                hintText: 'e.g., Mini Van',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: iconController,
              decoration: const InputDecoration(
                labelText: 'Icon (Emoji)',
                hintText: 'e.g., 🚐',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  _vehicleRates.add(VehicleRate(
                    vehicleType: nameController.text,
                    icon: iconController.text.isEmpty ? '🚗' : iconController.text,
                    capacity: 10,
                    rate: 50,
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _saveSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final settingsProvider = context.read<SettingsProvider>();
      final currentSettings = settingsProvider.settings;
      
      final newParkingCharges = ParkingCharges(
        chargeType: _selectedChargeType,
        vehicleRates: _vehicleRates,
        timeUnit: _selectedTimeUnit,
        timeUnitDuration: int.tryParse(_timeUnitDurationController.text) ?? 1,
        captureVehicleNumber: _captureVehicleNumber,
        captureOwnerName: _captureOwnerName,
        capturePhoneNumber: _capturePhoneNumber,
        minimumChargeMinutes: int.tryParse(_minimumChargeController.text) ?? 30,
      );

      EnhancedBusinessSettings newSettings;
      if (currentSettings is EnhancedBusinessSettings) {
        newSettings = currentSettings.copyWith(
          parkingCharges: newParkingCharges,
        );
      } else {
        newSettings = EnhancedBusinessSettings(
          businessName: currentSettings.businessName,
          address: currentSettings.address,
          city: currentSettings.city,
          contactNumber: currentSettings.contactNumber,
          showContactOnReceipt: currentSettings.showContactOnReceipt,
          paperSize: currentSettings.paperSize,
          autoPrint: currentSettings.autoPrint,
          primaryPrinterId: currentSettings.primaryPrinterId,
          parkingCharges: newParkingCharges,
        );
      }

      await settingsProvider.updateBusinessSettings(newSettings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Parking charges saved successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}