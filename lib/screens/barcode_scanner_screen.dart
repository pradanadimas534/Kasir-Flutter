import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../models/item_model.dart';
import '../providers/kasir_provider.dart';
import '../theme/app_theme.dart';

enum ScanMode {
  /// Pop sekali dengan nilai barcode (dipakai untuk mengisi field).
  field,

  /// Kamera tetap terbuka, tiap scan menambah barang ke keranjang kasir.
  cart,

  /// Kamera tetap terbuka, kumpulkan barang, lalu tekan tombol untuk
  /// menambahkan semuanya ke stok sekaligus.
  stock,
}

class BarcodeScannerScreen extends StatefulWidget {
  final ScanMode mode;

  const BarcodeScannerScreen({super.key, this.mode = ScanMode.field});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.qrCode,
    ],
  );

  bool _hasScanned = false; // mode field: cegah pop ganda
  final Map<String, DateTime> _lastSeen = {}; // cooldown per kode

  // Mode stock: kumpulan barang yang akan direstok
  final Map<int, ItemModel> _stockItems = {};
  final Map<int, double> _stockQty = {};
  bool _committing = false;

  // Banner umpan balik scan terakhir
  String? _flashMsg;
  Color _flashColor = AppColors.success;
  Timer? _flashTimer;

  @override
  void dispose() {
    _flashTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _showFlash(String msg, Color color) {
    _flashTimer?.cancel();
    setState(() {
      _flashMsg = msg;
      _flashColor = color;
    });
    _flashTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _flashMsg = null);
    });
  }

  bool _cooldownHit(String value) {
    final now = DateTime.now();
    final last = _lastSeen[value];
    if (last != null && now.difference(last).inMilliseconds < 1600) return true;
    _lastSeen[value] = now;
    return false;
  }

  void _onDetect(BarcodeCapture capture) {
    final value = capture.barcodes.firstOrNull?.rawValue?.trim();
    if (value == null || value.isEmpty) return;

    switch (widget.mode) {
      case ScanMode.field:
        if (_hasScanned) return;
        _hasScanned = true;
        Navigator.pop(context, value);
        return;

      case ScanMode.cart:
        if (_cooldownHit(value)) return;
        _handleCart(value);
        return;

      case ScanMode.stock:
        if (_cooldownHit(value)) return;
        _handleStock(value);
        return;
    }
  }

  void _handleCart(String value) {
    final p = context.read<KasirProvider>();
    final item = p.cariBarangDariBarcode(value);
    if (item == null) {
      HapticFeedback.heavyImpact();
      _showFlash('Barcode $value belum terdaftar', AppColors.warning);
      return;
    }
    if (item.stock <= 0) {
      HapticFeedback.heavyImpact();
      _showFlash('${item.name} sedang habis', AppColors.red);
      return;
    }
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
    p.tambahKeCart(item, qty: 1);
    _showFlash(
      item.type == 'timbang'
          ? '${item.name} +1 ${item.unit} — atur di keranjang'
          : '${item.name} +1',
      AppColors.success,
    );
  }

  void _handleStock(String value) {
    final p = context.read<KasirProvider>();
    final item = p.cariBarangDariBarcode(value);
    if (item == null) {
      HapticFeedback.heavyImpact();
      _showFlash('Barcode $value belum terdaftar — daftarkan produk dulu',
          AppColors.warning);
      return;
    }
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
    setState(() {
      _stockItems[item.id] = item;
      _stockQty[item.id] = (_stockQty[item.id] ?? 0) + 1;
    });
    _showFlash('${item.name} +1  (total ${_fmtQty(_stockQty[item.id]!)})',
        AppColors.success);
  }

  String _fmtQty(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(2);

  void _stepStock(int id, double delta) {
    setState(() {
      final next = (_stockQty[id] ?? 0) + delta;
      if (next <= 0) {
        _stockQty.remove(id);
        _stockItems.remove(id);
      } else {
        _stockQty[id] = next;
      }
    });
  }

  Future<void> _commitStock() async {
    if (_stockQty.isEmpty || _committing) return;
    setState(() => _committing = true);
    final p = context.read<KasirProvider>();
    try {
      for (final entry in _stockQty.entries) {
        await p.tambahStok(entry.key, entry.value);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _committing = false);
      _showFlash('Gagal menyimpan stok: $e', AppColors.red);
    }
  }

  String get _title => switch (widget.mode) {
        ScanMode.cart => 'Scan ke keranjang',
        ScanMode.stock => 'Scan restok stok',
        ScanMode.field => 'Scan barcode barang',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(_title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Nyalakan lampu',
            onPressed: _controller.toggleTorch,
            icon: const Icon(Icons.flash_on_outlined),
          ),
          IconButton(
            tooltip: 'Ganti kamera',
            onPressed: _controller.switchCamera,
            icon: const Icon(Icons.cameraswitch_outlined),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),

          // Bingkai pemindai
          Center(
            child: Container(
              width: 280,
              height: 180,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // Banner umpan balik scan
          Positioned(
            left: 20,
            right: 20,
            top: 16,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 200),
              offset: _flashMsg == null ? const Offset(0, -1.5) : Offset.zero,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _flashMsg == null ? 0 : 1,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _flashColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _flashMsg ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (widget.mode == ScanMode.field)
            const Positioned(
              left: 24,
              right: 24,
              bottom: 48,
              child: Text(
                'Arahkan kamera ke barcode pada kemasan barang',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),

          if (widget.mode == ScanMode.cart)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _CartBar(onDone: () => Navigator.pop(context)),
            ),

          if (widget.mode == ScanMode.stock)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _StockIntakeBar(
                lines: _stockQty.entries
                    .map((e) => (item: _stockItems[e.key]!, qty: e.value))
                    .toList(),
                committing: _committing,
                onStep: _stepStock,
                onCommit: _commitStock,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Bar keranjang (mode cart) ──────────────────────────────────────
class _CartBar extends StatefulWidget {
  final VoidCallback onDone;
  const _CartBar({required this.onDone});

  @override
  State<_CartBar> createState() => _CartBarState();
}

class _CartBarState extends State<_CartBar> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<KasirProvider>();
    final cart = p.cart;
    final jumlah = cart.fold<double>(0, (s, c) => s + c.qty);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 16)],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_expanded && cart.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                  itemCount: cart.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 14),
                  itemBuilder: (_, i) {
                    final c = cart[i];
                    return Row(
                      children: [
                        Expanded(
                          child: Text(
                            c.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                        Text('${p.formatQty(c.qty)} ${c.unit}',
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 12)),
                        const SizedBox(width: 10),
                        Text(p.formatHarga(c.total),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () => p.hapusCartItem(c.id),
                          icon: Icon(Icons.remove_circle_outline,
                              color: Colors.red.shade300, size: 20),
                        ),
                      ],
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: cart.isEmpty
                        ? null
                        : () => setState(() => _expanded = !_expanded),
                    child: Row(
                      children: [
                        const Icon(Icons.shopping_cart_rounded,
                            color: AppColors.red, size: 22),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${p.formatQty(jumlah)} barang',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12)),
                            Text(
                              p.formatHarga(p.total),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.red,
                              ),
                            ),
                          ],
                        ),
                        if (cart.isNotEmpty)
                          Icon(
                            _expanded
                                ? Icons.keyboard_arrow_down_rounded
                                : Icons.keyboard_arrow_up_rounded,
                            color: AppColors.textMuted,
                          ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: widget.onDone,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.red,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Selesai',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bar restok (mode stock) ────────────────────────────────────────
typedef _StockLine = ({ItemModel item, double qty});

class _StockIntakeBar extends StatelessWidget {
  final List<_StockLine> lines;
  final bool committing;
  final void Function(int id, double delta) onStep;
  final VoidCallback onCommit;

  const _StockIntakeBar({
    required this.lines,
    required this.committing,
    required this.onStep,
    required this.onCommit,
  });

  @override
  Widget build(BuildContext context) {
    final total = lines.fold<double>(0, (s, l) => s + l.qty);
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 16)],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_rounded,
                      color: AppColors.red, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    lines.isEmpty
                        ? 'Belum ada barang discan'
                        : '${lines.length} produk · ${total % 1 == 0 ? total.toInt() : total} pcs akan ditambahkan',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (lines.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 230),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
                  itemCount: lines.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 12),
                  itemBuilder: (_, i) {
                    final l = lines[i];
                    return Row(
                      children: [
                        Expanded(
                          child: Text(
                            l.item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                        _StepBtn(
                            icon: Icons.remove,
                            onTap: () => onStep(l.item.id, -1)),
                        SizedBox(
                          width: 34,
                          child: Text(
                            l.qty % 1 == 0
                                ? l.qty.toInt().toString()
                                : l.qty.toStringAsFixed(2),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        _StepBtn(
                            icon: Icons.add,
                            onTap: () => onStep(l.item.id, 1)),
                      ],
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed:
                      lines.isEmpty || committing ? null : onCommit,
                  icon: committing
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.add_box_rounded),
                  label: Text(committing ? 'Menyimpan...' : 'Tambahkan ke Stok',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: AppColors.ink),
      ),
    );
  }
}
