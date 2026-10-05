import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../l10n/tr.dart';
import '../../shell/page_intro.dart';
import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/detail_drawer.dart';

class QualityPage extends ConsumerWidget {
  const QualityPage({super.key});

  static const standards = [
    ('Changing Rooms', '96%', 'Passed', '08:42'),
    ('Pool & Wet Areas', '91%', 'Rework', '10:16'),
    ('Training Floors', '98%', 'Passed', '09:25'),
    ('Lounge', '89%', 'Pending', '—'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tk;
    final role = ref.watch(authProvider);
    final readOnly = role == Role.executive;
    // Supervisor / Executive on mobile: stack each record into grouped lines.
    final stacked = role != null && MediaQuery.sizeOf(context).width < 768;
    Tone tone(String v) => v == 'Passed'
        ? Tone.ready
        : (v == 'Rework' ? Tone.attention : Tone.muted);
    const bars = [76.0, 84.0, 82.0, 91.0, 88.0, 94.0, 92.0];
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const PageIntro(page: AppPage.quality),
      const StatGrid(children: [
        StatCard(
            label: 'Inspection pass rate',
            value: '94%',
            detail: '+3% this week'),
        StatCard(label: 'Completed today', value: '18', detail: '4 remaining'),
        StatCard(
            label: 'Rework required',
            value: '2',
            detail: 'Assigned and in progress',
            tone: Tone.attention),
        StatCard(label: 'Avg. score', value: '9.2', detail: 'Target 9.0'),
      ]),
      const SizedBox(height: 24),
      SpanRow(spans: const [
        8,
        4
      ], children: [
        Panel(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SectionHead(
              eyebrow: "TODAY'S INSPECTIONS",
              title: 'Quality standards',
              trailing: readOnly
                  ? null
                  : AppButton(
                      label: 'Start Inspection',
                      kind: BtnKind.primary,
                      icon: Icons.add,
                      onPressed: () => openDetail(
                          context, 'Inspection Detail', 'New Inspection'),
                    ),
            ),
            const SizedBox(height: 16),
            for (final s in standards)
              Tap(
                onTap: () => openDetail(context, 'Inspection Detail', s.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: t.lineSoft))),
                  child: stacked
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      T(s.$1,
                                          style: ts(14,
                                              weight: FontWeight.w600,
                                              height: 1.3)),
                                      const SizedBox(height: 4),
                                      T('Hospitality checklist · 12 items',
                                          style: ts(12, color: t.muted2)),
                                      const SizedBox(height: 8),
                                      Wrap(
                                          spacing: 12,
                                          runSpacing: 8,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            Text(s.$2,
                                                style: ts(16,
                                                    weight: FontWeight.w500)),
                                            StatusPill(s.$3, tone: tone(s.$3)),
                                            Text(s.$4,
                                                style: ts(12, color: t.muted2)),
                                          ]),
                                    ]),
                              ),
                              DirIcon(Icons.chevron_right,
                                  size: 18, color: t.muted2),
                            ])
                      : Row(children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                                color: t.surface2,
                                borderRadius: BorderRadius.circular(8)),
                            child: Icon(pageIcon(AppPage.quality),
                                size: 16, color: t.muted),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  T(s.$1,
                                      style: ts(12, weight: FontWeight.w600)),
                                  const SizedBox(height: 3),
                                  T('Hospitality checklist · 12 items',
                                      style: ts(10, color: t.muted2)),
                                ]),
                          ),
                          SizedBox(
                              width: 60,
                              child: Text(s.$2,
                                  style: ts(14, weight: FontWeight.w500))),
                          SizedBox(
                            width: 90,
                            child: StatusPill(s.$3,
                                tone: s.$3 == 'Passed'
                                    ? Tone.ready
                                    : (s.$3 == 'Rework'
                                        ? Tone.attention
                                        : Tone.muted)),
                          ),
                          SizedBox(
                              width: 50,
                              child:
                                  Text(s.$4, style: ts(10, color: t.muted2))),
                          DirIcon(Icons.chevron_right,
                              size: 16, color: t.muted2),
                        ]),
                ),
              ),
          ]),
        ),
        Panel(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionHead(eyebrow: '7 DAY QUALITY', title: 'Club standard'),
            const SizedBox(height: 16),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('9.2',
                  style: ts(48,
                      color: t.yellow, weight: FontWeight.w500, height: 1)),
              Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('/ 10', style: ts(14, color: t.muted))),
            ]),
            const SizedBox(height: 10),
            T('Quality has remained above target for 6 consecutive days.',
                style: ts(10, color: t.muted, height: 1.5)),
            const SizedBox(height: 20),
            SizedBox(
              height: 120,
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                for (var i = 0; i < bars.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: bars[i],
                              decoration: BoxDecoration(
                                color: t.yellow.withOpacity(
                                    i == bars.length - 1 ? 1 : 0.55),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(days[i], style: ts(8, color: t.muted2)),
                          ]),
                    ),
                  ),
              ]),
            ),
          ]),
        ),
      ]),
    ]);
  }
}
