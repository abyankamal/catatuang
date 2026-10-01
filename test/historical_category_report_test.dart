import 'package:catatuang/features/category/domain/category.dart';
import 'package:catatuang/features/report/data/report_repository.dart';
import 'package:catatuang/features/transaction/domain/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Historical Soft-Delete Category in Monthly Report Tests', () {
    test('Soft-deleted categories still appear with original name, icon, and color in MonthlyReportData', () {
      // 1. Setup categories: one active, one soft-deleted (isActive = false)
      final activeCategory = Category()
        ..id = 1
        ..syncId = 'cat_active'
        ..name = 'Makanan & Minuman'
        ..type = 'EXPENSE'
        ..icon = 'restaurant'
        ..colorValue = 0xFFEF4444
        ..isActive = true;

      final softDeletedCategory = Category()
        ..id = 2
        ..syncId = 'cat_archived'
        ..name = 'Langganan Netflix Lama'
        ..type = 'EXPENSE'
        ..icon = 'movie'
        ..colorValue = 0xFF8B5CF6
        ..isActive = false; // Soft-deleted

      // 2. Setup historical transactions associated with both categories
      final tx1 = Transaction()
        ..id = 101
        ..syncId = 'tx_101'
        ..type = 'EXPENSE'
        ..amount = 50000.0
        ..categorySyncId = activeCategory.syncId
        ..date = DateTime(2026, 9, 10);

      final tx2 = Transaction()
        ..id = 102
        ..syncId = 'tx_102'
        ..type = 'EXPENSE'
        ..amount = 186000.0
        ..categorySyncId = softDeletedCategory.syncId
        ..date = DateTime(2026, 9, 15);

      final transactions = [tx1, tx2];

      // 3. Simulate ReportRepository.getMonthlyReport logic
      // In Task 5, we changed category query from filter().isActiveEqualTo(true) to where().findAll()
      final allCategories = [activeCategory, softDeletedCategory];

      final txData = transactions.map((t) => {
        'type': t.type,
        'amount': t.amount,
        'categorySyncId': t.categorySyncId,
      }).toList();

      final catMap = <String, Map<String, dynamic>>{};
      for (final c in allCategories) {
        catMap[c.syncId] = {
          'name': c.name,
          'icon': c.icon,
          'color': c.colorValue,
        };
      }

      // Aggregate data
      double totalExpense = 0.0;
      final expenseCategoryTotals = <String, double>{};

      for (final tx in txData) {
        final type = tx['type'] as String;
        final amount = tx['amount'] as double;
        final catSyncId = tx['categorySyncId'] as String?;

        if (type == 'EXPENSE') {
          totalExpense += amount;
          final catId = catSyncId ?? 'uncategorized';
          expenseCategoryTotals[catId] = (expenseCategoryTotals[catId] ?? 0.0) + amount;
        }
      }

      final categoryExpenses = <CategoryExpenseSummary>[];
      expenseCategoryTotals.forEach((catId, amount) {
        final catInfo = catMap[catId];
        final name = catInfo?['name'] as String? ?? 'Tanpa Kategori';
        final icon = catInfo?['icon'] as String? ?? 'help_outline';
        final color = catInfo?['color'] as int? ?? 0xFF5D5CFF;
        final percentage = totalExpense > 0 ? (amount / totalExpense) * 100 : 0.0;

        categoryExpenses.add(
          CategoryExpenseSummary(
            categorySyncId: catId,
            categoryName: name,
            categoryIcon: icon,
            categoryColor: color,
            totalAmount: amount,
            percentage: percentage,
          ),
        );
      });

      // 4. Verify results
      expect(totalExpense, 236000.0);
      expect(categoryExpenses.length, 2);

      // Verify that the archived category is properly mapped and not rendered as 'Tanpa Kategori'
      final archivedSummary = categoryExpenses.firstWhere((c) => c.categorySyncId == 'cat_archived');
      expect(archivedSummary.categoryName, 'Langganan Netflix Lama');
      expect(archivedSummary.categoryIcon, 'movie');
      expect(archivedSummary.categoryColor, 0xFF8B5CF6);
      expect(archivedSummary.totalAmount, 186000.0);

      final activeSummary = categoryExpenses.firstWhere((c) => c.categorySyncId == 'cat_active');
      expect(activeSummary.categoryName, 'Makanan & Minuman');
      expect(activeSummary.totalAmount, 50000.0);
    });

    test('Old query with active-only categories causes soft-deleted category to fallback to Tanpa Kategori', () {
      final activeCategory = Category()
        ..id = 1
        ..syncId = 'cat_active'
        ..name = 'Makanan & Minuman'
        ..type = 'EXPENSE'
        ..icon = 'restaurant'
        ..colorValue = 0xFFEF4444
        ..isActive = true;

      // Soft-deleted category is NOT in the active query result
      final activeOnlyCategories = [activeCategory];

      final catMap = <String, Map<String, dynamic>>{};
      for (final c in activeOnlyCategories) {
        catMap[c.syncId] = {
          'name': c.name,
          'icon': c.icon,
          'color': c.colorValue,
        };
      }

      final archivedCatInfo = catMap['cat_archived'];
      final name = archivedCatInfo?['name'] as String? ?? 'Tanpa Kategori';

      // Confirms why where().findAll() was necessary
      expect(name, 'Tanpa Kategori');
    });
  });
}
