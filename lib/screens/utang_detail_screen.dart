import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/utang_model.dart';
import '../providers/kasir_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_ui.dart';

class UtangDetailScreen extends StatelessWidget {
  final int utangId;
  const UtangDetailScreen({super.key, required this.utangId});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<KasirProvider>();
    final u = p.cariUtang(utangId);
    if (u == null) return const Scaffold(body: Center(child: Text('Catatan utang tidak ditemukan')));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(children: [
        AppHeader(
          title: 'Detail Utang',
          onBack: () => Navigator.pop(context),
          actions: [
            IconButton(
              onPressed: () => _konfirmasiHapus(context, p, u),
              icon: const Icon(Icons.delete_outline, color: AppColors.inkSoft),
              tooltip: 'Hapus catatan',
            ),
          ],
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _kepala(context, p, u),
              const SizedBox(height: 16),
              _nominal(p, u),
              if (u.catatan.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Catatan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                  child: Text(u.catatan, style: const TextStyle(fontSize: 13, height: 1.4)),
                ),
              ],
              const SizedBox(height: 24),
              if (!u.lunas)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _dialogPelunasan(context, p, u),
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('Lunas', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: FilledButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _kepala(BuildContext context, KasirProvider p, UtangModel u) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.red.shade50,
            child: Text(u.nama.isEmpty ? '?' : u.nama[0].toUpperCase(), style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(u.nama, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 3),
            Text('Berutang ${p.formatTanggal(u.tanggal)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            if (u.lunas && u.tanggalLunas != null)
              Text('Lunas ${p.formatTanggal(u.tanggalLunas!)}', style: TextStyle(fontSize: 12, color: Colors.green.shade700)),
          ])),
          _statusChip(u.lunas),
        ]),
      );

  Widget _nominal(KasirProvider p, UtangModel u) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: u.lunas ? Colors.green.shade50 : Colors.red.shade50, borderRadius: BorderRadius.circular(14)),
        child: Column(children: [
          _baris('Total utang', p.formatHarga(u.total)),
          const SizedBox(height: 10),
          _baris('Sudah dibayar', p.formatHarga(u.totalDibayar)),
          const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1)),
          _baris('Sisa utang', p.formatHarga(u.sisa), besar: true),
        ]),
      );

  Widget _baris(String label, String nilai, {bool besar = false}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: besar ? FontWeight.bold : FontWeight.w500, fontSize: besar ? 15 : 13)),
          Text(nilai, style: TextStyle(fontWeight: FontWeight.bold, fontSize: besar ? 20 : 14)),
        ],
      );

  Widget _statusChip(bool lunas) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: lunas ? Colors.green.shade50 : Colors.red.shade50, borderRadius: BorderRadius.circular(20)),
        child: Text(lunas ? 'LUNAS' : 'BELUM LUNAS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: lunas ? Colors.green.shade700 : Colors.red.shade700)),
      );

  Future<void> _dialogPelunasan(BuildContext context, KasirProvider p, UtangModel u) async {
    final nominalCtrl = TextEditingController();
    final bayar = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Pelunasan utang'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Sisa utang: ${p.formatHarga(u.sisa)}'),
          const SizedBox(height: 12),
          TextField(
            controller: nominalCtrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(prefixText: 'Rp ', labelText: 'Nominal yang dibayar'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, double.tryParse(nominalCtrl.text) ?? 0),
            child: const Text('Lunas'),
          ),
        ],
      ),
    );
    nominalCtrl.dispose();
    if (bayar == null) return;
    try {
      await p.bayarUtang(u.id, bayar);
      if (!context.mounted) return;
      final sisa = p.cariUtang(u.id)?.sisa ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(sisa == 0 ? 'Utang ${u.nama} sudah lunas' : 'Pembayaran tersimpan. Sisa ${p.formatHarga(sisa)}'),
        backgroundColor: sisa == 0 ? Colors.green : Colors.orange.shade800,
      ));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _konfirmasiHapus(BuildContext context, KasirProvider p, UtangModel u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus catatan utang'),
        content: Text('Hapus catatan utang atas nama "${u.nama}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await p.hapusUtang(u.id);
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: Colors.red));
    }
  }
}
