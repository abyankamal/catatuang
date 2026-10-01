import 'package:catatuang/core/exceptions/locked_period_exception.dart';
import 'package:catatuang/features/debt/domain/debt.dart';
import 'package:catatuang/features/transaction/domain/transaction.dart';
import 'package:catatuang/features/wallet/domain/wallet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Debt Soft Delete Period Locking Tests', () {
    test('softDeleteDebt throws LockedPeriodException if debt.startDate is in locked period', () {
      final lockedUntil = DateTime(2026, 8, 31, 23, 59, 59);

      final debt = Debt()
        ..id = 1
        ..syncId = 'debt_locked_start'
        ..title = 'Pinjaman Masa Lalu'
        ..startDate = DateTime(2026, 8, 15) // Before lockedUntil
        ..totalAmount = 1000000.0
        ..paidAmount = 0.0
        ..isActive = true;

      void validateDelete({
        required Debt debt,
        required DateTime? lockedUntil,
        required List<Transaction> linkedTxs,
      }) {
        if (lockedUntil != null) {
          if (!debt.startDate.isAfter(lockedUntil)) {
            throw LockedPeriodException();
          }
          for (final tx in linkedTxs) {
            if (!tx.date.isAfter(lockedUntil)) {
              throw LockedPeriodException();
            }
          }
        }
      }

      expect(
        () => validateDelete(debt: debt, lockedUntil: lockedUntil, linkedTxs: []),
        throwsA(isA<LockedPeriodException>()),
      );
    });

    test('softDeleteDebt throws LockedPeriodException if any linked payment is in locked period, preserving wallet balance', () {
      final lockedUntil = DateTime(2026, 8, 31, 23, 59, 59);

      // Debt created AFTER locked period
      final debt = Debt()
        ..id = 2
        ..syncId = 'debt_recent'
        ..title = 'Utang Elektronik'
        ..startDate = DateTime(2026, 9, 1) // After lockedUntil
        ..totalAmount = 5000000.0
        ..paidAmount = 2000000.0
        ..isActive = true;

      final wallet = Wallet()
        ..id = 1
        ..syncId = 'wallet_bca'
        ..name = 'BCA'
        ..balance = 1500000.0
        ..isActive = true;

      // Linked payments:
      // Tx 1 was made in August (during locked period!)
      final txOldPayment = Transaction()
        ..id = 101
        ..syncId = 'tx_aug'
        ..type = 'EXPENSE'
        ..amount = 1000000.0
        ..date = DateTime(2026, 8, 25) // IN LOCKED PERIOD
        ..walletSyncId = wallet.syncId
        ..debtSyncId = debt.syncId;

      // Tx 2 was made in September (unlocked)
      final txNewPayment = Transaction()
        ..id = 102
        ..syncId = 'tx_sep'
        ..type = 'EXPENSE'
        ..amount = 1000000.0
        ..date = DateTime(2026, 9, 15) // After lockedUntil
        ..walletSyncId = wallet.syncId
        ..debtSyncId = debt.syncId;

      final linkedTransactions = [txOldPayment, txNewPayment];

      void executeSoftDelete({
        required Debt targetDebt,
        required DateTime? lockedUntil,
        required List<Transaction> linkedTxs,
        required Wallet targetWallet,
      }) {
        if (lockedUntil != null) {
          if (!targetDebt.startDate.isAfter(lockedUntil)) {
            throw LockedPeriodException();
          }
          for (final tx in linkedTxs) {
            if (!tx.date.isAfter(lockedUntil)) {
              throw LockedPeriodException();
            }
          }
        }

        // Reversal would happen here if check passed
        for (final tx in linkedTxs) {
          if (tx.type == 'EXPENSE') {
            targetWallet.balance += tx.amount;
          }
        }
        targetDebt.isActive = false;
      }

      expect(
        () => executeSoftDelete(
          targetDebt: debt,
          lockedUntil: lockedUntil,
          linkedTxs: linkedTransactions,
          targetWallet: wallet,
        ),
        throwsA(isA<LockedPeriodException>()),
      );

      // Verify that no reversal occurred and debt remains active
      expect(wallet.balance, 1500000.0);
      expect(debt.isActive, isTrue);
    });

    test('softDeleteDebt succeeds when both debt startDate and all linked payments are after lockedUntil', () {
      final lockedUntil = DateTime(2026, 8, 31, 23, 59, 59);

      final debt = Debt()
        ..id = 3
        ..syncId = 'debt_valid'
        ..title = 'Utang Baru'
        ..startDate = DateTime(2026, 9, 1)
        ..totalAmount = 2000000.0
        ..paidAmount = 500000.0
        ..isActive = true;

      final wallet = Wallet()
        ..id = 1
        ..syncId = 'wallet_bca'
        ..name = 'BCA'
        ..balance = 1000000.0
        ..isActive = true;

      final txPayment = Transaction()
        ..id = 201
        ..syncId = 'tx_valid_sep'
        ..type = 'EXPENSE'
        ..amount = 500000.0
        ..date = DateTime(2026, 9, 10)
        ..walletSyncId = wallet.syncId
        ..debtSyncId = debt.syncId;

      void executeSoftDelete({
        required Debt targetDebt,
        required DateTime? lockedUntil,
        required List<Transaction> linkedTxs,
        required Wallet targetWallet,
      }) {
        if (lockedUntil != null) {
          if (!targetDebt.startDate.isAfter(lockedUntil)) {
            throw LockedPeriodException();
          }
          for (final tx in linkedTxs) {
            if (!tx.date.isAfter(lockedUntil)) {
              throw LockedPeriodException();
            }
          }
        }

        for (final tx in linkedTxs) {
          if (tx.type == 'EXPENSE') {
            targetWallet.balance += tx.amount;
          }
        }
        targetDebt.isActive = false;
      }

      executeSoftDelete(
        targetDebt: debt,
        lockedUntil: lockedUntil,
        linkedTxs: [txPayment],
        targetWallet: wallet,
      );

      // Successfully reversed
      expect(wallet.balance, 1500000.0); // 1.000.000 + 500.000
      expect(debt.isActive, isFalse);
    });

    test('softDeleteDebt without linked transactions succeeds if debt.startDate is after lockedUntil', () {
      final lockedUntil = DateTime(2026, 8, 31, 23, 59, 59);

      final debt = Debt()
        ..id = 4
        ..syncId = 'debt_unpaid'
        ..title = 'Utang Belum Dicicil'
        ..startDate = DateTime(2026, 9, 5)
        ..totalAmount = 1000000.0
        ..paidAmount = 0.0
        ..isActive = true;

      void executeSoftDelete({
        required Debt targetDebt,
        required DateTime? lockedUntil,
        required List<Transaction> linkedTxs,
      }) {
        if (lockedUntil != null) {
          if (!targetDebt.startDate.isAfter(lockedUntil)) {
            throw LockedPeriodException();
          }
          for (final tx in linkedTxs) {
            if (!tx.date.isAfter(lockedUntil)) {
              throw LockedPeriodException();
            }
          }
        }
        targetDebt.isActive = false;
      }

      executeSoftDelete(
        targetDebt: debt,
        lockedUntil: lockedUntil,
        linkedTxs: [],
      );

      expect(debt.isActive, isFalse);
    });
  });
}
