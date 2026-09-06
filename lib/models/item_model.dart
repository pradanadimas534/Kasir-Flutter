class ItemModel {
  final int id;
  String name;
  double price;
  double stock;
  double sold;
  final String type; // 'satuan' | 'timbang'
  final String unit; // 'pcs' | 'gram' | 'ons' | 'kg'
  final String barcode;

  /// Kalau tidak null: barang ada di "Sampah" sejak tanggal ini.
  /// Dihapus permanen otomatis setelah 30 hari.
  final DateTime? deletedAt;

  ItemModel({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.sold,
    required this.type,
    required this.unit,
    this.barcode = '',
    this.deletedAt,
  });

  bool get diSampah => deletedAt != null;

  ItemModel copyWith({
    int? id,
    String? name,
    double? price,
    double? stock,
    double? sold,
    String? type,
    String? unit,
    String? barcode,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) =>
      ItemModel(
        id:    id    ?? this.id,
        name:  name  ?? this.name,
        price: price ?? this.price,
        stock: stock ?? this.stock,
        sold:  sold  ?? this.sold,
        type:  type  ?? this.type,
        unit:  unit  ?? this.unit,
        barcode: barcode ?? this.barcode,
        deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      );

  // ── XML ──────────────────────────────────────────────────────────
  Map<String, String> toXmlMap() => {
    'id':    id.toString(),
    'name':  name,
    'price': price.toString(),
    'stock': stock.toString(),
    'sold':  sold.toString(),
    'type':  type,
    'unit':  unit,
    'barcode': barcode,
    'deletedAt': deletedAt?.toIso8601String() ?? '',
  };

  factory ItemModel.fromXmlMap(Map<String, String> m) => ItemModel(
    id:    int.parse(m['id']    ?? '0'),
    name:  m['name']  ?? '',
    price: double.parse(m['price'] ?? '0'),
    stock: double.parse(m['stock'] ?? '0'),
    sold:  double.parse(m['sold']  ?? '0'),
    type:  m['type']  ?? 'satuan',
    unit:  m['unit']  ?? 'pcs',
    barcode: m['barcode'] ?? '',
    deletedAt: (m['deletedAt'] ?? '').isEmpty
        ? null
        : DateTime.tryParse(m['deletedAt']!),
  );
}
