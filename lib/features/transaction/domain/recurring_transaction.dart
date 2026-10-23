import 'package:isar/isar.dart';

part 'recurring_transaction.g.dart';

@Collection()
class RecurringTransaction {
  Id id = Isar.autoIncrement;

  RecurringTransaction();

  @Index(unique: true)
  late String syncId;

  @Index()
  late String type; // 'INCOME', 'EXPENSE', 'TRANSFER'

  late double amount;
  String? description;

  @Index()
  late String walletSyncId; // Dompet sumber
  String? targetWalletSyncId; // Dompet tujuan (khusus TRANSFER)
  String? categorySyncId;
  double? adminFee; // Biaya admin transfer jika ada

  late String frequency; // 'DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY'
  int interval = 1;

  late DateTime startDate;
  DateTime? endDate;
  int? maxOccurrences;
  int occurrenceCount = 0;

  @Index()
  late DateTime nextDueDate;
  DateTime? lastExecutedDate;

  late bool autoExecute; // true: otomatis dieksekusi, false: minta konfirmasi
  late bool isActive; // soft-delete & pause/resume

  late DateTime createdAt;
  late DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id == Isar.autoIncrement ? null : id,
      'syncId': syncId,
      'type': type,
      'amount': amount,
      'description': description,
      'walletSyncId': walletSyncId,
      'targetWalletSyncId': targetWalletSyncId,
      'categorySyncId': categorySyncId,
      'adminFee': adminFee,
      'frequency': frequency,
      'interval': interval,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'maxOccurrences': maxOccurrences,
      'occurrenceCount': occurrenceCount,
      'nextDueDate': nextDueDate.toIso8601String(),
      'lastExecutedDate': lastExecutedDate?.toIso8601String(),
      'autoExecute': autoExecute,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) {
    return RecurringTransaction()
      ..syncId = json['syncId'] as String
      ..type = json['type'] as String
      ..amount = (json['amount'] as num).toDouble()
      ..description = json['description'] as String?
      ..walletSyncId = json['walletSyncId'] as String
      ..targetWalletSyncId = json['targetWalletSyncId'] as String?
      ..categorySyncId = json['categorySyncId'] as String?
      ..adminFee = (json['adminFee'] as num?)?.toDouble()
      ..frequency = json['frequency'] as String
      ..interval = (json['interval'] as num?)?.toInt() ?? 1
      ..startDate = DateTime.parse(json['startDate'] as String)
      ..endDate = json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null
      ..maxOccurrences = (json['maxOccurrences'] as num?)?.toInt()
      ..occurrenceCount = (json['occurrenceCount'] as num?)?.toInt() ?? 0
      ..nextDueDate = DateTime.parse(json['nextDueDate'] as String)
      ..lastExecutedDate = json['lastExecutedDate'] != null ? DateTime.parse(json['lastExecutedDate'] as String) : null
      ..autoExecute = json['autoExecute'] as bool? ?? false
      ..isActive = json['isActive'] as bool? ?? true
      ..createdAt = DateTime.parse(json['createdAt'] as String)
      ..updatedAt = DateTime.parse(json['updatedAt'] as String);
  }
}
