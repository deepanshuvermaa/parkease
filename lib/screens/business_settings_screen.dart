import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/business_settings.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';

class BusinessSettingsScreen extends StatefulWidget {
  const BusinessSettingsScreen({super.key});

  @override
  State<BusinessSettingsScreen> createState() => _BusinessSettingsScreenState();
}

class _BusinessSettingsScreenState extends State<BusinessSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _businessNameController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _contactController;
  late bool _showContactOnReceipt;
  late PaperSize _paperSize;
  late bool _autoPrint;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>().settings;
    _businessNameController = TextEditingController(text: settings.businessName);
    _addressController = TextEditingController(text: settings.address);
    _cityController = TextEditingController(text: settings.city);
    _contactController = TextEditingController(text: settings.contactNumber);
    _showContactOnReceipt = settings.showContactOnReceipt;
    _paperSize = settings.paperSize;
    _autoPrint = settings.autoPrint;
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.businessSettings),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Business Information'),
              _buildTextField(
                controller: _businessNameController,
                label: 'Business Name',
                icon: Icons.business,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter business name';
                  }
                  return null;
                },
              ),
              _buildTextField(
                controller: _addressController,
                label: 'Address',
                icon: Icons.location_on,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter address';
                  }
                  return null;
                },
              ),
              _buildTextField(
                controller: _cityController,
                label: 'City',
                icon: Icons.location_city,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter city';
                  }
                  return null;
                },
              ),
              _buildTextField(
                controller: _contactController,
                label: 'Contact Number',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter contact number';
                  }
                  if (value.length < 10) {
                    return 'Please enter valid contact number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildSectionTitle('Receipt Settings'),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Show Contact on Receipt'),
                      subtitle: const Text('Display contact number on printed receipts'),
                      value: _showContactOnReceipt,
                      onChanged: (value) {
                        setState(() {
                          _showContactOnReceipt = value;
                        });
                      },
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('Paper Size'),
                      subtitle: Text(_paperSize.displayName),
                      trailing: DropdownButton<PaperSize>(
                        value: _paperSize,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _paperSize = value;
                            });
                          }
                        },
                        items: PaperSize.values.map((size) {
                          return DropdownMenuItem(
                            value: size,
                            child: Text(size.displayName),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildSectionTitle('Printing Preferences'),
              Card(
                child: SwitchListTile(
                  title: const Text('Auto Print'),
                  subtitle: const Text('Automatically print receipts after entry/exit'),
                  value: _autoPrint,
                  onChanged: (value) {
                    setState(() {
                      _autoPrint = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveSettings,
                  child: const Text('Save Settings'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: AppFontSize.lg,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        validator: validator,
      ),
    );
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final settingsProvider = context.read<SettingsProvider>();
    final newSettings = BusinessSettings(
      businessName: _businessNameController.text,
      address: _addressController.text,
      city: _cityController.text,
      contactNumber: _contactController.text,
      showContactOnReceipt: _showContactOnReceipt,
      paperSize: _paperSize,
      autoPrint: _autoPrint,
      primaryPrinterId: settingsProvider.settings.primaryPrinterId,
    );

    await settingsProvider.updateBusinessSettings(newSettings);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }
}