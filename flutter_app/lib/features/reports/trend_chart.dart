import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/tr.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';

class _Metric {
  const _Metric(this.name, this.unit, this.target, this.lowerBetter, this.base,
      this.spread);
  final String name, unit;
  final double target;
  final bool lowerBetter;
  final double base, spread;
}

const _metrics = [
  _Metric('Response time', 'mm:ss', 120, true, 112, 22),
  _Metric('SLA compliance', '%', 95, false, 95.6, 3),
  _Metric('Inspection pass', '%', 90, false, 93, 5),
];

double _r1(double v) => (v * 10).round() / 10;

class ReportTrendChart extends StatefulWidget {
  const ReportTrendChart(
      {super.key,
      required this.period,
      required this.zone,
      required this.facilityType});
  final String period, zone, facilityType;
  @override
  State<ReportTrendChart> createState() => _ReportTrendChartState();
}

class _ReportTrendChartState extends State<ReportTrendChart> {
  int metricIndex = 0;
  int? active;

  _Metric get m => _metrics[metricIndex];

  int get days => widget.period == 'Last 7 days'
      ? 7
      : (widget.period == 'This quarter' ? 13 : 30);
  String get label => widget.period == 'This quarter' ? 'Week' : 'Day';

  List<double> get values {
    final seed = (widget.zone.length * 7 + widget.facilityType.length * 3) % 11;
    return [
      for (var i = 0; i < days; i++)
        _r1(m.base +
            (math.sin((i + seed) * 1.3) * .6 +
                    math.cos((i * .7 + seed) * .9) * .4) *
                m.spread),
    ];
  }

  String fmt(double v) {
    if (m.unit == '%') return '${v.toStringAsFixed(1)}%';
    final s = v.round();
    return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  bool met(double v) => m.lowerBetter ? v <= m.target : v >= m.target;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    final vals = values;
    final avg = vals.reduce((a, b) => a + b) / vals.length;
    final metCount = vals.where(met).length;
    final missed = vals.length - metCount;
    final lo = math.min(vals.reduce(math.min), m.target) - m.spread * .3;
    final hi = math.max(vals.reduce(math.max), m.target) + m.spread * .3;
    final lbl = context.tr(label);

    Widget kpi(String k, String v, {Color? color}) => SizedBox(
          width: 140,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(k,
                style: ts(MediaQuery.sizeOf(context).width < 768 ? 12 : 9,
                    color: t.muted2)),
            const SizedBox(height: 4),
            Text(v, style: ts(18, weight: FontWeight.w500, color: color)),
          ]),
        );

    final narrow = MediaQuery.sizeOf(context).width < 768;
    final chips = Wrap(spacing: 6, runSpacing: 6, children: [
      for (var i = 0; i < _metrics.length; i++)
        AppChip(
          label: _metrics[i].name,
          active: metricIndex == i,
          onTap: () => setState(() {
            metricIndex = i;
            active = null;
          }),
        ),
    ]);
    final axis = ts(narrow ? 12 : 8, color: t.muted2)
        .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    return Panel(
      padding: EdgeInsets.all(narrow ? 16 : 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (narrow) ...[
          Text(
              '${context.tr(widget.period).toUpperCase()} · ${context.tr(widget.zone)} · ${context.tr(widget.facilityType)}',
              style: ts(12, color: t.muted2, weight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('${context.tr(m.name)} ${context.tr('vs target')}',
              style: ts(18, weight: FontWeight.w500, height: 1.3)),
          const SizedBox(height: 12),
          chips,
        ] else
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        '${context.tr(widget.period).toUpperCase()} · ${context.tr(widget.zone)} · ${context.tr(widget.facilityType)}',
                        style: ts(9,
                            color: t.muted2,
                            weight: FontWeight.w700,
                            spacing: 1.2)),
                    const SizedBox(height: 6),
                    Text('${context.tr(m.name)} ${context.tr('vs target')}',
                        style: ts(18, weight: FontWeight.w500)),
                  ]),
            ),
            chips,
          ]),
        const SizedBox(height: 20),
        Wrap(spacing: 16, runSpacing: 16, children: [
          kpi(context.tr('Average'), fmt(_r1(avg))),
          kpi(context.tr('Target'),
              '${m.lowerBetter ? '≤ ' : '≥ '}${fmt(m.target)}'),
          kpi('${lbl}s ${context.tr('on target')}', '$metCount / $days'),
          kpi(context.tr('Missed'), '$missed',
              color: missed > 0 ? t.coral : null),
        ]),
        const SizedBox(height: 20),
        SizedBox(
          height: 200,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: LayoutBuilder(builder: (context, c) {
              final w = c.maxWidth;
              const h = 200.0, p = 8.0;
              double x(int i) => p + i / (days - 1) * (w - 2 * p);
              double y(double v) => h - p - (v - lo) / (hi - lo) * (h - 2 * p);
              int idxAt(double dx) => ((dx - p) / (w - 2 * p) * (days - 1))
                  .round()
                  .clamp(0, days - 1);
              return MouseRegion(
                onHover: (e) =>
                    setState(() => active = idxAt(e.localPosition.dx)),
                onExit: (_) => setState(() => active = null),
                child: GestureDetector(
                  onTapDown: (d) =>
                      setState(() => active = idxAt(d.localPosition.dx)),
                  child: Stack(clipBehavior: Clip.none, children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _TrendPainter(
                          points: [
                            for (var i = 0; i < days; i++)
                              Offset(x(i), y(vals[i]))
                          ],
                          missed: [for (final v in vals) !met(v)],
                          targetY: y(m.target),
                          lowerBetter: m.lowerBetter,
                          active: active,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: y(m.target) - 16,
                      child: Text('${context.tr('Target')} ${fmt(m.target)}',
                          style: ts(9, color: t.muted2)),
                    ),
                    if (active != null)
                      Positioned(
                        left: (x(active!) - 70).clamp(0.0, w - 140),
                        top: (y(vals[active!]) - 64).clamp(-40.0, h),
                        child: Container(
                          width: 140,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: t.surface3,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: t.line),
                          ),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('$lbl ${active! + 1}',
                                    style: ts(9, color: t.muted2)),
                                const SizedBox(height: 3),
                                Text(
                                    '${fmt(vals[active!])} · ${context.tr(met(vals[active!]) ? 'On target' : 'Missed target')}',
                                    style: ts(10,
                                        weight: FontWeight.w600,
                                        color: met(vals[active!])
                                            ? t.green
                                            : t.coral)),
                              ]),
                        ),
                      ),
                  ]),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 8),
        Directionality(
          textDirection: TextDirection.ltr,
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('$lbl 1', style: axis),
            if (!narrow) Text('$lbl ${(days / 2).ceil()}', style: axis),
            Text('$lbl $days', style: axis),
          ]),
        ),
        const SizedBox(height: 14),
        Wrap(spacing: 18, runSpacing: 6, children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Dot(t.yellow),
            const SizedBox(width: 6),
            T('On target', style: ts(narrow ? 12 : 9, color: t.muted)),
          ]),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: t.coral, width: 2)),
            ),
            const SizedBox(width: 6),
            Flexible(
                child: T(
                    narrow
                        ? 'Missed target — tap a point for detail.'
                        : 'Missed target — hover a point for detail.',
                    style: ts(narrow ? 12 : 9, color: t.muted))),
          ]),
        ]),
      ]),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.points,
    required this.missed,
    required this.targetY,
    required this.lowerBetter,
    required this.active,
  });
  final List<Offset> points;
  final List<bool> missed;
  final double targetY;
  final bool lowerBetter;
  final int? active;

  @override
  void paint(Canvas canvas, Size size) {
    final t = kTokens;
    final band = lowerBetter
        ? Rect.fromLTRB(0, targetY, size.width, size.height)
        : Rect.fromLTRB(0, 0, size.width, targetY);
    canvas.drawRect(band, Paint()..color = t.green.withOpacity(0.06));
    final dash = Paint()
      ..color = t.muted2
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 8) {
      canvas.drawLine(Offset(x, targetY),
          Offset(math.min(x + 4, size.width), targetY), dash);
    }
    if (active != null) {
      canvas.drawLine(Offset(points[active!].dx, 0),
          Offset(points[active!].dx, size.height), Paint()..color = t.line);
    }
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = t.yellow
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    for (var i = 0; i < points.length; i++) {
      final s = i == active ? 1.6 : 1.0;
      if (missed[i]) {
        canvas.drawCircle(points[i], 4 * s, Paint()..color = t.canvas);
        canvas.drawCircle(
            points[i],
            4 * s,
            Paint()
              ..color = t.coral
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
      } else {
        canvas.drawCircle(points[i], 3 * s, Paint()..color = t.yellow);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) => true;
}
