import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  // ZHANGG! Alamat IP lu nongkrong di mari. 
  // Ganti di sini doang kalo mau ngetes pake WiFi/Hotspot lu ato hape temen lu
  static const String baseUrl = 'http://192.168.18.7:3000/api';

  // LOGIC BUAT DAFTAR
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
        'body': {'message': 'Server meledak pak: $e'}
      };
    }
  }

  // LOGIC BUAT MASUK
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
        'body': {'message': 'Server meledak pak: $e'}
      };
    }
  }

  // ZHANGG! LOGIC BUAT NYEDOT PROFIL DARI XAMPP
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
        'body': {'message': 'Server meledak pak: $e'}
      };
    }
  }

  // LOGIC BUAT UPDATE PROFIL
  Future<Map<String, dynamic>> updateProfile(String oldEmail, String email, String username, String password) async {
    final response = await http.put(
      Uri.parse('$baseUrl/update-profile'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'oldEmail': oldEmail, 'email': email, 'username': username, 'password': password}),
    );
    return {'statusCode': response.statusCode, 'body': jsonDecode(response.body)};
  }

  // LOGIC BUAT HAPUS AKUN
  Future<Map<String, dynamic>> deleteAccount(String email) async {
    final response = await http.delete(Uri.parse('$baseUrl/delete-account/$email'));
    return {'statusCode': response.statusCode, 'body': jsonDecode(response.body)};
  }

  // ==========================================
  // FITUR SAVED ADDRESS (TAMBAHAN DARI GUA PAK)
  // ==========================================

  // LOGIC BUAT NYEDOT ALAMAT DARI XAMPP
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
        'body': {'error': 'Server meledak pak: $e'}
      };
    }
  }

  // LOGIC BUAT NYIMPEN ALAMAT KE XAMPP
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
      return {'statusCode': 500, 'body': {'error': 'Server meledak pak: $e'}};
    }
  }

// LOGIC BUAT HAPUS ALAMAT
  Future<Map<String, dynamic>> deleteAddress(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/delete_address/$id'));
      return {'statusCode': response.statusCode, 'body': jsonDecode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'body': {'error': 'Server meledak pak: $e'}};
    }
  }

  // LOGIC BUAT EDIT ALAMAT (Patokan & Tipe Hunian)
  Future<Map<String, dynamic>> editAddress(String id, String address, String houseType, String description) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/edit_address/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'address': address, // ZHANGG! Kirim alamat barunye juga pak
          'house_type': houseType,
          'description': description,
        }),
      );
      return {'statusCode': response.statusCode, 'body': jsonDecode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'body': {'error': 'Server meledak pak: $e'}};
    }
  }

}