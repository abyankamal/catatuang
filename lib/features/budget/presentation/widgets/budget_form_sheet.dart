import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../dashboard/application/dashboard_providers.dart';
import '../../application/budget_providers.dart';
import '../../data/budget_repository.dart';

class BudgetFormSheet extends ConsumerStatefulWidget {
  final CategoryBudgetUsage? existingUsage;
  final int year;
  final int month;

  const BudgetFormSheet({
    super.key,
    this.existingUsage,
    required this.year,
    required this.month,
  });

  @override
  ConsumerState<BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends ConsumerState<BudgetFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String? _selectedCategorySyncId;
  bool _isLoading = false;

  bool get isEditMode => widget.existingUsage != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      final usage = widget.existingUsage!;
      _selectedCategorySyncId = usage.budget.categorySyncId;
      _amountController.text = usage.limitAmount.toInt().toString();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'restaurant':
      case 'food':
        return Icons.restaurant_rounded;
      case 'directions_car':
      case 'transport':
        return Icons.directions_car_rounded;
      case 'shopping_bag':
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'movie':
      case 'entertainment':
        return Icons.movie_rounded;
      case 'receipt_long':
      case 'bills':
        return Icons.receipt_long_rounded;
      case 'medical_services':
      case 'health':
        return Icons.medical_services_rounded;
      case 'school':
      case 'education':
        return Icons.school_rounded;
      case 'card_giftcard':
      case 'gift':
        return Icons.card_giftcard_rounded;
      case 'work':
      case 'salary':
        return Icons.work_rounded;
      case 'trending_up':
      case 'investment':
        return Icons.trending_up_rounded;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategorySyncId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih kategori pengeluaran terlebih dahulu.'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    final rawAmount = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(rawAmount) ?? 0.0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Batas anggaran harus lebih dari 0.'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final success = await ref.read(budgetControllerProvider.notifier).setBudget(
            categorySyncId: _selectedCategorySyncId!,
            monthlyLimit: amount,
            year: widget.year,
            month: widget.month,
          );

      if (mounted) {
        if (success) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEditMode
                    ? 'Anggaran berhasil diperbarui!'
                    : 'Anggaran baru berhasil disimpan!',
              ),
              backgroundColor: AppColors.income,
            ),
          );
        } else {
          final error = ref.read(budgetControllerProvider).error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menyimpan anggaran: ${error ?? "Terjadi kesalahan"}'),
              backgroundColor: AppColors.expense,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(activeCategoriesStreamProvider);
    final expenseCategories = categoriesAsync.valueOrNull
            ?.where((c) => c.type == 'EXPENSE')
            .toList() ??
        [];

    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.pie_chart_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isEditMode ? 'Edit Anggaran' : 'Atur Anggaran Baru',
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Category Selection
                Text(
                  'Kategori Pengeluaran *',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),

                if (isEditMode)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(widget.existingUsage!.categoryColor).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getIconData(widget.existingUsage!.categoryIcon),
                            color: Color(widget.existingUsage!.categoryColor),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          widget.existingUsage!.categoryName,
                          style: GoogleFonts.manrope(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategorySyncId,
                    decoration: InputDecoration(
                      hintText: 'Pilih Kategori',
                      hintStyle: GoogleFonts.hankenGrotesk(color: Colors.grey.shade400),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                    items: expenseCategories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat.syncId,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Color(cat.colorValue).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getIconData(cat.icon),
                                color: Color(cat.colorValue),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              cat.name,
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedCategorySyncId = val);
                    },
                    validator: (val) => val == null ? 'Kategori wajib dipilih' : null,
                  ),
                const SizedBox(height: 20),

                // Monthly Limit Input
                Text(
                  'Batas Anggaran Bulanan (Rp) *',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Contoh: 1500000',
                    prefixText: 'Rp ',
                    prefixStyle: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Nominal anggaran wajib diisi';
                    }
                    final parsed = double.tryParse(val.replaceAll(RegExp(r'[^0-9]'), ''));
                    if (parsed == null || parsed <= 0) {
                      return 'Nominal harus lebih dari 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            isEditMode ? 'Simpan Perubahan' : 'Pasang Anggaran',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                if (!isKeyboardVisible) const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
