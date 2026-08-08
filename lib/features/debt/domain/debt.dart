import 'package:isar/isar.dart';

part 'debt.g.dart';

@Collection()
class Debt {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  late String syncId;
  
  late String title;          // Judul/deskripsi kontrak
  
  @Index()
  late String type;           // 'PAYABLE' (utang) atau 'RECEIVABLE' (piutang)
  
  @Index()
  late String contactSyncId;  // Referensi ke Contact.syncId
  
  late double totalAmount;    // Jumlah total utang/piutang
  late double paidAmount;     // Jumlah yang sudah dibayar/diterima
  late DateTime startDate;    // Tanggal kontrak dimulai
  DateTime? dueDate;          // Tanggal jatuh tempo (opsional)
  String? notes;
  
  @Index()
  late bool isActive;         // Soft delete / lunas & arsip
  
  late DateTime createdAt;
  late DateTime updatedAt;
}
