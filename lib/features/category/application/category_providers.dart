import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/category_repository.dart';
import '../domain/category.dart';

final activeCategoriesStreamProvider = StreamProvider<List<Category>>((ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.watchActiveCategories();
});

class CategoryController extends StateNotifier<AsyncValue<void>> {
  final CategoryRepository _repo;

  CategoryController(this._repo) : super(const AsyncValue.data(null));

  Future<bool> addCategory({
    required String name,
    required String type,
    String icon = 'category',
    int colorValue = 0xFF5D5CFF,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.createCategory(
        name: name,
        type: type,
        icon: icon,
        colorValue: colorValue,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateCategory({
    required int id,
    required String name,
    required String type,
    String? icon,
    int? colorValue,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateCategory(
        id: id,
        name: name,
        type: type,
        icon: icon,
        colorValue: colorValue,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteCategory(int id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.softDeleteCategory(id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final categoryControllerProvider = StateNotifierProvider<CategoryController, AsyncValue<void>>((ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  return CategoryController(repo);
});
