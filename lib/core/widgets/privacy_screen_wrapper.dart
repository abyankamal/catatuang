import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/pin_lock_screen.dart';
import '../../features/settings/application/settings_providers.dart';

/// Wrapper widget untuk memberikan efek blur murni ketika aplikasi
/// berada di background/app switcher, serta gerbang penguncian PIN 6-digit.
class PrivacyScreenWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const PrivacyScreenWrapper({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<PrivacyScreenWrapper> createState() => _PrivacyScreenWrapperState();
}

class _PrivacyScreenWrapperState extends ConsumerState<PrivacyScreenWrapper>
    with WidgetsBindingObserver {
  bool _isBackground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Aktifkan blur ketika aplikasi tidak berada dalam foreground aktif (resumed)
    final isBackground = state != AppLifecycleState.resumed;

    if (state == AppLifecycleState.paused) {
      // Kunci kembali jika PIN aktif saat aplikasi berpindah ke background
      final isPinEnabled =
          ref.read(appSettingsStreamProvider).valueOrNull?.isPinEnabled ?? false;
      if (isPinEnabled) {
        ref.read(isAppUnlockedProvider.notifier).state = false;
      }
    }

    if (_isBackground != isBackground) {
      setState(() {
        _isBackground = isBackground;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(appSettingsStreamProvider);
    final settings = settingsAsync.valueOrNull;
    final isPrivacyEnabled = settings?.isPrivacyScreenEnabled ?? true;
    final isPinEnabled = settings?.isPinEnabled ?? false;
    final isUnlocked = ref.watch(isAppUnlockedProvider);

    final shouldBlur = _isBackground && isPrivacyEnabled;
    final shouldShowPinLock = isPinEnabled && !isUnlocked;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Konten utama aplikasi
        widget.child,

        // Layer Privasi: Murni Gaussian Blur
        if (shouldBlur)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
              child: Container(
                color: Colors.black.withValues(alpha: 0.15),
              ),
            ),
          ),

        // Layer Kunci PIN: Tampilkan jika PIN diaktifkan dan belum di-unlock
        if (shouldShowPinLock)
          Positioned.fill(
            child: PinLockScreen(
              mode: PinLockMode.unlock,
              onSuccess: () {
                ref.read(isAppUnlockedProvider.notifier).state = true;
              },
            ),
          ),
      ],
    );
  }
}
