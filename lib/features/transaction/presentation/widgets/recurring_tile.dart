import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/recurring_schedule_helper.dart';
import '../../domain/recurring_transaction.dart';

class RecurringTile extends StatelessWidget {
  final RecurringTransaction recurring;
  final String? walletName;
  final String? targetWalletName;
  final String? categoryName;
  final VoidCallback? onDelete;
  final ValueChanged<bool>? onToggleActive;

  const RecurringTile({
    super.key,
    required this.recurring,
    this.walletName,
    this.targetWalletName,
    this.categoryName,
    this.onDelete,
    this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = recurring.type == 'EXPENSE';
    final isIncome = recurring.type == 'INCOME';
    final isTransfer = recurring.type == 'TRANSFER';

    final Color typeColor = isExpense
        ? AppColors.expense
        : isIncome
            ? AppColors.income
            : AppColors.primary;

    final IconData typeIcon = isExpense
        ? Icons.arrow_outward_rounded
        : isIncome
            ? Icons.arrow_downward_rounded
            : Icons.swap_horiz_rounded;

    final String typeLabel = isExpense
        ? 'Pengeluaran'
        : isIncome
            ? 'Pemasukan'
            : 'Transfer';

    final frequencyLabel = RecurringScheduleHelper.formatFrequency(
      recurring.frequency,
      recurring.interval,
    );

    // Status display
    final isCompleted = recurring.isCompleted;
    final isActive = recurring.isActive;

    final Color statusBg = isCompleted
        ? Colors.grey.shade100
        : isActive
            ? Colors.green.shade50
            : Colors.amber.shade50;

    final Color statusColor = isCompleted
        ? Colors.grey.shade700
        : isActive
            ? Colors.green.shade700
            : Colors.amber.shade800;

    final String statusText = isCompleted
        ? 'Selesai'
        : isActive
            ? 'Aktif'
            : 'Dijeda';

    final description = (recurring.description != null &&
            recurring.description!.trim().isNotEmpty)
        ? recurring.description!.trim()
        : 'Transaksi Rutin';

    // Dompet display text
    final String walletDisplay;
    if (isTransfer) {
      walletDisplay =
          '${walletName ?? 'Dompet'} → ${targetWalletName ?? 'Tujuan'}';
    } else {
      walletDisplay = [
        walletName ?? 'Dompet',
        if (categoryName != null && categoryName!.isNotEmpty) categoryName,
      ].join(' • ');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted
              ? Colors.grey.shade200
              : isActive
                  ? Colors.grey.shade100
                  : Colors.amber.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(4),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Badges & Status
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Type Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: typeColor.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(typeIcon, size: 13, color: typeColor),
                            const SizedBox(width: 4),
                            Text(
                              typeLabel,
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: typeColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Frequency Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          frequencyLabel,
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),

                      // Execution Mode Badge (Otomatis vs Manual)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: recurring.autoExecute
                              ? AppColors.primary.withAlpha(15)
                              : Colors.orange.withAlpha(15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              recurring.autoExecute
                                  ? Icons.bolt_rounded
                                  : Icons.touch_app_rounded,
                              size: 13,
                              color: recurring.autoExecute
                                  ? AppColors.primary
                                  : Colors.orange.shade800,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              recurring.autoExecute ? 'Otomatis' : 'Manual',
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: recurring.autoExecute
                                    ? AppColors.primary
                                    : Colors.orange.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Row 2: Title and Amount
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        description,
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isCompleted
                              ? Colors.grey.shade600
                              : AppColors.secondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              walletDisplay,
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.format(recurring.amount),
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? Colors.grey.shade500 : typeColor,
                      ),
                    ),
                    if (isTransfer &&
                        recurring.adminFee != null &&
                        recurring.adminFee! > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        '+ Biaya ${CurrencyFormatter.format(recurring.adminFee!)}',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Row 3: Next Due Date & Controls
            Row(
              children: [
                Icon(
                  Icons.event_outlined,
                  size: 15,
                  color: isCompleted
                      ? Colors.grey.shade400
                      : AppColors.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isCompleted
                        ? 'Siklus telah berakhir'
                        : 'Jatuh tempo: ${DateFormatter.formatFullDate(recurring.nextDueDate)}',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 12,
                      fontWeight:
                          isCompleted ? FontWeight.normal : FontWeight.w600,
                      color: isCompleted
                          ? Colors.grey.shade500
                          : AppColors.secondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  iconSize: 20,
                  color: Colors.grey.shade500,
                  tooltip: 'Hapus Jadwal',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onDelete,
                ),
                const SizedBox(width: 12),
                Tooltip(
                  message: isCompleted
                      ? 'Jadwal yang sudah selesai tidak dapat diaktifkan kembali'
                      : (isActive ? 'Jeda jadwal' : 'Aktifkan jadwal'),
                  child: Switch.adaptive(
                    value: isActive,
                    activeTrackColor: AppColors.primary,
                    onChanged: isCompleted ? null : onToggleActive,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
