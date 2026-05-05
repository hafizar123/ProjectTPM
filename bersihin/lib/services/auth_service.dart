import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  // Alamat IP server berada di sini.
  // Ganti nilai ini jika ingin menguji menggunakan jaringan WiFi atau perangkat lain.
  static const String baseUrl = 'http://192.168.18.7:3000/api';

  // ── PENDAFTARAN AKUN ─────────────────────────────────────────
  Future<Map<String, dynamic>> register(String email, String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'username': username,
          'password': password,
        }),
      );
      
      return {
        'statusCode': response.statusCode,
        'body': jsonDecode(response.body)
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'body': {'message': 'Terjadi kesalahan pada server: \$e'}
      };
    }
  }

  // Login biometrik — tanpa password, cukup email
  Future<Map<String, dynamic>> biometricLogin(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/biometric-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      return {
        'statusCode': response.statusCode,
        'body': jsonDecode(response.body),
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'body': {'message': 'Terjadi kesalahan pada server'},
      };
    }
  }

  // ── MASUK AKUN ───────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      
      return {
        'statusCode': response.statusCode,
        'body': jsonDecode(response.body)
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'body': {'message': 'Terjadi kesalahan pada server: \$e'}
      };
    }
  }

  // ── PROFIL PENGGUNA ───────────────────────────────────────────
  Future<Map<String, dynamic>> getProfile(String email) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/profile/$email'));
      return {
        'statusCode': response.statusCode,
        'body': jsonDecode(response.body)
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'body': {'message': 'Terjadi kesalahan pada server: \$e'}
      };
    }
  }

  Future<Map<String, dynamic>> updateProfile(String oldEmail, String email, String username, String password, {String? avatarUrl}) async {
    try {
      // Bangun body — hanya sertakan avatar_url jika ada nilainya
      // Jika null, JANGAN kirim field ini agar server tidak menghapus foto yang sudah ada
      final Map<String, dynamic> body = {
        'oldEmail': oldEmail,
        'email': email,
        'username': username,
        'password': password,
      };
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        body['avatar_url'] = avatarUrl;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/update-profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      return {'statusCode': response.statusCode, 'body': jsonDecode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'body': {'message': 'Terjadi kesalahan pada server: \$e'}};
    }
  }

  // ── HAPUS AKUN ───────────────────────────────────────────────
  Future<Map<String, dynamic>> deleteAccount(String email) async {
    final response = await http.delete(Uri.parse('$baseUrl/delete-account/$email'));
    return {'statusCode': response.statusCode, 'body': jsonDecode(response.body)};
  }

  // ==========================================
  // FITUR ALAMAT TERSIMPAN
  // ==========================================

  // ── MENGAMBIL DAFTAR ALAMAT ───────────────────────────────────
  Future<Map<String, dynamic>> getSavedAddresses(String username) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get_addresses?username=$username'),
      );
      
      return {
        'statusCode': response.statusCode,
        'body': jsonDecode(response.body)
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'body': {'error': 'Terjadi kesalahan pada server: \$e'}
      };
    }
  }

  // ── MENYIMPAN ALAMAT BARU ─────────────────────────────────────
  Future<Map<String, dynamic>> saveNewAddress(String username, String address, String lat, String lng, String houseType, String description) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/save_address'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'address': address,
          'lat': lat,
          'lng': lng,
          'house_type': houseType,
          'description': description,
        }),
      );
      return {'statusCode': response.statusCode, 'body': jsonDecode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'body': {'error': 'Terjadi kesalahan pada server: \$e'}};
    }
  }

  // ── MENGHAPUS ALAMAT ──────────────────────────────────────────
  Future<Map<String, dynamic>> deleteAddress(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/delete_address/$id'));
      return {'statusCode': response.statusCode, 'body': jsonDecode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'body': {'error': 'Terjadi kesalahan pada server: \$e'}};
    }
  }

  // ── MENGUBAH ALAMAT ───────────────────────────────────────────
  Future<Map<String, dynamic>> editAddress(String id, String address, String houseType, String description) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/edit_address/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'address': address, 
          'house_type': houseType,
          'description': description,
        }),
      );
      return {'statusCode': response.statusCode, 'body': jsonDecode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'body': {'error': 'Terjadi kesalahan pada server: \$e'}};
    }
  }

  // ==========================================
  // FITUR PESANAN (ORDERS)
  // ==========================================

  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(orderData),
      );
      return {'statusCode': response.statusCode, 'body': json.decode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'body': {'error': e.toString()}};
    }
  }

  Future<Map<String, dynamic>> updateOrderStatus(int orderId, String status) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/orders/$orderId/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': status}),
      );
      return {'statusCode': response.statusCode, 'body': json.decode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'body': {'error': e.toString()}};
    }
  }

  Future<Map<String, dynamic>> getOrders(String email) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/orders/$email'));
      return {
        'statusCode': response.statusCode,
        'body': json.decode(response.body)
      };
    } catch (e) {
      return {'statusCode': 500, 'body': {'error': e.toString()}};
    }
  }

  // ── MEMBATALKAN PESANAN ───────────────────────────────────────
  Future<Map<String, dynamic>> cancelOrder(String identifier) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/cancel-order/$identifier'),
      );
      return {
        'statusCode': response.statusCode,
        'body': json.decode(response.body)
      };
    } catch (e) {
      return {'statusCode': 500, 'body': {'error': e.toString()}};
    }
  }

  
  // ── MENGIRIM EVALUASI ─────────────────────────────────────────
  Future<Map<String, dynamic>> submitEvaluasi(String email, double rating, String kesan, String saran) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/evaluasi'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'rating': rating,
          'kesan': kesan,
          'saran': saran,
        }),
      );
      return {'statusCode': response.statusCode, 'body': jsonDecode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'body': {'error': 'Terjadi kesalahan pada server: \$e'}};
    }
  }

// ==========================================
  // bagian API ADMIN
  // ==========================================
  Future<Map<String, dynamic>> loginAdmin(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username, 'password': password}),
      );
      return {'statusCode': response.statusCode, 'body': json.decode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'body': {'error': e.toString()}};
    }
  }

  Future<Map<String, dynamic>> getAllOrdersAdmin() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/admin/orders'));
      return {'statusCode': response.statusCode, 'body': json.decode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'body': {'error': e.toString()}};
    }
  }

  Future<Map<String, dynamic>> getAdminRevenue() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/admin/revenue'));
      return {'statusCode': response.statusCode, 'body': json.decode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'body': {'error': e.toString()}};
    }
  }

  // Ambil semua evaluasi untuk ditampilkan di carousel "Apa Kata Orang"
  Future<Map<String, dynamic>> getAllEvaluasi() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/evaluasi'));
      return {'statusCode': response.statusCode, 'body': json.decode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'body': {'error': e.toString()}};
    }
  }

  // ── LIVE CHAT ────────────────────────────────────────────────

  Future<Map<String, dynamic>> getMessages(String email) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/messages/$email'));
      return {'statusCode': response.statusCode, 'body': json.decode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'body': {'error': e.toString()}};
    }
  }

  Future<Map<String, dynamic>> sendMessage(String email, String sender, String message) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/messages'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_email': email, 'sender': sender, 'message': message}),
      );
      return {'statusCode': response.statusCode, 'body': json.decode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'body': {'error': e.toString()}};
    }
  }

  Future<Map<String, dynamic>> getAdminChatRooms() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/messages/admin/rooms'));
      return {'statusCode': response.statusCode, 'body': json.decode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'body': {'error': e.toString()}};
    }
  }

  // ── REVIEW TRANSAKSI ─────────────────────────────────────────

  Future<Map<String, dynamic>> submitOrderReview(
      int orderId, String userEmail, double rating, String review) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/order-reviews'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'order_id': orderId,
          'user_email': userEmail,
          'rating': rating,
          'review': review,
        }),
      );
      return {'statusCode': response.statusCode, 'body': json.decode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'body': {'error': e.toString()}};
    }
  }

  Future<Map<String, dynamic>> checkOrderReview(int orderId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/order-reviews/check/$orderId'));
      return {'statusCode': response.statusCode, 'body': json.decode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'body': {'error': e.toString()}};
    }
  }

  Future<Map<String, dynamic>> getAllOrderReviews() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/order-reviews'));
      return {'statusCode': response.statusCode, 'body': json.decode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'body': {'error': e.toString()}};
    }
  }

  // ── LAPORAN / ADUAN ──────────────────────────────────────────

  Future<Map<String, dynamic>> submitReport({
    required int orderId,
    required String userEmail,
    required String description,
    String? imageBase64,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reports'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'order_id': orderId,
          'user_email': userEmail,
          'description': description,
          'image_base64': imageBase64,
        }),
      );
      return {'statusCode': response.statusCode, 'body': json.decode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'body': {'error': e.toString()}};
    }
  }

  Future<Map<String, dynamic>> getAdminReports() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/admin/reports'));
      return {'statusCode': response.statusCode, 'body': json.decode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'body': {'error': e.toString()}};
    }
  }

  Future<Map<String, dynamic>> updateReportStatus(int reportId, String status) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/reports/$reportId/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': status}),
      );
      return {'statusCode': response.statusCode, 'body': json.decode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'body': {'error': e.toString()}};
    }
  }
}