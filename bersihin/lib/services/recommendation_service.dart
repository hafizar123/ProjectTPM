import 'dart:convert';
import 'package:http/http.dart' as http;

/// Model data untuk satu rekomendasi layanan
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
  static const String _baseUrl = 'http://192.168.18.7:3000/api';

  /// Ambil rekomendasi dari endpoint ML Content-Based Filtering di backend
  Future<List<ServiceRecommendation>> getRecommendations(String email) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/recommendations/$email'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> data = body['data'] ?? [];

        if (data.isEmpty) return _getPopularRecommendations();

        return data.map((item) => ServiceRecommendation(
          serviceName: item['service_name'] ?? '',
          reason: item['reason'] ?? '',
          icon: item['icon'] ?? '✨',
          priceRange: item['price_range'] ?? '-',
          similarityScore: (item['similarity_score'] ?? 0.0).toDouble(),
        )).toList();
      }

      return _getFallbackRecommendations();
    } catch (_) {
      return _getFallbackRecommendations();
    }
  }

  /// Rekomendasi populer untuk guest (public, tanpa login)
  List<ServiceRecommendation> getPopularPublic() => _getPopularRecommendations();

  /// Rekomendasi populer untuk user baru (belum punya order)
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

  /// Fallback jika backend tidak bisa diakses
  List<ServiceRecommendation> _getFallbackRecommendations() {
    return const [
      ServiceRecommendation(
        serviceName: 'Deep Cleaning',
        reason: 'Bersihkan hunian secara menyeluruh dan mendetail',
        icon: '🏠',
        priceRange: 'Rp 350.000 – 950.000',
      ),
      ServiceRecommendation(
        serviceName: 'Pijat Relaksasi',
        reason: 'Pulihkan energi dengan pijat profesional di rumah',
        icon: '💆',
        priceRange: 'Rp 100.000 – 200.000',
      ),
      ServiceRecommendation(
        serviceName: 'Cuci Sofa',
        reason: 'Sofa bersih untuk ruang tamu yang nyaman',
        icon: '🛋️',
        priceRange: 'Rp 120.000 – 350.000',
      ),
    ];
  }
}
