import 'dart:ffi';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import 'package:catatuang/main.dart';
import 'package:catatuang/core/database/database_provider.dart';
import 'package:catatuang/features/wallet/domain/wallet.dart';
import 'package:catatuang/features/category/domain/category.dart';
import 'package:catatuang/features/contact/domain/contact.dart';
import 'package:catatuang/features/debt/domain/debt.dart';
import 'package:catatuang/features/transaction/domain/transaction.dart';
import 'package:catatuang/features/settings/domain/app_settings.dart';
import 'package:catatuang/features/wallet/data/wallet_repository.dart';
import 'package:catatuang/features/dashboard/application/dashboard_providers.dart';
import 'package:catatuang/features/dashboard/presentation/dashboard_screen.dart';
import 'package:catatuang/features/goal/presentation/goal_list_screen.dart';
import 'package:catatuang/core/theme/app_theme.dart';

void main() {
  late Isar isar;
  late Directory tempDir;

  setUpAll(() async {
    await Isar.initializeIsarCore(
      libraries: {
        Abi.macosArm64: '/Users/muhammadabyankamal/.pub-cache/hosted/pub.dev/isar_flutter_libs-3.1.0+1/macos/libisar.dylib',
        Abi.macosX64: '/Users/muhammadabyankamal/.pub-cache/hosted/pub.dev/isar_flutter_libs-3.1.0+1/macos/libisar.dylib',
      },
    );
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('isar_test_');
    isar = await Isar.open(
      [
        WalletSchema,
        CategorySchema,
        ContactSchema,
        DebtSchema,
        TransactionSchema,
        AppSettingsSchema,
      ],
      directory: tempDir.path,
    );
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('dashboardSummaryProvider calculates correctly without timeout', () async {
    final container = ProviderContainer(
      overrides: [
        isarProvider.overrideWithValue(isar),
      ],
    );

    final walletRepo = container.read(walletRepositoryProvider);
    await walletRepo.seedDefaultWalletIfEmpty();

    final summary = await container.read(dashboardSummaryProvider.future);
    expect(summary.totalBalance, equals(0.0));
    expect(summary.monthlyIncome, equals(0.0));
    expect(summary.monthlyExpense, equals(0.0));
  });

  testWidgets('DashboardScreen renders without crashing', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isarProvider.overrideWithValue(isar),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const DashboardScreen(),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('Catat Uang'), findsOneWidget);
  });

  testWidgets('GoalListScreen renders without crashing', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isarProvider.overrideWithValue(isar),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const GoalListScreen(),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('Tujuan Tabungan'), findsOneWidget);
  });

  testWidgets('Pump full app and verify UI elements', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isarProvider.overrideWithValue(isar),
        ],
        child: const CatatUangApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Catat Uang'), findsOneWidget);
    expect(find.text('Total Saldo'), findsOneWidget);
  });
}
