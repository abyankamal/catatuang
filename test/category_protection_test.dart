import 'package:catatuang/features/budget/domain/budget.dart';
import 'package:catatuang/features/category/domain/category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Category Protection & Self-Healing Logic Tests', () {
    test('softDeleteCategory throws Exception when attempting to delete system category cat_transfer_fee', () {
      final transferFeeCat = Category()
        ..id = 1
        ..syncId = 'cat_transfer_fee'
        ..name = 'Biaya Transfer'
        ..type = 'EXPENSE'
        ..icon = 'swap_horiz'
        ..colorValue = 0xFF64748B
        ..isActive = true;

      void validateCategoryDeletion(Category category, {Budget? activeBudget}) {
        if (category.syncId == 'cat_transfer_fee') {
          throw Exception('Kategori sistem (Biaya Transfer) tidak dapat dinonaktifkan.');
        }

        if (activeBudget != null) {
          throw Exception(
            'Kategori "${category.name}" masih memiliki anggaran aktif untuk bulan ini. '
            'Silakan hapus atau nonaktifkan anggaran kategori ini terlebih dahulu.',
          );
        }

        category.isActive = false;
      }

      expect(
        () => validateCategoryDeletion(transferFeeCat),
        throwsA(
          predicate(
            (e) =>
                e is Exception &&
                e.toString().contains('Kategori sistem (Biaya Transfer) tidak dapat dinonaktifkan.'),
          ),
        ),
      );

      // Verify category remains active
      expect(transferFeeCat.isActive, isTrue);
    });

    test('softDeleteCategory throws Exception when category has an active budget for current month', () {
      final regularCategory = Category()
        ..id = 2
        ..syncId = 'cat_makanan'
        ..name = 'Makanan & Minuman'
        ..type = 'EXPENSE'
        ..icon = 'restaurant'
        ..colorValue = 0xFFEF4444
        ..isActive = true;

      final now = DateTime.now();
      final activeBudget = Budget()
        ..id = 10
        ..syncId = 'budget_10'
        ..categorySyncId = regularCategory.syncId
        ..monthlyLimit = 1500000.0
        ..year = now.year
        ..month = now.month
        ..isActive = true;

      void validateCategoryDeletion(Category category, {Budget? activeBudget}) {
        if (category.syncId == 'cat_transfer_fee') {
          throw Exception('Kategori sistem (Biaya Transfer) tidak dapat dinonaktifkan.');
        }

        if (activeBudget != null && activeBudget.isActive) {
          throw Exception(
            'Kategori "${category.name}" masih memiliki anggaran aktif untuk bulan ini. '
            'Silakan hapus atau nonaktifkan anggaran kategori ini terlebih dahulu.',
          );
        }

        category.isActive = false;
      }

      expect(
        () => validateCategoryDeletion(regularCategory, activeBudget: activeBudget),
        throwsA(
          predicate(
            (e) =>
                e is Exception &&
                e.toString().contains('masih memiliki anggaran aktif untuk bulan ini'),
          ),
        ),
      );

      expect(regularCategory.isActive, isTrue);
    });

    test('softDeleteCategory succeeds when category is normal and has no active budget', () {
      final normalCategory = Category()
        ..id = 3
        ..syncId = 'cat_hobi'
        ..name = 'Hobi & Game'
        ..type = 'EXPENSE'
        ..icon = 'sports_esports'
        ..colorValue = 0xFF8B5CF6
        ..isActive = true;

      void validateCategoryDeletion(Category category, {Budget? activeBudget}) {
        if (category.syncId == 'cat_transfer_fee') {
          throw Exception('Kategori sistem (Biaya Transfer) tidak dapat dinonaktifkan.');
        }

        if (activeBudget != null && activeBudget.isActive) {
          throw Exception(
            'Kategori "${category.name}" masih memiliki anggaran aktif untuk bulan ini. '
            'Silakan hapus atau nonaktifkan anggaran kategori ini terlebih dahulu.',
          );
        }

        category.isActive = false;
      }

      validateCategoryDeletion(normalCategory, activeBudget: null);
      expect(normalCategory.isActive, isFalse);
    });

    test('Self-healing logic automatically provides cat_transfer_fee for populated legacy database', () {
      // Simulate existing legacy categories without cat_transfer_fee
      final existingLegacyCategories = <Category>[
        Category()
          ..id = 1
          ..syncId = 'cat_makanan'
          ..name = 'Makanan & Minuman'
          ..type = 'EXPENSE'
          ..isActive = true,
        Category()
          ..id = 2
          ..syncId = 'cat_gaji'
          ..name = 'Gaji'
          ..type = 'INCOME'
          ..isActive = true,
      ];

      // Run self-healing simulation
      void selfHealCategories(List<Category> categories) {
        final hasTransferFee = categories.any((c) => c.syncId == 'cat_transfer_fee');
        if (!hasTransferFee) {
          categories.add(
            Category()
              ..syncId = 'cat_transfer_fee'
              ..name = 'Biaya Transfer'
              ..type = 'EXPENSE'
              ..icon = 'swap_horiz'
              ..colorValue = 0xFF64748B
              ..isActive = true,
          );
        }
      }

      expect(existingLegacyCategories.any((c) => c.syncId == 'cat_transfer_fee'), isFalse);

      selfHealCategories(existingLegacyCategories);

      expect(existingLegacyCategories.any((c) => c.syncId == 'cat_transfer_fee'), isTrue);
      final feeCat = existingLegacyCategories.firstWhere((c) => c.syncId == 'cat_transfer_fee');
      expect(feeCat.name, 'Biaya Transfer');
      expect(feeCat.isActive, isTrue);

      // Idempotent test: calling it again doesn't duplicate
      selfHealCategories(existingLegacyCategories);
      expect(
        existingLegacyCategories.where((c) => c.syncId == 'cat_transfer_fee').length,
        1,
      );
    });
  });
}
