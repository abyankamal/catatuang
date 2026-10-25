import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/recurring_schedule_helper.dart';

/// Widget pemilih opsi transaksi berulang pada form transaksi.
/// Memungkinkan pemilihan frekuensi, interval pengulangan, mode eksekusi (otomatis vs manual),
/// serta tanggal batas akhir opsional.
class RecurringIntervalPicker extends StatelessWidget {
  final bool isRecurring;
  final ValueChanged<bool> onRecurringChanged;
  final String frequency;
  final ValueChanged<String> onFrequencyChanged;
  final int interval;
  final ValueChanged<int> onIntervalChanged;
  final bool autoExecute;
  final ValueChanged<bool> onAutoExecuteChanged;
  final DateTime? endDate;
  final ValueChanged<DateTime?> onEndDateChanged;
  final Color themeColor;

  const RecurringIntervalPicker({
    super.key,
    required this.isRecurring,
    required this.onRecurringChanged,
    required this.frequency,
    required this.onFrequencyChanged,
    required this.interval,
    required this.onIntervalChanged,
    required this.autoExecute,
    required this.onAutoExecuteChanged,
    required this.endDate,
    required this.onEndDateChanged,
    this.themeColor = AppColors.primary,
  });

  String _getFrequencyLabel(String freq) {
    switch (freq.toUpperCase()) {
      case 'DAILY':
        return 'Harian';
      case 'WEEKLY':
        return 'Mingguan';
      case 'MONTHLY':
        return 'Bulanan';
      case 'YEARLY':
        return 'Tahunan';
      default:
        return 'Bulanan';
    }
  }

  String _getIntervalUnit(String freq, int step) {
    switch (freq.toUpperCase()) {
      case 'DAILY':
        return 'Hari';
      case 'WEEKLY':
        return 'Minggu';
      case 'MONTHLY':
        return 'Bulan';
      case 'YEARLY':
        return 'Tahun';
      default:
        return 'Siklus';
    }
  }

  Future<void> _pickEndDate(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = endDate ?? now.add(const Duration(days: 30));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(now) ? now : initialDate,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
      helpText: 'Pilih Tanggal Batas Akhir Pengulangan',
    );

    if (picked != null) {
      onEndDateChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.neutral,
        borderRadius: BorderRadius.circular(16),
        border: isRecurring
            ? Border.all(color: themeColor.withValues(alpha: 0.3), width: 1.5)
            : null,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Toggle
          InkWell(
            onTap: () => onRecurringChanged(!isRecurring),
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isRecurring
                        ? themeColor.withValues(alpha: 0.15)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.update_rounded,
                    color: isRecurring ? themeColor : Colors.grey.shade600,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jadikan Transaksi Berulang',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                      Text(
                        'Jadwalkan pencatatan otomatis atau rutin',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: isRecurring,
                  onChanged: onRecurringChanged,
                  activeTrackColor: themeColor,
                ),
              ],
            ),
          ),

          if (isRecurring) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),

            // Pilihan Frekuensi
            Text(
              'Frekuensi Pengulangan',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final freq in ['DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY']) ...[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: InkWell(
                        onTap: () => onFrequencyChanged(freq),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: frequency == freq
                                ? themeColor
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: frequency == freq
                                  ? themeColor
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _getFrequencyLabel(freq),
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: frequency == freq
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: frequency == freq
                                    ? Colors.white
                                    : AppColors.secondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Interval Stepper
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ulangi Setiap',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Setiap $interval ${_getIntervalUnit(frequency, interval)} sekali',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_rounded, size: 18),
                        onPressed: interval > 1
                            ? () => onIntervalChanged(interval - 1)
                            : null,
                        color: themeColor,
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          '$interval',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_rounded, size: 18),
                        onPressed: interval < 99
                            ? () => onIntervalChanged(interval + 1)
                            : null,
                        color: themeColor,
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Ringkasan Frekuensi
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 14, color: themeColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${RecurringScheduleHelper.formatFrequency(frequency, interval)} mulai tanggal transaksi.',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 11,
                        color: themeColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Toggle Mode Eksekusi (Otomatis vs Manual)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    autoExecute
                        ? Icons.bolt_rounded
                        : Icons.notifications_active_outlined,
                    color: autoExecute ? const Color(0xFFEA580C) : themeColor,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          autoExecute ? 'Eksekusi Otomatis' : 'Konfirmasi Manual',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                        Text(
                          autoExecute
                              ? 'Saldo dipotong otomatis saat jadwal tiba'
                              : 'Muncul banner & pengingat untuk persetujuan',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: autoExecute,
                    onChanged: onAutoExecuteChanged,
                    activeTrackColor: const Color(0xFFEA580C),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Batas Berakhir (Opsional)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event_busy_rounded,
                    color: Colors.grey.shade600,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      endDate == null
                          ? 'Batas Akhir: Selamanya (Tanpa Batas)'
                          : 'Batas Akhir: ${endDate!.day}/${endDate!.month}/${endDate!.year}',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                  if (endDate == null)
                    TextButton(
                      onPressed: () => _pickEndDate(context),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        'Atur',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: themeColor,
                        ),
                      ),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16),
                      onPressed: () => onEndDateChanged(null),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Hapus Batas Akhir',
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
