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

Future<Map<String, dynamic>> updateProfile(String oldEmail, String email, String username, String password) async {
    final response = await http.put(
      Uri.parse('$baseUrl/update-profile'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'oldEmail': oldEmail, 'email': email, 'username': username, 'password': password}),
    );
    return {'statusCode': response.statusCode, 'body': jsonDecode(response.body)};
  }

  Future<Map<String, dynamic>> deleteAccount(String email) async {
    final response = await http.delete(Uri.parse('$baseUrl/delete-account/$email'));
    return {'statusCode': response.statusCode, 'body': jsonDecode(response.body)};
  }

}