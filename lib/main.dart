import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/database/database_provider.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Indonesian locale formatting
  await initializeDateFormatting('id_ID', null);

  // Initialize Isar database
  final isar = await openIsar();

  runApp(
    ProviderScope(
      overrides: [
        isarProvider.overrideWithValue(isar),
      ],
      child: const CatatUangApp(),
    ),
  );
}

/// Custom ScrollBehavior untuk menghilangkan efek memuai (stretch overscroll) secara global
class NoStretchScrollBehavior extends MaterialScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child; // Menghilangkan indikator peregangan/stretch visual
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    // Menggunakan ClampingScrollPhysics agar posisi tampilan tetap menempel (clamp) tanpa memuai
    return const ClampingScrollPhysics();
  }

}

class CatatUangApp extends StatelessWidget {
  const CatatUangApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CatatUang',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      scrollBehavior: NoStretchScrollBehavior(),
      routerConfig: appRouter,
    );
  }
}
