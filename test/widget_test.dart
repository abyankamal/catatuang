import 'package:catatuang/features/dashboard/application/dashboard_providers.dart';
import 'package:catatuang/features/dashboard/presentation/dashboard_screen.dart';
import 'package:catatuang/features/splash/presentation/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('id_ID', null);
  });

  testWidgets('DashboardScreen renders without error in empty state', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWalletsStreamProvider.overrideWith((ref) => Stream.value([])),
          activeCategoriesStreamProvider.overrideWith((ref) => Stream.value([])),
          recentTransactionsStreamProvider.overrideWith((ref) => Stream.value([])),
          dashboardSummaryProvider.overrideWith(
            (ref) => Future.value(
              const DashboardSummaryState(
                totalBalance: 0.0,
                monthlyIncome: 0.0,
                monthlyExpense: 0.0,
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: DashboardScreen()),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Catat Uang'), findsOneWidget);
  });

  testWidgets('SplashScreen renders branding and elements correctly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: SplashScreen()),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Catat Uang'), findsOneWidget);
    expect(find.text('Kelola Arus Kas Cerdas & Offline'), findsOneWidget);
    expect(find.text('100% Offline-First & Aman'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1300));
  });
}
