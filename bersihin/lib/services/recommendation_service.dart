import 'package:google_generative_ai/google_generative_ai.dart';
import 'auth_service.dart';

/// Model data untuk satu rekomendasi layanan
class ServiceRecommendation {
  final String serviceName;
  final String reason;
  final String icon;
  final String priceRange;

  const ServiceRecommendation({
    required this.serviceName,
    required this.reason,
    required this.icon,
    required this.priceRange,
  });
}

class RecommendationService {
  final String _apiKey = 'AIzaSyA90Y0qej5QPk-UodJHohq8KeV_HHq4QaQ';
  final AuthService _authService = AuthService();

  // Map nama layanan ke icon & harga
  static const Map<String, Map<String, String>> _serviceInfo = {
    'Pemanas Air':      {'icon': '🔥', 'price': 'Rp 100.000 – 250.000'},
    'Reguler Cleaning': {'icon': '🧹', 'price': 'Rp 80.000 – 280.000'},
    'Cuci Kendaraan':   {'icon': '🚗', 'price': 'Rp 25.000 – 120.000'},
    'Cuci Kasur':       {'icon': '🛏️', 'price': 'Rp 150.000 – 300.000'},
    'Deep Cleaning':    {'icon': '🏠', 'price': 'Rp 350.000 – 950.000'},
    'Pijat Relaksasi':  {'icon': '💆', 'price': 'Rp 100.000 – 200.000'},
    'Service AC':       {'icon': '❄️', 'price': 'Rp 100.000 – 400.000'},
    'Cuci Sofa':        {'icon': '🛋️', 'price': 'Rp 120.000 – 350.000'},
    'Langganan Bulanan':{'icon': '📅', 'price': 'Rp 450.000 – 1.100.000'},
  };

  /// Ambil rekomendasi berdasarkan histori order user
  Future<List<ServiceRecommendation>> getRecommendations(String email) async {
    try {
      // 1. Ambil histori order user
      final ordersRes = await _authService.getOrders(email);
      if (ordersRes['statusCode'] != 200) return _getFallbackRecommendations();

      final List<dynamic> orders = ordersRes['body']['data'] ?? [];

      // 2. Kalau belum punya order, kasih rekomendasi populer
      if (orders.isEmpty) return _getPopularRecommendations();

      // 3. Susun ringkasan histori untuk dikirim ke Gemini
      final Map<String, int> serviceCount = {};
      final List<String> recentServices = [];

      for (final order in orders) {
        final name = (order['service_name'] ?? '').toString();
        // Ambil nama kategori utama (sebelum ' – ')
        final category = name.contains(' – ') ? name.split(' – ')[0].trim() : name;
        serviceCount[category] = (serviceCount[category] ?? 0) + 1;
        if (recentServices.length < 5) recentServices.add(category);
      }

      final historySummary = serviceCount.entries
          .map((e) => '${e.key} (${e.value}x)')
          .join(', ');

      // 4. Kirim ke Gemini
      final model = GenerativeModel(
        model: 'gemini-flash-latest',
        apiKey: _apiKey,
      );

      final prompt = '''
Kamu adalah sistem rekomendasi layanan kebersihan untuk aplikasi Bersih.In.

Histori layanan yang pernah dipesan user: $historySummary
Layanan terakhir dipesan: ${recentServices.first}

Layanan yang tersedia:
- Pemanas Air
- Reguler Cleaning
- Cuci Kendaraan
- Cuci Kasur
- Deep Cleaning
- Pijat Relaksasi
- Service AC
- Cuci Sofa
- Langganan Bulanan

Berikan TEPAT 3 rekomendasi layanan yang paling relevan untuk user ini.
Jawab HANYA dalam format JSON array berikut, tanpa teks lain:
[
  {"service": "Nama Layanan", "reason": "Alasan singkat 1 kalimat max 10 kata"},
  {"service": "Nama Layanan", "reason": "Alasan singkat 1 kalimat max 10 kata"},
  {"service": "Nama Layanan", "reason": "Alasan singkat 1 kalimat max 10 kata"}
]
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';

      return _parseGeminiResponse(text);
    } catch (e) {
      return _getFallbackRecommendations();
    }
  }

  /// Parse response JSON dari Gemini
  List<ServiceRecommendation> _parseGeminiResponse(String text) {
    try {
      // Ekstrak JSON dari response (kadang Gemini bungkus dengan markdown)
      final jsonStart = text.indexOf('[');
      final jsonEnd = text.lastIndexOf(']');
      if (jsonStart == -1 || jsonEnd == -1) return _getFallbackRecommendations();

      final jsonStr = text.substring(jsonStart, jsonEnd + 1);

      // Parse manual tanpa dart:convert untuk keamanan
      final List<ServiceRecommendation> result = [];
      final regex = RegExp(r'"service"\s*:\s*"([^"]+)".*?"reason"\s*:\s*"([^"]+)"', dotAll: true);
      final matches = regex.allMatches(jsonStr);

      for (final match in matches) {
        final serviceName = match.group(1) ?? '';
        final reason = match.group(2) ?? '';
        final info = _serviceInfo[serviceName] ?? {'icon': '✨', 'price': 'Lihat detail'};

        result.add(ServiceRecommendation(
          serviceName: serviceName,
          reason: reason,
          icon: info['icon']!,
          priceRange: info['price']!,
        ));
      }

      return result.isNotEmpty ? result : _getFallbackRecommendations();
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

  /// Fallback jika Gemini gagal
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
        serviceName: 'Langganan Bulanan',
        reason: 'Hemat lebih banyak dengan paket berlangganan',
        icon: '📅',
        priceRange: 'Rp 450.000 – 1.100.000',
      ),
    ];
  }
}
