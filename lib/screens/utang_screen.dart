import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/utang_model.dart';
import '../providers/kasir_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_ui.dart';
import 'utang_detail_screen.dart';
import 'utang_form_screen.dart';

class UtangScreen extends StatefulWidget {
  const UtangScreen({super.key});

  @override
  State<UtangScreen> createState() => _UtangScreenState();
}

class _UtangScreenState extends State<UtangScreen> {
  final _searchCtrl = TextEditingController();
  String _filter = 'belum'; // 'belum' | 'lunas' | 'semua'

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<KasirProvider>();
    final q = _searchCtrl.text.trim().toLowerCase();

    final list = p.utangList.where((u) {
      final byStatus = _filter == 'belum'
          ? !u.lunas
          : _filter == 'lunas'
              ? u.lunas
              : true;
      final bySearch = q.isEmpty || u.nama.toLowerCase().contains(q);
      return byStatus && bySearch;
    }).toList();

    return Column(
      children: [
        AppHeader(
          title: 'Catatan Utang',
          actions: [
            IconButton(
              onPressed: () => _bukaForm(context),
              tooltip: 'Catat utang baru',
              icon: const Icon(Icons.person_add_alt_1_rounded,
                  color: AppColors.inkSoft),
            ),
          ],
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
            children: [
              // Ringkasan total belum lunas
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: AppColors.loginGradient,
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
              const SizedBox(height: 14),

              SearchPill(
                controller: _searchCtrl,
                hint: 'Cari nama...',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    PillChip(
                        label: 'Belum Lunas',
                        active: _filter == 'belum',
                        onTap: () => setState(() => _filter = 'belum')),
                    const SizedBox(width: 10),
                    PillChip(
                        label: 'Lunas',
                        active: _filter == 'lunas',
                        onTap: () => setState(() => _filter = 'lunas')),
                    const SizedBox(width: 10),
                    PillChip(
                        label: 'Semua',
                        active: _filter == 'semua',
                        onTap: () => setState(() => _filter = 'semua')),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              if (list.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: AppEmptyState(
                    icon: Icons.inbox_outlined,
                    title: 'Tidak Ada data',
                    message: 'tekan + di kanan atas\nuntuk menambahkan data',
                  ),
                )
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
                    )),
            ],
          ),
        ),
      ],
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
        backgroundColor: AppColors.success,
      ));
    }
  }

}

class _UtangCard extends StatelessWidget {
  final UtangModel utang;
  final KasirProvider provider;
  final VoidCallback onTap;

  const _UtangCard({
    required this.utang,
    required this.provider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final u = utang;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.softShadow,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: u.lunas
                        ? AppColors.success.withValues(alpha: .12)
                        : AppColors.red.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    u.lunas ? 'LUNAS' : 'BELUM LUNAS',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: u.lunas ? AppColors.success : AppColors.red,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.event_outlined,
                    size: 13, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(provider.formatTanggal(u.tanggal),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              u.lunas
                  ? 'Total: ${provider.formatHarga(u.total)}'
                  : 'Sisa: ${provider.formatHarga(u.sisa)} dari ${provider.formatHarga(u.total)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: u.lunas ? AppColors.textMuted : AppColors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
