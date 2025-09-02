import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/printer_device.dart';
import '../models/vehicle.dart';
import '../models/business_settings.dart';
import '../utils/esc_pos_commands.dart';
import '../utils/storage_helper.dart';

class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();

  // Connection management
  BluetoothConnection? _currentConnection;
  StreamSubscription<Uint8List>? _dataSubscription;
  StreamSubscription<BluetoothDiscoveryResult>? _discoverySubscription;
  StreamSubscription<BluetoothState>? _stateSubscription;
  
  // State management
  bool _isConnected = false;
  bool _isDiscovering = false;
  bool _isInitialized = false;
  String? _defaultPrinterId;
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  
  // Error tracking
  String? _lastError;
  int _connectionAttempts = 0;
  static const int maxConnectionAttempts = 3;
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration discoveryTimeout = Duration(seconds: 20);
  static const Duration printTimeout = Duration(seconds: 10);

  // Getters
  bool get isConnected => _isConnected && _currentConnection != null;
  bool get isDiscovering => _isDiscovering;
  bool get isInitialized => _isInitialized;
  BluetoothConnection? get currentConnection => _currentConnection;
  String? get defaultPrinterId => _defaultPrinterId;
  String? get lastError => _lastError;
  BluetoothState get bluetoothState => _bluetoothState;

  /// Initialize the service and load settings
  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      // Load default printer
      _defaultPrinterId = await StorageHelper.getDefaultPrinterId();
      
      // Start monitoring Bluetooth state
      _startBluetoothStateMonitoring();
      
      // Check initial Bluetooth state
      await _checkBluetoothState();
      
      _isInitialized = true;
      debugPrint('BluetoothService initialized successfully');
    } catch (e) {
      _lastError = 'Failed to initialize Bluetooth service: $e';
      debugPrint(_lastError);
    }
  }

  /// Start monitoring Bluetooth state changes
  void _startBluetoothStateMonitoring() {
    _stateSubscription?.cancel();
    _stateSubscription = FlutterBluetoothSerial.instance.onStateChanged().listen(
      (BluetoothState state) {
        _bluetoothState = state;
        debugPrint('Bluetooth state changed: $state');
        
        // Handle state changes
        if (state == BluetoothState.STATE_OFF) {
          // Bluetooth turned off, disconnect if connected
          if (_isConnected) {
            disconnectPrinter();
          }
        } else if (state == BluetoothState.STATE_ON) {
          // Bluetooth turned on, can attempt to reconnect to default printer
          if (_defaultPrinterId != null && !_isConnected) {
            // Note: Don't auto-connect here to avoid unexpected connections
            debugPrint('Bluetooth enabled, default printer available: $_defaultPrinterId');
          }
        }
      },
      onError: (error) {
        debugPrint('Bluetooth state monitoring error: $error');
      },
    );
  }

  /// Check current Bluetooth state
  Future<void> _checkBluetoothState() async {
    try {
      _bluetoothState = await FlutterBluetoothSerial.instance.state;
      debugPrint('Current Bluetooth state: $_bluetoothState');
    } catch (e) {
      _bluetoothState = BluetoothState.UNKNOWN;
      debugPrint('Failed to get Bluetooth state: $e');
    }
  }

  /// Request all necessary permissions based on Android version
  Future<bool> requestBluetoothPermissions() async {
    try {
      // Check if we're on Android
      if (!Platform.isAndroid) {
        _lastError = 'Bluetooth printing is only supported on Android';
        return false;
      }

      // Get Android version
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      
      debugPrint('Android SDK version: $sdkInt');

      // Android 12+ (API 31+)
      if (sdkInt >= 31) {
        // Check if permissions are already granted
        final btScan = await Permission.bluetoothScan.status;
        final btConnect = await Permission.bluetoothConnect.status;
        
        if (btScan.isGranted && btConnect.isGranted) {
          return true;
        }
        
        // Request new Bluetooth permissions
        Map<Permission, PermissionStatus> statuses = await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.bluetoothAdvertise,
        ].request();
        
        // Check if any permission is permanently denied
        if (statuses.values.any((status) => status.isPermanentlyDenied)) {
          _lastError = 'Bluetooth permissions permanently denied. Please enable in app settings.';
          // Open app settings for user to manually grant permissions
          await openAppSettings();
          return false;
        }
        
        return statuses[Permission.bluetoothScan]!.isGranted &&
               statuses[Permission.bluetoothConnect]!.isGranted;
      }
      // Android 10-11 (API 29-30)
      else if (sdkInt >= 29) {
        // Need location permission for Bluetooth scanning
        Map<Permission, PermissionStatus> statuses = await [
          Permission.bluetooth,
          Permission.location,
          Permission.locationWhenInUse,
        ].request();
        
        if (statuses.values.any((status) => status.isPermanentlyDenied)) {
          _lastError = 'Required permissions permanently denied. Please enable in app settings.';
          await openAppSettings();
          return false;
        }
        
        return statuses.values.every((status) => status.isGranted);
      }
      // Android 6-9 (API 23-28)
      else {
        // Need location permission for Bluetooth scanning
        final locationStatus = await Permission.location.request();
        
        if (locationStatus.isPermanentlyDenied) {
          _lastError = 'Location permission required for Bluetooth. Please enable in app settings.';
          await openAppSettings();
          return false;
        }
        
        return locationStatus.isGranted;
      }
    } catch (e) {
      _lastError = 'Permission request failed: $e';
      debugPrint(_lastError);
      return false;
    }
  }

  /// Check if Bluetooth hardware is available
  Future<bool> checkBluetoothAvailability() async {
    try {
      final isAvailable = await FlutterBluetoothSerial.instance.isAvailable ?? false;
      if (!isAvailable) {
        _lastError = 'Bluetooth is not available on this device';
        return false;
      }
      return true;
    } catch (e) {
      _lastError = 'Failed to check Bluetooth availability: $e';
      debugPrint(_lastError);
      return false;
    }
  }

  /// Enable Bluetooth with proper error handling
  Future<bool> enableBluetooth() async {
    try {
      // First check if Bluetooth is available
      final isAvailable = await checkBluetoothAvailability();
      if (!isAvailable) return false;

      // Check current state
      BluetoothState state = await FlutterBluetoothSerial.instance.state;
      if (state == BluetoothState.STATE_ON) {
        return true;
      }
      
      // Request to enable Bluetooth
      debugPrint('Requesting to enable Bluetooth...');
      final result = await FlutterBluetoothSerial.instance.requestEnable();
      
      if (result == true) {
        // Wait for Bluetooth to fully enable (with timeout)
        int attempts = 0;
        while (attempts < 10) {
          await Future.delayed(const Duration(milliseconds: 500));
          state = await FlutterBluetoothSerial.instance.state;
          if (state == BluetoothState.STATE_ON) {
            debugPrint('Bluetooth enabled successfully');
            return true;
          }
          attempts++;
        }
        _lastError = 'Bluetooth enabling timeout';
        return false;
      } else {
        _lastError = 'User denied Bluetooth enable request';
        return false;
      }
    } catch (e) {
      _lastError = 'Failed to enable Bluetooth: $e';
      debugPrint(_lastError);
      return false;
    }
  }

  /// Scan for printers with comprehensive error handling
  Future<List<PrinterDevice>> scanForPrinters({
    bool includeAllDevices = false,
    Duration? timeout,
  }) async {
    final devices = <String, PrinterDevice>{};
    _lastError = null;
    
    // Prevent concurrent scanning
    if (_isDiscovering) {
      debugPrint('Already discovering devices');
      return devices.values.toList();
    }
    
    try {
      // 1. Check and request permissions
      final hasPermission = await requestBluetoothPermissions();
      if (!hasPermission) {
        throw Exception(_lastError ?? 'Bluetooth permissions not granted');
      }

      // 2. Check if Bluetooth is available
      final isAvailable = await checkBluetoothAvailability();
      if (!isAvailable) {
        throw Exception(_lastError ?? 'Bluetooth not available');
      }

      // 3. Enable Bluetooth if needed
      final isEnabled = await enableBluetooth();
      if (!isEnabled) {
        throw Exception(_lastError ?? 'Bluetooth not enabled');
      }

      // 4. Get already bonded/paired devices first
      debugPrint('Fetching bonded devices...');
      try {
        List<BluetoothDevice> bondedDevices = 
            await FlutterBluetoothSerial.instance.getBondedDevices();
        
        debugPrint('Found ${bondedDevices.length} bonded devices');
        
        for (BluetoothDevice device in bondedDevices) {
          if (device.address != null && device.address!.isNotEmpty) {
            final name = device.name ?? 'Unknown Device';
            final nameLower = name.toLowerCase();
            
            // Check if it might be a printer based on name
            final isPrinter = nameLower.contains('printer') || 
                             nameLower.contains('thermal') ||
                             nameLower.contains('pos') ||
                             nameLower.contains('bluetooth') ||
                             nameLower.contains('bt') ||
                             nameLower.contains('print') ||
                             nameLower.contains('tsc') ||
                             nameLower.contains('zebra') ||
                             nameLower.contains('epson') ||
                             nameLower.contains('star');
            
            if (isPrinter || includeAllDevices) {
              devices[device.address!] = PrinterDevice(
                id: device.address!,
                name: name,
                address: device.address!,
                isConnected: device.isConnected,
                isBonded: true, // These are bonded devices
                isDefault: device.address == _defaultPrinterId,
                rssi: 0,
              );
              debugPrint('Added bonded device: $name (${device.address})');
            }
          }
        }
      } catch (e) {
        debugPrint('Error getting bonded devices: $e');
        // Continue with discovery even if bonded devices fail
      }

      // 5. Start discovering new devices
      debugPrint('Starting device discovery...');
      _isDiscovering = true;
      
      // Cancel any existing discovery
      await cancelDiscovery();
      
      // Use provided timeout or default
      final scanTimeout = timeout ?? discoveryTimeout;
      final completer = Completer<void>();
      Timer? timeoutTimer;
      
      // Set up timeout
      timeoutTimer = Timer(scanTimeout, () {
        if (!completer.isCompleted) {
          debugPrint('Discovery timeout reached');
          completer.complete();
        }
      });
      
      try {
        _discoverySubscription = FlutterBluetoothSerial.instance.startDiscovery().listen(
          (BluetoothDiscoveryResult result) {
            if (result.device.address != null && result.device.address!.isNotEmpty) {
              final name = result.device.name ?? 'Unknown Device';
              final nameLower = name.toLowerCase();
              
              // More comprehensive printer detection
              final isPrinter = nameLower.contains('printer') || 
                               nameLower.contains('thermal') ||
                               nameLower.contains('pos') ||
                               nameLower.contains('bluetooth') ||
                               nameLower.contains('bt') ||
                               nameLower.contains('print') ||
                               nameLower.contains('tsc') ||
                               nameLower.contains('zebra') ||
                               nameLower.contains('epson') ||
                               nameLower.contains('star') ||
                               nameLower.contains('bixolon');
              
              if (isPrinter || includeAllDevices) {
                // Update or add device
                devices[result.device.address!] = PrinterDevice(
                  id: result.device.address!,
                  name: name,
                  address: result.device.address!,
                  isConnected: false,
                  isBonded: result.device.isBonded,
                  isDefault: result.device.address == _defaultPrinterId,
                  rssi: result.rssi ?? -100,
                );
                debugPrint('Discovered: $name (${result.device.address}) RSSI: ${result.rssi}');
              }
            }
          },
          onDone: () {
            debugPrint('Discovery stream completed');
            _isDiscovering = false;
            if (!completer.isCompleted) {
              completer.complete();
            }
          },
          onError: (error) {
            debugPrint('Discovery stream error: $error');
            _lastError = 'Discovery error: $error';
            _isDiscovering = false;
            if (!completer.isCompleted) {
              completer.completeError(error);
            }
          },
          cancelOnError: true,
        );

        // Wait for discovery to complete or timeout
        await completer.future;
      } finally {
        timeoutTimer?.cancel();
        await cancelDiscovery();
      }

    } catch (e) {
      _lastError = 'Scan failed: $e';
      debugPrint(_lastError);
    } finally {
      _isDiscovering = false;
    }
    
    // Sort devices by signal strength and bonded status
    final deviceList = devices.values.toList();
    deviceList.sort((a, b) {
      // Prioritize bonded devices
      if (a.isBonded && !b.isBonded) return -1;
      if (!a.isBonded && b.isBonded) return 1;
      // Then sort by signal strength (higher RSSI is better)
      return (b.rssi ?? -100).compareTo(a.rssi ?? -100);
    });
    
    debugPrint('Scan complete. Found ${deviceList.length} devices');
    return deviceList;
  }

  /// Cancel ongoing discovery
  Future<void> cancelDiscovery() async {
    try {
      if (_discoverySubscription != null) {
        await _discoverySubscription!.cancel();
        _discoverySubscription = null;
      }
      
      // Try to cancel Flutter Bluetooth Serial discovery
      try {
        await FlutterBluetoothSerial.instance.cancelDiscovery();
      } catch (e) {
        // Ignore errors here as discovery might not be active
        debugPrint('Cancel discovery note: $e');
      }
      
      _isDiscovering = false;
    } catch (e) {
      debugPrint('Error canceling discovery: $e');
    }
  }

  /// Pair with a device
  Future<bool> pairDevice(String address) async {
    try {
      _lastError = null;
      debugPrint('Attempting to pair with device: $address');
      
      // Check if already bonded
      final bondedDevices = await FlutterBluetoothSerial.instance.getBondedDevices();
      final isAlreadyBonded = bondedDevices.any((d) => d.address == address);
      
      if (isAlreadyBonded) {
        debugPrint('Device already paired');
        return true;
      }
      
      // Attempt to bond
      final bonded = await FlutterBluetoothSerial.instance.bondDeviceAtAddress(address);
      
      if (bonded == true) {
        debugPrint('Successfully paired with device');
        return true;
      } else {
        _lastError = 'Pairing failed or was cancelled';
        return false;
      }
    } catch (e) {
      _lastError = 'Pairing error: $e';
      debugPrint(_lastError);
      return false;
    }
  }

  /// Unpair a device
  Future<bool> unpairDevice(String address) async {
    try {
      _lastError = null;
      
      // Disconnect if this is the connected device
      if (_currentConnection != null && _connectedPrinter?.address == address) {
        await disconnectPrinter();
      }
      
      final removed = await FlutterBluetoothSerial.instance.removeDeviceBondWithAddress(address);
      return removed ?? false;
    } catch (e) {
      _lastError = 'Unpair error: $e';
      debugPrint(_lastError);
      return false;
    }
  }

  // Track connected printer info
  PrinterDevice? _connectedPrinter;
  PrinterDevice? get connectedPrinter => _connectedPrinter;

  /// Connect to a printer with retry mechanism and timeout
  Future<bool> connectToPrinter(String address, {String? name}) async {
    try {
      _lastError = null;
      _connectionAttempts = 0;
      
      // Disconnect any existing connection
      await disconnectPrinter();
      
      debugPrint('Connecting to printer at $address...');
      
      // Check Bluetooth state first
      if (_bluetoothState != BluetoothState.STATE_ON) {
        _lastError = 'Bluetooth is not enabled';
        return false;
      }
      
      // Try to connect with retry mechanism
      while (_connectionAttempts < maxConnectionAttempts) {
        _connectionAttempts++;
        debugPrint('Connection attempt $_connectionAttempts of $maxConnectionAttempts');
        
        try {
          // Attempt connection with timeout
          _currentConnection = await BluetoothConnection.toAddress(address)
              .timeout(connectionTimeout);
          
          _isConnected = true;
          
          // Store connected printer info
          _connectedPrinter = PrinterDevice(
            id: address,
            name: name ?? 'Printer',
            address: address,
            isConnected: true,
            isBonded: true,
            isDefault: address == _defaultPrinterId,
          );
          
          // Set up data listener
          _dataSubscription = _currentConnection!.input?.listen(
            (Uint8List data) {
              // Handle incoming data from printer
              debugPrint('Data from printer: ${utf8.decode(data, allowMalformed: true)}');
            },
            onDone: () {
              debugPrint('Printer disconnected by remote');
              _handleDisconnection();
            },
            onError: (error) {
              debugPrint('Connection stream error: $error');
              _handleDisconnection();
            },
            cancelOnError: false,
          );
          
          debugPrint('Successfully connected to printer');
          return true;
          
        } on TimeoutException {
          _lastError = 'Connection timeout (attempt $_connectionAttempts)';
          debugPrint(_lastError);
          
          if (_connectionAttempts < maxConnectionAttempts) {
            await Future.delayed(const Duration(seconds: 1));
          }
        } catch (e) {
          _lastError = 'Connection failed (attempt $_connectionAttempts): $e';
          debugPrint(_lastError);
          
          if (_connectionAttempts < maxConnectionAttempts) {
            await Future.delayed(const Duration(seconds: 1));
          }
        }
      }
      
      // All attempts failed
      _lastError = 'Failed to connect after $maxConnectionAttempts attempts';
      return false;
      
    } catch (e) {
      _lastError = 'Connection error: $e';
      debugPrint(_lastError);
      return false;
    } finally {
      _connectionAttempts = 0;
    }
  }

  /// Handle disconnection events
  void _handleDisconnection() {
    _isConnected = false;
    _currentConnection = null;
    _connectedPrinter = null;
    _dataSubscription?.cancel();
    _dataSubscription = null;
  }

  /// Disconnect from printer
  Future<void> disconnectPrinter() async {
    try {
      await _dataSubscription?.cancel();
      _dataSubscription = null;
      
      if (_currentConnection != null) {
        await _currentConnection!.close();
        _currentConnection = null;
      }
      
      _isConnected = false;
      _connectedPrinter = null;
      debugPrint('Printer disconnected');
    } catch (e) {
      debugPrint('Disconnect error: $e');
    }
  }

  /// Set default printer
  Future<bool> setDefaultPrinter(String? printerId) async {
    try {
      _defaultPrinterId = printerId;
      await StorageHelper.setDefaultPrinterId(printerId);
      return true;
    } catch (e) {
      _lastError = 'Failed to set default printer: $e';
      debugPrint(_lastError);
      return false;
    }
  }

  /// Print raw data with timeout
  Future<bool> printRawData(Uint8List data) async {
    if (!_isConnected || _currentConnection == null) {
      _lastError = 'No printer connected';
      return false;
    }
    
    try {
      _currentConnection!.output.add(data);
      await _currentConnection!.output.allSent.timeout(
        printTimeout,
        onTimeout: () {
          throw TimeoutException('Print timeout');
        },
      );
      debugPrint('Data sent to printer successfully');
      return true;
    } on TimeoutException {
      _lastError = 'Print timeout - printer may be offline or busy';
      debugPrint(_lastError);
      return false;
    } catch (e) {
      _lastError = 'Print error: $e';
      debugPrint(_lastError);
      
      // Check if connection is still valid
      if (!_currentConnection!.isConnected) {
        _handleDisconnection();
      }
      
      return false;
    }
  }

  /// Print text data
  Future<bool> printData(String data) async {
    try {
      Uint8List bytes = Uint8List.fromList(data.codeUnits);
      return await printRawData(bytes);
    } catch (e) {
      _lastError = 'Print data error: $e';
      debugPrint(_lastError);
      return false;
    }
  }

  /// Print receipt with error recovery
  Future<bool> printReceipt(Vehicle vehicle, BusinessSettings settings) async {
    try {
      if (!_isConnected) {
        _lastError = 'No printer connected';
        return false;
      }
      
      final receiptData = ESCPOSCommands.formatReceipt(vehicle, settings);
      final success = await printData(receiptData);
      
      if (!success && _lastError?.contains('timeout') == true) {
        // Try once more on timeout
        debugPrint('Retrying print after timeout...');
        await Future.delayed(const Duration(seconds: 2));
        return await printData(receiptData);
      }
      
      return success;
    } catch (e) {
      _lastError = 'Print receipt error: $e';
      debugPrint(_lastError);
      return false;
    }
  }

  /// Print test receipt
  Future<bool> printTestReceipt(BusinessSettings settings) async {
    try {
      if (!_isConnected) {
        _lastError = 'No printer connected';
        return false;
      }
      
      final testData = ESCPOSCommands.formatTestReceipt(settings);
      return await printData(testData);
    } catch (e) {
      _lastError = 'Test print error: $e';
      debugPrint(_lastError);
      return false;
    }
  }

  /// Get Bluetooth state stream
  Stream<BluetoothState> get bluetoothStateStream {
    return FlutterBluetoothSerial.instance.onStateChanged().handleError((error) {
      debugPrint('Bluetooth state stream error: $error');
    });
  }

  /// Get current Bluetooth state async
  Future<BluetoothState> get bluetoothStateAsync async {
    try {
      return await FlutterBluetoothSerial.instance.state;
    } catch (e) {
      debugPrint('Get bluetooth state error: $e');
      return BluetoothState.UNKNOWN;
    }
  }

  /// Check if device supports Bluetooth
  Future<bool> get isBluetoothSupported async {
    try {
      return await FlutterBluetoothSerial.instance.isAvailable ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Cleanup and dispose resources
  void dispose() {
    cancelDiscovery();
    disconnectPrinter();
    _stateSubscription?.cancel();
    _stateSubscription = null;
    _isInitialized = false;
  }
}