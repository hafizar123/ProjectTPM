import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// Data model satu rekomendasi layanan.
class ServiceRecommendation {
  final String serviceName;
  final String reason;
  final String icon;
  final String priceRange;
  final double similarityScore;

  const ServiceRecommendation({
    required this.serviceName,
    required this.reason,
    required this.icon,
    required this.priceRange,
    this.similarityScore = 0.0,
  });
}

class RecommendationService {
  static String get _baseUrl => AuthService.baseUrl;

  // Feature matrix 8 dimensi per layanan
  // kebersihan_umum, teknis, relaksasi, kendaraan, kasur_sofa, harga_rendah, harga_sedang, harga_tinggi
  static const Map<String, List<double>> _serviceVectors = {
    'Pemanas Air':      [0, 1, 0, 0, 0, 0, 1, 0],
    'Reguler Cleaning': [1, 0, 0, 0, 0, 1, 0, 0],
    'Cuci Kendaraan':   [0, 0, 0, 1, 0, 1, 0, 0],
    'Cuci Kasur':       [0, 0, 0, 0, 1, 0, 1, 0],
    'Deep Cleaning':    [1, 0, 0, 0, 0, 0, 0, 1],
    'Pijat Relaksasi':  [0, 0, 1, 0, 0, 0, 1, 0],
    'Service AC':       [0, 1, 0, 0, 0, 0, 1, 0],
    'Cuci Sofa':        [0, 0, 0, 0, 1, 0, 1, 0],
  };

  static const Map<String, String> _serviceIcons = {
    'Pemanas Air':      '🔥',
    'Reguler Cleaning': '🧹',
    'Cuci Kendaraan':   '🚗',
    'Cuci Kasur':       '🛏️',
    'Deep Cleaning':    '🏠',
    'Pijat Relaksasi':  '💆',
    'Service AC':       '❄️',
    'Cuci Sofa':        '🛋️',
  };

  static const Map<String, String> _servicePrices = {
    'Pemanas Air':      'Rp 100.000 – 250.000',
    'Reguler Cleaning': 'Rp 80.000 – 280.000',
    'Cuci Kendaraan':   'Rp 25.000 – 120.000',
    'Cuci Kasur':       'Rp 150.000 – 300.000',
    'Deep Cleaning':    'Rp 350.000 – 950.000',
    'Pijat Relaksasi':  'Rp 100.000 – 200.000',
    'Service AC':       'Rp 100.000 – 400.000',
    'Cuci Sofa':        'Rp 120.000 – 350.000',
  };

  static const Map<String, String> _serviceReasons = {
    'Pemanas Air':      'Perawatan teknis rumah yang sering dibutuhkan',
    'Reguler Cleaning': 'Jaga kebersihan hunian secara rutin',
    'Cuci Kendaraan':   'Kendaraan bersih meningkatkan kenyamanan berkendara',
    'Cuci Kasur':       'Kasur bersih untuk tidur lebih berkualitas',
    'Deep Cleaning':    'Bersihkan hunian secara menyeluruh dan mendetail',
    'Pijat Relaksasi':  'Pulihkan energi setelah aktivitas padat',
    'Service AC':       'AC terawat hemat listrik dan udara lebih segar',
    'Cuci Sofa':        'Sofa bersih untuk ruang tamu yang nyaman',
  };

  // Cosine similarity dua vektor
  double _cosineSimilarity(List<double> a, List<double> b) {
    double dot = 0, magA = 0, magB = 0;
    for (int i = 0; i < a.length; i++) {
      dot  += a[i] * b[i];
      magA += a[i] * a[i];
      magB += b[i] * b[i];
    }
    final denom = sqrt(magA) * sqrt(magB);
    return denom == 0 ? 0 : dot / denom;
  }

  // Bangun user profile vector dari histori order
  List<double> _buildUserProfile(Map<String, int> serviceCount) {
    final profile = List<double>.filled(8, 0);
    int totalWeight = 0;

    for (final entry in serviceCount.entries) {
      final vec = _serviceVectors[entry.key];
      if (vec == null) continue;
      for (int i = 0; i < 8; i++) {
        profile[i] += vec[i] * entry.value;
      }
      totalWeight += entry.value;
    }

    if (totalWeight > 0) {
      for (int i = 0; i < 8; i++) {
        profile[i] /= totalWeight;
      }
    }
    return profile;
  }

  /// Ambil rekomendasi untuk user yang sudah login (Content-Based Filtering).
  Future<List<ServiceRecommendation>> getRecommendations(String email) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/orders/$email'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return _getPopularRecommendations();

      final body = jsonDecode(response.body);
      final List<dynamic> orders = body['data'] ?? [];

      if (orders.isEmpty) return _getPopularRecommendations();

      final Map<String, int> serviceCount = {};
      final Set<String> orderedSet = {};

      for (final order in orders) {
        final raw = (order['service_name'] ?? '').toString();
        // Ambil kategori utama, abaikan sub-paket setelah ' - ' atau ' - '
        final category = raw.contains(' – ')
            ? raw.split(' – ')[0].trim()
            : raw.contains(' - ')
                ? raw.split(' - ')[0].trim()
                : raw;

        if (_serviceVectors.containsKey(category)) {
          serviceCount[category] = (serviceCount[category] ?? 0) + 1;
          orderedSet.add(category);
        }
      }

      final userProfile = _buildUserProfile(serviceCount);

      final allServices = _serviceVectors.keys.toList();
      final candidates = allServices
          .where((name) => !orderedSet.contains(name))
          .map((name) => MapEntry(
                name,
                _cosineSimilarity(userProfile, _serviceVectors[name]!),
              ))
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final top3 = candidates.take(3).toList();
      if (top3.length < 3) {
        final usedNames = top3.map((e) => e.key).toSet();
        final extras = allServices
            .where((name) => orderedSet.contains(name) && !usedNames.contains(name))
            .map((name) => MapEntry(
                  name,
                  _cosineSimilarity(userProfile, _serviceVectors[name]!),
                ))
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        top3.addAll(extras.take(3 - top3.length));
      }

      final seen = <String>{};
      final unique = top3.where((e) => seen.add(e.key)).toList();

      return unique.map((e) => ServiceRecommendation(
        serviceName: e.key,
        reason: _serviceReasons[e.key] ?? 'Layanan yang cocok untuk Anda',
        icon: _serviceIcons[e.key] ?? '✨',
        priceRange: _servicePrices[e.key] ?? '-',
        similarityScore: double.parse(e.value.toStringAsFixed(4)),
      )).toList();

    } catch (_) {
      return _getPopularRecommendations();
    }
  }

  /// Rekomendasi untuk guest, diurutkan dari rating tertinggi di backend.
  Future<List<ServiceRecommendation>> getPopularPublicAsync() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/order-reviews'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> reviews = body['data'] ?? [];

        if (reviews.isNotEmpty) {
          // Rata-rata rating per layanan
          final Map<String, List<double>> ratingMap = {};
          for (final r in reviews) {
            final raw = (r['service_name'] ?? '').toString();
            final category = raw.contains(' – ')
                ? raw.split(' – ')[0].trim()
                : raw.contains(' - ')
                    ? raw.split(' - ')[0].trim()
                    : raw;
            final rating = double.tryParse(r['rating']?.toString() ?? '0') ?? 0;
            if (_serviceVectors.containsKey(category)) {
              ratingMap.putIfAbsent(category, () => []).add(rating);
            }
          }

          final ranked = ratingMap.entries
              .map((e) => MapEntry(
                    e.key,
                    e.value.reduce((a, b) => a + b) / e.value.length,
                  ))
              .toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          if (ranked.isNotEmpty) {
            final top = ranked.take(3).toList();
            final usedNames = top.map((e) => e.key).toSet();
            if (top.length < 3) {
              final defaults = ['Reguler Cleaning', 'Service AC', 'Cuci Kasur']
                  .where((n) => !usedNames.contains(n))
                  .take(3 - top.length);
              for (final n in defaults) {
                top.add(MapEntry(n, 0.0));
              }
            }

            return top.map((e) => ServiceRecommendation(
              serviceName: e.key,
              reason: _serviceReasons[e.key] ?? 'Layanan populer pilihan pengguna',
              icon: _serviceIcons[e.key] ?? '✨',
              priceRange: _servicePrices[e.key] ?? '-',
              similarityScore: double.parse(e.value.toStringAsFixed(2)),
            )).toList();
          }
        }
      }
    } catch (_) {}

    return _getPopularRecommendations();
  }

  /// Sync fallback untuk guest (dipakai kalau async gagal)
  List<ServiceRecommendation> getPopularPublic() => _getPopularRecommendations();

  List<ServiceRecommendation> _getPopularRecommendations() {
    return const [
      ServiceRecommendation(
        serviceName: 'Reguler Cleaning',
        reason: 'Layanan terpopuler untuk hunian bersih setiap hari',
        icon: '🧹',
        priceRange: 'Rp 80.000 – 280.000',
      ),
      ServiceRecommendation(
        serviceName: 'Service AC',
        reason: 'Perawatan rutin AC agar udara tetap segar',
        icon: '❄️',
        priceRange: 'Rp 100.000 – 400.000',
      ),
      ServiceRecommendation(
        serviceName: 'Cuci Kasur',
        reason: 'Tidur lebih nyaman dengan kasur bebas tungau',
        icon: '🛏️',
        priceRange: 'Rp 150.000 – 300.000',
      ),
    ];
  }
}
