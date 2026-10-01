import 'package:catatuang/core/database/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

class FakeIsar implements Isar {
  final String tag;
  FakeIsar(this.tag);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('IsarStateNotifier & isarProvider Tests', () {
    test('IsarStateNotifier initializes with starting instance and updates state', () {
      final isarA = FakeIsar('A');
      final isarB = FakeIsar('B');

      final notifier = IsarStateNotifier(isarA);
      expect(notifier.state, equals(isarA));

      notifier.updateIsar(isarB);
      expect(notifier.state, equals(isarB));
    });

    test('isarProvider allows dynamic updates in ProviderContainer', () {
      final isarA = FakeIsar('Instance_A');
      final isarB = FakeIsar('Instance_B');

      final container = ProviderContainer(
        overrides: [
          isarProvider.overrideWith((ref) => IsarStateNotifier(isarA)),
        ],
      );

      try {
        // Initial state check
        expect(container.read(isarProvider), equals(isarA));

        // Update to new Isar instance
        container.read(isarProvider.notifier).updateIsar(isarB);

        // State reflects the new instance
        expect(container.read(isarProvider), equals(isarB));
      } finally {
        container.dispose();
      }
    });
  });
}
