import 'package:isar/isar.dart';

part 'budget.g.dart';

@Collection()
class Budget {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String syncId; // UUID v4

  @Index()
  late String categorySyncId; // Referensi ke Category.syncId

  late double monthlyLimit; // Batas nominal anggaran

  @Index()
  late int month; // 1 - 12

  @Index()
  late int year; // Tahun anggaran (misal: 2026)

  @Index()
  late bool isActive; // Soft delete flag

  late DateTime createdAt;
  late DateTime updatedAt;
}
