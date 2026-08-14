import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/budget_repository.dart';

class BudgetCard extends StatelessWidget {
  final CategoryBudgetUsage usage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const BudgetCard({
    super.key,
    required this.usage,
    required this.onEdit,
    required this.onDelete,
  });

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

  Color _getStatusColor(BudgetStatus status) {
    switch (status) {
      case BudgetStatus.overbudget:
        return AppColors.expense;
      case BudgetStatus.warning:
        return const Color(0xFFF59E0B); // Amber warning
      case BudgetStatus.safe:
        return AppColors.income;
    }
  }

  String _getStatusLabel(BudgetStatus status, double remaining) {
    switch (status) {
      case BudgetStatus.overbudget:
        return 'Overbudget ${CurrencyFormatter.format(remaining.abs())}';
      case BudgetStatus.warning:
        return 'Sisa ${CurrencyFormatter.format(remaining)} (Hampir Habis)';
      case BudgetStatus.safe:
        return 'Sisa ${CurrencyFormatter.format(remaining)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(usage.status);
    final progressValue = (usage.percentage / 100).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: usage.status == BudgetStatus.overbudget
            ? Border.all(color: AppColors.expense.withValues(alpha: 0.4), width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Category Icon, Name, and Popup Menu (Edit/Delete)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color(usage.categoryColor).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIconData(usage.categoryIcon),
                  color: Color(usage.categoryColor),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usage.categoryName,
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
                      _getStatusLabel(usage.status, usage.remainingAmount),
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Percentage Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${usage.percentage.toStringAsFixed(1)}%',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.grey, size: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (val) {
                  if (val == 'edit') onEdit();
                  if (val == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18, color: AppColors.secondary),
                        SizedBox(width: 8),
                        Text('Edit Batas'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.expense),
                        SizedBox(width: 8),
                        Text('Hapus Anggaran', style: TextStyle(color: AppColors.expense)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progressValue,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),

          // Spent & Limit Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Terpakai',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyFormatter.format(usage.spentAmount),
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Batas Anggaran',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyFormatter.format(usage.limitAmount),
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
