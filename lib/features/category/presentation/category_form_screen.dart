import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/category.dart';
import '../application/category_providers.dart';

class CategoryFormScreen extends ConsumerStatefulWidget {
  final Category? existingCategory;
  final String initialType; // 'EXPENSE' or 'INCOME'

  const CategoryFormScreen({
    super.key,
    this.existingCategory,
    this.initialType = 'EXPENSE',
  });

  @override
  ConsumerState<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends ConsumerState<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late String _selectedType;
  late String _selectedIcon;
  late int _selectedColor;

  bool _isLoading = false;
  bool get isEditMode => widget.existingCategory != null;

  final List<String> _availableIcons = [
    'restaurant', 'directions_car', 'shopping_bag', 'receipt',
    'payments', 'card_giftcard', 'trending_up', 'pets',
    'home', 'movie', 'fitness_center', 'medical_services',
    'school', 'category'
  ];

  final List<int> _availableColors = [
    0xFFEF4444, // Red
    0xFFF97316, // Orange
    0xFFF59E0B, // Amber
    0xFF10B981, // Emerald
    0xFF06B6D4, // Cyan
    0xFF3B82F6, // Blue
    0xFF6366F1, // Indigo
    0xFF8B5CF6, // Violet
    0xFFEC4899, // Pink
    0xFF64748B, // Slate
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingCategory?.name ?? '');
    _selectedType = widget.existingCategory?.type ?? widget.initialType;
    _selectedIcon = widget.existingCategory?.icon ?? 'category';
    _selectedColor = widget.existingCategory?.colorValue ?? 0xFF3B82F6;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  IconData _getIconData(String iconName) {
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final name = _nameController.text.trim();

    try {
      if (isEditMode) {
        await ref.read(categoryControllerProvider.notifier).updateCategory(
          id: widget.existingCategory!.id,
          name: name,
          type: _selectedType,
          icon: _selectedIcon,
          colorValue: _selectedColor,
        );
      } else {
        await ref.read(categoryControllerProvider.notifier).addCategory(
          name: name,
          type: _selectedType,
          icon: _selectedIcon,
          colorValue: _selectedColor,
        );
      }
      
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditMode ? 'Kategori berhasil diperbarui!' : 'Kategori berhasil ditambahkan!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          isEditMode ? 'Edit Kategori' : 'Tambah Kategori',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.secondary),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Tipe Kategori'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildTypeButton(
                        title: 'Pengeluaran',
                        value: 'EXPENSE',
                        color: AppColors.expense,
                        icon: Icons.arrow_downward_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTypeButton(
                        title: 'Pemasukan',
                        value: 'INCOME',
                        color: AppColors.income,
                        icon: Icons.arrow_upward_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                _buildLabel('Nama Kategori'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Contoh: Makanan, Gaji...',
                    hintStyle: GoogleFonts.hankenGrotesk(color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Nama kategori wajib diisi' : null,
                ),
                const SizedBox(height: 24),

                _buildLabel('Pilih Warna'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _availableColors.map((colorValue) {
                    final isSelected = _selectedColor == colorValue;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = colorValue),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(colorValue),
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.black, width: 3)
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                _buildLabel('Pilih Ikon'),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _availableIcons.length,
                  itemBuilder: (context, index) {
                    final iconName = _availableIcons[index];
                    final isSelected = _selectedIcon == iconName;
                    
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIcon = iconName),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? Color(_selectedColor).withAlpha(40) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(color: Color(_selectedColor), width: 2)
                              : Border.all(color: Colors.grey.shade200),
                        ),
                        child: Icon(
                          _getIconData(iconName),
                          color: isSelected ? Color(_selectedColor) : Colors.grey.shade600,
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Simpan Kategori',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.secondary,
      ),
    );
  }

  Widget _buildTypeButton({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    final isSelected = _selectedType == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(20) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey.shade400, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
