import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// BiometricService dengan isolasi per-akun.
/// Setiap akun (email) punya key sendiri di SharedPreferences,
/// sehingga 1 sidik jari hanya bisa login ke 1 akun yang didaftarkan.
class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  // ── Key per-akun (suffix = email yang di-sanitize) ───────────
  static String _keyEnabled(String email)  => 'bio_enabled_${_sanitize(email)}';
  static String _keyPassword(String email) => 'bio_password_${_sanitize(email)}';

  // Key global: daftar semua email yang sudah daftarkan biometrik
  static const _keyRegisteredEmails = 'bio_registered_emails';

  static String _sanitize(String email) =>
      email.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');

  // ── Cek apakah device support biometrik ─────────────────────
  static Future<bool> isAvailable() async {
    try {
      final canCheck    = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (_) {
      return false;
    }
  }

  // ── Cek apakah akun tertentu sudah daftarkan biometrik ───────
  static Future<bool> isEnabledForAccount(String email) async {
    if (email.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyEnabled(email)) ?? false;
  }

  // ── Cek apakah ADA akun manapun yang sudah daftar biometrik ──
  // Dipakai di login page untuk menampilkan tombol biometrik
  static Future<bool> hasAnyRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    final emails = prefs.getStringList(_keyRegisteredEmails) ?? [];
    for (final email in emails) {
      if (prefs.getBool(_keyEnabled(email)) == true) return true;
    }
    return false;
  }

  // ── Daftarkan biometrik untuk akun tertentu ──────────────────
  static Future<bool> enroll({
    required String email,
    required String password,
  }) async {
    if (email.isEmpty) return false;
    try {
      final authenticated = await _auth.authenticate(
        localizedReason:
            'Verifikasi identitas Anda untuk mengaktifkan login cepat di Bersih.In',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      if (authenticated) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_keyEnabled(email), true);
        await prefs.setString(_keyPassword(email), password);
        final emails = prefs.getStringList(_keyRegisteredEmails) ?? [];
        if (!emails.contains(email)) {
          emails.add(email);
          await prefs.setStringList(_keyRegisteredEmails, emails);
        }
      }
      return authenticated;
    } catch (_) {
      return false;
    }
  }

  // ── Autentikasi biometrik → kembalikan kredensial akun ───────
  static Future<Map<String, String>?> authenticate() async {
    try {
      final prefs  = await SharedPreferences.getInstance();
      final emails = prefs.getStringList(_keyRegisteredEmails) ?? [];
      final activeEmails = emails
          .where((e) => prefs.getBool(_keyEnabled(e)) == true)
          .toList();

      if (activeEmails.isEmpty) return null;

      final authenticated = await _auth.authenticate(
        localizedReason: 'Gunakan sidik jari atau wajah untuk masuk ke Bersih.In',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      if (!authenticated) return null;

      // Filter akun admin dari daftar
      final userEmails = activeEmails
          .where((e) => e.toLowerCase() != 'admin')
          .toList();

      if (userEmails.isEmpty) return null;

      // Selalu kembalikan format multi-akun agar dialog pilih akun selalu muncul
      return {
        'multi': 'true',
        'emails': userEmails.join(','),
      };
    } catch (_) {
      return null;
    }
  }

  // ── Ambil password tersimpan untuk akun tertentu ─────────────
  static Future<String?> getPasswordForAccount(String email) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPassword(email));
  }

  // ── Nonaktifkan biometrik untuk akun tertentu ────────────────
  static Future<void> disableForAccount(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled(email), false);
    await prefs.remove(_keyPassword(email));
    final emails = prefs.getStringList(_keyRegisteredEmails) ?? [];
    emails.remove(email);
    await prefs.setStringList(_keyRegisteredEmails, emails);
  }

  // ── Update password tersimpan (saat user ganti password) ─────
  static Future<void> updatePassword({
    required String email,
    required String newPassword,
  }) async {
    final enabled = await isEnabledForAccount(email);
    if (!enabled) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPassword(email), newPassword);
  }
}
