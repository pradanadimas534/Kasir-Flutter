class ItemModel {
  final int id;
  String name;
  double price;
  double stock;
  double sold;
  final String type; // 'satuan' | 'timbang'
  final String unit; // 'pcs' | 'gram' | 'ons' | 'kg'

  ItemModel({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.sold,
    required this.type,
    required this.unit,
  });

  ItemModel copyWith({
    int? id,
    String? name,
    double? price,
    double? stock,
    double? sold,
    String? type,
    String? unit,
  }) =>
      ItemModel(
        id:    id    ?? this.id,
        name:  name  ?? this.name,
        price: price ?? this.price,
        stock: stock ?? this.stock,
        sold:  sold  ?? this.sold,
        type:  type  ?? this.type,
        unit:  unit  ?? this.unit,
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
  };

  factory ItemModel.fromXmlMap(Map<String, String> m) => ItemModel(
    id:    int.parse(m['id']    ?? '0'),
    name:  m['name']  ?? '',
    price: double.parse(m['price'] ?? '0'),
    stock: double.parse(m['stock'] ?? '0'),
    sold:  double.parse(m['sold']  ?? '0'),
    type:  m['type']  ?? 'satuan',
    unit:  m['unit']  ?? 'pcs',
  );
}