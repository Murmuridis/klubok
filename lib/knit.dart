import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';

/// Лицевая гладь: столбики из петелек-«галочек», тон в тон с подложкой.
class KnitPainter extends CustomPainter {
  const KnitPainter({
    this.stitch = 14,
    this.shade = const Color(0x163C1E14),
    this.highlight = const Color(0x61FFFFFF),
  });

  final double stitch;
  final Color shade;
  final Color highlight;

  @override
  void paint(Canvas canvas, Size size) {
    final rowStep = stitch * 0.72;
    final leg = rowStep * 1.18;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (var pass = 0; pass < 2; pass++) {
      final ox = pass == 1 ? -0.7 : 0.0;
      final oy = pass == 1 ? -0.8 : 0.0;
      final path = Path();
      for (var y = -leg; y < size.height + rowStep; y += rowStep) {
        for (var x = -stitch / 2; x < size.width + stitch; x += stitch) {
          path
            ..moveTo(x + stitch * 0.14 + ox, y + oy)
            ..lineTo(x + stitch * 0.5 + ox, y + leg + oy)
            ..moveTo(x + stitch * 0.86 + ox, y + oy)
            ..lineTo(x + stitch * 0.5 + ox, y + leg + oy);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = pass == 1 ? stitch * 0.07 : stitch * 0.2
          ..color = pass == 1 ? highlight : shade,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(KnitPainter oldDelegate) =>
      oldDelegate.stitch != stitch ||
      oldDelegate.shade != shade ||
      oldDelegate.highlight != highlight;
}

/// Пунктирная «строчка ниткой» по краю заплатки.
class StitchBorderPainter extends CustomPainter {
  const StitchBorderPainter({
    required this.color,
    required this.radius,
    this.inset = 5,
  });

  final Color color;
  final double radius;
  final double inset;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(inset);
    if (rect.width <= 4 || rect.height <= 4) return;
    final r = math.min(math.max(2.0, radius), rect.shortestSide / 2);
    final outline = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(r)));
    const dash = 7.0;
    const gap = 5.0;
    final dashed = Path();
    for (final metric in outline.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        dashed.addPath(
          metric.extractPath(d, math.min(d + dash, metric.length)),
          Offset.zero,
        );
        d += dash + gap;
      }
    }
    canvas.drawPath(
      dashed,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.6
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(StitchBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.inset != inset;
}

/// Клубок пряжи с хвостиком нитки.
class YarnBallPainter extends CustomPainter {
  const YarnBallPainter({required this.color, this.tail = true});

  final Color color;
  final bool tail;

  static const _bundles = <List<double>>[
    [-0.55, -0.25, 0.9],
    [0.75, 0.2, 0.75],
    [0.12, 0.55, -0.8],
    [-1.25, -0.6, -0.5],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.min(size.width, size.height) / 2;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final c = Offset(cx, cy);
    final dark = Wool.darker(color);
    final light = Wool.lighter(color);

    if (tail) {
      final thread = Path()
        ..moveTo(cx + r * 0.55, cy + r * 0.8)
        ..cubicTo(cx + r * 1.05, cy + r * 1.25, cx + r * 1.35, cy + r * 0.75,
            cx + r * 1.15, cy + r * 1.15)
        ..cubicTo(cx + r * 1.0, cy + r * 1.45, cx + r * 1.5, cy + r * 1.4,
            cx + r * 1.6, cy + r * 1.2);
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(
          thread,
          p
            ..color = dark
            ..strokeWidth = r * 0.06);
      canvas.drawPath(
          thread,
          p
            ..color = color
            ..strokeWidth = r * 0.035);
    }

    // Тень под клубком.
    canvas.drawCircle(
      c.translate(0, r * 0.06),
      r * 0.98,
      Paint()
        ..color = const Color(0x4D4B3A33)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.12),
    );

    final ballRect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          radius: 0.78,
          colors: [light, color, dark],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(ballRect),
    );

    // Намотка: несколько пучков параллельных ниток под разными углами.
    canvas.save();
    canvas.clipPath(Path()..addOval(ballRect));
    final shadePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = r * 0.05
      ..color = const Color(0x33461923);
    final lightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = r * 0.016
      ..color = const Color(0x47FFFFFF);
    for (final b in _bundles) {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(b[0]);
      final shadePath = Path();
      final lightPath = Path();
      for (var j = -3; j <= 3; j++) {
        final o = (b[1] + j * 0.085) * r;
        final bulge = b[2] * r * 0.55;
        shadePath
          ..moveTo(-r * 1.1, o)
          ..quadraticBezierTo(0, o - bulge, r * 1.1, o);
        final o2 = o - r * 0.018;
        lightPath
          ..moveTo(-r * 1.1, o2)
          ..quadraticBezierTo(0, o2 - bulge, r * 1.1, o2);
      }
      canvas.drawPath(shadePath, shadePaint);
      canvas.drawPath(lightPath, lightPaint);
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(YarnBallPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.tail != tail;
}

/// Нитка-прогресс вокруг клубка.
class ThreadRingPainter extends CustomPainter {
  const ThreadRingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.min(size.width, size.height) / 2 - 4;
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: r);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = const Color(0x2E4B3A33);
    canvas.drawCircle(rect.center, r, track);
    if (progress <= 0) return;
    final p = progress.clamp(0.0, 1.0);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * p,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 5
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(ThreadRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

/// Пуговица.
class ButtonPainter extends CustomPainter {
  const ButtonPainter({required this.color, this.holes = false});

  final Color color;
  final bool holes;

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.min(size.width, size.height) / 2;
    final c = size.center(Offset.zero);
    final dark = Wool.darker(color, 0.12);
    canvas.drawCircle(
      c.translate(0, 3),
      r * 0.97,
      Paint()
        ..color = const Color(0x4D4B3A33)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(c, r, Paint()..color = color);
    canvas.drawCircle(
      c,
      r * 0.78,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.07
        ..color = dark,
    );
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r * 0.93),
      math.pi * 1.05,
      math.pi * 0.55,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = r * 0.05
        ..color = const Color(0x59FFFFFF),
    );
    if (holes) {
      final hole = Paint()..color = dark;
      for (final dx in const [-1.0, 1.0]) {
        for (final dy in const [-1.0, 1.0]) {
          canvas.drawCircle(
              c.translate(dx * r * 0.2, dy * r * 0.2), r * 0.09, hole);
        }
      }
    }
  }

  @override
  bool shouldRepaint(ButtonPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.holes != holes;
}

/// Резинка 1×1 — для нижней панели.
class RibPainter extends CustomPainter {
  const RibPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = color);
    const period = 16.0;
    const knitW = 9.0;
    const rowStep = knitW * 0.72;
    const leg = rowStep * 1.18;
    final purl = Paint()..color = const Color(0x1A3C1E14);
    final shade = Path();
    final light = Path();
    for (var x = 0.0; x < size.width; x += period) {
      canvas.drawRect(
          Rect.fromLTWH(x + knitW, 0, period - knitW, size.height), purl);
      for (var y = -leg; y < size.height + rowStep; y += rowStep) {
        shade
          ..moveTo(x + knitW * 0.14, y)
          ..lineTo(x + knitW * 0.5, y + leg)
          ..moveTo(x + knitW * 0.86, y)
          ..lineTo(x + knitW * 0.5, y + leg);
        light
          ..moveTo(x + knitW * 0.14 - 0.6, y - 0.7)
          ..lineTo(x + knitW * 0.5 - 0.6, y + leg - 0.7)
          ..moveTo(x + knitW * 0.86 - 0.6, y - 0.7)
          ..lineTo(x + knitW * 0.5 - 0.6, y + leg - 0.7);
      }
    }
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawPath(
      shade,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = knitW * 0.2
        ..color = const Color(0x1C3C1E14),
    );
    canvas.drawPath(
      light,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = knitW * 0.07
        ..color = const Color(0x52FFFFFF),
    );
    canvas.restore();
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, 2),
      Paint()..color = const Color(0x1F3C1E14),
    );
  }

  @override
  bool shouldRepaint(RibPainter oldDelegate) => oldDelegate.color != color;
}

/// Вязаный фон на весь экран.
class KnitBackground extends StatelessWidget {
  const KnitBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Wool.cream,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const RepaintBoundary(
            child: CustomPaint(painter: KnitPainter()),
          ),
          child,
        ],
      ),
    );
  }
}

/// Экран с вязаным фоном.
class KnitScaffold extends StatelessWidget {
  const KnitScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.resizeToAvoidBottomInset = true,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  /// false — экран не сжимается, когда выезжает клавиатура.
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return KnitBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        appBar: appBar,
        body: body,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
      ),
    );
  }
}

/// Вязаная заплатка: карточка с фактурой и строчкой по краю.
class Patch extends StatelessWidget {
  const Patch({
    super.key,
    required this.child,
    this.color = Wool.white,
    this.radius = 18,
    this.stitch = 12,
    this.threadColor,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.onLongPress,
    this.elevated = true,
  });

  final Widget child;
  final Color color;
  final double radius;
  final double stitch;
  final Color? threadColor;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    final thread = threadColor ??
        (Wool.isLight(color)
            ? Wool.rose.withValues(alpha: 0.8)
            : Wool.white.withValues(alpha: 0.9));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: r,
        boxShadow: elevated
            ? const [
                BoxShadow(
                  color: Color(0x384B3A33),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: r,
        child: CustomPaint(
          painter: KnitPainter(stitch: stitch),
          foregroundPainter:
              StitchBorderPainter(color: thread, radius: radius - 5),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              onLongPress: onLongPress,
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// Лёгкое «вдавливание» при нажатии.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.pressedScale = 0.94,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _down ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 90),
        child: widget.child,
      ),
    );
  }
}

/// Круглая кнопка-пуговица.
class WoolButton extends StatelessWidget {
  const WoolButton({
    super.key,
    required this.color,
    required this.onTap,
    required this.label,
    this.size = 64,
    this.child,
  });

  final Color color;
  final VoidCallback? onTap;

  /// Подпись для экранного диктора.
  final String label;
  final double size;

  /// Что нарисовано на пуговице; если пусто — четыре дырочки.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Pressable(
        onTap: onTap,
        child: CustomPaint(
          painter: ButtonPainter(color: color, holes: child == null),
          child: SizedBox.square(
            dimension: size,
            child: Center(
              child: IconTheme.merge(
                data: IconThemeData(color: Wool.white, size: size * 0.42),
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                    color: Wool.white,
                    fontWeight: FontWeight.w700,
                    fontSize: size * 0.34,
                  ),
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Вязаная «таблетка»: выбор статуса, фильтр, счётчик.
class WoolChip extends StatelessWidget {
  const WoolChip({
    super.key,
    required this.label,
    this.selected = false,
    this.color = Wool.rose,
    this.onTap,
    this.onLongPress,
    this.icon,
    this.dense = false,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Wool.white : Wool.brown;
    return Patch(
      color: selected ? color : Wool.white,
      threadColor: selected ? null : color.withValues(alpha: 0.85),
      radius: 22,
      stitch: 9,
      elevated: !dense,
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 12 : 16,
        vertical: dense ? 7 : 10,
      ),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: fg),
            if (label.isNotEmpty) const SizedBox(width: 6),
          ],
          if (label.isNotEmpty)
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w700,
                fontSize: dense ? 12.5 : 14,
              ),
            ),
        ],
      ),
    );
  }
}

/// Широкая кнопка-заплатка.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.color = Wool.rose,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fg = Wool.isLight(color) ? Wool.berry : Wool.white;
    return Patch(
      color: color,
      radius: 26,
      stitch: 10,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: fg),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Маленький клубок как значок.
class YarnDot extends StatelessWidget {
  const YarnDot({super.key, required this.color, this.size = 56});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Padding(
        padding: EdgeInsets.all(size * 0.06),
        child: CustomPaint(painter: YarnBallPainter(color: color, tail: false)),
      ),
    );
  }
}

/// Пустое состояние: клубок, пара слов и кнопка.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.text,
    this.actionLabel,
    this.onAction,
    this.color = Wool.rose,
  });

  final String title;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 150,
              height: 130,
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox.square(
                  dimension: 100,
                  child: CustomPaint(painter: YarnBallPainter(color: color)),
                ),
              ),
            ),
            Text(title, style: Wool.heading, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(text, style: Wool.body, textAlign: TextAlign.center),
            if (actionLabel != null) ...[
              const SizedBox(height: 22),
              PillButton(
                label: actionLabel!,
                icon: Icons.add,
                onTap: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
