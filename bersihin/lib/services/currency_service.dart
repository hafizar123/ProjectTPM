import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// Layanan konversi mata uang dengan kurs live dari backend.
/// Backend fetch dari open.er-api.com dan cache 1 jam.
class CurrencyService {
  // Kurs fallback jika backend tidak bisa dijangkau
  static const Map<String, double> _fallbackRates = {
    'IDR': 1.0,
    'CNY': 2250.0,
    'SGD': 11500.0,
    'SAR': 4100.0,
  };

  // Cache in-memory, valid selama 1 jam
  static Map<String, double>? _cachedRates;
  static DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(hours: 1);

  // Simbol mata uang
  static const Map<String, String> symbol = {
    'IDR': 'Rp',
    'CNY': '¥',
    'SGD': 'S\$',
    'SAR': 'SAR',
  };

  // Nama lengkap mata uang
  static const Map<String, String> name = {
    'IDR': 'Rupiah Indonesia',
    'CNY': 'Yuan Tiongkok',
    'SGD': 'Dolar Singapura',
    'SAR': 'Riyal Arab Saudi',
  };

  // Nama bank internasional
  static const Map<String, String> bankName = {
    'CNY': 'Bank of China',
    'SGD': 'United Overseas Bank',
    'SAR': 'Saudi National Bank',
  };

  // Kode bank untuk metode pembayaran
  static const Map<String, String> bankCode = {
    'CNY': 'bank_of_china',
    'SGD': 'united_overseas_bank',
    'SAR': 'saudi_national_bank',
  };

  /// Ambil kurs terkini dari backend, cache 1 jam di Flutter.
  static Future<Map<String, double>> getRates() async {
    if (_cachedRates != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      return _cachedRates!;
    }

    try {
      final response = await http
          .get(Uri.parse('${AuthService.baseUrl}/exchange-rates'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final rawRates = body['rates'] as Map<String, dynamic>;

        final rates = <String, double>{'IDR': 1.0};
        for (final entry in rawRates.entries) {
          final val = double.tryParse(entry.value.toString());
          if (val != null && val > 0) {
            rates[entry.key] = val;
          }
        }

        _cachedRates = rates;
        _cacheTime   = DateTime.now();
        return rates;
      }
    } catch (_) {}

    if (_cachedRates != null) return _cachedRates!;
    return _fallbackRates;
  }

  /// Konversi IDR ke mata uang target, async (live rates).
  static Future<double> fromIdrAsync(int amountIdr, String targetCurrency) async {
    if (targetCurrency == 'IDR') return amountIdr.toDouble();
    final rates = await getRates();
    final rate = rates[targetCurrency] ?? _fallbackRates[targetCurrency] ?? 1.0;
    return amountIdr / rate;
  }

  /// Konversi IDR ke mata uang target, sync (pakai cache, panggil getRates dulu).
  static double fromIdr(int amountIdr, String targetCurrency) {
    if (targetCurrency == 'IDR') return amountIdr.toDouble();
    final rates = _cachedRates ?? _fallbackRates;
    final rate  = rates[targetCurrency] ?? _fallbackRates[targetCurrency] ?? 1.0;
    return amountIdr / rate;
  }

  /// Format angka ke string dengan simbol mata uang.
  static String format(double amount, String currency) {    final sym = symbol[currency] ?? currency;
    if (currency == 'IDR') {
      final idr = amount.round();
      return '$sym ${idr.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      )}';
    }
    return '$sym ${amount.toStringAsFixed(2)}';
  }

  /// Format IDR ke mata uang target, async.
  static Future<String> formatFromIdrAsync(int amountIdr, String targetCurrency) async {
    final converted = await fromIdrAsync(amountIdr, targetCurrency);
    return format(converted, targetCurrency);
  }

  /// Format IDR ke mata uang target, sync.
  static String formatFromIdr(int amountIdr, String targetCurrency) {
    return format(fromIdr(amountIdr, targetCurrency), targetCurrency);
  }

  /// Paksa refresh cache kurs.
  static void invalidateCache() {
    _cachedRates = null;
    _cacheTime   = null;
  }

  /// Semua kode mata uang yang tersedia.
  static List<String> get allCurrencies => _fallbackRates.keys.toList();
}
