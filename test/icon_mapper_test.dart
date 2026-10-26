import 'package:catatuang/core/utils/icon_mapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppIconMapper Category Icon Tests', () {
    test('Maps known category and transaction icon strings correctly', () {
      expect(AppIconMapper.getCategoryIcon('restaurant'), Icons.restaurant_rounded);
      expect(AppIconMapper.getCategoryIcon('food'), Icons.restaurant_rounded);
      expect(AppIconMapper.getCategoryIcon('directions_car'), Icons.directions_car_rounded);
      expect(AppIconMapper.getCategoryIcon('transport'), Icons.directions_car_rounded);
      expect(AppIconMapper.getCategoryIcon('shopping_bag'), Icons.shopping_bag_rounded);
      expect(AppIconMapper.getCategoryIcon('shopping'), Icons.shopping_bag_rounded);
      expect(AppIconMapper.getCategoryIcon('movie'), Icons.movie_rounded);
      expect(AppIconMapper.getCategoryIcon('entertainment'), Icons.movie_rounded);
      expect(AppIconMapper.getCategoryIcon('receipt'), Icons.receipt_long_rounded);
      expect(AppIconMapper.getCategoryIcon('receipt_long'), Icons.receipt_long_rounded);
      expect(AppIconMapper.getCategoryIcon('bills'), Icons.receipt_long_rounded);
      expect(AppIconMapper.getCategoryIcon('medical_services'), Icons.medical_services_rounded);
      expect(AppIconMapper.getCategoryIcon('health'), Icons.medical_services_rounded);
      expect(AppIconMapper.getCategoryIcon('school'), Icons.school_rounded);
      expect(AppIconMapper.getCategoryIcon('education'), Icons.school_rounded);
      expect(AppIconMapper.getCategoryIcon('card_giftcard'), Icons.card_giftcard_rounded);
      expect(AppIconMapper.getCategoryIcon('gift'), Icons.card_giftcard_rounded);
      expect(AppIconMapper.getCategoryIcon('work'), Icons.work_rounded);
      expect(AppIconMapper.getCategoryIcon('salary'), Icons.work_rounded);
      expect(AppIconMapper.getCategoryIcon('trending_up'), Icons.trending_up_rounded);
      expect(AppIconMapper.getCategoryIcon('investment'), Icons.trending_up_rounded);
      expect(AppIconMapper.getCategoryIcon('payments'), Icons.payments_rounded);
      expect(AppIconMapper.getCategoryIcon('pets'), Icons.pets_rounded);
      expect(AppIconMapper.getCategoryIcon('home'), Icons.home_rounded);
      expect(AppIconMapper.getCategoryIcon('fitness_center'), Icons.fitness_center_rounded);
      expect(AppIconMapper.getCategoryIcon('swap_horiz'), Icons.swap_horiz_rounded);
      expect(AppIconMapper.getCategoryIcon('account_balance_wallet'), Icons.account_balance_wallet_rounded);
      expect(AppIconMapper.getCategoryIcon('savings'), Icons.savings_rounded);
      expect(AppIconMapper.getCategoryIcon('category'), Icons.category_rounded);
    });

    test('Returns defaultCategoryIcon on null, empty, or unknown strings', () {
      expect(AppIconMapper.getCategoryIcon(null), AppIconMapper.defaultCategoryIcon);
      expect(AppIconMapper.getCategoryIcon(''), AppIconMapper.defaultCategoryIcon);
      expect(AppIconMapper.getCategoryIcon('   '), AppIconMapper.defaultCategoryIcon);
      expect(AppIconMapper.getCategoryIcon('unknown_icon_xyz'), AppIconMapper.defaultCategoryIcon);
    });

    test('availableCategoryIcons contains valid icon mapping for all choices', () {
      for (final iconKey in AppIconMapper.availableCategoryIcons) {
        final iconData = AppIconMapper.getCategoryIcon(iconKey);
        expect(iconData, isA<IconData>());
      }
    });
  });

  group('AppIconMapper Avatar Icon Tests', () {
    test('Maps known avatar options correctly', () {
      expect(AppIconMapper.getAvatarIcon('person'), Icons.person_rounded);
      expect(AppIconMapper.getAvatarIcon('face'), Icons.face_rounded);
      expect(AppIconMapper.getAvatarIcon('account_circle'), Icons.account_circle_rounded);
      expect(AppIconMapper.getAvatarIcon('work'), Icons.work_rounded);
      expect(AppIconMapper.getAvatarIcon('savings'), Icons.savings_rounded);
      expect(AppIconMapper.getAvatarIcon('pets'), Icons.pets_rounded);
      expect(AppIconMapper.getAvatarIcon('star'), Icons.star_rounded);
      expect(AppIconMapper.getAvatarIcon('emoji_emotions'), Icons.emoji_emotions_rounded);
    });

    test('Returns defaultAvatarIcon on null, empty, or unknown strings', () {
      expect(AppIconMapper.getAvatarIcon(null), AppIconMapper.defaultAvatarIcon);
      expect(AppIconMapper.getAvatarIcon(''), AppIconMapper.defaultAvatarIcon);
      expect(AppIconMapper.getAvatarIcon('   '), AppIconMapper.defaultAvatarIcon);
      expect(AppIconMapper.getAvatarIcon('alien_face'), AppIconMapper.defaultAvatarIcon);
    });

    test('avatarOptions list provides valid entries with id and icon matching getAvatarIcon', () {
      expect(AppIconMapper.avatarOptions.length, 8);
      for (final option in AppIconMapper.avatarOptions) {
        final id = option['id'] as String;
        final icon = option['icon'] as IconData;
        expect(AppIconMapper.getAvatarIcon(id), equals(icon));
      }
    });
  });
}
