import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import 'package:uuid/uuid.dart';

import '../../../core/database/database_provider.dart';
import '../domain/category.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return CategoryRepository(isar);
});

class CategoryRepository {
  final Isar _isar;
  final _uuid = const Uuid();

  CategoryRepository(this._isar);

  Stream<List<Category>> watchActiveCategories() {
    return _isar.categorys
        .filter()
        .isActiveEqualTo(true)
        .watch(fireImmediately: true);
  }

  Future<List<Category>> getActiveCategories() async {
    return await _isar.categorys
        .filter()
        .isActiveEqualTo(true)
        .findAll();
  }

  /// Buat kategori pemasukan/pengeluaran baru
  Future<Category> createCategory({
    required String name,
    required String type, // 'INCOME' or 'EXPENSE'
    String icon = 'category',
    int colorValue = 0xFF5D5CFF,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Nama kategori tidak boleh kosong.');
    }

    final now = DateTime.now();
    final category = Category()
      ..syncId = _uuid.v4()
      ..name = trimmedName
      ..type = type
      ..icon = icon
      ..colorValue = colorValue
      ..isActive = true
      ..createdAt = now
      ..updatedAt = now;

    await _isar.writeTxn(() async {
      await _isar.categorys.put(category);
    });

    return category;
  }

  /// Inisialisasi kategori standar jika belum ada
  Future<void> seedDefaultCategoriesIfEmpty() async {
    final count = await _isar.categorys.count();
    if (count == 0) {
      await _isar.writeTxn(() async {
        final now = DateTime.now();
        final defaults = [
          // Expense Categories
          Category()
            ..syncId = 'cat_makanan'
            ..name = 'Makanan & Minuman'
            ..type = 'EXPENSE'
            ..icon = 'restaurant'
            ..colorValue = 0xFFEF4444
            ..isActive = true
            ..createdAt = now
            ..updatedAt = now,
          Category()
            ..syncId = 'cat_transport'
            ..name = 'Transportasi'
            ..type = 'EXPENSE'
            ..icon = 'directions_car'
            ..colorValue = 0xFFF59E0B
            ..isActive = true
            ..createdAt = now
            ..updatedAt = now,
          Category()
            ..syncId = 'cat_belanja'
            ..name = 'Belanja'
            ..type = 'EXPENSE'
            ..icon = 'shopping_bag'
            ..colorValue = 0xFF8B5CF6
            ..isActive = true
            ..createdAt = now
            ..updatedAt = now,
          Category()
            ..syncId = 'cat_tagihan'
            ..name = 'Tagihan & Utilitas'
            ..type = 'EXPENSE'
            ..icon = 'receipt'
            ..colorValue = 0xFFEC4899
            ..isActive = true
            ..createdAt = now
            ..updatedAt = now,
          Category()
            ..syncId = 'cat_transfer_fee'
            ..name = 'Biaya Transfer'
            ..type = 'EXPENSE'
            ..icon = 'swap_horiz'
            ..colorValue = 0xFF64748B
            ..isActive = true
            ..createdAt = now
            ..updatedAt = now,

          // Income Categories
          Category()
            ..syncId = 'cat_gaji'
            ..name = 'Gaji'
            ..type = 'INCOME'
            ..icon = 'payments'
            ..colorValue = 0xFF10B981
            ..isActive = true
            ..createdAt = now
            ..updatedAt = now,
          Category()
            ..syncId = 'cat_bonus'
            ..name = 'Bonus & Hadiah'
            ..type = 'INCOME'
            ..icon = 'card_giftcard'
            ..colorValue = 0xFF06B6D4
            ..isActive = true
            ..createdAt = now
            ..updatedAt = now,
          Category()
            ..syncId = 'cat_investasi'
            ..name = 'Investasi'
            ..type = 'INCOME'
            ..icon = 'trending_up'
            ..colorValue = 0xFF3B82F6
            ..isActive = true
            ..createdAt = now
            ..updatedAt = now,
        ];

        for (final cat in defaults) {
          await _isar.categorys.put(cat);
        }
      });
    }
  }

  /// Update Kategori
  Future<Category> updateCategory({
    required int id,
    required String name,
    required String type,
    String? icon,
    int? colorValue,
  }) async {
    final category = await _isar.categorys.get(id);
    if (category == null) throw Exception('Kategori tidak ditemukan');

    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Nama kategori tidak boleh kosong.');
    }

    category.name = trimmedName;
    category.type = type;
    if (icon != null) category.icon = icon;
    if (colorValue != null) category.colorValue = colorValue;
    category.updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.categorys.put(category);
    });

    return category;
  }

  /// Soft Delete Kategori
  Future<void> softDeleteCategory(int id) async {
    final category = await _isar.categorys.get(id);
    if (category == null) throw Exception('Kategori tidak ditemukan');

    category.isActive = false;
    category.updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.categorys.put(category);
    });
  }
}
