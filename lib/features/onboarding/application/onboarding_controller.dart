import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../category/data/category_repository.dart';
import '../../category/domain/category.dart';
import '../../settings/application/settings_providers.dart';
import '../../settings/data/app_settings_repository.dart';
import '../../wallet/data/wallet_repository.dart';

class OnboardingState {
  final int currentStep;
  final String userName;
  final String avatarIcon;
  final String walletName;
  final double initialBalance;
  final List<Category> categories;
  final Set<String> selectedCategorySyncIds;
  final bool isLoading;
  final String? errorMessage;

  const OnboardingState({
    this.currentStep = 0,
    this.userName = '',
    this.avatarIcon = 'person',
    this.walletName = 'Dompet Utama',
    this.initialBalance = 0.0,
    this.categories = const [],
    this.selectedCategorySyncIds = const {},
    this.isLoading = false,
    this.errorMessage,
  });

  OnboardingState copyWith({
    int? currentStep,
    String? userName,
    String? avatarIcon,
    String? walletName,
    double? initialBalance,
    List<Category>? categories,
    Set<String>? selectedCategorySyncIds,
    bool? isLoading,
    String? errorMessage,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      userName: userName ?? this.userName,
      avatarIcon: avatarIcon ?? this.avatarIcon,
      walletName: walletName ?? this.walletName,
      initialBalance: initialBalance ?? this.initialBalance,
      categories: categories ?? this.categories,
      selectedCategorySyncIds: selectedCategorySyncIds ?? this.selectedCategorySyncIds,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

final onboardingControllerProvider =
    StateNotifierProvider.autoDispose<OnboardingController, OnboardingState>((ref) {
  final settingsRepo = ref.watch(appSettingsRepositoryProvider);
  final walletRepo = ref.watch(walletRepositoryProvider);
  final categoryRepo = ref.watch(categoryRepositoryProvider);
  return OnboardingController(
    settingsRepo: settingsRepo,
    walletRepo: walletRepo,
    categoryRepo: categoryRepo,
    ref: ref,
  );
});

class OnboardingController extends StateNotifier<OnboardingState> {
  final AppSettingsRepository settingsRepo;
  final WalletRepository walletRepo;
  final CategoryRepository categoryRepo;
  final Ref ref;

  OnboardingController({
    required this.settingsRepo,
    required this.walletRepo,
    required this.categoryRepo,
    required this.ref,
  }) : super(const OnboardingState()) {
    _initCategories();
  }

  Future<void> _initCategories() async {
    // Pastikan default categories diinisialisasi
    await categoryRepo.seedDefaultCategoriesIfEmpty();
    final categories = await categoryRepo.getActiveCategories();
    final allSyncIds = categories.map((c) => c.syncId).toSet();

    state = state.copyWith(
      categories: categories,
      selectedCategorySyncIds: allSyncIds,
    );
  }

  void setStep(int step) {
    state = state.copyWith(currentStep: step);
  }

  void setUserName(String name) {
    state = state.copyWith(userName: name);
  }

  void setAvatar(String avatar) {
    state = state.copyWith(avatarIcon: avatar);
  }

  void setWalletName(String name) {
    state = state.copyWith(walletName: name);
  }

  void setInitialBalance(double balance) {
    state = state.copyWith(initialBalance: balance);
  }

  void toggleCategory(String syncId) {
    final updated = Set<String>.from(state.selectedCategorySyncIds);
    if (updated.contains(syncId)) {
      updated.remove(syncId);
    } else {
      updated.add(syncId);
    }
    state = state.copyWith(selectedCategorySyncIds: updated);
  }

  void selectAllCategories() {
    final allSyncIds = state.categories.map((c) => c.syncId).toSet();
    state = state.copyWith(selectedCategorySyncIds: allSyncIds);
  }

  /// Menyelesaikan Onboarding:
  /// 1. Buat Dompet Pertama
  /// 2. Nonaktifkan kategori yang tidak dipilih (jika ada)
  /// 3. Simpan Profil Pengguna & Tandai hasCompletedOnboarding = true
  Future<bool> finishOnboarding() async {
    if (state.userName.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Nama pengguna tidak boleh kosong');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // 1. Buat Dompet Utama
      final wName = state.walletName.trim().isNotEmpty
          ? state.walletName.trim()
          : 'Dompet Utama';
      await walletRepo.createWallet(
        name: wName,
        initialBalance: state.initialBalance,
      );

      // 2. Nonaktifkan kategori yang tidak dicentang pengguna
      for (final cat in state.categories) {
        if (!state.selectedCategorySyncIds.contains(cat.syncId)) {
          await categoryRepo.softDeleteCategory(cat.id);
        }
      }

      // 3. Simpan Profil & Tandai Onboarding Selesai
      await settingsRepo.completeOnboarding(
        userName: state.userName.trim(),
        avatarIcon: state.avatarIcon,
      );

      // Invalidate stream settings agar router bereaksi seketika
      ref.invalidate(appSettingsStreamProvider);

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal menyelesaikan onboarding: $e',
      );
      return false;
    }
  }
}
