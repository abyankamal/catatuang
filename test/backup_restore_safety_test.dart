import 'dart:io';
import 'package:catatuang/core/database/database_provider.dart';
import 'package:catatuang/features/backup/data/backup_restore_service.dart';
import 'package:catatuang/features/transaction/domain/recurring_transaction.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

class FakeIsar implements Isar {
  bool isOpenState = true;
  @override
  bool get isOpen => isOpenState;

  @override
  Future<bool> close({bool deleteFromDisk = false}) async {
    isOpenState = false;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory testTempDir;

  setUpAll(() async {
    testTempDir = await Directory.systemTemp.createTemp('catatuang_restore_test_');

    const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return testTempDir.path;
      },
    );
  });

  tearDownAll(() async {
    if (await testTempDir.exists()) {
      await testTempDir.delete(recursive: true);
    }
  });

  group('Atomic Backup Staging & Rollback Safety Tests', () {
    test('inspect real Isar file header and corrupt page test', () async {
      final isar = await Isar.open(isarSchemas, directory: testTempDir.path, name: 'real_db');
      final exportPath = '${testTempDir.path}/exported.isar';
      await isar.copyToFile(exportPath);
      final exportFile = File(exportPath);
      final bytes = await exportFile.readAsBytes();
      // ignore: avoid_print
      print('DEBUG: Real Isar export length: ${bytes.length}');
      await isar.close();

      // Verify magic bytes
      expect(bytes.length, greaterThanOrEqualTo(4096));
      expect(bytes[20], equals(3));
      expect(bytes[21], equals(17));
      expect(bytes[22], equals(76));
      expect(bytes[23], equals(239));
      expect(bytes[28], equals(1));
    });

    test('restoreDatabaseFromBytes immediately rejects empty bytes without modifying anything', () async {
      final fakeIsar = FakeIsar();
      bool callbackCalled = false;

      final service = BackupRestoreService(
        fakeIsar,
        onIsarRestored: (_) => callbackCalled = true,
      );

      final result = await service.restoreDatabaseFromBytes(Uint8List(0));

      expect(result.isSuccess, isFalse);
      expect(result.message, contains('kosong atau rusak'));
      expect(callbackCalled, isFalse);
      expect(fakeIsar.isOpen, isTrue); // active Isar was not closed
    });

    test('restoreDatabaseFromBytes rejects corrupted bytes during staging phase and leaves active database untouched', () async {
      final fakeIsar = FakeIsar();
      bool callbackCalled = false;

      final service = BackupRestoreService(
        fakeIsar,
        onIsarRestored: (_) => callbackCalled = true,
      );

      // Random non-Isar corrupted bytes
      final corruptBytes = Uint8List.fromList([
        0xDE, 0xAD, 0xBE, 0xEF, 0x00, 0x11, 0x22, 0x33,
        0x44, 0x55, 0x66, 0x77, 0x88, 0x99, 0xAA, 0xBB,
      ]);

      final result = await service.restoreDatabaseFromBytes(corruptBytes);

      expect(result.isSuccess, isFalse);
      expect(result.message, contains('tidak valid atau rusak'));
      expect(callbackCalled, isFalse);
      expect(fakeIsar.isOpen, isTrue); // active Isar must remain open and untouched
    });

    test('restoreDatabaseFromBytes successfully restores a valid Isar database snapshot and invokes onIsarRestored', () async {
      // 1. Buat database valid dan ekspor ke bytes
      final sourceIsar = await Isar.open(isarSchemas, directory: testTempDir.path, name: 'source_valid_db');
      final exportPath = '${testTempDir.path}/valid_export.isar';
      await sourceIsar.copyToFile(exportPath);
      final validBytes = await File(exportPath).readAsBytes();
      await sourceIsar.close();

      // 2. Mock active Isar
      final activeIsar = FakeIsar();
      Isar? newlyRestoredIsar;

      final service = BackupRestoreService(
        activeIsar,
        onIsarRestored: (newIsar) => newlyRestoredIsar = newIsar,
      );

      final result = await service.restoreDatabaseFromBytes(validBytes);

      expect(result.isSuccess, isTrue);
      expect(result.message, contains('berhasil dipulihkan'));
      expect(newlyRestoredIsar, isNotNull);
      expect(newlyRestoredIsar!.isOpen, isTrue);

      await newlyRestoredIsar!.close();
    });

    test('restoreDatabaseFromBytes preserves and restores RecurringTransaction records seamlessly', () async {
      // 1. Buat database valid dan isi data RecurringTransaction
      final sourceIsar = await Isar.open(
        isarSchemas,
        directory: testTempDir.path,
        name: 'source_recurring_db',
      );

      final recurring = RecurringTransaction()
        ..syncId = 'rec_backup_test'
        ..type = 'EXPENSE'
        ..amount = 250000
        ..description = 'Langganan Netflix 4K'
        ..walletSyncId = 'wallet_source_test'
        ..frequency = 'MONTHLY'
        ..interval = 1
        ..startDate = DateTime(2026, 1, 15)
        ..nextDueDate = DateTime(2026, 11, 15)
        ..autoExecute = true
        ..isActive = true
        ..occurrenceCount = 5
        ..createdAt = DateTime(2026, 1, 1)
        ..updatedAt = DateTime(2026, 1, 1);

      await sourceIsar.writeTxn(() async {
        await sourceIsar.recurringTransactions.put(recurring);
      });

      final exportPath = '${testTempDir.path}/recurring_export.isar';
      await sourceIsar.copyToFile(exportPath);
      final validBytes = await File(exportPath).readAsBytes();
      await sourceIsar.close();

      // 2. Pulihkan database melalui BackupRestoreService
      final activeIsar = FakeIsar();
      Isar? newlyRestoredIsar;

      final service = BackupRestoreService(
        activeIsar,
        onIsarRestored: (newIsar) => newlyRestoredIsar = newIsar,
      );

      final result = await service.restoreDatabaseFromBytes(validBytes);

      expect(result.isSuccess, isTrue);
      expect(newlyRestoredIsar, isNotNull);
      expect(newlyRestoredIsar!.isOpen, isTrue);

      // 3. Verifikasi entitas RecurringTransaction berhasil dipulihkan lengkap dengan seluruh atributnya
      final restoredList = await newlyRestoredIsar!.recurringTransactions.where().findAll();
      expect(restoredList.length, equals(1));

      final restoredItem = restoredList.first;
      expect(restoredItem.syncId, equals('rec_backup_test'));
      expect(restoredItem.type, equals('EXPENSE'));
      expect(restoredItem.amount, equals(250000));
      expect(restoredItem.description, equals('Langganan Netflix 4K'));
      expect(restoredItem.walletSyncId, equals('wallet_source_test'));
      expect(restoredItem.frequency, equals('MONTHLY'));
      expect(restoredItem.interval, equals(1));
      expect(restoredItem.autoExecute, isTrue);
      expect(restoredItem.isActive, isTrue);
      expect(restoredItem.occurrenceCount, equals(5));
      expect(restoredItem.nextDueDate, equals(DateTime(2026, 11, 15)));

      await newlyRestoredIsar!.close();
    });
  });
}
