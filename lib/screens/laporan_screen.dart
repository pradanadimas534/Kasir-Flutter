import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/kasir_provider.dart';

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  bool _tahunan = false;
  int _jumlahPeriode = 6;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KasirProvider>().loadRiwayatPendapatan();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<KasirProvider>();
    final now = DateTime.now();
    final data = _buatPeriode(p.riwayatPendapatan, now);
    final periodeIni = data.isEmpty ? _Periode('', now, 0, 0) : data.last;
    final periodeLalu = data.length < 2 ? null : data[data.length - 2];
    final selisih = periodeLalu == null ? 0.0 : periodeIni.total - periodeLalu.total;
    final persen = periodeLalu == null || periodeLalu.total == 0
        ? null : selisih / periodeLalu.total * 100;

    return RefreshIndicator(
      onRefresh: () => p.loadRiwayatPendapatan(force: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.menu_rounded,
                    color: Color(0xFFE51D2A), size: 28),
              ),
              const SizedBox(width: 4),
              const Text('Laporan',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Laporan omzet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Pantau hasil penjualan dan tren usaha Anda.', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          _HariIniCard(total: p.pendapatanHariIni, transaksi: p.transaksiHariIni, format: p.formatHarga),
          const SizedBox(height: 20),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, icon: Icon(Icons.calendar_month_outlined), label: Text('Bulanan')),
              ButtonSegment(value: true, icon: Icon(Icons.calendar_today_outlined), label: Text('Tahunan')),
            ],
            selected: {_tahunan},
            onSelectionChanged: (value) => setState(() {
              _tahunan = value.first;
              _jumlahPeriode = _tahunan ? 2 : 3;
            }),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Text('Bandingkan ', style: TextStyle(color: Colors.grey.shade700)),
            DropdownButton<int>(
              value: _jumlahPeriode,
              underline: const SizedBox(),
              items: (_tahunan ? [2, 3, 5] : [3, 6, 12]).map((jumlah) => DropdownMenuItem(
                value: jumlah, child: Text('$jumlah ${_tahunan ? 'tahun' : 'bulan'} terakhir'),
              )).toList(),
              onChanged: (value) => setState(() => _jumlahPeriode = value!),
            ),
          ]),
          const SizedBox(height: 8),
          if (p.laporanLoading) const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
          else ...[
            _TrendCard(
              label: _tahunan ? 'Tahun ini' : 'Bulan ini',
              total: periodeIni.total,
              transaksi: periodeIni.transaksi,
              selisih: selisih,
              persen: persen,
              pembanding: periodeLalu?.label,
              format: p.formatHarga,
            ),
            const SizedBox(height: 20),
            Text('Riwayat ${_tahunan ? 'tahunan' : 'bulanan'}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (data.every((item) => item.total == 0))
              _EmptyReport(tahunan: _tahunan)
            else
              ...data.reversed.map((item) => _PeriodTile(item: item, maxTotal: data.map((e) => e.total).fold(0.0, (a, b) => a > b ? a : b), format: p.formatHarga)),
          ],
        ],
      ),
    );
  }

  List<_Periode> _buatPeriode(List<Map<String, dynamic>> riwayat, DateTime now) {
    final jumlah = _jumlahPeriode;
    final hasil = <_Periode>[];
    for (var i = jumlah - 1; i >= 0; i--) {
      final date = _tahunan ? DateTime(now.year - i) : DateTime(now.year, now.month - i);
      final key = _tahunan
          ? '${date.year}'
          : '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final total = riwayat.where((d) => (d['tanggal'] as String).startsWith(key)).fold<double>(0, (sum, d) => sum + (d['total'] as double));
      final transaksi = riwayat.where((d) => (d['tanggal'] as String).startsWith(key)).fold<int>(0, (sum, d) => sum + (d['transaksi'] as int));
      hasil.add(_Periode(
        _tahunan ? '${date.year}' : '${_namaBulan[date.month - 1]} ${date.year}',
        date,
        total,
        transaksi,
      ));
    }
    return hasil;
  }

  static const _namaBulan = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];
}

class _Periode {
  final String label;
  final DateTime date;
  final double total;
  final int transaksi;
  const _Periode(this.label, this.date, this.total, this.transaksi);
}

class _HariIniCard extends StatelessWidget {
  final double total; final int transaksi; final String Function(double) format;
  const _HariIniCard({required this.total, required this.transaksi, required this.format});
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(18)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [Icon(Icons.today_outlined, color: Colors.white70), SizedBox(width: 8), Text('HASIL HARI INI', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold))]),
      const SizedBox(height: 10), Text(format(total), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4), Text('$transaksi transaksi berhasil', style: const TextStyle(color: Colors.white70)),
    ]),
  );
}

class _TrendCard extends StatelessWidget {
  final String label; final double total; final int transaksi; final double selisih; final double? persen; final String? pembanding; final String Function(double) format;
  const _TrendCard({required this.label, required this.total, required this.transaksi, required this.selisih, required this.persen, required this.pembanding, required this.format});
  @override Widget build(BuildContext context) {
    final naik = selisih >= 0;
    final color = naik ? Colors.green : Colors.red;
    final teks = pembanding == null ? 'Belum ada periode sebelumnya untuk dibandingkan' : '${naik ? 'Naik' : 'Turun'} ${format(selisih.abs())}${persen == null ? '' : ' (${persen!.abs().toStringAsFixed(1)}%)'} dari $pembanding';
    return Card(elevation: 0, color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)), child: Padding(
      padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600)), const SizedBox(height: 5), Text(format(total), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10), Row(children: [Icon(naik ? Icons.trending_up : Icons.trending_down, color: color), const SizedBox(width: 6), Expanded(child: Text(teks, style: TextStyle(color: pembanding == null ? Colors.grey.shade600 : color, fontWeight: FontWeight.w600, fontSize: 12)))]),
        const SizedBox(height: 6), Text('$transaksi transaksi', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      ]),
    ));
  }
}

class _PeriodTile extends StatelessWidget {
  final _Periode item; final double maxTotal; final String Function(double) format;
  const _PeriodTile({required this.item, required this.maxTotal, required this.format});
  @override Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
    child: Column(children: [Row(children: [Expanded(child: Text(item.label, style: const TextStyle(fontWeight: FontWeight.w600))), Text(format(item.total), style: const TextStyle(fontWeight: FontWeight.bold))]), const SizedBox(height: 9), ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: maxTotal == 0 ? 0 : item.total / maxTotal, minHeight: 7, backgroundColor: Colors.red.shade50, color: Colors.red)), const SizedBox(height: 6), Align(alignment: Alignment.centerLeft, child: Text('${item.transaksi} transaksi', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)))],),
  );
}

class _EmptyReport extends StatelessWidget {
  final bool tahunan; const _EmptyReport({required this.tahunan});
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Column(children: [Icon(Icons.receipt_long_outlined, size: 38, color: Colors.grey.shade400), const SizedBox(height: 8), Text('Belum ada penjualan pada periode ini', style: TextStyle(color: Colors.grey.shade600)), const SizedBox(height: 4), Text('Data akan muncul setelah transaksi diproses.', style: TextStyle(fontSize: 12, color: Colors.grey.shade500))]));
}
