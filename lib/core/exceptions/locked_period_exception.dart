class LockedPeriodException implements Exception {
  final String message;

  LockedPeriodException([this.message = 'Periode ini sudah tutup buku dan tidak dapat diubah.']);

  @override
  String toString() => message;
}
