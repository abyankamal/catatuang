import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../category/data/category_repository.dart';
import '../../dashboard/application/dashboard_providers.dart';
import '../application/transaction_controller.dart';
import '../domain/transaction.dart';
import '../../goal/application/goal_providers.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final Transaction? existingTransaction;

  const AddTransactionScreen({super.key, this.existingTransaction});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late String _selectedType;
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  late DateTime _selectedDate;

  String? _selectedWalletSyncId;
  String? _selectedCategorySyncId;

  @override
  void initState() {
    super.initState();
    if (widget.existingTransaction != null) {
      final tx = widget.existingTransaction!;
      _selectedType = tx.type;
      _amountController.text = tx.amount.toInt() == tx.amount
          ? tx.amount.toInt().toString()
          : tx.amount.toString();
      _descriptionController.text = tx.description ?? '';
      _selectedDate = tx.date;
      _selectedWalletSyncId = tx.walletSyncId;
      _selectedCategorySyncId = tx.categorySyncId;
    } else {
      _selectedType = 'EXPENSE';
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }


  Future<void> _selectDate() async {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final today = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final initialDate = _selectedDate.isAfter(today)
        ? today
        : (_selectedDate.isBefore(firstDayOfMonth) ? firstDayOfMonth : _selectedDate);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDayOfMonth,
      lastDate: today,
      helpText: 'Pilih Tanggal Transaksi (Bulan Ini)',
    );
    if (picked != null) {
      final isPickedToday = picked.year == now.year && picked.month == now.month && picked.day == now.day;
      
      // Jika tanggal hari ini, gunakan jam realtime. Jika tanggal sebelum hari ini, gunakan jam yang tersimpan atau jam 12:00
      final hour = isPickedToday ? now.hour : _selectedDate.hour;
      final minute = isPickedToday ? now.minute : _selectedDate.minute;

      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          hour,
          minute,
        );
      });

      // Otomatis buka pemilih jam jika memilih tanggal sebelum hari ini
      if (!isPickedToday && mounted) {
        _selectTime();
      }
    }
  }

  Future<void> _selectTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
      helpText: 'Pilih Waktu Transaksi',
    );

    if (pickedTime != null) {
      setState(() {
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

    if (_selectedDate.isAfter(endOfToday) || _selectedDate.isBefore(firstDayOfMonth)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanggal transaksi hanya diperbolehkan untuk bulan ini dan maksimal hari ini.'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    if (_selectedWalletSyncId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih dompet terlebih dahulu.')),
      );
      return;
    }

    final rawAmount = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(rawAmount) ?? 0.0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal harus lebih dari 0.')),
      );
      return;
    }

    final success = widget.existingTransaction != null
        ? await ref.read(transactionControllerProvider.notifier).updateTransaction(
              id: widget.existingTransaction!.id,
              type: _selectedType,
              amount: amount,
              date: _selectedDate,
              walletSyncId: _selectedWalletSyncId!,
              categorySyncId: _selectedCategorySyncId,
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
            )
        : await ref.read(transactionControllerProvider.notifier).addTransaction(
              type: _selectedType,
              amount: amount,
              date: _selectedDate,
              walletSyncId: _selectedWalletSyncId!,
              categorySyncId: _selectedCategorySyncId,
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
            );


    if (mounted) {
      if (success) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedType == 'INCOME'
                  ? 'Pemasukan berhasil dicatat!'
                  : 'Pengeluaran berhasil dicatat!',
            ),
            backgroundColor: _selectedType == 'INCOME' ? AppColors.income : AppColors.expense,
          ),
        );
      } else {
        final error = ref.read(transactionControllerProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan transaksi: ${error ?? "Terjadi kesalahan"}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(activeRegularWalletsStreamProvider);
    final categoriesAsync = ref.watch(activeCategoriesStreamProvider);
    final controllerState = ref.watch(transactionControllerProvider);
    final isLoading = controllerState.isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Catat Transaksi',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.secondary),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type Selector Toggle (Pemasukan / Pengeluaran)
                    _buildTypeToggle(),
                    const SizedBox(height: 28),

                    // Amount Input
                    _buildLabel('Nominal Transaksi (Rp)'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _selectedType == 'INCOME' ? AppColors.income : AppColors.expense,
                      ),
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: GoogleFonts.jetBrainsMono(color: Colors.grey.shade300),
                        prefixText: 'Rp ',
                        prefixStyle: GoogleFonts.jetBrainsMono(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _selectedType == 'INCOME' ? AppColors.income : AppColors.expense,
                        ),
                        filled: true,
                        fillColor: AppColors.neutral,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: _selectedType == 'INCOME' ? AppColors.income : AppColors.expense,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Nominal wajib diisi';
                        final num = double.tryParse(val.replaceAll(RegExp(r'[^0-9]'), ''));
                        if (num == null || num <= 0) return 'Nominal tidak valid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Wallet Picker
                    _buildLabel('Pilih Dompet'),
                    const SizedBox(height: 8),
                    walletsAsync.when(
                      data: (wallets) {
                        final regularWallets = wallets.where((w) => !w.isGoal).toList();
                        if (regularWallets.isEmpty) {
                          return const Text('Belum ada dompet aktif.');
                        }

                        // Auto-select first wallet if none selected
                        _selectedWalletSyncId ??= regularWallets.first.syncId;

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.neutral,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedWalletSyncId,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded),
                              items: regularWallets.map((w) {
                                return DropdownMenuItem<String>(
                                  value: w.syncId,
                                  child: Row(
                                    children: [
                                      const Icon(Icons.account_balance_wallet_rounded,
                                          size: 20, color: AppColors.primary),
                                      const SizedBox(width: 12),
                                      Text(
                                        w.name,
                                        style: GoogleFonts.hankenGrotesk(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedWalletSyncId = val);
                                }
                              },
                            ),
                          ),
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Gagal memuat dompet: $e'),
                    ),
                    const SizedBox(height: 24),

                    // Category Picker
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildLabel('Pilih Kategori'),
                        TextButton.icon(
                          onPressed: () => _showAddCategoryBottomSheet(context),
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 16, color: AppColors.primary),
                          label: Text(
                            '+ Tambah Kategori',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    categoriesAsync.when(
                      data: (categories) {
                        final filteredCategories =
                            categories.where((c) => c.type == _selectedType).toList();

                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ...filteredCategories.map((cat) {
                              final isSelected = _selectedCategorySyncId == cat.syncId;
                              return ChoiceChip(
                                label: Text(cat.name),
                                selected: isSelected,
                                selectedColor: AppColors.primary,
                                labelStyle: GoogleFonts.hankenGrotesk(
                                  color: isSelected ? Colors.white : AppColors.secondary,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                ),
                                backgroundColor: AppColors.neutral,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: isSelected ? AppColors.primary : Colors.transparent,
                                  ),
                                ),
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedCategorySyncId = selected ? cat.syncId : null;
                                  });
                                },
                              );
                            }),
                          ],
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Gagal memuat kategori: $e'),
                    ),
                    const SizedBox(height: 24),

                    // Date & Time Picker
                    _buildLabel('Tanggal & Waktu Transaksi'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: InkWell(
                            onTap: _selectDate,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                              decoration: BoxDecoration(
                                color: AppColors.neutral,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                      style: GoogleFonts.hankenGrotesk(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: InkWell(
                            onTap: _selectTime,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                              decoration: BoxDecoration(
                                color: AppColors.neutral,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.access_time_rounded, color: AppColors.primary, size: 20),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${_selectedDate.hour.toString().padLeft(2, '0')}:${_selectedDate.minute.toString().padLeft(2, '0')}',
                                    style: GoogleFonts.hankenGrotesk(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Description / Catatan
                    _buildLabel('Catatan (Opsional)'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        hintText: 'Contoh: Makan siang Nasi Padang',
                        hintStyle: GoogleFonts.hankenGrotesk(color: Colors.grey.shade400),
                        prefixIcon: const Icon(Icons.edit_note_rounded, color: AppColors.primary),
                        filled: true,
                        fillColor: AppColors.neutral,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'Simpan Transaksi',
                                style: GoogleFonts.manrope(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.neutral,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedType = 'EXPENSE';
                  _selectedCategorySyncId = null;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedType == 'EXPENSE' ? AppColors.expense : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Pengeluaran',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.bold,
                      color: _selectedType == 'EXPENSE' ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedType = 'INCOME';
                  _selectedCategorySyncId = null;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedType == 'INCOME' ? AppColors.income : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Pemasukan',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.bold,
                      color: _selectedType == 'INCOME' ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.hankenGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.secondary,
      ),
    );
  }

  void _showAddCategoryBottomSheet(BuildContext context) {
    final nameController = TextEditingController();
    final isIncome = _selectedType == 'INCOME';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tambah Kategori (${isIncome ? 'Pemasukan' : 'Pengeluaran'})',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: isIncome
                      ? 'Contoh: Cashback, Dividen, Sampingan'
                      : 'Contoh: Olahraga, Hiburan, Kopi',
                  hintStyle: GoogleFonts.hankenGrotesk(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: AppColors.neutral,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isIncome ? AppColors.income : AppColors.expense,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isIncome ? AppColors.income : AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    final color = isIncome ? 0xFF10B981 : 0xFFEF4444;
                    final category = await ref.read(categoryRepositoryProvider).createCategory(
                          name: name,
                          type: _selectedType,
                          colorValue: color,
                        );

                    ref.invalidate(activeCategoriesStreamProvider);
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      setState(() {
                        _selectedCategorySyncId = category.syncId;
                      });
                    }
                  },
                  child: Text(
                    'Simpan Kategori Baru',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
