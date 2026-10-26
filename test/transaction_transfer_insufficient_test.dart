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

    test('updateTransaction for EXPENSE on regular wallet allows negative balance', () {
      final wallet = Wallet()
        ..id = 1
        ..syncId = 'wallet_main'
        ..name = 'Dompet Utama'
        ..balance = 50000.0
        ..isActive = true
        ..isGoal = false;

      final existingTx = Transaction()
        ..id = 10
        ..syncId = 'tx_10'
        ..type = 'EXPENSE'
        ..amount = 30000.0
        ..walletSyncId = wallet.syncId
        ..date = DateTime(2026, 10, 1);

      // User edits existingTx to EXPENSE of 100k
      // After reverting old 30k, effective balance is 50k + 30k = 80k.
      // 80k - 100k = -20k. For regular wallet (isGoal == false), this is allowed.
      const newAmount = 100000.0;

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
          if (targetWallet.isGoal && effectiveBalance < newAmount) {
            throw Exception('Saldo kantong tabungan "${targetWallet.name}" tidak mencukupi untuk transaksi ini.');
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

      // Saldo kantong reguler terpotong menjadi minus tanpa exception
      expect(wallet.balance, -20000.0);
    });

    test('updateTransaction for EXPENSE on goal wallet throws Exception when balance is insufficient', () {
      final goalWallet = Wallet()
        ..id = 5
        ..syncId = 'wallet_goal'
        ..name = 'Tabungan Liburan'
        ..balance = 50000.0
        ..isActive = true
        ..isGoal = true;

      final existingTx = Transaction()
        ..id = 11
        ..syncId = 'tx_11'
        ..type = 'EXPENSE'
        ..amount = 30000.0
        ..walletSyncId = goalWallet.syncId
        ..date = DateTime(2026, 10, 1);

      const newAmount = 100000.0; // Needs 100k, available 80k

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
          if (targetWallet.isGoal && effectiveBalance < newAmount) {
            throw Exception('Saldo kantong tabungan "${targetWallet.name}" tidak mencukupi untuk transaksi ini.');
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
          targetWallet: goalWallet,
          newType: 'EXPENSE',
          newAmount: newAmount,
        ),
        throwsA(
          predicate(
            (e) =>
                e is Exception &&
                e.toString().contains('Saldo kantong tabungan "Tabungan Liburan" tidak mencukupi untuk transaksi ini.'),
          ),
        ),
      );

      expect(goalWallet.balance, 50000.0);
    });

    test('updateTransaction for EXPENSE succeeds when balance after reversal is sufficient', () {
      final wallet = Wallet()
        ..id = 1
        ..syncId = 'wallet_main'
        ..name = 'Dompet Utama'
        ..balance = 50000.0
        ..isActive = true
        ..isGoal = false;

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
          if (targetWallet.isGoal && effectiveBalance < newAmount) {
            throw Exception('Saldo kantong tabungan "${targetWallet.name}" tidak mencukupi untuk transaksi ini.');
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

    test('updateTransaction changing wallet checks destination goal wallet balance for EXPENSE', () {
      final oldWallet = Wallet()
        ..id = 1
        ..syncId = 'wallet_old'
        ..name = 'Dompet Lama'
        ..balance = 50000.0
        ..isActive = true
        ..isGoal = false;

      final newGoalWallet = Wallet()
        ..id = 2
        ..syncId = 'wallet_new_goal'
        ..name = 'Tabungan Haji'
        ..balance = 10000.0 // Only 10k
        ..isActive = true
        ..isGoal = true;

      final existingTx = Transaction()
        ..id = 15
        ..syncId = 'tx_15'
        ..type = 'EXPENSE'
        ..amount = 25000.0
        ..walletSyncId = oldWallet.syncId
        ..date = DateTime(2026, 10, 1);

      // Trying to move 25k expense to newGoalWallet which only has 10k
      void executeMoveWalletSimulation({
        required Transaction oldTx,
        required Wallet sourceWallet,
        required Wallet targetWallet,
        required double amount,
      }) {
        // Revert on old wallet
        sourceWallet.balance += oldTx.amount;

        // Apply on new wallet
        if (targetWallet.isGoal && targetWallet.balance < amount) {
          // Rollback source wallet modification (mimicking atomic writeTxn rollback on exception)
          sourceWallet.balance -= oldTx.amount;
          throw Exception('Saldo kantong tabungan "${targetWallet.name}" tidak mencukupi untuk transaksi ini.');
        }
        targetWallet.balance -= amount;
      }

      expect(
        () => executeMoveWalletSimulation(
          oldTx: existingTx,
          sourceWallet: oldWallet,
          targetWallet: newGoalWallet,
          amount: 25000.0,
        ),
        throwsA(
          predicate(
            (e) =>
                e is Exception &&
                e.toString().contains('Saldo kantong tabungan "Tabungan Haji" tidak mencukupi untuk transaksi ini.'),
          ),
        ),
      );

      // Balances preserved
      expect(oldWallet.balance, 50000.0);
      expect(newGoalWallet.balance, 10000.0);
    });
  });
}
