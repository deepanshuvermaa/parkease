import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/business_settings.dart';
import '../models/enhanced_business_settings.dart';

class SettingsProvider extends ChangeNotifier {
  BusinessSettings _settings = EnhancedBusinessSettings.defaultSettings();
  bool _isLoading = true;

  BusinessSettings get settings => _settings;
  bool get isLoading => _isLoading;

  SettingsProvider() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('business_settings');
      
      if (settingsJson != null) {
        final Map<String, dynamic> decoded = json.decode(settingsJson);
        // Try to load as enhanced settings first, fallback to basic if needed
        try {
          _settings = EnhancedBusinessSettings.fromJson(decoded);
        } catch (e) {
          _settings = BusinessSettings.fromJson(decoded);
        }
      } else {
        _settings = EnhancedBusinessSettings.defaultSettings();
        await saveSettings();
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
      _settings = EnhancedBusinessSettings.defaultSettings();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateSettings(BusinessSettings newSettings) {
    _settings = newSettings;
    notifyListeners();
  }

  Future<void> saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = json.encode(_settings.toJson());
      await prefs.setString('business_settings', settingsJson);
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  Future<void> updateBusinessSettings(BusinessSettings newSettings) async {
    _settings = newSettings;
    await saveSettings();
    notifyListeners();
  }

  Future<void> updateBusinessName(String name) async {
    _settings = _settings.copyWith(businessName: name);
    await saveSettings();
    notifyListeners();
  }

  Future<void> updateAddress(String address) async {
    _settings = _settings.copyWith(address: address);
    await saveSettings();
    notifyListeners();
  }

  Future<void> updateCity(String city) async {
    _settings = _settings.copyWith(city: city);
    await saveSettings();
    notifyListeners();
  }

  Future<void> updateContactNumber(String number) async {
    _settings = _settings.copyWith(contactNumber: number);
    await saveSettings();
    notifyListeners();
  }

  Future<void> toggleContactOnReceipt() async {
    _settings = _settings.copyWith(
      showContactOnReceipt: !_settings.showContactOnReceipt,
    );
    await saveSettings();
    notifyListeners();
  }

  Future<void> updatePaperSize(PaperSize size) async {
    _settings = _settings.copyWith(paperSize: size);
    await saveSettings();
    notifyListeners();
  }

  Future<void> toggleAutoPrint() async {
    _settings = _settings.copyWith(autoPrint: !_settings.autoPrint);
    await saveSettings();
    notifyListeners();
  }

  Future<void> setPrimaryPrinter(String? printerId) async {
    _settings = _settings.copyWith(primaryPrinterId: printerId);
    await saveSettings();
    notifyListeners();
  }

  Future<void> resetToDefaults() async {
    _settings = BusinessSettings.defaultSettings();
    await saveSettings();
    notifyListeners();
  }

  Map<String, dynamic> exportSettings() {
    return _settings.toJson();
  }

  Future<void> importSettings(Map<String, dynamic> settingsData) async {
    try {
      _settings = BusinessSettings.fromJson(settingsData);
      await saveSettings();
      notifyListeners();
    } catch (e) {
      debugPrint('Error importing settings: $e');
      throw Exception('Invalid settings format');
    }
  }
}