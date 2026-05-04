import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

/// Controller yang menangani semua logika autentikasi dan profil pengguna.
/// Memisahkan business logic dari UI layer.
class AuthController {
  final AuthService _authService = AuthService();

  // ==========================================
  // AUTENTIKASI
  // ==========================================

  Future<Map<String, dynamic>> login(String emailOrUsername, String password) async {
    return await _authService.login(emailOrUsername, password);
  }

  Future<Map<String, dynamic>> loginAdmin(String username, String password) async {
    return await _authService.loginAdmin(username, password);
  }

  Future<Map<String, dynamic>> register(String email, String username, String password) async {
    return await _authService.register(email, username, password);
  }

  Future<void> saveSession(String email, String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_email', email);
    await prefs.setString('saved_username', username);

    // Restore foto dari cache per-email jika ada
    // Ini membuat foto langsung muncul saat login tanpa harus fetch server dulu
    final cachedAvatar = prefs.getString('avatar_cache_${_sanitizeEmail(email)}');
    if (cachedAvatar != null && cachedAvatar.isNotEmpty) {
      await prefs.setString('profile_base64', cachedAvatar);
    }
  }

  /// Logout: hapus sesi aktif tapi PERTAHANKAN cache foto per-email
  /// agar foto langsung muncul saat login lagi tanpa harus fetch ulang.
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('saved_email') ?? '';

    // Backup foto ke key per-email sebelum clear
    final currentBase64 = prefs.getString('profile_base64');
    if (email.isNotEmpty && currentBase64 != null && currentBase64.isNotEmpty) {
      await prefs.setString('avatar_cache_${_sanitizeEmail(email)}', currentBase64);
    }

    // Hapus sesi aktif saja, bukan semua data
    // PENTING: key berikut TIDAK dihapus agar fitur tetap berjalan setelah logout-login:
    //   - order_created_at_<id>  → countdown timer pembayaran
    //   - order_currency_<id>    → mata uang yang dipilih saat order
    //   - order_converted_<id>   → nilai total dalam mata uang asing
    //   - avatar_cache_<email>   → cache foto profil per-akun
    await prefs.remove('saved_email');
    await prefs.remove('saved_username');
    await prefs.remove('saved_password');
    await prefs.remove('profile_image');
    await prefs.remove('profile_base64');
    await prefs.remove('order_address');
    await prefs.remove('order_house_type');
    await prefs.remove('order_patokan');
    await prefs.remove('zona_waktu');
  }

  static String _sanitizeEmail(String email) =>
      email.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString('saved_email') ?? '').isNotEmpty;
  }

  Future<String> getSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('saved_email') ?? '';
  }

  Future<String> getSavedUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('saved_username') ?? 'Tamu';
  }

  // ==========================================
  // PROFIL
  // ==========================================

  /// Mengambil data profil dari server dan menyimpan ke local cache.
  /// Mengembalikan [UserModel] jika berhasil, null jika gagal.
  Future<UserModel?> fetchAndCacheProfile(String email) async {
    final response = await _authService.getProfile(email);
    if (response['statusCode'] == 200) {
      final body = response['body'];
      final username = body['username'] ?? body['user']?['username'] ?? '';
      final avatarRaw = body['avatar_url'] ?? body['user']?['avatar_url'];

      String? cleanBase64;
      if (avatarRaw != null && (avatarRaw as String).isNotEmpty) {
        cleanBase64 = avatarRaw.replaceAll(RegExp(r'\s+'), '');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_username', username);
      if (cleanBase64 != null) {
        // Simpan ke cache aktif
        await prefs.setString('profile_base64', cleanBase64);
        // Simpan juga ke cache per-email agar tetap ada setelah logout
        await prefs.setString('avatar_cache_${_sanitizeEmail(email)}', cleanBase64);
      }

      return UserModel(email: email, username: username, avatarBase64: cleanBase64);
    }
    return null;
  }

  /// Mengambil data profil dari local cache (SharedPreferences).
  /// Jika cache aktif kosong, coba restore dari cache per-email.
  Future<UserModel> getCachedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('saved_email') ?? '';

    // Coba ambil dari cache aktif dulu
    String? base64 = prefs.getString('profile_base64');

    // Jika kosong, restore dari cache per-email (setelah logout-login)
    if ((base64 == null || base64.isEmpty) && email.isNotEmpty) {
      final perEmailCache = prefs.getString('avatar_cache_${_sanitizeEmail(email)}');
      if (perEmailCache != null && perEmailCache.isNotEmpty) {
        base64 = perEmailCache;
        // Restore ke cache aktif sekalian
        await prefs.setString('profile_base64', perEmailCache);
      }
    }

    return UserModel(
      email: email,
      username: prefs.getString('saved_username') ?? 'Tamu',
      avatarBase64: base64,
    );
  }

  /// Memilih gambar dari galeri atau kamera, lalu mengompresinya.
  /// Mengembalikan path file lokal jika berhasil, null jika dibatalkan.
  Future<String?> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 20,
      maxWidth: 600,
    );
    if (pickedFile != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image', pickedFile.path);
      return pickedFile.path;
    }
    return null;
  }

  /// Mengonversi file gambar ke Base64 string.
  Future<String?> imageToBase64(String imagePath) async {
    final file = File(imagePath);
    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      return base64Encode(bytes);
    }
    return null;
  }

  /// Menyimpan perubahan profil ke server dan memperbarui local cache.
  Future<Map<String, dynamic>> updateProfile({
    required String oldEmail,
    required String newEmail,
    required String username,
    required String password,
    String? imagePath,
  }) async {
    String? base64Image;

    if (imagePath != null) {
      // Ada foto baru dipilih — konversi ke base64
      base64Image = await imageToBase64(imagePath);
    } else {
      // Tidak ada foto baru — ambil dari cache agar tidak terhapus di server
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('profile_base64') ??
          prefs.getString('avatar_cache_${_sanitizeEmail(oldEmail)}');
      if (cached != null && cached.isNotEmpty) {
        base64Image = cached;
      }
      // Jika benar-benar tidak ada foto sama sekali, biarkan null
      // sehingga server tidak menerima field avatar_url dan foto lama tetap aman
    }

    final result = await _authService.updateProfile(
      oldEmail,
      newEmail,
      username,
      password,
      avatarUrl: base64Image,
    );

    if (result['statusCode'] == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_username', username);
      await prefs.setString('saved_email', newEmail);
      if (base64Image != null) {
        await prefs.setString('profile_base64', base64Image);
        await prefs.setString('avatar_cache_${_sanitizeEmail(newEmail)}', base64Image);
      }
    }

    return result;
  }

  Future<Map<String, dynamic>> deleteAccount(String email) async {
    return await _authService.deleteAccount(email);
  }
}
