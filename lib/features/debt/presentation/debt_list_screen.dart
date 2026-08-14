import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../contact/application/contact_providers.dart';
import '../../contact/domain/contact.dart';
import '../application/debt_providers.dart';
import '../domain/debt.dart';
import 'widgets/debt_card.dart';
import 'widgets/debt_payment_bottom_sheet.dart';

class DebtListScreen extends ConsumerStatefulWidget {
  const DebtListScreen({super.key});

  @override
  ConsumerState<DebtListScreen> createState() => _DebtListScreenState();
}

class _DebtListScreenState extends ConsumerState<DebtListScreen> {
  void _openPaymentModal(Debt debt, Contact? contact) {
    DebtPaymentBottomSheet.show(
      context,
      debt: debt,
      contact: contact,
    );
  }

  void _confirmDelete(Debt debt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Hapus Catatan?',
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus catatan "${debt.title}"?',
          style: GoogleFonts.hankenGrotesk(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.hankenGrotesk(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref
                  .read(debtControllerProvider.notifier)
                  .deleteDebt(debt.id);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Catatan berhasil dihapus.' : 'Gagal menghapus catatan.',
                    ),
                    backgroundColor: success ? AppColors.secondary : AppColors.expense,
                  ),
                );
              }
            },
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
  }

  @override
  Widget build(BuildContext context) {
    final typeFilter = ref.watch(debtTypeFilterProvider);
    final statusFilter = ref.watch(debtStatusFilterProvider);
    final debtsAsync = ref.watch(activeDebtsStreamProvider);
    final summaryAsync = ref.watch(debtSummaryProvider);
    final contactsAsync = ref.watch(activeContactsStreamProvider);

    // Build contacts lookup map
    final Map<String, Contact> contactMap = {};
    contactsAsync.whenData((contacts) {
      for (final c in contacts) {
        contactMap[c.syncId] = c;
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Utang & Piutang',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.secondary),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.contacts_rounded, color: AppColors.primary),
            tooltip: 'Buku Kontak',
            onPressed: () => context.push('/contacts'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Summary Card Banner
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: summaryAsync.when(
                skipLoadingOnReload: true,
                loading: () => const SizedBox(
                  height: 90,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text('Error: $e'),
                data: (summary) => _buildSummaryBanner(summary),
              ),
            ),

            // Type Filter Tabs (Semua / Utang / Piutang)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabItem('Semua', 'ALL', typeFilter),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTabItem('Utang Saya', 'PAYABLE', typeFilter),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTabItem('Piutang Saya', 'RECEIVABLE', typeFilter),
                  ),
                ],
              ),
            ),

            // Status Filter Chips (Semua, Belum Lunas, Jatuh Tempo, Lunas)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildStatusChip('Semua Status', 'ALL', statusFilter),
                    const SizedBox(width: 8),
                    _buildStatusChip('Belum Lunas', 'UNPAID', statusFilter),
                    const SizedBox(width: 8),
                    _buildStatusChip('Jatuh Tempo', 'OVERDUE', statusFilter),
                    const SizedBox(width: 8),
                    _buildStatusChip('Lunas', 'COMPLETED', statusFilter),
                  ],
                ),
              ),
            ),

            const Divider(height: 1),

            // Debts List View
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(activeDebtsStreamProvider);
                  ref.invalidate(debtSummaryProvider);
                },
                child: debtsAsync.when(
                  skipLoadingOnReload: true,
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(
                    child: Text('Gagal memuat catatan: $e', style: const TextStyle(color: AppColors.expense)),
                  ),
                  data: (debts) {
                    final now = DateTime.now();

                    // Apply client-side status filter
                    final filtered = debts.where((d) {
                      final isCompleted = d.paidAmount >= d.totalAmount;
                      final isOverdue = !isCompleted && d.dueDate != null && now.isAfter(d.dueDate!);

                      switch (statusFilter) {
                        case 'UNPAID':
                          return !isCompleted;
                        case 'OVERDUE':
                          return isOverdue;
                        case 'COMPLETED':
                          return isCompleted;
                        case 'ALL':
                        default:
                          return true;
                      }
                    }).toList();

                    if (filtered.isEmpty) {
                      return _buildEmptyState(typeFilter, statusFilter);
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final debt = filtered[index];
                        final contact = contactMap[debt.contactSyncId];

                        return DebtCard(
                          debt: debt,
                          contact: contact,
                          onPayTap: () => _openPaymentModal(debt, contact),
                          onEditTap: () => context.push('/debts/edit', extra: debt),
                          onDeleteTap: () => _confirmDelete(debt),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/debts/add'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Catat Utang / Piutang',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryBanner(DebtSummary summary) {
    return Row(
      children: [
        // Utang Card (Kewajiban)
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.expense.withAlpha(12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.expense.withAlpha(30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.arrow_outward_rounded, size: 14, color: AppColors.expense),
                    const SizedBox(width: 4),
                    Text(
                      'Sisa Utang Saya',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Rp ${CurrencyFormatter.format(summary.remainingPayable)}',
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.expense,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Piutang Card (Hak/Tagihan)
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.income.withAlpha(12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.income.withAlpha(30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.arrow_downward_rounded, size: 14, color: AppColors.income),
                    const SizedBox(width: 4),
                    Text(
                      'Sisa Piutang Saya',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Rp ${CurrencyFormatter.format(summary.remainingReceivable)}',
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.income,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabItem(String label, String type, String activeType) {
    final isSelected = type == activeType;
    return GestureDetector(
      onTap: () => ref.read(debtTypeFilterProvider.notifier).state = type,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.neutral,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, String status, String activeStatus) {
    final isSelected = status == activeStatus;
    return GestureDetector(
      onTap: () => ref.read(debtStatusFilterProvider.notifier).state = status,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.secondary : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String typeFilter, String statusFilter) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.neutral,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.assignment_turned_in_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak Ada Catatan',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              statusFilter != 'ALL' || typeFilter != 'ALL'
                  ? 'Tidak ada catatan yang sesuai dengan filter yang dipilih.'
                  : 'Belum ada catatan utang atau piutang yang aktif.\nKetuk tombol di bawah untuk mencatat.',
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => context.push('/debts/add'),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Catat Sekarang'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
