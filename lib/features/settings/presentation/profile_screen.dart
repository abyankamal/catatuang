import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../dashboard/application/dashboard_providers.dart';
import '../data/app_settings_repository.dart';

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

    // Load initial settings if available
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final settings = await ref.read(appSettingsRepositoryProvider).getOrInitSettings();
      if (mounted) {
        setState(() {
          _nameController.text = settings.userName ?? '';
          if (settings.avatarIcon != null && settings.avatarIcon!.isNotEmpty) {
            _selectedAvatar = settings.avatarIcon!;
          }
        });
      }
    });
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
      await ref.read(appSettingsRepositoryProvider).updateProfile(
            userName: _nameController.text.trim(),
            avatarIcon: _selectedAvatar,
          );
      ref.invalidate(appSettingsStreamProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui!'),
            backgroundColor: AppColors.income,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui profil: $e'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          'Tindakan ini akan menghapus SELURUH data dompet, transaksi, kategori, dan target tabungan Anda dari aplikasi ini secara permanen.\n\nApakah Anda yakin?',
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
        await ref.read(appSettingsRepositoryProvider).clearAllData();
        
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
          context.go('/dashboard');
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Profil Saya',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary),
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
                  const Text(
                    'Pilih Ikon Profil',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
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
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nama Pengguna',
                            style: TextStyle(
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
                                  : const Text(
                                      'Simpan Perubahan',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Pengaturan Lanjutan
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pengaturan Lanjutan',
                          style: TextStyle(
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
                          title: const Text(
                            'Manajemen Dompet',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary),
                          ),
                          subtitle: const Text('Tambah, edit, atau hapus dompet'),
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.secondary),
                          onTap: () => context.push('/wallets'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Danger Zone (Reset Data)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.expenseLight,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
