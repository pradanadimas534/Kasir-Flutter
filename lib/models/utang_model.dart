/// Satu catatan utang milik seseorang.
///
/// Catatan lama yang memuat daftar barang tetap bisa dibaca; catatan baru
/// hanya membutuhkan nominal utang dan catatan opsional.
class UtangModel {
  final int id;
  final String nama;
  final DateTime tanggal;
  final double nominal;
  final double totalDibayar;
  final String catatan;
  final bool lunas;
  final DateTime? tanggalLunas;

  const UtangModel({
    required this.id,
    required this.nama,
    required this.tanggal,
    required this.nominal,
    this.totalDibayar = 0,
    this.catatan = '',
    this.lunas = false,
    this.tanggalLunas,
  });

  double get total => nominal;
  double get sisa => (nominal - totalDibayar).clamp(0, double.infinity);

  UtangModel copyWith({
    int? id,
    String? nama,
    DateTime? tanggal,
    double? nominal,
    double? totalDibayar,
    String? catatan,
    bool? lunas,
    DateTime? tanggalLunas,
    bool clearTanggalLunas = false,
  }) =>
      UtangModel(
        id: id ?? this.id,
        nama: nama ?? this.nama,
        tanggal: tanggal ?? this.tanggal,
        nominal: nominal ?? this.nominal,
        totalDibayar: totalDibayar ?? this.totalDibayar,
        catatan: catatan ?? this.catatan,
        lunas: lunas ?? this.lunas,
        tanggalLunas:
            clearTanggalLunas ? null : (tanggalLunas ?? this.tanggalLunas),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'nama': nama,
        'tanggal': tanggal.toIso8601String(),
        'nominal': nominal,
        'totalDibayar': totalDibayar,
        'catatan': catatan,
        'lunas': lunas,
        'tanggalLunas': tanggalLunas?.toIso8601String(),
      };

  factory UtangModel.fromMap(Map<String, dynamic> m) {
    // Migrasi ringan: nominal dokumen lama dihitung dari daftar barangnya.
    final barangLama = (m['barang'] as List? ?? const []).fold<double>(
      0,
      (jumlah, item) {
        final data = Map<String, dynamic>.from(item as Map);
        return jumlah +
            ((data['jumlah'] as num?)?.toDouble() ?? 1) *
                ((data['harga'] as num?)?.toDouble() ?? 0);
      },
    );
    final nominal = (m['nominal'] as num?)?.toDouble() ?? barangLama;
    final totalDibayar = (m['totalDibayar'] as num?)?.toDouble() ??
        ((m['lunas'] as bool? ?? false) ? nominal : 0);
    return UtangModel(
      id: (m['id'] as num?)?.toInt() ?? 0,
      nama: m['nama'] as String? ?? '',
      tanggal: DateTime.tryParse(m['tanggal'] as String? ?? '') ?? DateTime.now(),
      nominal: nominal,
      totalDibayar: totalDibayar.clamp(0, nominal),
      catatan: m['catatan'] as String? ?? '',
      lunas: m['lunas'] as bool? ?? totalDibayar >= nominal,
      tanggalLunas: (m['tanggalLunas'] as String?) == null
          ? null
          : DateTime.tryParse(m['tanggalLunas'] as String),
    );
  }
}
