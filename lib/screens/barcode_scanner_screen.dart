import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../providers/kasir_provider.dart';
import '../theme/app_theme.dart';

class BarcodeScannerScreen extends StatefulWidget {
  /// Bila true: kamera tetap terbuka, tiap scan menambah barang ke keranjang,
  /// dan ringkasan keranjang ditampilkan di bawah layar kamera.
  /// Bila false: pop sekali dengan nilai barcode (dipakai untuk isi field).
  final bool cartMode;

  const BarcodeScannerScreen({super.key, this.cartMode = false});

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

  bool _hasScanned = false; // mode non-cart: cegah pop ganda
  final Map<String, DateTime> _lastSeen = {}; // mode cart: cooldown per kode

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

  void _onDetect(BarcodeCapture capture) {
    final value = capture.barcodes.firstOrNull?.rawValue?.trim();
    if (value == null || value.isEmpty) return;

    if (!widget.cartMode) {
      if (_hasScanned) return;
      _hasScanned = true;
      Navigator.pop(context, value);
      return;
    }

    // ── Mode keranjang ──────────────────────────────────────────────
    final now = DateTime.now();
    final last = _lastSeen[value];
    if (last != null && now.difference(last).inMilliseconds < 1600) return;
    _lastSeen[value] = now;

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
    if (item.type == 'timbang') {
      HapticFeedback.mediumImpact();
      p.tambahKeCart(item, qty: 1);
      _showFlash('${item.name} +1 ${item.unit} — atur di keranjang',
          AppColors.success);
    } else {
      HapticFeedback.mediumImpact();
      SystemSound.play(SystemSoundType.click);
      p.tambahKeCart(item);
      _showFlash('${item.name} +1', AppColors.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.cartMode ? 'Scan ke keranjang' : 'Scan barcode barang'),
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

          if (!widget.cartMode)
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

          // Ringkasan keranjang (mode cart)
          if (widget.cartMode)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _CartBar(onDone: () => Navigator.pop(context)),
            ),
        ],
      ),
    );
  }
}

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
        boxShadow: [
          BoxShadow(color: Colors.black45, blurRadius: 16),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Daftar item (bisa dibuka/tutup)
            if (_expanded && cart.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                  itemCount: cart.length,
                  separatorBuilder: (context, index) => const Divider(height: 14),
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

            // Baris ringkasan + tombol Selesai
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
                            Text(
                              '${p.formatQty(jumlah)} barang',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 12),
                            ),
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
