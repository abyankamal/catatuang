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
}
