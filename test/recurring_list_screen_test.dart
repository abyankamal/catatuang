import 'package:catatuang/features/category/domain/category.dart';
import 'package:catatuang/features/dashboard/application/dashboard_providers.dart';
import 'package:catatuang/features/transaction/application/recurring_transaction_controller.dart';
import 'package:catatuang/features/transaction/data/recurring_transaction_repository.dart';
import 'package:catatuang/features/transaction/domain/recurring_transaction.dart';
import 'package:catatuang/features/transaction/presentation/recurring_transaction_list_screen.dart';
import 'package:catatuang/features/transaction/presentation/widgets/recurring_tile.dart';
import 'package:catatuang/features/wallet/domain/wallet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class FakeRecurringTransactionRepository implements RecurringTransactionRepository {
  final Map<String, RecurringTransaction> items = {};
  bool toggleActiveCalled = false;
  String? lastToggledSyncId;
  bool? lastToggledValue;

  bool hardDeleteCalled = false;
  String? lastDeletedSyncId;

  @override
  Stream<List<RecurringTransaction>> watchAllRecurring() {
    return Stream.value(items.values.toList());
  }

  @override
  Stream<List<RecurringTransaction>> watchActiveRecurring() {
    return Stream.value(items.values.where((r) => r.isActive).toList());
  }

  @override
  Future<bool> toggleActive(String syncId, bool isActive) async {
    toggleActiveCalled = true;
    lastToggledSyncId = syncId;
    lastToggledValue = isActive;
    final item = items[syncId];
    if (item != null) {
      item.isActive = isActive;
      return true;
    }
    return false;
  }

  @override
  Future<bool> hardDelete(String syncId) async {
    hardDeleteCalled = true;
    lastDeletedSyncId = syncId;
    final existed = items.remove(syncId);
    return existed != null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('id_ID', null);
  });

  group('RecurringTransactionListScreen Widget Tests (Task 4.2)', () {
    testWidgets('Renders empty states on both tabs when there are no recurring items', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recurringTransactionListStreamProvider.overrideWith((ref) => Stream.value([])),
            activeWalletsStreamProvider.overrideWith((ref) => Stream.value([])),
            activeCategoriesStreamProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(
            home: RecurringTransactionListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check header title and tab headers
      expect(find.text('Transaksi Terjadwal'), findsOneWidget);
      expect(find.text('Aktif'), findsOneWidget);
      expect(find.text('Dijeda & Selesai'), findsOneWidget);

      // Check empty state in tab Aktif
      expect(find.text('Tidak Ada Jadwal Aktif'), findsOneWidget);

      // Switch to tab 'Dijeda & Selesai'
      await tester.tap(find.text('Dijeda & Selesai'));
      await tester.pumpAndSettle();

      expect(find.text('Tidak Ada Jadwal Dijeda / Selesai'), findsOneWidget);
    });

    testWidgets('Renders active and inactive items on their respective tabs', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final activeItem = RecurringTransaction()
        ..id = 1
        ..syncId = 'rec_wifi'
        ..type = 'EXPENSE'
        ..amount = 350000
        ..walletSyncId = 'wallet_bca'
        ..categorySyncId = 'cat_internet'
        ..frequency = 'MONTHLY'
        ..interval = 1
        ..startDate = DateTime(2026, 1, 1)
        ..nextDueDate = DateTime(2026, 11, 1)
        ..description = 'Langganan Wi-Fi Rumah'
        ..autoExecute = true
        ..isActive = true
        ..createdAt = DateTime(2026, 1, 1)
        ..updatedAt = DateTime(2026, 1, 1);

      final pausedItem = RecurringTransaction()
        ..id = 2
        ..syncId = 'rec_gym'
        ..type = 'EXPENSE'
        ..amount = 250000
        ..walletSyncId = 'wallet_bca'
        ..frequency = 'MONTHLY'
        ..interval = 1
        ..startDate = DateTime(2026, 1, 1)
        ..nextDueDate = DateTime(2026, 11, 15)
        ..description = 'Member Gym'
        ..autoExecute = false
        ..isActive = false
        ..createdAt = DateTime(2026, 1, 1)
        ..updatedAt = DateTime(2026, 1, 1);

      final wallet = Wallet()
        ..id = 1
        ..syncId = 'wallet_bca'
        ..name = 'Bank BCA'
        ..balance = 5000000
        ..isActive = true
        ..isGoal = false;

      final category = Category()
        ..id = 1
        ..syncId = 'cat_internet'
        ..name = 'Tagihan Internet'
        ..type = 'EXPENSE'
        ..icon = 'wifi'
        ..colorValue = 0xFF2196F3
        ..isActive = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recurringTransactionListStreamProvider.overrideWith(
              (ref) => Stream.value([activeItem, pausedItem]),
            ),
            activeWalletsStreamProvider.overrideWith((ref) => Stream.value([wallet])),
            activeCategoriesStreamProvider.overrideWith((ref) => Stream.value([category])),
          ],
          child: const MaterialApp(
            home: RecurringTransactionListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // On 'Aktif' tab
      expect(find.text('Langganan Wi-Fi Rumah'), findsOneWidget);
      expect(find.text('Member Gym'), findsNothing);

      // Switch to 'Dijeda & Selesai' tab
      await tester.tap(find.text('Dijeda & Selesai'));
      await tester.pumpAndSettle();

      expect(find.text('Member Gym'), findsOneWidget);
      expect(find.text('Langganan Wi-Fi Rumah'), findsNothing);
    });

    testWidgets('Toggling active switch triggers controller toggleActive', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final activeItem = RecurringTransaction()
        ..id = 1
        ..syncId = 'rec_netflix'
        ..type = 'EXPENSE'
        ..amount = 186000
        ..walletSyncId = 'wallet_bca'
        ..frequency = 'MONTHLY'
        ..interval = 1
        ..startDate = DateTime(2026, 1, 1)
        ..nextDueDate = DateTime(2026, 11, 5)
        ..description = 'Langganan Netflix'
        ..autoExecute = false
        ..isActive = true
        ..createdAt = DateTime(2026, 1, 1)
        ..updatedAt = DateTime(2026, 1, 1);

      final fakeRepo = FakeRecurringTransactionRepository();
      fakeRepo.items[activeItem.syncId] = activeItem;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recurringTransactionRepositoryProvider.overrideWithValue(fakeRepo),
            recurringTransactionListStreamProvider.overrideWith(
              (ref) => Stream.value([activeItem]),
            ),
            activeWalletsStreamProvider.overrideWith((ref) => Stream.value([])),
            activeCategoriesStreamProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(
            home: RecurringTransactionListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);

      // Tap switch to pause schedule
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(fakeRepo.toggleActiveCalled, isTrue);
      expect(fakeRepo.lastToggledSyncId, 'rec_netflix');
      expect(fakeRepo.lastToggledValue, isFalse);
      expect(find.text('Jadwal transaksi berhasil dijeda.'), findsOneWidget);
    });

    testWidgets('Delete button displays confirmation dialog and calls hardDelete upon confirmation', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final activeItem = RecurringTransaction()
        ..id = 1
        ..syncId = 'rec_spotify'
        ..type = 'EXPENSE'
        ..amount = 54990
        ..walletSyncId = 'wallet_bca'
        ..frequency = 'MONTHLY'
        ..interval = 1
        ..startDate = DateTime(2026, 1, 1)
        ..nextDueDate = DateTime(2026, 11, 10)
        ..description = 'Spotify Premium'
        ..autoExecute = true
        ..isActive = true
        ..createdAt = DateTime(2026, 1, 1)
        ..updatedAt = DateTime(2026, 1, 1);

      final fakeRepo = FakeRecurringTransactionRepository();
      fakeRepo.items[activeItem.syncId] = activeItem;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recurringTransactionRepositoryProvider.overrideWithValue(fakeRepo),
            recurringTransactionListStreamProvider.overrideWith(
              (ref) => Stream.value([activeItem]),
            ),
            activeWalletsStreamProvider.overrideWith((ref) => Stream.value([])),
            activeCategoriesStreamProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(
            home: RecurringTransactionListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find delete icon button
      final deleteBtnFinder = find.byTooltip('Hapus Jadwal');
      expect(deleteBtnFinder, findsOneWidget);

      await tester.tap(deleteBtnFinder);
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.text('Hapus Jadwal?'), findsOneWidget);
      expect(find.text('Aturan jadwal ini akan dihapus secara permanen dari daftar. Riwayat transaksi sebelumnya yang sudah tercatat tidak akan terhapus. Lanjutkan?'), findsOneWidget);

      // Tap 'Batal' first to ensure it cancels
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(fakeRepo.hardDeleteCalled, isFalse);
      expect(find.text('Hapus Jadwal?'), findsNothing);

      // Tap delete again and confirm
      await tester.tap(deleteBtnFinder);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Hapus'));
      await tester.pumpAndSettle();

      expect(fakeRepo.hardDeleteCalled, isTrue);
      expect(fakeRepo.lastDeletedSyncId, 'rec_spotify');
      expect(find.text('Jadwal transaksi berhasil dihapus.'), findsOneWidget);
    });
  });
}
