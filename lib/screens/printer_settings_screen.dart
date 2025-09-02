import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/printer_device.dart';
import '../providers/bluetooth_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Initial scan on screen open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scanForPrinters();
    });
  }

  Future<void> _scanForPrinters() async {
    final bluetoothProvider = context.read<BluetoothProvider>();
    await bluetoothProvider.scanForPrinters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.printerSettings),
        actions: [
          Consumer<BluetoothProvider>(
            builder: (context, bluetoothProvider, _) {
              if (bluetoothProvider.isScanning) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              }
              return IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Scan for devices',
                onPressed: _scanForPrinters,
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              final bluetoothProvider = context.read<BluetoothProvider>();
              switch (value) {
                case 'show_all':
                  bluetoothProvider.setIncludeAllDevices(
                    !bluetoothProvider.includeAllDevices
                  );
                  await _scanForPrinters();
                  break;
                case 'refresh_bluetooth':
                  await bluetoothProvider.refreshBluetoothState();
                  break;
                case 'clear_default':
                  await bluetoothProvider.setDefaultPrinter(null);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Default printer cleared')),
                  );
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              final bluetoothProvider = context.read<BluetoothProvider>();
              return [
                CheckedPopupMenuItem<String>(
                  value: 'show_all',
                  checked: bluetoothProvider.includeAllDevices,
                  child: const Text('Show All Devices'),
                ),
                const PopupMenuItem<String>(
                  value: 'refresh_bluetooth',
                  child: Text('Refresh Bluetooth'),
                ),
                if (bluetoothProvider.defaultPrinterId != null)
                  const PopupMenuItem<String>(
                    value: 'clear_default',
                    child: Text('Clear Default Printer'),
                  ),
              ];
            },
          ),
        ],
      ),
      body: Consumer2<BluetoothProvider, SettingsProvider>(
        builder: (context, bluetoothProvider, settingsProvider, _) {
          return Column(
            children: [
              _buildConnectionStatus(bluetoothProvider),
              if (bluetoothProvider.lastError != null)
                _buildErrorBanner(bluetoothProvider),
              _buildScanControl(bluetoothProvider),
              Expanded(
                child: _buildPrinterList(bluetoothProvider, settingsProvider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildConnectionStatus(BluetoothProvider bluetoothProvider) {
    final isConnected = bluetoothProvider.isConnected;
    final connectedPrinter = bluetoothProvider.connectedPrinter;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: isConnected ? AppColors.success.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
      child: Row(
        children: [
          Icon(
            isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
            color: isConnected ? AppColors.success : Colors.orange,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConnected ? 'Connected' : 'Not Connected',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isConnected ? AppColors.success : Colors.orange,
                  ),
                ),
                if (connectedPrinter != null)
                  Text(
                    '${connectedPrinter.name} (${connectedPrinter.address})',
                    style: const TextStyle(fontSize: AppFontSize.sm),
                  ),
              ],
            ),
          ),
          if (isConnected) ...[
            ElevatedButton.icon(
              onPressed: () async {
                final settings = context.read<SettingsProvider>().settings;
                final success = await bluetoothProvider.testPrint(settings);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Test print sent!' : 'Test print failed'),
                      backgroundColor: success ? AppColors.success : AppColors.error,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.print),
              label: const Text('Test'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            TextButton(
              onPressed: () => bluetoothProvider.disconnectPrinter(),
              child: const Text('Disconnect'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorBanner(BluetoothProvider bluetoothProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      color: AppColors.error.withOpacity(0.1),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              bluetoothProvider.lastError!,
              style: const TextStyle(color: AppColors.error, fontSize: AppFontSize.sm),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => bluetoothProvider.clearError(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildScanControl(BluetoothProvider bluetoothProvider) {
    if (!bluetoothProvider.isScanning) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: AppColors.primary.withOpacity(0.05),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.md),
          const Expanded(
            child: Text(
              'Scanning for devices...',
              style: TextStyle(fontSize: AppFontSize.sm),
            ),
          ),
          TextButton(
            onPressed: () => bluetoothProvider.stopScanning(),
            child: const Text('Stop'),
          ),
        ],
      ),
    );
  }

  Widget _buildPrinterList(
    BluetoothProvider bluetoothProvider,
    SettingsProvider settingsProvider,
  ) {
    final printers = bluetoothProvider.availablePrinters;

    if (printers.isEmpty && !bluetoothProvider.isScanning) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bluetooth_searching,
                size: 80,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'No devices found',
                style: TextStyle(
                  fontSize: AppFontSize.lg,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                bluetoothProvider.includeAllDevices
                    ? 'Make sure Bluetooth is enabled and devices are discoverable'
                    : 'Make sure your printer is paired in Bluetooth settings',
                style: const TextStyle(
                  fontSize: AppFontSize.sm,
                  color: AppColors.textLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: _scanForPrinters,
                icon: const Icon(Icons.refresh),
                label: const Text('Scan Again'),
              ),
              if (!bluetoothProvider.includeAllDevices) ...[
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () {
                    bluetoothProvider.setIncludeAllDevices(true);
                    _scanForPrinters();
                  },
                  child: const Text('Show all Bluetooth devices'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: printers.length,
      itemBuilder: (context, index) {
        final printer = printers[index];
        final isDefault = printer.isDefault;
        final isConnected = bluetoothProvider.connectedPrinter?.id == printer.id;

        return Card(
          elevation: isConnected ? 4 : 1,
          color: isConnected ? AppColors.success.withOpacity(0.05) : null,
          child: ListTile(
            leading: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Icon(
                  Icons.print,
                  size: 32,
                  color: isConnected 
                      ? AppColors.success 
                      : printer.isBonded 
                          ? AppColors.primary 
                          : AppColors.textSecondary,
                ),
                if (isDefault)
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: const Icon(
                      Icons.star,
                      size: 8,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    printer.name,
                    style: TextStyle(
                      fontWeight: isConnected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                if (printer.rssi != null && printer.rssi! != 0)
                  _buildSignalStrength(printer.rssi!),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  printer.address,
                  style: const TextStyle(fontSize: AppFontSize.xs),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (printer.isBonded)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Paired',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    if (isDefault) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Default',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            trailing: _buildPrinterActions(printer, isConnected, bluetoothProvider),
            onTap: () => _showPrinterOptions(printer, bluetoothProvider),
          ),
        );
      },
    );
  }

  Widget _buildSignalStrength(int rssi) {
    // Convert RSSI to signal bars (typically -100 to 0 dBm)
    int bars = 0;
    if (rssi >= -50) bars = 4;
    else if (rssi >= -60) bars = 3;
    else if (rssi >= -70) bars = 2;
    else if (rssi >= -80) bars = 1;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
        return Icon(
          Icons.signal_cellular_4_bar,
          size: 12,
          color: index < bars ? AppColors.success : Colors.grey.shade300,
        );
      }),
    );
  }

  Widget _buildPrinterActions(
    PrinterDevice printer,
    bool isConnected,
    BluetoothProvider bluetoothProvider,
  ) {
    // Check if this specific device is connecting
    final isConnecting = bluetoothProvider.isConnectingToDevice(printer.id);
    
    if (isConnecting) {
      return const SizedBox(
        width: 80,
        height: 32,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    
    if (isConnected) {
      return const Icon(
        Icons.check_circle,
        color: AppColors.success,
      );
    }

    return ElevatedButton(
      onPressed: () => _connectToPrinter(printer),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: const Size(0, 0),
      ),
      child: const Text('Connect', style: TextStyle(fontSize: 12)),
    );
  }

  Future<void> _connectToPrinter(PrinterDevice printer) async {
    final bluetoothProvider = context.read<BluetoothProvider>();
    final success = await bluetoothProvider.connectToPrinter(printer);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connected to ${printer.name}'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _showPrinterOptions(PrinterDevice printer, BluetoothProvider bluetoothProvider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.print,
                  size: 32,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        printer.name,
                        style: const TextStyle(
                          fontSize: AppFontSize.lg,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        printer.address,
                        style: const TextStyle(
                          fontSize: AppFontSize.sm,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            if (!printer.isDefault)
              ListTile(
                leading: const Icon(Icons.star_outline),
                title: const Text('Set as Default Printer'),
                onTap: () async {
                  await bluetoothProvider.setDefaultPrinter(printer);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${printer.name} set as default'),
                      ),
                    );
                  }
                },
              ),
            if (printer.isDefault)
              ListTile(
                leading: const Icon(Icons.star_border),
                title: const Text('Remove as Default'),
                onTap: () async {
                  await bluetoothProvider.setDefaultPrinter(null);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Default printer removed'),
                      ),
                    );
                  }
                },
              ),
            if (!printer.isBonded)
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('Pair Device'),
                onTap: () async {
                  Navigator.pop(context);
                  final success = await bluetoothProvider.pairDevice(printer);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success 
                              ? 'Paired with ${printer.name}'
                              : 'Failed to pair with ${printer.name}'
                        ),
                        backgroundColor: success ? AppColors.success : AppColors.error,
                      ),
                    );
                  }
                },
              ),
            if (printer.isBonded)
              ListTile(
                leading: const Icon(Icons.link_off),
                title: const Text('Unpair Device'),
                onTap: () async {
                  Navigator.pop(context);
                  final success = await bluetoothProvider.unpairDevice(printer);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success 
                              ? 'Unpaired ${printer.name}'
                              : 'Failed to unpair ${printer.name}'
                        ),
                      ),
                    );
                  }
                },
              ),
            if (bluetoothProvider.connectedPrinter?.id != printer.id && printer.isBonded)
              ListTile(
                leading: const Icon(Icons.bluetooth_connected),
                title: const Text('Connect'),
                onTap: () async {
                  Navigator.pop(context);
                  await _connectToPrinter(printer);
                },
              ),
            if (bluetoothProvider.connectedPrinter?.id == printer.id)
              ListTile(
                leading: const Icon(Icons.bluetooth_disabled),
                title: const Text('Disconnect'),
                onTap: () async {
                  Navigator.pop(context);
                  await bluetoothProvider.disconnectPrinter();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Disconnected'),
                      ),
                    );
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}