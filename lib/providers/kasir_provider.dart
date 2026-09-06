import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/item_model.dart';
import '../models/utang_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class CartItem {
  final int    id;
  final String name;
  final String type;
  final String unit;
  final double price;
  double qty;

  CartItem({
    required this.id,
    required this.name,
    required this.type,
    required this.unit,
    required this.price,
    required this.qty,
  });

  double get total => price * qty;
}

class KasirProvider extends ChangeNotifier {
  final _auth      = AuthService();
  final _firestore = FirestoreService();

  // ── STATE ────────────────────────────────────────────────────────
  List<ItemModel> items      = []; // barang aktif (tidak di sampah)
  List<ItemModel> trashItems = []; // barang di "Sampah"
  List<CartItem>  cart     = [];
  List<UtangModel> utangList = [];

  static const int umurSampahHari = 30;

  bool   isLoading  = true;
  bool   isLoggedIn = false;
  String status     = '';
  String loginError = '';

  double pendapatanHariIni = 0;
  int    transaksiHariIni  = 0;
  List<Map<String, dynamic>> barangTerjualHariIni = [];
  List<Map<String, dynamic>> riwayatPendapatan = [];
  bool laporanLoading = false;

  StreamSubscription? _authSub;

  // ── FORMAT ───────────────────────────────────────────────────────
  final _rupiah = NumberFormat.currency(
    locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0,
  );

  String formatHarga(double v) => _rupiah.format(v);

  String formatQty(double qty) =>
      qty % 1 == 0 ? qty.toInt().toString() : qty.toStringAsFixed(2);

  String formatStock(ItemModel item) {
    if (item.type == 'timbang') {
      return '${item.stock.toStringAsFixed(0)} ${item.unit}';
    }
    return '${item.stock.toStringAsFixed(0)} pcs';
  }

  // ── STATUS STOK ──────────────────────────────────────────────────
  double getThreshold(ItemModel item) {
    if (item.type == 'timbang') {
      if (item.unit == 'gram') return 500;
      if (item.unit == 'ons')  return 5;
      return 1;
    }
    return 5;
  }

  String getStatus(ItemModel item) {
    if (item.stock <= 0)                  return 'Habis';
    if (item.stock <= getThreshold(item)) return 'Menipis';
    return 'Aman';
  }

  Color getStatusColor(ItemModel item) {
    if (item.stock <= 0)                  return Colors.red;
    if (item.stock <= getThreshold(item)) return Colors.orange;
    return Colors.green;
  }

  // ── INFO USER ────────────────────────────────────────────────────
  String get uid       => _auth.uid;
  String get userName  => _auth.userName;
  String get userEmail => _auth.userEmail;
  String get userPhoto => _auth.userPhoto;

  // ════════════════════════════════════════════════════════════════
  //  INIT — dengarkan perubahan status login Firebase
  // ════════════════════════════════════════════════════════════════
  Future<void> init() async {
    isLoading = true;
    notifyListeners();

    // Firebase adalah sumber status sesi. Gerbang UI juga mendengarkan stream
    // yang sama, sehingga perpindahan ke beranda tidak bergantung pada proses
    // Firestore di bawah ini.
    _authSub = _auth.userStream.listen((user) async {
      if (user != null) {
        isLoggedIn = true;
        await _onLogin();
      } else {
        await _onLogout();
      }
    });
  }

  // ── Proses setelah login ─────────────────────────────────────────
  Future<void> _onLogin() async {
    isLoading = true;
    status    = 'Memuat data...';
    notifyListeners();

    // 1. Daftarkan user ke Firestore (jika belum ada)
    _firestore.isUserRegistered(uid).then((ada) {
      if (!ada) {
        _firestore.registerUser(
          uid:   uid,
          nama:  userName,
          email: userEmail,
        );
      }
    });

    // 2. Muat barang langsung dari Firestore
    try {
      await _muatBarang();
      status = '';
    } catch (_) {
      items = [];
      trashItems = [];
      status = 'Gagal memuat data barang';
    }

    // 2b. Muat catatan utang
    try {
      utangList = await _firestore.getUtang(uid);
    } catch (_) {
      utangList = [];
    }

    // 3. Load pendapatan hari ini
    _loadPendapatan();

    isLoading = false;
    notifyListeners();
  }

  // ── Muat & pilah barang aktif vs sampah + bersihkan yang kedaluwarsa ──
  Future<void> _muatBarang() async {
    final semua = await _firestore.getItems(uid);

    // Auto-hapus permanen barang yang di sampah lebih dari 30 hari.
    final batas =
        DateTime.now().subtract(const Duration(days: umurSampahHari));
    for (final b in semua
        .where((i) => i.deletedAt != null && i.deletedAt!.isBefore(batas))
        .toList()) {
      try {
        await _firestore.deleteItem(uid, b.id);
      } catch (_) {}
      semua.remove(b);
    }

    items = semua.where((i) => i.deletedAt == null).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    trashItems = semua.where((i) => i.deletedAt != null).toList()
      ..sort((a, b) => b.deletedAt!.compareTo(a.deletedAt!));
  }

  /// Sisa hari sebelum barang di sampah dihapus permanen.
  int sisaHariSampah(ItemModel item) {
    if (item.deletedAt == null) return umurSampahHari;
    final sisa =
        umurSampahHari - DateTime.now().difference(item.deletedAt!).inDays;
    return sisa < 0 ? 0 : sisa;
  }

  // ── Proses setelah logout ────────────────────────────────────────
  Future<void> _onLogout() async {
    items             = [];
    trashItems        = [];
    cart              = [];
    utangList         = [];
    isLoggedIn        = false;
    pendapatanHariIni = 0;
    transaksiHariIni  = 0;
    barangTerjualHariIni = [];
    riwayatPendapatan = [];
    laporanLoading = false;
    status            = '';
    isLoading         = false;
    notifyListeners();
  }

  // ── Load pendapatan hari ini ─────────────────────────────────────
  Future<void> _loadPendapatan() async {
    try {
      final data = await _firestore.getPendapatanHariIni(uid);
      pendapatanHariIni = data['total']     as double;
      transaksiHariIni  = data['transaksi'] as int;
      barangTerjualHariIni = List<Map<String, dynamic>>.from(
          data['barang'] as List? ?? const <Map<String, dynamic>>[]);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadRiwayatPendapatan({bool force = false}) async {
    if (laporanLoading || (riwayatPendapatan.isNotEmpty && !force)) return;
    laporanLoading = true;
    notifyListeners();
    riwayatPendapatan = await _firestore.getRiwayatPendapatan(uid);
    laporanLoading = false;
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════════
  //  LOGIN & LOGOUT
  // ════════════════════════════════════════════════════════════════
  Future<bool> login() async {
    isLoading = true;
    loginError = '';
    notifyListeners();

    final ok = await _auth.signIn();

    if (!ok) {
      loginError = _auth.lastError;
      isLoading = false;
      notifyListeners();
      return false;
    }
    // _onLogin dipanggil otomatis dari _authSub
    return true;
  }

  Future<void> logout() async {
    await _auth.signOut();
    // _onLogout dipanggil otomatis dari _authSub
  }

  // ════════════════════════════════════════════════════════════════
  //  CART
  // ════════════════════════════════════════════════════════════════
  void tambahKeCart(ItemModel item, {double qty = 1}) {
    if (item.stock < qty) return;

    final idx = cart.indexWhere((c) => c.id == item.id);
    if (idx != -1) {
      if (cart[idx].qty + qty > item.stock) return;
      cart[idx].qty += qty;
    } else {
      cart.add(CartItem(
        id:    item.id,
        name:  item.name,
        type:  item.type,
        unit:  item.unit,
        price: item.price,
        qty:   qty,
      ));
    }
    item.stock -= qty;
    notifyListeners();
  }

  ItemModel? cariBarangDariBarcode(String barcode) {
    final kode = barcode.trim();
    if (kode.isEmpty) return null;
    for (final item in items) {
      if (item.barcode.trim() == kode) return item;
    }
    return null;
  }

  void kurangiQty(int id) {
    final idx = cart.indexWhere((c) => c.id == id);
    if (idx == -1) return;

    final step    = cart[idx].type == 'timbang' ? 0.1 : 1.0;
    final itemIdx = items.indexWhere((i) => i.id == id);
    if (itemIdx != -1) items[itemIdx].stock += step;

    cart[idx].qty -= step;
    if (cart[idx].qty <= 0) {
      cart.removeAt(idx);
    }
    notifyListeners();
  }

  void hapusCartItem(int id) {
    final idx = cart.indexWhere((c) => c.id == id);
    if (idx == -1) return;
    final itemIdx = items.indexWhere((i) => i.id == cart[idx].id);
    if (itemIdx != -1) items[itemIdx].stock += cart[idx].qty;
    cart.removeAt(idx);
    notifyListeners();
  }

  void clearCart() {
    for (final c in cart) {
      final idx = items.indexWhere((i) => i.id == c.id);
      if (idx != -1) items[idx].stock += c.qty;
    }
    cart.clear();
    notifyListeners();
  }

  double get total => cart.fold(0.0, (s, c) => s + c.total);

  // ════════════════════════════════════════════════════════════════
  //  PROSES BAYAR
  // ════════════════════════════════════════════════════════════════
  Future<void> prosesBayar(double bayar) async {
    if (cart.isEmpty || bayar < total) return;

    for (final c in cart) {
      final idx = items.indexWhere((i) => i.id == c.id);
      if (idx != -1) items[idx].sold += c.qty;
    }

    final totalBayar = total;
    final barangTerjual = cart
        .map((c) => {
              'id': c.id,
              'nama': c.name,
              'jumlah': c.qty,
              'satuan': c.unit,
              'total': c.total,
            })
        .toList();

    // 1. Simpan perubahan barang ke Firestore
    await Future.wait(items.map((item) => _firestore.updateItem(uid, item)));
    cart.clear();

    // 2. Kirim ke Firestore (background)
    _firestore
        .tambahPendapatan(
          uid: uid,
          total: totalBayar,
          barang: barangTerjual,
        )
        .then((_) {
          _loadPendapatan();
          loadRiwayatPendapatan(force: true);
        })
        .catchError((_) {});

    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════════
  //  MANAJEMEN BARANG
  // ════════════════════════════════════════════════════════════════
  String newItemType = 'satuan';
  void setNewType(String type) {
    newItemType = type;
    notifyListeners();
  }

  Future<void> addItem({
    required String name,
    required double price,
    required double stock,
    required String type,
    required String unit,
    String barcode = '',
  }) async {
    if (name.isEmpty || price <= 0) return;
    final cleanBarcode = barcode.trim();
    if (cleanBarcode.isNotEmpty &&
        items.any((item) => item.barcode.trim() == cleanBarcode)) {
      throw StateError('Barcode sudah dipakai oleh barang lain');
    }

    final newItem = ItemModel(
      id: 0,
      name: name,
      price: price,
      stock: stock,
      sold: 0,
      type: type,
      unit: unit,
      barcode: cleanBarcode,
    );

    try {
      await _firestore.addItem(uid, newItem);
      await _muatBarang();
      notifyListeners();
    } catch (e, st) {
      debugPrint('Gagal menambah barang: $e\n$st');
      // Lempar lagi supaya UI (stok_screen.dart) bisa menampilkan
      // pesan error yang sebenarnya ke pengguna, bukan diam saja.
      rethrow;
    }
  }

  /// Pindahkan barang ke "Sampah" (soft delete). Bisa dipulihkan dalam 30 hari.
  Future<void> hapusItem(int id) async {
    final idx = items.indexWhere((i) => i.id == id);
    if (idx == -1) return;
    cart.removeWhere((c) => c.id == id);
    final dibuang = items[idx].copyWith(deletedAt: DateTime.now());
    await _firestore.updateItem(uid, dibuang);
    items.removeAt(idx);
    trashItems.insert(0, dibuang);
    notifyListeners();
  }

  /// Kembalikan barang dari "Sampah" ke daftar aktif.
  Future<void> pulihkanItem(int id) async {
    final idx = trashItems.indexWhere((i) => i.id == id);
    if (idx == -1) return;
    final pulih = trashItems[idx].copyWith(clearDeletedAt: true);
    await _firestore.updateItem(uid, pulih);
    trashItems.removeAt(idx);
    items.add(pulih);
    items.sort((a, b) => a.id.compareTo(b.id));
    notifyListeners();
  }

  /// Hapus permanen satu barang di "Sampah".
  Future<void> hapusPermanenItem(int id) async {
    await _firestore.deleteItem(uid, id);
    trashItems.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  /// Kosongkan seluruh "Sampah" (hapus permanen semuanya).
  Future<void> kosongkanSampah() async {
    for (final id in trashItems.map((i) => i.id).toList()) {
      try {
        await _firestore.deleteItem(uid, id);
      } catch (_) {}
    }
    trashItems.clear();
    notifyListeners();
  }

  Future<void> ubahStok(int id, double value) async {
    final idx = items.indexWhere((i) => i.id == id);
    if (idx == -1) return;
    final stokLama = items[idx].stock;
    items[idx].stock = value < 0 ? 0 : value;
    try {
      await _firestore.updateItem(uid, items[idx]);
      notifyListeners();
    } catch (e) {
      // Gagal simpan ke server -> kembalikan nilai lokal biar UI tidak
      // menampilkan stok baru yang sebenarnya belum tersimpan.
      items[idx].stock = stokLama;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> tambahStok(int id, double jumlah) async {
    if (jumlah <= 0) return;
    final idx = items.indexWhere((i) => i.id == id);
    if (idx == -1) return;
    items[idx].stock += jumlah;
    await _firestore.updateItem(uid, items[idx]);
    notifyListeners();
  }

  Future<void> ubahBarcode(int id, String barcode) async {
    final idx = items.indexWhere((item) => item.id == id);
    if (idx == -1) return;
    final cleanBarcode = barcode.trim();
    if (cleanBarcode.isNotEmpty &&
        items.any((item) =>
            item.id != id && item.barcode.trim() == cleanBarcode)) {
      throw StateError('Barcode sudah dipakai oleh barang lain');
    }
    items[idx] = items[idx].copyWith(barcode: cleanBarcode);
    await _firestore.updateItem(uid, items[idx]);
    notifyListeners();
  }

  Future<void> ubahHarga(int id, double value) async {
    final idx = items.indexWhere((i) => i.id == id);
    if (idx == -1) return;
    items[idx].price = value < 0 ? 0 : value;
    await _firestore.updateItem(uid, items[idx]);
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════════
  //  CATATAN UTANG
  // ════════════════════════════════════════════════════════════════
  static const _namaBulan = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  String formatTanggal(DateTime d) =>
      '${d.day} ${_namaBulan[d.month - 1]} ${d.year}';

  List<UtangModel> get utangBelumLunas =>
      utangList.where((u) => !u.lunas).toList();

  double get totalUtangBelumLunas =>
      utangBelumLunas.fold(0.0, (sum, u) => sum + u.sisa);

  int get jumlahUtangBelumLunas => utangBelumLunas.length;

  UtangModel? cariUtang(int id) {
    for (final u in utangList) {
      if (u.id == id) return u;
    }
    return null;
  }

  Future<void> tambahUtang({
    required String nama,
    required DateTime tanggal,
    required double nominal,
    String catatan = '',
  }) async {
    if (nama.trim().isEmpty || nominal <= 0) {
      throw ArgumentError('Nama dan nominal utang wajib diisi.');
    }
    final baru = UtangModel(
      id: 0,
      nama: nama.trim(),
      tanggal: tanggal,
      nominal: nominal,
      catatan: catatan.trim(),
    );
    utangList = await _firestore.addUtang(uid, baru);
    notifyListeners();
  }

  Future<void> hapusUtang(int id) async {
    await _firestore.deleteUtang(uid, id);
    utangList.removeWhere((u) => u.id == id);
    notifyListeners();
  }

  /// Catat pembayaran. Status menjadi lunas hanya saat sisa utang sudah nol.
  Future<void> bayarUtang(int id, double nominalBayar) async {
    final idx = utangList.indexWhere((u) => u.id == id);
    if (idx == -1) return;
    if (nominalBayar <= 0) {
      throw ArgumentError('Nominal pelunasan harus lebih dari Rp 0.');
    }
    final lama = utangList[idx];
    if (lama.lunas) return;
    if (nominalBayar > lama.sisa) {
      throw ArgumentError('Nominal pelunasan melebihi sisa utang.');
    }
    final dibayarBaru = lama.totalDibayar + nominalBayar;
    final sudahLunas = dibayarBaru >= lama.total;
    final baru = lama.copyWith(
      totalDibayar: dibayarBaru,
      lunas: sudahLunas,
      tanggalLunas: sudahLunas ? DateTime.now() : null,
    );
    utangList[idx] = baru;
    notifyListeners();
    try {
      await _firestore.updateUtang(uid, baru);
    } catch (e) {
      // Gagal simpan -> kembalikan nilai lama supaya UI tidak menipu.
      utangList[idx] = lama;
      notifyListeners();
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════════
  //  STATISTIK
  // ════════════════════════════════════════════════════════════════
  int get totalBarang => items.length;
  int get stokMenipis => items.where((i) =>
      i.stock > 0 && i.stock <= getThreshold(i)).length;
  int get stokHabis   => items.where((i) => i.stock <= 0).length;

  List<ItemModel> get restockList =>
      items.where((i) => i.stock <= getThreshold(i)).toList();

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
