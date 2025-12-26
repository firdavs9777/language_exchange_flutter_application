import 'package:intl/intl.dart';

/// Convert UTC DateTime to Korea timezone (Asia/Seoul)
DateTime toKoreaTime(DateTime utcDateTime) {
  // Korea is UTC+9
  return utcDateTime.add(const Duration(hours: 9));
}

/// Parse UTC string and convert to Korea time
DateTime parseToKoreaTime(String dateString) {
  try {
    final utcDateTime = DateTime.parse(dateString);
    // If the string doesn't have timezone info, assume it's UTC
    if (!dateString.contains('Z') && !dateString.contains('+') && !dateString.contains('-')) {
      return toKoreaTime(utcDateTime.toUtc());
    }
    return toKoreaTime(utcDateTime);
  } catch (e) {
    // If parsing fails, return current time in Korea
    return toKoreaTime(DateTime.now().toUtc());
  }
}

/// Format message time in Korea timezone
String formatMessageTime(String dateString) {
  try {
    final koreaTime = parseToKoreaTime(dateString);
    final now = toKoreaTime(DateTime.now().toUtc());
    final difference = now.difference(koreaTime);

    if (difference.inDays > 6) {
      return '${koreaTime.month}/${koreaTime.day}/${koreaTime.year.toString().substring(2)}';
    } else if (difference.inDays > 0) {
      return '${koreaTime.month}/${koreaTime.day}';
    } else {
      // 12-hour format with AM/PM
      int hour = koreaTime.hour;
      String period = hour >= 12 ? 'PM' : 'AM';
      hour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$hour:${koreaTime.minute.toString().padLeft(2, '0')} $period';
    }
  } catch (e) {
    return dateString;
  }
}

/// Format full date and time in Korea timezone
String formatFullDateTime(String dateString) {
  try {
    final koreaTime = parseToKoreaTime(dateString);
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

    final weekday = weekdays[koreaTime.weekday - 1];
    final month = months[koreaTime.month - 1];

    // 12-hour format
    int hour = koreaTime.hour;
    String period = hour >= 12 ? 'PM' : 'AM';
    hour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final time = '$hour:${koreaTime.minute.toString().padLeft(2, '0')} $period';

    return '$weekday, $month ${koreaTime.day}, ${koreaTime.year} at $time';
  } catch (e) {
    return dateString;
  }
}

/// Format date with DateFormat in Korea timezone
String formatDateWithFormat(String dateString, String format) {
  try {
    final koreaTime = parseToKoreaTime(dateString);
    return DateFormat(format).format(koreaTime);
  } catch (e) {
    return dateString;
  }
}

/// Get current time in Korea timezone
DateTime getKoreaNow() {
  return toKoreaTime(DateTime.now().toUtc());
}

