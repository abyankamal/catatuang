import 'package:catatuang/features/transaction/domain/recurring_schedule_helper.dart';
import 'package:catatuang/features/transaction/domain/recurring_transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RecurringScheduleHelper - calculateNextDueDate Tests', () {
    test('Calculates DAILY frequency with interval 1 and interval 3', () {
      final baseDate = DateTime(2026, 3, 10, 8, 30);

      final next1 = RecurringScheduleHelper.calculateNextDueDate(
        currentDueDate: baseDate,
        frequency: RecurringScheduleHelper.daily,
        interval: 1,
      );
      expect(next1, equals(DateTime(2026, 3, 11, 8, 30)));

      final next3 = RecurringScheduleHelper.calculateNextDueDate(
        currentDueDate: baseDate,
        frequency: RecurringScheduleHelper.daily,
        interval: 3,
      );
      expect(next3, equals(DateTime(2026, 3, 13, 8, 30)));
    });

    test('Calculates WEEKLY frequency across month boundary', () {
      final baseDate = DateTime(2026, 3, 26, 10, 0); // 26 March

      final nextWeek = RecurringScheduleHelper.calculateNextDueDate(
        currentDueDate: baseDate,
        frequency: RecurringScheduleHelper.weekly,
        interval: 1,
      );
      expect(nextWeek, equals(DateTime(2026, 4, 2, 10, 0))); // 26 + 7 = 33 -> 2 April

      final twoWeeks = RecurringScheduleHelper.calculateNextDueDate(
        currentDueDate: baseDate,
        frequency: RecurringScheduleHelper.weekly,
        interval: 2,
      );
      expect(twoWeeks, equals(DateTime(2026, 4, 9, 10, 0))); // 26 + 14 = 40 -> 9 April
    });

    test('Calculates MONTHLY frequency standard case', () {
      final baseDate = DateTime(2026, 5, 15, 14, 0);

      final nextMonth = RecurringScheduleHelper.calculateNextDueDate(
        currentDueDate: baseDate,
        frequency: RecurringScheduleHelper.monthly,
        interval: 1,
      );
      expect(nextMonth, equals(DateTime(2026, 6, 15, 14, 0)));

      final threeMonths = RecurringScheduleHelper.calculateNextDueDate(
        currentDueDate: baseDate,
        frequency: RecurringScheduleHelper.monthly,
        interval: 3,
      );
      expect(threeMonths, equals(DateTime(2026, 8, 15, 14, 0)));
    });

    test('Calculates MONTHLY frequency with year rollover', () {
      final baseDate = DateTime(2026, 11, 20, 9, 0);

      final nextMonth = RecurringScheduleHelper.calculateNextDueDate(
        currentDueDate: baseDate,
        frequency: RecurringScheduleHelper.monthly,
        interval: 3,
      );
      expect(nextMonth, equals(DateTime(2027, 2, 20, 9, 0)));
    });

    test('Handles month-end clamping (Jan 31 -> Feb 28) and preserves anchorDay for March', () {
      final jan31 = DateTime(2026, 1, 31, 12, 0);

      // 31 Jan -> Feb (2026 non-leap year has 28 days)
      final feb = RecurringScheduleHelper.calculateNextDueDate(
        currentDueDate: jan31,
        frequency: RecurringScheduleHelper.monthly,
        interval: 1,
        anchorDay: 31,
      );
      expect(feb, equals(DateTime(2026, 2, 28, 12, 0)));

      // Next from Feb with anchorDay 31 should restore to 31 March
      final mar = RecurringScheduleHelper.calculateNextDueDate(
        currentDueDate: feb,
        frequency: RecurringScheduleHelper.monthly,
        interval: 1,
        anchorDay: 31,
      );
      expect(mar, equals(DateTime(2026, 3, 31, 12, 0)));

      // Next to April (which has 30 days) clamps to 30 April
      final apr = RecurringScheduleHelper.calculateNextDueDate(
        currentDueDate: mar,
        frequency: RecurringScheduleHelper.monthly,
        interval: 1,
        anchorDay: 31,
      );
      expect(apr, equals(DateTime(2026, 4, 30, 12, 0)));
    });

    test('Handles leap year leap day (Feb 29 on leap year 2028)', () {
      final jan31 = DateTime(2028, 1, 31, 10, 0);

      final febLeap = RecurringScheduleHelper.calculateNextDueDate(
        currentDueDate: jan31,
        frequency: RecurringScheduleHelper.monthly,
        interval: 1,
        anchorDay: 31,
      );
      expect(febLeap, equals(DateTime(2028, 2, 29, 10, 0)));
    });

    test('Calculates YEARLY frequency with leap day handling', () {
      final leapDay = DateTime(2028, 2, 29, 10, 0);

      final nextYear = RecurringScheduleHelper.calculateNextDueDate(
        currentDueDate: leapDay,
        frequency: RecurringScheduleHelper.yearly,
        interval: 1,
        anchorDay: 29,
      );
      // 2029 is not a leap year, clamps to Feb 28
      expect(nextYear, equals(DateTime(2029, 2, 28, 10, 0)));
    });
  });

  group('RecurringScheduleHelper - isCompleted Tests', () {
    test('Returns false when neither maxOccurrences nor endDate is set', () {
      final recurring = RecurringTransaction()
        ..syncId = 'rec_1'
        ..type = 'EXPENSE'
        ..amount = 50000
        ..frequency = 'MONTHLY'
        ..interval = 1
        ..startDate = DateTime(2026, 1, 1)
        ..nextDueDate = DateTime(2026, 2, 1)
        ..occurrenceCount = 10;

      expect(RecurringScheduleHelper.isCompleted(recurring), isFalse);
    });

    test('Returns true when occurrenceCount reaches maxOccurrences', () {
      final recurring = RecurringTransaction()
        ..syncId = 'rec_2'
        ..type = 'EXPENSE'
        ..amount = 50000
        ..frequency = 'MONTHLY'
        ..interval = 1
        ..startDate = DateTime(2026, 1, 1)
        ..nextDueDate = DateTime(2026, 6, 1)
        ..maxOccurrences = 5
        ..occurrenceCount = 5;

      expect(RecurringScheduleHelper.isCompleted(recurring), isTrue);
    });

    test('Returns true when nextDueDate exceeds endDate', () {
      final recurring = RecurringTransaction()
        ..syncId = 'rec_3'
        ..type = 'EXPENSE'
        ..amount = 50000
        ..frequency = 'MONTHLY'
        ..interval = 1
        ..startDate = DateTime(2026, 1, 1)
        ..endDate = DateTime(2026, 5, 31)
        ..nextDueDate = DateTime(2026, 6, 1)
        ..occurrenceCount = 4;

      expect(RecurringScheduleHelper.isCompleted(recurring), isTrue);
    });
  });

  group('RecurringScheduleHelper - getMissedDueDates Multi-Cycle Catch-Up Tests', () {
    test('Returns empty list when nextDueDate is in the future', () {
      final now = DateTime(2026, 3, 15);
      final recurring = RecurringTransaction()
        ..syncId = 'rec_future'
        ..type = 'EXPENSE'
        ..amount = 100000
        ..frequency = 'MONTHLY'
        ..interval = 1
        ..isActive = true
        ..startDate = DateTime(2026, 3, 1)
        ..nextDueDate = DateTime(2026, 4, 1);

      final missed = RecurringScheduleHelper.getMissedDueDates(recurring, now);
      expect(missed, isEmpty);
    });

    test('Enumerates all missed monthly cycles when app is not opened for 3 months', () {
      // Current time is 15 April 2026
      final now = DateTime(2026, 4, 15, 12, 0);

      // Schedule was due on 1 Feb, 1 Mar, 1 Apr
      final recurring = RecurringTransaction()
        ..syncId = 'rec_lag'
        ..type = 'EXPENSE'
        ..amount = 150000
        ..frequency = 'MONTHLY'
        ..interval = 1
        ..isActive = true
        ..startDate = DateTime(2026, 1, 1, 8, 0)
        ..nextDueDate = DateTime(2026, 2, 1, 8, 0)
        ..occurrenceCount = 1;

      final missed = RecurringScheduleHelper.getMissedDueDates(recurring, now);
      expect(missed.length, equals(3));
      expect(missed[0], equals(DateTime(2026, 2, 1, 8, 0)));
      expect(missed[1], equals(DateTime(2026, 3, 1, 8, 0)));
      expect(missed[2], equals(DateTime(2026, 4, 1, 8, 0)));
    });

    test('Caps missed cycles to maxCycles (12) to prevent infinite loop or spam', () {
      // App hasn't been opened for 2 years (24 months)
      final now = DateTime(2028, 1, 1);

      final recurring = RecurringTransaction()
        ..syncId = 'rec_ancient'
        ..type = 'EXPENSE'
        ..amount = 20000
        ..frequency = 'MONTHLY'
        ..interval = 1
        ..isActive = true
        ..startDate = DateTime(2026, 1, 1)
        ..nextDueDate = DateTime(2026, 2, 1);

      final missed = RecurringScheduleHelper.getMissedDueDates(recurring, now, maxCycles: 12);
      expect(missed.length, equals(12));
    });

    test('Stops catch-up when maxOccurrences or endDate is reached', () {
      final now = DateTime(2026, 8, 1);

      final recurring = RecurringTransaction()
        ..syncId = 'rec_capped'
        ..type = 'EXPENSE'
        ..amount = 50000
        ..frequency = 'MONTHLY'
        ..interval = 1
        ..isActive = true
        ..startDate = DateTime(2026, 1, 1)
        ..nextDueDate = DateTime(2026, 2, 1)
        ..occurrenceCount = 1
        ..maxOccurrences = 3; // Should only yield 2 more (total 3)

      final missed = RecurringScheduleHelper.getMissedDueDates(recurring, now);
      expect(missed.length, equals(2));
      expect(missed[0], equals(DateTime(2026, 2, 1)));
      expect(missed[1], equals(DateTime(2026, 3, 1)));
    });
  });

  group('RecurringScheduleHelper - formatFrequency Tests', () {
    test('Formats Indonesian text correctly for all frequencies and intervals', () {
      expect(RecurringScheduleHelper.formatFrequency('DAILY', 1), equals('Setiap Hari'));
      expect(RecurringScheduleHelper.formatFrequency('DAILY', 3), equals('Setiap 3 Hari'));

      expect(RecurringScheduleHelper.formatFrequency('WEEKLY', 1), equals('Setiap Minggu'));
      expect(RecurringScheduleHelper.formatFrequency('WEEKLY', 2), equals('Setiap 2 Minggu'));

      expect(RecurringScheduleHelper.formatFrequency('MONTHLY', 1), equals('Setiap Bulan'));
      expect(RecurringScheduleHelper.formatFrequency('MONTHLY', 6), equals('Setiap 6 Bulan'));

      expect(RecurringScheduleHelper.formatFrequency('YEARLY', 1), equals('Setiap Tahun'));
    });
  });
}
