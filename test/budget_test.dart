import 'package:catatuang/features/budget/application/budget_providers.dart';
import 'package:catatuang/features/budget/data/budget_repository.dart';
import 'package:catatuang/features/budget/domain/budget.dart';
import 'package:catatuang/features/budget/presentation/budget_list_screen.dart';
import 'package:catatuang/features/category/application/category_providers.dart';
import 'package:catatuang/features/category/domain/category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('id_ID', null);
  });

  group('Budgeting (Anggaran) Unit & Widget Tests', () {
    test('BudgetStatus calculation and threshold logic', () {
      // 1. Safe status (< 75%)
      const safeSummary = MonthlyBudgetSummary(
        year: 2026,
        month: 8,
        totalBudgetLimit: 1000000,
        totalBudgetSpent: 500000,
        totalBudgetRemaining: 500000,
        totalPercentage: 50.0,
        overallStatus: BudgetStatus.safe,
        items: [],
      );
      expect(safeSummary.overallStatus, BudgetStatus.safe);
      expect(safeSummary.totalBudgetRemaining, 500000);

      // 2. Warning status (>= 75% & < 100%)
      const warningSummary = MonthlyBudgetSummary(
        year: 2026,
        month: 8,
        totalBudgetLimit: 1000000,
        totalBudgetSpent: 850000,
        totalBudgetRemaining: 150000,
        totalPercentage: 85.0,
        overallStatus: BudgetStatus.warning,
        items: [],
      );
      expect(warningSummary.overallStatus, BudgetStatus.warning);

      // 3. Overbudget status (>= 100%)
      const overSummary = MonthlyBudgetSummary(
        year: 2026,
        month: 8,
        totalBudgetLimit: 1000000,
        totalBudgetSpent: 1200000,
        totalBudgetRemaining: -200000,
        totalPercentage: 120.0,
        overallStatus: BudgetStatus.overbudget,
        items: [],
      );
      expect(overSummary.overallStatus, BudgetStatus.overbudget);
      expect(overSummary.totalBudgetRemaining, -200000);
    });

    testWidgets('BudgetListScreen renders empty state when no budgets exist', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            monthlyBudgetSummaryProvider.overrideWith(
              (ref) => Future.value(const MonthlyBudgetSummary.empty(2026, 8)),
            ),
            activeBudgetsStreamProvider.overrideWith((ref) => Stream.value([])),
            activeCategoriesStreamProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(
            home: BudgetListScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Anggaran Bulanan'), findsOneWidget);
      expect(find.text('Belum Ada Anggaran'), findsOneWidget);
      expect(find.text('Buat Anggaran Sekarang'), findsOneWidget);
    });

    testWidgets('BudgetListScreen renders budget card with usage details', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockBudget = Budget()
        ..id = 1
        ..syncId = 'b_1'
        ..categorySyncId = 'cat_food'
        ..monthlyLimit = 1500000
        ..year = 2026
        ..month = 8
        ..isActive = true
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      final mockUsage = CategoryBudgetUsage(
        budget: mockBudget,
        categoryName: 'Makanan & Minuman',
        categoryIcon: 'restaurant',
        categoryColor: 0xFF5D5CFF,
        spentAmount: 750000,
        limitAmount: 1500000,
        remainingAmount: 750000,
        percentage: 50.0,
        status: BudgetStatus.safe,
      );

      final summary = MonthlyBudgetSummary(
        year: 2026,
        month: 8,
        totalBudgetLimit: 1500000,
        totalBudgetSpent: 750000,
        totalBudgetRemaining: 750000,
        totalPercentage: 50.0,
        overallStatus: BudgetStatus.safe,
        items: [mockUsage],
      );

      final mockCategory = Category()
        ..id = 1
        ..syncId = 'cat_food'
        ..name = 'Makanan & Minuman'
        ..type = 'EXPENSE'
        ..icon = 'restaurant'
        ..colorValue = 0xFF5D5CFF
        ..isActive = true
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            monthlyBudgetSummaryProvider.overrideWith((ref) => Future.value(summary)),
            activeBudgetsStreamProvider.overrideWith((ref) => Stream.value([mockBudget])),
            activeCategoriesStreamProvider.overrideWith((ref) => Stream.value([mockCategory])),
          ],
          child: const MaterialApp(
            home: BudgetListScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Anggaran Bulanan'), findsOneWidget);
      expect(find.text('Total Anggaran Bulan Ini'), findsOneWidget);
      expect(find.text('Makanan & Minuman'), findsOneWidget);
      expect(find.text('50.0%'), findsOneWidget);
      expect(find.text('Kategori Terdaftar (1)'), findsOneWidget);
    });
  });
}
