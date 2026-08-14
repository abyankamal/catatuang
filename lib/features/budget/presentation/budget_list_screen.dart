import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../application/budget_providers.dart';
import '../data/budget_repository.dart';
import 'widgets/budget_card.dart';
import 'widgets/budget_form_sheet.dart';

class BudgetListScreen extends ConsumerStatefulWidget {
  const BudgetListScreen({super.key});

  @override
  ConsumerState<BudgetListScreen> createState() => _BudgetListScreenState();
}

class _BudgetListScreenState extends ConsumerState<BudgetListScreen> {
  static const List<String> _monthsIndonesian = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember'
  ];

  void _showMonthPicker(BuildContext context, WidgetRef ref, BudgetFilterState currentFilter) {
    int tempYear = currentFilter.year;
    int tempMonth = currentFilter.month;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag Handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header with Year Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pilih Periode Anggaran',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left_rounded),
                            onPressed: () => setModalState(() => tempYear--),
                          ),
                          Text(
                            tempYear.toString(),
                            style: GoogleFonts.manrope(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right_rounded),
                            onPressed: () => setModalState(() => tempYear++),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Months Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.2,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      final monthNum = index + 1;
                      final isSelected = monthNum == tempMonth;

                      return InkWell(
                        onTap: () {
                          setModalState(() => tempMonth = monthNum);
                          ref.read(budgetFilterProvider.notifier).state =
                              BudgetFilterState(year: tempYear, month: tempMonth);
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _monthsIndonesian[index],
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openAddOrEditForm({CategoryBudgetUsage? usage, required int year, required int month}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BudgetFormSheet(
        existingUsage: usage,
        year: year,
        month: month,
      ),
    );
  }

  Future<void> _confirmDeleteBudget(CategoryBudgetUsage usage) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: AppColors.expense, size: 28),
            SizedBox(width: 8),
            Text('Hapus Anggaran?'),
          ],
        ),
        content: Text(
          'Anggaran untuk kategori "${usage.categoryName}" akan dihapus dari bulan ini.',
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref.read(budgetControllerProvider.notifier).deleteBudget(usage.budget.id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Anggaran berhasil dihapus.'),
              backgroundColor: AppColors.income,
            ),
          );
        } else {
          final error = ref.read(budgetControllerProvider).error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus anggaran: ${error ?? "Terjadi kesalahan"}'),
              backgroundColor: AppColors.expense,
            ),
          );
        }
      }
    }
  }

  Future<void> _copyFromPreviousMonth(int currentYear, int currentMonth) async {
    final prevDate = DateTime(currentYear, currentMonth, 1).subtract(const Duration(days: 1));
    final prevYear = prevDate.year;
    final prevMonth = prevDate.month;

    final copied = await ref.read(budgetControllerProvider.notifier).copyBudgetsFromPreviousMonth(
          fromYear: prevYear,
          fromMonth: prevMonth,
          toYear: currentYear,
          toMonth: currentMonth,
        );

    if (mounted) {
      if (copied > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil menyalin $copied anggaran dari bulan ${_monthsIndonesian[prevMonth - 1]}.'),
            backgroundColor: AppColors.income,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tidak ada anggaran aktif di bulan ${_monthsIndonesian[prevMonth - 1]} untuk disalin.'),
            backgroundColor: AppColors.secondary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(budgetFilterProvider);
    final summaryAsync = ref.watch(monthlyBudgetSummaryProvider);

    final monthLabel = '${_monthsIndonesian[filter.month - 1]} ${filter.year}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Anggaran Bulanan',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded, color: AppColors.primary),
            tooltip: 'Salin dari bulan lalu',
            onPressed: () => _copyFromPreviousMonth(filter.year, filter.month),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(monthlyBudgetSummaryProvider);
          ref.invalidate(activeBudgetsStreamProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month Selector Bar
              GestureDetector(
                onTap: () => _showMonthPicker(context, ref, filter),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        monthLabel,
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Summary Overview Card
              summaryAsync.when(
                skipLoadingOnReload: true,
                data: (summary) {
                  if (summary.items.isEmpty) {
                    return _buildEmptyState(filter.year, filter.month);
                  }
                  return Column(
                    children: [
                      _buildSummaryCard(summary),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Kategori Terdaftar (${summary.items.length})',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _openAddOrEditForm(year: filter.year, month: filter.month),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Tambah'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: summary.items.length,
                        itemBuilder: (context, index) {
                          final item = summary.items[index];
                          return BudgetCard(
                            usage: item,
                            onEdit: () => _openAddOrEditForm(
                              usage: item,
                              year: filter.year,
                              month: filter.month,
                            ),
                            onDelete: () => _confirmDeleteBudget(item),
                          );
                        },
                      ),
                      const SizedBox(height: 80),
                    ],
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.expenseLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text('Gagal memuat anggaran: $err'),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddOrEditForm(year: filter.year, month: filter.month),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Atur Anggaran',
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(MonthlyBudgetSummary summary) {
    Color statusColor;
    String statusText;

    switch (summary.overallStatus) {
      case BudgetStatus.overbudget:
        statusColor = AppColors.expense;
        statusText = 'Overbudget Total';
        break;
      case BudgetStatus.warning:
        statusColor = const Color(0xFFF59E0B);
        statusText = 'Peringatan Pemakaian';
        break;
      case BudgetStatus.safe:
        statusColor = AppColors.income;
        statusText = 'Pemakaian Aman';
        break;
    }

    final progress = (summary.totalPercentage / 100).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Total Anggaran Bulan Ini',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
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
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(summary.totalBudgetLimit),
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 16),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 16),

          // Detailed 2-column stats
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Terpakai (${summary.totalPercentage.toStringAsFixed(1)}%)',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.format(summary.totalBudgetSpent),
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sisa Anggaran',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.format(summary.totalBudgetRemaining),
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(int year, int month) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pie_chart_outline_rounded,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Belum Ada Anggaran',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Atur batas pengeluaran untuk setiap kategori agar keuanganmu tetap terkontrol.',
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _openAddOrEditForm(year: year, month: month),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Buat Anggaran Sekarang'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
