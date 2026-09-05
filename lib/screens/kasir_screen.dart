import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/item_model.dart';
import '../providers/kasir_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_ui.dart';

class KasirScreen extends StatefulWidget {
  const KasirScreen({super.key});

  @override
  State<KasirScreen> createState() => _KasirScreenState();
}

class _KasirScreenState extends State<KasirScreen> {
  final _bayarCtrl  = TextEditingController();
  final _searchCtrl = TextEditingController();
  String _filter    = 'all';

  // ── Bottom sheet controller ──────────────────────────────────────
  final _sheetCtrl = DraggableScrollableController();
  bool  _cartOpen  = false;

  @override
  void dispose() {
    _bayarCtrl.dispose();
    _searchCtrl.dispose();
    _sheetCtrl.dispose();
    super.dispose();
  }

  void _toggleCart() {
    if (_cartOpen) {
      _sheetCtrl.animateTo(
        0.13,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _sheetCtrl.animateTo(
        0.75,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
    setState(() => _cartOpen = !_cartOpen);
  }


  @override
  Widget build(BuildContext context) {
    final p = context.watch<KasirProvider>();

    final filtered = p.items.where((item) {
      final matchSearch = _searchCtrl.text.isEmpty ||
          item.name.toLowerCase().contains(
              _searchCtrl.text.toLowerCase());
      final matchFilter =
          _filter == 'all' || item.type == _filter;
      return matchSearch && matchFilter;
    }).toList();

    final double bayar     = double.tryParse(_bayarCtrl.text) ?? 0;
    final double kembalian = bayar - p.total;
    final int    cartCount = p.cart.length;
    // Ruang untuk keranjang collapsed (~13% body) + margin
    final double cartPeek  = (MediaQuery.sizeOf(context).height * 0.13)
        .clamp(90.0, 130.0);

    return Stack(
      children: [
        // ── Daftar Barang ────────────────────────────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(12, 12, 12, cartPeek + 12),
          child: Column(
            children: [
              // Header: menu + search
              Row(
                children: [
                  IconButton(
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    icon: const Icon(Icons.menu_rounded,
                        color: AppColors.red, size: 28),
                  ),
                  Expanded(
                    child: SearchPill(
                      controller: _searchCtrl,
                      hint: 'Cari barang...',
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    PillChip(
                        label: 'All',
                        active: _filter == 'all',
                        onTap: () => setState(() => _filter = 'all')),
                    const SizedBox(width: 10),
                    PillChip(
                        label: 'Satuan',
                        active: _filter == 'satuan',
                        onTap: () => setState(() => _filter = 'satuan')),
                    const SizedBox(width: 10),
                    PillChip(
                        label: 'Timbangan',
                        active: _filter == 'timbang',
                        onTap: () => setState(() => _filter = 'timbang')),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Grid barang
              Expanded(
                child: filtered.isEmpty
                    ? const AppEmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: 'Tidak Ada Produk',
                        message:
                            'Tambahkan produk lewat menu Stok\nuntuk mulai berjualan',
                      )
                    : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:    2,
                          crossAxisSpacing:  10,
                          mainAxisSpacing:   10,
                          childAspectRatio:  1.5,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) =>
                            _ItemTile(item: filtered[i]),
                      ),
              ),
            ],
          ),
        ),

        // ── Bottom Sheet Keranjang ───────────────────────────────
        DraggableScrollableSheet(
          controller:      _sheetCtrl,
          initialChildSize: 0.13,
          minChildSize:    0.13,
          maxChildSize:    0.92,
          snap:            true,
          snapSizes:       const [0.13, 0.75, 0.92],
          builder: (_, scrollCtrl) => _CartSheet(
            scrollController: scrollCtrl,
            sheetController:  _sheetCtrl,
            bayarCtrl:        _bayarCtrl,
            bayar:            bayar,
            kembalian:        kembalian,
            cartCount:        cartCount,
            cartOpen:         _cartOpen,
            onToggle:         _toggleCart,
            onChanged:        () => setState(() {}),
            onBayar: () async {
              await p.prosesBayar(bayar);
              if (!context.mounted) return;
              _bayarCtrl.clear();
              _sheetCtrl.animateTo(
                0.08,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
              setState(() => _cartOpen = false);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Transaksi berhasil! Kembalian ${p.formatHarga(kembalian)}',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

}

// ── Tile barang ──────────────────────────────────────────────────
class _ItemTile extends StatelessWidget {
  final ItemModel item;
  const _ItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final p      = context.read<KasirProvider>();
    final habis  = item.stock <= 0;
    final timbang = item.type == 'timbang';

    return GestureDetector(
      onTap: habis
          ? null
          : () {
              if (timbang) {
                _showTimbangDialog(context, p);
              } else {
                p.tambahKeCart(item);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${item.name} ditambahkan'),
                    duration: const Duration(seconds: 1),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
      child: Container(
        decoration: BoxDecoration(
          color: habis ? Colors.grey.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border(
            top: timbang
                ? BorderSide(color: Colors.orange.shade300, width: 2)
                : BorderSide.none,
            left: BorderSide(color: Colors.grey.shade200),
            right: BorderSide(color: Colors.grey.shade200),
            bottom: BorderSide(color: Colors.grey.shade200),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge jenis
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: timbang
                    ? Colors.orange.shade50
                    : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                timbang ? '⚖️ ${item.unit}' : '📦 pcs',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: timbang
                      ? Colors.orange.shade700
                      : Colors.blue.shade700,
                ),
              ),
            ),
            const Spacer(),
            Text(
              item.name,
              style: TextStyle(
                fontSize:   13,
                fontWeight: FontWeight.bold,
                color: habis ? Colors.grey : Colors.black87,
              ),
              maxLines:  2,
              overflow:  TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              p.formatHarga(item.price),
              style: TextStyle(
                fontSize:   12,
                fontWeight: FontWeight.bold,
                color: habis
                    ? Colors.grey
                    : Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Stok: ${p.formatStock(item)}',
              style: TextStyle(
                fontSize: 10,
                color: habis
                    ? Colors.grey
                    : item.stock <= p.getThreshold(item)
                        ? Colors.orange
                        : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTimbangDialog(BuildContext context, KasirProvider p) {
    final ctrl = TextEditingController();
    double qty = 0;

    final presets = switch (item.unit) {
      'gram' => [100.0, 250.0, 500.0, 1000.0, 2000.0],
      'ons'  => [1.0, 2.0, 3.0, 5.0, 10.0],
      'kg'   => [0.5, 1.0, 2.0, 5.0, 10.0],
      _      => [100.0, 250.0, 500.0, 1000.0],
    };

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('⚖️ ${item.name}',
                  style: const TextStyle(fontSize: 16)),
              Text(
                '${p.formatHarga(item.price)}/${item.unit} · '
                'Stok: ${p.formatStock(item)}',
                style: const TextStyle(
                    fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      qty > 0
                          ? p.formatQty(qty)
                          : '0',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(item.unit,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12)),
                    if (qty > 0)
                      Text(
                        p.formatHarga(item.price * qty),
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Preset
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: presets
                    .map((pre) => GestureDetector(
                          onTap: () => setS(() {
                            qty  = pre;
                            ctrl.text = pre
                                .toString()
                                .replaceAll(
                                    RegExp(r'\.?0+$'), '');
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: qty == pre
                                  ? Colors.red.shade50
                                  : Colors.grey.shade100,
                              borderRadius:
                                  BorderRadius.circular(8),
                              border: Border.all(
                                color: qty == pre
                                    ? Colors.red
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              item.unit == 'gram' && pre >= 1000
                                  ? '${pre ~/ 1000}kg'
                                  : '$pre ${item.unit}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: qty == pre
                                    ? Colors.red.shade700
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),

              // Input manual
              TextField(
                controller: ctrl,
                keyboardType:
                    const TextInputType.numberWithOptions(
                        decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'[0-9.]')),
                ],
                onChanged: (v) =>
                    setS(() => qty = double.tryParse(v) ?? 0),
                decoration: InputDecoration(
                  labelText: item.unit,
                  hintText: 'Ketik jumlah...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: qty <= 0
                  ? null
                  : () {
                      p.tambahKeCart(item, qty: qty);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${item.name} ${p.formatQty(qty)} ${item.unit} ditambahkan',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
              child: const Text('Tambah'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom Sheet Keranjang ───────────────────────────────────────
class _CartSheet extends StatelessWidget {
  final ScrollController         scrollController;
  final DraggableScrollableController sheetController;
  final TextEditingController    bayarCtrl;
  final double  bayar;
  final double  kembalian;
  final int     cartCount;
  final bool    cartOpen;
  final VoidCallback onToggle;
  final VoidCallback onChanged;
  final VoidCallback onBayar;

  const _CartSheet({
    required this.scrollController,
    required this.sheetController,
    required this.bayarCtrl,
    required this.bayar,
    required this.kembalian,
    required this.cartCount,
    required this.cartOpen,
    required this.onToggle,
    required this.onChanged,
    required this.onBayar,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.watch<KasirProvider>();
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Handle & Header ──────────────────────────────────
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Column(
              children: [
                // Drag handle
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 4),
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_cart_rounded,
                          color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      const Text('Keranjang',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      const Spacer(),
                      if (cartCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.red.shade200),
                          ),
                          child: Text(
                            '$cartCount item',
                            style: TextStyle(
                              fontSize:   11,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Icon(
                        cartOpen
                            ? Icons.keyboard_arrow_down_rounded
                            : Icons.keyboard_arrow_up_rounded,
                        color: Colors.grey.shade500,
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: Colors.grey.shade100),
              ],
            ),
          ),

          // ── Konten scrollable ────────────────────────────────
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(14, 8, 14, 20 + keyboardInset),
              children: [
                // List item cart
                if (p.cart.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Icon(Icons.shopping_cart_outlined,
                            size: 44,
                            color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Text(
                          'Keranjang kosong',
                          style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 13),
                        ),
                      ],
                    ),
                  )
                else
                  ...p.cart.map((c) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.grey.shade100),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${p.formatQty(c.qty)} ${c.unit} × ${p.formatHarga(c.price)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              p.formatHarga(c.total),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => p.hapusCartItem(c.id),
                              child: Icon(
                                Icons.remove_circle_outline,
                                color: Colors.red.shade300,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      )),

                const SizedBox(height: 12),

                // ── Area bayar ───────────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withValues(alpha: .03),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Total
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                          Text(
                            p.formatHarga(p.total),
                            style: TextStyle(
                              fontSize:   20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Input bayar
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: bayarCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter
                                    .digitsOnly,
                              ],
                              onChanged: (_) => onChanged(),
                              decoration: InputDecoration(
                                hintText: 'Uang diterima...',
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                              bayarCtrl.text =
                                  p.total.toInt().toString();
                              onChanged();
                            },
                            child: const Text(
                              'Pas',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Kembalian
                      if (bayar > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: kembalian < 0
                                ? Colors.red.shade50
                                : Colors.green.shade50,
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Kembalian',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: kembalian < 0
                                      ? Colors.red
                                      : Colors.green.shade700,
                                ),
                              ),
                              Text(
                                p.formatHarga(
                                    kembalian < 0 ? 0 : kembalian),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: kembalian < 0
                                      ? Colors.red
                                      : Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),

                      // Tombol bayar
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: p.cart.isEmpty ||
                                  bayar < p.total
                              ? null
                              : onBayar,
                          icon: const Icon(Icons.payment),
                          label: const Text(
                            'Proses Pembayaran',
                            style: TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                            disabledBackgroundColor:
                                Colors.grey.shade200,
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
