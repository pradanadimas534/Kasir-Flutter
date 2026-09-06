import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Lingkaran + centang yang menggambar sendiri sekali saat muncul.
/// Dipakai di layar "Pembayaran Berhasil".
class SuccessCheck extends StatefulWidget {
  final double size;
  final Color color;

  const SuccessCheck({
    super.key,
    this.size = 104,
    this.color = const Color(0xFF34A853),
  });

  @override
  State<SuccessCheck> createState() => _SuccessCheckState();
}

class _SuccessCheckState extends State<SuccessCheck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value;
        // Pop lembut di akhir animasi.
        final pop = t < 0.85
            ? 1.0
            : 1.0 + math.sin((t - 0.85) / 0.15 * math.pi) * 0.06;
        return Transform.scale(
          scale: pop,
          child: CustomPaint(
            size: Size.square(widget.size),
            painter: _CheckPainter(t, widget.color),
          ),
        );
      },
    );
  }
}

class _CheckPainter extends CustomPainter {
  final double t;
  final Color color;
  _CheckPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final center = Offset(w / 2, w / 2);
    final r = w / 2 - w * 0.06;

    // Latar lingkaran lembut.
    canvas.drawCircle(center, r, Paint()..color = color.withValues(alpha: .12));

    // Lingkaran garis (menggambar dari atas).
    final circT = (t / 0.55).clamp(0.0, 1.0);
    final ring = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.075
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      -math.pi / 2,
      2 * math.pi * Curves.easeOutCubic.transform(circT),
      false,
      ring,
    );

    // Centang (mulai setelah lingkaran hampir penuh).
    final chkT =
        Curves.easeOut.transform(((t - 0.45) / 0.55).clamp(0.0, 1.0));
    if (chkT <= 0) return;

    final p1 = Offset(w * 0.30, w * 0.52);
    final p2 = Offset(w * 0.44, w * 0.66);
    final p3 = Offset(w * 0.72, w * 0.36);
    final lenA = (p2 - p1).distance;
    final lenB = (p3 - p2).distance;
    final draw = (lenA + lenB) * chkT;

    final path = Path()..moveTo(p1.dx, p1.dy);
    if (draw <= lenA) {
      final e = Offset.lerp(p1, p2, draw / lenA)!;
      path.lineTo(e.dx, e.dy);
    } else {
      path.lineTo(p2.dx, p2.dy);
      final e = Offset.lerp(p2, p3, ((draw - lenA) / lenB).clamp(0.0, 1.0))!;
      path.lineTo(e.dx, e.dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.09
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.t != t || old.color != color;
}
