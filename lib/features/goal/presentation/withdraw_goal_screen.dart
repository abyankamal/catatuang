import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../wallet/domain/wallet.dart';
import '../application/goal_providers.dart';

class WithdrawGoalScreen extends ConsumerStatefulWidget {
  final String goalId;

  const WithdrawGoalScreen({super.key, required this.goalId});

  @override
  ConsumerState<WithdrawGoalScreen> createState() => _WithdrawGoalScreenState();
}

class _WithdrawGoalScreenState extends ConsumerState<WithdrawGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  late DateTime _selectedDate;
  String? _selectedWalletSyncId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _applyPercentage(double percentage, double balance) {
    final amount = (balance * percentage).roundToDouble();
    _amountController.text = amount.toInt().toString();
    setState(() {});
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
      helpText: 'Pilih Tanggal Pencairan Tabungan',
    );

    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  Future<void> _submit(Wallet? goal) async {
    if (goal == null) return;
    if (!_formKey.currentState!.validate()) return;

    if (_selectedWalletSyncId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih dompet tujuan penerima dana.')),
      );
      return;
    }

    final rawAmount = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(rawAmount) ?? 0.0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal penarikan harus lebih dari 0.')),
      );
      return;
    }

    if (amount > goal.balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nominal melebihi saldo tabungan saat ini (${CurrencyFormatter.format(goal.balance)}).'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await ref.read(goalControllerProvider.notifier).withdrawGoal(
            goalWalletSyncId: widget.goalId,
            destinationWalletSyncId: _selectedWalletSyncId!,
            amount: amount,
            date: _selectedDate,
            notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          );

      if (mounted) {
        if (success) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Dana tabungan sebesar ${CurrencyFormatter.format(amount)} berhasil dicairkan!',
              ),
              backgroundColor: AppColors.income,
            ),
          );
        } else {
          final error = ref.read(goalControllerProvider).error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menarik dana: ${error ?? "Terjadi kesalahan"}'),
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
    final activeGoals = ref.watch(activeGoalsStreamProvider).valueOrNull ?? [];
    final goal = activeGoals.cast<Wallet?>().firstWhere(
          (g) => g?.syncId == widget.goalId,
          orElse: () => null,
        );
    final walletsAsync = ref.watch(activeRegularWalletsStreamProvider);

    final target = goal?.targetAmount ?? 0.0;
    final balance = goal?.balance ?? 0.0;
    final progress = target > 0 ? (balance / target).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Tarik Dana Tabungan',
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
                    // Target Goal Info Header Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withAlpha(25),
                            AppColors.primary.withAlpha(10),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary.withAlpha(40)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.track_changes_rounded,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      goal != null && goal.name.isNotEmpty ? goal.name : 'Target Tabungan',
                                      style: GoogleFonts.manrope(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.secondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Target: ${CurrencyFormatter.format(target)}',
                                      style: GoogleFonts.hankenGrotesk(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Saldo Tersedia untuk Ditarik',
                                      style: GoogleFonts.hankenGrotesk(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      CurrencyFormatter.format(balance),
                                      style: GoogleFonts.manrope(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${(progress * 100).toStringAsFixed(0)}% Terkumpul',
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Quick Percentage Presets
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildLabel('Nominal Penarikan (Rp) *'),
                        Text(
                          'Pilih Cepat',
                          style: GoogleFonts.hankenGrotesk(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildPresetChip('25%', () => _applyPercentage(0.25, balance)),
                          const SizedBox(width: 8),
                          _buildPresetChip('50%', () => _applyPercentage(0.50, balance)),
                          const SizedBox(width: 8),
                          _buildPresetChip('75%', () => _applyPercentage(0.75, balance)),
                          const SizedBox(width: 8),
                          _buildPresetChip('100% (Semua)', () => _applyPercentage(1.0, balance), isFull: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Amount Input
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: GoogleFonts.jetBrainsMono(color: Colors.grey.shade300),
                        prefixText: 'Rp ',
                        prefixStyle: GoogleFonts.jetBrainsMono(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                        filled: true,
                        fillColor: AppColors.neutral,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Nominal penarikan wajib diisi';
                        final num = double.tryParse(val.replaceAll(RegExp(r'[^0-9]'), ''));
                        if (num == null || num <= 0) return 'Nominal tidak valid';
                        if (num > balance) {
                          return 'Nominal melebihi saldo tabungan (${CurrencyFormatter.format(balance)})';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Destination Regular Wallet Picker
                    _buildLabel('Pindahkan ke Dompet Tujuan *'),
                    const SizedBox(height: 8),
                    walletsAsync.when(
                      skipLoadingOnReload: true,
                      data: (wallets) {
                        final regularWallets = wallets.where((w) => !w.isGoal).toList();
                        if (regularWallets.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.expenseLight,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text('Belum ada dompet reguler aktif untuk menampung dana.'),
                          );
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
                              icon: const Icon(Icons.keyboard_arrow_down_rounded),
                              items: regularWallets.map((w) {
                                return DropdownMenuItem<String>(
                                  value: w.syncId,
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.account_balance_wallet_rounded,
                                        size: 18,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        w.name,
                                        style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w600),
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

                    // Date Picker
                    _buildLabel('Tanggal Penarikan *'),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _selectDate,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.neutral,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                DateFormatter.formatFullDate(_selectedDate),
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Notes / Catatan
                    _buildLabel('Catatan Penarikan (Opsional)'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        hintText: 'Contoh: Realisasi impian / Kebutuhan darurat',
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
                    const SizedBox(height: 32),
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
              onPressed: _isLoading || balance <= 0 ? null : () => _submit(goal),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Cairkan Dana Tabungan',
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

  Widget _buildPresetChip(String label, VoidCallback onTap, {bool isFull = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isFull ? AppColors.primary.withAlpha(20) : AppColors.neutral,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isFull ? AppColors.primary : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isFull ? AppColors.primary : AppColors.secondary,
          ),
        ),
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
}
