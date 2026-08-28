import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _shortDate = DateFormat('d MMM yyyy', 'id_ID');
  static final DateFormat _fullDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID');
  static final DateFormat _monthYear = DateFormat('MMMM yyyy', 'id_ID');
  static final DateFormat _dayMonthYearTime = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID');
  static final DateFormat _timeOnly = DateFormat('HH:mm');
  static final DateFormat _isoDateKey = DateFormat('yyyy-MM-dd');

  /// Format tanggal singkat (contoh: 'Hari ini', 'Kemarin', atau '28 Agu 2026')
  static String formatShortDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final difference = today.difference(target).inDays;

    if (difference == 0) {
      return 'Hari ini';
    } else if (difference == 1) {
      return 'Kemarin';
    } else {
      return _shortDate.format(date);
    }
  }

  /// Format tanggal lengkap (contoh: 'Jumat, 28 Agustus 2026')
  static String formatFullDate(DateTime date) {
    return _fullDate.format(date);
  }

  /// Format bulan dan tahun (contoh: 'Agustus 2026')
  static String formatMonthYear(DateTime date) {
    return _monthYear.format(date);
  }

  /// Format tanggal dan waktu (contoh: '28 Agustus 2026, 20:50')
  static String formatDateTime(DateTime date) {
    return _dayMonthYearTime.format(date);
  }

  /// Format waktu saja (contoh: '20:50')
  static String formatTime(DateTime date) {
    return _timeOnly.format(date);
  }

  /// Format ISO key tanggal untuk grouping (contoh: '2026-08-28')
  static String formatIsoDateKey(DateTime date) {
    return _isoDateKey.format(date);
  }
}
