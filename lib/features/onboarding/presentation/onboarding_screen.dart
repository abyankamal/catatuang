import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../application/onboarding_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _walletNameController;
  late TextEditingController _balanceController;

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
    _walletNameController = TextEditingController(text: 'Dompet Utama');
    _balanceController = TextEditingController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _walletNameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  IconData _getIconData(String iconName) {
    final found = _avatarOptions.firstWhere(
      (opt) => opt['id'] == iconName,
      orElse: () => _avatarOptions.first,
    );
    return found['icon'] as IconData;
  }

  void _nextPage() {
    final state = ref.read(onboardingControllerProvider);
    if (state.currentStep == 0) {
      if (!_step1FormKey.currentState!.validate()) return;
      ref.read(onboardingControllerProvider.notifier).setUserName(_nameController.text.trim());
    } else if (state.currentStep == 1) {
      if (!_step2FormKey.currentState!.validate()) return;
      ref.read(onboardingControllerProvider.notifier).setWalletName(_walletNameController.text.trim());
      
      final cleanText = _balanceController.text.replaceAll('.', '').replaceAll(',', '').trim();
      final balance = double.tryParse(cleanText) ?? 0.0;
      ref.read(onboardingControllerProvider.notifier).setInitialBalance(balance);
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _prevPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finish() async {
    final success = await ref.read(onboardingControllerProvider.notifier).finishOnboarding();
    if (mounted) {
      if (success) {
        try {
          context.go('/dashboard');
        } catch (_) {
          // Fallback if GoRouter is not attached in testing environment
          Navigator.of(context).maybePop();
        }
      } else {
        final error = ref.read(onboardingControllerProvider).errorMessage ?? 'Gagal menyelesaikan onboarding';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Header: Step Progress Indicator
            _buildProgressIndicator(state.currentStep),
            const SizedBox(height: 16),

            // Page View
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Controlled via buttons
                onPageChanged: (index) {
                  ref.read(onboardingControllerProvider.notifier).setStep(index);
                },
                children: [
                  _buildStep1Welcome(state),
                  _buildStep2Wallet(state),
                  _buildStep3Categories(state),
                ],
              ),
            ),

            // Bottom Navigation Buttons
            _buildBottomBar(state),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(int currentStep) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index <= currentStep;
          return Expanded(
            child: Container(
              height: 6,
              margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }),
      ),
    );
  }

  // --- Step 1: Profil Pengguna ---
  Widget _buildStep1Welcome(OnboardingState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Welcome Icon Header
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.waving_hand_rounded,
                  color: AppColors.primary,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Selamat Datang di CatatUang!',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Aplikasi pencatat keuangan offline-first yang rapi, aman, dan menjaga privasi Anda.',
                textAlign: TextAlign.center,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

              // Selected Avatar Circle
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(30),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  _getIconData(state.avatarIcon),
                  size: 42,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),

              Text(
                'Pilih Ikon Avatar Anda',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: _avatarOptions.map((opt) {
                  final isSelected = opt['id'] == state.avatarIcon;
                  return GestureDetector(
                    onTap: () {
                      ref.read(onboardingControllerProvider.notifier).setAvatar(opt['id']);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(8),
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
                        size: 22,
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Name Input
              Form(
                key: _step1FormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nama Panggilan Anda',
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
                        hintText: 'Misal: Abyan, Budi, atau Sarah',
                        prefixIcon: const Icon(Icons.badge_outlined),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Nama tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Step 2: Buat Dompet Pertama ---
  Widget _buildStep2Wallet(OnboardingState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppColors.primary,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Buat Dompet Pertama Anda',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Dompet digunakan untuk menyimpan saldo tunai, rekening bank, atau e-wallet Anda.',
                textAlign: TextAlign.center,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

              Form(
                key: _step2FormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nama Dompet',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _walletNameController,
                      decoration: InputDecoration(
                        hintText: 'Misal: Tunai / Bank BCA / GoPay',
                        prefixIcon: const Icon(Icons.wallet_rounded),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Nama dompet tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Saldo Awal (Opsional)',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _balanceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '0',
                        prefixText: 'Rp ',
                        prefixStyle: GoogleFonts.manrope(
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                        prefixIcon: const Icon(Icons.attach_money_rounded),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '* Anda selalu dapat menambahkan atau mengedit dompet lain nanti di menu pengaturan.',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Step 3: Pilih Kategori ---
  Widget _buildStep3Categories(OnboardingState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.category_rounded,
                  color: AppColors.primary,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Kategori Transaksi',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Kami telah menyiapkan kategori bawaan. Anda dapat memilih yang sesuai dengan kebutuhan Anda.',
                textAlign: TextAlign.center,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Pilih Kategori Aktif (${state.selectedCategorySyncIds.length}/${state.categories.length})',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      ref.read(onboardingControllerProvider.notifier).selectAllCategories();
                    },
                    child: const Text('Pilih Semua'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (state.categories.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: state.categories.map((cat) {
                    final isSelected = state.selectedCategorySyncIds.contains(cat.syncId);

                    return FilterChip(
                      selected: isSelected,
                      showCheckmark: true,
                      checkmarkColor: Colors.white,
                      label: Text(cat.name),
                      labelStyle: GoogleFonts.hankenGrotesk(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : AppColors.secondary,
                      ),
                      selectedColor: Color(cat.colorValue),
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: isSelected ? Color(cat.colorValue) : Colors.grey.shade300,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (_) {
                        ref.read(onboardingControllerProvider.notifier).toggleCategory(cat.syncId);
                      },
                    );
                  }).toList(),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(OnboardingState state) {
    final isLastStep = state.currentStep == 2;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          if (state.currentStep > 0) ...[
            OutlinedButton(
              onPressed: state.isLoading ? null : _prevPage,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              child: Text(
                'Kembali',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: state.isLoading
                  ? null
                  : isLastStep
                      ? _finish
                      : _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              child: state.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isLastStep ? 'Mulai Sekarang' : 'Lanjut',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
