import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final AuthService _i = AuthService._();
  factory AuthService() => _i;
  AuthService._();

  final _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
      // Akses Google Sheets
      'https://www.googleapis.com/auth/spreadsheets',
      // Akses Google Drive
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
      // Coba login diam-diam dulu (kalau sudah pernah login)
      _account = await _googleSignIn.signInSilently();

      // Belum pernah login → tampilkan popup
      _account ??= await _googleSignIn.signIn();

      return _account != null;
    } catch (e) {
      return false;
    }
  }

  // ── Logout ───────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _account = null;
  }

  // ── Ambil auth headers untuk request ke Google API ───────────────
  Future<Map<String, String>> getAuthHeaders() async {
    if (_account == null) throw Exception('Belum login');
    return await _account!.authHeaders;
  }

  // ── Refresh token jika expired ───────────────────────────────────
  Future<void> refreshIfNeeded() async {
    try {
      await _account?.authentication;
    } catch (_) {
      await signIn();
    }
  }
}