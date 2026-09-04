import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/utang_model.dart';
import '../providers/kasir_provider.dart';
import 'utang_detail_screen.dart';
import 'utang_form_screen.dart';

class UtangScreen extends StatefulWidget {
  const UtangScreen({super.key});

  @override
  State<UtangScreen> createState() => _UtangScreenState();
}

class _UtangScreenState extends State<UtangScreen> {
  String _filter = 'belum'; // 'belum' | 'lunas' | 'semua'

  @override
  Widget build(BuildContext context) {
    final p = context.watch<KasirProvider>();

    final list = p.utangList.where((u) {
      if (_filter == 'belum') return !u.lunas;
      if (_filter == 'lunas') return u.lunas;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _bukaForm(context),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Catat Utang'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 96),
        children: [
          const Text('Catatan Utang',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Siapa berutang, kapan, dan barang apa saja.',
              style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 16),

          // ── Ringkasan ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.account_balance_wallet_outlined,
                      color: Colors.white70, size: 18),
                  SizedBox(width: 8),
                  Text('TOTAL UTANG BELUM LUNAS',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 10),
                Text(
                  p.formatHarga(p.totalUtangBelumLunas),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${p.jumlahUtangBelumLunas} catatan belum dilunasi',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Filter ────────────────────────────────────────────
          Row(
            children: [
              _filterChip('belum', 'Belum Lunas'),
              const SizedBox(width: 8),
              _filterChip('lunas', 'Lunas'),
              const SizedBox(width: 8),
              _filterChip('semua', 'Semua'),
            ],
          ),
          const SizedBox(height: 12),

          // ── Daftar ────────────────────────────────────────────
          if (list.isEmpty)
            _kosong()
          else
            ...list.map((u) => _UtangCard(
                  utang: u,
                  provider: p,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UtangDetailScreen(utangId: u.id),
                    ),
                  ),
                  onLunas: u.lunas ? null : () => _tandaiLunas(context, p, u),
                )),
        ],
      ),
    );
  }

  Future<void> _bukaForm(BuildContext context) async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const UtangFormScreen()),
    );
    if (added == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Catatan utang tersimpan'),
        backgroundColor: Colors.green,
      ));
    }
  }

  Future<void> _tandaiLunas(
      BuildContext context, KasirProvider p, UtangModel u) async {
    try {
      await p.setUtangLunas(u.id, true);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Utang ${u.nama} ditandai lunas'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Gagal menyimpan: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Widget _filterChip(String value, String label) {
    final active = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.red : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: active ? Colors.red : Colors.grey.shade200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: active ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _kosong() => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              _filter == 'lunas'
                  ? 'Belum ada utang yang lunas'
                  : _filter == 'belum'
                      ? 'Tidak ada utang yang belum lunas'
                      : 'Belum ada catatan utang',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text('Tekan tombol "Catat Utang" untuk menambah.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ],
        ),
      );
}

class _UtangCard extends StatelessWidget {
  final UtangModel utang;
  final KasirProvider provider;
  final VoidCallback onTap;
  final VoidCallback? onLunas;

  const _UtangCard({
    required this.utang,
    required this.provider,
    required this.onTap,
    required this.onLunas,
  });

  String get _ringkasBarang {
    if (utang.barang.isEmpty) return '-';
    final pertama = utang.barang.first.nama;
    if (utang.barang.length == 1) return pertama;
    return '$pertama +${utang.barang.length - 1} lainnya';
  }

  @override
  Widget build(BuildContext context) {
    final u = utang;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    u.nama,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: u.lunas
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    u.lunas ? 'LUNAS' : 'BELUM LUNAS',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: u.lunas
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.event_outlined,
                    size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Text(provider.formatTanggal(u.tanggal),
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.shopping_bag_outlined,
                    size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _ringkasBarang,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (u.adaHarga) ...[
              const SizedBox(height: 8),
              Text(
                provider.formatHarga(u.total),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: u.lunas ? Colors.grey : Colors.red.shade700,
                ),
              ),
            ],
            if (onLunas != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: onLunas,
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Lunas'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green.shade700,
                    side: BorderSide(color: Colors.green.shade300),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 4),
                    minimumSize: const Size(0, 34),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
