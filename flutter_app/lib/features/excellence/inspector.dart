import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../l10n/tr.dart';
import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import 'dialogs.dart';

enum _View { facility, device, history }

class Inspector extends ConsumerStatefulWidget {
  const Inspector({super.key, required this.facility, required this.role, required this.onClose});
  final Facility facility;
  final Role role;
  final VoidCallback onClose;

  @override
  ConsumerState<Inspector> createState() => _InspectorState();
}

class _InspectorState extends ConsumerState<Inspector> {
  _View view = _View.facility;

  @override
  void didUpdateWidget(covariant Inspector old) {
    super.didUpdateWidget(old);
    if (old.facility.id != widget.facility.id) view = _View.facility;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    return Container(
      width: 304,
      decoration: BoxDecoration(
        color: t.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.line),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 24)],
      ),
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: switch (view) {
          _View.facility => _facility(context),
          _View.device => _device(context),
          _View.history => _history(context),
        },
      ),
    );
  }

  Widget _kv(String k, String v, {Color? color, VoidCallback? onTap, Widget? valueWidget}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 100, child: T(k, style: ts(10, color: kTokens.muted2))),
          Expanded(
            child: valueWidget ??
                Tap(
                  onTap: onTap,
                  child: Text(context.tr(v),
                      style: ts(10, color: color ?? (onTap != null ? kTokens.yellow : kTokens.ivory), weight: FontWeight.w500)),
                ),
          ),
        ]),
      );

  Widget _head(String eyebrow, {VoidCallback? back}) => Row(children: [
        if (back != null) ...[
          LinkButton('← Facility', color: kTokens.muted, onTap: back),
          const SizedBox(width: 10),
        ],
        Expanded(child: Eyebrow(eyebrow)),
        IconBtn(Icons.close, size: 28, iconSize: 14, onTap: widget.onClose),
      ]);

  String _taskName(Facility f) {
    if (f.type == 'Shower') return 'Clean Shower ${f.id}';
    if (f.isBin) return 'Empty Bin ${f.id}';
    return 'Clean Toilet ${f.id}';
  }

  Widget _facility(BuildContext context) {
    final t = context.tk;
    final f = widget.facility;
    final fill = f.status.contains('%') ? f.status : '34%';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _head('SELECTED FACILITY'),
      const SizedBox(height: 8),
      Text(f.id, style: ts(27, weight: FontWeight.w500)),
      const SizedBox(height: 4),
      Text('${context.tr(f.type)} · ${context.tr(f.zone)}', style: ts(11, color: t.muted)),
      const SizedBox(height: 10),
      StatusPill(f.status, tone: f.tone),
      if (f.detail != null) ...[
        const SizedBox(height: 4),
        T(f.detail!, style: ts(9, color: t.muted2)),
      ],
      const SizedBox(height: 14),
      Divider(height: 1, color: t.lineSoft),
      const SizedBox(height: 6),
      if (f.isBin) _kv('Fill level', fill) else _kv('Occupancy', f.occupancy ?? 'Not monitored'),
      _kv('Device', '${f.deviceId} · ${context.tr(f.deviceStatus ?? 'Unknown')}',
          onTap: () => setState(() => view = _View.device)),
      _kv('Latest Event', f.lastEvent ?? '—'),
      _kv('Assigned To', f.assigned ?? 'Unassigned'),
      if (f.taskStatus != null) ...[
        _kv('Linked Task', _taskName(f)),
        _kv('Task Status', '',
            valueWidget: StatusPill(f.taskStatus!, tone: f.taskStatus == 'Accepted' ? Tone.ready : Tone.cleaning)),
        _kv('Response', f.taskStatus == 'Unassigned' ? 'Response due in 00:42' : 'Accepted in 00:32',
            color: f.taskStatus == 'Unassigned' ? t.yellow : null),
        _kv('Completion', f.id == 'WC-02' ? 'SLA breach in 02:10' : 'Completion due in 06:30'),
      ],
      const SizedBox(height: 16),
      if (widget.role == Role.supervisor) _supActions(context) else _dmActions(context),
    ]);
  }

  Widget _dmActions(BuildContext context) {
    final f = widget.facility;
    final a = ref.read(actionsProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (f.status != 'Ready') ...[
        AppButton(
          label: 'Open Task',
          trailingIcon: Icons.arrow_forward,
          kind: BtnKind.primary,
          expand: true,
          onPressed: () => a.openTask(taskIdFor(f.id)),
        ),
        const SizedBox(height: 8),
      ],
      AppButton(label: 'View Service History', expand: true, onPressed: () => setState(() => view = _View.history)),
      const SizedBox(height: 8),
      AppButton(label: 'View Device', kind: BtnKind.ghost, expand: true, onPressed: () => setState(() => view = _View.device)),
    ]);
  }

  Widget _supActions(BuildContext context) {
    final t = context.tk;
    final f = widget.facility;
    final own = ref.watch(ownershipProvider)[f.id];
    final a = ref.read(actionsProvider);
    final closed = own?.closed == true;
    final restored = own?.restored == true;

    String? primary;
    VoidCallback? onPrimary;
    String secondary = 'View Service History';
    VoidCallback onSecondary = () => setState(() => view = _View.history);
    IconData? primaryIcon;

    if (closed) {
      primary = 'Restore facility';
      onPrimary = () => openFacilityControl(context, f, close: false);
    } else if (restored) {
      primary = 'Inspect';
      onPrimary = () => a.navigate(AppPage.quality);
    } else if (f.taskStatus == 'Unassigned') {
      primary = 'Assign';
      onPrimary = () => openAssignDialog(context, f);
    } else if (f.taskStatus == 'Blocked') {
      primary = 'Follow up';
      onPrimary = () => a.navigate(AppPage.issues);
      secondary = 'Reassign';
      onSecondary = () => openAssignDialog(context, f);
    } else if (f.assigned != null) {
      primary = 'Open Task';
      primaryIcon = Icons.arrow_forward;
      onPrimary = () => a.openTask(taskIdFor(f.id));
      secondary = 'Reassign';
      onSecondary = () => openAssignDialog(context, f);
    } else if ((f.lastEvent ?? '').startsWith('Service completed')) {
      primary = 'Inspect';
      onPrimary = () => a.navigate(AppPage.quality);
    } else if (f.deviceStatus == 'Offline') {
      primary = 'Create manual task';
      onPrimary = () => a.navigate(AppPage.tasks);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (primary != null) ...[
        AppButton(label: primary, kind: BtnKind.primary, expand: true, trailingIcon: primaryIcon, onPressed: onPrimary),
        const SizedBox(height: 8),
      ],
      AppButton(label: secondary, expand: true, onPressed: onSecondary),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.only(top: 10),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: t.lineSoft))),
        child: Row(children: [
          Expanded(child: T('Facility controls', style: ts(10, color: t.muted2))),
          PopupMenuButton<String>(
            tooltip: '',
            color: t.surface3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: t.line)),
            onSelected: (v) => openFacilityControl(context, f, close: v == 'close'),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: closed ? 'restore' : 'close',
                height: 36,
                child: T(closed ? 'Restore facility' : 'Close facility',
                    style: ts(11, color: closed ? t.ivory : t.coral)),
              ),
            ],
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: t.line),
              ),
              child: Icon(Icons.more_horiz, size: 16, color: t.muted),
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _device(BuildContext context) {
    final t = context.tk;
    final f = widget.facility;
    final st = f.deviceStatus ?? 'Unknown';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _head('ASSOCIATED DEVICE', back: () => setState(() => view = _View.facility)),
      const SizedBox(height: 10),
      Text(f.deviceId ?? '—', style: ts(22, weight: FontWeight.w500)),
      const SizedBox(height: 8),
      StatusPill(st, tone: st == 'Offline' ? Tone.critical : (st == 'Delayed' ? Tone.attention : Tone.ready)),
      const SizedBox(height: 14),
      _kv('Device type', f.isBin ? 'Fill sensor' : 'Occupancy sensor'),
      _kv('Connected facility', f.id),
      _kv('Last update', '10:26 · Now'),
      _kv('Last event', f.lastEvent ?? '—'),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: t.cyan.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: t.cyan.withOpacity(0.3)),
        ),
        child: T('Monitoring is operating normally. Device details are shown only to support service decisions.',
            style: ts(10, color: t.cyan, height: 1.5)),
      ),
      const SizedBox(height: 14),
      SizedBox(
        width: double.infinity,
        child: AppButton(label: 'Back to Facility', expand: true, onPressed: () => setState(() => view = _View.facility)),
      ),
    ]);
  }

  Widget _history(BuildContext context) {
    final t = context.tk;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _head('SERVICE HISTORY', back: () => setState(() => view = _View.facility)),
      const SizedBox(height: 10),
      T('Recent service', style: ts(18, weight: FontWeight.w500)),
      const SizedBox(height: 12),
      for (final h in const [
        ('Today · 09:42', 'Service completed', 'Sara Omar'),
        ('Yesterday · 18:16', 'Routine cleaning', 'M. Khalid'),
        ('23 Jun · 12:08', 'Inspection passed', 'N. Faisal'),
      ])
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: t.lineSoft))),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                T(h.$2, style: ts(11, weight: FontWeight.w500)),
                const SizedBox(height: 3),
                T(h.$1, style: ts(9, color: t.muted2)),
              ]),
            ),
            T(h.$3, style: ts(10, color: t.muted)),
          ]),
        ),
    ]);
  }
}
