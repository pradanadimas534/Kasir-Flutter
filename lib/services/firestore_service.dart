import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item_model.dart';

class FirestoreService {
  static final FirestoreService _i = FirestoreService._();
  factory FirestoreService() => _i;
  FirestoreService._();

  final _db = FirebaseFirestore.instance;

  // ── Referensi collection users ───────────────────────────────────
  CollectionReference get _users => _db.collection('users');

  CollectionReference<Map<String, dynamic>> _items(String uid) =>
      _users.doc(uid).collection('items');

  Future<List<ItemModel>> getItems(String uid) async {
    final snapshot = await _items(uid).orderBy('id').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return ItemModel(
        id: data['id'] as int,
        name: data['name'] as String? ?? '',
        price: (data['price'] as num?)?.toDouble() ?? 0,
        stock: (data['stock'] as num?)?.toDouble() ?? 0,
        sold: (data['sold'] as num?)?.toDouble() ?? 0,
        type: data['type'] as String? ?? 'satuan',
        unit: data['unit'] as String? ?? 'pcs',
      );
    }).toList();
  }

  Future<List<ItemModel>> addItem(String uid, ItemModel item) async {
    final snapshot = await _items(uid)
        .orderBy('id', descending: true)
        .limit(1)
        .get();
    final nextId = snapshot.docs.isEmpty
        ? 1
        : (snapshot.docs.first.data()['id'] as int) + 1;
    final newItem = item.copyWith(id: nextId);
    await _items(uid).doc('$nextId').set(_itemData(newItem));
    return getItems(uid);
  }

  Future<void> updateItem(String uid, ItemModel item) async {
    await _items(uid).doc('${item.id}').set(_itemData(item));
  }

  Future<void> deleteItem(String uid, int id) async {
    await _items(uid).doc('$id').delete();
  }

  Map<String, dynamic> _itemData(ItemModel item) => {
        'id': item.id,
        'name': item.name,
        'price': item.price,
        'stock': item.stock,
        'sold': item.sold,
        'type': item.type,
        'unit': item.unit,
        'updatedAt': FieldValue.serverTimestamp(),
      };

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