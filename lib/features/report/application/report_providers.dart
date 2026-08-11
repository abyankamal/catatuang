import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../transaction/application/transaction_history_provider.dart';
import '../data/report_repository.dart';

class ReportFilterState {
  final int year;
  final int month;

  const ReportFilterState({
    required this.year,
    required this.month,
  });

  ReportFilterState copyWith({
    int? year,
    int? month,
  }) {
    return ReportFilterState(
      year: year ?? this.year,
      month: month ?? this.month,
    );
  }
}

class ReportFilterNotifier extends StateNotifier<ReportFilterState> {
  ReportFilterNotifier()
      : super(ReportFilterState(
          year: DateTime.now().year,
          month: DateTime.now().month,
        ));

  void setMonth(int year, int month) {
    state = state.copyWith(year: year, month: month);
  }
}

final reportFilterProvider =
    StateNotifierProvider<ReportFilterNotifier, ReportFilterState>((ref) {
  return ReportFilterNotifier();
});

final monthlyReportProvider = FutureProvider.autoDispose<MonthlyReportData>((ref) async {
  final repo = ref.watch(reportRepositoryProvider);
  final filter = ref.watch(reportFilterProvider);

  // Watch transactions stream so report auto-updates when transactions are added/edited/deleted
  ref.watch(transactionHistoryStreamProvider);

  return repo.getMonthlyReport(filter.year, filter.month);
});
