import 'package:isar/isar.dart';

part 'category.g.dart';

@Collection()
class Category {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  late String syncId;
  
  late String name;           // Nama kategori (e.g., "Makanan", "Gaji")
  
  @Index()
  late String type;           // 'INCOME' atau 'EXPENSE'
  
  late String icon;           // Nama ikon Material sebagai string (e.g., "restaurant")
  late int colorValue;        // Warna ARGB sebagai int
  
  @Index()
  late bool isActive;
  
  late DateTime createdAt;
  late DateTime updatedAt;
}
