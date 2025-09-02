import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/enhanced_business_settings.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';

class VehicleNumberInput extends StatefulWidget {
  final TextEditingController controller;
  final String? errorText;
  final Function(String)? onChanged;
  final bool enabled;

  const VehicleNumberInput({
    super.key,
    required this.controller,
    this.errorText,
    this.onChanged,
    this.enabled = true,
  });

  @override
  State<VehicleNumberInput> createState() => _VehicleNumberInputState();
}

class _VehicleNumberInputState extends State<VehicleNumberInput> {
  late TextEditingController _localController;
  String _prefix = '';

  @override
  void initState() {
    super.initState();
    _localController = TextEditingController();
    _updatePrefix();
    
    // Parse existing value if any
    if (widget.controller.text.isNotEmpty) {
      _parseExistingValue();
    }
    
    _localController.addListener(_onLocalTextChanged);
  }

  void _updatePrefix() {
    final settingsProvider = context.read<SettingsProvider>();
    final settings = settingsProvider.settings;
    
    if (settings is EnhancedBusinessSettings && 
        settings.vehicleNumberConfig != null && 
        settings.vehicleNumberConfig!.isEnabled) {
      _prefix = '${settings.vehicleNumberConfig!.stateCode}-';
    } else {
      _prefix = '';
    }
  }

  void _parseExistingValue() {
    final fullValue = widget.controller.text;
    if (_prefix.isNotEmpty && fullValue.startsWith(_prefix)) {
      _localController.text = fullValue.substring(_prefix.length);
    } else {
      _localController.text = fullValue;
    }
  }

  void _onLocalTextChanged() {
    final localValue = _localController.text.toUpperCase();
    final fullValue = _prefix + localValue;
    
    widget.controller.text = fullValue;
    widget.onChanged?.call(fullValue);
  }

  @override
  void dispose() {
    _localController.removeListener(_onLocalTextChanged);
    _localController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final settings = settingsProvider.settings;
        final hasPrefix = settings is EnhancedBusinessSettings && 
            settings.vehicleNumberConfig != null && 
            settings.vehicleNumberConfig!.isEnabled;

        if (hasPrefix && settings is EnhancedBusinessSettings && 
            settings.vehicleNumberConfig != null &&
            _prefix != '${settings.vehicleNumberConfig!.stateCode}-') {
          _prefix = '${settings.vehicleNumberConfig!.stateCode}-';
          _onLocalTextChanged();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (hasPrefix) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                      ),
                    ),
                    child: Text(
                      _prefix.substring(0, _prefix.length - 1), // Remove the '-'
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 56,
                    color: AppColors.primary,
                  ),
                ],
                Expanded(
                  child: TextFormField(
                    controller: _localController,
                    enabled: widget.enabled,
                    textCapitalization: TextCapitalization.characters,
                    keyboardType: TextInputType.text,
                    inputFormatters: [
                      UpperCaseTextFormatter(),
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^[0-9]{0,2}[A-Z]{0,2}[0-9]{0,4}$'),
                      ),
                      LengthLimitingTextInputFormatter(10),
                    ],
                    decoration: InputDecoration(
                      labelText: hasPrefix ? 'Vehicle Number' : 'Full Vehicle Number',
                      hintText: hasPrefix ? 'XX XX XXXX' : 'UP-32-AB-1234',
                      errorText: widget.errorText,
                      prefixIcon: const Icon(Icons.directions_car),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: hasPrefix ? Radius.zero : const Radius.circular(8),
                          bottomLeft: hasPrefix ? Radius.zero : const Radius.circular(8),
                          topRight: const Radius.circular(8),
                          bottomRight: const Radius.circular(8),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (hasPrefix) ...[
              const SizedBox(height: 8),
              Text(
                'Format: ${(settings as EnhancedBusinessSettings).vehicleNumberConfig!.displayFormat}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}