import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

/// Controller yang menangani semua logika pemesanan layanan.
class OrderController {
  final AuthService _authService = AuthService();

  // ==========================================
  // PESANAN
  // ==========================================

  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    return await _authService.createOrder(orderData);
  }

  Future<Map<String, dynamic>> getOrders(String email) async {
    return await _authService.getOrders(email);
  }

  Future<Map<String, dynamic>> updateOrderStatus(int orderId, String status) async {
    return await _authService.updateOrderStatus(orderId, status);
  }

  Future<Map<String, dynamic>> cancelOrder(String identifier) async {
    return await _authService.cancelOrder(identifier);
  }

  // ==========================================
  // ALAMAT
  // ==========================================

  Future<Map<String, dynamic>> getSavedAddresses(String username) async {
    return await _authService.getSavedAddresses(username);
  }

  Future<Map<String, dynamic>> saveNewAddress({
    required String username,
    required String address,
    required String lat,
    required String lng,
    required String houseType,
    required String description,
  }) async {
    return await _authService.saveNewAddress(username, address, lat, lng, houseType, description);
  }

  Future<Map<String, dynamic>> deleteAddress(String id) async {
    return await _authService.deleteAddress(id);
  }

  Future<Map<String, dynamic>> editAddress({
    required String id,
    required String address,
    required String houseType,
    required String description,
  }) async {
    return await _authService.editAddress(id, address, houseType, description);
  }

  // ==========================================
  // HELPER: SIMPAN & AMBIL ALAMAT ORDER SEMENTARA
  // ==========================================

  Future<void> saveOrderAddress({
    required String address,
    required String houseType,
    required String patokan,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('order_address', address);
    await prefs.setString('order_house_type', houseType);
    await prefs.setString('order_patokan', patokan);
  }

  Future<Map<String, String>> getOrderAddress() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'address': prefs.getString('order_address') ?? 'Alamat belum dipilih',
      'houseType': prefs.getString('order_house_type') ?? 'Rumah',
      'patokan': prefs.getString('order_patokan') ?? '-',
    };
  }

  // ==========================================
  // HELPER: FORMAT HARGA
  // ==========================================

  String formatPrice(int price) {
    return "Rp ${price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}";
  }

  // ==========================================
  // HELPER: GENERATE WAKTU TRANSAKSI
  // ==========================================

  Future<String> generateTransactionTime() async {
    final prefs = await SharedPreferences.getInstance();
    String timeZone = prefs.getString('zona_waktu') ?? 'WIB';
    DateTime now = DateTime.now().toUtc();
    int offset = {'WIB': 7, 'WITA': 8, 'WIT': 9, 'London': 1}[timeZone] ?? 7;
    DateTime zoneTime = now.add(Duration(hours: offset));
    return "${zoneTime.day.toString().padLeft(2, '0')}/${zoneTime.month.toString().padLeft(2, '0')}/${zoneTime.year} "
        "${zoneTime.hour.toString().padLeft(2, '0')}:${zoneTime.minute.toString().padLeft(2, '0')} $timeZone";
  }
}
