import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../category/data/category_repository.dart';
import '../../dashboard/application/dashboard_providers.dart';
import '../../goal/application/goal_providers.dart';
import '../application/transaction_controller.dart';
import '../domain/transaction.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final Transaction? existingTransaction;

  const AddTransactionScreen({super.key, this.existingTransaction});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _selectedType; // 'EXPENSE', 'INCOME', 'TRANSFER'
  final _amountController = TextEditingController();
  final _adminFeeController = TextEditingController();
  final _descriptionController = TextEditingController();
  late DateTime _selectedDate;

  String? _selectedWalletSyncId;
  String? _destinationWalletSyncId;
  String? _selectedCategorySyncId;

  bool get isEditMode => widget.existingTransaction != null;
  bool get isTransfer => _selectedType == 'TRANSFER';

  @override
  void initState() {
    super.initState();
    if (widget.existingTransaction != null) {
      final tx = widget.existingTransaction!;
      _selectedType = tx.type == 'TRANSFER_OUT' || tx.type == 'TRANSFER_IN'
          ? 'TRANSFER'
          : tx.type;
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
    _adminFeeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final initialDate = _selectedDate.isAfter(today) ? today : _selectedDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: today,
      helpText: 'Pilih Tanggal Transaksi',
    );
    if (picked != null) {
      final isPickedToday =
          picked.year == now.year &&
          picked.month == now.month &&
          picked.day == now.day;
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
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

    if (_selectedDate.isAfter(endOfToday)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tanggal transaksi tidak boleh melebihi hari ini.',
          ),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    if (isTransfer && isEditMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Transaksi transfer tidak dapat diedit langsung. Silakan hapus dan catat ulang transfer.',
          ),
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

    bool success;

    if (isTransfer) {
      if (_destinationWalletSyncId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silakan pilih dompet tujuan transfer.'),
          ),
        );
        return;
      }

      if (_selectedWalletSyncId == _destinationWalletSyncId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dompet sumber dan tujuan tidak boleh sama.'),
          ),
        );
        return;
      }

      final rawAdminFee = _adminFeeController.text.replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );
      final adminFee = double.tryParse(rawAdminFee) ?? 0.0;

      success = await ref
          .read(transactionControllerProvider.notifier)
          .transferBetweenWallets(
            sourceWalletSyncId: _selectedWalletSyncId!,
            destinationWalletSyncId: _destinationWalletSyncId!,
            amount: amount,
            date: _selectedDate,
            adminFee: adminFee,
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
          );
    } else if (isEditMode) {
      success = await ref
          .read(transactionControllerProvider.notifier)
          .updateTransaction(
            id: widget.existingTransaction!.id,
            type: _selectedType,
            amount: amount,
            date: _selectedDate,
            walletSyncId: _selectedWalletSyncId!,
            categorySyncId: _selectedCategorySyncId,
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
          );
    } else {
      success = await ref
          .read(transactionControllerProvider.notifier)
          .addTransaction(
            type: _selectedType,
            amount: amount,
            date: _selectedDate,
            walletSyncId: _selectedWalletSyncId!,
            categorySyncId: _selectedCategorySyncId,
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
          );
    }

    if (mounted) {
      if (success) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isTransfer
                  ? 'Transfer dana berhasil dicatat!'
                  : (_selectedType == 'INCOME'
                        ? 'Pemasukan berhasil dicatat!'
                        : 'Pengeluaran berhasil dicatat!'),
            ),
            backgroundColor: isTransfer
                ? AppColors.primary
                : (_selectedType == 'INCOME'
                      ? AppColors.income
                      : AppColors.expense),
          ),
        );
      } else {
        final error = ref.read(transactionControllerProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal menyimpan transaksi: ${error ?? "Terjadi kesalahan"}',
            ),
          ),
        );
      }
    }
  }

  Color get _themeColor {
    if (isTransfer) return AppColors.primary;
    return _selectedType == 'INCOME' ? AppColors.income : AppColors.expense;
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
          isEditMode ? 'Edit Transaksi' : 'Catat Transaksi',
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
                    // Type Selector Toggle (Pengeluaran / Pemasukan / Transfer)
                    if (!isEditMode) ...[
                      _buildTypeToggle(),
                      const SizedBox(height: 28),
                    ],

                    // Amount Input
                    _buildLabel(
                      isTransfer
                          ? 'Nominal Transfer (Rp) *'
                          : 'Nominal Transaksi (Rp) *',
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _themeColor,
                      ),
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: GoogleFonts.jetBrainsMono(
                          color: Colors.grey.shade300,
                        ),
                        prefixText: 'Rp ',
                        prefixStyle: GoogleFonts.jetBrainsMono(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _themeColor,
                        ),
                        filled: true,
                        fillColor: AppColors.neutral,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: _themeColor, width: 2),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Nominal wajib diisi';
                        }
                        final num = double.tryParse(
                          val.replaceAll(RegExp(r'[^0-9]'), ''),
                        );
                        if (num == null || num <= 0) {
                          return 'Nominal tidak valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Transfer vs Regular Form Fields
                    if (isTransfer) ...[
                      _buildTransferWalletsSection(walletsAsync),
                      const SizedBox(height: 24),
                      _buildAdminFeeInput(),
                      const SizedBox(height: 24),
                    ] else ...[
                      // Regular Wallet Picker
                      _buildLabel('Pilih Dompet *'),
                      const SizedBox(height: 8),
                      walletsAsync.when(
                        skipLoadingOnReload: true,
                        data: (wallets) {
                          final regularWallets = wallets
                              .where((w) => !w.isGoal)
                              .toList();
                          if (regularWallets.isEmpty) {
                            return const Text('Belum ada dompet aktif.');
                          }
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
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                ),
                                items: regularWallets.map((w) {
                                  return DropdownMenuItem<String>(
                                    value: w.syncId,
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.account_balance_wallet_rounded,
                                          size: 20,
                                          color: AppColors.primary,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          w.name,
                                          style: GoogleFonts.hankenGrotesk(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          CurrencyFormatter.format(w.balance),
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
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
                            onPressed: () =>
                                _showAddCategoryBottomSheet(context),
                            icon: const Icon(
                              Icons.add_circle_outline_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
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
                        skipLoadingOnReload: true,
                        data: (categories) {
                          final filteredCategories = categories
                              .where((c) => c.type == _selectedType)
                              .toList();

                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ...filteredCategories.map((cat) {
                                final isSelected =
                                    _selectedCategorySyncId == cat.syncId;
                                return ChoiceChip(
                                  label: Text(cat.name),
                                  selected: isSelected,
                                  selectedColor: AppColors.primary,
                                  labelStyle: GoogleFonts.hankenGrotesk(
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.secondary,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                  ),
                                  backgroundColor: AppColors.neutral,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.transparent,
                                    ),
                                  ),
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedCategorySyncId = selected
                                          ? cat.syncId
                                          : null;
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
                    ],

                    // Date & Time Picker
                    _buildLabel(
                      isTransfer
                          ? 'Tanggal & Waktu Transfer *'
                          : 'Tanggal & Waktu Transaksi *',
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: InkWell(
                            onTap: _selectDate,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.neutral,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    color: _themeColor,
                                    size: 20,
                                  ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.neutral,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    color: _themeColor,
                                    size: 20,
                                  ),
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
                        hintText: isTransfer
                            ? 'Contoh: Top up e-wallet / Bayar tagihan'
                            : 'Contoh: Makan siang Nasi Padang',
                        hintStyle: GoogleFonts.hankenGrotesk(
                          color: Colors.grey.shade400,
                        ),
                        prefixIcon: Icon(
                          Icons.edit_note_rounded,
                          color: _themeColor,
                        ),
                        filled: true,
                        fillColor: AppColors.neutral,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _themeColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      isTransfer ? 'Transfer Sekarang' : 'Simpan Transaksi',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransferWalletsSection(AsyncValue<List<dynamic>> walletsAsync) {
    return walletsAsync.when(
      skipLoadingOnReload: true,
      data: (wallets) {
        final regularWallets = wallets.where((w) => !w.isGoal).toList();
        if (regularWallets.length < 2) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.expenseLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Anda memerlukan minimal 2 dompet aktif untuk melakukan transfer.',
              style: TextStyle(
                color: AppColors.expense,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }

        _selectedWalletSyncId ??= regularWallets.first.syncId;
        _destinationWalletSyncId ??= regularWallets.length > 1
            ? (regularWallets.first.syncId == _selectedWalletSyncId
                  ? regularWallets[1].syncId
                  : regularWallets.first.syncId)
            : regularWallets.first.syncId;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dompet Sumber
            _buildLabel('Dompet Sumber (Asal Dana) *'),
            const SizedBox(height: 8),
            Container(
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
                          const Icon(
                            Icons.arrow_upward_rounded,
                            size: 18,
                            color: AppColors.expense,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            w.name,
                            style: GoogleFonts.hankenGrotesk(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            CurrencyFormatter.format(w.balance),
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedWalletSyncId = val;
                        // Pastikan tujuan berbeda jika sama
                        if (_destinationWalletSyncId == val) {
                          final other = regularWallets.firstWhere(
                            (w) => w.syncId != val,
                          );
                          _destinationWalletSyncId = other.syncId;
                        }
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Dompet Tujuan
            _buildLabel('Dompet Tujuan (Penerima Dana) *'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.neutral,
                borderRadius: BorderRadius.circular(16),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _destinationWalletSyncId,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  items: regularWallets.map((w) {
                    final isSameAsSource = w.syncId == _selectedWalletSyncId;
                    return DropdownMenuItem<String>(
                      value: w.syncId,
                      enabled: !isSameAsSource,
                      child: Row(
                        children: [
                          Icon(
                            Icons.arrow_downward_rounded,
                            size: 18,
                            color: isSameAsSource
                                ? Colors.grey
                                : AppColors.income,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isSameAsSource
                                ? '${w.name} (Dompet Sumber)'
                                : w.name,
                            style: GoogleFonts.hankenGrotesk(
                              fontWeight: FontWeight.w600,
                              color: isSameAsSource
                                  ? Colors.grey
                                  : AppColors.secondary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            CurrencyFormatter.format(w.balance),
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null && val != _selectedWalletSyncId) {
                      setState(() => _destinationWalletSyncId = val);
                    }
                  },
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Gagal memuat dompet: $e'),
    );
  }

  Widget _buildAdminFeeInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLabel('Biaya Admin (Opsional)'),
            Flexible(
              child: Text(
                'Dipotong dari dompet sumber',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _adminFeeController,
          keyboardType: TextInputType.number,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.secondary,
          ),
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: GoogleFonts.jetBrainsMono(color: Colors.grey.shade400),
            prefixText: 'Rp ',
            prefixStyle: GoogleFonts.jetBrainsMono(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.secondary,
            ),
            filled: true,
            fillColor: AppColors.neutral,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
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
                  color: _selectedType == 'EXPENSE'
                      ? AppColors.expense
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Pengeluaran',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: _selectedType == 'EXPENSE'
                          ? Colors.white
                          : Colors.grey.shade600,
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
                  color: _selectedType == 'INCOME'
                      ? AppColors.income
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Pemasukan',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: _selectedType == 'INCOME'
                          ? Colors.white
                          : Colors.grey.shade600,
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
                  _selectedType = 'TRANSFER';
                  _selectedCategorySyncId = null;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedType == 'TRANSFER'
                      ? AppColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Transfer',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: _selectedType == 'TRANSFER'
                          ? Colors.white
                          : Colors.grey.shade600,
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
                  hintStyle: GoogleFonts.hankenGrotesk(
                    color: Colors.grey.shade400,
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
                    backgroundColor: isIncome
                        ? AppColors.income
                        : AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    final color = isIncome ? 0xFF10B981 : 0xFFEF4444;
                    final category = await ref
                        .read(categoryRepositoryProvider)
                        .createCategory(
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
