import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/utang_model.dart';
import '../providers/kasir_provider.dart';

class UtangFormScreen extends StatefulWidget {
  const UtangFormScreen({super.key});

  @override
  State<UtangFormScreen> createState() => _UtangFormScreenState();
}

class _BarisBarang {
  final nama = TextEditingController();
  final jumlah = TextEditingController(text: '1');
  final satuan = TextEditingController(text: 'pcs');
  final harga = TextEditingController();

  void dispose() {
    nama.dispose();
    jumlah.dispose();
    satuan.dispose();
    harga.dispose();
  }
}

class _UtangFormScreenState extends State<UtangFormScreen> {
  final _namaCtrl = TextEditingController();
  final _catatanCtrl = TextEditingController();
  DateTime _tanggal = DateTime.now();
  final List<_BarisBarang> _baris = [_BarisBarang()];
  bool _saving = false;

  @override
  void dispose() {
    _namaCtrl.dispose();
    _catatanCtrl.dispose();
    for (final b in _baris) {
      b.dispose();
    }
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
    final p = context.read<KasirProvider>();
    final nama = _namaCtrl.text.trim();

    final barang = <UtangItem>[];
    for (final b in _baris) {
      final nm = b.nama.text.trim();
      if (nm.isEmpty) continue;
      barang.add(UtangItem(
        nama: nm,
        jumlah: double.tryParse(b.jumlah.text.replaceAll(',', '.')) ?? 1,
        satuan: b.satuan.text.trim().isEmpty ? 'pcs' : b.satuan.text.trim(),
        harga: double.tryParse(b.harga.text) ?? 0,
      ));
    }

    if (nama.isEmpty) {
      _snack('Isi nama orang yang berutang dulu.', Colors.red);
      return;
    }
    if (barang.isEmpty) {
      _snack('Tulis minimal satu barang yang dihutang.', Colors.red);
      return;
    }

    setState(() => _saving = true);
    try {
      await p.tambahUtang(
        nama: nama,
        tanggal: _tanggal,
        barang: barang,
        catatan: _catatanCtrl.text,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('Gagal menyimpan utang: $e', Colors.red);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.read<KasirProvider>();

    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),
      appBar: AppBar(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        title: const Text('Catat Utang Baru'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // ── Nama orang ────────────────────────────────────────
          _label('Nama orang yang berutang'),
          const SizedBox(height: 6),
          TextField(
            controller: _namaCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: _dec('Contoh: Bu Sri'),
          ),
          const SizedBox(height: 16),

          // ── Tanggal ───────────────────────────────────────────
          _label('Tanggal berutang'),
          const SizedBox(height: 6),
          InkWell(
            onTap: _pilihTanggal,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 18, color: Colors.red),
                  const SizedBox(width: 10),
                  Text(
                    p.formatTanggal(_tanggal),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Text('Ubah',
                      style: TextStyle(
                          color: Colors.red.shade700, fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Daftar barang ─────────────────────────────────────
          Row(
            children: [
              _label('Barang yang dihutang'),
              const Spacer(),
              TextButton.icon(
                onPressed: () => setState(() => _baris.add(_BarisBarang())),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tambah baris'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...List.generate(_baris.length, (i) => _barisBarangWidget(i)),
          const SizedBox(height: 8),

          // ── Catatan ───────────────────────────────────────────
          _label('Catatan (opsional)'),
          const SizedBox(height: 6),
          TextField(
            controller: _catatanCtrl,
            maxLines: 2,
            decoration: _dec('Contoh: dibayar setelah panen'),
          ),
          const SizedBox(height: 20),

          // ── Simpan ────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _simpan,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Simpan Catatan Utang',
                      style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _barisBarangWidget(int i) {
    final b = _baris[i];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: b.nama,
                  textCapitalization: TextCapitalization.words,
                  decoration: _dec('Nama barang, mis. Beras'),
                ),
              ),
              if (_baris.length > 1)
                IconButton(
                  onPressed: () => setState(() {
                    _baris.removeAt(i).dispose();
                  }),
                  icon: const Icon(Icons.close, size: 18),
                  color: Colors.red.shade300,
                  tooltip: 'Hapus baris',
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: b.jumlah,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: _dec('Jumlah'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: b.satuan,
                  decoration: _dec('Satuan'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: b.harga,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _dec('Harga/satuan (opsional)'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      );

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        isDense: true,
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      );
}
