import 'package:catatuang/features/contact/application/contact_providers.dart';
import 'package:catatuang/features/contact/domain/contact.dart';
import 'package:catatuang/features/contact/presentation/contact_list_screen.dart';
import 'package:catatuang/features/debt/application/debt_providers.dart';
import 'package:catatuang/features/debt/domain/debt.dart';
import 'package:catatuang/features/debt/presentation/debt_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('id_ID', null);
  });

  group('Debt & Contact Tests', () {
    test('DebtSummary computation logic', () {
      const summary = DebtSummary(
        totalPayable: 1000000,
        paidPayable: 250000,
        remainingPayable: 750000,
        totalReceivable: 500000,
        paidReceivable: 500000,
        remainingReceivable: 0,
        overdueCount: 1,
      );

      expect(summary.totalPayable, 1000000);
      expect(summary.remainingPayable, 750000);
      expect(summary.remainingReceivable, 0);
      expect(summary.overdueCount, 1);
    });

    testWidgets('DebtListScreen renders empty state properly', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeDebtsStreamProvider.overrideWith((ref) => Stream.value([])),
            debtSummaryProvider.overrideWith((ref) => Future.value(const DebtSummary.empty())),
            activeContactsStreamProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(
            home: DebtListScreen(),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Utang & Piutang'), findsOneWidget);
      expect(find.text('Semua Status'), findsOneWidget);
      expect(find.text('Tidak Ada Catatan'), findsOneWidget);
    });

    testWidgets('ContactListScreen renders empty state properly', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeContactsStreamProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(
            home: ContactListScreen(),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Buku Kontak'), findsOneWidget);
      expect(find.text('Belum Ada Kontak'), findsOneWidget);
    });

    testWidgets('DebtListScreen renders debt cards with data', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockContact = Contact()
        ..syncId = 'contact_1'
        ..name = 'Budi Santoso'
        ..phoneNumber = '08123456789'
        ..isActive = true
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      final mockDebt = Debt()
        ..id = 1
        ..syncId = 'debt_1'
        ..type = 'PAYABLE'
        ..contactSyncId = 'contact_1'
        ..title = 'Pinjaman Modal Usaha'
        ..totalAmount = 1000000
        ..paidAmount = 250000
        ..startDate = DateTime.now()
        ..dueDate = DateTime.now().add(const Duration(days: 14))
        ..isActive = true
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeDebtsStreamProvider.overrideWith((ref) => Stream.value([mockDebt])),
            debtSummaryProvider.overrideWith(
              (ref) => Future.value(
                const DebtSummary(
                  totalPayable: 1000000,
                  paidPayable: 250000,
                  remainingPayable: 750000,
                  totalReceivable: 0,
                  paidReceivable: 0,
                  remainingReceivable: 0,
                  overdueCount: 0,
                ),
              ),
            ),
            activeContactsStreamProvider.overrideWith((ref) => Stream.value([mockContact])),
          ],
          child: const MaterialApp(
            home: DebtListScreen(),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Pinjaman Modal Usaha'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Utang Saya'), findsNWidgets(2)); // in Tab & on card
      expect(find.text('Bayar / Cicil Utang'), findsOneWidget);
    });
  });
}
