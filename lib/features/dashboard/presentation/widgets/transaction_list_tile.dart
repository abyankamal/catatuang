import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../category/domain/category.dart';
import '../../../transaction/domain/transaction.dart';

class TransactionListTile extends StatelessWidget {
  final Transaction transaction;
  final Category? category;
  final String walletName;
  final DateTime? lockedUntil;
  final VoidCallback? onTap;

  const TransactionListTile({
    super.key,
    required this.transaction,
    this.category,
    required this.walletName,
    this.lockedUntil,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked = lockedUntil != null && !transaction.date.isAfter(lockedUntil!);

    // Semantic colors based on transaction type
    Color amountColor;
    String prefix;
    IconData defaultIcon;

    switch (transaction.type) {
      case 'INCOME':
        amountColor = AppColors.income;
        prefix = '+';
        defaultIcon = Icons.arrow_downward_rounded;
        break;
      case 'TRANSFER_IN':
        amountColor = AppColors.transfer;
        prefix = '+';
        defaultIcon = Icons.swap_horiz_rounded;
        break;
      case 'TRANSFER_OUT':
        amountColor = AppColors.transfer;
        prefix = '-';
        defaultIcon = Icons.swap_horiz_rounded;
        break;
      case 'EXPENSE':
      default:
        amountColor = AppColors.expense;
        prefix = '-';
        defaultIcon = Icons.arrow_upward_rounded;
        break;
    }

    final categoryName = category?.name ?? (transaction.type.contains('TRANSFER') ? 'Transfer' : 'Lainnya');
    final iconData = _getIconData(category?.icon) ?? defaultIcon;
    final isCategoryActive = category?.isActive ?? true;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Category Icon container
              Stack(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: category?.colorValue != null
                          ? Color(category!.colorValue).withAlpha(30)
                          : amountColor.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      iconData,
                      color: category?.colorValue != null
                          ? Color(category!.colorValue)
                          : amountColor,
                      size: 22,
                    ),
                  ),
                  if (isLocked)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),

              // Title and date/wallet
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            categoryName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isCategoryActive ? const Color(0xFF0F172A) : Colors.grey.shade500,
                              decoration: isCategoryActive ? TextDecoration.none : TextDecoration.lineThrough,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${DateFormatter.formatShortDate(transaction.date)} • $walletName',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$prefix${CurrencyFormatter.format(transaction.amount)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: amountColor,
                    ),
                  ),
                  if (transaction.description != null && transaction.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      transaction.description!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData? _getIconData(String? iconName) {
    if (iconName == null) return null;
    switch (iconName) {
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_car':
        return Icons.directions_car;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'receipt':
        return Icons.receipt;
      case 'swap_horiz':
        return Icons.swap_horiz;
      case 'payments':
        return Icons.payments;
      case 'card_giftcard':
        return Icons.card_giftcard;
      case 'trending_up':
        return Icons.trending_up;
      default:
        return Icons.category;
    }
  }
}
