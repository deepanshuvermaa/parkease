import 'package:intl/intl.dart';
import 'dart:math';

class Helpers {
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '$hours hr ${minutes} min';
    } else {
      return '$minutes min';
    }
  }

  static String formatCurrency(double amount) {
    return 'Rs.${amount.toStringAsFixed(2)}';
  }

  static String generateTicketId() {
    final now = DateTime.now();
    final dateStr = DateFormat('yyMMdd').format(now);
    final random = Random();
    final randomNum = random.nextInt(9999).toString().padLeft(4, '0');
    return 'T$dateStr$randomNum';
  }

  static bool isValidVehicleNumber(String number) {
    if (number.isEmpty) return false;
    
    final regExp = RegExp(
      r'^[A-Z]{2}[\s-]?[0-9]{1,2}[\s-]?[A-Z]{1,2}[\s-]?[0-9]{1,4}$',
      caseSensitive: false,
    );
    
    return regExp.hasMatch(number.replaceAll(' ', ''));
  }

  static String formatVehicleNumber(String number) {
    return number.toUpperCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatTime(DateTime time) {
    return DateFormat('hh:mm a').format(time);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
  }

  static String formatDateShort(DateTime date) {
    return DateFormat('dd/MM/yy').format(date);
  }

  static String formatTimeShort(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  static double calculateParkingFee(DateTime entryTime, DateTime exitTime, double ratePerHour) {
    final duration = exitTime.difference(entryTime);
    final hours = (duration.inMinutes / 60).ceil();
    return hours * ratePerHour;
  }

  static String getGreeting() {
    final hour = DateTime.now().hour;
    
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 7) {
      return formatDate(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }

  static String getDayLabel(DateTime date) {
    if (isToday(date)) {
      return 'Today';
    } else if (isYesterday(date)) {
      return 'Yesterday';
    } else {
      return formatDate(date);
    }
  }

  static int getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  static List<DateTime> getWeekDates(DateTime date) {
    final weekday = date.weekday;
    final startOfWeek = date.subtract(Duration(days: weekday - 1));
    
    return List.generate(7, (index) {
      return startOfWeek.add(Duration(days: index));
    });
  }

  static String getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  static String getDayName(int weekday) {
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 
      'Friday', 'Saturday', 'Sunday'
    ];
    return days[weekday - 1];
  }
}