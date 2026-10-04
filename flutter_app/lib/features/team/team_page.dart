import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../l10n/tr.dart';
import '../../shell/page_intro.dart';
import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/detail_drawer.dart';

class TeamPage extends ConsumerStatefulWidget {
  const TeamPage({super.key});
  @override
  ConsumerState<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends ConsumerState<TeamPage> {
  String view = 'Current Team';
  String availability = 'All Statuses';
  bool filters = false;

  static const team = [
    ('AH', 'Ahmed Hassan', 'Duty Manager', 'All zones', 'SH-04 · Service', 3, 'Available'),
    ('SO', 'Sara Omar', 'Hospitality Associate', 'Changing Rooms', 'SH-07 · Cleaning', 5, 'On task'),
    ('MK', 'M. Khalid', 'Hospitality Associate', 'Functional Training', 'TC-05 · Cleaning', 4, 'On task'),
    ('NF', 'N. Faisal', 'Quality Supervisor', 'Pool & Lounge', 'Pool inspection', 2, 'Available'),
  ];
  static const shifts = [
    ('Morning Operations', '07:00—15:00', 'Current Shift', 8, 'Ahmed Hassan'),
    ('Evening Hospitality', '15:00—23:00', 'Upcoming', 7, 'Sara Omar'),
    ('Night Deep Clean', '23:00—03:00', 'Upcoming', 4, 'M. Khalid'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    final members = team.where((m) => availability == 'All Statuses' || m.$7 == availability).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const PageIntro(page: AppPage.team),
      const StatGrid(children: [
        StatCard(label: 'On shift', value: '12', detail: 'Full planned coverage'),
        StatCard(label: 'Available', value: '5', detail: 'Ready for assignment'),
        StatCard(label: 'Active tasks', value: '6', detail: 'Across 4 zones', tone: Tone.cleaning),
        StatCard(label: 'Overdue', value: '0', detail: 'Service standard met'),
      ]),
      const SizedBox(height: 24),
      Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
        AppChip(label: 'Current Team', active: view == 'Current Team', onTap: () => setState(() => view = 'Current Team')),
        AppChip(label: 'Shifts', active: view == 'Shifts', onTap: () => setState(() => view = 'Shifts')),
        const SizedBox(width: 8),
        AppButton(label: 'Filters', icon: Icons.filter_list, onPressed: () => setState(() => filters = !filters)),
        AppButton(
          label: view == 'Shifts' ? 'Create Shift' : 'Manage Shift',
          icon: Icons.add,
          kind: BtnKind.primary,
          onPressed: () {
            setState(() => view = 'Shifts');
            showSideDrawer(context, width: 440, builder: (_) => const ShiftForm());
          },
        ),
      ]),
      if (filters) ...[
        const SizedBox(height: 12),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: AppDropdown(
            label: 'AVAILABILITY',
            value: availability,
            options: const ['All Statuses', 'Available', 'On task'],
            onChanged: (v) => setState(() => availability = v),
          ),
        ),
      ],
      const SizedBox(height: 16),
      if (view == 'Current Team')
        Panel(
          padding: EdgeInsets.zero,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: t.line))),
              child: Row(children: [
                for (final h in const [('Employee', 3), ('Assigned zone', 2), ('Current work', 2), ('Completed', 1), ('Status', 1)])
                  Expanded(flex: h.$2, child: T(h.$1, style: ts(9, color: t.muted2, weight: FontWeight.w700, spacing: 0.8))),
              ]),
            ),
            if (members.isEmpty)
              const EmptyState(title: 'No team members match these filters.')
            else
              for (final m in members)
                Tap(
                  onTap: () => openDetail(context, 'Team Member', m.$2),
                  child: Container(
                    height: 64,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: t.lineSoft))),
                    child: Row(children: [
                      Expanded(
                        flex: 3,
                        child: Row(children: [
                          Avatar(m.$1, size: 34),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                              T(m.$2, style: ts(12, weight: FontWeight.w600)),
                              T(m.$3, style: ts(10, color: t.muted2)),
                            ]),
                          ),
                        ]),
                      ),
                      Expanded(flex: 2, child: T(m.$4, style: ts(11, color: t.muted))),
                      Expanded(flex: 2, child: T(m.$5, style: ts(11))),
                      Expanded(flex: 1, child: Text('${m.$6} ${context.tr('today')}', style: ts(11))),
                      Expanded(
                        flex: 1,
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: StatusPill(m.$7, tone: m.$7 == 'Available' ? Tone.ready : Tone.cleaning),
                        ),
                      ),
                    ]),
                  ),
                ),
          ]),
        )
      else
        Column(children: [
          for (final s in shifts)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Panel(
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        T(s.$1, style: ts(14, weight: FontWeight.w600)),
                        const SizedBox(width: 10),
                        StatusPill(s.$3, tone: s.$3 == 'Current Shift' ? Tone.ready : Tone.muted),
                      ]),
                      const SizedBox(height: 6),
                      Text(s.$2, style: ts(12, color: t.yellow, weight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('${s.$4} ${context.tr('employees')} · ${context.tr('Supervisor')}: ${s.$5}',
                          style: ts(10, color: t.muted)),
                    ]),
                  ),
                  for (final z in const ['CR', 'PL', 'FT'])
                    Container(
                      width: 30,
                      height: 30,
                      margin: const EdgeInsetsDirectional.only(start: 6),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: t.line), color: t.surface2),
                      child: Text(z, style: ts(8, color: t.muted, weight: FontWeight.w700)),
                    ),
                ]),
              ),
            ),
        ]),
    ]);
  }
}

class ShiftForm extends ConsumerStatefulWidget {
  const ShiftForm({super.key});
  @override
  ConsumerState<ShiftForm> createState() => _ShiftFormState();
}

class _ShiftFormState extends ConsumerState<ShiftForm> {
  final name = TextEditingController(text: 'Morning Operations');
  final start = TextEditingController(text: '07:00');
  final end = TextEditingController(text: '15:00');
  final notes = TextEditingController();
  String employee = 'Ahmed Hassan · Available';

  @override
  void dispose() {
    name.dispose();
    start.dispose();
    end.dispose();
    notes.dispose();
    super.dispose();
  }

  bool get timeInvalid => end.text.compareTo(start.text) <= 0;
  bool get conflict => employee.startsWith('M. Khalid');

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    return Column(children: [
      Expanded(
        child: ListView(padding: const EdgeInsets.all(32), children: [
          Row(children: [
            const Expanded(child: Eyebrow('SHIFT MANAGEMENT')),
            IconBtn(Icons.close, size: 32, onTap: () => Navigator.of(context).pop()),
          ]),
          const SizedBox(height: 6),
          T('Create Shift', style: ts(22, weight: FontWeight.w500)),
          const SizedBox(height: 24),
          const FieldLabel('Shift Name'),
          AppTextField(controller: name),
          const SizedBox(height: 16),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const FieldLabel('Start'),
                AppTextField(controller: start, onChanged: (_) => setState(() {})),
              ]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const FieldLabel('End'),
                AppTextField(
                  controller: end,
                  onChanged: (_) => setState(() {}),
                  error: timeInvalid ? 'End time must be after start time.' : null,
                ),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          const FieldLabel('Employee'),
          AppDropdown(
            expand: true,
            value: employee,
            options: const ['Ahmed Hassan · Available', 'Sara Omar · On Task', 'M. Khalid · Conflict'],
            onChanged: (v) => setState(() => employee = v),
          ),
          if (conflict) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: t.coral.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: t.coral.withOpacity(0.4)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const StatusPill('Availability conflict', tone: Tone.critical),
                const SizedBox(height: 6),
                T('M. Khalid is assigned to Functional Training until 16:00.', style: ts(10, color: t.muted)),
              ]),
            ),
          ],
          const SizedBox(height: 16),
          const FieldLabel('Zone Assignment'),
          const AppDropdown(expand: true, options: ['Changing Rooms', 'Pool', 'Functional Training', 'Lounge']),
          const SizedBox(height: 16),
          const FieldLabel('Operational Notes'),
          AppTextField(controller: notes, placeholder: 'Add shift context if required', maxLines: 3),
        ]),
      ),
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: t.line))),
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          AppButton(label: 'Cancel', onPressed: () => Navigator.of(context).pop()),
          const SizedBox(width: 8),
          AppButton(
            label: 'Save Shift',
            kind: BtnKind.primary,
            onPressed: timeInvalid || conflict
                ? null
                : () {
                    ref.read(actionsProvider).toast('Shift updated');
                    Navigator.of(context).pop();
                  },
          ),
        ]),
      ),
    ]);
  }
}
