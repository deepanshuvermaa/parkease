import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/database_helper.dart';
import '../services/api_service.dart';
import '../services/device_info_helper.dart';
import 'dart:async';

class HybridAuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = true;
  bool _isOnline = false;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  String? _deviceId;
  Timer? _sessionCheckTimer;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get isOnline => _isOnline;
  bool get isAdmin => _currentUser?.role == 'admin';
  bool get isGuest => _currentUser?.isGuest ?? false;
  bool get canAccess => _currentUser?.canAccess ?? false;
  int get remainingTrialDays => _currentUser?.remainingTrialDays ?? 0;

  HybridAuthProvider() {
    _initializeProvider();
  }
  
  Future<void> _initializeProvider() async {
    _deviceId = await DeviceInfoHelper.getDeviceId();
    await ApiService.initialize();
    await _checkBackendConnectivity();
    await checkAuthStatus();
    _startSessionCheck();
  }

  Future<void> _checkBackendConnectivity() async {
    _isOnline = await ApiService.isBackendHealthy();
    notifyListeners();
  }
  
  void _startSessionCheck() {
    _sessionCheckTimer?.cancel();
    _sessionCheckTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _checkSessionValidity();
    });
  }
  
  Future<void> _checkSessionValidity() async {
    if (_currentUser == null) return;
    
    // Check backend connectivity periodically
    await _checkBackendConnectivity();
    
    // Check if guest trial expired
    if (_currentUser!.isGuest && !_currentUser!.canAccess) {
      await logout();
      notifyListeners();
      return;
    }
    
    // If online, sync with backend
    if (_isOnline) {
      await _syncWithBackend();
    }
  }
  
  Future<void> _syncWithBackend() async {
    try {
      // Sync any pending local data to backend
      // This is where you'd implement data synchronization logic
      print('Syncing with backend...');
    } catch (e) {
      print('Sync error: $e');
    }
  }
  
  @override
  void dispose() {
    _sessionCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      final username = prefs.getString('username');
      final fullName = prefs.getString('fullName');
      final role = prefs.getString('role');
      final rememberMe = prefs.getBool('rememberMe') ?? false;

      if (rememberMe && userId != null && username != null && fullName != null && role != null) {
        // Try to restore user session
        if (_isOnline) {
          // If online, validate with backend
          final isValidSession = await _validateBackendSession();
          if (isValidSession) {
            _currentUser = User(
              id: userId,
              username: username,
              password: '',
              fullName: fullName,
              role: role,
              createdAt: DateTime.now(),
            );
            _isAuthenticated = true;
          } else {
            // Backend session invalid, clear local session
            await _clearLocalSession();
          }
        } else {
          // Offline mode - use local session
          _currentUser = User(
            id: userId,
            username: username,
            password: '',
            fullName: fullName,
            role: role,
            createdAt: DateTime.now(),
          );
          _isAuthenticated = true;
        }
      }
    } catch (e) {
      debugPrint('Error checking auth status: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> _validateBackendSession() async {
    try {
      // Try to make an authenticated request
      final settings = await ApiService.getSettings();
      return settings != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> _clearLocalSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('username');
    await prefs.remove('fullName');
    await prefs.remove('role');
    await prefs.setBool('rememberMe', false);
  }

  Future<bool> login(String username, String password, bool rememberMe) async {
    _isLoading = true;
    notifyListeners();

    try {
      User? user;
      
      if (_isOnline) {
        // Try backend login first
        final backendResponse = await ApiService.login(username, password);
        if (backendResponse != null) {
          user = User(
            id: backendResponse['user']['id'],
            username: backendResponse['user']['username'],
            password: '',
            fullName: backendResponse['user']['fullName'],
            role: backendResponse['user']['role'],
            createdAt: DateTime.parse(backendResponse['user']['createdAt']),
            isGuest: backendResponse['user']['isGuest'] ?? false,
            trialStartDate: backendResponse['user']['trialStartDate'] != null
                ? DateTime.parse(backendResponse['user']['trialStartDate'])
                : null,
            trialEndDate: backendResponse['user']['trialEndDate'] != null
                ? DateTime.parse(backendResponse['user']['trialEndDate'])
                : null,
          );
          
          // Store in local database for offline access
          await _dbHelper.createUser(user, password);
        }
      } else {
        // Offline mode - use local database
        user = await _dbHelper.authenticateUser(username, password);
      }
      
      if (user != null) {
        _currentUser = user;
        _isAuthenticated = true;
        
        // Save auth state
        if (rememberMe) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userId', user.id);
          await prefs.setString('username', user.username);
          await prefs.setString('fullName', user.fullName);
          await prefs.setString('role', user.role);
          await prefs.setBool('rememberMe', true);
        }
        
        return true;
      }
    } catch (e) {
      debugPrint('Login error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    
    return false;
  }

  Future<bool> guestSignup(String username, String fullName) async {
    _isLoading = true;
    notifyListeners();

    try {
      User? user;
      
      if (_isOnline) {
        // Try backend signup first
        final backendResponse = await ApiService.guestSignup(username, fullName);
        if (backendResponse != null) {
          user = User(
            id: backendResponse['user']['id'],
            username: backendResponse['user']['username'],
            password: '',
            fullName: backendResponse['user']['fullName'],
            role: backendResponse['user']['role'],
            createdAt: DateTime.parse(backendResponse['user']['createdAt']),
            isGuest: true,
            trialStartDate: DateTime.parse(backendResponse['user']['trialStartDate']),
            trialEndDate: DateTime.parse(backendResponse['user']['trialEndDate']),
          );
          
          // Store in local database
          await _dbHelper.createUser(user, 'guest');
        }
      } else {
        // Offline guest signup
        final trialStart = DateTime.now();
        final trialEnd = trialStart.add(const Duration(days: 3));
        
        user = User(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          username: username,
          password: 'guest',
          fullName: fullName,
          role: 'guest',
          createdAt: DateTime.now(),
          isGuest: true,
          trialStartDate: trialStart,
          trialEndDate: trialEnd,
        );
        
        await _dbHelper.createUser(user, 'guest');
      }
      
      if (user != null) {
        _currentUser = user;
        _isAuthenticated = true;
        
        // Save auth state
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', user.id);
        await prefs.setString('username', user.username);
        await prefs.setString('fullName', user.fullName);
        await prefs.setString('role', user.role);
        await prefs.setBool('rememberMe', true);
        
        return true;
      }
    } catch (e) {
      debugPrint('Guest signup error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    
    return false;
  }

  Future<void> logout({String? showMessage}) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_isOnline) {
        await ApiService.logout();
      }
      
      // Clear local state
      _currentUser = null;
      _isAuthenticated = false;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userId');
      await prefs.remove('username');
      await prefs.remove('fullName');
      await prefs.remove('role');
      await prefs.setBool('rememberMe', false);
      
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Force refresh connectivity status
  Future<void> refreshConnectivity() async {
    await _checkBackendConnectivity();
    if (_isOnline && _currentUser != null) {
      await _syncWithBackend();
    }
  }
}