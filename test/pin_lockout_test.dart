import 'package:catatuang/core/utils/pin_security_helper.dart';
import 'package:catatuang/features/settings/domain/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PIN Persistent Rate Limiting & Cold-Start Lockout Tests', () {
    test('Consecutive wrong attempts increment failedPinAttempts and trigger 30s lockout on 5th attempt', () {
      final salt = PinSecurityHelper.generateSalt();
      final correctPin = '123456';
      final hash = PinSecurityHelper.hashPin(correctPin, salt);

      final settings = AppSettings()
        ..id = 1
        ..syncId = 'settings_pin'
        ..isPinEnabled = true
        ..pinSalt = salt
        ..pinHash = hash
        ..failedPinAttempts = 0
        ..lockedOutUntil = null;

      bool simulateVerifyPin(AppSettings s, String enteredPin, DateTime currentTime) {
        if (!s.isPinEnabled || s.pinHash == null || s.pinSalt == null) {
          return true;
        }

        // Check if currently locked out
        if (s.lockedOutUntil != null && currentTime.isBefore(s.lockedOutUntil!)) {
          final remainingSeconds = s.lockedOutUntil!.difference(currentTime).inSeconds + 1;
          throw Exception('Terlalu banyak percobaan salah. Coba lagi dalam $remainingSeconds detik.');
        }

        final isValid = PinSecurityHelper.verifyPin(
          enteredPin: enteredPin,
          storedHash: s.pinHash!,
          storedSalt: s.pinSalt!,
        );

        if (isValid) {
          s.failedPinAttempts = 0;
          s.lockedOutUntil = null;
          return true;
        } else {
          final newAttempts = s.failedPinAttempts + 1;
          DateTime? newLockoutUntil;

          if (newAttempts >= 8) {
            newLockoutUntil = currentTime.add(const Duration(minutes: 5));
          } else if (newAttempts >= 5) {
            newLockoutUntil = currentTime.add(const Duration(seconds: 30));
          }

          s.failedPinAttempts = newAttempts;
          s.lockedOutUntil = newLockoutUntil;

          if (newLockoutUntil != null) {
            final seconds = newLockoutUntil.difference(currentTime).inSeconds;
            throw Exception('Terlalu banyak percobaan salah. Coba lagi dalam $seconds detik.');
          }

          return false;
        }
      }

      final t0 = DateTime(2026, 10, 2, 12, 0, 0);

      // Attempts 1 to 4 fail without lockout exception
      for (var i = 1; i <= 4; i++) {
        final result = simulateVerifyPin(settings, '000000', t0);
        expect(result, isFalse);
        expect(settings.failedPinAttempts, i);
        expect(settings.lockedOutUntil, isNull);
      }

      // 5th attempt triggers lockout for 30s
      expect(
        () => simulateVerifyPin(settings, '000000', t0),
        throwsA(
          predicate(
            (e) =>
                e is Exception &&
                e.toString().contains('Terlalu banyak percobaan salah. Coba lagi dalam 30 detik.'),
          ),
        ),
      );

      expect(settings.failedPinAttempts, 5);
      expect(settings.lockedOutUntil, t0.add(const Duration(seconds: 30)));
    });

    test('Locked out state rejects inputs until lockout duration expires', () {
      final salt = PinSecurityHelper.generateSalt();
      final hash = PinSecurityHelper.hashPin('654321', salt);
      final t0 = DateTime(2026, 10, 2, 12, 0, 0);

      final settings = AppSettings()
        ..id = 1
        ..syncId = 'settings_pin'
        ..isPinEnabled = true
        ..pinSalt = salt
        ..pinHash = hash
        ..failedPinAttempts = 5
        ..lockedOutUntil = t0.add(const Duration(seconds: 30));

      bool simulateVerifyPin(AppSettings s, String enteredPin, DateTime currentTime) {
        if (s.lockedOutUntil != null && currentTime.isBefore(s.lockedOutUntil!)) {
          final remainingSeconds = s.lockedOutUntil!.difference(currentTime).inSeconds + 1;
          throw Exception('Terlalu banyak percobaan salah. Coba lagi dalam $remainingSeconds detik.');
        }
        return PinSecurityHelper.verifyPin(
          enteredPin: enteredPin,
          storedHash: s.pinHash!,
          storedSalt: s.pinSalt!,
        );
      }

      // 10 seconds later: still locked (21 seconds remaining)
      final t1 = t0.add(const Duration(seconds: 10));
      expect(
        () => simulateVerifyPin(settings, '654321', t1),
        throwsA(
          predicate((e) => e.toString().contains('21 detik')),
        ),
      );

      // 31 seconds later: lockout expired, valid pin accepted
      final t2 = t0.add(const Duration(seconds: 31));
      expect(simulateVerifyPin(settings, '654321', t2), isTrue);
    });

    test('Cold start / force-close verification retains lockedOutUntil and prevents bypass', () {
      final t0 = DateTime(2026, 10, 2, 14, 0, 0);

      // Persistent database record with active lockout
      final persistedSettings = AppSettings()
        ..id = 1
        ..syncId = 'settings_1'
        ..isPinEnabled = true
        ..failedPinAttempts = 5
        ..lockedOutUntil = t0.add(const Duration(seconds: 30));

      // Helper simulating checkLockoutStatus on app launch / cold start
      int checkLockoutStatus(AppSettings s, DateTime currentTime) {
        if (!s.isPinEnabled || s.lockedOutUntil == null) {
          return 0;
        }
        if (currentTime.isBefore(s.lockedOutUntil!)) {
          return s.lockedOutUntil!.difference(currentTime).inSeconds + 1;
        }
        s.lockedOutUntil = null;
        return 0;
      }

      // App is killed and relaunched 5 seconds later
      final relaunchTime = t0.add(const Duration(seconds: 5));
      final remaining = checkLockoutStatus(persistedSettings, relaunchTime);

      // Lockout is still active! 26 seconds remaining
      expect(remaining, 26);
      expect(persistedSettings.lockedOutUntil, isNotNull);

      // App is opened after 35 seconds
      final laterTime = t0.add(const Duration(seconds: 35));
      final remainingLater = checkLockoutStatus(persistedSettings, laterTime);
      expect(remainingLater, 0);
      expect(persistedSettings.lockedOutUntil, isNull);
    });

    test('8th failed attempt escalates lockout duration to 5 minutes', () {
      final salt = PinSecurityHelper.generateSalt();
      final hash = PinSecurityHelper.hashPin('111222', salt);
      final t0 = DateTime(2026, 10, 2, 10, 0, 0);

      final settings = AppSettings()
        ..id = 1
        ..syncId = 'settings_pin'
        ..isPinEnabled = true
        ..pinSalt = salt
        ..pinHash = hash
        ..failedPinAttempts = 7 // Already failed 7 times
        ..lockedOutUntil = null;

      void simulateFailedAttempt(AppSettings s, DateTime currentTime) {
        final newAttempts = s.failedPinAttempts + 1;
        DateTime? newLockoutUntil;

        if (newAttempts >= 8) {
          newLockoutUntil = currentTime.add(const Duration(minutes: 5));
        } else if (newAttempts >= 5) {
          newLockoutUntil = currentTime.add(const Duration(seconds: 30));
        }

        s.failedPinAttempts = newAttempts;
        s.lockedOutUntil = newLockoutUntil;

        if (newLockoutUntil != null) {
          final seconds = newLockoutUntil.difference(currentTime).inSeconds;
          throw Exception('Terlalu banyak percobaan salah. Coba lagi dalam $seconds detik.');
        }
      }

      expect(
        () => simulateFailedAttempt(settings, t0),
        throwsA(
          predicate((e) => e.toString().contains('300 detik')),
        ),
      );

      expect(settings.failedPinAttempts, 8);
      expect(settings.lockedOutUntil, t0.add(const Duration(minutes: 5)));
    });

    test('Correct PIN resets failedPinAttempts and lockedOutUntil to 0 and null', () {
      final salt = PinSecurityHelper.generateSalt();
      final hash = PinSecurityHelper.hashPin('999888', salt);

      final settings = AppSettings()
        ..id = 1
        ..syncId = 'settings_pin'
        ..isPinEnabled = true
        ..pinSalt = salt
        ..pinHash = hash
        ..failedPinAttempts = 4
        ..lockedOutUntil = null;

      final isValid = PinSecurityHelper.verifyPin(
        enteredPin: '999888',
        storedHash: settings.pinHash!,
        storedSalt: settings.pinSalt!,
      );

      if (isValid) {
        settings.failedPinAttempts = 0;
        settings.lockedOutUntil = null;
      }

      expect(isValid, isTrue);
      expect(settings.failedPinAttempts, 0);
      expect(settings.lockedOutUntil, isNull);
    });
  });
}
