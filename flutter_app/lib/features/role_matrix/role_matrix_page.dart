import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../l10n/tr.dart';
import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';

/// Cell text plus optional "To confirm" tag and denied styling.
typedef _Cell = ({String text, bool confirm, bool denied});

_Cell _c(String text, {bool confirm = false, bool denied = false}) =>
    (text: text, confirm: confirm, denied: denied);

final _nav = <(String, String, _Cell)>[
  ('Excellence Center', 'Full', _c('Full (actions in own zones)')),
  ('Tasks', 'Full', _c('Dispatch Board (own team / zones)')),
  ('Schedule', 'Full', _c('Shift Planner (own zones)', confirm: true)),
  ('Team', 'Full', _c('Crew Board (own team)')),
  ('Quality', 'Full', _c('Inspection Mode')),
  ('Issues', 'Full', _c('Triage Inbox')),
  ('Reports', 'Full', _c('Shift Summary, view only', confirm: true)),
  ('Settings', 'Per config', _c('Hidden (not available)', denied: true)),
];

final _actions = <(String, _Cell)>[
  ('View facility detail', _c('Yes')),
  ('Create manual task', _c('Yes', confirm: true)),
  ('Assign / Reassign', _c('Yes (own team)')),
  ('Cancel task', _c('Yes, reason required')),
  ('Redistribute work', _c('Yes')),
  ('Run inspection, Pass / Fail', _c('Yes')),
  ('Create rework (via Fail)', _c('Yes (automatic, linked)')),
  ('Update issue status', _c('Yes')),
  ('Close / Restore facility', _c('Yes (authorized)')),
  (
    'Edit SLA, thresholds, devices, users, SOPs',
    _c('No (administrator only)', denied: true)
  ),
  (
    'View live employee location',
    _c('Never (assigned zone only)', denied: true)
  ),
  ('Act outside own zones', _c('View only', confirm: true)),
  ('Command bar (Ctrl / Cmd + K)', _c('Search + quick actions', confirm: true)),
];

const _paradigm = [
  ('Job', 'Oversee, analyze, configure', 'Run the shift, act now'),
  ('Mental model', 'Management console', 'Shift command workbench'),
  ('Time', 'Periods, trends, history', 'Now → next 8 hours'),
  ('Primary object', 'Tables, forms, reports', 'Boards, lanes, queues'),
  ('Interaction', 'Filter → open → edit', 'See → drag / tap → resolve'),
  ('Density', 'High-density, analytical', 'Spacious, action-first'),
  ('Pages feel like', 'Data & configuration', 'Dispatch & decisions'),
  ('Settings', 'Yes (admin)', 'None'),
];

const _principles = [
  (
    'Role comes from the account',
    'Nobody picks a role at login. The Staff ID decides it. Demo chips only prefill example credentials and are not part of production.'
  ),
  (
    'Hidden, not disabled',
    "Navigation a role can't use isn't shown. Actions a role can't take aren't rendered."
  ),
  (
    'No dead ends',
    'Deep links into a restricted area show which role can act and offer a way back.'
  ),
  (
    'View only outside own zones',
    'Whole-club visibility with actions limited to own zones, marked with a quiet label. To confirm.'
  ),
  (
    'Supervisor principles',
    'Action over information · ownership visible · time is spatial · every drag has a button · tables are secondary · no configuration · one job at a time.'
  ),
];

class RoleMatrixPage extends ConsumerWidget {
  const RoleMatrixPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tk;
    final role = ref.watch(authProvider) ?? Role.dutyManager;

    Widget cell(_Cell c) => Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              T(c.text, style: ts(11, color: c.denied ? t.muted2 : t.ivory)),
              if (c.confirm) const DashedTag('To confirm'),
            ]);

    Widget table(List<String> headers, List<List<Widget>> rows) {
      final hs = ts(9, color: t.muted2, weight: FontWeight.w700, spacing: 1);
      Widget line(List<Widget> cells) => Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: t.lineSoft))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (var i = 0; i < cells.length; i++)
                Expanded(
                  flex: i == 0 ? 3 : (cells.length == 2 ? 2 : 2),
                  child: Padding(
                      padding: const EdgeInsetsDirectional.only(end: 12),
                      child: cells[i]),
                ),
            ]),
          );
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        line([for (final h in headers) T(h, style: hs)]),
        for (final r in rows) line(r),
      ]);
    }

    final paradigm = Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SectionHead(
          eyebrow: 'ROLE PARADIGMS',
          title: 'Same language, different workspace',
          trailing: StatusPill(
              '${context.tr('Signed in as')} ${context.tr(role.label)}',
              tone: Tone.ready,
              translate: false),
        ),
        const SizedBox(height: 20),
        Row(children: [
          const Expanded(flex: 2, child: SizedBox()),
          Expanded(
              flex: 3,
              child: T('Duty Manager / Admin',
                  style: ts(11, weight: FontWeight.w700))),
          Expanded(
              flex: 3,
              child: T('Supervisor',
                  style: ts(11, weight: FontWeight.w700, color: t.yellow))),
        ]),
        for (final p in _paradigm)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
                border: Border(top: BorderSide(color: t.lineSoft))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 2, child: T(p.$1, style: ts(10, color: t.muted2))),
              Expanded(flex: 3, child: T(p.$2, style: ts(11, color: t.muted))),
              Expanded(flex: 3, child: T(p.$3, style: ts(11))),
            ]),
          ),
      ]),
    );

    final navPanel = Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SectionHead(eyebrow: 'NAVIGATION ACCESS', title: 'Menu by role'),
        const SizedBox(height: 16),
        table(const [
          'MENU',
          'DUTY MANAGER',
          'SUPERVISOR'
        ], [
          for (final n in _nav)
            [
              T(n.$1, style: ts(11)),
              T(n.$2, style: ts(11, color: t.muted)),
              cell(n.$3)
            ],
        ]),
      ]),
    );

    final actionsPanel = Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SectionHead(eyebrow: 'KEY ACTIONS', title: 'Supervisor actions'),
        const SizedBox(height: 16),
        table(const [
          'ACTION',
          'SUPERVISOR'
        ], [
          for (final a in _actions) [T(a.$1, style: ts(11)), cell(a.$2)],
        ]),
      ]),
    );

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      paradigm,
      const SizedBox(height: 24),
      SpanRow(spans: const [1, 1], children: [navPanel, actionsPanel]),
      const SizedBox(height: 24),
      LayoutBuilder(builder: (context, c) {
        final cols = c.maxWidth > 1100 ? 5 : (c.maxWidth > 700 ? 3 : 1);
        final w = (c.maxWidth - (cols - 1) * 16) / cols;
        return Wrap(spacing: 16, runSpacing: 16, children: [
          for (final p in _principles)
            SizedBox(
              width: w,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: t.line),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      T(p.$1, style: ts(12, weight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      T(p.$2, style: ts(10, color: t.muted, height: 1.5)),
                    ]),
              ),
            ),
        ]);
      }),
    ]);
  }
}
