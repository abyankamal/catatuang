import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/utils/currency_formatter.dart';
import 'report_repository.dart';

class PdfReportService {
  static const List<String> _monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  static final DateFormat _dateFormat = DateFormat('d MMM yyyy, HH:mm', 'id_ID');

  static String _formatRupiah(double amount) {
    return CurrencyFormatter.format(amount);
  }

  static String _formatDate(DateTime date) {
    return _dateFormat.format(date);
  }


  static String _formatShortDate(DateTime date) {
    return DateFormat('d MMM yyyy', 'id_ID').format(date);
  }

  static Future<Uint8List> generatePdf(DetailedMonthlyReport data) async {
    final pdf = pw.Document(
      title: 'Laporan Keuangan CatatUang - ${_monthNames[data.month - 1]} ${data.year}',
      author: data.userName,
    );

    final periodStr = '${_monthNames[data.month - 1]} ${data.year}';
    final generatedDateStr = _formatDate(DateTime.now());

    final primaryColor = PdfColor.fromHex('#5D5CFF');
    final incomeColor = PdfColor.fromHex('#10B981');
    final expenseColor = PdfColor.fromHex('#EF4444');
    final neutralBg = PdfColor.fromHex('#F8FAFC');
    final darkTextColor = PdfColor.fromHex('#1E293B');
    final subTextColor = PdfColor.fromHex('#64748B');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 12),
            margin: const pw.EdgeInsets.only(bottom: 16),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  children: [
                    pw.Container(
                      width: 28,
                      height: 28,
                      decoration: pw.BoxDecoration(
                        color: primaryColor,
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        'CU',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      'CatatUang',
                      style: pw.TextStyle(
                        color: primaryColor,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                pw.Text(
                  'Laporan Keuangan Bulanan',
                  style: pw.TextStyle(
                    color: subTextColor,
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(top: 12),
            margin: const pw.EdgeInsets.only(top: 16),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey300, width: 1),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Dibuat otomatis oleh CatatUang App pada $generatedDateStr',
                  style: pw.TextStyle(color: subTextColor, fontSize: 9),
                ),
                pw.Text(
                  'Halaman ${context.pageNumber} dari ${context.pagesCount}',
                  style: pw.TextStyle(color: subTextColor, fontSize: 9),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // Title & Meta Section
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Laporan Periode $periodStr',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: darkTextColor,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Pengguna: ${data.userName}',
                      style: pw.TextStyle(fontSize: 12, color: subTextColor),
                    ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: neutralBg,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Text(
                    'Dicetak: $generatedDateStr',
                    style: pw.TextStyle(fontSize: 10, color: subTextColor),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Executive Summary Box
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: neutralBg,
                borderRadius: pw.BorderRadius.circular(12),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'TOTAL PEMASUKAN',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: subTextColor,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        _formatRupiah(data.summary.totalIncome),
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: incomeColor,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(width: 1, height: 32, color: PdfColors.grey300),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'TOTAL PENGELUARAN',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: subTextColor,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        _formatRupiah(data.summary.totalExpense),
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: expenseColor,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(width: 1, height: 32, color: PdfColors.grey300),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'ARUS KAS BERSIH (NET)',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: subTextColor,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        _formatRupiah(data.summary.netIncome),
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: data.summary.netIncome >= 0 ? incomeColor : expenseColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Category Breakdown Table
            if (data.summary.categoryExpenses.isNotEmpty) ...[
              pw.Text(
                'Pengeluaran per Kategori',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: darkTextColor,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(4),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: neutralBg),
                    children: [
                      _buildTableHeader('Kategori'),
                      _buildTableHeader('Total Pengeluaran', alignRight: true),
                      _buildTableHeader('Porsi (%)', alignRight: true),
                    ],
                  ),
                  ...data.summary.categoryExpenses.map((cat) {
                    return pw.TableRow(
                      children: [
                        _buildTableCell(cat.categoryName),
                        _buildTableCell(_formatRupiah(cat.totalAmount), alignRight: true),
                        _buildTableCell('${cat.percentage.toStringAsFixed(1)}%', alignRight: true),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 20),
            ],

            // Wallet Balances Summary Table
            if (data.wallets.isNotEmpty) ...[
              pw.Text(
                'Rekapitulasi Saldo Dompet',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: darkTextColor,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(4),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FlexColumnWidth(3),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: neutralBg),
                    children: [
                      _buildTableHeader('Nama Dompet'),
                      _buildTableHeader('Tipe'),
                      _buildTableHeader('Saldo Terkini', alignRight: true),
                    ],
                  ),
                  ...data.wallets.map((w) {
                    return pw.TableRow(
                      children: [
                        _buildTableCell(w.name),
                        _buildTableCell(w.isGoal ? 'Target Tabungan' : 'Dompet Reguler'),
                        _buildTableCell(_formatRupiah(w.balance), alignRight: true),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 24),
            ],

            // Transaction Details List Table
            pw.Text(
              'Rincian Seluruh Transaksi (${data.transactions.length} Transaksi)',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: darkTextColor,
              ),
            ),
            pw.SizedBox(height: 8),
            if (data.transactions.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'Tidak ada catatan transaksi pada periode ini.',
                  style: pw.TextStyle(color: subTextColor, fontSize: 11),
                ),
              )
            else
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2.2),
                  1: const pw.FlexColumnWidth(2.5),
                  2: const pw.FlexColumnWidth(2.2),
                  3: const pw.FlexColumnWidth(3),
                  4: const pw.FlexColumnWidth(1.8),
                  5: const pw.FlexColumnWidth(2.8),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: neutralBg),
                    children: [
                      _buildTableHeader('Tanggal'),
                      _buildTableHeader('Kategori'),
                      _buildTableHeader('Dompet'),
                      _buildTableHeader('Catatan'),
                      _buildTableHeader('Tipe'),
                      _buildTableHeader('Nominal', alignRight: true),
                    ],
                  ),
                  ...data.transactions.map((tx) {
                    final isIncome = tx.type == 'INCOME';
                    final isExpense = tx.type == 'EXPENSE';

                    final typeLabel = isIncome
                        ? 'Masuk'
                        : isExpense
                            ? 'Keluar'
                            : 'Transfer';

                    final nominalColor = isIncome
                        ? incomeColor
                        : isExpense
                            ? expenseColor
                            : primaryColor;

                    return pw.TableRow(
                      children: [
                        _buildTableCell(_formatShortDate(tx.date)),
                        _buildTableCell(tx.categoryName),
                        _buildTableCell(tx.walletName),
                        _buildTableCell(tx.notes ?? '-'),
                        _buildTableCell(typeLabel),
                        _buildTableCell(
                          _formatRupiah(tx.amount),
                          alignRight: true,
                          textColor: nominalColor,
                          isBold: true,
                        ),
                      ],
                    );
                  }),
                ],
              ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildTableHeader(String title, {bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        title,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromHex('#334155'),
        ),
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool alignRight = false,
    PdfColor? textColor,
    bool isBold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 8.5,
          color: textColor ?? PdfColor.fromHex('#1E293B'),
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
