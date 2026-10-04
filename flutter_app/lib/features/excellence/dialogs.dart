import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../l10n/tr.dart';
import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';

Future<void> openAssignDialog(BuildContext context, Facility f) =>
    showAppModal(context, width: 640, builder: (_) => AssignDialog(facility: f));

Future<void> openFacilityControl(BuildContext context, Facility f, {required bool close}) =>
    showAppModal(context, width: 520, builder: (_) => FacilityControlDialog(facility: f, close: close));

class AssignDialog extends ConsumerStatefulWidget {
  const AssignDialog({super.key, required this.facility});
  final Facility facility;
  @override
  ConsumerState<AssignDialog> createState() => _AssignDialogState();
}

class _AssignDialogState extends ConsumerState<AssignDialog> {
  String? choice;
  String? reason;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    final f = widget.facility;
    final current = f.assigned;
    final reassign = current != null;
    final ranked = [...supervisorTeam]..sort((a, b) {
        if (a.fit != b.fit) return a.fit ? -1 : 1;
        if (a.overdue != b.overdue) return a.overdue - b.overdue;
        return a.active - b.active;
      });
    TeamMember? suggested;
    for (final m in ranked) {
      if (m.shift == 'On shift' && m.name != current) {
        suggested = m;
        break;
      }
    }
    final intro = '${context.tr(f.zone)} · ${context.tr(f.status)}' +
        (reassign ? ' · ${context.tr('Currently')} $current' : ' · ${context.tr('Response due in 00:42')}');

    return Padding(
      padding: const EdgeInsets.all(28),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Eyebrow(reassign ? 'REASSIGN TASK' : 'ASSIGN TASK')),
            IconBtn(Icons.close, size: 32, onTap: () => Navigator.of(context).pop()),
          ]),
          const SizedBox(height: 6),
          Text('${f.id} · ${context.tr(f.type)}', style: ts(22, weight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(intro, style: ts(11, color: t.muted)),
          const SizedBox(height: 20),
          for (final m in ranked) _row(context, m, m == suggested, m.name == current),
          if (reassign) ...[
            const SizedBox(height: 18),
            const FieldLabel('Reason (optional)'),
            Wrap(spacing: 8, children: [
              for (final r in const ['Workload', 'Absence', 'SLA risk', 'Other'])
                AppChip(label: r, active: reason == r, onTap: () => setState(() => reason = reason == r ? null : r)),
            ]),
          ],
          const SizedBox(height: 18),
          Row(children: [
            Icon(Icons.lock_outline, size: 14, color: t.muted2),
            const SizedBox(width: 8),
            T('Completion deadline stays the same.', style: ts(10, color: t.muted2)),
          ]),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            AppButton(label: 'Cancel', onPressed: () => Navigator.of(context).pop()),
            const SizedBox(width: 8),
            AppButton(
              label: 'Confirm assignment',
              kind: BtnKind.primary,
              onPressed: choice == null
                  ? null
                  : () {
                      ref.read(ownershipProvider.notifier).modify(
                            f.id,
                            (o) => Ownership(
                                assignee: choice, taskStatus: 'New', closed: o.closed, restored: o.restored, reason: o.reason),
                          );
                      final verb = context.tr(reassign ? 'reassigned to' : 'assigned to');
                      final r = reason != null ? ' · ${context.tr(reason!)}' : '';
                      ref.read(actionsProvider).toast('${f.id} $verb $choice$r · ${context.tr('Response SLA running')}');
                      Navigator.of(context).pop();
                    },
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _row(BuildContext context, TeamMember m, bool suggested, bool isCurrent) {
    final t = context.tk;
    final selected = choice == m.name;
    return Opacity(
      opacity: isCurrent ? 0.5 : 1,
      child: Tap(
        onTap: isCurrent ? null : () => setState(() => choice = m.name),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? AppTokens.chipActiveBg : t.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? t.yellow : t.line),
          ),
          child: Row(children: [
            Avatar(m.initials, size: 34),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text(m.name, overflow: TextOverflow.ellipsis, style: ts(12, weight: FontWeight.w600))),
                  if (suggested || isCurrent) ...[
                    const SizedBox(width: 8),
                    RoleBadge(isCurrent ? 'Current' : 'Suggested'),
                  ],
                ]),
                const SizedBox(height: 3),
                Text('${context.tr(m.zone)}${m.fit ? '' : ' · ${context.tr('Outside zone')}'}',
                    style: ts(10, color: t.muted2)),
              ]),
            ),
            Text('${m.active} ${context.tr('active')} / ${m.overdue} ${context.tr('overdue')}',
                style: ts(10, color: m.overdue > 0 ? t.coral : t.muted)),
            const SizedBox(width: 14),
            StatusPill(m.shift, tone: m.shift == 'On shift' ? Tone.ready : Tone.muted),
          ]),
        ),
      ),
    );
  }
}

class FacilityControlDialog extends ConsumerStatefulWidget {
  const FacilityControlDialog({super.key, required this.facility, required this.close});
  final Facility facility;
  final bool close;
  @override
  ConsumerState<FacilityControlDialog> createState() => _FacilityControlDialogState();
}

class _FacilityControlDialogState extends ConsumerState<FacilityControlDialog> {
  final reason = TextEditingController();
  final expected = TextEditingController();
  String? error;

  @override
  void dispose() {
    reason.dispose();
    expected.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    final f = widget.facility;
    final close = widget.close;
    final offline = f.deviceStatus == 'Offline';
    return Padding(
      padding: const EdgeInsets.all(28),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Eyebrow(close ? 'CLOSE FACILITY' : 'RESTORE FACILITY')),
            IconBtn(Icons.close, size: 32, onTap: () => Navigator.of(context).pop()),
          ]),
          const SizedBox(height: 6),
          Text(
              close
                  ? '${context.tr('Take')} ${f.id} ${context.tr('out of service?')}'
                  : '${context.tr('Restore')} ${f.id} ${context.tr('to service?')}',
              style: ts(22, weight: FontWeight.w500)),
          const SizedBox(height: 10),
          if (close) ...[
            Text(
                context.isArabic
                    ? context.tr('Members won\'t be directed to this facility.')
                    : "Members won't be directed to this facility. Open tasks linked to ${f.id} are paused by supervisor, and their SLA timers show \"Paused by supervisor\".",
                style: ts(11, color: t.muted, height: 1.5)),
            const SizedBox(height: 20),
            const FieldLabel('Reason (required)'),
            AppTextField(
              controller: reason,
              placeholder: 'e.g. Damaged fitting',
              error: error,
              onChanged: (_) {
                if (error != null) setState(() => error = null);
              },
            ),
            const SizedBox(height: 16),
            const FieldLabel('Expected restoration (optional)'),
            AppTextField(controller: expected, placeholder: 'e.g. Today · 14:00'),
          ] else ...[
            const SizedBox(height: 10),
            Panel(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                T('Resulting status', style: ts(10, color: t.muted)),
                const Spacer(),
                StatusPill(offline ? 'Unverified · Device offline' : 'Service Required · inspection before Ready',
                    tone: offline ? Tone.muted : Tone.attention),
              ]),
            ),
            const SizedBox(height: 12),
            T('Facilities are never marked Ready until service is verified and the device is online.',
                style: ts(10, color: t.muted2, height: 1.5)),
          ],
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            AppButton(label: 'Cancel', onPressed: () => Navigator.of(context).pop()),
            const SizedBox(width: 8),
            if (close)
              AppButton(
                label: 'Close facility',
                kind: BtnKind.danger,
                onPressed: () {
                  if (reason.text.trim().isEmpty) {
                    setState(() => error = 'Add a reason to close the facility.');
                    return;
                  }
                  final r = expected.text.trim().isEmpty
                      ? reason.text.trim()
                      : '${reason.text.trim()} · ${context.tr('expected')} ${expected.text.trim()}';
                  ref.read(ownershipProvider.notifier).modify(f.id, (o) => Ownership(
                      assignee: o.assignee, taskStatus: o.taskStatus, closed: true, restored: false, reason: r));
                  ref.read(actionsProvider).toast('${f.id} ${context.tr('is out of service')}');
                  Navigator.of(context).pop();
                },
              )
            else
              AppButton(
                label: 'Restore',
                kind: BtnKind.primary,
                onPressed: () {
                  ref.read(ownershipProvider.notifier).modify(f.id, (o) => Ownership(
                      assignee: o.assignee, taskStatus: o.taskStatus, closed: false, restored: true));
                  ref.read(actionsProvider).toast('${f.id} ${context.tr('restored · awaiting inspection')}');
                  Navigator.of(context).pop();
                },
              ),
          ]),
        ]),
      ),
    );
  }
}
