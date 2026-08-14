import 'package:isar/isar.dart';

part 'app_settings.g.dart';

@Collection()
class AppSettings {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  late String syncId;
  
  String? userName;
  String? avatarIcon;

  DateTime? lockedUntil;       // Tanggal terakhir periode terkunci (Tutup Buku)
  
  bool hasCompletedOnboarding = false; // Flag status penyelesaian onboarding
  
  late DateTime createdAt;
  late DateTime updatedAt;
}
