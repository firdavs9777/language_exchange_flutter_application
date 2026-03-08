import 'package:intl/intl.dart';

/// Convert UTC DateTime to user's local timezone
DateTime toLocalTime(DateTime utcDateTime) {
  return utcDateTime.toLocal();
}

/// Parse UTC string and convert to user's local time
DateTime parseToLocalTime(String dateString) {
  try {
    final utcDateTime = DateTime.parse(dateString);
    // DateTime.parse handles the 'Z' suffix and returns UTC
    // If it has 'Z' or timezone offset, it's already properly parsed as UTC
    // Convert to UTC first, then to local time
    return utcDateTime.toUtc().toLocal();
  } catch (e) {
    // If parsing fails, return current local time
    return DateTime.now();
  }
}

// Legacy functions for backward compatibility - now use local time
@Deprecated('Use toLocalTime instead')
DateTime toKoreaTime(DateTime utcDateTime) => toLocalTime(utcDateTime);

@Deprecated('Use parseToLocalTime instead')
DateTime parseToKoreaTime(String dateString) => parseToLocalTime(dateString);

/// Format message time in user's local timezone
String formatMessageTime(String dateString) {
  try {
    final localTime = parseToLocalTime(dateString);
    final now = DateTime.now();
    final difference = now.difference(localTime);

    if (difference.inDays > 6) {
      return '${localTime.month}/${localTime.day}/${localTime.year.toString().substring(2)}';
    } else if (difference.inDays > 0) {
      return '${localTime.month}/${localTime.day}';
    } else {
      // 12-hour format with AM/PM
      int hour = localTime.hour;
      String period = hour >= 12 ? 'PM' : 'AM';
      hour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$hour:${localTime.minute.toString().padLeft(2, '0')} $period';
    }
  } catch (e) {
    return dateString;
  }
}

/// Format full date and time in user's local timezone
String formatFullDateTime(String dateString) {
  try {
    final localTime = parseToLocalTime(dateString);
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    final weekday = weekdays[localTime.weekday - 1];
    final month = months[localTime.month - 1];

    // 12-hour format
    int hour = localTime.hour;
    String period = hour >= 12 ? 'PM' : 'AM';
    hour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final time = '$hour:${localTime.minute.toString().padLeft(2, '0')} $period';

    return '$weekday, $month ${localTime.day}, ${localTime.year} at $time';
  } catch (e) {
    return dateString;
  }
}

/// Format date with DateFormat in user's local timezone
String formatDateWithFormat(String dateString, String format) {
  try {
    final localTime = parseToLocalTime(dateString);
    return DateFormat(format).format(localTime);
  } catch (e) {
    return dateString;
  }
}

/// Get current time in user's local timezone
DateTime getLocalNow() {
  return DateTime.now();
}

// Legacy function for backward compatibility
@Deprecated('Use getLocalNow instead')
DateTime getKoreaNow() => getLocalNow();

