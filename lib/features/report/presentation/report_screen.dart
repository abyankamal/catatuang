import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../core/theme/app_theme.dart';
import '../application/report_providers.dart';
import '../data/csv_report_service.dart';
import '../data/pdf_report_service.dart';
import '../data/report_repository.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  String _selectedType = 'EXPENSE'; // 'EXPENSE' or 'INCOME'

  static const List<String> _monthsIndonesian = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  static const List<Color> _chartColors = [
    Color(0xFF5D5CFF), // Brand Primary
    Color(0xFF10B981), // Green
    Color(0xFFF59E0B), // Amber
    Color(0xFFEC4899), // Pink
    Color(0xFF8B5CF6), // Purple
    Color(0xFF06B6D4), // Cyan
    Color(0xFFEF4444), // Red
    Color(0xFF64748B), // Slate
  ];

  String _formatCurrency(double amount) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return currencyFormatter.format(amount);
  }

  void _showMonthPicker(BuildContext context, WidgetRef ref, ReportFilterState currentFilter) {
    int tempYear = currentFilter.year;
    int tempMonth = currentFilter.month;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pilih Periode',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () {
                            setModalState(() {
                              tempYear--;
                            });
                          },
                        ),
                        Text(
                          '$tempYear',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () {
                            setModalState(() {
                              tempYear++;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 2.5,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        final isSelected = (index + 1) == tempMonth;
                        return InkWell(
                          onTap: () {
                            setModalState(() {
                              tempMonth = index + 1;
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _monthsIndonesian[index],
                              style: GoogleFonts.outfit(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          ref
                              .read(reportFilterProvider.notifier)
                              .setMonth(tempYear, tempMonth);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Terapkan',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _exportPdf(ReportFilterState filter) async {
    try {
      final detailedReport = await ref
          .read(reportRepositoryProvider)
          .getDetailedMonthlyReport(filter.year, filter.month);

      await Printing.layoutPdf(
        name: 'Laporan_Keuangan_${_monthsIndonesian[filter.month - 1]}_${filter.year}',
        onLayout: (PdfPageFormat format) async {
          return await PdfReportService.generatePdf(detailedReport);
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengekspor laporan PDF: $e'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    }
  }

  Future<void> _exportCsv({required bool allTime, required ReportFilterState filter}) async {
    try {
      final repo = ref.read(reportRepositoryProvider);
      final List<DetailedTransactionItem> transactions;
      final String fileName;

      if (allTime) {
        transactions = await repo.getAllTransactionsForExport();
        fileName = 'CatatUang_Semua_Transaksi_${DateTime.now().year}.csv';
      } else {
        final detailed = await repo.getDetailedMonthlyReport(filter.year, filter.month);
        transactions = detailed.transactions;
        fileName = 'CatatUang_Transaksi_${_monthsIndonesian[filter.month - 1]}_${filter.year}.csv';
      }

      if (transactions.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak ada catatan transaksi untuk diekspor.'),
              backgroundColor: AppColors.secondary,
            ),
          );
        }
        return;
      }

      final csvBytes = await CsvReportService.generateCsvBytes(transactions);

      await Printing.sharePdf(
        bytes: csvBytes,
        filename: fileName,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengekspor CSV: $e'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    }
  }

  void _showExportOptionsSheet(BuildContext context, ReportFilterState filter) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ekspor Laporan Keuangan',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pilih format berkas yang Anda inginkan',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 20),

                // Option 1: PDF Visual Report
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 24),
                  ),
                  title: Text(
                    'Laporan PDF (Visual & Cetak)',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: AppColors.secondary),
                  ),
                  subtitle: Text(
                    'Periode ${_monthsIndonesian[filter.month - 1]} ${filter.year} lengkap dengan tabel dan rekap',
                    style: GoogleFonts.hankenGrotesk(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pop(context);
                    _exportPdf(filter);
                  },
                ),
                const Divider(height: 24),

                // Option 2: CSV Month
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.table_chart_rounded, color: Colors.green, size: 24),
                  ),
                  title: Text(
                    'Spreadsheet CSV (Bulan Ini)',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: AppColors.secondary),
                  ),
                  subtitle: Text(
                    'Data transaksi bulan ${_monthsIndonesian[filter.month - 1]} ${filter.year} untuk Excel / Sheets',
                    style: GoogleFonts.hankenGrotesk(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pop(context);
                    _exportCsv(allTime: false, filter: filter);
                  },
                ),
                const SizedBox(height: 8),

                // Option 3: CSV All Time
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.file_download_outlined, color: Colors.blue, size: 24),
                  ),
                  title: Text(
                    'Spreadsheet CSV (Semua Transaksi)',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: AppColors.secondary),
                  ),
                  subtitle: Text(
                    'Seluruh riwayat transaksi (Full Backup) untuk pengolahan spreadsheet',
                    style: GoogleFonts.hankenGrotesk(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pop(context);
                    _exportCsv(allTime: true, filter: filter);
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(reportFilterProvider);
    final reportAsync = ref.watch(monthlyReportProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Laporan & Grafik',
          style: GoogleFonts.outfit(
            color: AppColors.secondary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: AppColors.primary),
            tooltip: 'Ekspor Laporan (PDF / CSV)',
            onPressed: () => _showExportOptionsSheet(context, filter),
          ),
        ],
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Month Selector Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: InkWell(
              onTap: () => _showMonthPicker(context, ref, filter),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withAlpha(40)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_month, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${_monthsIndonesian[filter.month - 1]} ${filter.year}',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: reportAsync.when(
              skipLoadingOnReload: true,
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Terjadi kesalahan: $err',
                    style: GoogleFonts.outfit(color: AppColors.expense),
                  ),
                ),
              ),
              data: (report) {
                if (report.totalIncome == 0 && report.totalExpense == 0) {
                  return _buildEmptyState();
                }

                final currentCategories = _selectedType == 'EXPENSE'
                    ? report.categoryExpenses
                    : report.categoryIncomes;
                final currentTotal = _selectedType == 'EXPENSE'
                    ? report.totalExpense
                    : report.totalIncome;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Financial Summary Cards
                      _buildSummaryCards(report),

                      const SizedBox(height: 20),

                      // Toggle Button (Pengeluaran vs Pemasukan)
                      Row(
                        children: [
                          Expanded(
                            child: _buildTypeToggleItem(
                              label: 'Pengeluaran',
                              type: 'EXPENSE',
                              activeColor: AppColors.expense,
                              icon: Icons.arrow_upward_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTypeToggleItem(
                              label: 'Pemasukan',
                              type: 'INCOME',
                              activeColor: AppColors.income,
                              icon: Icons.arrow_downward_rounded,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Donut Chart Card
                      if (currentTotal > 0) ...[
                        _buildChartCard(
                          categories: currentCategories,
                          totalAmount: currentTotal,
                          type: _selectedType,
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Category Breakdown Section
                      if (currentCategories.isNotEmpty) ...[
                        Text(
                          _selectedType == 'EXPENSE'
                              ? 'Pengeluaran per Kategori'
                              : 'Pemasukan per Kategori',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildCategoryList(currentCategories),
                      ] else if (currentTotal == 0) ...[
                        Card(
                          elevation: 0,
                          margin: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Center(
                              child: Text(
                                _selectedType == 'EXPENSE'
                                    ? 'Tidak ada pengeluaran pada periode ini.'
                                    : 'Tidak ada pemasukan pada periode ini.',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () => _exportPdf(filter),
                          icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary),
                          label: Text(
                            'Export Laporan PDF (${_monthsIndonesian[filter.month - 1]} ${filter.year})',
                            style: GoogleFonts.outfit(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeToggleItem({
    required String label,
    required String type,
    required Color activeColor,
    required IconData icon,
  }) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withAlpha(20) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? activeColor : Colors.grey.shade500,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? activeColor : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(MonthlyReportData report) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _summaryItem(
                  'Pemasukan',
                  _formatCurrency(report.totalIncome),
                  AppColors.income,
                  Icons.arrow_downward,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey.shade200,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: _summaryItem(
                    'Pengeluaran',
                    _formatCurrency(report.totalExpense),
                    AppColors.expense,
                    Icons.arrow_upward,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sisa Bersih (Net)',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                _formatCurrency(report.netIncome),
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: report.netIncome >= 0 ? AppColors.income : AppColors.expense,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, Color color, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildChartCard({
    required List<CategoryExpenseSummary> categories,
    required double totalAmount,
    required String type,
  }) {
    final sections = List.generate(categories.length, (index) {
      final item = categories[index];
      final color = _chartColors[index % _chartColors.length];
      return PieChartSectionData(
        color: color,
        value: item.totalAmount,
        title: '${item.percentage.toStringAsFixed(0)}%',
        radius: 28,
        titleStyle: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });

    final isExpense = type == 'EXPENSE';

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              isExpense ? 'Persentase Pengeluaran' : 'Persentase Pemasukan',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: Stack(
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 60,
                      sections: sections,
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isExpense ? 'Total Out' : 'Total In',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatCurrency(totalAmount),
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isExpense ? AppColors.expense : AppColors.income,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList(List<CategoryExpenseSummary> categories) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          indent: 16,
          endIndent: 16,
          color: Colors.grey.shade100,
        ),
        itemBuilder: (context, index) {
          final item = categories[index];
          final color = _chartColors[index % _chartColors.length];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.categoryName,
                              style: GoogleFonts.outfit(
                                fontSize: 15,
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
                    const SizedBox(width: 12),
                    Row(
                      children: [
                        Text(
                          _formatCurrency(item.totalAmount),
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${item.percentage.toStringAsFixed(1)}%',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (item.percentage / 100).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Data Laporan',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Belum ada transaksi pengeluaran atau pemasukan yang dicatat pada periode ini.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
