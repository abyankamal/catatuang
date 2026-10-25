import 'recurring_transaction.dart';

class RecurringScheduleHelper {
  static const String daily = 'DAILY';
  static const String weekly = 'WEEKLY';
  static const String monthly = 'MONTHLY';
  static const String yearly = 'YEARLY';

  /// Menghitung tanggal jatuh tempo berikutnya berdasarkan frekuensi dan interval.
  /// [anchorDay] dapat diberikan untuk mempertahankan hari yang diinginkan pada akhir bulan
  /// (misalnya tanggal 31 Januari -> 28 Februari -> 31 Maret).
  static DateTime calculateNextDueDate({
    required DateTime currentDueDate,
    required String frequency,
    int interval = 1,
    int? anchorDay,
  }) {
    final step = interval < 1 ? 1 : interval;
    final preferredDay = anchorDay ?? currentDueDate.day;

    switch (frequency.toUpperCase()) {
      case daily:
        return DateTime(
          currentDueDate.year,
          currentDueDate.month,
          currentDueDate.day + step,
          currentDueDate.hour,
          currentDueDate.minute,
          currentDueDate.second,
        );

      case weekly:
        return DateTime(
          currentDueDate.year,
          currentDueDate.month,
          currentDueDate.day + (7 * step),
          currentDueDate.hour,
          currentDueDate.minute,
          currentDueDate.second,
        );

      case monthly:
        var totalMonths = currentDueDate.month + step;
        var newYear = currentDueDate.year;
        while (totalMonths > 12) {
          newYear++;
          totalMonths -= 12;
        }
        final newMonth = totalMonths;
        final daysInNewMonth = DateTime(newYear, newMonth + 1, 0).day;
        final actualDay = preferredDay > daysInNewMonth ? daysInNewMonth : preferredDay;

        return DateTime(
          newYear,
          newMonth,
          actualDay,
          currentDueDate.hour,
          currentDueDate.minute,
          currentDueDate.second,
        );

      case yearly:
        final newYear = currentDueDate.year + step;
        final targetMonth = currentDueDate.month;
        final daysInMonth = DateTime(newYear, targetMonth + 1, 0).day;
        final actualDay = preferredDay > daysInMonth ? daysInMonth : preferredDay;

        return DateTime(
          newYear,
          targetMonth,
          actualDay,
          currentDueDate.hour,
          currentDueDate.minute,
          currentDueDate.second,
        );

      default:
        // Fallback jika tipe tidak dikenal: anggap bulanan
        return DateTime(
          currentDueDate.year,
          currentDueDate.month + step,
          currentDueDate.day,
          currentDueDate.hour,
          currentDueDate.minute,
          currentDueDate.second,
        );
    }
  }

  /// Menormalkan waktu ke awal hari (00:00:00.000).
  static DateTime startOfDay(DateTime dateTime) {
    return DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      0,
      0,
      0,
      0,
    );
  }

  /// Menormalkan waktu ke batas akhir hari (23:59:59.999).
  static DateTime endOfDay(DateTime dateTime) {
    return DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      23,
      59,
      59,
      999,
    );
  }

  /// Memeriksa apakah jadwal berulang sudah mencapai batas akhir (kadaluarsa/selesai).
  static bool isCompleted(RecurringTransaction recurring) {
    // 1. Batas jumlah pengulangan
    if (recurring.maxOccurrences != null && recurring.maxOccurrences! > 0) {
      if (recurring.occurrenceCount >= recurring.maxOccurrences!) {
        return true;
      }
    }

    // 2. Batas tanggal akhir dinormalisasi ke akhir hari (23:59:59.999)
    // agar siklus terakhir pada tanggal endDate tetap tereksekusi meskipun
    // tanggal endDate berasal dari date picker dengan jam 00:00:00.
    if (recurring.endDate != null) {
      final normalizedEndDate = endOfDay(recurring.endDate!);
      if (recurring.nextDueDate.isAfter(normalizedEndDate)) {
        return true;
      }
    }

    return false;
  }

  /// Menghasilkan daftar tanggal jatuh tempo yang tertunda (*missed cycles*)
  /// hingga batas akhir hari [now], dibatasi maksimal [maxCycles] (default 12) untuk mencegah loop/spam.
  static List<DateTime> getMissedDueDates(
    RecurringTransaction recurring,
    DateTime now, {
    int maxCycles = 12,
  }) {
    if (!recurring.isActive || isCompleted(recurring)) {
      return const [];
    }

    final normalizedNow = endOfDay(now);
    if (recurring.nextDueDate.isAfter(normalizedNow)) {
      return const [];
    }

    final missedDates = <DateTime>[];
    var currentCursor = recurring.nextDueDate;
    var virtualCount = recurring.occurrenceCount;
    final anchorDay = recurring.startDate.day;
    final normalizedEndDate =
        recurring.endDate != null ? endOfDay(recurring.endDate!) : null;

    while (!currentCursor.isAfter(normalizedNow) && missedDates.length < maxCycles) {
      // Periksa apakah batas tanggal atau batas pengulangan tercapai
      if (normalizedEndDate != null && currentCursor.isAfter(normalizedEndDate)) {
        break;
      }

      if (recurring.maxOccurrences != null &&
          recurring.maxOccurrences! > 0 &&
          virtualCount >= recurring.maxOccurrences!) {
        break;
      }

      missedDates.add(currentCursor);
      virtualCount++;

      currentCursor = calculateNextDueDate(
        currentDueDate: currentCursor,
        frequency: recurring.frequency,
        interval: recurring.interval,
        anchorDay: anchorDay,
      );
    }

    return missedDates;
  }

  /// Format teks frekuensi ramah pengguna dalam Bahasa Indonesia.
  static String formatFrequency(String frequency, int interval) {
    final step = interval < 1 ? 1 : interval;
    switch (frequency.toUpperCase()) {
      case daily:
        return step == 1 ? 'Setiap Hari' : 'Setiap $step Hari';
      case weekly:
        return step == 1 ? 'Setiap Minggu' : 'Setiap $step Minggu';
      case monthly:
        return step == 1 ? 'Setiap Bulan' : 'Setiap $step Bulan';
      case yearly:
        return step == 1 ? 'Setiap Tahun' : 'Setiap $step Tahun';
      default:
        return 'Setiap $step Siklus';
    }
  }
}
