import 'dart:math';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ticket_id_settings.dart';

class TicketIdGenerator {
  static const String _sequenceKey = 'ticket_sequence_counter';
  static const String _lastResetDateKey = 'ticket_last_reset_date';
  
  static Future<String> generateTicketId(TicketIdSettings settings, {String? locationCode}) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if we need to reset the counter (daily reset)
    if (settings.resetDaily) {
      await _checkAndResetDailyCounter(prefs);
    }
    
    // Get and increment sequence counter
    int sequence = prefs.getInt(_sequenceKey) ?? 1;
    await prefs.setInt(_sequenceKey, sequence + 1);
    
    // Get the pattern to use
    String pattern = settings.format == TicketIdFormat.custom 
        ? settings.customPattern 
        : settings.format.defaultPattern;
    
    if (pattern.isEmpty) {
      pattern = TicketIdFormat.dateTime.defaultPattern;
    }
    
    // Replace pattern variables
    String ticketId = _replacePatternVariables(
      pattern, 
      sequence, 
      settings.prefix,
      locationCode,
    );
    
    return ticketId;
  }
  
  static Future<void> _checkAndResetDailyCounter(SharedPreferences prefs) async {
    final lastResetDate = prefs.getString(_lastResetDateKey);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    if (lastResetDate != today) {
      await prefs.setInt(_sequenceKey, 1);
      await prefs.setString(_lastResetDateKey, today);
    }
  }
  
  static String _replacePatternVariables(
    String pattern, 
    int sequence,
    String prefix,
    String? locationCode,
  ) {
    final now = DateTime.now();
    final random = Random();
    
    // Replace date/time variables
    pattern = pattern.replaceAll('{YYYY}', DateFormat('yyyy').format(now));
    pattern = pattern.replaceAll('{YY}', DateFormat('yy').format(now));
    pattern = pattern.replaceAll('{MM}', DateFormat('MM').format(now));
    pattern = pattern.replaceAll('{DD}', DateFormat('dd').format(now));
    pattern = pattern.replaceAll('{HH}', DateFormat('HH').format(now));
    pattern = pattern.replaceAll('{mm}', DateFormat('mm').format(now));
    pattern = pattern.replaceAll('{ss}', DateFormat('ss').format(now));
    
    // Replace YYYYMMDD shorthand
    pattern = pattern.replaceAll('{YYYYMMDD}', DateFormat('yyyyMMdd').format(now));
    pattern = pattern.replaceAll('{YYMMDD}', DateFormat('yyMMdd').format(now));
    
    // Replace prefix
    pattern = pattern.replaceAll('{PREFIX}', prefix);
    
    // Replace location code if available
    if (locationCode != null) {
      pattern = pattern.replaceAll('{LOC}', locationCode);
    }
    
    // Replace sequence with padding
    final seqRegex = RegExp(r'\{SEQ:(\d+)\}');
    pattern = pattern.replaceAllMapped(seqRegex, (match) {
      final padding = int.parse(match.group(1)!);
      return sequence.toString().padLeft(padding, '0');
    });
    
    // Replace random alphanumeric
    final randRegex = RegExp(r'\{RAND:(\d+)([AN]?)\}');
    pattern = pattern.replaceAllMapped(randRegex, (match) {
      final length = int.parse(match.group(1)!);
      final type = match.group(2) ?? 'N';
      
      if (type == 'A') {
        // Generate random letters
        return _generateRandomLetters(length);
      } else if (type == 'N') {
        // Generate random numbers
        return _generateRandomNumbers(length);
      } else {
        // Generate random alphanumeric
        return _generateRandomAlphanumeric(length);
      }
    });
    
    // Simple sequence replacement (without padding specification)
    pattern = pattern.replaceAll('{SEQ}', sequence.toString());
    
    return pattern;
  }
  
  static String _generateRandomLetters(int length) {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final random = Random();
    return String.fromCharCodes(
      List.generate(length, (_) => letters.codeUnitAt(random.nextInt(letters.length)))
    );
  }
  
  static String _generateRandomNumbers(int length) {
    final random = Random();
    return List.generate(length, (_) => random.nextInt(10).toString()).join();
  }
  
  static String _generateRandomAlphanumeric(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      List.generate(length, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
  }
  
  static Future<void> resetSequenceCounter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sequenceKey, 1);
    await prefs.setString(_lastResetDateKey, DateFormat('yyyy-MM-dd').format(DateTime.now()));
  }
  
  static Future<int> getCurrentSequence() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_sequenceKey) ?? 1;
  }
}