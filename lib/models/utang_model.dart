/// Satu baris barang yang dihutang.
class UtangItem {
  final String nama;
  final double jumlah;
  final String satuan; // bebas: 'pcs', 'kg', 'bungkus', dst.
  final double harga;  // harga per satuan; 0 kalau tidak dicatat

  const UtangItem({
    required this.nama,
    this.jumlah = 1,
    this.satuan = 'pcs',
    this.harga = 0,
  });

  double get subtotal => harga * jumlah;

  Map<String, dynamic> toMap() => {
        'nama': nama,
        'jumlah': jumlah,
        'satuan': satuan,
        'harga': harga,
      };

  factory UtangItem.fromMap(Map<String, dynamic> m) => UtangItem(
        nama: m['nama'] as String? ?? '',
        jumlah: (m['jumlah'] as num?)?.toDouble() ?? 1,
        satuan: m['satuan'] as String? ?? 'pcs',
        harga: (m['harga'] as num?)?.toDouble() ?? 0,
      );
}

/// Satu catatan utang milik seseorang.
class UtangModel {
  final int id;
  final String nama;            // nama orang yang berutang
  final DateTime tanggal;       // tanggal dia berutang
  final List<UtangItem> barang; // barang apa saja yang dihutang
  final String catatan;
  final bool lunas;
  final DateTime? tanggalLunas;

  UtangModel({
    required this.id,
    required this.nama,
    required this.tanggal,
    required this.barang,
    this.catatan = '',
    this.lunas = false,
    this.tanggalLunas,
  });

  /// Total nilai utang. 0 kalau tidak ada harga yang dicatat.
  double get total => barang.fold(0.0, (sum, b) => sum + b.subtotal);

  /// Apakah minimal satu barang punya harga.
  bool get adaHarga => barang.any((b) => b.harga > 0);

  UtangModel copyWith({
    int? id,
    String? nama,
    DateTime? tanggal,
    List<UtangItem>? barang,
    String? catatan,
    bool? lunas,
    DateTime? tanggalLunas,
    bool clearTanggalLunas = false,
  }) =>
      UtangModel(
        id: id ?? this.id,
        nama: nama ?? this.nama,
        tanggal: tanggal ?? this.tanggal,
        barang: barang ?? this.barang,
        catatan: catatan ?? this.catatan,
        lunas: lunas ?? this.lunas,
        tanggalLunas:
            clearTanggalLunas ? null : (tanggalLunas ?? this.tanggalLunas),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'nama': nama,
        'tanggal': tanggal.toIso8601String(),
        'barang': barang.map((b) => b.toMap()).toList(),
        'catatan': catatan,
        'lunas': lunas,
        'tanggalLunas': tanggalLunas?.toIso8601String(),
      };

  factory UtangModel.fromMap(Map<String, dynamic> m) {
    final rawBarang = (m['barang'] as List?) ?? const [];
    return UtangModel(
      id: (m['id'] as num?)?.toInt() ?? 0,
      nama: m['nama'] as String? ?? '',
      tanggal: DateTime.tryParse(m['tanggal'] as String? ?? '') ?? DateTime.now(),
      barang: rawBarang
          .map((e) => UtangItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      catatan: m['catatan'] as String? ?? '',
      lunas: m['lunas'] as bool? ?? false,
      tanggalLunas: (m['tanggalLunas'] as String?) == null
          ? null
          : DateTime.tryParse(m['tanggalLunas'] as String),
    );
  }
}
