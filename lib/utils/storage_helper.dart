import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vehicle.dart';
import '../models/business_settings.dart';

class StorageHelper {
  static const String _activeVehiclesKey = 'active_vehicles';
  static const String _completedVehiclesKey = 'completed_vehicles';
  static const String _businessSettingsKey = 'business_settings';
  static const String _printerSettingsKey = 'printer_settings';
  static const String _lastBackupKey = 'last_backup';
  static const String _defaultPrinterKey = 'default_printer_id';

  static Future<void> saveVehicles(List<Vehicle> vehicles, {bool isActive = true}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = isActive ? _activeVehiclesKey : _completedVehiclesKey;
      final jsonList = vehicles.map((v) => v.toJson()).toList();
      await prefs.setString(key, json.encode(jsonList));
    } catch (e) {
      debugPrint('Error saving vehicles: $e');
      throw Exception('Failed to save vehicles');
    }
  }

  static Future<List<Vehicle>> loadVehicles({bool isActive = true}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = isActive ? _activeVehiclesKey : _completedVehiclesKey;
      final jsonString = prefs.getString(key);
      
      if (jsonString == null) return [];
      
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => Vehicle.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading vehicles: $e');
      return [];
    }
  }

  static Future<void> saveSettings(BusinessSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_businessSettingsKey, json.encode(settings.toJson()));
    } catch (e) {
      debugPrint('Error saving settings: $e');
      throw Exception('Failed to save settings');
    }
  }

  static Future<BusinessSettings> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_businessSettingsKey);
      
      if (jsonString == null) {
        return BusinessSettings.defaultSettings();
      }
      
      return BusinessSettings.fromJson(json.decode(jsonString));
    } catch (e) {
      debugPrint('Error loading settings: $e');
      return BusinessSettings.defaultSettings();
    }
  }

  static Future<File> createBackup() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupFile = File('${directory.path}/parkease_backup_$timestamp.json');
      
      final activeVehicles = await loadVehicles(isActive: true);
      final completedVehicles = await loadVehicles(isActive: false);
      final settings = await loadSettings();
      
      final backupData = {
        'version': '1.0.0',
        'timestamp': DateTime.now().toIso8601String(),
        'activeVehicles': activeVehicles.map((v) => v.toJson()).toList(),
        'completedVehicles': completedVehicles.map((v) => v.toJson()).toList(),
        'businessSettings': settings.toJson(),
      };
      
      await backupFile.writeAsString(json.encode(backupData));
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastBackupKey, DateTime.now().toIso8601String());
      
      return backupFile;
    } catch (e) {
      debugPrint('Error creating backup: $e');
      throw Exception('Failed to create backup');
    }
  }

  static Future<void> restoreBackup(File backupFile) async {
    try {
      final jsonString = await backupFile.readAsString();
      final Map<String, dynamic> backupData = json.decode(jsonString);
      
      final List<dynamic> activeJson = backupData['activeVehicles'] ?? [];
      final List<dynamic> completedJson = backupData['completedVehicles'] ?? [];
      final Map<String, dynamic> settingsJson = backupData['businessSettings'] ?? {};
      
      final activeVehicles = activeJson.map((json) => Vehicle.fromJson(json)).toList();
      final completedVehicles = completedJson.map((json) => Vehicle.fromJson(json)).toList();
      final settings = BusinessSettings.fromJson(settingsJson);
      
      await saveVehicles(activeVehicles, isActive: true);
      await saveVehicles(completedVehicles, isActive: false);
      await saveSettings(settings);
    } catch (e) {
      debugPrint('Error restoring backup: $e');
      throw Exception('Failed to restore backup');
    }
  }

  static Future<List<File>> getBackupFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync()
          .whereType<File>()
          .where((file) => file.path.contains('parkease_backup'))
          .toList();
      
      files.sort((a, b) => b.path.compareTo(a.path));
      return files;
    } catch (e) {
      debugPrint('Error getting backup files: $e');
      return [];
    }
  }

  static Future<void> deleteBackup(File backupFile) async {
    try {
      if (await backupFile.exists()) {
        await backupFile.delete();
      }
    } catch (e) {
      debugPrint('Error deleting backup: $e');
      throw Exception('Failed to delete backup');
    }
  }

  static Future<void> autoBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastBackupString = prefs.getString(_lastBackupKey);
      
      DateTime? lastBackup;
      if (lastBackupString != null) {
        lastBackup = DateTime.parse(lastBackupString);
      }
      
      final now = DateTime.now();
      if (lastBackup == null || now.difference(lastBackup).inDays >= 1) {
        await createBackup();
        await cleanOldBackups();
      }
    } catch (e) {
      debugPrint('Error in auto backup: $e');
    }
  }

  static Future<void> cleanOldBackups() async {
    try {
      final backups = await getBackupFiles();
      if (backups.length > 7) {
        for (int i = 7; i < backups.length; i++) {
          await deleteBackup(backups[i]);
        }
      }
    } catch (e) {
      debugPrint('Error cleaning old backups: $e');
    }
  }

  static Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync()
          .whereType<File>()
          .where((file) => file.path.contains('parkease'));
      
      for (var file in files) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error clearing all data: $e');
      throw Exception('Failed to clear all data');
    }
  }

  static Future<Map<String, dynamic>> exportData() async {
    try {
      final activeVehicles = await loadVehicles(isActive: true);
      final completedVehicles = await loadVehicles(isActive: false);
      final settings = await loadSettings();
      
      return {
        'exportDate': DateTime.now().toIso8601String(),
        'activeVehicles': activeVehicles.map((v) => v.toJson()).toList(),
        'completedVehicles': completedVehicles.map((v) => v.toJson()).toList(),
        'businessSettings': settings.toJson(),
        'statistics': {
          'totalActive': activeVehicles.length,
          'totalCompleted': completedVehicles.length,
        },
      };
    } catch (e) {
      debugPrint('Error exporting data: $e');
      throw Exception('Failed to export data');
    }
  }

  static Future<void> setDefaultPrinterId(String? printerId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (printerId != null) {
        await prefs.setString(_defaultPrinterKey, printerId);
      } else {
        await prefs.remove(_defaultPrinterKey);
      }
    } catch (e) {
      debugPrint('Error saving default printer: $e');
    }
  }

  static Future<String?> getDefaultPrinterId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_defaultPrinterKey);
    } catch (e) {
      debugPrint('Error loading default printer: $e');
      return null;
    }
  }
}