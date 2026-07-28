import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'xml_service.dart';

class DriveService {
  static final DriveService _i = DriveService._();
  factory DriveService() => _i;
  DriveService._();

  final _auth = AuthService();
  final _xml  = XmlService();

  static const _baseUrl = 'https://www.googleapis.com/drive/v3';
  static const _uploadUrl = 'https://www.googleapis.com/upload/drive/v3';

  // ── Nama file XML di Drive ───────────────────────────────────────
  String _fileName(String uid) => 'barang_$uid.xml';

  // ════════════════════════════════════════════════════════════════
  //  CARI FILE DI DRIVE
  // ════════════════════════════════════════════════════════════════

  // ── Cari file berdasarkan nama, return fileId atau null ──────────
  Future<String?> _findFileId(String uid) async {
    try {
      final headers = await _auth.getAuthHeaders();
      final name    = _fileName(uid);

      final url = Uri.parse(
        '$_baseUrl/files'
        '?q=name%3D%27$name%27+and+trashed%3Dfalse'
        '&fields=files(id,name)'
        '&spaces=drive',
      );

      final resp = await http.get(url, headers: headers);
      if (resp.statusCode != 200) return null;

      final data  = jsonDecode(resp.body) as Map<String, dynamic>;
      final files = (data['files'] as List?) ?? [];

      if (files.isEmpty) return null;
      return files.first['id'] as String;
    } catch (_) {
      return null;
    }
  }

  // ════════════════════════════════════════════════════════════════
  //  UPLOAD XML KE DRIVE
  // ════════════════════════════════════════════════════════════════

  Future<bool> uploadXml(String uid) async {
    try {
      final content = await _xml.getRawContent(uid);
      if (content == null) return false;

      final headers  = await _auth.getAuthHeaders();
      final fileId   = await _findFileId(uid);
      final fileName = _fileName(uid);
      final bytes    = utf8.encode(content);

      if (fileId != null) {
        // ── File sudah ada → UPDATE ──────────────────────────────
        final url = Uri.parse(
          '$_uploadUrl/files/$fileId?uploadType=media',
        );

        final resp = await http.patch(
          url,
          headers: {
            ...headers,
            'Content-Type': 'application/xml',
          },
          body: bytes,
        );
        return resp.statusCode == 200;
      } else {
        // ── File belum ada → CREATE ──────────────────────────────
        // Step 1: buat metadata
        final metaResp = await http.post(
          Uri.parse('$_baseUrl/files'),
          headers: {
            ...headers,
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'name':     fileName,
            'mimeType': 'application/xml',
          }),
        );

        if (metaResp.statusCode != 200) return false;
        final newId = jsonDecode(metaResp.body)['id'] as String;

        // Step 2: upload isi file
        final uploadResp = await http.patch(
          Uri.parse('$_uploadUrl/files/$newId?uploadType=media'),
          headers: {
            ...headers,
            'Content-Type': 'application/xml',
          },
          body: bytes,
        );
        return uploadResp.statusCode == 200;
      }
    } catch (_) {
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════════
  //  DOWNLOAD XML DARI DRIVE
  // ════════════════════════════════════════════════════════════════

  Future<bool> downloadXml(String uid) async {
    try {
      final headers = await _auth.getAuthHeaders();
      final fileId  = await _findFileId(uid);

      // Tidak ada file di Drive → return false
      if (fileId == null) return false;

      final url = Uri.parse(
        '$_baseUrl/files/$fileId?alt=media',
      );

      final resp = await http.get(url, headers: headers);
      if (resp.statusCode != 200) return false;

      // Simpan ke lokal
      await _xml.writeRaw(uid, resp.body);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════════
  //  CEK ADA FILE DI DRIVE
  // ════════════════════════════════════════════════════════════════

  Future<bool> hasCloudData(String uid) async {
    final fileId = await _findFileId(uid);
    return fileId != null;
  }
}