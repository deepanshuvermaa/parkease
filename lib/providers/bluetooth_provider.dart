import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../models/printer_device.dart';
import '../models/vehicle.dart';
import '../models/business_settings.dart';
import '../services/bluetooth_service.dart';
import '../utils/storage_helper.dart';

class BluetoothProvider extends ChangeNotifier {
  final BluetoothService _bluetoothService = BluetoothService();
  
  // State management
  List<PrinterDevice> _availablePrinters = [];
  PrinterDevice? _connectedPrinter;
  bool _isScanning = false;
  String? _connectingDeviceId; // Track which device is being connected
  String? _lastError;
  bool _includeAllDevices = false;
  String? _defaultPrinterId;
  bool _isInitialized = false;
  bool _hasScannedOnce = false;
  
  // Connection retry management
  Timer? _reconnectionTimer;
  int _reconnectionAttempts = 0;
  static const int maxReconnectionAttempts = 3;
  
  // Getters
  List<PrinterDevice> get availablePrinters => _availablePrinters;
  PrinterDevice? get connectedPrinter => _connectedPrinter;
  bool get isScanning => _isScanning;
  bool isConnectingToDevice(String deviceId) => _connectingDeviceId == deviceId;
  String? get lastError => _lastError;
  bool get isConnected => _bluetoothService.isConnected;
  bool get includeAllDevices => _includeAllDevices;
  String? get defaultPrinterId => _defaultPrinterId;
  bool get isInitialized => _isInitialized;
  bool get hasScannedOnce => _hasScannedOnce;
  BluetoothState get bluetoothState => _bluetoothService.bluetoothState;

  BluetoothProvider() {
    _init();
  }

  /// Initialize the provider and service
  Future<void> _init() async {
    if (_isInitialized) return;
    
    try {
      await _bluetoothService.init();
      _defaultPrinterId = _bluetoothService.defaultPrinterId;
      _isInitialized = true;
      
      // Start monitoring Bluetooth state
      _startBluetoothStateMonitoring();
      
      // Load bonded devices immediately on init
      await _loadBondedDevices();
      
      notifyListeners();
    } catch (e) {
      debugPrint('BluetoothProvider initialization error: $e');
      _lastError = 'Failed to initialize Bluetooth: $e';
      notifyListeners();
    }
  }

  /// Load bonded devices immediately without full scan
  Future<void> _loadBondedDevices() async {
    try {
      // Check permissions first
      final hasPermission = await _bluetoothService.requestBluetoothPermissions();
      if (!hasPermission) {
        debugPrint('No Bluetooth permissions for loading bonded devices');
        return;
      }

      // Check if Bluetooth is on
      if (_bluetoothService.bluetoothState != BluetoothState.STATE_ON) {
        debugPrint('Bluetooth is off, cannot load bonded devices');
        return;
      }

      // Get bonded devices
      final bondedDevices = await FlutterBluetoothSerial.instance.getBondedDevices();
      
      _availablePrinters.clear();
      for (var device in bondedDevices) {
        if (device.address != null && device.address!.isNotEmpty) {
          final name = device.name ?? 'Unknown Device';
          final nameLower = name.toLowerCase();
          
          // Check if it might be a printer
          final isPrinter = nameLower.contains('printer') || 
                           nameLower.contains('thermal') ||
                           nameLower.contains('pos') ||
                           nameLower.contains('bluetooth') ||
                           nameLower.contains('bt') ||
                           nameLower.contains('print') ||
                           nameLower.contains('bp') ||
                           includeAllDevices;
          
          if (isPrinter) {
            _availablePrinters.add(PrinterDevice(
              id: device.address!,
              name: name,
              address: device.address!,
              isConnected: false,
              isBonded: true,
              isDefault: device.address == _defaultPrinterId,
              rssi: 0,
            ));
          }
        }
      }
      
      // Update connection status for connected device
      if (_connectedPrinter != null) {
        final index = _availablePrinters.indexWhere((p) => p.id == _connectedPrinter!.id);
        if (index != -1) {
          _availablePrinters[index] = _availablePrinters[index].copyWith(isConnected: true);
        }
      }
      
      debugPrint('Loaded ${_availablePrinters.length} bonded devices');
      notifyListeners();
      
    } catch (e) {
      debugPrint('Error loading bonded devices: $e');
    }
  }

  /// Monitor Bluetooth state changes
  void _startBluetoothStateMonitoring() {
    _bluetoothService.bluetoothStateStream.listen(
      (BluetoothState state) {
        notifyListeners();
        
        if (state == BluetoothState.STATE_OFF && _connectedPrinter != null) {
          _handleDisconnection();
        } else if (state == BluetoothState.STATE_ON && !_hasScannedOnce) {
          // Load bonded devices when Bluetooth turns on
          _loadBondedDevices();
        }
      },
      onError: (error) {
        debugPrint('Bluetooth state monitoring error: $error');
      },
    );
  }

  /// Set whether to include all devices in scan
  void setIncludeAllDevices(bool value) {
    _includeAllDevices = value;
    if (!_isScanning) {
      _loadBondedDevices(); // Reload with new filter
    }
    notifyListeners();
  }

  /// Scan for printers with improved performance
  Future<void> scanForPrinters({
    bool includeAll = false,
    Duration? timeout,
  }) async {
    if (_isScanning) {
      debugPrint('Already scanning for devices');
      return;
    }
    
    _isScanning = true;
    _lastError = null;
    _hasScannedOnce = true;
    
    // Don't clear devices, keep bonded ones visible
    notifyListeners();
    
    try {
      // Perform full scan for new devices
      final scannedDevices = await _bluetoothService.scanForPrinters(
        includeAllDevices: includeAll || _includeAllDevices,
        timeout: timeout ?? const Duration(seconds: 10), // Reduced timeout
      );
      
      // Merge scanned devices with existing ones
      final deviceMap = <String, PrinterDevice>{};
      
      // Add existing devices first
      for (var device in _availablePrinters) {
        deviceMap[device.id] = device;
      }
      
      // Update or add scanned devices
      for (var device in scannedDevices) {
        deviceMap[device.id] = device.copyWith(
          isDefault: device.id == _defaultPrinterId,
          isConnected: _connectedPrinter?.id == device.id,
        );
      }
      
      _availablePrinters = deviceMap.values.toList();
      
      // Sort by bonded status and signal strength
      _availablePrinters.sort((a, b) {
        if (a.isBonded && !b.isBonded) return -1;
        if (!a.isBonded && b.isBonded) return 1;
        return (b.rssi ?? -100).compareTo(a.rssi ?? -100);
      });
      
      // Check for errors
      if (_bluetoothService.lastError != null) {
        _lastError = _bluetoothService.lastError;
      } else if (_availablePrinters.isEmpty) {
        _lastError = 'No devices found. Make sure Bluetooth is enabled and devices are discoverable.';
      } else {
        debugPrint('Found ${_availablePrinters.length} total devices');
        
        // Auto-connect to default printer if found
        if (_defaultPrinterId != null && !isConnected) {
          final defaultPrinter = _availablePrinters.firstWhere(
            (p) => p.id == _defaultPrinterId,
            orElse: () => PrinterDevice(id: '', name: '', address: ''),
          );
          
          if (defaultPrinter.id.isNotEmpty) {
            connectToPrinter(defaultPrinter);
          }
        }
      }
    } catch (e) {
      _lastError = 'Scan failed: ${e.toString()}';
      debugPrint('Scan error: $e');
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  /// Stop ongoing scan
  Future<void> stopScanning() async {
    await _bluetoothService.cancelDiscovery();
    _isScanning = false;
    notifyListeners();
  }

  /// Pair with a device
  Future<bool> pairDevice(PrinterDevice printer) async {
    try {
      _lastError = null;
      notifyListeners();
      
      final success = await _bluetoothService.pairDevice(printer.address);
      
      if (success) {
        // Update device status in list
        final index = _availablePrinters.indexWhere((p) => p.id == printer.id);
        if (index != -1) {
          _availablePrinters[index] = printer.copyWith(isBonded: true);
          notifyListeners();
        }
        
        // Optionally connect after pairing
        if (!isConnected) {
          await connectToPrinter(printer);
        }
      } else {
        _lastError = _bluetoothService.lastError ?? 'Failed to pair with ${printer.name}';
      }
      
      notifyListeners();
      return success;
    } catch (e) {
      _lastError = 'Pairing error: ${e.toString()}';
      debugPrint('Pair error: $e');
      notifyListeners();
      return false;
    }
  }

  /// Unpair a device
  Future<bool> unpairDevice(PrinterDevice printer) async {
    try {
      // Disconnect if this is the connected printer
      if (_connectedPrinter?.id == printer.id) {
        await disconnectPrinter();
      }
      
      final success = await _bluetoothService.unpairDevice(printer.address);
      
      if (success) {
        // Remove device from list if unpairing successful
        _availablePrinters.removeWhere((p) => p.id == printer.id);
      } else {
        _lastError = _bluetoothService.lastError ?? 'Failed to unpair ${printer.name}';
      }
      
      notifyListeners();
      return success;
    } catch (e) {
      _lastError = 'Unpair error: ${e.toString()}';
      debugPrint('Unpair error: $e');
      notifyListeners();
      return false;
    }
  }

  /// Connect to a printer with proper state management
  Future<bool> connectToPrinter(PrinterDevice printer) async {
    if (_connectingDeviceId == printer.id) {
      debugPrint('Already connecting to this device');
      return false;
    }
    
    _connectingDeviceId = printer.id;
    _lastError = null;
    _reconnectionAttempts = 0;
    notifyListeners();
    
    try {
      // Cancel any reconnection timer
      _cancelReconnectionTimer();
      
      // Check Bluetooth state first
      if (_bluetoothService.bluetoothState != BluetoothState.STATE_ON) {
        _lastError = 'Please enable Bluetooth first';
        
        // Try to enable Bluetooth
        final enabled = await _bluetoothService.enableBluetooth();
        if (!enabled) {
          _lastError = _bluetoothService.lastError ?? 'Failed to enable Bluetooth';
          return false;
        }
      }
      
      // If not bonded, try to pair first
      if (!printer.isBonded) {
        debugPrint('Device not bonded, attempting to pair first...');
        final paired = await _bluetoothService.pairDevice(printer.address);
        if (!paired) {
          _lastError = _bluetoothService.lastError ?? 
                      'Failed to pair. Please pair manually in Bluetooth settings.';
          return false;
        }
        
        // Update printer bonded status
        printer = printer.copyWith(isBonded: true);
      }
      
      // Attempt connection
      final success = await _bluetoothService.connectToPrinter(
        printer.address,
        name: printer.name,
      );
      
      if (success) {
        _connectedPrinter = printer.copyWith(isConnected: true);
        _updatePrinterConnectionStatus();
        debugPrint('Successfully connected to ${printer.name}');
      } else {
        _lastError = _bluetoothService.lastError ?? 
                    'Failed to connect. Make sure printer is on and in range.';
        
        // Schedule reconnection attempt if this was the default printer
        if (printer.id == _defaultPrinterId) {
          _scheduleReconnection(printer);
        }
      }
      
      return success;
    } catch (e) {
      _lastError = 'Connection error: ${e.toString()}';
      debugPrint('Connect error: $e');
      return false;
    } finally {
      _connectingDeviceId = null;
      notifyListeners();
    }
  }

  /// Schedule automatic reconnection for default printer
  void _scheduleReconnection(PrinterDevice printer) {
    if (_reconnectionAttempts >= maxReconnectionAttempts) {
      debugPrint('Max reconnection attempts reached');
      return;
    }
    
    _cancelReconnectionTimer();
    
    final delay = Duration(seconds: 5 * (_reconnectionAttempts + 1));
    debugPrint('Scheduling reconnection attempt in ${delay.inSeconds} seconds...');
    
    _reconnectionTimer = Timer(delay, () async {
      _reconnectionAttempts++;
      debugPrint('Reconnection attempt $_reconnectionAttempts of $maxReconnectionAttempts');
      
      final success = await connectToPrinter(printer);
      if (!success && _reconnectionAttempts < maxReconnectionAttempts) {
        _scheduleReconnection(printer);
      }
    });
  }

  /// Cancel reconnection timer
  void _cancelReconnectionTimer() {
    _reconnectionTimer?.cancel();
    _reconnectionTimer = null;
    _reconnectionAttempts = 0;
  }

  /// Handle disconnection
  void _handleDisconnection() {
    _connectedPrinter = null;
    _connectingDeviceId = null;
    _updatePrinterConnectionStatus();
    notifyListeners();
  }

  /// Disconnect from printer
  Future<void> disconnectPrinter() async {
    _cancelReconnectionTimer();
    await _bluetoothService.disconnectPrinter();
    _handleDisconnection();
  }

  /// Set default printer
  Future<bool> setDefaultPrinter(PrinterDevice? printer) async {
    try {
      _defaultPrinterId = printer?.id;
      await _bluetoothService.setDefaultPrinter(printer?.id);
      
      // Update printer list to reflect new default
      for (int i = 0; i < _availablePrinters.length; i++) {
        _availablePrinters[i] = _availablePrinters[i].copyWith(
          isDefault: _availablePrinters[i].id == printer?.id,
        );
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = 'Failed to set default printer';
      debugPrint('Set default error: $e');
      notifyListeners();
      return false;
    }
  }

  /// Connect to default printer
  Future<bool> connectToDefaultPrinter() async {
    if (_defaultPrinterId == null) {
      _lastError = 'No default printer set';
      notifyListeners();
      return false;
    }
    
    // Check if printer is in current list
    var printer = _availablePrinters.firstWhere(
      (p) => p.id == _defaultPrinterId,
      orElse: () => PrinterDevice(id: '', name: '', address: ''),
    );
    
    // If not found, scan for it
    if (printer.id.isEmpty) {
      debugPrint('Default printer not in list, scanning...');
      await scanForPrinters();
      
      printer = _availablePrinters.firstWhere(
        (p) => p.id == _defaultPrinterId,
        orElse: () => PrinterDevice(id: '', name: '', address: ''),
      );
      
      if (printer.id.isEmpty) {
        _lastError = 'Default printer not found. Make sure it\'s turned on.';
        notifyListeners();
        return false;
      }
    }
    
    return await connectToPrinter(printer);
  }

  /// Print receipt with automatic connection to default printer
  Future<bool> printReceipt(Vehicle vehicle, BusinessSettings settings) async {
    try {
      // If not connected, try to connect to default printer
      if (!isConnected) {
        if (_defaultPrinterId != null) {
          debugPrint('Not connected, attempting to connect to default printer...');
          final connected = await connectToDefaultPrinter();
          
          if (!connected) {
            _lastError = 'Unable to connect to printer. Please check printer is on and in range.';
            notifyListeners();
            return false;
          }
          
          // Small delay after connection
          await Future.delayed(const Duration(milliseconds: 500));
        } else {
          _lastError = 'No printer connected. Please connect to a printer first.';
          notifyListeners();
          return false;
        }
      }
      
      // Attempt to print
      final success = await _bluetoothService.printReceipt(vehicle, settings);
      
      if (!success) {
        _lastError = _bluetoothService.lastError ?? 'Print failed. Check printer status.';
        
        // If print failed due to connection issue, try to reconnect once
        if (_lastError!.contains('No printer connected') && _defaultPrinterId != null) {
          debugPrint('Connection lost, attempting reconnection...');
          final reconnected = await connectToDefaultPrinter();
          
          if (reconnected) {
            // Retry print after reconnection
            await Future.delayed(const Duration(milliseconds: 500));
            final retrySuccess = await _bluetoothService.printReceipt(vehicle, settings);
            
            if (retrySuccess) {
              _lastError = null;
              notifyListeners();
              return true;
            }
          }
        }
      } else {
        _lastError = null;
      }
      
      notifyListeners();
      return success;
    } catch (e) {
      _lastError = 'Print error: ${e.toString()}';
      debugPrint('Print error: $e');
      notifyListeners();
      return false;
    }
  }

  /// Test print
  Future<bool> testPrint(BusinessSettings settings) async {
    if (!isConnected) {
      _lastError = 'No printer connected';
      notifyListeners();
      return false;
    }
    
    try {
      final success = await _bluetoothService.printTestReceipt(settings);
      
      if (!success) {
        _lastError = _bluetoothService.lastError ?? 'Test print failed';
      } else {
        _lastError = null;
      }
      
      notifyListeners();
      return success;
    } catch (e) {
      _lastError = 'Test print error: ${e.toString()}';
      debugPrint('Test print error: $e');
      notifyListeners();
      return false;
    }
  }

  /// Update printer connection status in list
  void _updatePrinterConnectionStatus() {
    for (int i = 0; i < _availablePrinters.length; i++) {
      _availablePrinters[i] = _availablePrinters[i].copyWith(
        isConnected: _connectedPrinter != null && 
                    _availablePrinters[i].id == _connectedPrinter!.id,
      );
    }
  }

  /// Clear error message
  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  /// Refresh Bluetooth state
  Future<void> refreshBluetoothState() async {
    try {
      // Check if Bluetooth is available
      final isSupported = await _bluetoothService.isBluetoothSupported;
      
      if (!isSupported) {
        _lastError = 'Bluetooth is not supported on this device';
        notifyListeners();
        return;
      }
      
      // Try to enable Bluetooth if it's off
      if (_bluetoothService.bluetoothState != BluetoothState.STATE_ON) {
        final enabled = await _bluetoothService.enableBluetooth();
        
        if (!enabled) {
          _lastError = _bluetoothService.lastError ?? 'Failed to enable Bluetooth';
        } else {
          _lastError = null;
          // Load bonded devices first
          await _loadBondedDevices();
          // Then scan for new devices
          await scanForPrinters();
        }
      } else {
        // Bluetooth is already on, reload devices
        await _loadBondedDevices();
        await scanForPrinters();
      }
      
      notifyListeners();
    } catch (e) {
      _lastError = 'Failed to refresh Bluetooth: $e';
      debugPrint('Refresh bluetooth error: $e');
      notifyListeners();
    }
  }

  /// Check if Bluetooth is available and enabled
  Future<bool> checkBluetoothReady() async {
    try {
      // Check if supported
      final isSupported = await _bluetoothService.isBluetoothSupported;
      if (!isSupported) {
        _lastError = 'Bluetooth is not supported on this device';
        return false;
      }
      
      // Check if enabled
      if (_bluetoothService.bluetoothState != BluetoothState.STATE_ON) {
        _lastError = 'Bluetooth is not enabled';
        return false;
      }
      
      return true;
    } catch (e) {
      _lastError = 'Bluetooth check failed: $e';
      return false;
    }
  }

  @override
  void dispose() {
    _cancelReconnectionTimer();
    _bluetoothService.dispose();
    super.dispose();
  }
}