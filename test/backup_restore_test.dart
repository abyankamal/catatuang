import 'package:catatuang/core/theme/app_theme.dart';
import 'package:catatuang/features/backup/data/backup_restore_service.dart';
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

  group('Backup & Restore Database Tests', () {
    test('BackupRestoreResult holds success status and message correctly', () {
      const successResult = BackupRestoreResult(
        isSuccess: true,
        message: 'Cadangan data berhasil disimpan: catatuang_backup_20260902_120000.isar',
        filePath: '/downloads/catatuang_backup_20260902_120000.isar',
      );

      expect(successResult.isSuccess, isTrue);
      expect(successResult.message, contains('Cadangan data berhasil disimpan'));
      expect(successResult.filePath, isNotNull);

      const errorResult = BackupRestoreResult(
        isSuccess: false,
        message: 'File cadangan kosong atau rusak.',
      );

      expect(errorResult.isSuccess, isFalse);
      expect(errorResult.filePath, isNull);
    });

    testWidgets('ProfileScreen renders Cadangan & Pemulihan Data section properly', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ProfileScreen(),
          ),
        ),
      );

      await tester.pump();

      // Scroll to reveal backup restore section
      await tester.scrollUntilVisible(
        find.text('Cadangan & Pemulihan Data'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();

      expect(find.text('Cadangan & Pemulihan Data'), findsOneWidget);
      expect(find.text('Simpan atau pulihkan file database offline (.isar)'), findsOneWidget);
      expect(find.text('Cadangkan Data'), findsOneWidget);
      expect(find.text('Pulihkan Data'), findsOneWidget);
    });
  });
}
