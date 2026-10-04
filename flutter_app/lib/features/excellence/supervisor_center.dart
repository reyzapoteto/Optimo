import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../l10n/tr.dart';
import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import 'charts.dart';
import 'dialogs.dart';
import 'digital_twin.dart';

class SupervisorCenter extends ConsumerStatefulWidget {
  const SupervisorCenter({super.key, this.initialFocus});
  final String? initialFocus;
  @override
  ConsumerState<SupervisorCenter> createState() => _SupervisorCenterState();
}

class _QItem {
  const _QItem(this.id, this.type, this.zone, this.status, this.time, this.tone, this.owner,
      {this.action, this.onAction, this.viewOnly = false});
  final String id, type, zone, status, time;
  final Tone tone;
  final String? owner;
  final String? action;
  final VoidCallback? onAction;
  final bool viewOnly;
}

class _SupervisorCenterState extends ConsumerState<SupervisorCenter> {
  late String? selected = widget.initialFocus;

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(focusFacilityProvider, (_, next) {
      if (next != null) setState(() => selected = next);
    });
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SpanRow(spans: const [4, 4, 4], children: [_zoneReadiness(context), _slaRisk(context), _teamLoad(context)]),
      const SizedBox(height: 24),
      SpanRow(spans: const [9, 3], breakpoint: 1181, children: [
        DigitalTwin(
          role: Role.supervisor,
          selectedId: selected,
          onSelect: (id) => setState(() => selected = id),
          attentionFilter: false,
          onClearFilter: () {},
        ),
        _queue(context),
      ]),
      const SizedBox(height: 24),
      const ShiftFlow(),
    ]);
  }

  Widget _card({required Widget child}) => Panel(height: 224, radius: 16, child: child);

  Widget _zoneReadiness(BuildContext context) {
    final t = context.tk;
    final scope = ref.watch(scopeProvider);
    final mine = scope == 'My zones';
    final monitored = mine ? 27 : 42;
    final critical = mine ? 1 : 2;
    final attention = mine ? 2 : 3;
    final ready = monitored - critical - attention;
    final pct = (ready / monitored * 100).round();
    final rp = ready / monitored * 100, ap = attention / monitored * 100;
    return _card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(child: Eyebrow('ZONE READINESS')),
          RoleBadge(scope),
        ]),
        const SizedBox(height: 14),
        Expanded(
          child: Row(children: [
            Tooltip(
              message: '${context.tr('SERVICE REQUIRED')} · $attention ${context.tr('facilities')} · ${(ap).round()}%',
              child: Donut(
                size: 128,
                stroke: 12,
                segments: [
                  Seg(0, rp, t.yellow),
                  Seg(rp, rp + ap, t.yellowSoft.withOpacity(0.55)),
                  Seg(rp + ap, 100, t.coral),
                ],
                center: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('$pct%', style: ts(30, weight: FontWeight.w500)),
                  const Eyebrow('READY'),
                ]),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('$monitored ${context.tr('monitored')}', style: ts(10, color: t.muted)),
                const SizedBox(height: 8),
                _legend(t.yellow, '$ready ${context.tr('ready')} ($pct%)'),
                _legend(t.yellowSoft, '$attention ${context.tr('need attention')}'),
                _legend(t.coral, '$critical ${context.tr('critical')}'),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _legend(Color c, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Dot(c),
          const SizedBox(width: 8),
          Flexible(child: Text(text, style: ts(10))),
        ]),
      );

  Widget _slaRisk(BuildContext context) {
    final t = context.tk;
    final own = ref.watch(ownershipProvider);
    final unassigned = own['SH-04']?.taskStatus == 'Unassigned';
    return _card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Eyebrow('SLA RISK'),
        const SizedBox(height: 14),
        Text(unassigned ? '00:42' : '02:10', style: ts(32, color: t.yellow, weight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(
            unassigned
                ? '${context.tr('Response due')} · SH-04 · T-1042'
                : '${context.tr('Completion due')} · WC-02 · T-1036',
            style: ts(10, color: t.muted)),
        const Spacer(),
        Row(children: [
          Expanded(flex: 4, child: Container(height: 6, decoration: BoxDecoration(color: t.green, borderRadius: BorderRadius.circular(3)))),
          const SizedBox(width: 4),
          Expanded(flex: 2, child: Container(height: 6, decoration: BoxDecoration(color: t.yellow, borderRadius: BorderRadius.circular(3)))),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _legendInline(t.green, '4 ${context.tr('Within')}'),
          _legendInline(t.yellow, '2 ${context.tr('Approaching')}'),
          _legendInline(t.coral, '0 ${context.tr('Breached')}'),
        ]),
        const SizedBox(height: 12),
        LinkButton('View at-risk tasks', arrow: true, onTap: () => ref.read(actionsProvider).navigate(AppPage.tasks)),
      ]),
    );
  }

  Widget _legendInline(Color c, String text) => Padding(
        padding: const EdgeInsetsDirectional.only(end: 14),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Dot(c), const SizedBox(width: 6), Text(text, style: ts(9, color: kTokens.muted))]),
      );

  Widget _teamLoad(BuildContext context) {
    final t = context.tk;
    final own = ref.watch(ownershipProvider);
    final unassigned = own.values.where((o) => o.taskStatus == 'Unassigned').length + 1;
    final rows = [
      for (final m in supervisorTeam)
        (
          m,
          (m.name == 'Noura Al-Salem' || m.name == 'Yousef Mansour' ? 0 : 1) +
              own.values.where((o) => o.assignee == m.name && !o.closed).length
        ),
    ]..sort((a, b) => b.$2 - a.$2);
    return _card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(child: Eyebrow('TEAM LOAD')),
          LinkButton('Open dispatch board', onTap: () => ref.read(actionsProvider).navigate(AppPage.tasks)),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: t.surface2,
            border: BorderDirectional(start: BorderSide(color: t.yellow, width: 2)),
          ),
          child: Text('$unassigned ${context.tr('Unassigned')}', style: ts(10, color: t.yellow, weight: FontWeight.w600)),
        ),
        const SizedBox(height: 8),
        for (final r in rows)
          Tap(
            onTap: () => ref.read(actionsProvider).navigate(AppPage.team),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(children: [
                Avatar(r.$1.initials, size: 22),
                const SizedBox(width: 8),
                SizedBox(
                  width: 110,
                  child: Text('${r.$1.name}${r.$1.name == 'Sara Al-Dosari' ? ' · ${context.tr('Blocked')}' : ''}',
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(10)),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      minHeight: 5,
                      value: (r.$2 / 3).clamp(0.0, 1.0),
                      color: r.$2 >= 3 ? t.yellow : t.yellowSoft,
                      backgroundColor: AppTokens.track,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${r.$2} / 3', style: ts(9, color: t.muted)),
                if (r.$2 >= 3) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.error_outline, size: 12, color: t.yellow),
                  T('At capacity', style: ts(8, color: t.yellow)),
                ],
              ]),
            ),
          ),
      ]),
    );
  }

  List<_QItem> _items(BuildContext context, List<Facility> list) {
    final own = ref.watch(ownershipProvider);
    final scope = ref.watch(scopeProvider);
    final a = ref.read(actionsProvider);
    Facility f(String id) => list.firstWhere((x) => x.id == id);
    final out = <_QItem>[];
    for (final x in list) {
      if (own[x.id]?.closed == true) {
        out.add(_QItem(x.id, x.type, x.zone, 'Out of Service', x.detail ?? '', Tone.critical, x.assigned,
            action: 'Restore', onAction: () => openFacilityControl(context, x, close: false)));
      }
    }
    final sh = f('SH-04');
    if (own['SH-04']?.closed != true) {
      final assigned = sh.assigned;
      out.add(_QItem('SH-04', 'Shower', 'Changing Room A', sh.status,
          assigned != null ? 'Completion due in 06:30' : 'Response due in 00:42', Tone.attention, assigned,
          action: assigned != null ? 'Open Task' : 'Assign',
          onAction: assigned != null ? () => a.openTask('TSK-1048') : () => openAssignDialog(context, sh)));
    }
    final wc = f('WC-02');
    if (own['WC-02']?.closed != true) {
      out.add(_QItem('WC-02', 'Toilet', 'Toilet Area', 'Cleaning Required', 'SLA breach in 02:10', Tone.critical, wc.assigned,
          action: 'Open Task', onAction: () => a.openTask('TSK-1047')));
    }
    final bin = f('BIN-02');
    if (own['BIN-02']?.closed != true) {
      out.add(_QItem('BIN-02', 'Waste Bin', 'Vanity Area', '85% full', 'Approaching threshold', Tone.attention, bin.assigned,
          action: 'Open Task', onAction: () => a.openTask('TSK-1046')));
    }
    if (scope == 'Whole club') {
      out.add(const _QItem('WB-06', 'Waste Bin', 'Lounge · outside your zones', 'Blocked', 'Breached by 04:20', Tone.critical,
          'Sara Omar',
          viewOnly: true));
    } else {
      out.add(_QItem('SH-01', 'Shower', 'Shower Area', 'Inspection due · Completed 09:58', 'Due by 11:00', Tone.cleaning, null,
          action: 'Inspect', onAction: () => a.navigate(AppPage.quality)));
    }
    return out;
  }

  Widget _queue(BuildContext context) {
    final t = context.tk;
    final list = ref.watch(resolvedFacilitiesProvider);
    final items = _items(context, list);
    final shown = items.take(4).toList();
    return Panel(
      radius: 16,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: T('Needs Your Decision', style: ts(16, weight: FontWeight.w500))),
          Text('${items.length}', style: ts(12, color: t.yellow, weight: FontWeight.w700)),
        ]),
        const SizedBox(height: 6),
        T('Prioritized by urgency. Each item shows its owner and next step.', style: ts(10, color: t.muted2)),
        const SizedBox(height: 16),
        if (shown.isEmpty) ...[
          T('All clear', style: ts(14, weight: FontWeight.w500)),
          const SizedBox(height: 6),
          T('All monitored facilities are operating normally.', style: ts(10, color: t.muted)),
          const SizedBox(height: 12),
          LinkButton('View upcoming inspections', onTap: () => ref.read(actionsProvider).navigate(AppPage.quality)),
        ] else
          for (var i = 0; i < shown.length; i++) _qRow(context, i, shown[i]),
        const SizedBox(height: 6),
        LinkButton('View all in Dispatch Board', arrow: true, onTap: () => ref.read(actionsProvider).navigate(AppPage.tasks)),
      ]),
    );
  }

  Widget _qRow(BuildContext context, int i, _QItem q) {
    final t = context.tk;
    final c = toneColor(q.tone);
    return Tap(
      onTap: q.viewOnly ? null : () => setState(() => selected = q.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: selected == q.id ? t.surface2 : t.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: t.lineSoft),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(width: 3, color: c),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text((i + 1).toString().padLeft(2, '0'), style: ts(9, color: t.muted2, weight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Text(q.id, style: ts(13, weight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Flexible(child: StatusPill(q.status, tone: q.tone)),
                  ]),
                  const SizedBox(height: 4),
                  Text('${context.tr(q.type)} · ${context.tr(q.zone)}', style: ts(9, color: t.muted)),
                  const SizedBox(height: 6),
                  if (q.owner == null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppTokens.chipActiveBg, borderRadius: BorderRadius.circular(4)),
                      child: Text(context.tr('UNASSIGNED'), style: ts(8, color: t.yellow, weight: FontWeight.w700, spacing: 1)),
                    )
                  else
                    Text('${context.tr('Assigned to')} ${q.owner}', style: ts(9, color: t.muted2)),
                  const SizedBox(height: 6),
                  Row(children: [
                    Expanded(child: T(q.time, style: ts(9, color: c))),
                    if (q.viewOnly)
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.visibility_outlined, size: 12, color: t.muted2),
                        const SizedBox(width: 4),
                        T('View only', style: ts(9, color: t.muted2)),
                      ])
                    else if (q.action != null)
                      AppButton(label: q.action!, compact: true, kind: q.owner == null ? BtnKind.primary : BtnKind.secondary, onPressed: q.onAction),
                  ]),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
