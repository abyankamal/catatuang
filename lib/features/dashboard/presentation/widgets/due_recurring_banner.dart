import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../transaction/application/recurring_transaction_controller.dart';
import '../../../transaction/domain/recurring_transaction.dart';

/// Banner di Beranda untuk transaksi terjadwal manual yang jatuh tempo hari ini atau terlewat.
class DueRecurringBanner extends ConsumerWidget {
  const DueRecurringBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dueAsync = ref.watch(dueManualRecurringProvider);

    return dueAsync.maybeWhen(
      skipLoadingOnReload: true,
      data: (dueItems) {
        if (dueItems.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final item in dueItems) ...[
                _DueRecurringCard(recurring: item),
                if (item != dueItems.last) const SizedBox(height: 10),
              ],
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _DueRecurringCard extends ConsumerWidget {
  final RecurringTransaction recurring;

  const _DueRecurringCard({required this.recurring});

  bool _isOverdue(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return dueDay.isBefore(today);
  }

  Future<void> _showConfirmDialog(BuildContext context, WidgetRef ref) async {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController(
      text: recurring.amount.toInt() == recurring.amount
          ? recurring.amount.toInt().toString()
          : recurring.amount.toString(),
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
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
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recurring.description?.isNotEmpty == true
                      ? recurring.description!
                      : 'Transaksi Terjadwal',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Jatuh tempo: ${DateFormatter.formatFullDate(recurring.nextDueDate)}',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
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
                    final parsed = double.tryParse(value.replaceAll('.', '').replaceAll(',', '.'));
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
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Batal',
                style: GoogleFonts.manrope(color: Colors.grey.shade600),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                final success = await ref
                    .read(recurringTransactionControllerProvider.notifier)
                    .skipCurrentCycle(recurring.syncId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
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
              },
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
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final parsed = double.parse(
                  amountController.text.replaceAll('.', '').replaceAll(',', '.'),
                );
                Navigator.pop(dialogContext);

                final success = await ref
                    .read(recurringTransactionControllerProvider.notifier)
                    .confirmExecution(
                      recurring.syncId,
                      customAmount: parsed,
                    );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
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
              },
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
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overdue = _isOverdue(recurring.nextDueDate);
    final isIncome = recurring.type == 'INCOME';
    final isTransfer = recurring.type == 'TRANSFER';

    final badgeText = overdue ? 'TERLEWAT' : 'HARI INI';
    final badgeColor = overdue ? AppColors.expense : const Color(0xFFEA580C);

    final title = recurring.description?.isNotEmpty == true
        ? recurring.description!
        : (isIncome ? 'Pemasukan Rutin' : (isTransfer ? 'Transfer Rutin' : 'Pengeluaran Rutin'));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: overdue ? AppColors.expense.withValues(alpha: 0.3) : const Color(0xFFEA580C).withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header badge & due date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badgeText,
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: badgeColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Jadwal Rutin Jatuh Tempo',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              Text(
                DateFormatter.formatFullDate(recurring.nextDueDate),
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title & Amount
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isIncome ? AppColors.income : (isTransfer ? AppColors.primary : AppColors.expense))
                      .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isIncome
                      ? Icons.arrow_downward_rounded
                      : (isTransfer ? Icons.swap_horiz_rounded : Icons.calendar_today_rounded),
                  color: isIncome ? AppColors.income : (isTransfer ? AppColors.primary : AppColors.expense),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(recurring.amount),
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isIncome ? AppColors.income : AppColors.expense,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () async {
                  final success = await ref
                      .read(recurringTransactionControllerProvider.notifier)
                      .skipCurrentCycle(recurring.syncId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
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
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Lewati',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _showConfirmDialog(context, ref),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                label: Text(
                  'Catat Sekarang',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
