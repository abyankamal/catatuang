import 'package:catatuang/core/widgets/privacy_screen_wrapper.dart';
import 'package:catatuang/features/settings/application/settings_providers.dart';
import 'package:catatuang/features/settings/domain/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PrivacyScreenWrapper Tests', () {
    testWidgets('Renders child normally when app is in foreground', (tester) async {
      final settings = AppSettings()
        ..id = 1
        ..syncId = 's_1'
        ..isPrivacyScreenEnabled = true
        ..hasCompletedOnboarding = true
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appSettingsStreamProvider.overrideWith((ref) => Stream.value(settings)),
          ],
          child: const MaterialApp(
            home: PrivacyScreenWrapper(
              child: Scaffold(
                body: Text('Sensitive Finance Data'),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Sensitive Finance Data'), findsOneWidget);
      // BackdropFilter should not exist while in foreground
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('Applies pure blur BackdropFilter when lifecycle changes to inactive/paused', (tester) async {
      final settings = AppSettings()
        ..id = 1
        ..syncId = 's_1'
        ..isPrivacyScreenEnabled = true
        ..hasCompletedOnboarding = true
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appSettingsStreamProvider.overrideWith((ref) => Stream.value(settings)),
          ],
          child: const MaterialApp(
            home: PrivacyScreenWrapper(
              child: Scaffold(
                body: Text('Sensitive Finance Data'),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Simulate App moving to inactive (e.g. App Switcher triggered)
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();

      // BackdropFilter should now be active
      expect(find.byType(BackdropFilter), findsOneWidget);

      // Simulate App returning to foreground (resumed)
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      // BackdropFilter should disappear
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('Does not apply blur if isPrivacyScreenEnabled is false', (tester) async {
      final settings = AppSettings()
        ..id = 1
        ..syncId = 's_1'
        ..isPrivacyScreenEnabled = false
        ..hasCompletedOnboarding = true
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appSettingsStreamProvider.overrideWith((ref) => Stream.value(settings)),
          ],
          child: const MaterialApp(
            home: PrivacyScreenWrapper(
              child: Scaffold(
                body: Text('Sensitive Finance Data'),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Simulate App moving to inactive
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();

      // BackdropFilter should NOT be shown because privacy screen is disabled
      expect(find.byType(BackdropFilter), findsNothing);
    });
  });
}
