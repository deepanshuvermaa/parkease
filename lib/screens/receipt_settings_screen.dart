import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/enhanced_business_settings.dart';
import '../models/ticket_id_settings.dart';
import '../models/print_customization.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';
import '../widgets/loading_button.dart';

class ReceiptSettingsScreen extends StatefulWidget {
  const ReceiptSettingsScreen({super.key});

  @override
  State<ReceiptSettingsScreen> createState() => _ReceiptSettingsScreenState();
}

class _ReceiptSettingsScreenState extends State<ReceiptSettingsScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  
  // Ticket ID Settings
  TicketIdFormat _selectedFormat = TicketIdFormat.simple;
  final _customPatternController = TextEditingController();
  final _prefixController = TextEditingController();
  final _startNumberController = TextEditingController();
  bool _resetDaily = false;
  bool _includeLocation = false;
  
  // Print Customization
  double _businessNameSize = 24;
  double _addressSize = 12;
  double _ticketIdSize = 32;
  double _labelSize = 12;
  double _valueSize = 14;
  double _totalLabelSize = 16;
  double _totalValueSize = 18;
  double _footerSize = 10;
  double _poweredBySize = 10;
  
  bool _boldBusinessName = true;
  bool _boldTicketId = true;
  bool _boldTotal = true;
  bool _centerAlign = true;
  bool _printDashedLine = true;
  
  // Receipt Footer
  final _receiptFooterController = TextEditingController();
  bool _showQrCode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSettings();
  }

  void _loadSettings() {
    final settings = context.read<SettingsProvider>().settings;
    
    if (settings is EnhancedBusinessSettings) {
      // Load Ticket ID Settings
      if (settings.ticketIdSettings != null) {
        final ticketSettings = settings.ticketIdSettings!;
        _selectedFormat = ticketSettings.format;
        _customPatternController.text = ticketSettings.customPattern;
        _prefixController.text = ticketSettings.prefix;
        _startNumberController.text = ticketSettings.sequenceCounter.toString();
        _resetDaily = ticketSettings.resetDaily;
        _includeLocation = ticketSettings.includeLocation;
      }
      
      // Load Print Customization
      if (settings.printCustomization != null) {
        final printSettings = settings.printCustomization!;
        _businessNameSize = printSettings.businessNameSize;
        _addressSize = printSettings.addressSize;
        _ticketIdSize = printSettings.ticketIdSize;
        _labelSize = printSettings.labelSize;
        _valueSize = printSettings.valueSize;
        _totalLabelSize = printSettings.totalLabelSize;
        _totalValueSize = printSettings.totalValueSize;
        _footerSize = printSettings.footerSize;
        _poweredBySize = printSettings.poweredBySize;
        _boldBusinessName = printSettings.boldBusinessName;
        _boldTicketId = printSettings.boldTicketId;
        _boldTotal = printSettings.boldTotal;
        _centerAlign = printSettings.centerAlign;
        _printDashedLine = printSettings.printDashedLine;
      }
      
      // Load Receipt Footer
      _receiptFooterController.text = settings.receiptFooter;
      _showQrCode = settings.showQrCode;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customPatternController.dispose();
    _prefixController.dispose();
    _startNumberController.dispose();
    _receiptFooterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Settings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Ticket ID'),
            Tab(text: 'Font Sizes'),
            Tab(text: 'Footer'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTicketIdTab(),
          _buildFontSizesTab(),
          _buildFooterTab(),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: LoadingButton(
          onPressed: _saveSettings,
          isLoading: _isLoading,
          child: const Text('Save Settings'),
        ),
      ),
    );
  }

  Widget _buildTicketIdTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ticket ID Format',
                    style: TextStyle(
                      fontSize: AppFontSize.lg,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  // Format Selection
                  ...TicketIdFormat.values.map((format) => RadioListTile<TicketIdFormat>(
                    title: Text(format.displayName),
                    subtitle: Text(
                      _getFormatExample(format),
                      style: const TextStyle(fontSize: AppFontSize.sm),
                    ),
                    value: format,
                    groupValue: _selectedFormat,
                    onChanged: (value) {
                      setState(() {
                        _selectedFormat = value!;
                      });
                    },
                  )),
                  
                  // Custom Pattern Input
                  if (_selectedFormat == TicketIdFormat.custom) ...[
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _customPatternController,
                      decoration: const InputDecoration(
                        labelText: 'Custom Pattern',
                        hintText: 'e.g., PARK-{YYYY}{MM}{DD}-{SEQ:4}',
                        helperText: 'Variables: {YYYY}, {MM}, {DD}, {HH}, {mm}, {SEQ:n}, {RAND:n}, {LOC}',
                        helperMaxLines: 2,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: AppSpacing.md),
                  
                  // Additional Options
                  TextFormField(
                    controller: _prefixController,
                    decoration: const InputDecoration(
                      labelText: 'Prefix (Optional)',
                      hintText: 'e.g., TKT, PARK',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.md),
                  
                  TextFormField(
                    controller: _startNumberController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Starting Number',
                      hintText: '1',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.md),
                  
                  SwitchListTile(
                    title: const Text('Reset Daily'),
                    subtitle: const Text('Reset sequence number every day'),
                    value: _resetDaily,
                    onChanged: (value) {
                      setState(() {
                        _resetDaily = value;
                      });
                    },
                  ),
                  
                  SwitchListTile(
                    title: const Text('Include Location'),
                    subtitle: const Text('Add location code to ticket ID'),
                    value: _includeLocation,
                    onChanged: (value) {
                      setState(() {
                        _includeLocation = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // Preview Section
          const SizedBox(height: AppSpacing.md),
          Card(
            color: AppColors.primary.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Preview',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _getPreviewTicketId(),
                    style: const TextStyle(
                      fontSize: AppFontSize.xl,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFontSizesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Font Size Customization',
                    style: TextStyle(
                      fontSize: AppFontSize.lg,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  _buildSliderOption(
                    'Business Name',
                    _businessNameSize,
                    12, 48,
                    (value) => setState(() => _businessNameSize = value),
                  ),
                  
                  _buildSliderOption(
                    'Address/City',
                    _addressSize,
                    8, 20,
                    (value) => setState(() => _addressSize = value),
                  ),
                  
                  _buildSliderOption(
                    'Ticket ID',
                    _ticketIdSize,
                    16, 72,
                    (value) => setState(() => _ticketIdSize = value),
                  ),
                  
                  _buildSliderOption(
                    'Labels (Vehicle No, Type, etc)',
                    _labelSize,
                    8, 20,
                    (value) => setState(() => _labelSize = value),
                  ),
                  
                  _buildSliderOption(
                    'Values',
                    _valueSize,
                    10, 24,
                    (value) => setState(() => _valueSize = value),
                  ),
                  
                  _buildSliderOption(
                    'Total Label',
                    _totalLabelSize,
                    12, 28,
                    (value) => setState(() => _totalLabelSize = value),
                  ),
                  
                  _buildSliderOption(
                    'Total Amount',
                    _totalValueSize,
                    14, 32,
                    (value) => setState(() => _totalValueSize = value),
                  ),
                  
                  _buildSliderOption(
                    'Footer Text',
                    _footerSize,
                    8, 16,
                    (value) => setState(() => _footerSize = value),
                  ),
                  
                  _buildSliderOption(
                    'Powered By Text',
                    _poweredBySize,
                    8, 14,
                    (value) => setState(() => _poweredBySize = value),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Text Formatting',
                    style: TextStyle(
                      fontSize: AppFontSize.lg,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  SwitchListTile(
                    title: const Text('Bold Business Name'),
                    value: _boldBusinessName,
                    onChanged: (value) => setState(() => _boldBusinessName = value),
                  ),
                  
                  SwitchListTile(
                    title: const Text('Bold Ticket ID'),
                    value: _boldTicketId,
                    onChanged: (value) => setState(() => _boldTicketId = value),
                  ),
                  
                  SwitchListTile(
                    title: const Text('Bold Total Amount'),
                    value: _boldTotal,
                    onChanged: (value) => setState(() => _boldTotal = value),
                  ),
                  
                  SwitchListTile(
                    title: const Text('Center Align Header'),
                    value: _centerAlign,
                    onChanged: (value) => setState(() => _centerAlign = value),
                  ),
                  
                  SwitchListTile(
                    title: const Text('Print Dashed Lines'),
                    value: _printDashedLine,
                    onChanged: (value) => setState(() => _printDashedLine = value),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Receipt Footer',
                    style: TextStyle(
                      fontSize: AppFontSize.lg,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  TextFormField(
                    controller: _receiptFooterController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Footer Message',
                      hintText: 'Thank you for choosing us!',
                      helperText: 'This message appears before the powered by text',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.md),
                  
                  SwitchListTile(
                    title: const Text('Show QR Code'),
                    subtitle: const Text('Print QR code with ticket information'),
                    value: _showQrCode,
                    onChanged: (value) => setState(() => _showQrCode = value),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // Mandatory Footer Info
          Card(
            color: Colors.orange.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mandatory Footer',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'The text "Powered by Go2 Billing Softwares" will always appear at the bottom of receipts',
                          style: TextStyle(
                            fontSize: AppFontSize.sm,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderOption(
    String label,
    double value,
    double min,
    double max,
    Function(double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              '${value.toInt()}pt',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          label: value.toInt().toString(),
          onChanged: onChanged,
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  String _getFormatExample(TicketIdFormat format) {
    switch (format) {
      case TicketIdFormat.simple:
        return 'Example: T001, T002, T003...';
      case TicketIdFormat.dateTime:
        return 'Example: T20250102-1234';
      case TicketIdFormat.alphanumeric:
        return 'Example: TKT-AB1234';
      case TicketIdFormat.custom:
        return 'Create your own pattern';
    }
  }

  String _getPreviewTicketId() {
    String prefix = _prefixController.text.isNotEmpty ? _prefixController.text : 'T';
    
    switch (_selectedFormat) {
      case TicketIdFormat.simple:
        return '${prefix}001';
      case TicketIdFormat.dateTime:
        return '${prefix}20250102-1234';
      case TicketIdFormat.alphanumeric:
        return '${prefix}-AB1234';
      case TicketIdFormat.custom:
        if (_customPatternController.text.isEmpty) {
          return '${prefix}-CUSTOM-001';
        }
        // Show a sample based on pattern
        String pattern = _customPatternController.text;
        pattern = pattern.replaceAll('{YYYY}', '2025');
        pattern = pattern.replaceAll('{MM}', '01');
        pattern = pattern.replaceAll('{DD}', '02');
        pattern = pattern.replaceAll('{HH}', '14');
        pattern = pattern.replaceAll('{mm}', '30');
        pattern = pattern.replaceAll(RegExp(r'\{SEQ:\d+\}'), '0001');
        pattern = pattern.replaceAll(RegExp(r'\{RAND:\d+\}'), 'A1B2');
        pattern = pattern.replaceAll('{LOC}', 'LOC1');
        return pattern;
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);

    try {
      final settingsProvider = context.read<SettingsProvider>();
      final currentSettings = settingsProvider.settings;
      
      // Create new ticket ID settings
      final ticketIdSettings = TicketIdSettings(
        format: _selectedFormat,
        customPattern: _customPatternController.text,
        prefix: _prefixController.text,
        sequenceCounter: int.tryParse(_startNumberController.text) ?? 1,
        resetDaily: _resetDaily,
        includeLocation: _includeLocation,
      );
      
      // Create new print customization
      final printCustomization = PrintCustomization(
        businessNameSize: _businessNameSize,
        addressSize: _addressSize,
        ticketIdSize: _ticketIdSize,
        labelSize: _labelSize,
        valueSize: _valueSize,
        totalLabelSize: _totalLabelSize,
        totalValueSize: _totalValueSize,
        footerSize: _footerSize,
        poweredBySize: _poweredBySize,
        boldBusinessName: _boldBusinessName,
        boldTicketId: _boldTicketId,
        boldTotal: _boldTotal,
        centerAlign: _centerAlign,
        printDashedLine: _printDashedLine,
      );
      
      // Create enhanced settings with all values
      final enhancedSettings = EnhancedBusinessSettings(
        businessName: currentSettings.businessName,
        address: currentSettings.address,
        city: currentSettings.city,
        contactNumber: currentSettings.contactNumber,
        showContactOnReceipt: currentSettings.showContactOnReceipt,
        paperSize: currentSettings.paperSize,
        autoPrint: currentSettings.autoPrint,
        primaryPrinterId: currentSettings.primaryPrinterId,
        showQrCode: _showQrCode,
        receiptFooter: _receiptFooterController.text.isNotEmpty 
            ? _receiptFooterController.text 
            : 'Thank you for choosing us!',
        ticketIdSettings: ticketIdSettings,
        printCustomization: printCustomization,
        customVehicleTypes: currentSettings is EnhancedBusinessSettings 
            ? currentSettings.customVehicleTypes 
            : null,
        parkingCharges: currentSettings is EnhancedBusinessSettings 
            ? currentSettings.parkingCharges 
            : null,
        vehicleNumberConfig: currentSettings is EnhancedBusinessSettings 
            ? currentSettings.vehicleNumberConfig 
            : null,
        minimumParkingMinutes: currentSettings is EnhancedBusinessSettings 
            ? currentSettings.minimumParkingMinutes 
            : 1,
        gracePeriodMinutes: currentSettings is EnhancedBusinessSettings 
            ? currentSettings.gracePeriodMinutes 
            : 5,
        enableGracePeriod: currentSettings is EnhancedBusinessSettings 
            ? currentSettings.enableGracePeriod 
            : false,
      );
      
      settingsProvider.updateSettings(enhancedSettings);
      await settingsProvider.saveSettings();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt settings saved successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}