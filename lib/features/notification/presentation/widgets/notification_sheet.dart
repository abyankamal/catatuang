import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../application/notification_providers.dart';
import '../../domain/app_notification.dart';

class NotificationSheet extends ConsumerWidget {
  const NotificationSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NotificationSheet(),
    );
  }

  Color _getUrgencyColor(NotificationUrgency urgency) {
    switch (urgency) {
      case NotificationUrgency.overdue:
        return AppColors.expense;
      case NotificationUrgency.dueToday:
        return const Color(0xFFEA580C); // Oranye menyala
      case NotificationUrgency.upcoming:
        return const Color(0xFFF59E0B); // Kuning amber
    }
  }

  String _getUrgencyBadge(NotificationUrgency urgency) {
    switch (urgency) {
      case NotificationUrgency.overdue:
        return 'TERLEWAT';
      case NotificationUrgency.dueToday:
        return 'HARI INI';
      case NotificationUrgency.upcoming:
        return 'MENDATANG';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(activeRemindersProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pusat Pengingat',
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                      Text(
                        'Jatuh tempo utang & tagihan piutang',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content
          Expanded(
            child: remindersAsync.when(
              skipLoadingOnReload: true,
              data: (reminders) {
                if (reminders.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.income.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 54,
                              color: AppColors.income,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Semua Tagihan Beres!',
                            style: GoogleFonts.manrope(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tidak ada kewajiban utang atau penagihan piutang yang mendesak saat ini.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  itemCount: reminders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = reminders[index];
                    final urgencyColor = _getUrgencyColor(item.urgency);
                    final isPayable = item.type == 'PAYABLE';

                    return InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/debts');
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: item.urgency == NotificationUrgency.overdue
                                ? AppColors.expense.withValues(alpha: 0.4)
                                : Colors.grey.shade200,
                            width: item.urgency == NotificationUrgency.overdue ? 1.5 : 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header badge & date
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: urgencyColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _getUrgencyBadge(item.urgency),
                                    style: GoogleFonts.manrope(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: urgencyColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Jatuh Tempo: ${DateFormatter.formatFullDate(item.dueDate)}',
                                    style: GoogleFonts.hankenGrotesk(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Title & Description
                            Text(
                              item.title,
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.message,
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 12,
                                color: Colors.black87,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Amount & Action Button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Sisa Tagihan',
                                      style: GoogleFonts.hankenGrotesk(
                                        fontSize: 10,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                    Text(
                                      CurrencyFormatter.format(item.remainingAmount),
                                      style: GoogleFonts.manrope(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isPayable ? AppColors.expense : AppColors.income,
                                      ),
                                    ),
                                  ],
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    context.push('/debts');
                                  },
                                  icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                                  label: Text(
                                    isPayable ? 'Bayar' : 'Tagih',
                                    style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (err, _) => Center(
                child: Text('Gagal memuat pengingat: $err'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
