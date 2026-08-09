import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';

class HeroBalanceCard extends StatelessWidget {
  final double totalBalance;
  final double monthlyIncome;
  final double monthlyExpense;
  final DateTime? lockedUntil;
  final VoidCallback? onAddTap;
  final VoidCallback? onScanTap;

  const HeroBalanceCard({
    super.key,
    required this.totalBalance,
    required this.monthlyIncome,
    required this.monthlyExpense,
    this.lockedUntil,
    this.onAddTap,
    this.onScanTap,
  });

  @override
  Widget build(BuildContext context) {
    final isNegative = totalBalance < 0;
    final formattedBalance = CurrencyFormatter.format(totalBalance);
    
    // Split formatted string for styled decimal/thousands if needed
    String mainPart = formattedBalance;
    String endPart = '';
    if (formattedBalance.length > 4) {
      endPart = formattedBalance.substring(formattedBalance.length - 4);
      mainPart = formattedBalance.substring(0, formattedBalance.length - 4);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Saldo',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (lockedUntil != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber.withAlpha(80)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_rounded, size: 12, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        'Tutup Buku: ${DateFormatter.formatShortDate(lockedUntil!)}',
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Big formatted Balance
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: mainPart,
                  style: TextStyle(
                    color: isNegative ? AppColors.expense : AppColors.secondary,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                if (endPart.isNotEmpty)
                  TextSpan(
                    text: endPart,
                    style: TextStyle(
                      color: isNegative ? AppColors.expense : AppColors.primary.withAlpha(180),
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Income and Expense Mini Cards
          Row(
            children: [
              Expanded(
                child: _buildStatChip(
                  label: 'PEMASUKAN',
                  amount: monthlyIncome,
                  color: AppColors.income,
                  isIncome: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatChip(
                  label: 'PENGELUARAN',
                  amount: monthlyExpense,
                  color: AppColors.expense,
                  isIncome: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.grey.shade100, height: 1),
          const SizedBox(height: 20),

          // Pill Action Button inside the card
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAddTap ?? () {},
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Tambah Transaksi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required String label,
    required double amount,
    required Color color,
    required bool isIncome,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.neutral,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200.withAlpha(120)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isIncome ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                size: 12,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${isIncome ? '+' : '-'}${CurrencyFormatter.formatCompact(amount)}',
            style: const TextStyle(
              color: AppColors.secondary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
