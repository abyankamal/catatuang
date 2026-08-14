import 'package:catatuang/features/goal/application/goal_providers.dart';
import 'package:catatuang/features/goal/presentation/goal_list_screen.dart';
import 'package:catatuang/features/goal/presentation/withdraw_goal_screen.dart';
import 'package:catatuang/features/wallet/domain/wallet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class FakeGoalController extends StateNotifier<AsyncValue<void>> implements GoalController {
  FakeGoalController() : super(const AsyncValue.data(null));

  @override
  Future<bool> withdrawGoal({
    required String goalWalletSyncId,
    required String destinationWalletSyncId,
    required double amount,
    required DateTime date,
    String? notes,
  }) async {
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('id_ID', null);
    FlutterError.onError = (details) {
      debugPrint('FLUTTER_CAUGHT_ERROR: ${details.exceptionAsString()}');
    };
  });

  group('Withdraw Goal Tests', () {
    testWidgets('GoalListScreen displays Tarik button only when goal has positive balance', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final goalWithBalance = Wallet()
        ..id = 1
        ..syncId = 'goal_1'
        ..name = 'Liburan ke Bali'
        ..balance = 1500000
        ..targetAmount = 5000000
        ..isActive = true
        ..isGoal = true;

      final goalEmpty = Wallet()
        ..id = 2
        ..syncId = 'goal_2'
        ..name = 'Beli Laptop'
        ..balance = 0
        ..targetAmount = 15000000
        ..isActive = true
        ..isGoal = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeGoalsStreamProvider.overrideWith((ref) => Stream.value([goalWithBalance, goalEmpty])),
            goalControllerProvider.overrideWith((ref) => FakeGoalController()),
          ],
          child: const MaterialApp(
            home: GoalListScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Liburan ke Bali'), findsOneWidget);
      expect(find.text('Beli Laptop'), findsOneWidget);

      // 'Tarik' button should appear only once (for the goal with balance)
      expect(find.text('Tarik'), findsOneWidget);
      // 'Nabung' button should appear for both
      expect(find.text('Nabung'), findsNWidgets(2));
    });

    testWidgets('WithdrawGoalScreen renders presets and validates amount', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final goal = Wallet()
        ..id = 1
        ..syncId = 'goal_1'
        ..name = 'Liburan ke Bali'
        ..balance = 1000000
        ..targetAmount = 5000000
        ..isActive = true
        ..isGoal = true;

      final regularWallet = Wallet()
        ..id = 10
        ..syncId = 'wallet_bca'
        ..name = 'Bank BCA'
        ..balance = 500000
        ..isActive = true
        ..isGoal = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeGoalsStreamProvider.overrideWith((ref) => Stream.value([goal])),
            activeRegularWalletsStreamProvider.overrideWith((ref) => Stream.value([regularWallet])),
            goalControllerProvider.overrideWith((ref) => FakeGoalController()),
          ],
          child: const MaterialApp(
            home: WithdrawGoalScreen(goalId: 'goal_1'),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Tarik Dana Tabungan'), findsOneWidget);
      expect(find.text('Liburan ke Bali'), findsOneWidget);
      expect(find.text('Saldo Tersedia untuk Ditarik'), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('100% (Semua)'), findsOneWidget);
      expect(find.text('Cairkan Dana Tabungan'), findsOneWidget);

      // Tap 50% preset chip
      await tester.tap(find.text('50%'));
      await tester.pump();

      final editable = tester.widget<EditableText>(find.byType(EditableText).first);
      expect(editable.controller.text, '500000');
    });
  });
}
