import 'package:catatuang/features/category/data/category_repository.dart';
import 'package:catatuang/features/category/domain/category.dart';
import 'package:catatuang/features/onboarding/presentation/onboarding_screen.dart';
import 'package:catatuang/features/settings/data/app_settings_repository.dart';
import 'package:catatuang/features/settings/domain/app_settings.dart';
import 'package:catatuang/features/wallet/data/wallet_repository.dart';
import 'package:catatuang/features/wallet/domain/wallet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

// Fake Repositories for testing
class FakeAppSettingsRepository implements AppSettingsRepository {
  AppSettings settings = AppSettings()
    ..id = 1
    ..syncId = 'settings_1'
    ..hasCompletedOnboarding = false
    ..createdAt = DateTime.now()
    ..updatedAt = DateTime.now();

  @override
  Stream<AppSettings?> watchSettings() {
    return Stream.value(settings);
  }

  @override
  Future<AppSettings> getOrInitSettings() async => settings;

  @override
  Future<void> updateProfile({required String userName, String? avatarIcon}) async {
    settings.userName = userName;
    settings.avatarIcon = avatarIcon;
  }

  @override
  Future<void> completeOnboarding({required String userName, String? avatarIcon}) async {
    settings.userName = userName;
    settings.avatarIcon = avatarIcon;
    settings.hasCompletedOnboarding = true;
  }

  @override
  Future<void> updateLockedUntil(DateTime? lockedUntil) async {
    settings.lockedUntil = lockedUntil;
  }

  @override
  Future<void> updatePrivacyScreen(bool isEnabled) async {
    settings.isPrivacyScreenEnabled = isEnabled;
  }

  @override
  Future<void> clearAllData() async {}
}

class FakeWalletRepository implements WalletRepository {
  final List<Wallet> wallets = [];

  @override
  Future<Wallet> createWallet({required String name, double initialBalance = 0.0}) async {
    final w = Wallet()
      ..id = wallets.length + 1
      ..syncId = 'wallet_${wallets.length + 1}'
      ..name = name
      ..balance = initialBalance
      ..isGoal = false
      ..isActive = true
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();
    wallets.add(w);
    return w;
  }

  @override
  Future<List<Wallet>> getActiveWallets() async => wallets;

  @override
  Stream<List<Wallet>> watchActiveWallets() => Stream.value(wallets);

  @override
  Stream<List<Wallet>> watchActiveRegularWallets() =>
      Stream.value(wallets.where((w) => !w.isGoal).toList());

  @override
  Stream<List<Wallet>> watchActiveGoals() =>
      Stream.value(wallets.where((w) => w.isGoal).toList());

  @override
  Future<Wallet> createGoal({
    required String name,
    required double targetAmount,
    DateTime? targetDate,
    double initialBalance = 0.0,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Wallet> updateGoal({
    required int id,
    required String name,
    required double targetAmount,
    DateTime? targetDate,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Wallet> updateWallet({required int id, required String name}) async {
    throw UnimplementedError();
  }

  @override
  Future<void> softDeleteWallet(int id) async {}
}

class FakeCategoryRepository implements CategoryRepository {
  final List<Category> categories = [
    Category()
      ..id = 1
      ..syncId = 'cat_1'
      ..name = 'Makanan & Minuman'
      ..type = 'EXPENSE'
      ..icon = 'restaurant'
      ..colorValue = 0xFFFF5722
      ..isActive = true
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now(),
    Category()
      ..id = 2
      ..syncId = 'cat_2'
      ..name = 'Gaji'
      ..type = 'INCOME'
      ..icon = 'payments'
      ..colorValue = 0xFF4CAF50
      ..isActive = true
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now(),
  ];

  @override
  Future<void> seedDefaultCategoriesIfEmpty() async {}

  @override
  Future<List<Category>> getActiveCategories() async => categories;

  @override
  Stream<List<Category>> watchActiveCategories() => Stream.value(categories);

  @override
  Future<Category> createCategory({
    required String name,
    required String type,
    String icon = 'category',
    int colorValue = 0xFF5D5CFF,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Category> updateCategory({
    required int id,
    required String name,
    required String type,
    String? icon,
    int? colorValue,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> softDeleteCategory(int id) async {}
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('id_ID', null);
  });

  group('Onboarding Flow Tests', () {
    testWidgets('OnboardingScreen renders step 1 (Welcome & Profile input)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeSettingsRepo = FakeAppSettingsRepository();
      final fakeWalletRepo = FakeWalletRepository();
      final fakeCategoryRepo = FakeCategoryRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appSettingsRepositoryProvider.overrideWithValue(fakeSettingsRepo),
            walletRepositoryProvider.overrideWithValue(fakeWalletRepo),
            categoryRepositoryProvider.overrideWithValue(fakeCategoryRepo),
          ],
          child: const MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Selamat Datang di CatatUang!'), findsOneWidget);
      expect(find.text('Nama Panggilan Anda'), findsOneWidget);
      expect(find.text('Lanjut'), findsOneWidget);
    });

    testWidgets('Onboarding full flow completes properly and creates wallet and settings', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeSettingsRepo = FakeAppSettingsRepository();
      final fakeWalletRepo = FakeWalletRepository();
      final fakeCategoryRepo = FakeCategoryRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appSettingsRepositoryProvider.overrideWithValue(fakeSettingsRepo),
            walletRepositoryProvider.overrideWithValue(fakeWalletRepo),
            categoryRepositoryProvider.overrideWithValue(fakeCategoryRepo),
          ],
          child: const MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Step 1: Input nama dan tekan Lanjut
      await tester.enterText(find.byType(TextFormField), 'Abyan');
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();

      // Step 2: Buat Dompet Pertama
      expect(find.text('Buat Dompet Pertama Anda'), findsOneWidget);
      expect(find.text('Nama Dompet'), findsOneWidget);
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();

      // Step 3: Kategori
      expect(find.text('Kategori Transaksi'), findsOneWidget);
      expect(find.text('Mulai Sekarang'), findsOneWidget);
      await tester.tap(find.text('Mulai Sekarang'));
      await tester.pumpAndSettle();

      // Verifikasi data
      expect(fakeSettingsRepo.settings.hasCompletedOnboarding, isTrue);
      expect(fakeSettingsRepo.settings.userName, 'Abyan');
      expect(fakeWalletRepo.wallets.length, 1);
      expect(fakeWalletRepo.wallets.first.name, 'Dompet Utama');
    });
  });
}
