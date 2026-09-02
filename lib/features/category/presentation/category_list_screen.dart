import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/category.dart';
import '../application/category_providers.dart';

class CategoryListScreen extends ConsumerStatefulWidget {
  const CategoryListScreen({super.key});

  @override
  ConsumerState<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends ConsumerState<CategoryListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Category category) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus Kategori?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus kategori "${category.name}"?',
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.outfit(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref
                  .read(categoryControllerProvider.notifier)
                  .deleteCategory(category.id);
              if (!success && context.mounted) {
                final error = ref.read(categoryControllerProvider).error;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error?.toString() ?? 'Gagal menghapus kategori'),
                    backgroundColor: AppColors.expense,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
            ),
            child: Text('Hapus', style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(activeCategoriesStreamProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Manajemen Kategori',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.secondary),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Pengeluaran'),
            Tab(text: 'Pemasukan'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final type = _tabController.index == 0 ? 'EXPENSE' : 'INCOME';
          context.push('/categories/add', extra: type);
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: categoriesAsync.when(
        skipLoadingOnReload: true,
        data: (categories) {
          final expenseCategories = categories.where((c) => c.type == 'EXPENSE').toList();
          final incomeCategories = categories.where((c) => c.type == 'INCOME').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildCategoryList(expenseCategories),
              _buildCategoryList(incomeCategories),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildCategoryList(List<Category> categories) {
    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Belum ada kategori.',
              style: GoogleFonts.hankenGrotesk(
                color: Colors.grey.shade500,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Color(category.colorValue).withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getIconData(category.icon),
                color: Color(category.colorValue),
                size: 24,
              ),
            ),
            title: Text(
              category.name,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: AppColors.secondary,
              ),
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, size: 20, color: Colors.grey),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (value) {
                if (value == 'edit') {
                  context.push('/categories/edit', extra: category);
                } else if (value == 'delete') {
                  _confirmDelete(context, ref, category);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text('Edit', style: GoogleFonts.outfit()),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline, size: 18, color: AppColors.expense),
                      const SizedBox(width: 8),
                      Text('Hapus', style: GoogleFonts.outfit(color: AppColors.expense)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getIconData(String iconName) {
    // Basic mapping for preview, you can expand this or use a package
    switch (iconName) {
      case 'restaurant': return Icons.restaurant;
      case 'directions_car': return Icons.directions_car;
      case 'shopping_bag': return Icons.shopping_bag;
      case 'receipt': return Icons.receipt;
      case 'swap_horiz': return Icons.swap_horiz;
      case 'payments': return Icons.payments;
      case 'card_giftcard': return Icons.card_giftcard;
      case 'trending_up': return Icons.trending_up;
      case 'pets': return Icons.pets;
      case 'home': return Icons.home;
      case 'movie': return Icons.movie;
      case 'fitness_center': return Icons.fitness_center;
      case 'medical_services': return Icons.medical_services;
      case 'school': return Icons.school;
      case 'category': return Icons.category;
      default: return Icons.category;
    }
  }
}
