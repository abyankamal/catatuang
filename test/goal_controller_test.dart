import 'package:catatuang/core/exceptions/locked_period_exception.dart';
import 'package:catatuang/features/goal/application/goal_providers.dart';
import 'package:catatuang/features/settings/data/app_settings_repository.dart';
import 'package:catatuang/features/settings/domain/app_settings.dart';
import 'package:catatuang/features/transaction/data/transaction_repository.dart';
import 'package:catatuang/features/wallet/data/wallet_repository.dart';
import 'package:catatuang/features/wallet/domain/wallet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MockWalletRepository implements WalletRepository {
  final List<Wallet> createdWallets = [];
  final Map<String, Wallet> walletsBySyncId = {};

  @override
  Future<Wallet> createGoal({
    required String name,
    required double targetAmount,
    DateTime? targetDate,
    double initialBalance = 0.0,
  }) async {
    final goal = Wallet()
      ..id = createdWallets.length + 100
      ..syncId = 'goal_${createdWallets.length + 1}'
      ..name = name
      ..balance = initialBalance
      ..targetAmount = targetAmount
      ..targetDate = targetDate
      ..isGoal = true
      ..isActive = true
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    createdWallets.add(goal);
    walletsBySyncId[goal.syncId] = goal;
    return goal;
  }

  @override
  Future<Wallet?> getWalletBySyncId(String syncId) async {
    return walletsBySyncId[syncId];
  }

  int? lastUpdatedId;
  String? lastUpdatedName;
  double? lastUpdatedTargetAmount;
  DateTime? lastUpdatedTargetDate;
  int? lastSoftDeletedId;

  @override
  Future<Wallet> updateGoal({
    required int id,
    required String name,
    required double targetAmount,
    DateTime? targetDate,
  }) async {
    lastUpdatedId = id;
    lastUpdatedName = name;
    lastUpdatedTargetAmount = targetAmount;
    lastUpdatedTargetDate = targetDate;
    final w = createdWallets.firstWhere((element) => element.id == id);
    w.name = name;
    w.targetAmount = targetAmount;
    w.targetDate = targetDate;
    return w;
  }

  @override
  Future<void> softDeleteWallet(int id) async {
    lastSoftDeletedId = id;
    final w = createdWallets.firstWhere((element) => element.id == id);
    w.isActive = false;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockTransactionRepository implements TransactionRepository {
  bool allocateSavingsCalled = false;
  String? lastSourceSyncId;
  String? lastGoalSyncId;
  double? lastAmount;

  bool withdrawSavingsCalled = false;
  String? lastWithdrawGoalSyncId;
  String? lastWithdrawDestSyncId;
  double? lastWithdrawAmount;
  String? lastWithdrawNotes;

  bool shouldThrowOnAllocate = false;
  bool shouldThrowOnWithdraw = false;

  @override
  Future<void> allocateSavings({
    required String sourceWalletSyncId,
    required String goalWalletSyncId,
    required double amount,
    required DateTime date,
  }) async {
    if (shouldThrowOnAllocate) {
      throw Exception('Gagal alokasi tabungan pada repositori');
    }
    allocateSavingsCalled = true;
    lastSourceSyncId = sourceWalletSyncId;
    lastGoalSyncId = goalWalletSyncId;
    lastAmount = amount;
  }

  @override
  Future<void> withdrawSavings({
    required String goalWalletSyncId,
    required String destinationWalletSyncId,
    required double amount,
    required DateTime date,
    String? notes,
  }) async {
    if (shouldThrowOnWithdraw) {
      throw Exception('Gagal pencairan tabungan pada repositori');
    }
    withdrawSavingsCalled = true;
    lastWithdrawGoalSyncId = goalWalletSyncId;
    lastWithdrawDestSyncId = destinationWalletSyncId;
    lastWithdrawAmount = amount;
    lastWithdrawNotes = notes;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAppSettingsRepository implements AppSettingsRepository {
  AppSettings settings;

  MockAppSettingsRepository(this.settings);

  @override
  Future<AppSettings> getOrInitSettings() async {
    return settings;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockWalletRepository walletRepo;
  late MockTransactionRepository txRepo;
  late MockAppSettingsRepository settingsRepo;
  late AppSettings defaultSettings;
  late GoalController controller;

  setUp(() {
    walletRepo = MockWalletRepository();
    txRepo = MockTransactionRepository();
    defaultSettings = AppSettings()
      ..id = 1
      ..syncId = 'settings_1'
      ..lockedUntil = null;
    settingsRepo = MockAppSettingsRepository(defaultSettings);
    controller = GoalController(walletRepo, txRepo, settingsRepo);
  });

  group('GoalController.addGoal Strict Pre-Validation Tests (Task 1.3)', () {
    test('Successful creation without initial balance creates goal and does not call allocateSavings', () async {
      await controller.addGoal(
        name: 'Dana Darurat',
        targetAmount: 10000000,
        initialBalance: 0,
      );

      expect(walletRepo.createdWallets.length, 1);
      expect(walletRepo.createdWallets.first.name, 'Dana Darurat');
      expect(txRepo.allocateSavingsCalled, isFalse);
    });

    test('Successful creation with valid initial balance creates goal and executes allocateSavings', () async {
      final sourceWallet = Wallet()
        ..id = 1
        ..syncId = 'wallet_bca'
        ..name = 'Bank BCA'
        ..balance = 2000000
        ..isActive = true
        ..isGoal = false;
      walletRepo.walletsBySyncId['wallet_bca'] = sourceWallet;

      await controller.addGoal(
        name: 'Beli Laptop',
        targetAmount: 15000000,
        initialBalance: 500000,
        sourceWalletSyncId: 'wallet_bca',
      );

      expect(walletRepo.createdWallets.length, 1);
      expect(walletRepo.createdWallets.first.name, 'Beli Laptop');
      expect(txRepo.allocateSavingsCalled, isTrue);
      expect(txRepo.lastSourceSyncId, 'wallet_bca');
      expect(txRepo.lastGoalSyncId, walletRepo.createdWallets.first.syncId);
      expect(txRepo.lastAmount, 500000);
    });

    test('Throws Exception and DOES NOT create goal if sourceWalletSyncId is missing with initialBalance > 0', () async {
      expect(
        () => controller.addGoal(
          name: 'Liburan',
          targetAmount: 5000000,
          initialBalance: 200000,
          sourceWalletSyncId: null,
        ),
        throwsA(isA<Exception>()),
      );

      // Pastikan tidak ada orphan goal yang dibuat di repository
      expect(walletRepo.createdWallets, isEmpty);
      expect(txRepo.allocateSavingsCalled, isFalse);
    });

    test('Throws Exception and DOES NOT create goal if source wallet is not found', () async {
      expect(
        () => controller.addGoal(
          name: 'Liburan',
          targetAmount: 5000000,
          initialBalance: 200000,
          sourceWalletSyncId: 'non_existent_wallet',
        ),
        throwsA(
          predicate((e) => e is Exception && e.toString().contains('tidak ditemukan atau tidak aktif')),
        ),
      );

      expect(walletRepo.createdWallets, isEmpty);
      expect(txRepo.allocateSavingsCalled, isFalse);
    });

    test('Throws Exception and DOES NOT create goal if source wallet is soft-deleted (isActive == false)', () async {
      final archivedWallet = Wallet()
        ..id = 2
        ..syncId = 'wallet_archived'
        ..name = 'Dompet Lama'
        ..balance = 1000000
        ..isActive = false
        ..isGoal = false;
      walletRepo.walletsBySyncId['wallet_archived'] = archivedWallet;

      expect(
        () => controller.addGoal(
          name: 'Renovasi Rumah',
          targetAmount: 20000000,
          initialBalance: 500000,
          sourceWalletSyncId: 'wallet_archived',
        ),
        throwsA(
          predicate((e) => e is Exception && e.toString().contains('tidak ditemukan atau tidak aktif')),
        ),
      );

      expect(walletRepo.createdWallets, isEmpty);
      expect(txRepo.allocateSavingsCalled, isFalse);
    });

    test('Throws Exception and DOES NOT create goal if source wallet is a goal wallet (isGoal == true)', () async {
      final goalSource = Wallet()
        ..id = 3
        ..syncId = 'goal_source'
        ..name = 'Tabungan Emas'
        ..balance = 3000000
        ..isActive = true
        ..isGoal = true;
      walletRepo.walletsBySyncId['goal_source'] = goalSource;

      expect(
        () => controller.addGoal(
          name: 'Gadget Baru',
          targetAmount: 10000000,
          initialBalance: 500000,
          sourceWalletSyncId: 'goal_source',
        ),
        throwsA(
          predicate((e) => e is Exception && e.toString().contains('tidak boleh berupa kantong tabungan impian')),
        ),
      );

      expect(walletRepo.createdWallets, isEmpty);
      expect(txRepo.allocateSavingsCalled, isFalse);
    });

    test('Throws Exception and DOES NOT create goal if source wallet balance is insufficient', () async {
      final brokeWallet = Wallet()
        ..id = 4
        ..syncId = 'wallet_broke'
        ..name = 'Dompet Tipis'
        ..balance = 50000
        ..isActive = true
        ..isGoal = false;
      walletRepo.walletsBySyncId['wallet_broke'] = brokeWallet;

      expect(
        () => controller.addGoal(
          name: 'Mobil Baru',
          targetAmount: 100000000,
          initialBalance: 500000, // Butuh 500k, saldo cuma 50k
          sourceWalletSyncId: 'wallet_broke',
        ),
        throwsA(
          predicate((e) => e is Exception && e.toString().contains('tidak mencukupi untuk saldo awal tabungan')),
        ),
      );

      expect(walletRepo.createdWallets, isEmpty);
      expect(txRepo.allocateSavingsCalled, isFalse);
    });

    test('Throws LockedPeriodException and DOES NOT create goal if current date is within locked period', () async {
      final validWallet = Wallet()
        ..id = 5
        ..syncId = 'wallet_valid'
        ..name = 'Dompet Cukup'
        ..balance = 1000000
        ..isActive = true
        ..isGoal = false;
      walletRepo.walletsBySyncId['wallet_valid'] = validWallet;

      // Kunci periode hingga masa depan
      defaultSettings.lockedUntil = DateTime.now().add(const Duration(days: 1));

      expect(
        () => controller.addGoal(
          name: 'Kurban',
          targetAmount: 3000000,
          initialBalance: 250000,
          sourceWalletSyncId: 'wallet_valid',
        ),
        throwsA(isA<LockedPeriodException>()),
      );

      // Benar-benar tidak ada record wallet goal baru yang dibuat di Isar
      expect(walletRepo.createdWallets, isEmpty);
      expect(txRepo.allocateSavingsCalled, isFalse);
    });
  });

  group('GoalController Operations & State Tests (Task 4.1)', () {
    test('topUpGoal sets loading and data(null) state and returns true on success', () async {
      final states = <AsyncValue<void>>[];
      controller.addListener((state) => states.add(state));

      final success = await controller.topUpGoal(
        goalWalletSyncId: 'goal_1',
        sourceWalletSyncId: 'wallet_source',
        amount: 250000,
        date: DateTime(2026, 10, 25),
      );

      expect(success, isTrue);
      expect(txRepo.allocateSavingsCalled, isTrue);
      expect(txRepo.lastGoalSyncId, 'goal_1');
      expect(txRepo.lastSourceSyncId, 'wallet_source');
      expect(txRepo.lastAmount, 250000);
      expect(controller.state, const AsyncValue<void>.data(null));
      expect(states.any((s) => s is AsyncLoading), isTrue);
    });

    test('topUpGoal catches error, sets state to error, and returns false on failure', () async {
      txRepo.shouldThrowOnAllocate = true;

      final success = await controller.topUpGoal(
        goalWalletSyncId: 'goal_1',
        sourceWalletSyncId: 'wallet_source',
        amount: 100000,
        date: DateTime(2026, 10, 25),
      );

      expect(success, isFalse);
      expect(controller.state.hasError, isTrue);
      expect(controller.state.error.toString(), contains('Gagal alokasi tabungan'));
    });

    test('withdrawGoal executes withdrawSavings and returns true on success', () async {
      final success = await controller.withdrawGoal(
        goalWalletSyncId: 'goal_laptop',
        destinationWalletSyncId: 'wallet_bca',
        amount: 5000000,
        date: DateTime(2026, 10, 26),
        notes: 'Pencairan beli laptop baru',
      );

      expect(success, isTrue);
      expect(txRepo.withdrawSavingsCalled, isTrue);
      expect(txRepo.lastWithdrawGoalSyncId, 'goal_laptop');
      expect(txRepo.lastWithdrawDestSyncId, 'wallet_bca');
      expect(txRepo.lastWithdrawAmount, 5000000);
      expect(txRepo.lastWithdrawNotes, 'Pencairan beli laptop baru');
      expect(controller.state, const AsyncValue<void>.data(null));
    });

    test('withdrawGoal returns false and sets state to error on failure', () async {
      txRepo.shouldThrowOnWithdraw = true;

      final success = await controller.withdrawGoal(
        goalWalletSyncId: 'goal_laptop',
        destinationWalletSyncId: 'wallet_bca',
        amount: 5000000,
        date: DateTime(2026, 10, 26),
      );

      expect(success, isFalse);
      expect(controller.state.hasError, isTrue);
      expect(controller.state.error.toString(), contains('Gagal pencairan tabungan'));
    });

    test('updateGoal updates target and returns true on success', () async {
      await controller.addGoal(
        name: 'Target Lama',
        targetAmount: 5000000,
      );
      final created = walletRepo.createdWallets.first;

      final success = await controller.updateGoal(
        id: created.id,
        name: 'Target Diperbarui',
        targetAmount: 8000000,
        targetDate: DateTime(2026, 12, 31),
      );

      expect(success, isTrue);
      expect(walletRepo.lastUpdatedId, created.id);
      expect(walletRepo.lastUpdatedName, 'Target Diperbarui');
      expect(walletRepo.lastUpdatedTargetAmount, 8000000);
      expect(created.name, 'Target Diperbarui');
      expect(controller.state, const AsyncValue<void>.data(null));
    });

    test('deleteGoal throws and returns false if goal still has positive balance', () async {
      await controller.addGoal(
        name: 'Goal Bersaldo',
        targetAmount: 2000000,
      );
      final created = walletRepo.createdWallets.first;
      created.balance = 150000; // Masih ada saldo

      final success = await controller.deleteGoal(created);

      expect(success, isFalse);
      expect(created.isActive, isTrue); // Tidak di-soft delete
      expect(controller.state.hasError, isTrue);
      expect(controller.state.error.toString(), contains('Tidak dapat menghapus tabungan yang masih memiliki saldo'));
    });

    test('deleteGoal succeeds and soft-deletes wallet if balance is 0', () async {
      await controller.addGoal(
        name: 'Goal Kosong',
        targetAmount: 1000000,
      );
      final created = walletRepo.createdWallets.first;
      created.balance = 0.0; // Saldo 0

      final success = await controller.deleteGoal(created);

      expect(success, isTrue);
      expect(walletRepo.lastSoftDeletedId, created.id);
      expect(created.isActive, isFalse);
      expect(controller.state, const AsyncValue<void>.data(null));
    });
  });
}
