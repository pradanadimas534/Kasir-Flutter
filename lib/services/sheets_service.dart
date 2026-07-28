import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class SheetsService {
  static final SheetsService _i = SheetsService._();
  factory SheetsService() => _i;
  SheetsService._();

  final _auth = AuthService();

  // ── Ganti dengan Spreadsheet ID milik kamu ──────────────────────
  static const _spreadsheetId = 'SPREADSHEET_ID_KAMU';

  static const _baseUrl =
      'https://sheets.googleapis.com/v4/spreadsheets/$_spreadsheetId';

  // ── GET request ke Sheets API ────────────────────────────────────
  Future<Map<String, dynamic>> _get(String range) async {
    final headers = await _auth.getAuthHeaders();
    final url     = Uri.parse('$_baseUrl/values/$range');
    final resp    = await http.get(url, headers: headers);

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    throw Exception('Sheets GET error: ${resp.statusCode} ${resp.body}');
  }

  // ── APPEND row ke sheet ──────────────────────────────────────────
  Future<void> _append(String range, List<dynamic> values) async {
    final headers = await _auth.getAuthHeaders();
    headers['Content-Type'] = 'application/json';

    final url = Uri.parse(
      '$_baseUrl/values/$range:append'
      '?valueInputOption=RAW&insertDataOption=INSERT_ROWS',
    );

    await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        'values': [values],
      }),
    );
  }

  // ── UPDATE satu cell ─────────────────────────────────────────────
  Future<void> _update(String range, List<dynamic> values) async {
    final headers = await _auth.getAuthHeaders();
    headers['Content-Type'] = 'application/json';

    final url = Uri.parse(
      '$_baseUrl/values/$range?valueInputOption=RAW',
    );

    await http.put(
      url,
      headers: headers,
      body: jsonEncode({
        'range':  range,
        'values': [values],
      }),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  USERS
  // ════════════════════════════════════════════════════════════════

  // ── Cek apakah uid sudah ada di sheet Users ──────────────────────
  Future<bool> isUserRegistered(String uid) async {
    try {
      final data = await _get('Users!A:A');
      final rows = (data['values'] as List?)?.cast<List>() ?? [];
      return rows.any((row) => row.isNotEmpty && row[0] == uid);
    } catch (_) {
      return false;
    }
  }

  // ── Daftarkan user baru ke sheet Users ───────────────────────────
  Future<void> registerUser({
    required String uid,
    required String nama,
    required String email,
  }) async {
    await _append('Users!A:D', [
      uid,
      nama,
      email,
      DateTime.now().toIso8601String(),
    ]);
  }

  // ════════════════════════════════════════════════════════════════
  //  PENDAPATAN
  // ════════════════════════════════════════════════════════════════

  // ── Tambah/update pendapatan hari ini ────────────────────────────
  Future<void> tambahPendapatan({
    required String uid,
    required double total,
  }) async {
    final today    = DateTime.now();
    final tanggal  = '${today.day.toString().padLeft(2,'0')}/'
                     '${today.month.toString().padLeft(2,'0')}/'
                     '${today.year}';

    // Cek apakah sudah ada baris untuk uid + tanggal hari ini
    final rowIndex = await _findPendapatanRow(uid, tanggal);

    if (rowIndex != -1) {
      // Sudah ada → update total & jumlah transaksi
      final data = await _get('Pendapatan!A:E');
      final rows = (data['values'] as List?)?.cast<List>() ?? [];
      final row  = rows[rowIndex];

      final totalLama       = double.tryParse(row[3].toString()) ?? 0;
      final transaksiLama   = int.tryParse(row[4].toString())    ?? 0;

      final sheetRow = rowIndex + 1; // Sheets index mulai dari 1
      await _update('Pendapatan!D${sheetRow}:E${sheetRow}', [
        (totalLama + total).toStringAsFixed(0),
        (transaksiLama + 1).toString(),
      ]);
    } else {
      // Belum ada → append baris baru
      await _append('Pendapatan!A:E', [
        uid,
        today.toIso8601String(),
        tanggal,
        total.toStringAsFixed(0),
        '1',
      ]);
    }
  }

  // ── Ambil pendapatan hari ini untuk uid tertentu ─────────────────
  Future<Map<String, dynamic>> getPendapatanHariIni(String uid) async {
    try {
      final today   = DateTime.now();
      final tanggal = '${today.day.toString().padLeft(2,'0')}/'
                      '${today.month.toString().padLeft(2,'0')}/'
                      '${today.year}';

      final rowIndex = await _findPendapatanRow(uid, tanggal);
      if (rowIndex == -1) return {'total': 0.0, 'transaksi': 0};

      final data = await _get('Pendapatan!A:E');
      final rows = (data['values'] as List?)?.cast<List>() ?? [];
      final row  = rows[rowIndex];

      return {
        'total':     double.tryParse(row[3].toString()) ?? 0.0,
        'transaksi': int.tryParse(row[4].toString())    ?? 0,
      };
    } catch (_) {
      return {'total': 0.0, 'transaksi': 0};
    }
  }

  // ── Cari index baris pendapatan uid + tanggal ────────────────────
  Future<int> _findPendapatanRow(String uid, String tanggal) async {
    try {
      final data = await _get('Pendapatan!A:C');
      final rows = (data['values'] as List?)?.cast<List>() ?? [];

      for (var i = 0; i < rows.length; i++) {
        final row = rows[i];
        if (row.length >= 3 &&
            row[0].toString() == uid &&
            row[2].toString() == tanggal) {
          return i;
        }
      }
      return -1;
    } catch (_) {
      return -1;
    }
  }
}