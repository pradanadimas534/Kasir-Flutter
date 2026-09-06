import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item_model.dart';
import '../models/utang_model.dart';

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
    // Urutkan di aplikasi agar tidak bergantung pada query orderBy Firestore.
    // Ini juga tetap dapat membaca data barang lama yang mungkin belum memiliki
    // field `id` lengkap.
    final snapshot = await _items(uid).get();
    final items = snapshot.docs.map((doc) {
      final data = doc.data();
      return ItemModel(
        id: (data['id'] as num?)?.toInt() ?? int.tryParse(doc.id) ?? 0,
        name: data['name'] as String? ?? '',
        price: (data['price'] as num?)?.toDouble() ?? 0,
        stock: (data['stock'] as num?)?.toDouble() ?? 0,
        sold: (data['sold'] as num?)?.toDouble() ?? 0,
        type: data['type'] as String? ?? 'satuan',
        unit: data['unit'] as String? ?? 'pcs',
        barcode: data['barcode'] as String? ?? '',
      );
    }).toList();
    items.sort((a, b) => a.id.compareTo(b.id));
    return items;
  }

  Future<List<ItemModel>> addItem(String uid, ItemModel item) async {
    // Mengambil daftar biasa lalu menentukan ID terbesar secara lokal.
    // Sebelumnya query orderBy di sini dapat gagal sebelum proses simpan.
    final existingItems = await getItems(uid);
    final nextId = existingItems.isEmpty
        ? 1
        : existingItems.map((existing) => existing.id).reduce(
              (highest, id) => id > highest ? id : highest,
            ) + 1;
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

  // ── CATATAN UTANG ───────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> _utang(String uid) =>
      _users.doc(uid).collection('utang');

  Future<List<UtangModel>> getUtang(String uid) async {
    final snapshot = await _utang(uid).get();
    final list = snapshot.docs.map((doc) {
      final data = doc.data();
      return UtangModel.fromMap({
        ...data,
        'id': (data['id'] as num?)?.toInt() ?? int.tryParse(doc.id) ?? 0,
      });
    }).toList();
    // Utang belum lunas dulu, lalu urutkan dari yang terbaru.
    list.sort((a, b) {
      if (a.lunas != b.lunas) return a.lunas ? 1 : -1;
      return b.tanggal.compareTo(a.tanggal);
    });
    return list;
  }

  Future<List<UtangModel>> addUtang(String uid, UtangModel utang) async {
    final existing = await getUtang(uid);
    final nextId = existing.isEmpty
        ? 1
        : existing.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
    final baru = utang.copyWith(id: nextId);
    await _utang(uid).doc('$nextId').set({
      ...baru.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return getUtang(uid);
  }

  Future<void> updateUtang(String uid, UtangModel utang) async {
    await _utang(uid).doc('${utang.id}').set({
      ...utang.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteUtang(String uid, int id) async {
    await _utang(uid).doc('$id').delete();
  }

  Map<String, dynamic> _itemData(ItemModel item) => {
        'id': item.id,
        'name': item.name,
        'price': item.price,
        'stock': item.stock,
        'sold': item.sold,
        'type': item.type,
        'unit': item.unit,
        'barcode': item.barcode,
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
    required List<Map<String, dynamic>> barang,
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
        final data = snap.data() as Map<String, dynamic>;
        final barangHariIni = Map<String, dynamic>.from(
            data['barang'] as Map? ?? const <String, dynamic>{});
        for (final item in barang) {
          final id = item['id'].toString();
          final lama = Map<String, dynamic>.from(
              barangHariIni[id] as Map? ?? const <String, dynamic>{});
          barangHariIni[id] = {
            'nama': item['nama'],
            'jumlah': ((lama['jumlah'] as num?)?.toDouble() ?? 0) +
                (item['jumlah'] as num).toDouble(),
            'total': ((lama['total'] as num?)?.toDouble() ?? 0) +
                (item['total'] as num).toDouble(),
            'satuan': item['satuan'],
          };
        }
        tx.update(ref, {
          'total': FieldValue.increment(total),
          'transaksi': FieldValue.increment(1),
          'barang': barangHariIni,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        final barangHariIni = <String, dynamic>{
          for (final item in barang)
            item['id'].toString(): {
              'nama': item['nama'],
              'jumlah': item['jumlah'],
              'total': item['total'],
              'satuan': item['satuan'],
            },
        };
        tx.set(ref, {
          'tanggal':    tanggal,
          'total':      total,
          'transaksi':  1,
          'barang': barangHariIni,
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

      if (!doc.exists) {
        return {'total': 0.0, 'transaksi': 0, 'barang': <Map<String, dynamic>>[]};
      }

      final data = doc.data() as Map<String, dynamic>;
      return {
        'total':     (data['total']     as num).toDouble(),
        'transaksi': (data['transaksi'] as num).toInt(),
        'barang': (data['barang'] as Map? ?? const <String, dynamic>{})
            .values
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList(),
      };
    } catch (_) {
      return {'total': 0.0, 'transaksi': 0, 'barang': <Map<String, dynamic>>[]};
    }
  }

  /// Semua rekap harian dipakai untuk membentuk laporan bulanan dan tahunan.
  /// ID dokumen menggunakan format ISO (YYYY-MM-DD), sehingga tanggal bisa
  /// diurutkan dan dikelompokkan konsisten di sisi aplikasi.
  Future<List<Map<String, dynamic>>> getRiwayatPendapatan(String uid) async {
    try {
      final snapshot = await _users.doc(uid).collection('pendapatan').get();
      final result = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'tanggal': data['tanggal'] as String? ?? doc.id,
          'total': (data['total'] as num?)?.toDouble() ?? 0,
          'transaksi': (data['transaksi'] as num?)?.toInt() ?? 0,
        };
      }).toList();
      result.sort((a, b) => (a['tanggal'] as String).compareTo(b['tanggal'] as String));
      return result;
    } catch (_) {
      return [];
    }
  }
}
