import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../theme/app_theme.dart';
import '../widgets/success_check.dart';

class StrukItem {
  final String nama;
  final double qty;
  final String unit;
  final double harga;
  const StrukItem({
    required this.nama,
    required this.qty,
    required this.unit,
    required this.harga,
  });
  double get subtotal => qty * harga;
}

class StrukData {
  final DateTime waktu;
  final String kasir;
  final List<StrukItem> items;
  final double total;
  final double bayar;
  final double kembalian;

  const StrukData({
    required this.waktu,
    required this.kasir,
    required this.items,
    required this.total,
    required this.bayar,
    required this.kembalian,
  });

  String get nomor => DateFormat('yyMMdd-HHmmss').format(waktu);
}

class StrukScreen extends StatelessWidget {
  final StrukData data;
  const StrukScreen({super.key, required this.data});

  static final _rupiah = NumberFormat.currency(
      locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  String _rp(double v) => _rupiah.format(v);
  String _qty(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(2);

  static const _bulan = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];
  String _tglJam(DateTime d) =>
      '${d.day} ${_bulan[d.month - 1]} ${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  String _teksStruk() {
    final b = StringBuffer()
      ..writeln('KASIR TOKO')
      ..writeln('Kasir & Operasional')
      ..writeln('=========================')
      ..writeln('No   : ${data.nomor}')
      ..writeln('Tgl  : ${_tglJam(data.waktu)}')
      ..writeln('Kasir: ${data.kasir}')
      ..writeln('-------------------------');
    for (final it in data.items) {
      b
        ..writeln(it.nama)
        ..writeln('  ${_qty(it.qty)} ${it.unit} x ${_rp(it.harga)}'
            '  =  ${_rp(it.subtotal)}');
    }
    b
      ..writeln('-------------------------')
      ..writeln('TOTAL   : ${_rp(data.total)}')
      ..writeln('BAYAR   : ${_rp(data.bayar)}')
      ..writeln('KEMBALI : ${_rp(data.kembalian)}')
      ..writeln('=========================')
      ..writeln('Terima kasih telah berbelanja');
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
                children: [
                  Center(child: const SuccessCheck(size: 100)),
                  const SizedBox(height: 14),
                  const Center(
                    child: Text('Pembayaran Berhasil',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 20)),
                  ),
                  if (data.kembalian > 0) ...[
                    const SizedBox(height: 4),
                    Center(
                      child: Text('Kembalian ${_rp(data.kembalian)}',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 13)),
                    ),
                  ],
                  const SizedBox(height: 22),
                  _kertasStruk(),
                ],
              ),
            ),
            _footer(context),
          ],
        ),
      ),
    );
  }

  Widget _kertasStruk() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.softShadow,
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: Text('Kasir Toko',
                style: TextStyle(
                    fontFamily: 'Lobster',
                    fontSize: 30,
                    color: AppColors.red)),
          ),
          const Center(
            child: Text('Kasir & Operasional',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textMuted)),
          ),
          const _Dashed(),
          _baris('No', data.nomor),
          _baris('Tanggal', _tglJam(data.waktu)),
          _baris('Kasir', data.kasir),
          const _Dashed(),
          ...data.items.map(_itemBaris),
          const _Dashed(),
          _totalBaris('TOTAL', _rp(data.total), tebal: true),
          _totalBaris('Bayar', _rp(data.bayar)),
          _totalBaris('Kembali', _rp(data.kembalian)),
          const _Dashed(),
          const Center(
            child: Text('Terima kasih telah berbelanja 🙏',
                style: TextStyle(fontSize: 12, color: AppColors.inkSoft)),
          ),
        ],
      ),
    );
  }

  Widget _itemBaris(StrukItem it) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(it.nama,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
          Row(
            children: [
              Expanded(
                child: Text(
                  '  ${_qty(it.qty)} ${it.unit} x ${_rp(it.harga)}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted),
                ),
              ),
              Text(_rp(it.subtotal),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _baris(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(
              width: 66,
              child: Text(k,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted)),
            ),
            Text(': ',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textMuted)),
            Expanded(
              child: Text(v, style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );

  Widget _totalBaris(String k, String v, {bool tebal = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k,
                style: TextStyle(
                    fontSize: tebal ? 15 : 13,
                    fontWeight: tebal ? FontWeight.bold : FontWeight.w500)),
            Text(v,
                style: TextStyle(
                    fontSize: tebal ? 16 : 13,
                    fontWeight: tebal ? FontWeight.bold : FontWeight.w600,
                    color: tebal ? AppColors.red : AppColors.ink)),
          ],
        ),
      );

  Widget _footer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: .06),
              blurRadius: 12,
              offset: const Offset(0, -3)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Share.share(_teksStruk(),
                  subject: 'Struk Kasir Toko'),
              icon: const Icon(Icons.share_outlined, size: 18),
              label: const Text('Bagikan'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.ink,
                side: const BorderSide(color: AppColors.ink, width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.red,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Selesai',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Garis putus-putus ala kertas struk.
class _Dashed extends StatelessWidget {
  const _Dashed();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: LayoutBuilder(
        builder: (context, c) {
          final n = (c.maxWidth / 8).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              n,
              (_) => Container(
                width: 4,
                height: 1.4,
                color: AppColors.line,
              ),
            ),
          );
        },
      ),
    );
  }
}
