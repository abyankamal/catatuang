import 'package:isar/isar.dart';

part 'app_settings.g.dart';

@Collection()
class AppSettings {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  late String syncId;
  
  DateTime? lockedUntil;       // Tanggal terakhir periode terkunci (Tutup Buku)
  
  late DateTime createdAt;
  late DateTime updatedAt;
}
