import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/tr.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';

class Seg {
  const Seg(this.from, this.to, this.color);
  final double from, to; // percent 0..100
  final Color color;
}

/// Ring / donut drawn with arcs starting at 12 o'clock.
class DonutPainter extends CustomPainter {
  DonutPainter({required this.segments, required this.stroke, this.track = AppTokens.track, this.gapDeg = 0});
  final List<Seg> segments;
  final double stroke;
  final Color track;
  final double gapDeg;

  @override
  void paint(Canvas canvas, Size size) {
    final r = (math.min(size.width, size.height) - stroke) / 2;
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: r);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawCircle(rect.center, r, p);
    for (final s in segments) {
      final start = -math.pi / 2 + s.from / 100 * 2 * math.pi + gapDeg * math.pi / 180;
      final sweep = (s.to - s.from) / 100 * 2 * math.pi - 2 * gapDeg * math.pi / 180;
      if (sweep <= 0) continue;
      canvas.drawArc(rect, start, sweep, false, p..color = s.color);
    }
  }

  @override
  bool shouldRepaint(covariant DonutPainter old) => true;
}

class Donut extends StatelessWidget {
  const Donut({super.key, required this.size, required this.stroke, required this.segments, required this.center});
  final double size, stroke;
  final List<Seg> segments;
  final Widget center;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: DonutPainter(segments: segments, stroke: stroke),
          child: Center(child: center),
        ),
      );
}

// ---------------------------------------------------------------------------
// Duty Manager response performance line chart (800x180 viewBox)
// ---------------------------------------------------------------------------

/// Path "M0 106C60 100 82 70 139 83s85 43 139 25 ..." expanded to absolute cubics.
const _curve = <List<double>>[
  [60, 100, 82, 70, 139, 83],
  [196, 96, 224, 126, 278, 108],
  [332, 90, 352, 58, 410, 77],
  [468, 96, 490, 136, 550, 117],
  [610, 98, 621, 62, 679, 86],
  [737, 110, 748, 117, 800, 98],
  [852, 79, 865, 63, 900, 69],
];

class PerformancePainter extends CustomPainter {
  PerformancePainter({required this.hover});
  final bool hover;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 800, sy = size.height / 180;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.scale(sx, sy);
    final grid = Paint()
      ..color = kTokens.lineSoft
      ..strokeWidth = 1 / sy;
    for (final y in [45.0, 90.0, 135.0]) {
      canvas.drawLine(Offset(0, y), Offset(800, y), grid);
    }
    final path = Path()..moveTo(0, 106);
    for (final c in _curve) {
      path.cubicTo(c[0], c[1], c[2], c[3], c[4], c[5]);
    }
    final area = Path.from(path)
      ..lineTo(900, 180)
      ..lineTo(0, 180)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [kTokens.yellow.withOpacity(0.18), kTokens.yellow.withOpacity(0)],
        ).createShader(const Rect.fromLTWH(0, 60, 800, 120)),
    );
    // target line (dashed)
    final target = Paint()
      ..color = kTokens.muted2
      ..strokeWidth = 1 / sy;
    for (double x = 0; x < 800; x += 8) {
      canvas.drawLine(Offset(x, 91), Offset(x + 4, 91), target);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = kTokens.yellow
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 / sy,
    );
    if (hover) {
      canvas.drawLine(const Offset(520, 0), const Offset(520, 180), Paint()..color = kTokens.muted2..strokeWidth = 1 / sx);
    }
    canvas.restore();
    if (hover) {
      final c = Offset(520 * sx, 110 * sy);
      canvas.drawCircle(c, 5, Paint()..color = kTokens.canvas);
      canvas.drawCircle(c, 5, Paint()..color = kTokens.yellow..style = PaintingStyle.stroke..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(covariant PerformancePainter old) => old.hover != hover;
}

class PerformanceChart extends StatefulWidget {
  const PerformanceChart({super.key});
  @override
  State<PerformanceChart> createState() => _PerformanceChartState();
}

class _PerformanceChartState extends State<PerformanceChart> {
  String range = 'Today';
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    final avg = {'Today': '01:48', '7 days': '01:53', '30 days': '01:57'}[range]!;
    final pct = {'Today': '12%', '7 days': '7%', '30 days': '3%'}[range]!;
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionHead(
          eyebrow: 'TODAY · 08:00—NOW',
          title: 'Response Performance',
          trailing: AppDropdown(
            height: 40,
            value: range,
            options: const ['Today', '7 days', '30 days'],
            onChanged: (v) => setState(() => range = v),
          ),
        ),
        const SizedBox(height: 16),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(avg, style: ts(28, weight: FontWeight.w500)),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: T('Average response', style: ts(10, color: t.muted)),
          ),
          const Spacer(),
          Text('$pct ${context.tr('faster than target')}', style: ts(10, color: t.green, weight: FontWeight.w600)),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(
              width: 40,
              child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                for (final l in ['03:00', '02:00', '01:00']) Text(l, style: ts(8, color: t.muted2)),
              ]),
            ),
            Expanded(
              child: LayoutBuilder(builder: (context, c) {
                return MouseRegion(
                  onEnter: (_) => setState(() => hover = true),
                  onExit: (_) => setState(() => hover = false),
                  child: GestureDetector(
                    onTap: () => setState(() => hover = !hover),
                    child: Stack(clipBehavior: Clip.none, children: [
                      Positioned.fill(child: CustomPaint(painter: PerformancePainter(hover: hover))),
                      if (hover)
                        Positioned(
                          left: (520 / 800 * c.maxWidth - 70).clamp(0.0, c.maxWidth - 140),
                          top: 0,
                          child: Container(
                            width: 140,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: t.surface3,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: t.line),
                            ),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('10:24 AM', style: ts(9, color: t.muted2)),
                              const SizedBox(height: 4),
                              Text('${context.tr('Response')} 01:42', style: ts(11, weight: FontWeight.w600)),
                              Text('${context.tr('Target')} 02:00', style: ts(9, color: t.muted)),
                              Text(context.tr('18 sec faster'), style: ts(9, color: t.green)),
                            ]),
                          ),
                        ),
                    ]),
                  ),
                );
              }),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 40),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            for (final l in ['08:00', '09:00', '10:00', '11:00', '12:00']) Text(l, style: ts(8, color: t.muted2)),
          ]),
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Supervisor shift flow (800x200 viewBox)
// ---------------------------------------------------------------------------

const _hours = <(int, int)>[(3, 3), (3, 3), (5, 4), (2, 1)];
const _xs = <double>[0, 100, 200, 300, 340];

class _FlowData {
  _FlowData() {
    var c = 0, d = 0;
    created.add(0);
    completed.add(0);
    for (final h in _hours) {
      c += h.$1;
      d += h.$2;
      created.add(c);
      completed.add(d);
    }
  }
  final created = <int>[];
  final completed = <int>[];
  int get backlog => created.last - completed.last;
}

class ShiftFlowPainter extends CustomPainter {
  ShiftFlowPainter(this.data, this.hoverCol);
  final _FlowData data;
  final int? hoverCol;

  double y(int v) => 176 - v * 10.0;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 800, sy = size.height / 200;
    Offset p(double x, double yy) => Offset(x * sx, yy * sy);
    final grid = Paint()..color = kTokens.lineSoft;
    for (final gy in [56.0, 96.0, 136.0, 176.0]) {
      canvas.drawLine(p(0, gy), p(800, gy), grid);
    }
    if (hoverCol != null) {
      canvas.drawRect(Rect.fromLTWH(hoverCol! * 100 * sx, 0, 100 * sx, size.height),
          Paint()..color = Colors.white.withOpacity(0.03));
    }
    final gap = Path()..moveTo(_xs[0] * sx, y(data.created[0]) * sy);
    for (var i = 1; i < _xs.length; i++) {
      gap.lineTo(_xs[i] * sx, y(data.created[i]) * sy);
    }
    for (var i = _xs.length - 1; i >= 0; i--) {
      gap.lineTo(_xs[i] * sx, y(data.completed[i]) * sy);
    }
    gap.close();
    canvas.drawPath(gap, Paint()..color = kTokens.yellow.withOpacity(0.07));

    Path line(List<int> v) {
      final pa = Path()..moveTo(_xs[0] * sx, y(v[0]) * sy);
      for (var i = 1; i < _xs.length; i++) {
        pa.lineTo(_xs[i] * sx, y(v[i]) * sy);
      }
      return pa;
    }

    canvas.drawPath(
        line(data.created),
        Paint()
          ..color = kTokens.muted
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    canvas.drawPath(
        line(data.completed),
        Paint()
          ..color = kTokens.yellow
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    final dash = Paint()
      ..color = kTokens.line
      ..strokeWidth = 1;
    for (double x = _xs.last; x < 800; x += 10) {
      canvas.drawLine(p(x, 176), p(math.min(x + 5, 800), 176), dash);
    }
    canvas.drawLine(p(_xs.last, 8), p(_xs.last, 186), Paint()..color = kTokens.yellowSoft.withOpacity(0.6));
  }

  @override
  bool shouldRepaint(covariant ShiftFlowPainter old) => old.hoverCol != hoverCol;
}

class ShiftFlow extends StatefulWidget {
  const ShiftFlow({super.key});
  @override
  State<ShiftFlow> createState() => _ShiftFlowState();
}

class _ShiftFlowState extends State<ShiftFlow> {
  final data = _FlowData();
  int? hover;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    return Panel(
      height: 296,
      radius: 16,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionHead(
          eyebrow: 'SHIFT FLOW',
          title: 'Created vs completed',
          trailing: Wrap(spacing: 8, children: [
            _chip(context, '${context.tr('Backlog')} ${data.backlog}'),
            _chip(context, '${context.tr('Avg response')} 01:48 · ${context.tr('target')} 02:00'),
          ]),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: LayoutBuilder(builder: (context, c) {
            final w = c.maxWidth;
            int? colAt(double dx) {
              final x = dx / w * 800;
              final col = (x / 100).floor();
              return col >= 0 && col < _hours.length ? col : null;
            }

            return Directionality(
              textDirection: TextDirection.ltr,
              child: MouseRegion(
                onHover: (e) => setState(() => hover = colAt(e.localPosition.dx)),
                onExit: (_) => setState(() => hover = null),
                child: Stack(clipBehavior: Clip.none, children: [
                  Positioned.fill(child: CustomPaint(painter: ShiftFlowPainter(data, hover))),
                  Positioned(
                    left: _xs.last / 800 * w + 6,
                    top: 0,
                    child: Text('${context.tr('Now')} · 10:24', style: ts(9, color: t.yellowSoft)),
                  ),
                  Positioned(
                    left: _xs.last / 800 * w + 6,
                    top: (176 - data.created.last * 10) / 200 * c.maxHeight - 14,
                    child: T('Created', style: ts(9, color: t.muted)),
                  ),
                  Positioned(
                    left: _xs.last / 800 * w + 6,
                    top: (176 - data.completed.last * 10) / 200 * c.maxHeight + 2,
                    child: T('Completed', style: ts(9, color: t.yellow)),
                  ),
                  if (hover != null)
                    Positioned(
                      left: hover! * 100 / 800 * w + 8,
                      top: 24,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: t.surface3,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: t.line),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${(7 + hover!).toString().padLeft(2, '0')}:00–${(8 + hover!).toString().padLeft(2, '0')}:00',
                              style: ts(9, color: t.muted2)),
                          const SizedBox(height: 4),
                          Text(
                              '${context.tr('Created')} ${_hours[hover!].$1} · ${context.tr('Completed')} ${_hours[hover!].$2}',
                              style: ts(10, weight: FontWeight.w600)),
                          Text('${context.tr('Backlog')} +${_hours[hover!].$1 - _hours[hover!].$2}',
                              style: ts(9, color: t.yellow)),
                        ]),
                      ),
                    ),
                ]),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            for (var h = 7; h <= 15; h++) Text('${h.toString().padLeft(2, '0')}:00', style: ts(8, color: t.muted2)),
          ]),
        ),
      ]),
    );
  }

  Widget _chip(BuildContext context, String text) => Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: kTokens.surface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kTokens.line),
        ),
        child: Text(text, style: ts(9, color: kTokens.muted)),
      );
}
