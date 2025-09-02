import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/vehicle.dart';
import '../models/vehicle_type.dart';

class VehicleProvider extends ChangeNotifier {
  List<Vehicle> _activeVehicles = [];
  List<Vehicle> _completedVehicles = [];
  double _todayCollection = 0.0;
  Map<VehicleType, int> _vehicleTypeCount = {
    VehicleType.cycle: 0,
    VehicleType.twoWheeler: 0,
    VehicleType.fourWheeler: 0,
    VehicleType.auto: 0,
  };

  List<Vehicle> get activeVehicles => _activeVehicles;
  List<Vehicle> get completedVehicles => _completedVehicles;
  double get todayCollection => _todayCollection;
  Map<VehicleType, int> get vehicleTypeStats => _vehicleTypeCount;
  
  int get totalActiveVehicles => _activeVehicles.length;
  int get todayCompletedVehicles {
    final today = DateTime.now();
    return _completedVehicles.where((v) {
      return v.exitTime != null &&
          v.exitTime!.day == today.day &&
          v.exitTime!.month == today.month &&
          v.exitTime!.year == today.year;
    }).length;
  }

  VehicleProvider() {
    loadVehicles();
  }

  Future<void> loadVehicles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final activeJson = prefs.getString('active_vehicles');
      if (activeJson != null) {
        final List<dynamic> decoded = json.decode(activeJson);
        _activeVehicles = decoded.map((item) => Vehicle.fromJson(item)).toList();
      }
      
      final completedJson = prefs.getString('completed_vehicles');
      if (completedJson != null) {
        final List<dynamic> decoded = json.decode(completedJson);
        _completedVehicles = decoded.map((item) => Vehicle.fromJson(item)).toList();
      }
      
      _calculateTodayCollection();
      _updateVehicleTypeCount();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading vehicles: $e');
    }
  }

  Future<void> saveVehicles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final activeJson = json.encode(_activeVehicles.map((v) => v.toJson()).toList());
      await prefs.setString('active_vehicles', activeJson);
      
      final completedJson = json.encode(_completedVehicles.map((v) => v.toJson()).toList());
      await prefs.setString('completed_vehicles', completedJson);
    } catch (e) {
      debugPrint('Error saving vehicles: $e');
    }
  }

  void addVehicle(Vehicle vehicle) {
    _activeVehicles.add(vehicle);
    _updateVehicleTypeCount();
    saveVehicles();
    notifyListeners();
  }

  Vehicle? getVehicleById(String id) {
    try {
      return _activeVehicles.firstWhere((v) => v.id == id);
    } catch (e) {
      return null;
    }
  }

  Vehicle? getVehicleByNumber(String number) {
    try {
      return _activeVehicles.firstWhere(
        (v) => v.vehicleNumber.toLowerCase() == number.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  void exitVehicle(String vehicleId, double amount) {
    final index = _activeVehicles.indexWhere((v) => v.id == vehicleId);
    if (index != -1) {
      final vehicle = _activeVehicles[index];
      final exitedVehicle = vehicle.copyWith(
        exitTime: DateTime.now(),
        totalAmount: amount,
        isPaid: true,
      );
      
      _activeVehicles.removeAt(index);
      _completedVehicles.add(exitedVehicle);
      
      _calculateTodayCollection();
      _updateVehicleTypeCount();
      saveVehicles();
      notifyListeners();
    }
  }

  void _calculateTodayCollection() {
    final today = DateTime.now();
    _todayCollection = 0.0;
    
    for (var vehicle in _completedVehicles) {
      if (vehicle.exitTime != null &&
          vehicle.exitTime!.day == today.day &&
          vehicle.exitTime!.month == today.month &&
          vehicle.exitTime!.year == today.year) {
        _todayCollection += vehicle.totalAmount ?? 0.0;
      }
    }
  }

  void _updateVehicleTypeCount() {
    _vehicleTypeCount = {
      VehicleType.cycle: 0,
      VehicleType.twoWheeler: 0,
      VehicleType.fourWheeler: 0,
      VehicleType.auto: 0,
    };
    
    for (var vehicle in _activeVehicles) {
      _vehicleTypeCount[vehicle.vehicleType] = 
          (_vehicleTypeCount[vehicle.vehicleType] ?? 0) + 1;
    }
  }

  List<Vehicle> searchVehicles(String query) {
    if (query.isEmpty) return _activeVehicles;
    
    final lowerQuery = query.toLowerCase();
    return _activeVehicles.where((vehicle) {
      return vehicle.vehicleNumber.toLowerCase().contains(lowerQuery) ||
          vehicle.ticketId.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  List<Vehicle> getVehiclesByDateRange(DateTime start, DateTime end) {
    return _completedVehicles.where((vehicle) {
      if (vehicle.exitTime == null) return false;
      return vehicle.exitTime!.isAfter(start) && 
             vehicle.exitTime!.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  double getCollectionByDateRange(DateTime start, DateTime end) {
    double total = 0.0;
    final vehicles = getVehiclesByDateRange(start, end);
    for (var vehicle in vehicles) {
      total += vehicle.totalAmount ?? 0.0;
    }
    return total;
  }

  Map<VehicleType, double> getRevenueByVehicleType(DateTime start, DateTime end) {
    Map<VehicleType, double> revenue = {
      VehicleType.cycle: 0.0,
      VehicleType.twoWheeler: 0.0,
      VehicleType.fourWheeler: 0.0,
      VehicleType.auto: 0.0,
    };
    
    final vehicles = getVehiclesByDateRange(start, end);
    for (var vehicle in vehicles) {
      revenue[vehicle.vehicleType] = 
          (revenue[vehicle.vehicleType] ?? 0.0) + (vehicle.totalAmount ?? 0.0);
    }
    
    return revenue;
  }

  void clearOldData() {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    _completedVehicles.removeWhere((vehicle) {
      return vehicle.exitTime != null && vehicle.exitTime!.isBefore(thirtyDaysAgo);
    });
    saveVehicles();
    notifyListeners();
  }
}