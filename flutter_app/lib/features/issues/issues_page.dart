import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../l10n/tr.dart';
import '../../shell/page_intro.dart';
import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/detail_drawer.dart';

class IssuesPage extends ConsumerStatefulWidget {
  const IssuesPage({super.key});
  @override
  ConsumerState<IssuesPage> createState() => _IssuesPageState();
}

class _IssuesPageState extends ConsumerState<IssuesPage> {
  String chip = 'All issues 14';
  String severity = 'All Severities';
  bool filters = false;

  static const chips = [
    'All issues 14',
    'Open 3',
    'In Progress 2',
    'Blocked 1',
    'Resolved 8'
  ];
  static const issues = [
    (
      'ISS-203',
      'Leakage',
      'Shower SH-09',
      'High',
      'Open',
      '11 min ago',
      'Facilities Team'
    ),
    (
      'ISS-202',
      'Damaged fitting',
      'Changing Room B',
      'Medium',
      'In Progress',
      '42 min ago',
      'M. Khalid'
    ),
    (
      'ISS-201',
      'Missing supplies',
      'Lounge',
      'Low',
      'Resolved',
      '1h 18m ago',
      'Sara Omar'
    ),
    (
      'ISS-198',
      'Facility fault',
      'Pool shower',
      'High',
      'Blocked',
      '2h 06m ago',
      'Maintenance'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    final status = chip.replaceAll(RegExp(r'\s*\d+$'), '');
    final list = issues.where((i) {
      if (status != 'All issues' && i.$5 != status) return false;
      if (severity != 'All Severities' && i.$4 != severity) return false;
      return true;
    }).toList();
    final role = ref.watch(authProvider);
    final readOnly = role == Role.executive;
    // Supervisor / Executive on mobile: compact record cards keep every field.
    final cards = role != null && MediaQuery.sizeOf(context).width < 768;
    Tone sevTone(String v) => v == 'High'
        ? Tone.critical
        : (v == 'Medium' ? Tone.attention : Tone.muted);
    Tone statTone(String v) => v == 'Resolved'
        ? Tone.ready
        : (v == 'Blocked' ? Tone.critical : Tone.cleaning);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PageIntro(page: AppPage.issues, actions: [
        AppButton(
            label: 'Filters',
            icon: Icons.filter_list,
            onPressed: () => setState(() => filters = !filters)),
        if (!readOnly)
          AppButton(
            label: 'Report Issue',
            icon: Icons.add,
            kind: BtnKind.primary,
            onPressed: () => openDetail(context, 'Issue Detail', 'New Issue'),
          ),
      ]),
      if (filters) ...[
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: AppDropdown(
            label: 'SEVERITY',
            value: severity,
            options: const ['All Severities', 'High', 'Medium', 'Low'],
            onChanged: (v) => setState(() => severity = v),
          ),
        ),
        const SizedBox(height: 16),
      ],
      if (severity != 'All Severities') ...[
        Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              T('Active filters', style: ts(12, color: t.muted2)),
              StatusPill(severity, tone: sevTone(severity)),
              LinkButton('Reset filters',
                  onTap: () => setState(() => severity = 'All Severities')),
            ]),
        const SizedBox(height: 16),
      ],
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final c in chips)
          AppChip(
            label:
                '${context.tr(c.replaceAll(RegExp(r'\s*\d+$'), ''))} ${RegExp(r'\d+$').stringMatch(c) ?? ''}',
            translate: false,
            active: chip == c,
            onTap: () => setState(() => chip = c),
          ),
      ]),
      const SizedBox(height: 16),
      Panel(
        padding: EdgeInsets.zero,
        child: list.isEmpty
            ? const EmptyState(title: 'No issues match these filters.')
            : Column(children: [
                for (final i in list)
                  if (cards)
                    Tap(
                      onTap: () => openDetail(context, 'Issue Detail', i.$1),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            border:
                                Border(bottom: BorderSide(color: t.lineSoft))),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Expanded(
                                    child: Text('${i.$1} · ${context.tr(i.$2)}',
                                        style: ts(14,
                                            weight: FontWeight.w600,
                                            height: 1.3))),
                                DirIcon(Icons.chevron_right,
                                    size: 18, color: t.muted2),
                              ]),
                              const SizedBox(height: 4),
                              T(i.$3,
                                  style: ts(13, color: t.muted, height: 1.5)),
                              const SizedBox(height: 8),
                              Wrap(spacing: 8, runSpacing: 8, children: [
                                StatusPill(i.$4, tone: sevTone(i.$4)),
                                StatusPill(i.$5, tone: statTone(i.$5)),
                              ]),
                              const SizedBox(height: 8),
                              Wrap(spacing: 16, runSpacing: 4, children: [
                                Text('${context.tr('Owner')}: ${i.$7}',
                                    style: ts(12, color: t.muted2)),
                                Text(context.tr(i.$6),
                                    style: ts(12, color: t.muted2)),
                              ]),
                            ]),
                      ),
                    )
                  else
                    Tap(
                      onTap: () => openDetail(context, 'Issue Detail', i.$1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                            border:
                                Border(bottom: BorderSide(color: t.lineSoft))),
                        child: Row(children: [
                          SizedBox(
                            width: 80,
                            child: StatusPill(i.$4,
                                tone: i.$4 == 'High'
                                    ? Tone.critical
                                    : (i.$4 == 'Medium'
                                        ? Tone.attention
                                        : Tone.muted)),
                          ),
                          Expanded(
                            flex: 3,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${i.$1} · ${context.tr(i.$2)}',
                                      style: ts(12, weight: FontWeight.w600)),
                                  const SizedBox(height: 3),
                                  T(i.$3, style: ts(10, color: t.muted2)),
                                ]),
                          ),
                          _col(
                              context,
                              'STATUS',
                              StatusPill(i.$5,
                                  tone: i.$5 == 'Resolved'
                                      ? Tone.ready
                                      : (i.$5 == 'Blocked'
                                          ? Tone.critical
                                          : Tone.cleaning))),
                          _col(context, 'REPORTED', T(i.$6, style: ts(11))),
                          _col(context, 'OWNER', T(i.$7, style: ts(11))),
                          DirIcon(Icons.chevron_right,
                              size: 16, color: t.muted2),
                        ]),
                      ),
                    ),
              ]),
      ),
    ]);
  }

  Widget _col(BuildContext context, String label, Widget child) => Expanded(
        flex: 2,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Eyebrow(label),
          const SizedBox(height: 4),
          child,
        ]),
      );
}
