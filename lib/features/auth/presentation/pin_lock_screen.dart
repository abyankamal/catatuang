import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../settings/application/settings_providers.dart';

enum PinLockMode {
  unlock, // Layar kunci saat membuka aplikasi
  create, // Membuat PIN baru pertama kali
  change, // Mengubah PIN lama
}

class PinLockScreen extends ConsumerStatefulWidget {
  final PinLockMode mode;
  final VoidCallback? onSuccess;
  final VoidCallback? onCancel;

  const PinLockScreen({
    super.key,
    this.mode = PinLockMode.unlock,
    this.onSuccess,
    this.onCancel,
  });

  @override
  ConsumerState<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends ConsumerState<PinLockScreen> {
  String _enteredPin = '';
  String _tempNewPin = '';
  String? _errorMessage;
  int _step = 1; // 1: Input / Old PIN, 2: New PIN / Confirm, 3: Confirm New PIN

  void _onNumberPressed(String number) {
    if (_enteredPin.length >= 6) return;

    setState(() {
      _errorMessage = null;
      _enteredPin += number;
    });

    if (_enteredPin.length == 6) {
      _processCompletePin(_enteredPin);
    }
  }

  void _onBackspacePressed() {
    if (_enteredPin.isEmpty) return;
    setState(() {
      _errorMessage = null;
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
    });
  }

  Future<void> _processCompletePin(String pin) async {
    final controller = ref.read(settingsControllerProvider.notifier);

    switch (widget.mode) {
      case PinLockMode.unlock:
        final isValid = await controller.verifyPin(pin);
        if (isValid) {
          widget.onSuccess?.call();
        } else {
          setState(() {
            _enteredPin = '';
            _errorMessage = 'PIN salah. Silakan coba lagi.';
          });
        }
        break;

      case PinLockMode.create:
        if (_step == 1) {
          setState(() {
            _tempNewPin = pin;
            _enteredPin = '';
            _step = 2;
          });
        } else if (_step == 2) {
          if (pin == _tempNewPin) {
            final success = await controller.setPin(pin);
            if (success) {
              widget.onSuccess?.call();
            } else {
              setState(() {
                _enteredPin = '';
                _errorMessage = 'Gagal menyimpan PIN baru.';
              });
            }
          } else {
            setState(() {
              _enteredPin = '';
              _step = 1;
              _errorMessage = 'Konfirmasi PIN tidak cocok. Ulangi dari awal.';
            });
          }
        }
        break;

      case PinLockMode.change:
        if (_step == 1) {
          final isOldValid = await controller.verifyPin(pin);
          if (isOldValid) {
            setState(() {
              _enteredPin = '';
              _step = 2;
            });
          } else {
            setState(() {
              _enteredPin = '';
              _errorMessage = 'PIN lama salah.';
            });
          }
        } else if (_step == 2) {
          setState(() {
            _tempNewPin = pin;
            _enteredPin = '';
            _step = 3;
          });
        } else if (_step == 3) {
          if (pin == _tempNewPin) {
            final success = await controller.setPin(pin);
            if (success) {
              widget.onSuccess?.call();
            } else {
              setState(() {
                _enteredPin = '';
                _errorMessage = 'Gagal memperbarui PIN.';
              });
            }
          } else {
            setState(() {
              _enteredPin = '';
              _step = 2;
              _errorMessage = 'Konfirmasi PIN baru tidak cocok.';
            });
          }
        }
        break;
    }
  }

  String get _title {
    switch (widget.mode) {
      case PinLockMode.unlock:
        return 'Buka Kunci Aplikasi';
      case PinLockMode.create:
        return _step == 1 ? 'Buat PIN 6-Digit' : 'Konfirmasi PIN Baru';
      case PinLockMode.change:
        if (_step == 1) return 'Masukkan PIN Saat Ini';
        if (_step == 2) return 'Buat PIN Baru';
        return 'Konfirmasi PIN Baru';
    }
  }

  String get _subtitle {
    switch (widget.mode) {
      case PinLockMode.unlock:
        return 'Masukkan 6 digit PIN untuk mengakses CatatUang';
      case PinLockMode.create:
        return _step == 1
            ? 'Pilih 6 digit angka yang mudah Anda ingat'
            : 'Masukkan kembali 6 digit PIN untuk verifikasi';
      case PinLockMode.change:
        if (_step == 1) return 'Verifikasi PIN lama sebelum mengubahnya';
        if (_step == 2) return 'Masukkan 6 digit PIN baru yang Anda inginkan';
        return 'Ulangi 6 digit PIN baru untuk memastikan kecocokan';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: widget.onCancel != null
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.secondary),
                onPressed: widget.onCancel,
              ),
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            children: [
              const Spacer(flex: 1),

              // Icon Lock
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  size: 36,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                _title,
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                _subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              // 6-Digit Indicator Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  final isFilled = index < _enteredPin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: isFilled ? 18 : 14,
                    height: isFilled ? 18 : 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled ? AppColors.primary : Colors.grey.shade300,
                      border: isFilled
                          ? Border.all(color: AppColors.primary, width: 2)
                          : null,
                    ),
                  );
                }),
              ),

              const SizedBox(height: 16),

              // Error Message
              SizedBox(
                height: 24,
                child: _errorMessage != null
                    ? Text(
                        _errorMessage!,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.expense,
                        ),
                      )
                    : null,
              ),

              const Spacer(flex: 2),

              // Custom Numeric Keypad
              _buildKeypad(),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        _buildKeypadRow(['1', '2', '3']),
        const SizedBox(height: 16),
        _buildKeypadRow(['4', '5', '6']),
        const SizedBox(height: 16),
        _buildKeypadRow(['7', '8', '9']),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 72, height: 72), // Empty placeholder
            _buildKeypadButton('0'),
            SizedBox(
              width: 72,
              height: 72,
              child: IconButton(
                onPressed: _onBackspacePressed,
                icon: const Icon(
                  Icons.backspace_outlined,
                  size: 26,
                  color: AppColors.secondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeypadRow(List<String> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((n) => _buildKeypadButton(n)).toList(),
    );
  }

  Widget _buildKeypadButton(String number) {
    return Material(
      color: Colors.grey.shade100,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => _onNumberPressed(number),
        child: Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          child: Text(
            number,
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
        ),
      ),
    );
  }
}
