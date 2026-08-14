import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../contact/domain/contact.dart';
import '../../domain/debt.dart';

class DebtCard extends StatelessWidget {
  final Debt debt;
  final Contact? contact;
  final VoidCallback onPayTap;
  final VoidCallback onEditTap;
  final VoidCallback onDeleteTap;

  const DebtCard({
    super.key,
    required this.debt,
    this.contact,
    required this.onPayTap,
    required this.onEditTap,
    required this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPayable = debt.type == 'PAYABLE';
    final remaining = (debt.totalAmount - debt.paidAmount).clamp(0.0, debt.totalAmount);
    final progress = debt.totalAmount > 0
        ? (debt.paidAmount / debt.totalAmount).clamp(0.0, 1.0)
        : 0.0;
    final isCompleted = debt.paidAmount >= debt.totalAmount;

    final now = DateTime.now();
    final isOverdue = !isCompleted &&
        debt.dueDate != null &&
        now.isAfter(debt.dueDate!);

    final primaryThemeColor = isPayable ? AppColors.expense : AppColors.primary;
    final typeLabel = isPayable ? 'Utang Saya' : 'Piutang Saya';
    final contactName = contact?.name ?? 'Tanpa Kontak';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOverdue ? AppColors.expense.withAlpha(60) : Colors.grey.shade100,
          width: isOverdue ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
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
            // Top Row: Type Badge + Due Date Badge + More Actions
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPayable
                        ? AppColors.expense.withAlpha(20)
                        : AppColors.income.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPayable ? Icons.arrow_outward_rounded : Icons.arrow_downward_rounded,
                        size: 14,
                        color: isPayable ? AppColors.expense : AppColors.income,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        typeLabel,
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isPayable ? AppColors.expense : AppColors.income,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Status Badge (Overdue / Completed / Due Date)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: isCompleted
                        ? Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Lunas 🎉',
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                          )
                        : isOverdue
                            ? Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.expense.withAlpha(20),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.warning_amber_rounded, size: 12, color: AppColors.expense),
                                      const SizedBox(width: 3),
                                      Text(
                                        'Lewat Tempo',
                                        style: GoogleFonts.manrope(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.expense,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : debt.dueDate != null
                                ? Text(
                                    'Tempo: ${DateFormatter.formatShortDate(debt.dueDate!)}',
                                    style: GoogleFonts.hankenGrotesk(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : const SizedBox.shrink(),
                  ),
                ),

                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: Colors.grey, size: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onSelected: (val) {
                    if (val == 'edit') {
                      onEditTap();
                    } else if (val == 'delete') {
                      onDeleteTap();
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text('Edit', style: GoogleFonts.hankenGrotesk()),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.expense),
                          const SizedBox(width: 8),
                          Text('Hapus', style: GoogleFonts.hankenGrotesk(color: AppColors.expense)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Title & Contact Info
            Text(
              debt.title,
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.person_outline_rounded, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  contactName,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                if (debt.notes != null && debt.notes!.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text('•', style: TextStyle(color: Colors.grey.shade400)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      debt.notes!,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppColors.neutral,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isCompleted ? Colors.green : primaryThemeColor,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Amounts Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCompleted ? 'Total Pokok' : 'Sisa Tagihan',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isCompleted
                            ? CurrencyFormatter.format(debt.totalAmount)
                            : CurrencyFormatter.format(remaining),
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isCompleted
                              ? Colors.green.shade700
                              : (isPayable ? AppColors.expense : AppColors.secondary),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Terbayar / Total',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${CurrencyFormatter.format(debt.paidAmount)} / ${CurrencyFormatter.format(debt.totalAmount)}',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (!isCompleted) ...[
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 38,
                child: ElevatedButton.icon(
                  onPressed: onPayTap,
                  icon: Icon(
                    isPayable ? Icons.payment_rounded : Icons.move_to_inbox_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: Text(
                    isPayable ? 'Bayar / Cicil Utang' : 'Terima Pembayaran',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPayable ? AppColors.expense : AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
