import '../../category/domain/category.dart';
import '../../contact/domain/contact.dart';
import '../../debt/domain/debt.dart';
import '../../transaction/domain/transaction.dart';
import '../../wallet/domain/wallet.dart';

class EnrichedTransactionItem {
  final Transaction transaction;
  final Wallet? wallet;
  final Category? category;

  const EnrichedTransactionItem({
    required this.transaction,
    this.wallet,
    this.category,
  });
}

class EnrichedDebtItem {
  final Debt debt;
  final Contact? contact;

  const EnrichedDebtItem({
    required this.debt,
    this.contact,
  });
}

class GlobalSearchResult {
  final String query;
  final List<EnrichedTransactionItem> transactions;
  final List<EnrichedDebtItem> debts;
  final List<Wallet> goals;
  final double totalIncome;
  final double totalExpense;

  const GlobalSearchResult({
    required this.query,
    required this.transactions,
    required this.debts,
    required this.goals,
    required this.totalIncome,
    required this.totalExpense,
  });

  const GlobalSearchResult.empty([this.query = ''])
      : transactions = const [],
        debts = const [],
        goals = const [],
        totalIncome = 0.0,
        totalExpense = 0.0;

  bool get isEmpty =>
      transactions.isEmpty && debts.isEmpty && goals.isEmpty;

  int get totalMatchesCount =>
      transactions.length + debts.length + goals.length;
}
