import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../l10n/tr.dart';
import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/detail_drawer.dart';

const _sections = [
  'Locations & Zones',
  'Users',
  'Roles & Permissions',
  'Facilities & Devices',
  'Operational Thresholds',
  'SLA Rules',
  'Notifications & Alerts',
  'Standard Operating Procedures',
  'Language & Localization',
];

const _standardItems = <String, List<String>>{
  'Locations & Zones': ['Main Club', 'Level 01', 'Changing Rooms', 'Pool & Wet Areas', 'Functional Training'],
  'Users': ['Ahmed Hassan', 'Sara Omar', 'M. Khalid', 'N. Faisal'],
  'Roles & Permissions': ['Duty Manager', 'Operations Manager', 'Supervisor', 'Administrator'],
  'SLA Rules': ['Service Response · 30 min', 'Cleaning Completion · 45 min', 'Critical Issue · 10 min'],
  'Notifications & Alerts': ['Service Required', 'SLA Approaching', 'Device Offline', 'Inspection Failed'],
  'Standard Operating Procedures': ['Shower Service SOP', 'Waste Bin Service SOP', 'Quality Inspection SOP'],
  'Language & Localization': ['English', 'العربية', 'Saudi Arabia · Asia/Riyadh'],
};

const _devices = [
  ('SNS-SH04', 'Occupancy sensor', 'SH-04 · Changing Area A', 'Online', 'Now'),
  ('SNS-WC02', 'Usage sensor', 'WC-02 · Toilet Area', 'Delayed', '6 min ago'),
  ('SNS-BIN02', 'Fill sensor', 'BIN-02 · Vanity Area', 'Online', 'Now'),
  ('SNS-WC03', 'Occupancy sensor', 'WC-03 · Toilet Area', 'Offline', '28 min ago'),
];

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});
  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  String section = _sections.first;
  String query = '';
  String deviceStatus = 'All Statuses';
  final searchCtrl = TextEditingController();
  final thresholdCtrl = TextEditingController(text: '80');
  final toiletCtrl = TextEditingController(text: '18');

  @override
  void dispose() {
    searchCtrl.dispose();
    thresholdCtrl.dispose();
    toiletCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    final aside = SizedBox(
      width: 216,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final s in _sections)
          Tap(
            onTap: () => setState(() => section = s),
            child: Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: s == section ? AppTokens.chipActiveBg : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: s == section ? AppTokens.chipActiveBorder : Colors.transparent),
              ),
              child: Row(children: [
                Expanded(
                  child: T(s,
                      style: ts(11,
                          color: s == section ? t.yellow : t.muted,
                          weight: s == section ? FontWeight.w600 : FontWeight.w400)),
                ),
                DirIcon(Icons.chevron_right, size: 15, color: t.muted2),
              ]),
            ),
          ),
      ]),
    );

    final panel = Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 16,
          runSpacing: 16,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Eyebrow('CONFIGURATION'),
                const SizedBox(height: 6),
                T(section, style: ts(22, weight: FontWeight.w500)),
                const SizedBox(height: 6),
                T('Manage the operational structure and rules used across Main Club.',
                    style: ts(11, color: t.muted)),
              ]),
            ),
            AppButton(
              label: '${context.tr('Add')} ${context.tr(section.split(' ').first)}',
              translate: false,
              kind: BtnKind.primary,
              icon: Icons.add,
              onPressed: () => openDetail(context, 'Settings Detail', 'New $section'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (section == 'Facilities & Devices')
          _devicesView(context)
        else if (section == 'Operational Thresholds')
          _thresholds(context)
        else
          _list(context),
      ]),
    );

    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth < 760) {
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final s in _sections)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 6),
                  child: AppChip(label: s, active: s == section, onTap: () => setState(() => section = s)),
                ),
            ]),
          ),
          const SizedBox(height: 16),
          panel,
        ]);
      }
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        aside,
        const SizedBox(width: 24),
        Expanded(child: panel),
      ]);
    });
  }

  Widget _list(BuildContext context) {
    final t = context.tk;
    final items = _standardItems[section] ?? const <String>[];
    return Column(children: [
      for (var i = 0; i < items.length; i++)
        Tap(
          onTap: () => openDetail(context, 'Settings Detail', items[i]),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: t.lineSoft))),
            child: Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: t.surface2, borderRadius: BorderRadius.circular(8)),
                child: Icon(i == 0 ? pageIcon(AppPage.excellence) : pageIcon(AppPage.settings),
                    size: 16, color: t.muted),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  T(items[i], style: ts(12, weight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(
                    i == 0
                        ? context.tr('Primary club · Riyadh')
                        : '${8 + i * 5} ${context.tr('monitored facilities')}',
                    style: ts(10, color: t.muted2),
                  ),
                ]),
              ),
              const StatusPill('Active', tone: Tone.ready),
              const SizedBox(width: 10),
              IconBtn(Icons.more_horiz, size: 32, iconSize: 16, tooltip: 'More actions', onTap: () {}),
            ]),
          ),
        ),
    ]);
  }

  Widget _devicesView(BuildContext context) {
    final t = context.tk;
    final rows = _devices
        .where((d) => [d.$1, d.$2, d.$3, d.$4, d.$5].join(' ').toLowerCase().contains(query.toLowerCase()))
        .where((d) => deviceStatus == 'All Statuses' || d.$4 == deviceStatus)
        .toList();
    Tone tone(String s) => s == 'Online' ? Tone.ready : (s == 'Offline' ? Tone.critical : Tone.attention);
    Widget row(List<Widget> cells, {bool header = false}) => Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: t.lineSoft))),
          child: Row(children: [
            for (var i = 0; i < cells.length; i++)
              Expanded(flex: i == 2 ? 3 : 2, child: Align(alignment: AlignmentDirectional.centerStart, child: cells[i])),
          ]),
        );
    final hs = ts(9, color: t.muted2, weight: FontWeight.w700, spacing: 1);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(spacing: 12, runSpacing: 12, children: [
        SearchField(
          placeholder: 'Search devices or facilities',
          controller: searchCtrl,
          onChanged: (v) => setState(() => query = v),
        ),
        AppDropdown(
          value: deviceStatus,
          options: const ['All Statuses', 'Online', 'Delayed', 'Offline'],
          onChanged: (v) => setState(() => deviceStatus = v),
        ),
      ]),
      const SizedBox(height: 16),
      LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth < 680 ? 680.0 : c.maxWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: w,
            child: Column(children: [
              row([
                T('Device ID', style: hs),
                T('Type', style: hs),
                T('Connected Facility', style: hs),
                T('Connectivity', style: hs),
                T('Last update', style: hs),
              ], header: true),
              for (final d in rows)
                Tap(
                  onTap: () => openDetail(context, 'Device Detail', d.$1),
                  child: row([
                    Text(d.$1, style: ts(11, weight: FontWeight.w600), textDirection: TextDirection.ltr),
                    T(d.$2, style: ts(11, color: t.muted)),
                    Text(d.$3, style: ts(11, color: t.muted), textDirection: TextDirection.ltr),
                    StatusPill(d.$4, tone: tone(d.$4)),
                    T(d.$5, style: ts(11, color: t.muted2)),
                  ]),
                ),
            ]),
          ),
        );
      }),
      if (rows.isEmpty)
        EmptyState(
          title: 'No search results',
          body: 'No devices match these filters.',
          action: 'Clear search',
          onAction: () => setState(() {
            query = '';
            searchCtrl.clear();
            deviceStatus = 'All Statuses';
          }),
        ),
    ]);
  }

  Widget _thresholds(BuildContext context) {
    final t = context.tk;
    final v = thresholdCtrl.text;
    final canSave = v.isNotEmpty && (int.tryParse(v) ?? 0) <= 95;
    Widget control(String title, String sub, TextEditingController ctrl, String unit, {bool restrict = false}) =>
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: t.lineSoft))),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                T(title, style: ts(12, weight: FontWeight.w600)),
                const SizedBox(height: 4),
                T(sub, style: ts(10, color: t.muted2)),
              ]),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 140,
              child: AppTextField(
                controller: ctrl,
                height: 44,
                onChanged: (_) => setState(() {}),
                inputFormatters: restrict
                    ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)]
                    : null,
                suffix: Padding(
                  padding: const EdgeInsetsDirectional.only(end: 12),
                  child: T(unit, style: ts(11, color: t.muted, weight: FontWeight.w600)),
                ),
              ),
            ),
          ]),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      control('Waste Bin Service Threshold', 'Create a service task when fill reaches this level.', thresholdCtrl, '%',
          restrict: true),
      control('Toilet Usage Threshold', 'Request cleaning after the defined number of uses.', toiletCtrl, 'uses'),
      const SizedBox(height: 20),
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        AppButton(
          label: 'Cancel',
          kind: BtnKind.ghost,
          onPressed: () => setState(() => thresholdCtrl.text = '80'),
        ),
        const SizedBox(width: 10),
        AppButton(
          label: 'Save Changes',
          kind: BtnKind.primary,
          onPressed: canSave ? () => ref.read(actionsProvider).toast('Changes saved successfully.') : null,
        ),
      ]),
    ]);
  }
}
