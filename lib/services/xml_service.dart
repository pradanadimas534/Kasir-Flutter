import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:xml/xml.dart';
import '../models/item_model.dart';

class XmlService {
  static final XmlService _i = XmlService._();
  factory XmlService() => _i;
  XmlService._();

  // ── Path file XML per user ───────────────────────────────────────
  Future<File> _getFile(String uid) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/KasirKu');
    if (!await folder.exists()) await folder.create(recursive: true);
    return File('${folder.path}/barang_$uid.xml');
  }

  // ── Cek apakah XML user sudah ada ───────────────────────────────
  Future<bool> hasData(String uid) async {
    final file = await _getFile(uid);
    return file.exists();
  }

  // ── Baca semua barang dari XML ───────────────────────────────────
  Future<List<ItemModel>> readAll(String uid) async {
    final file = await _getFile(uid);
    if (!await file.exists()) return [];

    try {
      final content  = await file.readAsString();
      final document = XmlDocument.parse(content);
      final itemNodes = document.findAllElements('item');

      return itemNodes.map((node) {
        final map = <String, String>{};
        for (final child in node.childElements) {
          map[child.name.local] = child.innerText;
        }
        return ItemModel.fromXmlMap(map);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Tulis ulang seluruh XML ──────────────────────────────────────
  Future<void> writeAll(String uid, List<ItemModel> items) async {
    final file = await _getFile(uid);

    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element('items', nest: () {
      builder.attribute('uid', uid);
      builder.attribute('updated', DateTime.now().toIso8601String());
      for (final item in items) {
        builder.element('item', nest: () {
          item.toXmlMap().forEach((key, value) {
            builder.element(key, nest: () => builder.text(value));
          });
        });
      }
    });

    final document = builder.buildDocument();
    await file.writeAsString(
      document.toXmlString(pretty: true),
      flush: true,
    );
  }

  // ── Ambil isi XML sebagai String (untuk upload ke Drive) ─────────
  Future<String?> getRawContent(String uid) async {
    final file = await _getFile(uid);
    if (!await file.exists()) return null;
    return file.readAsString();
  }

  // ── Tulis XML dari String (hasil download dari Drive) ────────────
  Future<void> writeRaw(String uid, String xmlContent) async {
    final file = await _getFile(uid);
    await file.writeAsString(xmlContent, flush: true);
  }

  // ── Tambah satu barang ───────────────────────────────────────────
  Future<List<ItemModel>> addItem(String uid, ItemModel item) async {
    final items  = await readAll(uid);
    final nextId = items.isEmpty
        ? 1
        : items.map((i) => i.id).reduce((a, b) => a > b ? a : b) + 1;
    final newItem = item.copyWith(id: nextId);
    items.add(newItem);
    await writeAll(uid, items);
    return items;
  }

  // ── Update satu barang ───────────────────────────────────────────
  Future<List<ItemModel>> updateItem(String uid, ItemModel updated) async {
    final items = await readAll(uid);
    final idx   = items.indexWhere((i) => i.id == updated.id);
    if (idx != -1) items[idx] = updated;
    await writeAll(uid, items);
    return items;
  }

  // ── Hapus satu barang ────────────────────────────────────────────
  Future<List<ItemModel>> deleteItem(String uid, int id) async {
    final items = await readAll(uid);
    items.removeWhere((i) => i.id == id);
    await writeAll(uid, items);
    return items;
  }
}