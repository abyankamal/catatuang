import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../dashboard/application/dashboard_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  String _selectedAvatar = 'person';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _avatarOptions = [
    {'id': 'person', 'icon': Icons.person_rounded},
    {'id': 'face', 'icon': Icons.face_rounded},
    {'id': 'account_circle', 'icon': Icons.account_circle_rounded},
    {'id': 'work', 'icon': Icons.work_rounded},
    {'id': 'savings', 'icon': Icons.savings_rounded},
    {'id': 'pets', 'icon': Icons.pets_rounded},
    {'id': 'star', 'icon': Icons.star_rounded},
    {'id': 'emoji_emotions', 'icon': Icons.emoji_emotions_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final success = await ref.read(settingsControllerProvider.notifier).updateProfile(
            userName: _nameController.text.trim(),
            avatarIcon: _selectedAvatar,
          );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil berhasil diperbarui!'),
              backgroundColor: AppColors.income,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal memperbarui profil.'),
              backgroundColor: AppColors.expense,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showLockPeriodSheet(DateTime? currentLockedUntil) async {
    final now = DateTime.now();
    // Akhir bulan lalu: Hari terakhir dari bulan sebelumnya
    final lastDayOfPrevMonth = DateTime(now.year, now.month, 0);

    final action = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_clock_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pilih Tanggal Tutup Buku',
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Transaksi pada atau sebelum tanggal ini akan dikunci.',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
                title: Text(
                  'Akhir Bulan Lalu',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: AppColors.secondary),
                ),
                subtitle: Text(
                  DateFormatter.formatFullDate(lastDayOfPrevMonth),
                  style: GoogleFonts.hankenGrotesk(color: Colors.grey.shade600),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.pop(context, 'last_month'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_available_rounded, color: AppColors.secondary),
                title: Text(
                  'Pilih Tanggal Kustom',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: AppColors.secondary),
                ),
                subtitle: Text(
                  'Tentukan tanggal spesifik penutupan buku',
                  style: GoogleFonts.hankenGrotesk(color: Colors.grey.shade600),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.pop(context, 'custom'),
              ),
            ],
          ),
        ),
      ),
    );

    if (action == null) return;

    DateTime? selectedDate;
    if (action == 'last_month') {
      selectedDate = lastDayOfPrevMonth;
    } else if (action == 'custom') {
      if (!mounted) return;
      final initialDate = currentLockedUntil ?? lastDayOfPrevMonth;
      final picked = await showDatePicker(
        context: context,
        initialDate: initialDate.isAfter(now) ? now : initialDate,
        firstDate: DateTime(2020),
        lastDate: now,
        helpText: 'Pilih Tanggal Batas Tutup Buku',
      );
      if (picked != null) {
        selectedDate = picked;
      }
    }

    if (selectedDate != null) {
      setState(() => _isLoading = true);
      try {
        final success = await ref
            .read(settingsControllerProvider.notifier)
            .setLockedUntil(selectedDate);

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Tutup Buku berhasil diaktifkan hingga ${DateFormatter.formatFullDate(selectedDate)}.',
                ),
                backgroundColor: AppColors.income,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Gagal mengaktifkan Tutup Buku.'),
                backgroundColor: AppColors.expense,
              ),
            );
          }
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmUnlockPeriod() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_open_rounded, color: AppColors.primary, size: 28),
            SizedBox(width: 8),
            Text('Buka Kunci Periode?'),
          ],
        ),
        content: const Text(
          'Setelah kunci dibuka, Anda dapat kembali menambahkan, mengedit, atau menghapus transaksi pada periode lampau.\n\nApakah Anda ingin melanjutkan?',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Buka Kunci'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final success = await ref.read(settingsControllerProvider.notifier).unlockPeriod();

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Kunci Tutup Buku telah dibuka. Semua periode bebas diedit.'),
                backgroundColor: AppColors.income,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Gagal membuka kunci Tutup Buku.'),
                backgroundColor: AppColors.expense,
              ),
            );
          }
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmResetData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.expense, size: 28),
            SizedBox(width: 8),
            Text('Reset Semua Data?'),
          ],
        ),
        content: const Text(
          'Tindakan ini akan menghapus SELURUH data dompet, transaksi, kategori, kontak, utang, dan target tabungan Anda dari aplikasi ini secara permanen.\n\nApakah Anda yakin?',
          style: TextStyle(height: 1.4),
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
            child: const Text('Ya, Hapus Semua'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await ref.read(settingsControllerProvider.notifier).clearAllData();

        // Refresh all providers
        ref.invalidate(activeWalletsStreamProvider);
        ref.invalidate(activeCategoriesStreamProvider);
        ref.invalidate(recentTransactionsStreamProvider);
        ref.invalidate(dashboardSummaryProvider);
        ref.invalidate(appSettingsStreamProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Seluruh data berhasil dihapus.'),
              backgroundColor: AppColors.secondary,
            ),
          );
          context.go('/onboarding');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal mereset data: $e'),
              backgroundColor: AppColors.expense,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  IconData _getIconData(String iconName) {
    final found = _avatarOptions.firstWhere(
      (opt) => opt['id'] == iconName,
      orElse: () => _avatarOptions.first,
    );
    return found['icon'] as IconData;
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(appSettingsStreamProvider);
    final settings = settingsAsync.valueOrNull;

    // Inisialisasi controller text & avatar jika belum diubah
    if (_nameController.text.isEmpty && settings?.userName != null) {
      _nameController.text = settings!.userName!;
    }
    if (settings?.avatarIcon != null && settings!.avatarIcon!.isNotEmpty && _selectedAvatar == 'person') {
      _selectedAvatar = settings.avatarIcon!;
    }

    final lockedUntil = settings?.lockedUntil;
    final isLocked = lockedUntil != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Profil & Pengaturan',
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: AppColors.secondary),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.secondary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Selected Big Avatar
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(30),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _getIconData(_selectedAvatar),
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Avatar Picker Options
                  Text(
                    'Pilih Ikon Profil',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: _avatarOptions.map((opt) {
                      final isSelected = opt['id'] == _selectedAvatar;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedAvatar = opt['id']),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppColors.primary : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            opt['icon'] as IconData,
                            size: 24,
                            color: isSelected ? Colors.white : Colors.grey.shade700,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),

                  // Form Input Name
                  Form(
                    key: _formKey,
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nama Pengguna',
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                hintText: 'Masukkan nama Anda (misal: Abyan)',
                                prefixIcon: const Icon(Icons.person_outline_rounded),
                                filled: true,
                                fillColor: AppColors.neutral,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Nama tidak boleh kosong';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _saveProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        'Simpan Perubahan',
                                        style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Card Tutup Buku (Period Locking)
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isLocked ? Colors.amber.shade300 : Colors.grey.shade100,
                          width: isLocked ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isLocked
                                      ? Colors.amber.withAlpha(30)
                                      : AppColors.primary.withAlpha(20),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                                  color: isLocked ? Colors.amber.shade900 : AppColors.primary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tutup Buku (Kunci Periode)',
                                      style: GoogleFonts.manrope(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isLocked
                                          ? 'Terkunci s.d. ${DateFormatter.formatFullDate(lockedUntil)}'
                                          : 'Periode Bebas Edit (Tidak Terkunci)',
                                      style: GoogleFonts.hankenGrotesk(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isLocked ? Colors.amber.shade900 : AppColors.income,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            isLocked
                                ? 'Transaksi pada atau sebelum tanggal batas telah dikunci untuk melindungi laporan keuangan Anda dari perubahan atau penghapusan yang tidak disengaja.'
                                : 'Kunci periode masa lalu untuk membekukan pembukuan keuangan dan mencegah perubahan data secara tidak sengaja.',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (isLocked) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _isLoading ? null : _confirmUnlockPeriod,
                                    icon: const Icon(Icons.lock_open_rounded, size: 16, color: AppColors.secondary),
                                    label: Text(
                                      'Buka Kunci',
                                      style: GoogleFonts.manrope(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: Colors.grey.shade300),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _isLoading ? null : () => _showLockPeriodSheet(lockedUntil),
                                    icon: const Icon(Icons.edit_calendar_rounded, size: 16, color: Colors.white),
                                    label: Text(
                                      'Ubah Tanggal',
                                      style: GoogleFonts.manrope(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : () => _showLockPeriodSheet(null),
                                icon: const Icon(Icons.lock_outline_rounded, size: 18, color: Colors.white),
                                label: Text(
                                  'Kunci Periode Sekarang',
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Pengaturan Lanjutan
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pengaturan Lanjutan',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(20),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary),
                            ),
                            title: Text(
                              'Manajemen Dompet',
                              style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: AppColors.secondary),
                            ),
                            subtitle: Text('Tambah, edit, atau hapus dompet', style: GoogleFonts.hankenGrotesk()),
                            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.secondary),
                            onTap: () => context.push('/wallets'),
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.orange.withAlpha(20),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.category_rounded, color: Colors.orange),
                            ),
                            title: Text(
                              'Manajemen Kategori',
                              style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: AppColors.secondary),
                            ),
                            subtitle: Text('Kelola kategori pemasukan & pengeluaran', style: GoogleFonts.hankenGrotesk()),
                            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.secondary),
                            onTap: () => context.push('/categories'),
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.indigo.withAlpha(20),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.handshake_outlined, color: Colors.indigo),
                            ),
                            title: Text(
                              'Utang & Piutang',
                              style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: AppColors.secondary),
                            ),
                            subtitle: Text('Kelola catatan pinjaman & hak tagih', style: GoogleFonts.hankenGrotesk()),
                            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.secondary),
                            onTap: () => context.push('/debts'),
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.purple.withAlpha(20),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.pie_chart_rounded, color: Colors.purple),
                            ),
                            title: Text(
                              'Anggaran Bulanan',
                              style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: AppColors.secondary),
                            ),
                            subtitle: Text('Batas pengeluaran per kategori', style: GoogleFonts.hankenGrotesk()),
                            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.secondary),
                            onTap: () => context.push('/budgets'),
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.teal.withAlpha(20),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.contacts_rounded, color: Colors.teal),
                            ),
                            title: Text(
                              'Buku Kontak',
                              style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: AppColors.secondary),
                            ),
                            subtitle: Text('Kelola daftar relasi & pihak peminjam', style: GoogleFonts.hankenGrotesk()),
                            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.secondary),
                            onTap: () => context.push('/contacts'),
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            activeThumbColor: AppColors.primary,
                            secondary: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blueGrey.withAlpha(20),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.blur_on_rounded, color: Colors.blueGrey),
                            ),
                            title: Text(
                              'Privasi Layar (Blur)',
                              style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: AppColors.secondary),
                            ),
                            subtitle: Text(
                              'Samarkan tampilan saat membuka recent apps',
                              style: GoogleFonts.hankenGrotesk(),
                            ),
                            value: settings?.isPrivacyScreenEnabled ?? true,
                            onChanged: (val) {
                              ref.read(settingsControllerProvider.notifier).setPrivacyScreenEnabled(val);
                            },
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            activeThumbColor: AppColors.primary,
                            secondary: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.deepOrange.withAlpha(20),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.notifications_active_rounded, color: Colors.deepOrange),
                            ),
                            title: Text(
                              'Pengingat Utang & Piutang',
                              style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: AppColors.secondary),
                            ),
                            subtitle: Text(
                              'Peringatan otomatis jatuh tempo tagihan & pinjaman',
                              style: GoogleFonts.hankenGrotesk(),
                            ),
                            value: settings?.isDebtReminderEnabled ?? true,
                            onChanged: (val) {
                              ref.read(settingsControllerProvider.notifier).setDebtReminderEnabled(val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Danger Zone (Reset Data)
                  Material(
                    color: AppColors.expenseLight,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.expense.withAlpha(60)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.delete_forever_rounded, color: AppColors.expense, size: 22),
                              SizedBox(width: 8),
                              Text(
                                'Zona Bahaya',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.expense,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Fitur ini akan mengosongkan seluruh database aplikasi (dompet, transaksi, target) untuk menguji situasi pengguna baru (Empty State).',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _isLoading ? null : _confirmResetData,
                              icon: const Icon(Icons.restart_alt_rounded, color: AppColors.expense),
                              label: const Text(
                                'Reset / Hapus Semua Data',
                                style: TextStyle(
                                  color: AppColors.expense,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.expense),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
