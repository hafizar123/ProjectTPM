// ============================================================
// UNIT TEST - AuthController (TDD - Bersih.In)
// Nama  : Akmal Danendra Maulana / 123230135
// Modul : Autentikasi Pengguna (auth_controller.dart)
//
// Skenario:
//   A - Login sukses dengan kredensial valid
//   B - Login gagal dengan kredensial salah
//   C - Validasi manajemen sesi setelah login
// ============================================================

import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Stub / fake pengganti AuthService agar pengujian tidak membutuhkan
// koneksi jaringan atau server backend yang aktif.
// ---------------------------------------------------------------------------

class _FakeUser {
  final String email;
  final String username;
  final String passwordHash; // bcrypt hash dari password asli

  const _FakeUser({
    required this.email,
    required this.username,
    required this.passwordHash,
  });
}

/// Simulasi respons server untuk keperluan pengujian.
/// Logika identik dengan alur di AuthService.login() dan server.js.
class _FakeAuthService {
  final List<_FakeUser> _users;

  _FakeAuthService(this._users);

  /// Simulasi POST /api/login
  Future<Map<String, dynamic>> login(String emailOrUsername, String password) async {
    try {
      // Cari pengguna berdasarkan email atau username
      _FakeUser? found;
      for (final u in _users) {
        if (u.email == emailOrUsername || u.username == emailOrUsername) {
          found = u;
          break;
        }
      }

      if (found == null) {
        return {
          'statusCode': 401,
          'body': {'message': 'Email/username tidak ditemukan'},
        };
      }

      // Simulasi pencocokan password (pada server asli menggunakan bcrypt)
      // Untuk keperluan pengujian, password disimpan sebagai plaintext di fixture
      if (password != found.passwordHash) {
        return {
          'statusCode': 401,
          'body': {'message': 'Kata sandi salah'},
        };
      }

      return {
        'statusCode': 200,
        'body': {
          'message': 'Login berhasil',
          'user': {'email': found.email, 'username': found.username},
        },
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'body': {'message': 'Terjadi kesalahan pada server'},
      };
    }
  }
}

// ---------------------------------------------------------------------------
// Simulasi AuthController dengan dependency injection untuk keperluan pengujian.
// Logika identik dengan auth_controller.dart asli, namun menggunakan
// _FakeAuthService sebagai pengganti AuthService yang membutuhkan jaringan.
// ---------------------------------------------------------------------------

class _TestableAuthController {
  final _FakeAuthService _authService;
  final Map<String, String> _prefs; // Simulasi SharedPreferences

  _TestableAuthController(this._authService, this._prefs);

  /// Simulasi AuthController.login() + AuthController.saveSession()
  Future<Map<String, dynamic>> loginAndSaveSession(
    String emailOrUsername,
    String password,
  ) async {
    final response = await _authService.login(emailOrUsername, password);

    if (response['statusCode'] == 200) {
      final user = response['body']['user'] as Map<String, dynamic>;
      // Simulasi saveSession — menyimpan email dan username ke SharedPreferences
      _prefs['saved_email']    = user['email'] as String;
      _prefs['saved_username'] = user['username'] as String;
    }

    return response;
  }

  /// Simulasi AuthController.isLoggedIn()
  bool isLoggedIn() {
    return (_prefs['saved_email'] ?? '').isNotEmpty;
  }

  /// Simulasi AuthController.clearSession()
  void clearSession() {
    _prefs.remove('saved_email');
    _prefs.remove('saved_username');
    _prefs.remove('saved_password');
  }

  /// Simulasi AuthController.getSavedEmail()
  String getSavedEmail() {
    return _prefs['saved_email'] ?? '';
  }
}

// ---------------------------------------------------------------------------
// DATA FIXTURE
// ---------------------------------------------------------------------------

const _userAkmal = _FakeUser(
  email: 'akmal@bersihin.in',
  username: 'akmal135',
  passwordHash: 'akmal123', // Plaintext untuk simulasi pengujian
);

const _userHafiz = _FakeUser(
  email: 'hafiz@bersihin.in',
  username: 'hafiz149',
  passwordHash: 'hafiz123',
);

// ===========================================================================
// MAIN TEST
// ===========================================================================

void main() {
  // -------------------------------------------------------------------------
  // SKENARIO A — Login Sukses
  // -------------------------------------------------------------------------
  group('Skenario A: Login Sukses', () {
    late _TestableAuthController auth;
    late Map<String, String> prefs;

    setUp(() {
      prefs = {};
      auth = _TestableAuthController(
        _FakeAuthService([_userAkmal, _userHafiz]),
        prefs,
      );
    });

    test(
      'A1 - login dengan email valid mengembalikan statusCode 200',
      () async {
        final result = await auth.loginAndSaveSession(
          'akmal@bersihin.in',
          'akmal123',
        );

        expect(result['statusCode'], 200);
      },
    );

    test(
      'A2 - login dengan username valid mengembalikan statusCode 200',
      () async {
        final result = await auth.loginAndSaveSession('akmal135', 'akmal123');

        expect(result['statusCode'], 200);
      },
    );

    test(
      'A3 - login sukses mengembalikan pesan "Login berhasil"',
      () async {
        final result = await auth.loginAndSaveSession(
          'akmal@bersihin.in',
          'akmal123',
        );

        expect(result['body']['message'], 'Login berhasil');
      },
    );

    test(
      'A4 - setelah login sukses, sesi tersimpan di SharedPreferences',
      () async {
        await auth.loginAndSaveSession('akmal@bersihin.in', 'akmal123');

        expect(prefs['saved_email'], 'akmal@bersihin.in');
        expect(prefs['saved_username'], 'akmal135');
      },
    );

    test(
      'A5 - setelah login sukses, isLoggedIn() mengembalikan true',
      () async {
        await auth.loginAndSaveSession('akmal@bersihin.in', 'akmal123');

        expect(auth.isLoggedIn(), isTrue);
      },
    );

    test(
      'A6 - login dengan akun kedua juga berhasil',
      () async {
        final result = await auth.loginAndSaveSession(
          'hafiz@bersihin.in',
          'hafiz123',
        );

        expect(result['statusCode'], 200);
        expect(prefs['saved_email'], 'hafiz@bersihin.in');
      },
    );
  });

  // -------------------------------------------------------------------------
  // SKENARIO B — Login Gagal (Kredensial Salah)
  // -------------------------------------------------------------------------
  group('Skenario B: Login Gagal - Kredensial Salah', () {
    late _TestableAuthController auth;

    setUp(() {
      auth = _TestableAuthController(
        _FakeAuthService([_userAkmal, _userHafiz]),
        {},
      );
    });

    test(
      'B1 - password salah mengembalikan statusCode 401',
      () async {
        final result = await auth.loginAndSaveSession(
          'akmal@bersihin.in',
          'password_salah',
        );

        expect(result['statusCode'], 401);
      },
    );

    test(
      'B2 - password salah mengembalikan pesan kesalahan yang sesuai',
      () async {
        final result = await auth.loginAndSaveSession(
          'akmal@bersihin.in',
          'password_salah',
        );

        expect(result['body']['message'], 'Kata sandi salah');
      },
    );

    test(
      'B3 - email tidak terdaftar mengembalikan statusCode 401',
      () async {
        final result = await auth.loginAndSaveSession(
          'tidakada@bersihin.in',
          'akmal123',
        );

        expect(result['statusCode'], 401);
      },
    );

    test(
      'B4 - username tidak terdaftar mengembalikan statusCode 401',
      () async {
        final result = await auth.loginAndSaveSession(
          'user_tidak_ada',
          'akmal123',
        );

        expect(result['statusCode'], 401);
      },
    );

    test(
      'B5 - email dan password sama-sama salah tetap ditolak',
      () async {
        final result = await auth.loginAndSaveSession(
          'hacker@evil.com',
          'wrongpass',
        );

        expect(result['statusCode'], 401);
      },
    );

    test(
      'B6 - login gagal tidak menyimpan sesi di SharedPreferences',
      () async {
        final prefs = <String, String>{};
        final authWithPrefs = _TestableAuthController(
          _FakeAuthService([_userAkmal]),
          prefs,
        );

        await authWithPrefs.loginAndSaveSession(
          'akmal@bersihin.in',
          'password_salah',
        );

        expect(prefs.containsKey('saved_email'), isFalse);
        expect(prefs.containsKey('saved_username'), isFalse);
      },
    );
  });

  // -------------------------------------------------------------------------
  // SKENARIO C — Manajemen Sesi (Session Management)
  // -------------------------------------------------------------------------
  group('Skenario C: Manajemen Sesi', () {
    test(
      'C1 - sebelum login, isLoggedIn() mengembalikan false',
      () {
        final auth = _TestableAuthController(
          _FakeAuthService([_userAkmal]),
          {},
        );

        expect(auth.isLoggedIn(), isFalse);
      },
    );

    test(
      'C2 - setelah login sukses, getSavedEmail() mengembalikan email yang benar',
      () async {
        final prefs = <String, String>{};
        final auth = _TestableAuthController(
          _FakeAuthService([_userAkmal]),
          prefs,
        );

        await auth.loginAndSaveSession('akmal@bersihin.in', 'akmal123');

        expect(auth.getSavedEmail(), 'akmal@bersihin.in');
      },
    );

    test(
      'C3 - setelah clearSession(), isLoggedIn() mengembalikan false',
      () async {
        final prefs = <String, String>{};
        final auth = _TestableAuthController(
          _FakeAuthService([_userAkmal]),
          prefs,
        );

        await auth.loginAndSaveSession('akmal@bersihin.in', 'akmal123');
        expect(auth.isLoggedIn(), isTrue);

        auth.clearSession();
        expect(auth.isLoggedIn(), isFalse);
      },
    );

    test(
      'C4 - setelah clearSession(), getSavedEmail() mengembalikan string kosong',
      () async {
        final prefs = <String, String>{};
        final auth = _TestableAuthController(
          _FakeAuthService([_userAkmal]),
          prefs,
        );

        await auth.loginAndSaveSession('akmal@bersihin.in', 'akmal123');
        auth.clearSession();

        expect(auth.getSavedEmail(), '');
      },
    );

    test(
      'C5 - login ulang setelah logout menghasilkan sesi baru yang valid',
      () async {
        final prefs = <String, String>{};
        final auth = _TestableAuthController(
          _FakeAuthService([_userAkmal]),
          prefs,
        );

        // Login pertama
        await auth.loginAndSaveSession('akmal@bersihin.in', 'akmal123');
        expect(auth.isLoggedIn(), isTrue);

        // Logout
        auth.clearSession();
        expect(auth.isLoggedIn(), isFalse);

        // Login ulang
        await auth.loginAndSaveSession('akmal@bersihin.in', 'akmal123');
        expect(auth.isLoggedIn(), isTrue);
        expect(auth.getSavedEmail(), 'akmal@bersihin.in');
      },
    );
  });
}
