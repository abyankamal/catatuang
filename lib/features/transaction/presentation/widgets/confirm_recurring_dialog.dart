import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../application/recurring_transaction_controller.dart';
import '../../domain/recurring_transaction.dart';

/// Dialog konfirmasi untuk pencatatan transaksi rutin manual.
/// Menyediakan kemampuan verifikasi/penyesuaian nominal (misal tagihan bervariasi),
/// opsi lewati siklus, dan pembatalan dengan manajemen lifecycle TextEditingController yang bersih.
class ConfirmRecurringDialog extends ConsumerStatefulWidget {
  final RecurringTransaction recurring;
  final BuildContext? parentContext;

  const ConfirmRecurringDialog({
    super.key,
    required this.recurring,
    this.parentContext,
  });

  /// Menampilkan dialog konfirmasi transaksi berulang
  static Future<void> show(
    BuildContext context, {
    required RecurringTransaction recurring,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => ConfirmRecurringDialog(
        recurring: recurring,
        parentContext: context,
      ),
    );
  }

  /// Format tampilan awal nominal:
  /// Jika bilangan bulat (contoh: 250000.0) -> '250000'
  /// Jika desimal (contoh: 150.5) -> '150,5'
  static String formatInitialAmount(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.toInt().toString();
    }
    return amount.toString().replaceAll('.', ',');
  }

  /// Mem-parsing input nominal dari pengguna secara adaptif:
  /// - Format ribuan Indonesia: '250.000' -> 250000.0, '1.250.000' -> 1250000.0
  /// - Format desimal koma: '150,5' -> 150.5, '150000,75' -> 150000.75
  /// - Format desimal titik: '150.5' -> 150.5, '150.50' -> 150.5
  /// - Format gabungan titik ribuan & koma desimal: '150.000,50' -> 150000.5
  static double? parseAmount(String? text) {
    if (text == null) return null;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.contains(',')) {
      final normalized = trimmed.replaceAll('.', '').replaceAll(',', '.');
      return double.tryParse(normalized);
    }

    final dotCount = '.'.allMatches(trimmed).length;
    if (dotCount == 0) {
      return double.tryParse(trimmed);
    } else if (dotCount > 1) {
      return double.tryParse(trimmed.replaceAll('.', ''));
    } else {
      final parts = trimmed.split('.');
      final integerPart = parts[0];
      final fractionalPart = parts[1];

      if (integerPart == '0' || integerPart == '-0') {
        return double.tryParse(trimmed);
      }

      if (fractionalPart.length == 3 && integerPart.isNotEmpty && integerPart.length <= 3) {
        return double.tryParse(trimmed.replaceAll('.', ''));
      }

      return double.tryParse(trimmed);
    }
  }

  @override
  ConsumerState<ConfirmRecurringDialog> createState() => _ConfirmRecurringDialogState();
}

class _ConfirmRecurringDialogState extends ConsumerState<ConfirmRecurringDialog> {
  late final TextEditingController _amountController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: ConfirmRecurringDialog.formatInitialAmount(widget.recurring.amount),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handleSkip() async {
    final messenger = (widget.parentContext != null && widget.parentContext!.mounted)
        ? ScaffoldMessenger.of(widget.parentContext!)
        : ScaffoldMessenger.of(context);
    Navigator.pop(context);

    final success = await ref
        .read(recurringTransactionControllerProvider.notifier)
        .skipCurrentCycle(widget.recurring.syncId);

    if (messenger.mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Siklus transaksi berhasil dilewati.'
                : 'Gagal melewati siklus.',
          ),
          backgroundColor: success ? AppColors.secondary : AppColors.expense,
        ),
      );
    }
  }

  Future<void> _handleConfirm() async {
    if (!_formKey.currentState!.validate()) return;
    final parsed = ConfirmRecurringDialog.parseAmount(_amountController.text);
    if (parsed == null) return;

    final messenger = (widget.parentContext != null && widget.parentContext!.mounted)
        ? ScaffoldMessenger.of(widget.parentContext!)
        : ScaffoldMessenger.of(context);
    Navigator.pop(context);

    final success = await ref
        .read(recurringTransactionControllerProvider.notifier)
        .confirmExecution(
          widget.recurring.syncId,
          customAmount: parsed,
        );

    if (messenger.mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Transaksi rutin berhasil dicatat!'
                : 'Gagal mencatat transaksi rutin.',
          ),
          backgroundColor: success ? AppColors.income : AppColors.expense,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.edit_calendar_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Catat Transaksi Rutin',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.recurring.description?.isNotEmpty == true
                  ? widget.recurring.description!
                  : 'Transaksi Terjadwal',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Jatuh tempo: ${DateFormatter.formatFullDate(widget.recurring.nextDueDate)}',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Nominal',
                prefixText: 'Rp ',
                helperText: 'Sesuaikan nominal jika terdapat perubahan tagihan.',
                helperMaxLines: 2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nominal tidak boleh kosong';
                }
                final parsed = ConfirmRecurringDialog.parseAmount(value);
                if (parsed == null || parsed <= 0) {
                  return 'Nominal harus lebih dari 0';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Batal',
            style: GoogleFonts.manrope(color: Colors.grey.shade600),
          ),
        ),
        TextButton(
          onPressed: _handleSkip,
          child: Text(
            'Lewati',
            style: GoogleFonts.manrope(color: Colors.orange.shade800),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: _handleConfirm,
          child: Text(
            'Catat Sekarang',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
