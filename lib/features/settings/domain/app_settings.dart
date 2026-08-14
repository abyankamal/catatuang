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
  
  bool isPrivacyScreenEnabled = true;  // Flag status privasi blur saat app switcher

  bool isDebtReminderEnabled = true;   // Flag status pengingat notifikasi utang & piutang

  late DateTime createdAt;
  late DateTime updatedAt;
}
