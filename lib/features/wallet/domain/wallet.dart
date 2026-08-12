import 'package:isar/isar.dart';

part 'wallet.g.dart';

@Collection()
class Wallet {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  late String syncId;         // UUID v4
  
  late String name;           // Nama kantong (e.g., "BCA", "Cash")
  late double balance;        // Saldo saat ini
  
  @Index()
  late bool isActive;         // Soft delete flag
  
  @Index()
  bool isGoal = false;        // Savings goal flag

  double? targetAmount;       // Target amount for savings goal
  DateTime? targetDate;       // Target deadline date for savings goal

  late DateTime createdAt;
  late DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id == Isar.autoIncrement ? null : id,
      'syncId': syncId,
      'name': name,
      'balance': balance,
      'isActive': isActive,
      'isGoal': isGoal,
      'targetAmount': targetAmount,
      'targetDate': targetDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
