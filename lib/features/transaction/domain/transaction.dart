import 'package:isar/isar.dart';

part 'transaction.g.dart';

@Collection()
class Transaction {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  late String syncId;
  
  @Index()
  late String type;               // 'INCOME', 'EXPENSE', 'TRANSFER_IN', 'TRANSFER_OUT'
  
  late double amount;
  
  @Index()
  late DateTime date;
  
  String? description;
  
  @Index()
  late String walletSyncId;       // Referensi ke Wallet.syncId
  
  @Index()
  String? categorySyncId;         // Referensi ke Category.syncId (null untuk transfer tanpa kategori)
  
  @Index()
  String? transactionGroupId;     // UUID yang mengikat grup transfer (3-Transaction pattern)
  
  @Index()
  String? debtSyncId;             // Referensi ke Debt.syncId (jika terkait utang/piutang)
  
  late DateTime createdAt;
  late DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id == Isar.autoIncrement ? null : id,
      'syncId': syncId,
      'type': type,
      'amount': amount,
      'date': date.toIso8601String(),
      'description': description,
      'walletSyncId': walletSyncId,
      'categorySyncId': categorySyncId,
      'transactionGroupId': transactionGroupId,
      'debtSyncId': debtSyncId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
