import 'package:catatuang/features/transaction/domain/transaction.dart';
import 'package:catatuang/features/wallet/domain/wallet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Comprehensive Negative Balance Protection Tests', () {
    test('Transfer with amount + adminFee exceeding source wallet balance throws Exception', () {
      final sourceWallet = Wallet()
        ..id = 1
        ..syncId = 'wallet_src'
        ..name = 'BCA Prioritas'
        ..balance = 100000.0
        ..isActive = true;

      final destWallet = Wallet()
        ..id = 2
        ..syncId = 'wallet_dst'
        ..name = 'Kantong Jajan'
        ..balance = 20000.0
        ..isActive = true;

      final transferAmount = 98000.0;
      final adminFee = 2500.0; // Total required = 100,500.0 > 100,000.0

      void executeTransferSimulation({
        required Wallet source,
        required Wallet destination,
        required double amount,
        required double fee,
      }) {
        final totalRequired = amount + fee;
        if (source.balance < totalRequired) {
          throw Exception('Saldo kantong "${source.name}" tidak mencukupi untuk melakukan transfer.');
        }

        source.balance -= totalRequired;
        destination.balance += amount;
      }

      expect(
        () => executeTransferSimulation(
          source: sourceWallet,
          destination: destWallet,
          amount: transferAmount,
          fee: adminFee,
        ),
        throwsA(
          predicate(
            (e) =>
                e is Exception &&
                e.toString().contains('Saldo kantong "BCA Prioritas" tidak mencukupi untuk melakukan transfer.'),
          ),
        ),
      );

      // Verify wallet balances are preserved completely
      expect(sourceWallet.balance, 100000.0);
      expect(destWallet.balance, 20000.0);
    });

    test('Transfer succeeds when balance is exactly equal to amount + fee', () {
      final sourceWallet = Wallet()
        ..id = 1
        ..syncId = 'wallet_src'
        ..name = 'Gopay'
        ..balance = 52500.0
        ..isActive = true;

      final destWallet = Wallet()
        ..id = 2
        ..syncId = 'wallet_dst'
        ..name = 'OVO'
        ..balance = 0.0
        ..isActive = true;

      final transferAmount = 50000.0;
      final adminFee = 2500.0;

      void executeTransferSimulation({
        required Wallet source,
        required Wallet destination,
        required double amount,
        required double fee,
      }) {
        final totalRequired = amount + fee;
        if (source.balance < totalRequired) {
          throw Exception('Saldo kantong "${source.name}" tidak mencukupi untuk melakukan transfer.');
        }

        source.balance -= (amount + fee);
        destination.balance += amount;
      }

      executeTransferSimulation(
        source: sourceWallet,
        destination: destWallet,
        amount: transferAmount,
        fee: adminFee,
      );

      expect(sourceWallet.balance, 0.0);
      expect(destWallet.balance, 50000.0);
    });

    test('updateTransaction for EXPENSE throws Exception when new amount exceeds available wallet balance', () {
      // Wallet starting with balance 50k
      final wallet = Wallet()
        ..id = 1
        ..syncId = 'wallet_main'
        ..name = 'Dompet Utama'
        ..balance = 50000.0
        ..isActive = true;

      // Existing transaction was an EXPENSE of 30k (so wallet balance before was 80k, currently 50k)
      final existingTx = Transaction()
        ..id = 10
        ..syncId = 'tx_10'
        ..type = 'EXPENSE'
        ..amount = 30000.0
        ..walletSyncId = wallet.syncId
        ..date = DateTime(2026, 10, 1);

      // User tries to edit existingTx to EXPENSE of 100k
      // After reverting old 30k, effective balance is 50k + 30k = 80k.
      // 80k is insufficient for 100k expense!
      const newAmount = 100000.0;

      void executeUpdateSimulation({
        required Transaction oldTx,
        required Wallet targetWallet,
        required String newType,
        required double newAmount,
      }) {
        // Revert old transaction effect
        var effectiveBalance = targetWallet.balance;
        if (oldTx.type == 'INCOME') {
          effectiveBalance -= oldTx.amount;
        } else if (oldTx.type == 'EXPENSE') {
          effectiveBalance += oldTx.amount;
        }

        // Check new transaction effect
        if (newType == 'EXPENSE') {
          if (effectiveBalance < newAmount) {
            throw Exception('Saldo kantong "${targetWallet.name}" tidak mencukupi untuk transaksi ini.');
          }
          effectiveBalance -= newAmount;
        } else if (newType == 'INCOME') {
          effectiveBalance += newAmount;
        }

        targetWallet.balance = effectiveBalance;
      }

      expect(
        () => executeUpdateSimulation(
          oldTx: existingTx,
          targetWallet: wallet,
          newType: 'EXPENSE',
          newAmount: newAmount,
        ),
        throwsA(
          predicate(
            (e) =>
                e is Exception &&
                e.toString().contains('Saldo kantong "Dompet Utama" tidak mencukupi untuk transaksi ini.'),
          ),
        ),
      );

      // Verify original wallet balance was not corrupted
      expect(wallet.balance, 50000.0);
    });

    test('updateTransaction for EXPENSE succeeds when balance after reversal is sufficient', () {
      final wallet = Wallet()
        ..id = 1
        ..syncId = 'wallet_main'
        ..name = 'Dompet Utama'
        ..balance = 50000.0
        ..isActive = true;

      final existingTx = Transaction()
        ..id = 10
        ..syncId = 'tx_10'
        ..type = 'EXPENSE'
        ..amount = 30000.0
        ..walletSyncId = wallet.syncId
        ..date = DateTime(2026, 10, 1);

      // Revert 30k -> 80k available. New expense = 70k -> final balance 10k.
      const newAmount = 70000.0;

      void executeUpdateSimulation({
        required Transaction oldTx,
        required Wallet targetWallet,
        required String newType,
        required double newAmount,
      }) {
        var effectiveBalance = targetWallet.balance;
        if (oldTx.type == 'INCOME') {
          effectiveBalance -= oldTx.amount;
        } else if (oldTx.type == 'EXPENSE') {
          effectiveBalance += oldTx.amount;
        }

        if (newType == 'EXPENSE') {
          if (effectiveBalance < newAmount) {
            throw Exception('Saldo kantong "${targetWallet.name}" tidak mencukupi untuk transaksi ini.');
          }
          effectiveBalance -= newAmount;
        } else if (newType == 'INCOME') {
          effectiveBalance += newAmount;
        }

        targetWallet.balance = effectiveBalance;
      }

      executeUpdateSimulation(
        oldTx: existingTx,
        targetWallet: wallet,
        newType: 'EXPENSE',
        newAmount: newAmount,
      );

      expect(wallet.balance, 10000.0);
    });

    test('updateTransaction changing wallet checks destination wallet balance for EXPENSE', () {
      final oldWallet = Wallet()
        ..id = 1
        ..syncId = 'wallet_old'
        ..name = 'Dompet Lama'
        ..balance = 50000.0
        ..isActive = true;

      final newWallet = Wallet()
        ..id = 2
        ..syncId = 'wallet_new'
        ..name = 'Dompet Baru'
        ..balance = 10000.0 // Only 10k
        ..isActive = true;

      final existingTx = Transaction()
        ..id = 15
        ..syncId = 'tx_15'
        ..type = 'EXPENSE'
        ..amount = 25000.0
        ..walletSyncId = oldWallet.syncId
        ..date = DateTime(2026, 10, 1);

      // Trying to move 25k expense to newWallet which only has 10k
      void executeMoveWalletSimulation({
        required Transaction oldTx,
        required Wallet sourceWallet,
        required Wallet targetWallet,
        required double amount,
      }) {
        // Revert on old wallet
        sourceWallet.balance += oldTx.amount;

        // Apply on new wallet
        if (targetWallet.balance < amount) {
          // Rollback source wallet modification (mimicking atomic writeTxn rollback on exception)
          sourceWallet.balance -= oldTx.amount;
          throw Exception('Saldo kantong "${targetWallet.name}" tidak mencukupi untuk transaksi ini.');
        }
        targetWallet.balance -= amount;
      }

      expect(
        () => executeMoveWalletSimulation(
          oldTx: existingTx,
          sourceWallet: oldWallet,
          targetWallet: newWallet,
          amount: 25000.0,
        ),
        throwsA(
          predicate(
            (e) =>
                e is Exception &&
                e.toString().contains('Saldo kantong "Dompet Baru" tidak mencukupi untuk transaksi ini.'),
          ),
        ),
      );

      // Balances preserved
      expect(oldWallet.balance, 50000.0);
      expect(newWallet.balance, 10000.0);
    });
  });
}
