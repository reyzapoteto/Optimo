import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models.dart';
import '../l10n/tr.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';

class ShiftPulseBar extends ConsumerWidget {
  const ShiftPulseBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tk;
    final own = ref.watch(ownershipProvider);
    final unassigned =
        own.values.where((o) => o.taskStatus == 'Unassigned').length + 1;
    final closed = own.values.where((o) => o.closed).length;
    final chips = <(String, int, IconData, Tone, AppPage)>[
      (
        'Unassigned',
        unassigned,
        pageIcon(AppPage.tasks),
        Tone.attention,
        AppPage.tasks
      ),
      ('Breaching soon', 1, Icons.error_outline, Tone.critical, AppPage.tasks),
      ('Blocked', 1, pageIcon(AppPage.issues), Tone.critical, AppPage.issues),
      (
        'Inspections due',
        2,
        pageIcon(AppPage.quality),
        Tone.cleaning,
        AppPage.quality
      ),
      (
        'Out of service',
        closed,
        Icons.lock_outline,
        Tone.critical,
        AppPage.issues
      ),
    ].where((c) => c.$2 > 0).toList();
    final actions = ref.read(actionsProvider);
    return Container(
      height: 48,
      padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.sizeOf(context).width < 768
              ? 16
              : (MediaQuery.sizeOf(context).width < 1440 ? 24 : 32)),
      decoration: BoxDecoration(
          color: t.sidebar,
          border: Border(bottom: BorderSide(color: t.lineSoft))),
      child: Row(children: [
        const Eyebrow('SHIFT PULSE'),
        const SizedBox(width: 16),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              if (chips.isEmpty)
                Row(children: [
                  Dot(t.green),
                  const SizedBox(width: 8),
                  T('Shift on track',
                      style: ts(10, color: t.green, weight: FontWeight.w600)),
                ])
              else
                for (final c in chips)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: Tap(
                      onTap: () => actions.navigate(c.$5),
                      child: Container(
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: t.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: t.line),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(c.$3, size: 13, color: toneColor(c.$4)),
                          const SizedBox(width: 6),
                          Text('${c.$2}',
                              style: ts(11,
                                  color: toneColor(c.$4),
                                  weight: FontWeight.w700)),
                          const SizedBox(width: 6),
                          T(c.$1, style: ts(10, color: t.muted)),
                        ]),
                      ),
                    ),
                  ),
            ]),
          ),
        ),
        Dot(t.green),
        const SizedBox(width: 8),
        Text(context.tr('Live · synced now'), style: ts(9, color: t.muted)),
      ]),
    );
  }
}
