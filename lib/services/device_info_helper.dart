import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceInfoHelper {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  
  static Future<String> getDeviceId() async {
    String deviceId = '';
    
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        // Use Android ID as unique identifier
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        // Use identifierForVendor for iOS
        deviceId = iosInfo.identifierForVendor ?? 'unknown_ios';
      } else if (Platform.isWindows) {
        final windowsInfo = await _deviceInfo.windowsInfo;
        // Use computer name and product ID for Windows
        deviceId = '${windowsInfo.computerName}_${windowsInfo.productId}';
      } else if (Platform.isMacOS) {
        final macInfo = await _deviceInfo.macOsInfo;
        // Use system GUID for macOS
        deviceId = macInfo.systemGUID ?? 'unknown_mac';
      } else if (Platform.isLinux) {
        final linuxInfo = await _deviceInfo.linuxInfo;
        // Use machine ID for Linux
        deviceId = linuxInfo.machineId ?? 'unknown_linux';
      } else {
        // Fallback for web or other platforms
        deviceId = 'web_${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (e) {
      // If we can't get device info, generate a pseudo-random ID
      deviceId = 'unknown_${DateTime.now().millisecondsSinceEpoch}';
    }
    
    return deviceId;
  }
  
  static Future<Map<String, String>> getDeviceDetails() async {
    Map<String, String> details = {};
    
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        details = {
          'platform': 'Android',
          'model': androidInfo.model,
          'brand': androidInfo.brand,
          'version': androidInfo.version.release,
          'sdk': androidInfo.version.sdkInt.toString(),
        };
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        details = {
          'platform': 'iOS',
          'model': iosInfo.model,
          'name': iosInfo.name,
          'version': iosInfo.systemVersion,
        };
      } else if (Platform.isWindows) {
        final windowsInfo = await _deviceInfo.windowsInfo;
        details = {
          'platform': 'Windows',
          'computerName': windowsInfo.computerName,
          'numberOfCores': windowsInfo.numberOfCores.toString(),
          'systemMemory': '${windowsInfo.systemMemoryInMegabytes} MB',
        };
      } else if (Platform.isMacOS) {
        final macInfo = await _deviceInfo.macOsInfo;
        details = {
          'platform': 'macOS',
          'model': macInfo.model,
          'arch': macInfo.arch,
          'kernelVersion': macInfo.kernelVersion,
        };
      } else if (Platform.isLinux) {
        final linuxInfo = await _deviceInfo.linuxInfo;
        details = {
          'platform': 'Linux',
          'name': linuxInfo.name,
          'version': linuxInfo.version ?? 'Unknown',
          'id': linuxInfo.id,
        };
      }
    } catch (e) {
      details = {'platform': 'Unknown', 'error': e.toString()};
    }
    
    return details;
  }
}