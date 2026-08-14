import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/application/settings_providers.dart';

/// Wrapper widget untuk memberikan efek blur murni ketika aplikasi
/// berada di background, app switcher, atau inactive state.
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

    if (_isBackground != isBackground) {
      setState(() {
        _isBackground = isBackground;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(appSettingsStreamProvider);
    final isPrivacyEnabled =
        settingsAsync.valueOrNull?.isPrivacyScreenEnabled ?? true;

    final shouldBlur = _isBackground && isPrivacyEnabled;

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
      ],
    );
  }
}
