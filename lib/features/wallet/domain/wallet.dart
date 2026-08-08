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
  
  late DateTime createdAt;
  late DateTime updatedAt;
}
