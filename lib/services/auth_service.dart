import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final AuthService _i = AuthService._();
  factory AuthService() => _i;
  AuthService._();

  final _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
      'https://www.googleapis.com/auth/spreadsheets',
      'https://www.googleapis.com/auth/drive.file',
    ],
  );

  GoogleSignInAccount? _account;

  bool   get isSignedIn => _account != null;
  String get uid        => _account?.id        ?? '';
  String get userName   => _account?.displayName ?? '';
  String get userEmail  => _account?.email      ?? '';
  String get userPhoto  => _account?.photoUrl   ?? '';

  // ── Login ────────────────────────────────────────────────────────
  Future<bool> signIn() async {
    try {
      // Coba restore sesi login sebelumnya
      _account = await _googleSignIn.signInSilently();

      // Jika tidak ada sesi tersimpan, munculkan dialog pilihkun
      _account ??= await _googleSignIn.signIn();

      return _account != null;
    } catch (e) {
      debugPrint('Error pada Google SignIn: $e');
      return false;
    }
  }

  // ── Logout ───────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _account = null;
  }

  // ── Ambil auth headers (Auto Restore & Refresh Token) ────────────
  Future<Map<String, String>> getAuthHeaders() async {
    // 1. Jika app baru dibuka & _account null, coba restore akun dulu
    if (_account == null) {
      _account = await _googleSignIn.signInSilently();
    }

    // 2. Jika masih null, artinya user memang harus login ulang
    if (_account == null) {
      throw Exception('User belum login. Silakan login terlebih dahulu.');
    }

    // 3. Ambil header terbaru (termasuk Authorization Bearer Token)
    final headers = await _account!.authHeaders;
    
    // Periksa apakah token berhasil didapat
    if (!headers.containsKey('Authorization')) {
      throw Exception('Gagal mendapatkan token OAuth dari Google.');
    }

    return headers;
  }
}