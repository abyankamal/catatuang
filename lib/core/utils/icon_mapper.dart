import 'package:flutter/material.dart';

/// Utilitas terpusat untuk pemetaan nama ikon string ke [IconData].
///
/// Menyediakan mapping konsisten di seluruh modul aplikasi (Kategori, Anggaran,
/// Transaksi, Dashboard, Profil, dan Onboarding), dilengkapi fallback aman
/// saat nama ikon tidak dikenali.
class AppIconMapper {
  const AppIconMapper._();

  /// Default fallback icon untuk kategori/transaksi
  static const IconData defaultCategoryIcon = Icons.category_rounded;

  /// Default fallback icon untuk avatar profil
  static const IconData defaultAvatarIcon = Icons.person_rounded;

  /// Pemetaan nama ikon kategori / transaksi ke [IconData].
  ///
  /// Menerima parameter nama ikon opsional (bisa bernilai `null` atau kosong).
  /// Jika nama ikon tidak dikenali atau null, mengembalikan [defaultCategoryIcon].
  static IconData getCategoryIcon(String? iconName) {
    if (iconName == null || iconName.trim().isEmpty) {
      return defaultCategoryIcon;
    }

    switch (iconName.trim()) {
      case 'restaurant':
      case 'food':
        return Icons.restaurant_rounded;
      case 'directions_car':
      case 'transport':
        return Icons.directions_car_rounded;
      case 'shopping_bag':
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'movie':
      case 'entertainment':
        return Icons.movie_rounded;
      case 'receipt':
      case 'receipt_long':
      case 'bills':
        return Icons.receipt_long_rounded;
      case 'medical_services':
      case 'health':
        return Icons.medical_services_rounded;
      case 'school':
      case 'education':
        return Icons.school_rounded;
      case 'card_giftcard':
      case 'gift':
        return Icons.card_giftcard_rounded;
      case 'work':
      case 'salary':
        return Icons.work_rounded;
      case 'trending_up':
      case 'investment':
        return Icons.trending_up_rounded;
      case 'payments':
        return Icons.payments_rounded;
      case 'pets':
        return Icons.pets_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'fitness_center':
        return Icons.fitness_center_rounded;
      case 'swap_horiz':
        return Icons.swap_horiz_rounded;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet_rounded;
      case 'savings':
        return Icons.savings_rounded;
      case 'category':
        return Icons.category_rounded;
      default:
        return defaultCategoryIcon;
    }
  }

  /// Pemetaan nama ikon avatar profil ke [IconData].
  ///
  /// Jika nama ikon tidak dikenali atau null, mengembalikan [defaultAvatarIcon].
  static IconData getAvatarIcon(String? iconName) {
    if (iconName == null || iconName.trim().isEmpty) {
      return defaultAvatarIcon;
    }

    switch (iconName.trim()) {
      case 'person':
        return Icons.person_rounded;
      case 'face':
        return Icons.face_rounded;
      case 'account_circle':
        return Icons.account_circle_rounded;
      case 'work':
        return Icons.work_rounded;
      case 'savings':
        return Icons.savings_rounded;
      case 'pets':
        return Icons.pets_rounded;
      case 'star':
        return Icons.star_rounded;
      case 'emoji_emotions':
        return Icons.emoji_emotions_rounded;
      default:
        return defaultAvatarIcon;
    }
  }

  /// Daftar opsi avatar profil untuk UI picker (ProfileScreen, OnboardingScreen)
  static const List<Map<String, dynamic>> avatarOptions = [
    {'id': 'person', 'icon': Icons.person_rounded},
    {'id': 'face', 'icon': Icons.face_rounded},
    {'id': 'account_circle', 'icon': Icons.account_circle_rounded},
    {'id': 'work', 'icon': Icons.work_rounded},
    {'id': 'savings', 'icon': Icons.savings_rounded},
    {'id': 'pets', 'icon': Icons.pets_rounded},
    {'id': 'star', 'icon': Icons.star_rounded},
    {'id': 'emoji_emotions', 'icon': Icons.emoji_emotions_rounded},
  ];

  /// Daftar nama ikon kategori yang tersedia di CategoryFormScreen
  static const List<String> availableCategoryIcons = [
    'restaurant',
    'directions_car',
    'shopping_bag',
    'receipt',
    'payments',
    'card_giftcard',
    'trending_up',
    'pets',
    'home',
    'movie',
    'fitness_center',
    'medical_services',
    'school',
    'category',
  ];
}
