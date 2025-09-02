import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/vehicle.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'parkease.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Users table with enhanced fields for guest accounts and device tracking
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        fullName TEXT NOT NULL,
        role TEXT NOT NULL,
        isActive INTEGER DEFAULT 1,
        createdAt INTEGER NOT NULL,
        lastLogin INTEGER,
        isGuest INTEGER DEFAULT 0,
        trialStartDate INTEGER,
        trialEndDate INTEGER,
        isPaid INTEGER DEFAULT 0,
        subscriptionId TEXT,
        subscriptionEndDate INTEGER,
        currentDeviceId TEXT,
        lastDeviceId TEXT
      )
    ''');

    // Vehicles table (as per your specification)
    await db.execute('''
      CREATE TABLE vehicles (
        id TEXT PRIMARY KEY,
        vehicle_number TEXT NOT NULL,
        vehicle_type TEXT NOT NULL,
        entry_time INTEGER NOT NULL,
        exit_time INTEGER,
        rate REAL NOT NULL,
        total_amount REAL,
        is_paid INTEGER DEFAULT 0,
        ticket_id TEXT UNIQUE,
        payment_method TEXT,
        created_at INTEGER DEFAULT (strftime('%s','now'))
      )
    ''');

    // Create indexes
    await db.execute('CREATE INDEX idx_vehicle_number ON vehicles(vehicle_number)');
    await db.execute('CREATE INDEX idx_entry_time ON vehicles(entry_time)');
    await db.execute('CREATE INDEX idx_is_paid ON vehicles(is_paid)');
    await db.execute('CREATE INDEX idx_username ON users(username)');

    // Create default admin user
    await _createDefaultAdmin(db);
  }

  Future<void> _createDefaultAdmin(Database db) async {
    final adminUser = User(
      id: 'admin_${DateTime.now().millisecondsSinceEpoch}',
      username: 'admin',
      password: hashPassword('admin123'), // Default password
      fullName: 'Administrator',
      role: 'admin',
      isActive: true,
      createdAt: DateTime.now(),
    );

    await db.insert('users', adminUser.toJson());
  }

  // Hash password using SHA256
  String hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // User operations
  Future<User?> authenticateUser(String username, String password, {String? deviceId}) async {
    final db = await database;
    final hashedPassword = hashPassword(password);
    
    final result = await db.query(
      'users',
      where: 'username = ? AND password = ? AND isActive = 1',
      whereArgs: [username, hashedPassword],
    );

    if (result.isNotEmpty) {
      var user = User.fromJson(result.first);
      
      // Check if guest user's trial/subscription is still valid
      if (user.isGuest && !user.canAccess) {
        return null; // Block access if trial/subscription expired
      }
      
      // Handle device tracking for single-device enforcement
      if (deviceId != null) {
        if (user.currentDeviceId != null && user.currentDeviceId != deviceId) {
          // Different device trying to login, update device ID
          await db.update(
            'users',
            {
              'lastDeviceId': user.currentDeviceId,
              'currentDeviceId': deviceId,
              'lastLogin': DateTime.now().millisecondsSinceEpoch,
            },
            where: 'id = ?',
            whereArgs: [user.id],
          );
        } else {
          // Same device or first login
          await db.update(
            'users',
            {
              'currentDeviceId': deviceId,
              'lastLogin': DateTime.now().millisecondsSinceEpoch,
            },
            where: 'id = ?',
            whereArgs: [user.id],
          );
        }
        // Refresh user with updated device info
        final updatedResult = await db.query(
          'users',
          where: 'id = ?',
          whereArgs: [user.id],
        );
        if (updatedResult.isNotEmpty) {
          user = User.fromJson(updatedResult.first);
        }
      } else {
        // Just update last login
        await db.update(
          'users',
          {'lastLogin': DateTime.now().millisecondsSinceEpoch},
          where: 'id = ?',
          whereArgs: [user.id],
        );
      }
      
      return user;
    }
    return null;
  }
  
  // Create guest user with trial period
  Future<User?> createGuestUser({
    required String email,
    required String password,
    required String fullName,
    required String deviceId,
  }) async {
    final db = await database;
    
    // Check if email already exists
    final existing = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [email],
    );
    
    if (existing.isNotEmpty) {
      return null; // User already exists
    }
    
    final now = DateTime.now();
    final trialEndDate = now.add(const Duration(days: 3));
    
    final guestUser = User(
      id: 'guest_${now.millisecondsSinceEpoch}',
      username: email,
      password: hashPassword(password),
      fullName: fullName,
      role: 'guest',
      isActive: true,
      createdAt: now,
      isGuest: true,
      trialStartDate: now,
      trialEndDate: trialEndDate,
      currentDeviceId: deviceId,
    );
    
    await db.insert('users', guestUser.toJson());
    return guestUser;
  }
  
  // Check if device is already logged in with another user
  Future<bool> isDeviceInUse(String deviceId, String? excludeUserId) async {
    final db = await database;
    
    String query = 'currentDeviceId = ?';
    List<dynamic> args = [deviceId];
    
    if (excludeUserId != null) {
      query += ' AND id != ?';
      args.add(excludeUserId);
    }
    
    final result = await db.query(
      'users',
      where: query,
      whereArgs: args,
    );
    
    return result.isNotEmpty;
  }
  
  // Update user subscription
  Future<bool> updateUserSubscription({
    required String userId,
    required String subscriptionId,
    required DateTime endDate,
  }) async {
    final db = await database;
    
    final result = await db.update(
      'users',
      {
        'isPaid': 1,
        'subscriptionId': subscriptionId,
        'subscriptionEndDate': endDate.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
    
    return result > 0;
  }
  
  // Remote management - block/unblock user
  Future<bool> toggleUserAccess(String userId, bool enable) async {
    final db = await database;
    
    final result = await db.update(
      'users',
      {'isActive': enable ? 1 : 0},
      where: 'id = ?',
      whereArgs: [userId],
    );
    
    return result > 0;
  }

  Future<int> createUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toJson());
  }

  Future<List<User>> getAllUsers() async {
    final db = await database;
    final result = await db.query('users', orderBy: 'createdAt DESC');
    return result.map((json) => User.fromJson(json)).toList();
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toJson(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(String userId) async {
    final db = await database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<bool> changePassword(String userId, String oldPassword, String newPassword) async {
    final db = await database;
    final hashedOldPassword = hashPassword(oldPassword);
    final hashedNewPassword = hashPassword(newPassword);

    final result = await db.query(
      'users',
      where: 'id = ? AND password = ?',
      whereArgs: [userId, hashedOldPassword],
    );

    if (result.isNotEmpty) {
      await db.update(
        'users',
        {'password': hashedNewPassword},
        where: 'id = ?',
        whereArgs: [userId],
      );
      return true;
    }
    return false;
  }

  // Vehicle operations
  Future<int> insertVehicle(Vehicle vehicle) async {
    final db = await database;
    return await db.insert('vehicles', {
      'id': vehicle.id,
      'vehicle_number': vehicle.vehicleNumber,
      'vehicle_type': vehicle.vehicleType.name,
      'entry_time': vehicle.entryTime.millisecondsSinceEpoch,
      'exit_time': vehicle.exitTime?.millisecondsSinceEpoch,
      'rate': vehicle.rate,
      'total_amount': vehicle.totalAmount,
      'is_paid': vehicle.isPaid ? 1 : 0,
      'ticket_id': vehicle.ticketId,
      'payment_method': 'cash', // Default to cash
    });
  }

  Future<int> updateVehicle(Vehicle vehicle) async {
    final db = await database;
    return await db.update(
      'vehicles',
      {
        'exit_time': vehicle.exitTime?.millisecondsSinceEpoch,
        'total_amount': vehicle.totalAmount,
        'is_paid': vehicle.isPaid ? 1 : 0,
        'payment_method': 'cash', // Default to cash
      },
      where: 'id = ?',
      whereArgs: [vehicle.id],
    );
  }

  Future<List<Map<String, dynamic>>> getActiveVehicles() async {
    final db = await database;
    return await db.query(
      'vehicles',
      where: 'exit_time IS NULL',
      orderBy: 'entry_time DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getVehiclesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    return await db.query(
      'vehicles',
      where: 'entry_time >= ? AND entry_time <= ?',
      whereArgs: [
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ],
      orderBy: 'entry_time DESC',
    );
  }

  Future<Map<String, dynamic>> getDailyStats(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final totalVehicles = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM vehicles
      WHERE entry_time >= ? AND entry_time < ?
    ''', [startOfDay.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch]);

    final totalCollection = await db.rawQuery('''
      SELECT SUM(total_amount) as total
      FROM vehicles
      WHERE exit_time >= ? AND exit_time < ?
    ''', [startOfDay.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch]);

    return {
      'totalVehicles': totalVehicles.first['count'] ?? 0,
      'totalCollection': totalCollection.first['total'] ?? 0.0,
    };
  }

  // Backup and restore
  Future<Map<String, dynamic>> exportDatabase() async {
    final db = await database;
    final vehicles = await db.query('vehicles');
    final users = await db.query('users');

    return {
      'exportDate': DateTime.now().toIso8601String(),
      'vehicles': vehicles,
      'users': users,
    };
  }

  Future<void> importDatabase(Map<String, dynamic> data) async {
    final db = await database;
    
    // Clear existing data
    await db.delete('vehicles');
    await db.delete('users');

    // Import users
    for (final user in data['users']) {
      await db.insert('users', user);
    }

    // Import vehicles
    for (final vehicle in data['vehicles']) {
      await db.insert('vehicles', vehicle);
    }
  }

  Future<void> clearOldData(int daysToKeep) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    
    await db.delete(
      'vehicles',
      where: 'exit_time < ? AND exit_time IS NOT NULL',
      whereArgs: [cutoffDate.millisecondsSinceEpoch],
    );
  }
}