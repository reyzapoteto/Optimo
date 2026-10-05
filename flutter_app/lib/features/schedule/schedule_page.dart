import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../l10n/tr.dart';
import '../../shell/page_intro.dart';
import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/detail_drawer.dart';

class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({super.key});
  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends ConsumerState<SchedulePage> {
  int offset = 0;
  String view = 'Day';

  String get dateLabel {
    if (offset == 0) return 'Monday, 24 June';
    if (offset > 0) return 'Tuesday, ${24 + offset} June';
    return 'Sunday, ${24 + offset} June';
  }

  static const dayRows = [
    ('08:00', 'Routine Cleaning', 'Changing Rooms', 'Sara Omar', 'Completed'),
    ('10:30', 'Facility Inspection', 'Pool', 'N. Faisal', 'In Progress'),
    ('12:00', 'Replenishment', 'Lounge', 'Ahmed Hassan', 'Upcoming'),
    (
      '14:30',
      'Routine Cleaning',
      'Functional Training',
      'M. Khalid',
      'Upcoming'
    ),
    ('18:00', 'Deep Cleaning', 'Showers', 'Evening Team', 'Upcoming'),
  ];
  static const weekRows = [
    ('TUE 09:00', 'Current Shift', 'All Zones', 'Ahmed Hassan', 'Upcoming'),
    ('WED 18:00', 'Deep Cleaning', 'Pool', 'Evening Team', 'Upcoming'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    final rows = view == 'Week' ? [...dayRows, ...weekRows] : dayRows;
    // Supervisor on mobile: agenda layout with grouped, readable rows.
    final agenda = ref.watch(authProvider) != Role.executive &&
        MediaQuery.sizeOf(context).width < 768;
    Tone tone(String s) => s == 'Completed'
        ? Tone.ready
        : (s == 'In Progress' ? Tone.cleaning : Tone.muted);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const PageIntro(page: AppPage.schedule),
      Wrap(
          spacing: 8,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (agenda) ...[
              AppButton(
                label: 'Schedule Work',
                icon: Icons.add,
                kind: BtnKind.primary,
                onPressed: () => showSideDrawer(context,
                    width: 440, builder: (_) => const ScheduleForm()),
              ),
              Row(mainAxisSize: MainAxisSize.min, children: [
                AppChip(
                    label: 'Day',
                    active: view == 'Day',
                    onTap: () => setState(() => view = 'Day')),
                const SizedBox(width: 8),
                AppChip(
                    label: 'Week',
                    active: view == 'Week',
                    onTap: () => setState(() => view = 'Week')),
              ]),
              Row(children: [
                AppButton(
                    label: 'Today',
                    onPressed: () => setState(() => offset = 0)),
                const SizedBox(width: 8),
                IconBtn(Icons.chevron_left,
                    size: 44,
                    tooltip: 'Previous',
                    onTap: () => setState(() => offset--)),
                Expanded(
                    child: Center(
                        child: T(dateLabel,
                            style: ts(14, weight: FontWeight.w600)))),
                IconBtn(Icons.chevron_right,
                    size: 44,
                    tooltip: 'Next',
                    onTap: () => setState(() => offset++)),
              ]),
            ] else ...[
              AppButton(
                  label: 'Today', onPressed: () => setState(() => offset = 0)),
              IconBtn(Icons.chevron_left,
                  onTap: () => setState(() => offset--)),
              SizedBox(
                width: 170,
                child: Center(
                    child:
                        T(dateLabel, style: ts(12, weight: FontWeight.w600))),
              ),
              IconBtn(Icons.chevron_right,
                  onTap: () => setState(() => offset++)),
              const SizedBox(width: 8),
              AppChip(
                  label: 'Day',
                  active: view == 'Day',
                  onTap: () => setState(() => view = 'Day')),
              AppChip(
                  label: 'Week',
                  active: view == 'Week',
                  onTap: () => setState(() => view = 'Week')),
              const SizedBox(width: 8),
              AppButton(
                label: 'Schedule Work',
                icon: Icons.add,
                kind: BtnKind.primary,
                onPressed: () => showSideDrawer(context,
                    width: 440, builder: (_) => const ScheduleForm()),
              ),
            ],
          ]),
      SizedBox(height: agenda ? 16 : 24),
      SpanRow(
          spans: const [8, 4],
          gap: agenda ? 16 : 24,
          children: [
            Panel(
              padding: EdgeInsets.zero,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: t.line))),
                      child: Row(children: [
                        Text(context.tr('MON 24'),
                            style: ts(11,
                                color: t.yellow,
                                weight: FontWeight.w700,
                                spacing: 1)),
                        const SizedBox(width: 14),
                        Expanded(
                            child: T('Operational schedule',
                                style: ts(14, weight: FontWeight.w500))),
                        Text('${rows.length} ${context.tr('items')}',
                            style: ts(10, color: t.muted)),
                      ]),
                    ),
                    for (final r in rows)
                      Tap(
                        onTap: () =>
                            openDetail(context, 'Schedule Detail', r.$2),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          decoration: BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(color: t.lineSoft))),
                          child: agenda
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                      Container(
                                          width: 4,
                                          height: 64,
                                          decoration: BoxDecoration(
                                              color: t.yellow,
                                              borderRadius:
                                                  BorderRadius.circular(2))),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(children: [
                                                Text(context.tr(r.$1),
                                                    style: ts(14,
                                                            color: t.yellow,
                                                            weight:
                                                                FontWeight.w600)
                                                        .copyWith(
                                                            fontFeatures: const [
                                                          FontFeature
                                                              .tabularFigures()
                                                        ])),
                                                const Spacer(),
                                                StatusPill(r.$5,
                                                    tone: tone(r.$5)),
                                              ]),
                                              const SizedBox(height: 8),
                                              T(r.$2,
                                                  style: ts(16,
                                                      weight: FontWeight.w600,
                                                      height: 1.3)),
                                              const SizedBox(height: 4),
                                              Text(
                                                  '${context.tr(r.$3)} · ${context.tr(r.$4)}',
                                                  style: ts(13,
                                                      color: t.muted,
                                                      height: 1.5)),
                                            ]),
                                      ),
                                    ])
                              : Row(children: [
                                  SizedBox(
                                      width: 80,
                                      child: Text(context.tr(r.$1),
                                          style: ts(11, color: t.muted))),
                                  Container(
                                      width: 6,
                                      height: 40,
                                      decoration: BoxDecoration(
                                          color: t.yellow,
                                          borderRadius:
                                              BorderRadius.circular(3))),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          T(r.$2,
                                              style: ts(12,
                                                  weight: FontWeight.w600)),
                                          const SizedBox(height: 4),
                                          Text(
                                              '${context.tr(r.$3)} · ${context.tr(r.$4)}',
                                              style: ts(10, color: t.muted2)),
                                        ]),
                                  ),
                                  StatusPill(r.$5,
                                      tone: r.$5 == 'Completed'
                                          ? Tone.ready
                                          : (r.$5 == 'In Progress'
                                              ? Tone.cleaning
                                              : Tone.muted)),
                                ]),
                        ),
                      ),
                  ]),
            ),
            Panel(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHead(
                        eyebrow: 'TODAY', title: 'Schedule coverage'),
                    const SizedBox(height: 18),
                    Text('92%',
                        style:
                            ts(40, color: t.yellow, weight: FontWeight.w500)),
                    T('All critical zones covered',
                        style: ts(10, color: t.muted)),
                    const SizedBox(height: 20),
                    for (final s in const [
                      ('Scheduled', '12'),
                      ('Completed', '7'),
                      ('Remaining', '5')
                    ])
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(children: [
                          Expanded(
                              child: T(s.$1, style: ts(11, color: t.muted))),
                          Text(s.$2, style: ts(12, weight: FontWeight.w600)),
                        ]),
                      ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: t.surface2,
                        border: BorderDirectional(
                            start: BorderSide(color: t.yellow, width: 2)),
                      ),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Eyebrow('NEXT ROUTINE'),
                            const SizedBox(height: 6),
                            T('Replenishment',
                                style: ts(13, weight: FontWeight.w600)),
                            const SizedBox(height: 3),
                            Text('12:00 · ${context.tr('Lounge')}',
                                style: ts(10, color: t.muted)),
                          ]),
                    ),
                  ]),
            ),
          ]),
    ]);
  }
}

class ScheduleForm extends StatefulWidget {
  const ScheduleForm({super.key});
  @override
  State<ScheduleForm> createState() => _ScheduleFormState();
}

class _ScheduleFormState extends State<ScheduleForm> {
  final date = TextEditingController(text: '2025-06-24');
  final time = TextEditingController(text: '12:00');
  bool saved = false;

  @override
  void dispose() {
    date.dispose();
    time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    if (saved) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('✓', style: ts(28, color: t.green)),
          const SizedBox(height: 12),
          T('Work scheduled', style: ts(22, weight: FontWeight.w500)),
          const SizedBox(height: 8),
          T('The routine is now visible to the assigned team.',
              style: ts(11, color: t.muted), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          AppButton(
              label: 'Done',
              kind: BtnKind.primary,
              onPressed: () => Navigator.of(context).pop()),
        ]),
      );
    }
    return Column(children: [
      Expanded(
        child: ListView(padding: const EdgeInsets.all(32), children: [
          Row(children: [
            const Expanded(child: Eyebrow('OPERATIONAL ROUTINE')),
            IconBtn(Icons.close,
                size: 32, onTap: () => Navigator.of(context).pop()),
          ]),
          const SizedBox(height: 6),
          T('Schedule Work', style: ts(22, weight: FontWeight.w500)),
          const SizedBox(height: 24),
          const FieldLabel('Routine Type *'),
          const AppDropdown(expand: true, options: [
            'Routine Cleaning',
            'Inspection',
            'Replenishment',
            'Deep Cleaning'
          ]),
          const SizedBox(height: 16),
          const FieldLabel('Zone *'),
          const AppDropdown(expand: true, options: [
            'Changing Rooms',
            'Pool',
            'Functional Training',
            'Lounge'
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FieldLabel('Date *'),
                    AppTextField(controller: date),
                  ]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FieldLabel('Time *'),
                    AppTextField(controller: time),
                  ]),
            ),
          ]),
          const SizedBox(height: 16),
          const FieldLabel('Assignee *'),
          const AppDropdown(expand: true, options: [
            'Sara Omar · Available',
            'Ahmed Hassan · Available',
            'M. Khalid · On Task'
          ]),
          const SizedBox(height: 16),
          const FieldLabel('Recurrence'),
          const AppDropdown(expand: true, options: ['Once', 'Daily', 'Weekly']),
        ]),
      ),
      Container(
        padding: const EdgeInsets.all(24),
        decoration:
            BoxDecoration(border: Border(top: BorderSide(color: t.line))),
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          AppButton(
              label: 'Cancel', onPressed: () => Navigator.of(context).pop()),
          const SizedBox(width: 8),
          AppButton(
              label: 'Save Schedule',
              kind: BtnKind.primary,
              onPressed: () => setState(() => saved = true)),
        ]),
      ),
    ]);
  }
}
