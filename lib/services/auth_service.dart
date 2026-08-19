import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final AuthService _i = AuthService._();
  factory AuthService() => _i;
  AuthService._();

  final _auth         = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn();

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
    try {
      // Coba silent login dulu
      final silentUser = await _googleSignIn.signInSilently();
      if (silentUser != null) {
        final googleAuth = await silentUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken:     googleAuth.idToken,
        );
        await _auth.signInWithCredential(credential);
        return true;
      }

      // Tampilkan popup login
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken:     googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── Logout ───────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

}