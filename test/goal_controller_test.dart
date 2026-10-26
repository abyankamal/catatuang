import 'package:catatuang/core/exceptions/locked_period_exception.dart';
import 'package:catatuang/features/goal/application/goal_providers.dart';
import 'package:catatuang/features/settings/data/app_settings_repository.dart';
import 'package:catatuang/features/settings/domain/app_settings.dart';
import 'package:catatuang/features/transaction/data/transaction_repository.dart';
import 'package:catatuang/features/wallet/data/wallet_repository.dart';
import 'package:catatuang/features/wallet/domain/wallet.dart';
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

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockTransactionRepository implements TransactionRepository {
  bool allocateSavingsCalled = false;
  String? lastSourceSyncId;
  String? lastGoalSyncId;
  double? lastAmount;

  @override
  Future<void> allocateSavings({
    required String sourceWalletSyncId,
    required String goalWalletSyncId,
    required double amount,
    required DateTime date,
  }) async {
    allocateSavingsCalled = true;
    lastSourceSyncId = sourceWalletSyncId;
    lastGoalSyncId = goalWalletSyncId;
    lastAmount = amount;
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
}
