import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_data.dart';
import '../data/models.dart';
import '../l10n/tr.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import 'common.dart';

/// Opens the generic detail drawer (Task / Issue / Inspection / Team Member / Device / Settings / Schedule).
Future<void> openDetail(BuildContext context, String type, String title) {
  return showSideDrawer(context,
      width: 440, builder: (_) => DetailDrawer(type: type, title: title));
}

class DetailDrawer extends ConsumerStatefulWidget {
  const DetailDrawer({super.key, required this.type, required this.title});
  final String type;
  final String title;

  @override
  ConsumerState<DetailDrawer> createState() => _DetailDrawerState();
}

class _DetailDrawerState extends ConsumerState<DetailDrawer> {
  TaskRow? source;
  late String state;
  String owner = 'Ahmed Hassan · Available · 3 tasks';
  String? feedback;
  Timer? _fbTimer;

  @override
  void initState() {
    super.initState();
    for (final r in taskRows) {
      if (r.id == widget.title) source = r;
    }
    if (widget.type == 'Task Detail') {
      state = source?.status ?? 'New';
    } else if (widget.type == 'Issue Detail') {
      state = 'Investigating';
    } else {
      state = 'Active';
    }
  }

  @override
  void dispose() {
    _fbTimer?.cancel();
    super.dispose();
  }

  bool get isTask => widget.type == 'Task Detail';

  void _say(String msg) {
    _fbTimer?.cancel();
    setState(() => feedback = msg);
    _fbTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => feedback = null);
    });
  }

  (String, String?) get _taskAction {
    switch (state) {
      case 'New':
        return ('Accept Task', 'Accepted');
      case 'Accepted':
        return ('Start Task', 'In Progress');
      case 'Blocked':
        return ('Resolve Block', 'In Progress');
      case 'Completed':
        return ('View History', null);
      default:
        return ('Complete Task', 'Completed');
    }
  }

  String get _primaryLabel {
    if (isTask) return _taskAction.$1;
    switch (widget.type) {
      case 'Issue Detail':
        return 'Resolve Issue';
      case 'Inspection Detail':
        return 'Create Corrective Task';
      case 'Team Member':
        return 'Change Assignment';
      case 'Device Detail':
        return 'Create Related Issue';
      case 'Settings Detail':
        return 'Save Changes';
      default:
        return 'Edit Schedule';
    }
  }

  void _primary() {
    if (isTask) {
      final next = _taskAction.$2;
      if (next == null) {
        _say('History opened');
      } else {
        setState(() => state = next);
        _say('Task updated · ${context.tr(next)}');
      }
      return;
    }
    switch (widget.type) {
      case 'Issue Detail':
        setState(() => state = 'Resolved');
        _say('Issue resolved');
        break;
      case 'Team Member':
        _say('Assignment updated');
        break;
      case 'Inspection Detail':
        _say('Corrective task created');
        break;
      case 'Device Detail':
        _say('Related issue created');
        break;
      case 'Settings Detail':
        _say('Changes saved successfully.');
        break;
      default:
        _say('Schedule updated');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    final facilityExists =
        source != null && facilityById(source!.facility) != null;
    final done = state == 'Completed' || state == 'Resolved';
    return Column(children: [
      Expanded(
        child: ListView(padding: const EdgeInsets.all(32), children: [
          Row(children: [
            Expanded(child: Eyebrow(widget.type.toUpperCase())),
            IconBtn(Icons.close,
                size: 32, onTap: () => Navigator.of(context).pop()),
          ]),
          const SizedBox(height: 8),
          Text(context.tr(widget.title),
              style: ts(26, weight: FontWeight.w500)),
          const SizedBox(height: 10),
          StatusPill(state, tone: done ? Tone.ready : Tone.attention),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 3.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _fact('Location', source?.location ?? 'Changing Area A'),
              _fact('Owner', source?.assignee ?? 'Ahmed Hassan'),
              _fact('Created', 'Today · 10:24'),
              _fact('SLA',
                  '${context.tr(source?.sla ?? '28 min')} ${context.tr('remaining')}',
                  color: t.yellow),
            ],
          ),
          if (isTask && state != 'Completed') ...[
            const SizedBox(height: 24),
            const Eyebrow('ASSIGNMENT'),
            const SizedBox(height: 10),
            AppDropdown(
              label: 'Operational owner',
              expand: true,
              value: owner,
              options: const [
                'Ahmed Hassan · Available · 3 tasks',
                'Sara Omar · On Task · 5 tasks',
                'M. Khalid · On Task · 4 tasks',
              ],
              onChanged: (v) {
                setState(() => owner = v);
                _say('Task assigned');
              },
            ),
          ],
          const SizedBox(height: 24),
          const Eyebrow('OPERATIONAL CONTEXT'),
          const SizedBox(height: 10),
          Panel(
            color: t.surface,
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              T(
                  widget.type == 'Inspection Detail'
                      ? 'Hospitality standard checklist'
                      : 'Service activity',
                  style: ts(12, weight: FontWeight.w600)),
              const SizedBox(height: 6),
              T('Facility requires attention to restore the expected OPTIMO hospitality standard.',
                  style: ts(11, color: t.muted, height: 1.5)),
              if (widget.type == 'Inspection Detail') ...[
                const SizedBox(height: 12),
                for (final c in const [
                  ('Surface condition', 'Passed'),
                  ('Supplies available', 'Rework'),
                  ('Guest-ready standard', 'Passed'),
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(children: [
                      Expanded(child: T(c.$1, style: ts(11))),
                      StatusPill(c.$2,
                          tone: c.$2 == 'Passed' ? Tone.ready : Tone.attention),
                    ]),
                  ),
              ],
            ]),
          ),
          const SizedBox(height: 24),
          const Eyebrow('ACTIVITY'),
          const SizedBox(height: 10),
          for (final a in [
            ('10:24', context.tr('Request created automatically')),
            (
              '10:26',
              '${context.tr('Assigned to')} ${context.tr(source?.assignee ?? 'Ahmed Hassan')}'
            ),
            ('10:31', context.tr('Work started')),
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(children: [
                SizedBox(
                    width: 48,
                    child: Text(a.$1, style: ts(10, color: t.muted2))),
                Dot(t.yellowSoft),
                const SizedBox(width: 10),
                Expanded(child: Text(a.$2, style: ts(11))),
              ]),
            ),
          if (feedback != null) ...[
            const SizedBox(height: 16),
            Row(children: [
              Icon(Icons.check, size: 14, color: t.green),
              const SizedBox(width: 8),
              Text(context.tr(feedback!), style: ts(11, color: t.green)),
            ]),
          ],
        ]),
      ),
      Container(
        padding: const EdgeInsets.all(24),
        decoration:
            BoxDecoration(border: Border(top: BorderSide(color: t.line))),
        child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              if (isTask && facilityExists)
                AppButton(
                  label: 'Locate in Digital Twin',
                  kind: BtnKind.ghost,
                  onPressed: () {
                    Navigator.of(context).pop();
                    ref.read(actionsProvider).openFacility(source!.facility);
                  },
                ),
              AppButton(
                  label: 'Close', onPressed: () => Navigator.of(context).pop()),
              if (isTask && state == 'In Progress')
                AppButton(
                  label: 'Mark Blocked',
                  kind: BtnKind.destructive,
                  onPressed: () {
                    setState(() => state = 'Blocked');
                    _say('Task marked as blocked');
                  },
                ),
              AppButton(
                  label: _primaryLabel,
                  kind: BtnKind.primary,
                  onPressed: _primary),
            ]),
      ),
    ]);
  }

  Widget _fact(String label, String value, {Color? color}) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kTokens.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kTokens.lineSoft),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              T(label, style: ts(9, color: kTokens.muted2)),
              const SizedBox(height: 4),
              Text(context.tr(value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ts(12, color: color)),
            ]),
      );
}
