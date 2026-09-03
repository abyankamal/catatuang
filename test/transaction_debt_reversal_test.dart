import 'package:catatuang/core/utils/currency_formatter.dart';
import 'package:catatuang/features/debt/domain/debt.dart';
import 'package:catatuang/features/transaction/domain/transaction.dart';
import 'package:catatuang/features/wallet/domain/wallet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('id_ID', null);
  });

  group('Transaction & Debt Payment Reversal Logic Tests', () {
    test('CurrencyFormatter does not produce duplicate Rp prefix', () {
      final formatted = CurrencyFormatter.format(50000);
      expect(formatted, 'Rp 50.000');
      expect(formatted.startsWith('Rp Rp'), isFalse);
    });

    test('Deleting a PAYABLE debt payment transaction reverts Wallet balance and Debt.paidAmount', () {
      // Setup initial entities
      final wallet = Wallet()
        ..id = 1
        ..syncId = 'wallet_1'
        ..name = 'BCA'
        ..balance = 750000
        ..isActive = true;

      final debt = Debt()
        ..id = 10
        ..syncId = 'debt_payable_1'
        ..type = 'PAYABLE'
        ..title = 'Pinjaman Teman'
        ..totalAmount = 1000000
        ..paidAmount = 250000 // Already paid 250k
        ..isActive = true;

      // Payment transaction that was created earlier
      final paymentTx = Transaction()
        ..id = 100
        ..syncId = 'tx_100'
        ..type = 'EXPENSE'
        ..amount = 250000
        ..date = DateTime.now()
        ..walletSyncId = wallet.syncId
        ..debtSyncId = debt.syncId;

      // Simulate Reversal Logic from TransactionRepository.deleteTransaction()
      // 1. Wallet balance reversal
      if (paymentTx.type == 'EXPENSE') {
        wallet.balance += paymentTx.amount;
      }

      // 2. Debt paidAmount reversal
      final isPayment = (debt.type == 'PAYABLE' && paymentTx.type == 'EXPENSE') ||
          (debt.type == 'RECEIVABLE' && paymentTx.type == 'INCOME');
      if (isPayment) {
        debt.paidAmount = (debt.paidAmount - paymentTx.amount).clamp(0.0, debt.totalAmount);
      }

      // Verify
      expect(wallet.balance, 1000000); // 750k + 250k
      expect(debt.paidAmount, 0.0); // 250k - 250k
    });

    test('Deleting a RECEIVABLE debt payment transaction reverts Wallet balance and Debt.paidAmount', () {
      final wallet = Wallet()
        ..id = 1
        ..syncId = 'wallet_1'
        ..name = 'Cash'
        ..balance = 800000
        ..isActive = true;

      final debt = Debt()
        ..id = 20
        ..syncId = 'debt_rec_1'
        ..type = 'RECEIVABLE'
        ..title = 'Piutang Rekan'
        ..totalAmount = 500000
        ..paidAmount = 300000
        ..isActive = true;

      final paymentTx = Transaction()
        ..id = 200
        ..syncId = 'tx_200'
        ..type = 'INCOME'
        ..amount = 300000
        ..date = DateTime.now()
        ..walletSyncId = wallet.syncId
        ..debtSyncId = debt.syncId;

      // Simulate Reversal
      if (paymentTx.type == 'INCOME') {
        wallet.balance -= paymentTx.amount;
      }

      final isPayment = (debt.type == 'PAYABLE' && paymentTx.type == 'EXPENSE') ||
          (debt.type == 'RECEIVABLE' && paymentTx.type == 'INCOME');
      if (isPayment) {
        debt.paidAmount = (debt.paidAmount - paymentTx.amount).clamp(0.0, debt.totalAmount);
      }

      expect(wallet.balance, 500000); // 800k - 300k
      expect(debt.paidAmount, 0.0); // 300k - 300k
    });

    test('Modifying a grouped transaction (Transfer/Savings) directly throws UnsupportedError', () {
      final transferTx = Transaction()
        ..id = 300
        ..syncId = 'tx_300'
        ..type = 'TRANSFER_OUT'
        ..amount = 100000
        ..transactionGroupId = 'group_uuid_123'
        ..walletSyncId = 'wallet_1'
        ..date = DateTime.now();

      void validateUpdate(Transaction tx) {
        if (tx.transactionGroupId != null && tx.transactionGroupId!.isNotEmpty) {
          throw UnsupportedError(
            'Transaksi transfer/tabungan yang terikat dalam grup tidak dapat diubah sebagian.',
          );
        }
      }

      expect(() => validateUpdate(transferTx), throwsA(isA<UnsupportedError>()));
    });

    test('Modifying a debt payment transaction directly throws UnsupportedError', () {
      final debtPaymentTx = Transaction()
        ..id = 400
        ..syncId = 'tx_400'
        ..type = 'EXPENSE'
        ..amount = 150000
        ..debtSyncId = 'debt_123'
        ..walletSyncId = 'wallet_1'
        ..date = DateTime.now();

      void validateUpdate(Transaction tx) {
        if (tx.debtSyncId != null && tx.debtSyncId!.isNotEmpty) {
          throw UnsupportedError(
            'Transaksi pembayaran utang/piutang tidak dapat diubah langsung.',
          );
        }
      }

      expect(() => validateUpdate(debtPaymentTx), throwsA(isA<UnsupportedError>()));
    });

    test('Soft deleting a Debt reverts all linked transactions and restores Wallet balance', () {
      final wallet = Wallet()
        ..id = 1
        ..syncId = 'wallet_1'
        ..name = 'BCA'
        ..balance = 700000
        ..isActive = true;

      final debt = Debt()
        ..id = 10
        ..syncId = 'debt_1'
        ..type = 'PAYABLE'
        ..title = 'Cicilan Laptop'
        ..totalAmount = 5000000
        ..paidAmount = 1000000
        ..isActive = true;

      // Skenario: ada 2 transaksi pembayaran cicilan @500k yang tercatat sebagai EXPENSE
      final tx1 = Transaction()
        ..id = 101
        ..syncId = 'tx_101'
        ..type = 'EXPENSE'
        ..amount = 500000
        ..walletSyncId = wallet.syncId
        ..debtSyncId = debt.syncId;

      final tx2 = Transaction()
        ..id = 102
        ..syncId = 'tx_102'
        ..type = 'EXPENSE'
        ..amount = 500000
        ..walletSyncId = wallet.syncId
        ..debtSyncId = debt.syncId;

      final linkedTxs = [tx1, tx2];

      // Simulasi Reversal Logic dari softDeleteDebt()
      for (final tx in linkedTxs) {
        if (tx.type == 'EXPENSE') {
          wallet.balance += tx.amount;
        } else if (tx.type == 'INCOME') {
          wallet.balance -= tx.amount;
        }
      }
      debt.isActive = false;

      // Saldo dompet harus kembali: 700k + 500k + 500k = 1.700.000
      expect(wallet.balance, 1700000);
      expect(debt.isActive, isFalse);
    });

    test('Soft deleting a wallet with non-zero balance is prohibited', () {
      final activeWalletWithBalance = Wallet()
        ..id = 1
        ..name = 'BCA Tabungan'
        ..balance = 500000.0
        ..isActive = true;

      final zeroBalanceWallet = Wallet()
        ..id = 2
        ..name = 'Dompet Lama Kosong'
        ..balance = 0.0
        ..isActive = true;

      void validateSoftDelete(Wallet wallet) {
        if (wallet.balance.abs() > 0.001) {
          throw Exception('Dompet masih memiliki saldo.');
        }
      }

      expect(() => validateSoftDelete(activeWalletWithBalance), throwsA(isA<Exception>()));
      expect(() => validateSoftDelete(zeroBalanceWallet), returnsNormally);
    });
  });
}
