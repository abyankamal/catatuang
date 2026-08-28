import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../transaction/data/transaction_repository.dart';
import '../data/search_repository.dart';
import '../domain/search_result.dart';

class SearchFilterState {
  final String query;
  final SearchTypeFilter typeFilter;
  final SearchDateRangeFilter dateRangeFilter;

  const SearchFilterState({
    this.query = '',
    this.typeFilter = SearchTypeFilter.all,
    this.dateRangeFilter = SearchDateRangeFilter.allTime,
  });

  SearchFilterState copyWith({
    String? query,
    SearchTypeFilter? typeFilter,
    SearchDateRangeFilter? dateRangeFilter,
  }) {
    return SearchFilterState(
      query: query ?? this.query,
      typeFilter: typeFilter ?? this.typeFilter,
      dateRangeFilter: dateRangeFilter ?? this.dateRangeFilter,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchFilterState &&
          runtimeType == other.runtimeType &&
          query == other.query &&
          typeFilter == other.typeFilter &&
          dateRangeFilter == other.dateRangeFilter;

  @override
  int get hashCode =>
      query.hashCode ^ typeFilter.hashCode ^ dateRangeFilter.hashCode;
}

class SearchFilterNotifier extends StateNotifier<SearchFilterState> {
  SearchFilterNotifier() : super(const SearchFilterState());

  void setQuery(String q) {
    state = state.copyWith(query: q);
  }

  void setTypeFilter(SearchTypeFilter filter) {
    state = state.copyWith(typeFilter: filter);
  }

  void setDateRangeFilter(SearchDateRangeFilter filter) {
    state = state.copyWith(dateRangeFilter: filter);
  }

  void reset() {
    state = const SearchFilterState();
  }
}

final searchFilterProvider =
    StateNotifierProvider.autoDispose<SearchFilterNotifier, SearchFilterState>((ref) {
  return SearchFilterNotifier();
});

final searchResultsProvider =
    FutureProvider.autoDispose<GlobalSearchResult>((ref) async {
  final filter = ref.watch(searchFilterProvider);
  final repo = ref.watch(searchRepositoryProvider);

  // Watch transactions to ensure search results update if transactions change
  ref.watch(transactionRepositoryProvider);

  if (filter.query.trim().isEmpty) {
    return const GlobalSearchResult.empty();
  }

  // 300ms debounce to prevent firing queries and isolates on every keystroke
  var didCancel = false;
  ref.onDispose(() => didCancel = true);
  await Future.delayed(const Duration(milliseconds: 300));
  if (didCancel) {
    return const GlobalSearchResult.empty();
  }

  return await repo.search(
    query: filter.query,
    typeFilter: filter.typeFilter,
    dateRangeFilter: filter.dateRangeFilter,
  );
});

