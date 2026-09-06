import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/item_model.dart';
import '../providers/kasir_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_ui.dart';

class SampahScreen extends StatelessWidget {
  const SampahScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<KasirProvider>();
    final trash = p.trashItems;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          AppHeader(
            title: 'Sampah',
            onBack: () => Navigator.pop(context),
            actions: [
              if (trash.isNotEmpty)
                TextButton(
                  onPressed: () => _kosongkan(context, p),
                  child: const Text('Kosongkan',
                      style: TextStyle(color: AppColors.red)),
                ),
            ],
          ),
          Container(
            width: double.infinity,
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: const Text(
              'Barang di sini dihapus otomatis setelah 30 hari. '
              'Pulihkan sebelum itu kalau masih dibutuhkan.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: trash.isEmpty
                ? const AppEmptyState(
                    icon: Icons.delete_outline,
                    title: 'Sampah kosong',
                    message: 'Barang yang kamu hapus akan muncul di sini',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                    itemCount: trash.length,
                    itemBuilder: (_, i) =>
                        _TrashTile(item: trash[i], provider: p),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _kosongkan(BuildContext context, KasirProvider p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Kosongkan Sampah'),
        content: Text(
            'Hapus permanen ${p.trashItems.length} barang di Sampah? '
            'Tindakan ini tidak bisa dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await p.kosongkanSampah();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Sampah dikosongkan'),
      ));
    }
  }
}

class _TrashTile extends StatelessWidget {
  final ItemModel item;
  final KasirProvider provider;
  const _TrashTile({required this.item, required this.provider});

  @override
  Widget build(BuildContext context) {
    final sisa = provider.sisaHariSampah(item);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.name,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 2),
          Text(
            'Dihapus ${provider.formatTanggal(item.deletedAt!)} · '
            '${sisa == 0 ? 'akan dihapus hari ini' : 'sisa $sisa hari'}',
            style: TextStyle(
              fontSize: 11,
              color: sisa <= 3 ? AppColors.red : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await provider.pulihkanItem(item.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('${item.name} dipulihkan'),
                        backgroundColor: AppColors.success,
                      ));
                    }
                  },
                  icon: const Icon(Icons.restore_rounded, size: 18),
                  label: const Text('Pulihkan'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.success,
                    side: BorderSide(
                        color: AppColors.success.withValues(alpha: .5)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _hapusPermanen(context),
                tooltip: 'Hapus permanen',
                icon: const Icon(Icons.delete_forever_rounded,
                    color: AppColors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _hapusPermanen(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus permanen'),
        content: Text('Hapus "${item.name}" selamanya?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await provider.hapusPermanenItem(item.id);
  }
}
