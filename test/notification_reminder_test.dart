import 'package:catatuang/features/contact/domain/contact.dart';
import 'package:catatuang/features/debt/domain/debt.dart';
import 'package:catatuang/features/notification/application/notification_providers.dart';
import 'package:catatuang/features/notification/domain/app_notification.dart';
import 'package:catatuang/features/notification/presentation/widgets/notification_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('id_ID', null);
  });

  group('Notification & Debt Reminders Tests', () {
    test('AppNotificationItem calculates correct urgency levels', () {
      final now = DateTime.now();

      final mockDebt = Debt()
        ..id = 1
        ..syncId = 'd_1'
        ..title = 'Pinjaman Usaha'
        ..type = 'PAYABLE'
        ..contactSyncId = 'c_1'
        ..totalAmount = 1000000
        ..paidAmount = 200000
        ..startDate = now.subtract(const Duration(days: 30))
        ..dueDate = now
        ..isActive = true
        ..createdAt = now
        ..updatedAt = now;

      final item = AppNotificationItem(
        id: 'notif_1',
        title: 'Utang Jatuh Tempo Hari Ini',
        message: 'Segera lunasi utang Pinjaman Usaha hari ini.',
        type: 'PAYABLE',
        urgency: NotificationUrgency.dueToday,
        debtId: 1,
        debt: mockDebt,
        dueDate: now,
        remainingAmount: 800000,
      );

      expect(item.urgency, NotificationUrgency.dueToday);
      expect(item.remainingAmount, 800000);
      expect(item.type, 'PAYABLE');
    });

    testWidgets('NotificationSheet renders empty state when no reminders exist', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeRemindersProvider.overrideWith((ref) => Future.value(const [])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: NotificationSheet(),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Pusat Pengingat'), findsOneWidget);
      expect(find.text('Semua Tagihan Beres!'), findsOneWidget);
    });

    testWidgets('NotificationSheet renders list of active debt reminders', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final now = DateTime.now();
      final mockContact = Contact()
        ..id = 1
        ..syncId = 'c_1'
        ..name = 'Budi Santoso'
        ..phoneNumber = '08123456789'
        ..isActive = true
        ..createdAt = now
        ..updatedAt = now;

      final mockDebt = Debt()
        ..id = 1
        ..syncId = 'd_1'
        ..title = 'Uang Kos'
        ..type = 'PAYABLE'
        ..contactSyncId = 'c_1'
        ..totalAmount = 1500000
        ..paidAmount = 0
        ..startDate = now.subtract(const Duration(days: 20))
        ..dueDate = now
        ..isActive = true
        ..createdAt = now
        ..updatedAt = now;

      final item = AppNotificationItem(
        id: 'notif_1',
        title: 'Utang Jatuh Tempo Hari Ini',
        message: 'Segera lunasi utang "Uang Kos" ke Budi Santoso hari ini.',
        type: 'PAYABLE',
        urgency: NotificationUrgency.dueToday,
        debtId: 1,
        debt: mockDebt,
        contact: mockContact,
        dueDate: now,
        remainingAmount: 1500000,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeRemindersProvider.overrideWith((ref) => Future.value([item])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: NotificationSheet(),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Pusat Pengingat'), findsOneWidget);
      expect(find.text('Utang Jatuh Tempo Hari Ini'), findsOneWidget);
      expect(find.text('HARI INI'), findsOneWidget);
      expect(find.text('Bayar'), findsOneWidget);
    });
  });
}
