import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final AuthService _i = AuthService._();
  factory AuthService() => _i;
  AuthService._();

  final _auth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn(
    serverClientId:
        '19959687372-ssoq87ktac1ngl3kc5bbgl2iei2douta.apps.googleusercontent.com',
  );
  String lastError = '';

  // ── Stream perubahan status login ────────────────────────────────
  Stream<User?> get userStream => _auth.authStateChanges();

  User?   get currentUser => _auth.currentUser;
  String  get uid         => _auth.currentUser?.uid        ?? '';
  String  get userName    => _auth.currentUser?.displayName ?? '';
  String  get userEmail   => _auth.currentUser?.email       ?? '';
  String  get userPhoto   => _auth.currentUser?.photoURL    ?? '';
  bool    get isLoggedIn  => _auth.currentUser != null;

  // ── Login Google ─────────────────────────────────────────────────
  Future<bool> signIn() async {
    lastError = '';
    try {
      // Coba silent login dulu
      final silentUser = await _googleSignIn.signInSilently();
      if (silentUser != null) {
        final googleAuth = await silentUser.authentication;
        final credential = _credentialFrom(googleAuth);
        await _auth.signInWithCredential(credential);
        return true;
      }

      // Tampilkan popup login
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false;

      final googleAuth = await googleUser.authentication;
      final credential = _credentialFrom(googleAuth);

      await _auth.signInWithCredential(credential);
      return true;
    } on FirebaseAuthException catch (e) {
      lastError = _firebaseErrorMessage(e);
      debugPrint('Firebase Auth gagal: $lastError');
      return false;
    } on PlatformException catch (e) {
      lastError = _googleErrorMessage(e);
      debugPrint('Google Sign-In gagal: $lastError');
      return false;
    } catch (e) {
      lastError = e.toString();
      debugPrint('Google Sign-In gagal: $lastError');
      return false;
    }
  }

  AuthCredential _credentialFrom(GoogleSignInAuthentication googleAuth) {
    final idToken = googleAuth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw PlatformException(
        code: 'missing-id-token',
        message: 'Google tidak mengembalikan ID token.',
      );
    }

    return GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: idToken,
    );
  }

  String _googleErrorMessage(PlatformException e) {
    final detail = '${e.code} ${e.message ?? ''} ${e.details ?? ''}'
        .toLowerCase();

    if (detail.contains('api_exception: 10') ||
        detail.contains('developer_error')) {
      return 'Konfigurasi Google Sign-In Android belum lengkap. '
          'Tambahkan SHA-1 dan SHA-256 aplikasi di Firebase Console, '
          'lalu unduh google-services.json terbaru dan build ulang aplikasi.';
    }
    if (e.code == 'sign_in_canceled') return 'Login Google dibatalkan.';
    if (e.code == 'network_error') return 'Tidak dapat terhubung ke Google. Cek koneksi internet.';
    if (e.code == 'missing-id-token') return e.message!;

    return 'Google Sign-In [${e.code}]: '
        '${e.message ?? e.details ?? 'Tidak ada detail'}';
  }

  String _firebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return 'Email ini sudah terdaftar dengan metode login lain.';
      case 'network-request-failed':
        return 'Tidak dapat terhubung ke Firebase. Cek koneksi internet.';
      case 'operation-not-allowed':
        return 'Provider Google belum diaktifkan di Firebase Authentication.';
      default:
        return 'Firebase Auth [${e.code}]: ${e.message ?? 'Tidak ada detail'}';
    }
  }

  // ── Logout ───────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

}
