import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/kasir_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_ui.dart';

class UtangFormScreen extends StatefulWidget {
  const UtangFormScreen({super.key});

  @override
  State<UtangFormScreen> createState() => _UtangFormScreenState();
}

class _UtangFormScreenState extends State<UtangFormScreen> {
  final _namaCtrl = TextEditingController();
  final _nominalCtrl = TextEditingController();
  final _catatanCtrl = TextEditingController();
  DateTime _tanggal = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _namaCtrl.dispose();
    _nominalCtrl.dispose();
    _catatanCtrl.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
    final hasil = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Tanggal berutang',
    );
    if (hasil != null) setState(() => _tanggal = hasil);
  }

  Future<void> _simpan() async {
    final nama = _namaCtrl.text.trim();
    final nominal = double.tryParse(_nominalCtrl.text) ?? 0;
    if (nama.isEmpty) return _snack('Isi nama orang yang berutang.', Colors.red);
    if (nominal <= 0) return _snack('Isi nominal utang yang benar.', Colors.red);

    setState(() => _saving = true);
    try {
      await context.read<KasirProvider>().tambahUtang(
            nama: nama,
            tanggal: _tanggal,
            nominal: nominal,
            catatan: _catatanCtrl.text,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _snack('Gagal menyimpan utang: $e', Colors.red);
      }
    }
  }

  void _snack(String message, Color color) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message), backgroundColor: color));

  @override
  Widget build(BuildContext context) {
    final p = context.read<KasirProvider>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(children: [
        AppHeader(title: 'Catat Utang Baru', onBack: () => Navigator.pop(context)),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _label('Nama orang yang berutang'),
              const SizedBox(height: 6),
              TextField(
                controller: _namaCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: _dec('Contoh: Bu Sri'),
              ),
              const SizedBox(height: 16),
              _label('Tanggal berutang'),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pilihTanggal,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.red),
                    const SizedBox(width: 10),
                    Text(p.formatTanggal(_tanggal), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    const Spacer(),
                    Text('Ubah', style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              _label('Nominal utang'),
              const SizedBox(height: 6),
              TextField(
                controller: _nominalCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _dec('Contoh: 50000').copyWith(prefixText: 'Rp '),
              ),
              const SizedBox(height: 16),
              _label('Catatan (opsional)'),
              const SizedBox(height: 6),
              TextField(
                controller: _catatanCtrl,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: _dec('Contoh: membeli beras dan minyak'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _simpan,
                  style: FilledButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: _saving
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Simpan Catatan Utang', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _label(String text) => Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13));
  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        isDense: true,
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      );
}
