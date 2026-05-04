/// Layanan konversi mata uang dengan kurs tetap (fixed rate).
/// Kurs diperbarui secara manual sesuai referensi Bank Indonesia.
class CurrencyService {
  // ── Kurs terhadap IDR (1 unit mata uang asing = X IDR) ──────
  static const Map<String, double> _rateToIdr = {
    'IDR': 1.0,
    'CNY': 2250.0,   // 1 CNY ≈ Rp 2.250  (Bank of China)
    'SGD': 11500.0,  // 1 SGD ≈ Rp 11.500 (United Overseas Bank)
    'SAR': 4100.0,   // 1 SAR ≈ Rp 4.100  (Saudi National Bank)
  };

  // ── Simbol mata uang ─────────────────────────────────────────
  static const Map<String, String> symbol = {
    'IDR': 'Rp',
    'CNY': '¥',
    'SGD': 'S\$',
    'SAR': 'SAR',
  };

  // ── Nama lengkap mata uang ───────────────────────────────────
  static const Map<String, String> name = {
    'IDR': 'Rupiah Indonesia',
    'CNY': 'Yuan Tiongkok',
    'SGD': 'Dolar Singapura',
    'SAR': 'Riyal Arab Saudi',
  };

  // ── Nama bank internasional ──────────────────────────────────
  static const Map<String, String> bankName = {
    'CNY': 'Bank of China',
    'SGD': 'United Overseas Bank',
    'SAR': 'Saudi National Bank',
  };

  // ── Kode bank untuk payment method ──────────────────────────
  static const Map<String, String> bankCode = {
    'CNY': 'bank_of_china',
    'SGD': 'united_overseas_bank',
    'SAR': 'saudi_national_bank',
  };

  /// Konversi dari IDR ke mata uang target.
  /// Mengembalikan nilai dalam mata uang target (double).
  static double fromIdr(int amountIdr, String targetCurrency) {
    final rate = _rateToIdr[targetCurrency] ?? 1.0;
    return amountIdr / rate;
  }

  /// Format angka ke string dengan simbol mata uang.
  static String format(double amount, String currency) {
    final sym = symbol[currency] ?? currency;
    if (currency == 'IDR') {
      // Format IDR: Rp 1.500.000
      final idr = amount.round();
      return '$sym ${idr.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      )}';
    } else if (currency == 'CNY' || currency == 'SGD') {
      // Format desimal 2 angka
      return '$sym ${amount.toStringAsFixed(2)}';
    } else {
      // SAR — 2 desimal
      return '$sym ${amount.toStringAsFixed(2)}';
    }
  }

  /// Format langsung dari IDR ke mata uang target.
  static String formatFromIdr(int amountIdr, String targetCurrency) {
    return format(fromIdr(amountIdr, targetCurrency), targetCurrency);
  }

  /// Daftar semua kode mata uang yang tersedia.
  static List<String> get allCurrencies => _rateToIdr.keys.toList();
}
