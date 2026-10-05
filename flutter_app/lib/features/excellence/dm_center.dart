import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../l10n/tr.dart';
import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import 'charts.dart';
import 'digital_twin.dart';

class DmCenter extends ConsumerStatefulWidget {
  const DmCenter({super.key, this.initialFocus});
  final String? initialFocus;
  @override
  ConsumerState<DmCenter> createState() => _DmCenterState();
}

class _DmCenterState extends ConsumerState<DmCenter> {
  late String? selected = widget.initialFocus;
  bool attention = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(focusFacilityProvider, (_, next) {
      if (next != null) setState(() => selected = next);
    });
    // Narrow screens: the action queue first, then KPIs, the twin, and trends.
    final w = MediaQuery.sizeOf(context).width;
    if (w < 1180) {
      final gap = w < 768 ? 16.0 : 24.0;
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _queue(context),
        SizedBox(height: gap),
        SpanRow(
            spans: const [1, 1],
            breakpoint: 760,
            gap: gap,
            children: [
              _readiness(context),
              _performance(context),
            ]),
        SizedBox(height: gap),
        _workload(context),
        SizedBox(height: gap),
        DigitalTwin(
          role: Role.dutyManager,
          selectedId: selected,
          onSelect: (id) => setState(() => selected = id),
          attentionFilter: attention,
          onClearFilter: () => setState(() => attention = false),
        ),
        SizedBox(height: gap),
        const PerformanceChart(),
        SizedBox(height: gap),
        _ActivityPanel(onFocus: (id) => setState(() => selected = id)),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SpanRow(spans: const [
        4,
        3,
        5
      ], children: [
        _readiness(context),
        _performance(context),
        _workload(context),
      ]),
      const SizedBox(height: 24),
      SpanRow(
          spans: const [9, 3],
          breakpoint: 1180,
          children: [
            DigitalTwin(
              role: Role.dutyManager,
              selectedId: selected,
              onSelect: (id) => setState(() => selected = id),
              attentionFilter: attention,
              onClearFilter: () => setState(() => attention = false),
            ),
            _queue(context),
          ]),
      const SizedBox(height: 24),
      SpanRow(spans: const [
        8,
        4
      ], children: [
        const PerformanceChart(),
        _ActivityPanel(onFocus: (id) => setState(() => selected = id)),
      ]),
    ]);
  }

  Widget _readiness(BuildContext context) {
    final t = context.tk;
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionHead(
            eyebrow: 'WASHROOM STANDARD',
            title: 'Operational Readiness',
            trailing: const StatusPill('Live', tone: Tone.ready)),
        const SizedBox(height: 18),
        Row(children: [
          Tooltip(
            message:
                '${context.tr('NEEDS ATTENTION')} 3 ${context.tr('facilities')} · 33%',
            child: Tap(
              onTap: () => setState(() => attention = !attention),
              child: Donut(
                size: 142,
                stroke: 7,
                segments: [
                  Seg(0, 67, t.yellow),
                  Seg(68, 90, t.yellowSoft),
                  Seg(90, 100, t.cyan)
                ],
                center: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('67%', style: ts(30, weight: FontWeight.w500)),
                  const Eyebrow('READY'),
                ]),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              T('9 monitored', style: ts(12, color: t.muted)),
              const SizedBox(height: 8),
              T('3 need attention',
                  style: ts(12, color: t.yellow, weight: FontWeight.w600)),
              if (attention) ...[
                const SizedBox(height: 10),
                T('Readiness filter', style: ts(9, color: t.muted2)),
              ],
            ]),
          ),
        ]),
      ]),
    );
  }

  Widget _performance(BuildContext context) {
    final t = context.tk;
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHead(
            eyebrow: 'WASHROOM SERVICE', title: 'Response Performance'),
        const SizedBox(height: 18),
        Center(
          child: Donut(
            size: 112,
            stroke: 6,
            segments: [Seg(0, 89, t.green)],
            center: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('89%', style: ts(24, weight: FontWeight.w500)),
              Text(context.tr('WITHIN TARGET'),
                  style: ts(7,
                      color: t.muted2, weight: FontWeight.w700, spacing: 1)),
            ]),
          ),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
              child: T('8 / 9 responses inside service target',
                  style: ts(10, color: t.muted))),
          T('+2% today',
              style: ts(10, color: t.green, weight: FontWeight.w600)),
        ]),
      ]),
    );
  }

  Widget _workload(BuildContext context) {
    final t = context.tk;
    final a = ref.read(actionsProvider);
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionHead(
          eyebrow: 'WASHROOM · RIGHT NOW',
          title: 'Active Workload',
          trailing: LinkButton('Open task board',
              arrow: true, onTap: () => a.navigate(AppPage.tasks)),
        ),
        const SizedBox(height: 24),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('3', style: ts(44, weight: FontWeight.w500, height: 1)),
          const SizedBox(width: 10),
          Flexible(
              child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Eyebrow('ACTIVE'),
              T('Washroom / Changing Area', style: ts(10, color: t.muted)),
            ]),
          )),
        ]),
        const SizedBox(height: 22),
        Row(children: [
          for (final c in [t.yellow, t.green, t.cyan]) ...[
            Expanded(
                child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                        color: c, borderRadius: BorderRadius.circular(3)))),
            if (c != t.cyan) const SizedBox(width: 4),
          ],
        ]),
        const SizedBox(height: 14),
        Wrap(spacing: 18, children: [
          for (final l in [
            ('1', 'New', t.yellow),
            ('1', 'Accepted', t.green),
            ('1', 'In Progress', t.cyan)
          ])
            Row(mainAxisSize: MainAxisSize.min, children: [
              Dot(l.$3),
              const SizedBox(width: 6),
              Text('${l.$1} ${context.tr(l.$2)}',
                  style: ts(10, color: t.muted)),
            ]),
        ]),
      ]),
    );
  }

  Widget _queue(BuildContext context) {
    final t = context.tk;
    const items = [
      (
        'SH-04',
        'Shower',
        'Changing Area A',
        'Service Required',
        'Open for 01:32',
        Tone.attention
      ),
      (
        'WC-02',
        'Toilet',
        'Toilet Area',
        'Cleaning',
        'Open for 03:20',
        Tone.cleaning
      ),
      (
        'BIN-02',
        'Waste Bin',
        'Vanity Area',
        '85% Full',
        'SLA breach in 18 min',
        Tone.attention
      ),
    ];
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionHead(
          eyebrow: 'DECISION QUEUE',
          title: 'Needs Attention',
          trailing: Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: AppTokens.chipActiveBg,
                borderRadius: BorderRadius.circular(8)),
            child: Text('3',
                style: ts(12, color: t.yellow, weight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 6),
        T('Prioritized by urgency and service impact.',
            style: ts(10, color: t.muted2)),
        const SizedBox(height: 16),
        for (final i in items)
          Tap(
            onTap: () => setState(() {
              selected = i.$1;
              attention = true;
            }),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected == i.$1 ? t.surface2 : t.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: selected == i.$1 ? toneColor(i.$6) : t.lineSoft),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(i.$1, style: ts(14, weight: FontWeight.w600)),
                      const Spacer(),
                      StatusPill(i.$4, tone: i.$6),
                    ]),
                    const SizedBox(height: 4),
                    Text('${context.tr(i.$2)} · ${context.tr(i.$3)}',
                        style: ts(10, color: t.muted)),
                    const SizedBox(height: 6),
                    T(i.$5, style: ts(9, color: toneColor(i.$6))),
                  ]),
            ),
          ),
        const SizedBox(height: 6),
        LinkButton('View all exceptions',
            arrow: true,
            onTap: () => ref.read(actionsProvider).navigate(AppPage.tasks)),
      ]),
    );
  }
}

class _ActivityPanel extends StatefulWidget {
  const _ActivityPanel({required this.onFocus});
  final ValueChanged<String> onFocus;
  @override
  State<_ActivityPanel> createState() => _ActivityPanelState();
}

class _ActivityPanelState extends State<_ActivityPanel> {
  bool all = false;
  static const rows = [
    ('10:24', 'SH-04', 'Service requested', Tone.attention),
    ('10:18', 'BIN-02', 'Reached 85% fill', Tone.attention),
    ('10:12', 'SH-01', 'Service completed', Tone.ready),
    ('10:06', 'WC-03', 'Device signal lost', Tone.critical),
    ('09:58', 'BIN-01', 'Bin service completed', Tone.ready),
    ('09:46', 'WC-02', 'Cleaning accepted', Tone.cleaning),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    final list = all ? rows : rows.take(4).toList();
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHead(eyebrow: 'AWARENESS', title: 'Live Activity'),
        const SizedBox(height: 16),
        for (final r in list)
          Tap(
            onTap: () => widget.onFocus(r.$2),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: t.lineSoft))),
              child: Row(children: [
                SizedBox(
                    width: 44,
                    child: Text(r.$1, style: ts(10, color: t.muted2))),
                Dot(toneColor(r.$4)),
                const SizedBox(width: 10),
                SizedBox(
                    width: 52,
                    child: Text(r.$2, style: ts(11, weight: FontWeight.w600))),
                Expanded(
                    child: T(r.$3, style: ts(10, color: t.muted), maxLines: 1)),
              ]),
            ),
          ),
        const SizedBox(height: 14),
        LinkButton(all ? 'Show recent activity' : 'View all activity',
            onTap: () => setState(() => all = !all)),
      ]),
    );
  }
}
