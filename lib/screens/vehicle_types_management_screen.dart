import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/custom_vehicle_type.dart';
import '../models/pricing_tier.dart';
import '../providers/settings_provider.dart';
import '../models/enhanced_business_settings.dart';
import '../utils/constants.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/loading_button.dart';

class VehicleTypesManagementScreen extends StatefulWidget {
  const VehicleTypesManagementScreen({super.key});

  @override
  State<VehicleTypesManagementScreen> createState() =>
      _VehicleTypesManagementScreenState();
}

class _VehicleTypesManagementScreenState
    extends State<VehicleTypesManagementScreen> {
  late List<CustomVehicleType> _vehicleTypes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>().settings;
    if (settings is EnhancedBusinessSettings) {
      _vehicleTypes = List.from(settings.customVehicleTypes);
    } else {
      _vehicleTypes = DefaultVehicleTypes.getDefaults();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Vehicle Categories',
        showBackButton: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _vehicleTypes.length,
              itemBuilder: (context, index) {
                final vehicleType = _vehicleTypes[index];
                return _buildVehicleTypeCard(vehicleType, index);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                LoadingButton(
                  onPressed: _addNewVehicleType,
                  isLoading: false,
                  backgroundColor: AppColors.accent,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add),
                      SizedBox(width: 8),
                      Text('Add New Vehicle Type'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                LoadingButton(
                  onPressed: _saveChanges,
                  isLoading: _isLoading,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.save),
                      SizedBox(width: 8),
                      Text('Save Changes'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleTypeCard(CustomVehicleType vehicleType, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    vehicleType.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicleType.displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        vehicleType.currentRateDisplay,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: vehicleType.isActive,
                  onChanged: (value) {
                    setState(() {
                      _vehicleTypes[index] = vehicleType.copyWith(
                        isActive: value,
                      );
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editVehicleType(vehicleType, index),
                ),
                if (_vehicleTypes.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteVehicleType(index),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Pricing Tiers:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            ...vehicleType.pricingTiers.map((tier) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${tier.displayName}: Rs.${tier.ratePerHour.toStringAsFixed(0)}/hr',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  void _addNewVehicleType() {
    _editVehicleType(null, -1);
  }

  void _editVehicleType(CustomVehicleType? vehicleType, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VehicleTypeEditorScreen(
          vehicleType: vehicleType,
          onSave: (editedType) {
            setState(() {
              if (index == -1) {
                _vehicleTypes.add(editedType);
              } else {
                _vehicleTypes[index] = editedType;
              }
            });
          },
        ),
      ),
    );
  }

  void _deleteVehicleType(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vehicle Type'),
        content: Text(
          'Are you sure you want to delete "${_vehicleTypes[index].displayName}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _vehicleTypes.removeAt(index);
              });
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _saveChanges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final settingsProvider = context.read<SettingsProvider>();
      final currentSettings = settingsProvider.settings;

      EnhancedBusinessSettings updatedSettings;
      if (currentSettings is EnhancedBusinessSettings) {
        updatedSettings = currentSettings.copyWith(
          customVehicleTypes: _vehicleTypes,
        );
      } else {
        // Convert old settings to enhanced settings
        updatedSettings = EnhancedBusinessSettings(
          businessName: currentSettings.businessName,
          address: currentSettings.address,
          city: currentSettings.city,
          contactNumber: currentSettings.contactNumber,
          showContactOnReceipt: currentSettings.showContactOnReceipt,
          paperSize: currentSettings.paperSize,
          autoPrint: currentSettings.autoPrint,
          primaryPrinterId: currentSettings.primaryPrinterId,
          customVehicleTypes: _vehicleTypes,
        );
      }

      await settingsProvider.updateBusinessSettings(updatedSettings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vehicle types updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save changes: ${e.toString()}'),
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

class VehicleTypeEditorScreen extends StatefulWidget {
  final CustomVehicleType? vehicleType;
  final Function(CustomVehicleType) onSave;

  const VehicleTypeEditorScreen({
    super.key,
    this.vehicleType,
    required this.onSave,
  });

  @override
  State<VehicleTypeEditorScreen> createState() =>
      _VehicleTypeEditorScreenState();
}

class _VehicleTypeEditorScreenState extends State<VehicleTypeEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _displayNameController;
  late TextEditingController _iconController;
  late List<PricingTier> _pricingTiers;
  bool _isActive = true;
  bool _requiresVehicleNumber = true;

  final List<String> _iconOptions = [
    '🚲', '🛴', '🏍️', '🚗', '🚙', '🚐', '🚚', '🚛', '🛺', '🚌'
  ];

  @override
  void initState() {
    super.initState();
    final vehicleType = widget.vehicleType;
    
    _nameController = TextEditingController(
      text: vehicleType?.name ?? '',
    );
    _displayNameController = TextEditingController(
      text: vehicleType?.displayName ?? '',
    );
    _iconController = TextEditingController(
      text: vehicleType?.icon ?? '🚗',
    );
    _pricingTiers = vehicleType?.pricingTiers.map((tier) => tier).toList() ?? [
      PricingTier(
        startHour: 0,
        endHour: null,
        ratePerHour: 50.0,
        displayName: 'Standard Rate',
      ),
    ];
    _isActive = vehicleType?.isActive ?? true;
    _requiresVehicleNumber = vehicleType?.requiresVehicleNumber ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _displayNameController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.vehicleType == null ? 'Add Vehicle Type' : 'Edit Vehicle Type',
        showBackButton: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildBasicInfoSection(),
            const SizedBox(height: 24),
            _buildPricingSection(),
            const SizedBox(height: 32),
            LoadingButton(
              onPressed: _saveVehicleType,
              isLoading: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.save),
                  SizedBox(width: 8),
                  Text('Save Vehicle Type'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Basic Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Internal Name',
                hintText: 'e.g., twoWheeler',
                prefixIcon: Icon(Icons.tag),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an internal name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _displayNameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                hintText: 'e.g., Two Wheeler',
                prefixIcon: Icon(Icons.label),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a display name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _iconController,
                    decoration: const InputDecoration(
                      labelText: 'Icon',
                      prefixIcon: Icon(Icons.emoji_emotions),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select an icon';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _iconController.text.isEmpty ? '🚗' : _iconController.text,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _iconOptions.map((icon) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _iconController.text = icon;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _iconController.text == icon
                            ? AppColors.primary
                            : Colors.grey,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Active:'),
                const SizedBox(width: 8),
                Switch(
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Vehicle Number Requirement',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Require vehicle number for entry',
                            style: TextStyle(color: Colors.orange.shade800),
                          ),
                        ),
                        Switch(
                          value: _requiresVehicleNumber,
                          onChanged: (value) {
                            setState(() {
                              _requiresVehicleNumber = value;
                            });
                          },
                        ),
                      ],
                    ),
                    if (!_requiresVehicleNumber)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Note: Vehicles without numbers will be issued tickets with auto-generated IDs',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Pricing Tiers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _addPricingTier,
                  icon: const Icon(Icons.add),
                  color: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._pricingTiers.asMap().entries.map((entry) {
              final index = entry.key;
              final tier = entry.value;
              return _buildPricingTierCard(tier, index);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingTierCard(PricingTier tier, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tier.displayName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (_pricingTiers.length > 1)
                  IconButton(
                    onPressed: () => _removePricingTier(index),
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text('From ${tier.startHour} hours'),
                ),
                Expanded(
                  child: Text(
                    tier.endHour != null 
                        ? 'To ${tier.endHour} hours'
                        : 'No limit',
                  ),
                ),
                Expanded(
                  child: Text('Rs.${tier.ratePerHour.toStringAsFixed(0)}/hr'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _editPricingTier(tier, index),
              child: const Text('Edit'),
            ),
          ],
        ),
      ),
    );
  }

  void _addPricingTier() {
    final lastTier = _pricingTiers.last;
    final newTier = PricingTier(
      startHour: lastTier.endHour ?? (lastTier.startHour + 1),
      endHour: null,
      ratePerHour: 50.0,
      displayName: 'Extended Rate',
    );
    
    setState(() {
      _pricingTiers.add(newTier);
    });
  }

  void _removePricingTier(int index) {
    setState(() {
      _pricingTiers.removeAt(index);
    });
  }

  void _editPricingTier(PricingTier tier, int index) {
    showDialog(
      context: context,
      builder: (context) => PricingTierDialog(
        tier: tier,
        onSave: (updatedTier) {
          setState(() {
            _pricingTiers[index] = updatedTier;
          });
        },
      ),
    );
  }

  void _saveVehicleType() {
    if (_formKey.currentState!.validate() && _pricingTiers.isNotEmpty) {
      final vehicleType = CustomVehicleType(
        id: widget.vehicleType?.id ?? _nameController.text.toLowerCase(),
        name: _nameController.text,
        displayName: _displayNameController.text,
        icon: _iconController.text,
        pricingTiers: _pricingTiers,
        isActive: _isActive,
        sortOrder: widget.vehicleType?.sortOrder ?? 0,
        requiresVehicleNumber: _requiresVehicleNumber,
      );

      widget.onSave(vehicleType);
      Navigator.of(context).pop();
    } else if (_pricingTiers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one pricing tier'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

class PricingTierDialog extends StatefulWidget {
  final PricingTier tier;
  final Function(PricingTier) onSave;

  const PricingTierDialog({
    super.key,
    required this.tier,
    required this.onSave,
  });

  @override
  State<PricingTierDialog> createState() => _PricingTierDialogState();
}

class _PricingTierDialogState extends State<PricingTierDialog> {
  late TextEditingController _displayNameController;
  late TextEditingController _startHourController;
  late TextEditingController _endHourController;
  late TextEditingController _rateController;
  bool _hasEndHour = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(text: widget.tier.displayName);
    _startHourController = TextEditingController(text: widget.tier.startHour.toString());
    _endHourController = TextEditingController(
      text: widget.tier.endHour?.toString() ?? '',
    );
    _rateController = TextEditingController(text: widget.tier.ratePerHour.toString());
    _hasEndHour = widget.tier.endHour != null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Pricing Tier'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _displayNameController,
              decoration: const InputDecoration(labelText: 'Display Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _startHourController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Start Hour'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _hasEndHour,
                  onChanged: (value) {
                    setState(() {
                      _hasEndHour = value!;
                    });
                  },
                ),
                const Text('Has End Hour'),
              ],
            ),
            if (_hasEndHour) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _endHourController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'End Hour'),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _rateController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Rate per Hour'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final updatedTier = PricingTier(
              startHour: int.tryParse(_startHourController.text) ?? 0,
              endHour: _hasEndHour ? int.tryParse(_endHourController.text) : null,
              ratePerHour: double.tryParse(_rateController.text) ?? 0.0,
              displayName: _displayNameController.text,
            );
            widget.onSave(updatedTier);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _startHourController.dispose();
    _endHourController.dispose();
    _rateController.dispose();
    super.dispose();
  }
}