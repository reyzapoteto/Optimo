import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/tr.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';

class SupToast {
  const SupToast(this.id, this.facility, this.title, this.time, this.tone);
  final String id, facility, title, time;
  final Tone tone;
}

final supToastsProvider = StateProvider<List<SupToast>>((ref) => const []);

/// Schedules the demo toasts once per app session (6s and 14s after first Supervisor shell).
final _supToastScheduler = Provider<void>((ref) {
  void push(SupToast t) {
    final n = ref.read(supToastsProvider.notifier);
    final next = [...n.state.where((e) => e.id != t.id), t];
    n.state = next.length > 3 ? next.sublist(next.length - 3) : next;
  }

  final timers = <Timer>[
    Timer(const Duration(seconds: 6), () {
      push(const SupToast('t1', 'SH-05', 'Shower requires cleaning',
          'Response due in 03:10', Tone.attention));
    }),
    Timer(const Duration(seconds: 14), () {
      push(const SupToast(
          't2', 'SH-06', 'Leak alert', 'Detected now', Tone.critical));
    }),
  ];
  ref.onDispose(() {
    for (final t in timers) {
      t.cancel();
    }
  });
});

class SupervisorToasts extends ConsumerWidget {
  const SupervisorToasts({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(_supToastScheduler);
    ref.watch(supToastAutoDismiss);
    final toasts = ref.watch(supToastsProvider);
    final t = context.tk;
    if (toasts.isEmpty) return const SizedBox.shrink();
    void dismiss(String id) => ref.read(supToastsProvider.notifier).state =
        ref.read(supToastsProvider).where((e) => e.id != id).toList();
    return PositionedDirectional(
      top: 24,
      end: 24,
      width: 360,
      child: Column(children: [
        for (final toast in toasts)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: t.surface3,
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                    color: toast.tone == Tone.critical ? t.coral : t.line),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.error_outline,
                          size: 18, color: toneColor(toast.tone)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              T(toast.title,
                                  style: ts(13, weight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              Text(
                                  '${toast.facility} · ${context.tr(toast.time)}',
                                  style: ts(12, color: t.muted)),
                            ]),
                      ),
                      LinkButton('View', onTap: () {
                        dismiss(toast.id);
                        ref.read(actionsProvider).openFacility(
                            toast.facility == 'SH-06'
                                ? 'SH-04'
                                : toast.facility);
                      }),
                      const SizedBox(width: 8),
                      IconBtn(Icons.close,
                          size: 24,
                          iconSize: 14,
                          bordered: false,
                          onTap: () => dismiss(toast.id)),
                    ]),
              ),
            ),
          ),
      ]),
    );
  }
}

/// Auto-dismiss t1 after 8s: handled by watching the list.
final supToastAutoDismiss = Provider<void>((ref) {
  Timer? timer;
  ref.listen<List<SupToast>>(supToastsProvider, (prev, next) {
    final added = next.any((e) => e.id == 't1') &&
        !(prev ?? const []).any((e) => e.id == 't1');
    if (added) {
      timer?.cancel();
      timer = Timer(const Duration(seconds: 8), () {
        final n = ref.read(supToastsProvider.notifier);
        n.state = n.state.where((e) => e.id != 't1').toList();
      });
    }
  });
  ref.onDispose(() => timer?.cancel());
});
