import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/goal/presentation/goal_list_screen.dart';
import '../../features/goal/presentation/add_goal_screen.dart';
import '../../features/goal/presentation/top_up_goal_screen.dart';
import '../../features/goal/presentation/withdraw_goal_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/report/presentation/report_screen.dart';
import '../../features/settings/application/settings_providers.dart';
import '../../features/settings/presentation/profile_screen.dart';
import '../../features/transaction/presentation/add_transaction_screen.dart';
import '../../features/transaction/presentation/transaction_history_screen.dart';
import '../presentation/main_navigation_screen.dart';
import 'not_found_screen.dart';
import '../../features/wallet/domain/wallet.dart';
import '../../features/wallet/presentation/wallet_list_screen.dart';
import '../../features/wallet/presentation/wallet_form_screen.dart';
import '../../features/budget/presentation/budget_list_screen.dart';
import '../../features/category/domain/category.dart';
import '../../features/category/presentation/category_list_screen.dart';
import '../../features/category/presentation/category_form_screen.dart';
import '../../features/contact/domain/contact.dart';
import '../../features/contact/presentation/contact_list_screen.dart';
import '../../features/contact/presentation/contact_form_screen.dart';
import '../../features/debt/domain/debt.dart';
import '../../features/debt/presentation/debt_list_screen.dart';
import '../../features/debt/presentation/debt_form_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(appSettingsStreamProvider, (previous, next) {
      notifyListeners();
    });
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final settings = _ref.read(appSettingsStreamProvider).valueOrNull;
    final isGoingToOnboarding = state.matchedLocation == '/onboarding';

    // Jika database kosong / settings belum ada / belum onboarding:
    // (Misal setelah reset data atau fresh install)
    final hasCompleted = settings?.hasCompletedOnboarding ?? false;

    // Jika belum selesai onboarding dan bukan sedang menuju /onboarding
    if (!hasCompleted && !isGoingToOnboarding) {
      return '/onboarding';
    }

    // Jika sudah selesai onboarding dan mencoba ke /onboarding
    if (hasCompleted && isGoingToOnboarding) {
      return '/dashboard';
    }

    return null;
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  final notifier = RouterNotifier(ref);
  ref.onDispose(notifier.dispose);
  return notifier;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard',
    refreshListenable: notifier,
    errorBuilder: (context, state) => const NotFoundScreen(),
    redirect: notifier.redirect,
    routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainNavigationScreen(navigationShell: navigationShell);
      },
      branches: [
        // Tab 1: Dashboard
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),
          ],
        ),
        // Tab 2: Transaksi / Riwayat
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/transactions',
              builder: (context, state) => const TransactionHistoryScreen(),
            ),
          ],
        ),

        // Tab 3: Laporan / Statistik
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/reports',
              builder: (context, state) => const ReportScreen(),
            ),
          ],
        ),

        // Tab 4: Target (Savings Goals)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/goals',
              builder: (context, state) => const GoalListScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/add_transaction',
      builder: (context, state) => const AddTransactionScreen(),
    ),
    GoRoute(
      path: '/add_goal',
      builder: (context, state) => const AddGoalScreen(),
    ),
    GoRoute(
      path: '/edit_goal',
      builder: (context, state) {
        final goal = state.extra as Wallet;
        return AddGoalScreen(existingGoal: goal);
      },
    ),
    GoRoute(
      path: '/top_up_goal/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return TopUpGoalScreen(goalId: id);
      },
    ),
    GoRoute(
      path: '/withdraw_goal/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return WithdrawGoalScreen(goalId: id);
      },
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/wallets',
      builder: (context, state) => const WalletListScreen(),
    ),
    GoRoute(
      path: '/wallets/add',
      builder: (context, state) => const WalletFormScreen(),
    ),
    GoRoute(
      path: '/add_wallet',
      builder: (context, state) => const WalletFormScreen(),
    ),
    GoRoute(
      path: '/wallets/edit',
      builder: (context, state) {
        final wallet = state.extra as Wallet;
        return WalletFormScreen(existingWallet: wallet);
      },
    ),
    GoRoute(
      path: '/categories',
      builder: (context, state) => const CategoryListScreen(),
    ),
    GoRoute(
      path: '/categories/add',
      builder: (context, state) {
        final type = state.extra as String?;
        return CategoryFormScreen(initialType: type ?? 'EXPENSE');
      },
    ),
    GoRoute(
      path: '/categories/edit',
      builder: (context, state) {
        final category = state.extra as Category;
        return CategoryFormScreen(existingCategory: category);
      },
    ),
    // Fitur Utang & Piutang
    GoRoute(
      path: '/debts',
      builder: (context, state) => const DebtListScreen(),
    ),
    GoRoute(
      path: '/debts/add',
      builder: (context, state) {
        final type = state.extra as String?;
        return DebtFormScreen(initialType: type ?? 'PAYABLE');
      },
    ),
    GoRoute(
      path: '/debts/edit',
      builder: (context, state) {
        final debt = state.extra as Debt;
        return DebtFormScreen(existingDebt: debt);
      },
    ),
    // Fitur Kontak
    GoRoute(
      path: '/contacts',
      builder: (context, state) => const ContactListScreen(),
    ),
    GoRoute(
      path: '/contacts/add',
      builder: (context, state) => const ContactFormScreen(),
    ),
    GoRoute(
      path: '/contacts/edit',
      builder: (context, state) {
        final contact = state.extra as Contact;
        return ContactFormScreen(existingContact: contact);
      },
    ),
    // Fitur Anggaran
    GoRoute(
      path: '/budgets',
      builder: (context, state) => const BudgetListScreen(),
    ),
    // Fitur Onboarding
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
  ],
);
});

