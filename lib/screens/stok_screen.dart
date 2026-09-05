import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/item_model.dart';
import '../providers/kasir_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_ui.dart';
import 'barcode_scanner_screen.dart';

class StokScreen extends StatefulWidget {
  const StokScreen({super.key});

  @override
  State<StokScreen> createState() => _StokScreenState();
}

class _StokScreenState extends State<StokScreen> {
  final _searchCtrl = TextEditingController();
  bool  _showForm   = false;

  // Form tambah barang
  final _nameCtrl  = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _nameFocus = FocusNode();
  String _newType  = 'satuan';
  String _newUnit  = 'pcs';
  bool   _isSaving = false;

  // Edit inline
  int?   _editId;
  final _editStockCtrl = TextEditingController();
  final _editPriceCtrl = TextEditingController();
  final _editBarcodeCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _barcodeCtrl.dispose();
    _nameFocus.dispose();
    _editStockCtrl.dispose();
    _editPriceCtrl.dispose();
    _editBarcodeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<KasirProvider>();

    final filtered = p.items.where((item) {
      return _searchCtrl.text.isEmpty ||
          item.name.toLowerCase().contains(
              _searchCtrl.text.toLowerCase());
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Header ─────────────────────────────────────────────
          Row(
            children: [
              IconButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.menu_rounded,
                    color: AppColors.red, size: 28),
              ),
              const SizedBox(width: 4),
              const Text(
                'Stok Barang',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Summary Cards ──────────────────────────────────────
          Row(
            children: [
              _SumCard(
                label: 'Total Barang',
                value: '${p.totalBarang}',
                color: Colors.blue,
                icon:  Icons.inventory_2_outlined,
              ),
              const SizedBox(width: 8),
              _SumCard(
                label: 'Menipis',
                value: '${p.stokMenipis}',
                color: Colors.orange,
                icon:  Icons.warning_amber_rounded,
              ),
              const SizedBox(width: 8),
              _SumCard(
                label: 'Habis',
                value: '${p.stokHabis}',
                color: Colors.red,
                icon:  Icons.remove_shopping_cart_outlined,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Search + Tombol Tambah ─────────────────────────────
          Row(
            children: [
              Expanded(
                child: SearchPill(
                  controller: _searchCtrl,
                  hint: 'Cari barang...',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: () => setState(() => _showForm = !_showForm),
                icon: Icon(_showForm ? Icons.close : Icons.add),
                label: Text(_showForm ? 'Tutup' : 'Tambah'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.red,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Form Tambah Barang ─────────────────────────────────
          if (_showForm)
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tambah Barang Baru',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Toggle jenis
                  Row(
                    children: [
                      _typeChip('satuan',  '📦 Satuan'),
                      const SizedBox(width: 8),
                      _typeChip('timbang', '⚖️ Timbang'),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Input nama
                  _formField(
                    ctrl:        _nameCtrl,
                    label:       'Nama Barang',
                    hint:        _newType == 'satuan'
                        ? 'Contoh: Indomie Goreng'
                        : 'Contoh: Telur / Beras / Tepung',
                    inputType:   TextInputType.text,
                    focusNode:   _nameFocus,
                  ),
                  const SizedBox(height: 8),

                  // Barcode — hanya untuk barang satuan.
                  // Barang timbang (telur, beras, tepung kiloan) tidak
                  // punya barcode, jadi field ini disembunyikan.
                  if (_newType == 'satuan') ...[
                    Row(
                      children: [
                        Expanded(
                          child: _formField(
                            ctrl: _barcodeCtrl,
                            label: 'Barcode (opsional)',
                            hint: 'Scan atau ketik manual',
                            inputType: TextInputType.text,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          onPressed: () => _scanBarcodeUntuk(_barcodeCtrl),
                          tooltip: 'Scan barcode',
                          icon: const BarcodeIcon(size: 22),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  Row(
                    children: [
                      // Input harga
                      Expanded(
                        child: _formField(
                          ctrl:      _priceCtrl,
                          label:     _newType == 'satuan'
                              ? 'Harga/pcs (Rp)'
                              : 'Harga/$_newUnit (Rp)',
                          hint:      '0',
                          inputType: TextInputType.number,
                          formatter: FilteringTextInputFormatter
                              .digitsOnly,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Satuan (timbang only)
                      if (_newType == 'timbang')
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _newUnit,
                            decoration: InputDecoration(
                              labelText: 'Satuan',
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'gram',
                                  child: Text('per gram')),
                              DropdownMenuItem(
                                  value: 'ons',
                                  child: Text('per ons')),
                              DropdownMenuItem(
                                  value: 'kg',
                                  child: Text('per kg')),
                            ],
                            onChanged: (v) =>
                                setState(() => _newUnit = v!),
                          ),
                        ),

                      // Stok awal
                      const SizedBox(width: 8),
                      Expanded(
                        child: _formField(
                          ctrl:      _stockCtrl,
                          label:     'Stok Awal',
                          hint:      '0',
                          inputType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          formatter: FilteringTextInputFormatter
                              .allow(RegExp(r'[0-9.]')),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Tombol simpan ────────────────────────────────
                  if (_newType == 'satuan') ...[
                    // Mode cepat: isi nama + harga sekali, lalu tinggal
                    // scan. "tit" — tersimpan, ganti nama + harga,
                    // "tit" — tersimpan lagi, dan seterusnya.
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isSaving ? null : _tambahCepatScan,
                        icon: _isSaving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const BarcodeIcon(light: true, size: 22),
                        label: Text(
                          _isSaving
                              ? 'Menyimpan...'
                              : 'Scan Barcode & Simpan',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: _isSaving
                          ? null
                          : () => _simpanBarang(tutupForm: true),
                      child: const Text('Simpan tanpa barcode'),
                    ),
                  ] else
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isSaving
                            ? null
                            : () => _simpanBarang(tutupForm: true),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Simpan Barang',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                ],
              ),
            ),

          // ── Daftar Barang ──────────────────────────────────────
          if (filtered.isEmpty && !_showForm)
            const Padding(
              padding: EdgeInsets.only(top: 60),
              child: AppEmptyState(
                icon: Icons.inventory_2_outlined,
                title: 'Tidak Ada Produk',
                message: 'pencet tambah produk\nuntuk menambah produk',
              ),
            ),
          ...filtered.map((item) => _ItemCard(
                item:         item,
                editId:       _editId,
                editStockCtrl: _editStockCtrl,
                editPriceCtrl: _editPriceCtrl,
                onStartEdit: () {
                  setState(() {
                    _editId = item.id;
                    _editStockCtrl.text =
                        item.stock.toString();
                    _editPriceCtrl.text =
                        item.price.toInt().toString();
                    _editBarcodeCtrl.text = item.barcode;
                  });
                },
                onSaveEdit: () async {
                  final newStock = double.tryParse(
                          _editStockCtrl.text) ??
                      item.stock;
                  final newPrice = double.tryParse(
                          _editPriceCtrl.text) ??
                      item.price;
                  await p.ubahStok(item.id, newStock);
                  await p.ubahHarga(item.id, newPrice);
                  await p.ubahBarcode(item.id, _editBarcodeCtrl.text);
                  if (!context.mounted) return;
                  setState(() => _editId = null);
                },
                onAddStock: () => _showTambahStokDialog(item),
                editBarcodeCtrl: _editBarcodeCtrl,
                onScanBarcode: () => _scanBarcodeUntuk(_editBarcodeCtrl),
                onCancelEdit: () =>
                    setState(() => _editId = null),
                onDelete: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Hapus Barang'),
                      content: Text(
                          'Hapus "${item.name}" dari daftar?'),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(context, false),
                          child: const Text('Batal'),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.red),
                          child: const Text('Hapus'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) await p.hapusItem(item.id);
                },
              )),
        ],
      ),
    );
  }

  Future<void> _showTambahStokDialog(ItemModel item) async {
    final ctrl = TextEditingController();
    final jumlah = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Tambah stok ${item.name}'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: InputDecoration(
            labelText: 'Jumlah (${item.unit})',
            hintText: 'Contoh: ${item.type == 'timbang' ? '0.5' : '10'}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              ctx,
              double.tryParse(ctrl.text.trim()),
            ),
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (jumlah == null || jumlah <= 0 || !mounted) return;

    try {
      await context.read<KasirProvider>().tambahStok(item.id, jumlah);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${context.read<KasirProvider>().formatQty(jumlah)} ${item.unit} ditambahkan ke ${item.name}'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Gagal menambah stok: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _scanBarcodeUntuk(TextEditingController controller) async {
    final barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (!mounted || barcode == null) return;
    setState(() => controller.text = barcode);
  }

  Widget _typeChip(String value, String label) {
    final active = _newType == value;
    return GestureDetector(
      onTap: () => setState(() {
        _newType = value;
        _newUnit = value == 'satuan' ? 'pcs' : 'gram';
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? Colors.red : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize:   12,
            fontWeight: FontWeight.w500,
            color: active ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  // ── Simpan barang dari form ────────────────────────────────────
  /// Mengembalikan true kalau barang berhasil disimpan.
  /// [tutupForm] = tutup form setelah simpan (dipakai mode manual);
  /// kalau false, form dibiarkan terbuka & field dibersihkan supaya
  /// siap untuk barang berikutnya (dipakai mode scan cepat).
  Future<bool> _simpanBarang({required bool tutupForm}) async {
    final p     = context.read<KasirProvider>();
    final name  = _nameCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    final stock = double.tryParse(_stockCtrl.text) ?? 0;

    if (name.isEmpty || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Isi nama dan harga dulu!'),
        backgroundColor: Colors.red,
      ));
      return false;
    }

    setState(() => _isSaving = true);

    try {
      await p.addItem(
        name:  name,
        price: price,
        stock: stock,
        type:  _newType,
        unit:  _newType == 'satuan' ? 'pcs' : _newUnit,
        // Barang timbang tidak pakai barcode.
        barcode: _newType == 'satuan' ? _barcodeCtrl.text : '',
      );
      if (!mounted) return false;

      _nameCtrl.clear();
      _priceCtrl.clear();
      _stockCtrl.clear();
      _barcodeCtrl.clear();
      setState(() {
        _isSaving = false;
        if (tutupForm) _showForm = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$name berhasil ditambahkan'),
        backgroundColor: Colors.green,
        duration: const Duration(milliseconds: 900),
      ));
      return true;
    } catch (e) {
      if (!mounted) return false;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Gagal menambahkan barang: $e'),
        backgroundColor: Colors.red,
      ));
      return false;
    }
  }

  // ── Mode scan cepat (barang satuan) ────────────────────────────
  /// Pastikan nama & harga terisi lebih dulu, buka kamera, dan begitu
  /// dapat barcode langsung simpan. Form tetap terbuka dengan fokus di
  /// kolom Nama supaya bisa lanjut: tit — nambah, tit — nambah.
  Future<void> _tambahCepatScan() async {
    final name  = _nameCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    if (name.isEmpty || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Tulis nama & harga dulu, baru scan barcode.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (!mounted || barcode == null || barcode.isEmpty) return;

    _barcodeCtrl.text = barcode;
    final ok = await _simpanBarang(tutupForm: false);
    if (ok && mounted) {
      HapticFeedback.mediumImpact();
      SystemSound.play(SystemSoundType.click);
      _nameFocus.requestFocus();
    }
  }

  Widget _formField({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required TextInputType inputType,
    TextInputFormatter? formatter,
    FocusNode? focusNode,
  }) {
    return TextField(
      controller: ctrl,
      focusNode: focusNode,
      keyboardType: inputType,
      inputFormatters:
          formatter != null ? [formatter] : null,
      decoration: InputDecoration(
        labelText: label,
        hintText:  hint,
        filled:    true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
      ),
    );
  }
}

// ── Card tiap barang ─────────────────────────────────────────────
class _ItemCard extends StatelessWidget {
  final ItemModel              item;
  final int?                   editId;
  final TextEditingController  editStockCtrl;
  final TextEditingController  editPriceCtrl;
  final TextEditingController editBarcodeCtrl;
  final VoidCallback           onStartEdit;
  final VoidCallback           onAddStock;
  final VoidCallback onScanBarcode;
  final VoidCallback           onSaveEdit;
  final VoidCallback           onCancelEdit;
  final VoidCallback           onDelete;

  const _ItemCard({
    required this.item,
    required this.editId,
    required this.editStockCtrl,
    required this.editPriceCtrl,
    required this.editBarcodeCtrl,
    required this.onStartEdit,
    required this.onAddStock,
    required this.onScanBarcode,
    required this.onSaveEdit,
    required this.onCancelEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final p       = context.read<KasirProvider>();
    final editing = editId == item.id;
    final status  = p.getStatus(item);
    final color   = p.getStatusColor(item);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Nama & jenis
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: item.type == 'timbang'
                                ? Colors.orange.shade50
                                : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.type == 'timbang'
                                ? '⚖️ ${item.unit}'
                                : '📦 pcs',
                            style: TextStyle(
                              fontSize: 10,
                              color: item.type == 'timbang'
                                  ? Colors.orange.shade700
                                  : Colors.blue.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: .1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize:   10,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Aksi
              if (!editing) ...[
                IconButton(
                  onPressed: onAddStock,
                  icon: const Icon(Icons.add_box_outlined, size: 19),
                  tooltip: 'Tambah stok',
                  color: Colors.red,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(32, 32),
                  ),
                ),
                IconButton(
                  onPressed: onStartEdit,
                  icon: const Icon(
                      Icons.edit_outlined, size: 18),
                  tooltip: 'Edit',
                  style: IconButton.styleFrom(
                    minimumSize: const Size(32, 32),
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(
                      Icons.delete_outline, size: 18),
                  tooltip: 'Hapus',
                  style: IconButton.styleFrom(
                    foregroundColor: Colors.red,
                    minimumSize: const Size(32, 32),
                  ),
                ),
              ] else ...[
                TextButton(
                  onPressed: onSaveEdit,
                  child: const Text('Simpan',
                      style: TextStyle(color: Colors.red)),
                ),
                TextButton(
                  onPressed: onCancelEdit,
                  child: const Text('Batal',
                      style:
                          TextStyle(color: Colors.grey)),
                ),
              ],
            ],
          ),

          // ── Info stok & harga / Edit form ──────────────────
          const SizedBox(height: 8),
          if (!editing)
            Row(
              children: [
                _infoBox(
                  'Stok',
                  p.formatStock(item),
                  Colors.blue,
                ),
                const SizedBox(width: 8),
                _infoBox(
                  'Harga',
                  '${p.formatHarga(item.price)}/${item.unit}',
                  Colors.green,
                ),
                const SizedBox(width: 8),
                _infoBox(
                  'Terjual',
                  '${item.sold.toInt()} ${item.unit}',
                  Colors.purple,
                ),
              ],
            )
          else
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: editStockCtrl,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Stok (${item.unit})',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: editPriceCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          labelText: 'Harga (Rp)',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: editBarcodeCtrl,
                  decoration: InputDecoration(
                    labelText: 'Barcode',
                    hintText: 'Kosongkan jika tidak memakai barcode',
                    suffixIcon: IconButton(
                      onPressed: onScanBarcode,
                      tooltip: 'Scan barcode',
                      icon: const BarcodeIcon(size: 22),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _infoBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color.withValues(alpha: .7),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize:   12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines:  1,
              overflow:  TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Summary Card ─────────────────────────────────────────────────
class _SumCard extends StatelessWidget {
  final String  label;
  final String  value;
  final Color   color;
  final IconData icon;

  const _SumCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: color.withValues(alpha: .2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize:   22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color.withValues(alpha: .7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
