import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../contact/domain/contact.dart';
import '../../application/debt_providers.dart';
import '../../domain/debt.dart';

class DebtPaymentBottomSheet extends ConsumerStatefulWidget {
  final Debt debt;
  final Contact? contact;

  const DebtPaymentBottomSheet({
    super.key,
    required this.debt,
    this.contact,
  });

  static Future<bool?> show(
    BuildContext context, {
    required Debt debt,
    Contact? contact,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: DebtPaymentBottomSheet(debt: debt, contact: contact),
      ),
    );
  }

  @override
  ConsumerState<DebtPaymentBottomSheet> createState() => _DebtPaymentBottomSheetState();
}

class _DebtPaymentBottomSheetState extends ConsumerState<DebtPaymentBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  late DateTime _selectedDate;
  String? _selectedWalletSyncId;
  bool _isLoading = false;

  double get remaining =>
      (widget.debt.totalAmount - widget.debt.paidAmount).clamp(0.0, widget.debt.totalAmount);
  bool get isPayable => widget.debt.type == 'PAYABLE';

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

  void _setFullPayment() {
    setState(() {
      _amountController.text = remaining.toInt() == remaining
          ? remaining.toInt().toString()
          : remaining.toString();
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Pilih Tanggal Pembayaran',
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
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

    if (amount > remaining + 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal tidak boleh melebihi sisa tagihan.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await ref.read(debtControllerProvider.notifier).recordPayment(
            debtId: widget.debt.id,
            paymentAmount: amount,
            date: _selectedDate,
            walletSyncId: _selectedWalletSyncId!,
            notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          );

      if (mounted) {
        if (success) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isPayable
                    ? 'Pembayaran utang sebesar Rp ${CurrencyFormatter.format(amount)} berhasil dicatat!'
                    : 'Penerimaan piutang sebesar Rp ${CurrencyFormatter.format(amount)} berhasil dicatat!',
              ),
              backgroundColor: isPayable ? AppColors.expense : AppColors.income,
            ),
          );
        } else {
          final error = ref.read(debtControllerProvider).error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal mencatat pembayaran: ${error ?? "Terjadi kesalahan"}'),
              backgroundColor: AppColors.expense,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(activeRegularWalletsStreamProvider);
    final themeColor = isPayable ? AppColors.expense : AppColors.primary;
    final actionTitle = isPayable ? 'Bayar / Cicil Utang' : 'Terima Pembayaran Piutang';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      actionTitle,
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.grey),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Info Box: Sisa Tagihan & Judul
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.neutral,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.debt.title,
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.secondary,
                            ),
                          ),
                          if (widget.contact != null)
                            Text(
                              widget.contact!.name,
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Sisa yang harus ${isPayable ? "dibayar" : "diterima"}:',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            'Rp ${CurrencyFormatter.format(remaining)}',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: themeColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Input Nominal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildLabel('Nominal Pembayaran (Rp) *'),
                    GestureDetector(
                      onTap: _setFullPayment,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: themeColor.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Bayar Lunas',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: themeColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: themeColor,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    prefixText: 'Rp ',
                    prefixStyle: GoogleFonts.jetBrainsMono(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: themeColor,
                    ),
                    filled: true,
                    fillColor: AppColors.neutral,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: themeColor, width: 2),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Nominal wajib diisi';
                    final num = double.tryParse(val.replaceAll(RegExp(r'[^0-9]'), ''));
                    if (num == null || num <= 0) return 'Nominal tidak valid';
                    if (num > remaining + 0.01) return 'Melebihi sisa tagihan';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Pilih Dompet
                _buildLabel(
                  isPayable ? 'Pilih Dompet Sumber Dana *' : 'Pilih Dompet Penampung Dana *',
                ),
                const SizedBox(height: 8),
                walletsAsync.when(
                  data: (wallets) {
                    if (wallets.isEmpty) {
                      return const Text('Belum ada dompet aktif.');
                    }
                    _selectedWalletSyncId ??= wallets.first.syncId;

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
                          items: wallets.map((w) {
                            return DropdownMenuItem<String>(
                              value: w.syncId,
                              child: Row(
                                children: [
                                  const Icon(Icons.account_balance_wallet_rounded,
                                      size: 18, color: AppColors.primary),
                                  const SizedBox(width: 10),
                                  Text(
                                    w.name,
                                    style: GoogleFonts.hankenGrotesk(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Rp ${CurrencyFormatter.format(w.balance)}',
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
                const SizedBox(height: 16),

                // Tanggal Pembayaran
                _buildLabel('Tanggal Pembayaran'),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.neutral,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Text(
                          DateFormatter.formatShortDate(_selectedDate),
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
                const SizedBox(height: 16),

                // Catatan Pembayaran
                _buildLabel('Catatan (Opsional)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    hintText: 'Contoh: Cicilan ke-1 / Transfer BCA',
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
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : Text(
                            'Simpan Pembayaran',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
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
      style: GoogleFonts.hankenGrotesk(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.secondary,
      ),
    );
  }
}
