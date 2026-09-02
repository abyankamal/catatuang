import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

class PinSecurityHelper {
  static const _uuid = Uuid();

  /// Hasilkan salt unik acak
  static String generateSalt() {
    return _uuid.v4();
  }

  /// Hitung hash SHA-256 dari PIN 6-digit dan salt
  static String hashPin(String pin, String salt) {
    final bytes = utf8.encode('$pin:$salt:catatuang_secure_pin');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verifikasi apakah PIN yang dimasukkan cocok dengan hash dan salt yang tersimpan
  static bool verifyPin({
    required String enteredPin,
    required String storedHash,
    required String storedSalt,
  }) {
    final computedHash = hashPin(enteredPin, storedSalt);
    return computedHash == storedHash;
  }
}
