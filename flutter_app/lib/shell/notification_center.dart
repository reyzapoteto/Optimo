import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models.dart';
import '../l10n/tr.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';

class SupNotification {
  const SupNotification(this.id, this.facility, this.title, this.time, this.group, this.action, this.tone);
  final String id, facility, title, time, group;
  final String? action;
  final Tone tone;
}

const supNotifications = <SupNotification>[
  SupNotification('n1', 'SH-04', 'Unassigned task · T-1042', 'Response due in 00:42', 'Today', 'Assign now', Tone.attention),
  SupNotification('n2', 'WC-02', 'SLA approaching · T-1036', 'SLA breach in 02:10', 'Today', 'Open task', Tone.attention),
  SupNotification('n3', 'SH-06', 'Leak alert · near SH-06', 'Detected 10:16 · 8 min ago', 'Today', 'Open issue', Tone.critical),
  SupNotification('n4', 'INSP-210', 'Inspection due · SH-01', 'Due by 11:00', 'Today', 'Inspect', Tone.cleaning),
  SupNotification('n5', 'BIN-02', 'Device restored · BIN-02 sensor', 'Reconnected 09:40', 'Earlier', null, Tone.ready),
  SupNotification('n6', 'SH-02', 'Rework completed · T-1044', 'Completed 09:12', 'Earlier', null, Tone.ready),
];

final supReadProvider = StateProvider<Set<String>>((ref) => {'n5', 'n6'});
final supSoundProvider = StateProvider<bool>((ref) => false);

Future<void> openNotificationCenter(BuildContext context) =>
    showSideDrawer(context, width: 420, builder: (_) => const NotificationCenter());

class NotificationCenter extends ConsumerStatefulWidget {
  const NotificationCenter({super.key});
  @override
  ConsumerState<NotificationCenter> createState() => _NotificationCenterState();
}

class _NotificationCenterState extends ConsumerState<NotificationCenter> {
  String tab = 'All';

  void _markRead(String id) => ref.read(supReadProvider.notifier).state = {...ref.read(supReadProvider), id};

  void _act(SupNotification n) {
    _markRead(n.id);
    Navigator.of(context).pop();
    final a = ref.read(actionsProvider);
    final target = n.id == 'n3' ? 'ISS-SH06' : n.facility;
    if (target.startsWith('ISS')) {
      a.navigate(AppPage.issues);
    } else if (target.startsWith('INSP')) {
      a.navigate(AppPage.quality);
    } else {
      a.openFacility(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    final read = ref.watch(supReadProvider);
    final sound = ref.watch(supSoundProvider);
    final unread = supNotifications.where((n) => !read.contains(n.id)).length;
    final list = supNotifications.where((n) {
      if (tab == 'Unread') return !read.contains(n.id);
      if (tab == 'Needs action') return n.action != null;
      return true;
    }).toList();

    Widget tabBtn(String label) {
      final a = tab == label;
      return Tap(
        onTap: () => setState(() => tab = label),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: a ? AppTokens.chipActiveBg : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: a ? t.yellow : t.line),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            T(label, style: ts(10, color: a ? t.ivory : t.muted, weight: FontWeight.w600)),
            if (label == 'Unread' && unread > 0) ...[
              const SizedBox(width: 6),
              Text('$unread', style: ts(10, color: t.yellow, weight: FontWeight.w700)),
            ],
          ]),
        ),
      );
    }

    final groups = <String, List<SupNotification>>{};
    for (final n in list) {
      groups.putIfAbsent(n.group, () => []).add(n);
    }

    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.of(context).pop()},
      child: Focus(
        autofocus: true,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(children: [
              Expanded(child: T('Notifications', style: ts(18, weight: FontWeight.w500))),
              IconBtn(Icons.close, size: 32, onTap: () => Navigator.of(context).pop()),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Wrap(spacing: 8, children: [tabBtn('All'), tabBtn('Unread'), tabBtn('Needs action')]),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: list.isEmpty
                ? Center(child: T("You're all caught up.", style: ts(12, color: t.muted)))
                : ListView(padding: const EdgeInsets.symmetric(horizontal: 24), children: [
                    for (final g in groups.entries) ...[
                      Padding(padding: const EdgeInsets.only(top: 14, bottom: 6), child: Eyebrow(g.key.toUpperCase())),
                      for (final n in g.value) _item(context, n, read.contains(n.id)),
                    ],
                  ]),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: t.line))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                AppButton(
                  label: 'Mark all read',
                  compact: true,
                  onPressed: () =>
                      ref.read(supReadProvider.notifier).state = {for (final n in supNotifications) n.id},
                ),
                const Spacer(),
                Tap(
                  onTap: () => ref.read(supSoundProvider.notifier).state = !sound,
                  child: Row(children: [
                    Icon(sound ? Icons.check_box : Icons.check_box_outline_blank, size: 16, color: t.muted),
                    const SizedBox(width: 6),
                    T(sound ? 'Sound on' : 'Sound off', style: ts(10, color: t.muted)),
                    const SizedBox(width: 6),
                    const DashedTag('To confirm'),
                  ]),
                ),
              ]),
              const SizedBox(height: 12),
              T('Reading a notification does not assign or accept anything.', style: ts(9, color: t.muted2)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _item(BuildContext context, SupNotification n, bool isRead) {
    final t = context.tk;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: t.lineSoft))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(top: 4), child: Dot(toneColor(n.tone), size: 8)),
        const SizedBox(width: 12),
        Expanded(
          child: Tap(
            onTap: () => _markRead(n.id),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              T(n.title, style: ts(12, weight: isRead ? FontWeight.w400 : FontWeight.w600, color: isRead ? t.muted : t.ivory)),
              const SizedBox(height: 4),
              Text('${n.facility} · ${context.tr(n.time)}', style: ts(10, color: t.muted2)),
              if (!isRead) ...[
                const SizedBox(height: 4),
                Text(context.tr('Unread').toUpperCase(), style: ts(8, color: t.yellow, weight: FontWeight.w700, spacing: 1)),
              ],
            ]),
          ),
        ),
        if (n.action != null) AppButton(label: n.action!, compact: true, onPressed: () => _act(n)),
      ]),
    );
  }
}
