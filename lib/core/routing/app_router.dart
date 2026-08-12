import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/goal/presentation/goal_list_screen.dart';
import '../../features/goal/presentation/add_goal_screen.dart';
import '../../features/goal/presentation/top_up_goal_screen.dart';
import '../../features/report/presentation/report_screen.dart';
import '../../features/settings/presentation/profile_screen.dart';
import '../../features/transaction/presentation/add_transaction_screen.dart';
import '../../features/transaction/presentation/transaction_history_screen.dart';
import '../presentation/main_navigation_screen.dart';
import 'not_found_screen.dart';
import '../../features/wallet/domain/wallet.dart';
import '../../features/wallet/presentation/wallet_list_screen.dart';
import '../../features/wallet/presentation/wallet_form_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/dashboard',
  errorBuilder: (context, state) => const NotFoundScreen(),
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
      path: '/top_up_goal/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return TopUpGoalScreen(goalId: id);
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
  ],
);
