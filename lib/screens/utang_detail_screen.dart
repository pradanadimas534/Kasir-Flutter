import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/utang_model.dart';
import '../providers/kasir_provider.dart';

class UtangDetailScreen extends StatelessWidget {
  final int utangId;
  const UtangDetailScreen({super.key, required this.utangId});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<KasirProvider>();
    final u = p.cariUtang(utangId);

    // Sudah dihapus dari halaman lain -> tutup saja.
    if (u == null) {
      return const Scaffold(
        body: Center(child: Text('Catatan utang tidak ditemukan')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),
      appBar: AppBar(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        title: const Text('Detail Utang'),
        actions: [
          IconButton(
            onPressed: () => _konfirmasiHapus(context, p, u),
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Hapus catatan',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // ── Kepala: nama + status ─────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.red.shade50,
                      child: Text(
                        u.nama.isNotEmpty ? u.nama[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            u.nama,
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.event_outlined,
                                  size: 13, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                'Berutang ${p.formatTanggal(u.tanggal)}',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _statusChip(u.lunas),
                  ],
                ),
                if (u.lunas && u.tanggalLunas != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Lunas pada ${p.formatTanggal(u.tanggalLunas!)}',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Daftar barang ─────────────────────────────────────
          const Text('Barang yang dihutang',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                for (var i = 0; i < u.barang.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: Colors.grey.shade100),
                  _barisBarang(p, u.barang[i]),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Total ─────────────────────────────────────────────
          if (u.adaHarga)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total utang',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(
                    p.formatHarga(u.total),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),

          // ── Catatan ───────────────────────────────────────────
          if (u.catatan.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Catatan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(u.catatan,
                  style: const TextStyle(fontSize: 13, height: 1.4)),
            ),
          ],
          const SizedBox(height: 24),

          // ── Tombol lunas ──────────────────────────────────────
          if (!u.lunas)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _tandaiLunas(context, p, u, true),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Tandai Sudah Lunas',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _tandaiLunas(context, p, u, false),
                icon: const Icon(Icons.undo, size: 18),
                label: const Text('Batalkan status lunas'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _barisBarang(KasirProvider p, UtangItem b) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.nama,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  b.harga > 0
                      ? '${p.formatQty(b.jumlah)} ${b.satuan} × ${p.formatHarga(b.harga)}'
                      : '${p.formatQty(b.jumlah)} ${b.satuan}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          if (b.harga > 0)
            Text(
              p.formatHarga(b.subtotal),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13),
            ),
        ],
      ),
    );
  }

  Widget _statusChip(bool lunas) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: lunas ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        lunas ? 'LUNAS' : 'BELUM LUNAS',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: lunas ? Colors.green.shade700 : Colors.red.shade700,
        ),
      ),
    );
  }

  Future<void> _tandaiLunas(
      BuildContext context, KasirProvider p, UtangModel u, bool lunas) async {
    try {
      await p.setUtangLunas(u.id, lunas);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(lunas
            ? 'Utang ${u.nama} ditandai lunas'
            : 'Status lunas ${u.nama} dibatalkan'),
        backgroundColor: lunas ? Colors.green : Colors.grey.shade700,
      ));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Gagal menyimpan: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _konfirmasiHapus(
      BuildContext context, KasirProvider p, UtangModel u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus catatan utang'),
        content: Text('Hapus catatan utang atas nama "${u.nama}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await p.hapusUtang(u.id);
      if (!context.mounted) return;
      Navigator.pop(context); // kembali ke daftar
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Gagal menghapus: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }
}
