import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final FirestoreService _i = FirestoreService._();
  factory FirestoreService() => _i;
  FirestoreService._();

  final _db = FirebaseFirestore.instance;

  // ── Referensi collection users ───────────────────────────────────
  CollectionReference get _users => _db.collection('users');

  // ── Daftarkan user baru ──────────────────────────────────────────
  Future<void> registerUser({
    required String uid,
    required String nama,
    required String email,
  }) async {
    await _users.doc(uid).set({
      'uid':        uid,
      'nama':       nama,
      'email':      email,
      'createdAt':  FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ── Cek user sudah terdaftar ─────────────────────────────────────
  Future<bool> isUserRegistered(String uid) async {
    final doc = await _users.doc(uid).get();
    return doc.exists;
  }

  // ── Simpan pendapatan harian ─────────────────────────────────────
  Future<void> tambahPendapatan({
    required String uid,
    required double total,
  }) async {
    final now     = DateTime.now();
    final tanggal = '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

    final ref = _users
        .doc(uid)
        .collection('pendapatan')
        .doc(tanggal);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (snap.exists) {
        tx.update(ref, {
          'total':      FieldValue.increment(total),
          'transaksi':  FieldValue.increment(1),
          'updatedAt':  FieldValue.serverTimestamp(),
        });
      } else {
        tx.set(ref, {
          'tanggal':    tanggal,
          'total':      total,
          'transaksi':  1,
          'createdAt':  FieldValue.serverTimestamp(),
          'updatedAt':  FieldValue.serverTimestamp(),
        });
      }
    });
  }

  // ── Ambil pendapatan hari ini ────────────────────────────────────
  Future<Map<String, dynamic>> getPendapatanHariIni(String uid) async {
    try {
      final now     = DateTime.now();
      final tanggal = '${now.year}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';

      final doc = await _users
          .doc(uid)
          .collection('pendapatan')
          .doc(tanggal)
          .get();

      if (!doc.exists) return {'total': 0.0, 'transaksi': 0};

      final data = doc.data() as Map<String, dynamic>;
      return {
        'total':     (data['total']     as num).toDouble(),
        'transaksi': (data['transaksi'] as num).toInt(),
      };
    } catch (_) {
      return {'total': 0.0, 'transaksi': 0};
    }
  }
}