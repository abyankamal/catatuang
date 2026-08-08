import 'package:isar/isar.dart';

part 'contact.g.dart';

@Collection()
class Contact {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  late String syncId;
  
  late String name;           // Nama kontak
  String? phoneNumber;        // Nomor telepon (opsional)
  String? email;              // Email (opsional)
  
  @Index()
  late bool isActive;         // Soft delete flag
  
  late DateTime createdAt;
  late DateTime updatedAt;
}
