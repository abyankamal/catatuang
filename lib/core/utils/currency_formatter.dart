import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// Format nominal ke string Rupiah (contoh: 1500000 -> "Rp 1.500.000")
  static String format(double amount) {
    if (amount < 0) {
      final positive = _currencyFormat.format(amount.abs());
      return '-$positive';
    }
    return _currencyFormat.format(amount);
  }

  /// Format angka ringkas (contoh: 1500000 -> "Rp 1,5 Jt") jika ruang terbatas
  static String formatCompact(double amount) {
    final absAmount = amount.abs();
    final prefix = amount < 0 ? '-Rp ' : 'Rp ';

    if (absAmount >= 1000000000) {
      return '$prefix${(absAmount / 1000000000).toStringAsFixed(1)} M';
    } else if (absAmount >= 1000000) {
      return '$prefix${(absAmount / 1000000).toStringAsFixed(1)} Jt';
    } else if (absAmount >= 1000) {
      return '$prefix${(absAmount / 1000).toStringAsFixed(0)} Rb';
    }
    return format(amount);
  }
}
