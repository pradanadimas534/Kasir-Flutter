import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/kasir_provider.dart';

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<KasirProvider>().loadRiwayatPendapatan(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<KasirProvider>();
    final hari = _tujuhHariTerakhir(p, DateTime.now());
    final kemarin = hari[hari.length - 2];
    final hariIni = hari.last;
    final rataRata = hari.take(6).fold<int>(0, (sum, h) => sum + h.transaksi) / 6;
    final naik = hariIni.transaksi >= kemarin.transaksi;
    final ramai = hariIni.transaksi > 0 && hariIni.transaksi >= rataRata;

    return RefreshIndicator(
      onRefresh: () => p.loadRiwayatPendapatan(force: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        children: [
          Row(children: [
            IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu_rounded, color: Color(0xFFE51D2A), size: 28),
            ),
            const SizedBox(width: 4),
            const Text('Laporan', style: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 10),
          const Text('Penjualan hari ini', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Lihat hasil jualan dan tingkat keramaian toko.', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          _HariIniCard(
            total: p.pendapatanHariIni,
            transaksi: p.transaksiHariIni,
            format: p.formatHarga,
          ),
          const SizedBox(height: 20),
          const Text('Barang yang terjual hari ini', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _BarangHariIni(barang: p.barangTerjualHariIni, format: p.formatHarga),
          const SizedBox(height: 20),
          const Text('Ramai atau sepi?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _StatusRamai(
            transaksi: hariIni.transaksi,
            kemarin: kemarin.transaksi,
            rataRata: rataRata,
            ramai: ramai,
            naik: naik,
          ),
          const SizedBox(height: 20),
          const Text('Grafik transaksi 7 hari terakhir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Jumlah transaksi per hari', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 10),
          if (p.laporanLoading)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
          else
            _GrafikTransaksi(data: hari),
        ],
      ),
    );
  }

  List<_Hari> _tujuhHariTerakhir(KasirProvider p, DateTime now) {
    final awalHariIni = DateTime(now.year, now.month, now.day);
    return List.generate(7, (i) {
      final tanggal = awalHariIni.subtract(Duration(days: 6 - i));
      final key = '${tanggal.year}-${tanggal.month.toString().padLeft(2, '0')}-${tanggal.day.toString().padLeft(2, '0')}';
      final data = p.riwayatPendapatan.cast<Map<String, dynamic>>().where((d) => d['tanggal'] == key).toList();
      return _Hari(tanggal, data.fold(0, (sum, d) => sum + (d['transaksi'] as int)), data.fold(0.0, (sum, d) => sum + (d['total'] as double)));
    });
  }
}

class _Hari {
  final DateTime tanggal;
  final int transaksi;
  final double total;
  const _Hari(this.tanggal, this.transaksi, this.total);
}

class _HariIniCard extends StatelessWidget {
  final double total;
  final int transaksi;
  final String Function(double) format;
  const _HariIniCard({required this.total, required this.transaksi, required this.format});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(18)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [Icon(Icons.today_outlined, color: Colors.white70), SizedBox(width: 8), Text('PENJUALAN HARI INI', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold))]),
          const SizedBox(height: 10),
          Text(format(total), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('$transaksi transaksi berhasil', style: const TextStyle(color: Colors.white70)),
        ]),
      );
}

class _BarangHariIni extends StatelessWidget {
  final List<Map<String, dynamic>> barang;
  final String Function(double) format;
  const _BarangHariIni({required this.barang, required this.format});

  @override
  Widget build(BuildContext context) {
    if (barang.isEmpty) return _kotakPesan(Icons.shopping_bag_outlined, 'Belum ada barang terjual hari ini');
    final urut = [...barang]..sort((a, b) => ((b['total'] as num?) ?? 0).compareTo((a['total'] as num?) ?? 0));
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        for (var i = 0; i < urut.length; i++) ...[
          if (i > 0) Divider(height: 1, color: Colors.grey.shade100),
          ListTile(
            leading: CircleAvatar(backgroundColor: Colors.red.shade50, child: Icon(Icons.shopping_bag_outlined, color: Colors.red.shade700, size: 20)),
            title: Text(urut[i]['nama'] as String? ?? '-', style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${_angka(urut[i]['jumlah'])} ${urut[i]['satuan'] ?? 'pcs'}'),
            trailing: Text(format((urut[i]['total'] as num?)?.toDouble() ?? 0), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ]),
    );
  }

  String _angka(dynamic angka) {
    final nilai = (angka as num?)?.toDouble() ?? 0;
    return nilai % 1 == 0 ? nilai.toInt().toString() : nilai.toStringAsFixed(2);
  }
}

class _StatusRamai extends StatelessWidget {
  final int transaksi, kemarin;
  final double rataRata;
  final bool ramai, naik;
  const _StatusRamai({required this.transaksi, required this.kemarin, required this.rataRata, required this.ramai, required this.naik});

  @override
  Widget build(BuildContext context) {
    final warna = ramai ? Colors.green : Colors.orange.shade800;
    final label = transaksi == 0 ? 'Belum ada transaksi' : ramai ? 'Toko sedang ramai' : 'Toko cenderung sepi';
    final beda = transaksi - kemarin;
    final tren = beda == 0 ? 'Sama dengan kemarin' : '${naik ? 'Naik' : 'Turun'} ${beda.abs()} transaksi dari kemarin';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: warna.withValues(alpha: .10), borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Icon(naik ? Icons.trending_up : Icons.trending_down, color: warna, size: 32),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: warna, fontSize: 16)),
          const SizedBox(height: 3),
          Text('$tren. Rata-rata 6 hari terakhir: ${rataRata.toStringAsFixed(1)} transaksi.', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        ])),
      ]),
    );
  }
}

class _GrafikTransaksi extends StatelessWidget {
  final List<_Hari> data;
  const _GrafikTransaksi({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.every((d) => d.transaksi == 0)) return _kotakPesan(Icons.show_chart, 'Belum ada data transaksi untuk grafik');
    final max = data.map((d) => d.transaksi).reduce((a, b) => a > b ? a : b);
    const namaHari = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          for (final h in data)
            Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text('${h.transaksi}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Flexible(child: FractionallySizedBox(
                  heightFactor: h.transaksi / max,
                  alignment: Alignment.bottomCenter,
                  child: Container(decoration: BoxDecoration(color: h == data.last ? Colors.red : Colors.red.shade200, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)))),
                )),
              ]),
            )),
        ])),
        const SizedBox(height: 8),
        Row(children: [for (final h in data) Expanded(child: Center(child: Text(namaHari[h.tanggal.weekday - 1], style: const TextStyle(fontSize: 10))))]),
      ]),
    );
  }
}

Widget _kotakPesan(IconData icon, String pesan) => Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [Icon(icon, size: 36, color: Colors.grey.shade400), const SizedBox(height: 8), Text(pesan, style: TextStyle(color: Colors.grey.shade600))]),
    );
