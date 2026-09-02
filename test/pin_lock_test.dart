import 'package:catatuang/core/utils/pin_security_helper.dart';
import 'package:catatuang/core/widgets/privacy_screen_wrapper.dart';
import 'package:catatuang/features/auth/presentation/pin_lock_screen.dart';
import 'package:catatuang/features/settings/application/settings_providers.dart';
import 'package:catatuang/features/settings/domain/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('id_ID', null);
  });

  group('PinSecurityHelper Unit Tests', () {
    test('generateSalt returns a non-empty unique string', () {
      final salt1 = PinSecurityHelper.generateSalt();
      final salt2 = PinSecurityHelper.generateSalt();

      expect(salt1.isNotEmpty, isTrue);
      expect(salt2.isNotEmpty, isTrue);
      expect(salt1, isNot(equals(salt2)));
    });

    test('hashPin produces a consistent SHA-256 hash for identical PIN and salt', () {
      const pin = '123456';
      const salt = 'unique_salt_test';

      final hash1 = PinSecurityHelper.hashPin(pin, salt);
      final hash2 = PinSecurityHelper.hashPin(pin, salt);

      expect(hash1, equals(hash2));
      expect(hash1.length, equals(64)); // SHA-256 hex string length
    });

    test('verifyPin correctly matches valid PIN and rejects invalid PIN', () {
      const pin = '654321';
      final salt = PinSecurityHelper.generateSalt();
      final hash = PinSecurityHelper.hashPin(pin, salt);

      expect(
        PinSecurityHelper.verifyPin(
          enteredPin: '654321',
          storedHash: hash,
          storedSalt: salt,
        ),
        isTrue,
      );

      expect(
        PinSecurityHelper.verifyPin(
          enteredPin: '123456',
          storedHash: hash,
          storedSalt: salt,
        ),
        isFalse,
      );
    });
  });

  group('PinLockScreen Widget Tests', () {
    testWidgets('PinLockScreen renders lock icon, keypad, and 6-dot indicator in unlock mode', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PinLockScreen(mode: PinLockMode.unlock),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Buka Kunci Aplikasi'), findsOneWidget);
      expect(find.text('Masukkan 6 digit PIN untuk mengakses CatatUang'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.byIcon(Icons.backspace_outlined), findsOneWidget);
    });

    testWidgets('Entering numbers fills the indicator dots', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PinLockScreen(mode: PinLockMode.create),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Buat PIN 6-Digit'), findsOneWidget);

      // Tap 1, 2, 3
      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('2'));
      await tester.pump();
      await tester.tap(find.text('3'));
      await tester.pump();

      // Tap backspace
      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pump();
    });

    testWidgets('PrivacyScreenWrapper shows PinLockScreen when PIN is enabled and app is locked', (tester) async {
      final lockedSettings = AppSettings()
        ..id = 1
        ..syncId = 'settings_1'
        ..userName = 'Abyan'
        ..isPrivacyScreenEnabled = true
        ..isPinEnabled = true
        ..pinHash = PinSecurityHelper.hashPin('123456', 'salt')
        ..pinSalt = 'salt'
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appSettingsStreamProvider.overrideWith((ref) => Stream.value(lockedSettings)),
            isAppUnlockedProvider.overrideWith((ref) => false),
          ],
          child: const MaterialApp(
            home: PrivacyScreenWrapper(
              child: Scaffold(body: Text('Protected Dashboard Content')),
            ),
          ),
        ),
      );

      await tester.pump();

      // PinLockScreen should be visible on top
      expect(find.text('Buka Kunci Aplikasi'), findsOneWidget);
    });
  });
}
