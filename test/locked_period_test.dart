import 'package:catatuang/core/exceptions/locked_period_exception.dart';
import 'package:catatuang/features/settings/application/settings_providers.dart';
import 'package:catatuang/features/settings/domain/app_settings.dart';
import 'package:catatuang/features/settings/presentation/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('id_ID', null);
  });

  group('Tutup Buku (Period Locking) Tests', () {
    testWidgets('ProfileScreen renders Unlocked status by default', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final settings = AppSettings()
        ..id = 1
        ..syncId = 'settings_1'
        ..userName = 'Abyan'
        ..avatarIcon = 'person'
        ..lockedUntil = null
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appSettingsStreamProvider.overrideWith((ref) => Stream.value(settings)),
          ],
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Tutup Buku (Kunci Periode)'), findsOneWidget);
      expect(find.text('Periode Bebas Edit (Tidak Terkunci)'), findsOneWidget);
      expect(find.text('Kunci Periode Sekarang'), findsOneWidget);
    });

    testWidgets('ProfileScreen renders Locked status when lockedUntil is set', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final lockDate = DateTime(2026, 7, 31, 23, 59, 59);
      final settings = AppSettings()
        ..id = 1
        ..syncId = 'settings_1'
        ..userName = 'Abyan'
        ..avatarIcon = 'person'
        ..lockedUntil = lockDate
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appSettingsStreamProvider.overrideWith((ref) => Stream.value(settings)),
          ],
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Tutup Buku (Kunci Periode)'), findsOneWidget);
      expect(find.text('Buka Kunci'), findsOneWidget);
      expect(find.text('Ubah Tanggal'), findsOneWidget);
    });

    test('LockedPeriodException contains appropriate message', () {
      final exception = LockedPeriodException();
      expect(exception.message, contains('tutup buku'));
    });
  });
}
