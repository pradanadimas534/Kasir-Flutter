import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/item_model.dart';
import '../services/auth_service.dart';
import '../services/xml_service.dart';
import '../services/sheets_service.dart';
import '../services/drive_service.dart';

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
  final _auth   = AuthService();
  final _xml    = XmlService();
  final _sheets = SheetsService();
  final _drive  = DriveService();

  // ── STATE ────────────────────────────────────────────────────────
  List<ItemModel> items    = [];
  List<CartItem>  cart     = [];

  bool   isLoading  = true;
  bool   isLoggedIn = false;
  String status     = '';

  double pendapatanHariIni = 0;
  int    transaksiHariIni  = 0;

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
  //  INIT
  // ════════════════════════════════════════════════════════════════
  Future<void> init() async {
    isLoading = true;
    notifyListeners();

    // Coba login diam-diam (pakai akun yang sudah pernah login)
    final ok = await _auth.signIn();

    if (ok) {
      await _onLogin();
    } else {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Proses setelah login ─────────────────────────────────────────
  Future<void> _onLogin() async {
    isLoggedIn = true;
    status     = 'Memuat data...';
    notifyListeners();

    // ── LANGKAH 1: Daftarkan user ke Sheets jika belum ada ────────
    // Jalankan di background, tidak perlu tunggu
    _sheets.isUserRegistered(uid).then((terdaftar) {
      if (!terdaftar) {
        _sheets.registerUser(
          uid:   uid,
          nama:  userName,
          email: userEmail,
        );
      }
    });

    // ── LANGKAH 2: Cek XML lokal ──────────────────────────────────
    final adaLokal = await _xml.hasData(uid);

    if (adaLokal) {
      // ✅ Ada data lokal → langsung pakai, tidak perlu cek Drive
      status = 'Memuat data lokal...';
      notifyListeners();
      items = await _xml.readAll(uid);
    } else {
      // ❌ Tidak ada lokal → pertama kali login di HP ini
      // Coba download dari Drive (kalau pernah backup sebelumnya)
      status = 'HP baru terdeteksi, mencari backup...';
      notifyListeners();

      bool restored = false;
      try {
        final adaDrive = await _drive.hasCloudData(uid);
        if (adaDrive) {
          status = 'Memulihkan data dari backup...';
          notifyListeners();
          final ok = await _drive.downloadXml(uid);
          if (ok) {
            items    = await _xml.readAll(uid);
            restored = true;
            status   = 'Data berhasil dipulihkan ✓';
          }
        }
      } catch (_) {
        // Tidak ada internet / Drive error → mulai kosong
      }

      if (!restored) {
        // Benar-benar baru, mulai dari kosong
        items  = [];
        status = '';
      }
    }

    // ── LANGKAH 3: Load pendapatan hari ini (background) ──────────
    _loadPendapatan();

    isLoading = false;
    notifyListeners();
  }

  // ── Load pendapatan hari ini ─────────────────────────────────────
  Future<void> _loadPendapatan() async {
    try {
      final data = await _sheets.getPendapatanHariIni(uid);
      pendapatanHariIni = data['total']     as double;
      transaksiHariIni  = data['transaksi'] as int;
      notifyListeners();
    } catch (_) {
      pendapatanHariIni = 0;
      transaksiHariIni  = 0;
    }
  }

  // ════════════════════════════════════════════════════════════════
  //  LOGIN & LOGOUT
  // ════════════════════════════════════════════════════════════════
  Future<bool> login() async {
    isLoading = true;
    notifyListeners();

    final ok = await _auth.signIn();
    if (ok) {
      await _onLogin();
      return true;
    }

    isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    // Upload XML ke Drive sebelum logout (background)
    try { _drive.uploadXml(uid); } catch (_) {}

    await _auth.signOut();

    items             = [];
    cart              = [];
    isLoggedIn        = false;
    pendapatanHariIni = 0;
    transaksiHariIni  = 0;
    status            = '';
    notifyListeners();
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

    // Update sold di memori
    for (final c in cart) {
      final idx = items.indexWhere((i) => i.id == c.id);
      if (idx != -1) items[idx].sold += c.qty;
    }

    final totalBayar = total;
    cart.clear();

    // 1. Simpan ke XML lokal dulu (pasti berhasil)
    await _xml.writeAll(uid, items);

    // 2. Kirim pendapatan ke Sheets (background, tidak block UI)
    _sheets.tambahPendapatan(uid: uid, total: totalBayar)
        .then((_) => _loadPendapatan())
        .catchError((_) {});

    // 3. Upload XML ke Drive (background)
    _drive.uploadXml(uid).catchError((_) {});

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
  }) async {
    if (name.isEmpty || price <= 0) return;

    final newItem = ItemModel(
      id: 0, name: name, price: price,
      stock: stock, sold: 0, type: type, unit: unit,
    );

    // Simpan ke lokal
    items = await _xml.addItem(uid, newItem);

    // Backup ke Drive di background
    _drive.uploadXml(uid).catchError((_) {});

    notifyListeners();
  }

  Future<void> hapusItem(int id) async {
    cart.removeWhere((c) => c.id == id);
    items = await _xml.deleteItem(uid, id);
    _drive.uploadXml(uid).catchError((_) {});
    notifyListeners();
  }

  Future<void> ubahStok(int id, double value) async {
    final idx = items.indexWhere((i) => i.id == id);
    if (idx == -1) return;
    items[idx].stock = value < 0 ? 0 : value;
    await _xml.writeAll(uid, items);
    notifyListeners();
  }

  Future<void> ubahHarga(int id, double value) async {
    final idx = items.indexWhere((i) => i.id == id);
    if (idx == -1) return;
    items[idx].price = value < 0 ? 0 : value;
    await _xml.writeAll(uid, items);
    notifyListeners();
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
    super.dispose();
  }
}