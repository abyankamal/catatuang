import 'package:catatuang/features/category/domain/category.dart';
import 'package:catatuang/features/transaction/application/recurring_transaction_controller.dart';
import 'package:catatuang/features/transaction/domain/recurring_transaction.dart';
import 'package:catatuang/features/transaction/presentation/recurring_transaction_list_screen.dart';
import 'package:catatuang/features/transaction/presentation/widgets/recurring_tile.dart';
import 'package:catatuang/features/dashboard/application/dashboard_providers.dart';
import 'package:catatuang/features/wallet/domain/wallet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class MockRecurringTransactionController
    extends StateNotifier<AsyncValue<void>>
    implements RecurringTransactionController {
  String? toggledSyncId;
  bool? toggledValue;
  String? hardDeletedSyncId;

  MockRecurringTransactionController() : super(const AsyncValue.data(null));

  @override
  bool get isProcessingAutoRecurring => false;

  @override
  Future<bool> toggleActive(String syncId, bool isActive) async {
    toggledSyncId = syncId;
    toggledValue = isActive;
    return true;
  }

  @override
  Future<bool> hardDelete(String syncId) async {
    hardDeletedSyncId = syncId;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('id_ID', null);
  });

  Widget buildTestWidget({
    required List<RecurringTransaction> items,
    MockRecurringTransactionController? controller,
    List<Wallet>? wallets,
    List<Category>? categories,
  }) {
    final mockCtrl = controller ?? MockRecurringTransactionController();
    final testWallets = wallets ??
        [
          Wallet()
            ..syncId = 'wallet_bca'
            ..name = 'BCA Utama'
            ..balance = 1000000
            ..isActive = true
            ..createdAt = DateTime.now()
            ..updatedAt = DateTime.now(),
        ];
    final testCategories = categories ??
        [
          Category()
            ..syncId = 'cat_internet'
            ..name = 'Internet & Wi-Fi'
            ..type = 'EXPENSE'
            ..isActive = true
            ..createdAt = DateTime.now()
            ..updatedAt = DateTime.now(),
        ];

    return ProviderScope(
      overrides: [
        recurringTransactionListStreamProvider
            .overrideWith((ref) => Stream.value(items)),
        activeWalletsStreamProvider
            .overrideWith((ref) => Stream.value(testWallets)),
        activeCategoriesStreamProvider
            .overrideWith((ref) => Stream.value(testCategories)),
        recurringTransactionControllerProvider
            .overrideWith((ref) => mockCtrl),
      ],
      child: const MaterialApp(
        home: RecurringTransactionListScreen(),
      ),
    );
  }

  group('RecurringTransactionListScreen Widget Tests', () {
    testWidgets('renders empty state in Aktif tab when no active items exist',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(items: []));
      await tester.pumpAndSettle();

      expect(find.text('Transaksi Terjadwal'), findsOneWidget);
      expect(find.text('Tidak Ada Jadwal Aktif'), findsOneWidget);
      expect(find.text('Jadwal Baru'), findsOneWidget);
    });

    testWidgets('renders active item in Aktif tab with proper badges and amount',
        (tester) async {
      final activeItem = RecurringTransaction()
        ..syncId = 'rec_wifi'
        ..type = 'EXPENSE'
        ..amount = 350000
        ..description = 'Tagihan IndiHome'
        ..walletSyncId = 'wallet_bca'
        ..categorySyncId = 'cat_internet'
        ..frequency = 'MONTHLY'
        ..interval = 1
        ..startDate = DateTime(2026, 1, 1)
        ..nextDueDate = DateTime(2026, 11, 1)
        ..autoExecute = true
        ..isActive = true
        ..occurrenceCount = 0
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      await tester.pumpWidget(buildTestWidget(items: [activeItem]));
      await tester.pumpAndSettle();

      expect(find.text('Tagihan IndiHome'), findsOneWidget);
      expect(find.text('Rp 350.000'), findsOneWidget);
      expect(find.text('Pengeluaran'), findsOneWidget);
      expect(find.text('Setiap Bulan'), findsOneWidget);
      expect(find.text('Otomatis'), findsOneWidget);
      expect(find.text('Aktif'), findsAtLeastNWidgets(1));
      expect(find.textContaining('BCA Utama • Internet & Wi-Fi'), findsOneWidget);
      expect(find.byType(RecurringTile), findsOneWidget);
    });

    testWidgets('renders paused and completed items in Dijeda & Selesai tab',
        (tester) async {
      final pausedItem = RecurringTransaction()
        ..syncId = 'rec_gym'
        ..type = 'EXPENSE'
        ..amount = 200000
        ..description = 'Langganan Gym'
        ..walletSyncId = 'wallet_bca'
        ..frequency = 'MONTHLY'
        ..interval = 1
        ..startDate = DateTime(2026, 1, 1)
        ..nextDueDate = DateTime(2026, 11, 1)
        ..autoExecute = false
        ..isActive = false // Paused
        ..occurrenceCount = 0
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      final completedItem = RecurringTransaction()
        ..syncId = 'rec_cicilan'
        ..type = 'EXPENSE'
        ..amount = 500000
        ..description = 'Cicilan Laptop'
        ..walletSyncId = 'wallet_bca'
        ..frequency = 'MONTHLY'
        ..interval = 1
        ..startDate = DateTime(2026, 1, 1)
        ..nextDueDate = DateTime(2026, 11, 1)
        ..maxOccurrences = 3
        ..occurrenceCount = 3 // Completed
        ..autoExecute = true
        ..isActive = false
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      await tester.pumpWidget(
          buildTestWidget(items: [pausedItem, completedItem]));
      await tester.pumpAndSettle();

      // Aktif tab should show empty state
      expect(find.text('Tidak Ada Jadwal Aktif'), findsOneWidget);

      // Tap tab "Dijeda & Selesai"
      await tester.tap(find.text('Dijeda & Selesai'));
      await tester.pumpAndSettle();

      expect(find.text('Langganan Gym'), findsOneWidget);
      expect(find.text('Cicilan Laptop'), findsOneWidget);
      expect(find.text('Dijeda'), findsOneWidget);
      expect(find.text('Selesai'), findsOneWidget);
    });

    testWidgets('toggling switch calls controller.toggleActive',
        (tester) async {
      final controller = MockRecurringTransactionController();
      final activeItem = RecurringTransaction()
        ..syncId = 'rec_toggle_test'
        ..type = 'EXPENSE'
        ..amount = 150000
        ..description = 'Netflix'
        ..walletSyncId = 'wallet_bca'
        ..frequency = 'MONTHLY'
        ..interval = 1
        ..startDate = DateTime(2026, 1, 1)
        ..nextDueDate = DateTime(2026, 11, 1)
        ..autoExecute = false
        ..isActive = true
        ..occurrenceCount = 0
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      await tester.pumpWidget(buildTestWidget(
        items: [activeItem],
        controller: controller,
      ));
      await tester.pumpAndSettle();

      // Find switch inside RecurringTile
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);

      // Tap to toggle off
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(controller.toggledSyncId, equals('rec_toggle_test'));
      expect(controller.toggledValue, isFalse);
      expect(find.text('Jadwal transaksi berhasil dijeda.'), findsOneWidget);
    });

    testWidgets('tapping delete button shows confirmation dialog and calls hardDelete',
        (tester) async {
      final controller = MockRecurringTransactionController();
      final activeItem = RecurringTransaction()
        ..syncId = 'rec_delete_test'
        ..type = 'EXPENSE'
        ..amount = 75000
        ..description = 'Spotify Premium'
        ..walletSyncId = 'wallet_bca'
        ..frequency = 'MONTHLY'
        ..interval = 1
        ..startDate = DateTime(2026, 1, 1)
        ..nextDueDate = DateTime(2026, 11, 1)
        ..autoExecute = false
        ..isActive = true
        ..occurrenceCount = 0
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      await tester.pumpWidget(buildTestWidget(
        items: [activeItem],
        controller: controller,
      ));
      await tester.pumpAndSettle();

      // Tap delete button
      final deleteBtnFinder = find.byTooltip('Hapus Jadwal');
      expect(deleteBtnFinder, findsOneWidget);
      await tester.tap(deleteBtnFinder);
      await tester.pumpAndSettle();

      // Dialog should be visible
      expect(find.text('Hapus Jadwal?'), findsOneWidget);
      expect(find.textContaining('Riwayat transaksi sebelumnya yang sudah tercatat tidak akan terhapus'), findsOneWidget);

      // Tap "Hapus" inside dialog
      await tester.tap(find.widgetWithText(ElevatedButton, 'Hapus'));
      await tester.pumpAndSettle();

      expect(controller.hardDeletedSyncId, equals('rec_delete_test'));
      expect(find.text('Jadwal transaksi berhasil dihapus.'), findsOneWidget);
    });
  });
}
