import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/category/domain/category.dart';
import '../../features/contact/domain/contact.dart';
import '../../features/debt/domain/debt.dart';
import '../../features/settings/domain/app_settings.dart';
import '../../features/transaction/domain/transaction.dart';
import '../../features/wallet/domain/wallet.dart';

final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError(
    'isarProvider belum diinisialisasi. '
    'Pastikan openIsar() dipanggil sebelum runApp().',
  );
});

Future<Isar> openIsar() async {
  if (kIsWeb) {
    return Isar.open(
      [
        WalletSchema,
        CategorySchema,
        ContactSchema,
        DebtSchema,
        TransactionSchema,
        AppSettingsSchema,
      ],
      directory: '',
    );
  }

  final dir = await getApplicationDocumentsDirectory();
  return Isar.open(
    [
      WalletSchema,
      CategorySchema,
      ContactSchema,
      DebtSchema,
      TransactionSchema,
      AppSettingsSchema,
    ],
    directory: dir.path,
  );
}
