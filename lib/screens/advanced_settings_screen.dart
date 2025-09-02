import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/enhanced_business_settings.dart';
import '../models/business_settings.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/loading_button.dart';
import 'vehicle_types_management_screen.dart';
import 'parking_charges_screen.dart';

class AdvancedSettingsScreen extends StatefulWidget {
  const AdvancedSettingsScreen({super.key});

  @override
  State<AdvancedSettingsScreen> createState() => _AdvancedSettingsScreenState();
}

class _AdvancedSettingsScreenState extends State<AdvancedSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for form fields
  late TextEditingController _businessNameController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _contactController;
  late TextEditingController _minimumParkingController;
  late TextEditingController _gracePeriodController;
  late TextEditingController _receiptFooterController;
  
  // Form state variables
  late bool _showContactOnReceipt;
  late bool _autoPrint;
  late bool _enableGracePeriod;
  late bool _showQrCode;
  late PaperSize _paperSize;
  VehicleNumberConfig? _vehicleNumberConfig;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final settings = context.read<SettingsProvider>().settings;
    
    EnhancedBusinessSettings enhancedSettings;
    if (settings is EnhancedBusinessSettings) {
      enhancedSettings = settings;
    } else {
      // Convert old settings to enhanced
      enhancedSettings = EnhancedBusinessSettings(
        businessName: settings.businessName,
        address: settings.address,
        city: settings.city,
        contactNumber: settings.contactNumber,
        showContactOnReceipt: settings.showContactOnReceipt,
        paperSize: settings.paperSize,
        autoPrint: settings.autoPrint,
        primaryPrinterId: settings.primaryPrinterId,
      );
    }

    _businessNameController = TextEditingController(text: enhancedSettings.businessName);
    _addressController = TextEditingController(text: enhancedSettings.address);
    _cityController = TextEditingController(text: enhancedSettings.city);
    _contactController = TextEditingController(text: enhancedSettings.contactNumber);
    _minimumParkingController = TextEditingController(
      text: enhancedSettings.minimumParkingMinutes.toString(),
    );
    _gracePeriodController = TextEditingController(
      text: enhancedSettings.gracePeriodMinutes.toString(),
    );
    _receiptFooterController = TextEditingController(text: enhancedSettings.receiptFooter);

    _showContactOnReceipt = enhancedSettings.showContactOnReceipt;
    _autoPrint = enhancedSettings.autoPrint;
    _enableGracePeriod = enhancedSettings.enableGracePeriod;
    _showQrCode = enhancedSettings.showQrCode;
    _paperSize = enhancedSettings.paperSize;
    _vehicleNumberConfig = enhancedSettings.vehicleNumberConfig;
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _contactController.dispose();
    _minimumParkingController.dispose();
    _gracePeriodController.dispose();
    _receiptFooterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Advanced Settings',
        showBackButton: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildBusinessInfoSection(),
            const SizedBox(height: 24),
            _buildVehicleNumberSection(),
            const SizedBox(height: 24),
            _buildParkingSettingsSection(),
            const SizedBox(height: 24),
            _buildReceiptSettingsSection(),
            const SizedBox(height: 24),
            _buildManagementSection(),
            const SizedBox(height: 32),
            LoadingButton(
              onPressed: _saveSettings,
              isLoading: _isLoading,
              child: const Text('Save Settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Business Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _businessNameController,
              decoration: const InputDecoration(
                labelText: 'Business Name',
                prefixIcon: Icon(Icons.business),
              ),
              validator: (value) => value?.isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                prefixIcon: Icon(Icons.location_on),
              ),
              validator: (value) => value?.isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'City',
                prefixIcon: Icon(Icons.location_city),
              ),
              validator: (value) => value?.isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contactController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Contact Number',
                prefixIcon: Icon(Icons.phone),
              ),
              validator: (value) => value?.isEmpty == true ? 'Required' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleNumberSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vehicle Number Configuration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Enable State Prefix:'),
                const Spacer(),
                Switch(
                  value: _vehicleNumberConfig?.isEnabled ?? false,
                  onChanged: (value) {
                    setState(() {
                      if (value && _vehicleNumberConfig == null) {
                        _vehicleNumberConfig = VehicleNumberConfig(
                          stateCode: 'DL',
                          stateName: 'Delhi',
                          isEnabled: true,
                        );
                      } else if (_vehicleNumberConfig != null) {
                        _vehicleNumberConfig = _vehicleNumberConfig!.copyWith(
                          isEnabled: value,
                        );
                      }
                    });
                  },
                ),
              ],
            ),
            if (_vehicleNumberConfig?.isEnabled == true) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _vehicleNumberConfig?.stateCode,
                decoration: const InputDecoration(
                  labelText: 'Select State',
                  prefixIcon: Icon(Icons.map),
                ),
                items: IndianStateCodes.stateCodes.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text('${entry.key} - ${entry.value}'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _vehicleNumberConfig = VehicleNumberConfig(
                        stateCode: value,
                        stateName: IndianStateCodes.stateCodes[value]!,
                        isEnabled: true,
                      );
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Format Preview: ${_vehicleNumberConfig?.displayFormat ?? 'XX-##-XX-####'}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildParkingSettingsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Parking Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _minimumParkingController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Minimum Parking Duration (minutes)',
                prefixIcon: Icon(Icons.timer),
                suffixText: 'min',
              ),
              validator: (value) {
                if (value?.isEmpty == true) return 'Required';
                if (int.tryParse(value!) == null) return 'Invalid number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Enable Grace Period:'),
                const Spacer(),
                Switch(
                  value: _enableGracePeriod,
                  onChanged: (value) {
                    setState(() {
                      _enableGracePeriod = value;
                    });
                  },
                ),
              ],
            ),
            if (_enableGracePeriod) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _gracePeriodController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Grace Period Duration (minutes)',
                  prefixIcon: Icon(Icons.schedule),
                  suffixText: 'min',
                ),
                validator: (value) {
                  if (_enableGracePeriod && value?.isEmpty == true) {
                    return 'Required';
                  }
                  if (value?.isNotEmpty == true && int.tryParse(value!) == null) {
                    return 'Invalid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Customers won\'t be charged if they exit within the grace period.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptSettingsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Receipt Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Show Contact on Receipt:'),
                const Spacer(),
                Switch(
                  value: _showContactOnReceipt,
                  onChanged: (value) {
                    setState(() {
                      _showContactOnReceipt = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Auto-Print Receipts:'),
                const Spacer(),
                Switch(
                  value: _autoPrint,
                  onChanged: (value) {
                    setState(() {
                      _autoPrint = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Show QR Code:'),
                const Spacer(),
                Switch(
                  value: _showQrCode,
                  onChanged: (value) {
                    setState(() {
                      _showQrCode = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PaperSize>(
              value: _paperSize,
              decoration: const InputDecoration(
                labelText: 'Paper Size',
                prefixIcon: Icon(Icons.print),
              ),
              items: PaperSize.values.map((size) {
                return DropdownMenuItem(
                  value: size,
                  child: Text(size.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _paperSize = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _receiptFooterController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Receipt Footer Message',
                prefixIcon: Icon(Icons.message),
                hintText: 'Thank you for choosing us!',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Management',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.directions_car, color: AppColors.primary),
              title: const Text('Manage Vehicle Types'),
              subtitle: const Text('Add, edit, or remove vehicle categories and pricing'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const VehicleTypesManagementScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.attach_money, color: AppColors.primary),
              title: const Text('Parking Charges'),
              subtitle: const Text('Configure pricing and charge types'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ParkingChargesScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.print, color: AppColors.primary),
              title: const Text('Printer Settings'),
              subtitle: const Text('Configure Bluetooth printers'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.of(context).pushNamed('/printer_settings');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final settingsProvider = context.read<SettingsProvider>();
      final currentSettings = settingsProvider.settings;

      EnhancedBusinessSettings newSettings;
      if (currentSettings is EnhancedBusinessSettings) {
        newSettings = currentSettings.copyWith(
          businessName: _businessNameController.text,
          address: _addressController.text,
          city: _cityController.text,
          contactNumber: _contactController.text,
          showContactOnReceipt: _showContactOnReceipt,
          paperSize: _paperSize,
          autoPrint: _autoPrint,
          vehicleNumberConfig: _vehicleNumberConfig,
          minimumParkingMinutes: int.tryParse(_minimumParkingController.text) ?? 30,
          enableGracePeriod: _enableGracePeriod,
          gracePeriodMinutes: int.tryParse(_gracePeriodController.text) ?? 15,
          receiptFooter: _receiptFooterController.text,
          showQrCode: _showQrCode,
        );
      } else {
        newSettings = EnhancedBusinessSettings(
          businessName: _businessNameController.text,
          address: _addressController.text,
          city: _cityController.text,
          contactNumber: _contactController.text,
          showContactOnReceipt: _showContactOnReceipt,
          paperSize: _paperSize,
          autoPrint: _autoPrint,
          primaryPrinterId: currentSettings.primaryPrinterId,
          vehicleNumberConfig: _vehicleNumberConfig,
          minimumParkingMinutes: int.tryParse(_minimumParkingController.text) ?? 30,
          enableGracePeriod: _enableGracePeriod,
          gracePeriodMinutes: int.tryParse(_gracePeriodController.text) ?? 15,
          receiptFooter: _receiptFooterController.text,
          showQrCode: _showQrCode,
        );
      }

      await settingsProvider.updateBusinessSettings(newSettings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
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