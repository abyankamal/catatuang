import '../../features/category/domain/category.dart';
import '../../features/dashboard/application/dashboard_providers.dart';
import '../../features/transaction/domain/transaction.dart';
import '../../features/wallet/domain/wallet.dart';

class DummyData {
  static final now = DateTime.now();

  static final List<Wallet> wallets = [
    Wallet()
      ..syncId = 'dummy_w1'
      ..name = 'Dompet Utama'
      ..balance = 3500000.0
      ..isActive = true
      ..isGoal = false
      ..createdAt = now
      ..updatedAt = now,
    Wallet()
      ..syncId = 'dummy_w2'
      ..name = 'Bank BCA'
      ..balance = 12800000.0
      ..isActive = true
      ..isGoal = false
      ..createdAt = now
      ..updatedAt = now,
    Wallet()
      ..syncId = 'dummy_w3'
      ..name = 'E-Wallet'
      ..balance = 4500000.0
      ..isActive = true
      ..isGoal = false
      ..createdAt = now
      ..updatedAt = now,
  ];

  static final List<Wallet> goals = [
    Wallet()
      ..syncId = 'dummy_g1'
      ..name = 'Beli Laptop Workstation'
      ..balance = 13000000.0
      ..targetAmount = 20000000.0
      ..targetDate = DateTime(now.year, now.month + 4, 15)
      ..isGoal = true
      ..isActive = true
      ..createdAt = now
      ..updatedAt = now,
    Wallet()
      ..syncId = 'dummy_g2'
      ..name = 'Dana Darurat 6 Bulan'
      ..balance = 12000000.0
      ..targetAmount = 30000000.0
      ..targetDate = DateTime(now.year + 1, 6, 30)
      ..isGoal = true
      ..isActive = true
      ..createdAt = now
      ..updatedAt = now,
    Wallet()
      ..syncId = 'dummy_g3'
      ..name = 'Liburan Akhir Tahun'
      ..balance = 2500000.0
      ..targetAmount = 10000000.0
      ..targetDate = DateTime(now.year, 12, 25)
      ..isGoal = true
      ..isActive = true
      ..createdAt = now
      ..updatedAt = now,
  ];

  static final List<Category> categories = [
    Category()
      ..syncId = 'cat_gaji'
      ..name = 'Gaji'
      ..type = 'INCOME'
      ..icon = 'payments'
      ..colorValue = 0xFF22C55E
      ..isActive = true
      ..createdAt = now
      ..updatedAt = now,
    Category()
      ..syncId = 'cat_makanan'
      ..name = 'Makanan & Minuman'
      ..type = 'EXPENSE'
      ..icon = 'restaurant'
      ..colorValue = 0xFFEF4444
      ..isActive = true
      ..createdAt = now
      ..updatedAt = now,
    Category()
      ..syncId = 'cat_belanja'
      ..name = 'Belanja Supermarket'
      ..type = 'EXPENSE'
      ..icon = 'shopping_bag'
      ..colorValue = 0xFFF59E0B
      ..isActive = true
      ..createdAt = now
      ..updatedAt = now,
  ];

  static final List<Transaction> transactions = [
    Transaction()
      ..syncId = 'dummy_tx1'
      ..type = 'INCOME'
      ..amount = 15000000.0
      ..date = now.subtract(const Duration(days: 2))
      ..description = 'Gaji Bulanan PT Maju Jaya'
      ..walletSyncId = 'dummy_w2'
      ..categorySyncId = 'cat_gaji'
      ..createdAt = now
      ..updatedAt = now,
    Transaction()
      ..syncId = 'dummy_tx2'
      ..type = 'EXPENSE'
      ..amount = 75000.0
      ..date = now.subtract(const Duration(hours: 4))
      ..description = 'Kopi & Makan Siang'
      ..walletSyncId = 'dummy_w1'
      ..categorySyncId = 'cat_makanan'
      ..createdAt = now
      ..updatedAt = now,
    Transaction()
      ..syncId = 'dummy_tx3'
      ..type = 'EXPENSE'
      ..amount = 850000.0
      ..date = now.subtract(const Duration(days: 1))
      ..description = 'Belanja Bulanan Supermarket'
      ..walletSyncId = 'dummy_w2'
      ..categorySyncId = 'cat_belanja'
      ..createdAt = now
      ..updatedAt = now,
  ];

  static const DashboardSummaryState summary = DashboardSummaryState(
    totalBalance: 20800000.0,
    monthlyIncome: 15000000.0,
    monthlyExpense: 925000.0,
  );
}
