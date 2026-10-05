import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/mock_data.dart';
import '../data/models.dart';
import '../l10n/tr.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import 'notification_center.dart';
import 'page_intro.dart';
import 'profile_panel.dart';
import 'responsive.dart';

/// Read ids for the Duty Manager notification popover.
final dmReadProvider = StateProvider<Set<String>>((ref) => <String>{});

const dmNotifications = <(String, String, String, Tone)>[
  ('SH-04', 'Service Required', 'Changing Area A · 2 min ago', Tone.attention),
  ('WC-02', 'Cleaning task created', 'Toilet Area · 4 min ago', Tone.cleaning),
  ('TSK-1046', 'Task Reassigned', 'Assigned to Sara Ali', Tone.cleaning),
  (
    'BIN-02',
    'Service threshold approaching',
    'Vanity Area · 8 min ago',
    Tone.attention
  ),
  ('SH-03', 'Inspection completed', 'Shower Area · 12 min ago', Tone.ready),
];

class AppHeader extends ConsumerStatefulWidget {
  const AppHeader(
      {super.key, required this.page, required this.role, this.onMenu});
  final AppPage page;
  final Role role;

  /// Opens the navigation drawer on tablet and mobile (Supervisor / Executive).
  final VoidCallback? onMenu;

  @override
  ConsumerState<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends ConsumerState<AppHeader> {
  final _bellKey = GlobalKey();
  final _userKey = GlobalKey();
  Timer? _clock;
  DateTime now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 30),
        (_) => setState(() => now = DateTime.now()));
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  bool get sup => widget.role == Role.supervisor;
  bool get executive => widget.role == Role.executive;
  bool get home => widget.page == AppPage.excellence;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    final width = MediaQuery.of(context).size.width;
    if (isResponsiveRole(widget.role)) return _responsive(context, width);
    final heading = home
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
                if (!sup) ...[const LiveLabel(), const SizedBox(height: 10)],
                Text(
                    context.tr(sup
                        ? 'Hello, Supervisor'
                        : 'Hospitality Excellence Center'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.title(sup ? 30 : 34,
                        arabic: context.isArabic)),
                if (!sup || width > 1360) ...[
                  const SizedBox(height: 6),
                  T(
                      sup
                          ? 'Live facility operations across your zones.'
                          : 'Live operations for the Washroom / Changing Area.',
                      maxLines: 1,
                      style: ts(11, color: t.muted)),
                ],
              ])
        : const SizedBox.shrink();

    final controls = <Widget>[
      if (!sup && !executive) _contextSummary(context),
      if (sup) _connection(context, width),
      if (sup && width > 1280) _shiftClock(context),
      if (sup &&
          widget.page != AppPage.roleMatrix &&
          widget.page != AppPage.settings)
        _scope(context),
      if (!executive) const LanguageSwitch(),
      _bell(context),
      _userButton(context),
    ];

    return Container(
      constraints: BoxConstraints(minHeight: sup ? 72 : (home ? 144 : 88)),
      padding: sup
          ? const EdgeInsets.symmetric(horizontal: 32, vertical: 16)
          : const EdgeInsets.all(32),
      decoration:
          BoxDecoration(border: Border(bottom: BorderSide(color: t.lineSoft))),
      child: Row(children: [
        Expanded(child: heading),
        const SizedBox(width: 16),
        for (var i = 0; i < controls.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          controls[i],
        ],
      ]),
    );
  }

  /// Supervisor / Executive header: keeps the desktop structure on wide screens,
  /// wraps secondary controls into a second row as space narrows, and shows the
  /// current page title next to a menu button when navigation moves to a drawer.
  Widget _responsive(BuildContext context, double width) {
    final t = context.tk;
    final tier = tierFor(width);
    final narrow = tier == Tier.mobile || tier == Tier.tablet;
    final pad = pagePaddingFor(tier);
    final titleSize = !home
        ? 18.0
        : switch (tier) {
            Tier.mobile => 22.0,
            Tier.tablet => 26.0,
            _ => sup
                ? 30.0
                : (tier == Tier.wide ? (executive ? 32.0 : 34.0) : 30.0),
          };
    final titleText = home
        ? (sup ? 'Hello, Supervisor' : 'Hospitality Excellence Center')
        : widget.page.label;
    final subtitle = home
        ? (sup
            ? 'Live facility operations across your zones.'
            : 'Live operations for the Washroom / Changing Area.')
        : null;
    final showTitle = home; // other pages show their title in PageIntro

    final heading = showTitle
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
                if (!sup && home && tier != Tier.mobile) ...[
                  const LiveLabel(),
                  const SizedBox(height: 10)
                ],
                T(titleText,
                    style: AppFonts.title(titleSize, arabic: context.isArabic)
                        .copyWith(height: 1.2)),
                if (subtitle != null &&
                    tier != Tier.mobile &&
                    (!sup || width > 1360 || narrow)) ...[
                  const SizedBox(height: 6),
                  T(subtitle, style: ts(12, color: t.muted, height: 1.5)),
                ],
              ])
        : const SizedBox.shrink();

    final dm = widget.role == Role.dutyManager;
    final secondary = <Widget>[
      if (dm) _contextSummary(context),
      if (sup) _connection(context, width),
      if (sup && width > 1280) _shiftClock(context),
      if (sup &&
          widget.page != AppPage.roleMatrix &&
          widget.page != AppPage.settings)
        _scope(context),
      if (!executive) const LanguageSwitch(),
    ];
    final primary = <Widget>[_bell(context), _userButton(context)];

    Widget gapRow(List<Widget> items) =>
        Row(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            items[i]
          ],
        ]);

    final menu = widget.onMenu == null
        ? null
        : Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: Semantics(
              button: true,
              label: context.tr('Open navigation'),
              child: IconBtn(Icons.menu,
                  size: 44,
                  tooltip: context.tr('Open navigation'),
                  onTap: widget.onMenu),
            ),
          );

    // Secondary controls drop to their own wrapping row before they can overlap the title.
    final splitRows = narrow || width < 1280;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: pad, vertical: narrow ? 12 : (sup ? 16 : pad)),
      decoration:
          BoxDecoration(border: Border(bottom: BorderSide(color: t.lineSoft))),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              if (menu != null) menu,
              Expanded(child: heading),
              const SizedBox(width: 16),
              if (!splitRows && secondary.isNotEmpty) ...[
                gapRow(secondary),
                const SizedBox(width: 8)
              ],
              gapRow(primary),
            ]),
            if (splitRows && secondary.isNotEmpty) ...[
              const SizedBox(height: 12),
              // Phones: one scrollable row keeps the fixed header short.
              if (tier == Tier.mobile)
                SingleChildScrollView(
                    scrollDirection: Axis.horizontal, child: gapRow(secondary))
              else
                Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: secondary),
            ],
          ]),
    );
  }

  Widget _contextSummary(BuildContext context) {
    final t = context.tk;
    Widget pair(String k, String v) =>
        Row(mainAxisSize: MainAxisSize.min, children: [
          T(k,
              style:
                  ts(8, color: t.muted2, weight: FontWeight.w700, spacing: 1)),
          const SizedBox(width: 6),
          T(v, style: ts(10, weight: FontWeight.w500)),
        ]);
    Widget sep() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text('›', style: ts(10, color: kTokens.muted2)));
    final items = <Widget>[pair('CLUB', 'Main Club')];
    if (home && MediaQuery.of(context).size.width > 1440) {
      items.addAll([
        sep(),
        pair('FLOOR', 'Ground Floor'),
        sep(),
        pair('LIVE TWIN', 'Washroom / Changing Area')
      ]);
    }
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.line),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: items),
    );
  }

  Widget _connection(BuildContext context, double width) {
    final t = context.tk;
    final c = ref.watch(connectionProvider);
    final labels = ['Online', 'Delayed data', 'Offline'];
    final colors = [t.green, t.yellow, t.coral];
    final icons = [
      pageIcon(AppPage.quality),
      pageIcon(AppPage.quality),
      Icons.close
    ];
    return Tap(
      onTap: () => ref.read(connectionProvider.notifier).state = (c + 1) % 3,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: t.line),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icons[c], size: 14, color: colors[c]),
          const SizedBox(width: 8),
          T(labels[c],
              style: ts(10, color: colors[c], weight: FontWeight.w600)),
          if (width > 1440) ...[
            const SizedBox(width: 8),
            Text(DateFormat('HH:mm').format(now),
                style: ts(10, color: t.muted2)),
          ],
        ]),
      ),
    );
  }

  Widget _shiftClock(BuildContext context) {
    final t = context.tk;
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.line),
      ),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              T('SHIFT',
                  style: ts(8,
                      color: t.muted2, weight: FontWeight.w700, spacing: 1)),
              const SizedBox(width: 6),
              Text('07:00–15:00 · ${context.tr('3h 20m left')}',
                  style: ts(10, weight: FontWeight.w500)),
            ]),
            const SizedBox(height: 5),
            SizedBox(
              width: 150,
              height: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                    value: 0.58,
                    color: t.yellowSoft,
                    backgroundColor: AppTokens.track),
              ),
            ),
          ]),
    );
  }

  Widget _scope(BuildContext context) {
    final t = context.tk;
    final scope = ref.watch(scopeProvider);
    Widget seg(String s) {
      final a = scope == s;
      return Tap(
        onTap: () => ref.read(scopeProvider.notifier).state = s,
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: a ? t.surface2 : Colors.transparent,
            border: Border(
                bottom: BorderSide(
                    color: a ? t.yellow : Colors.transparent, width: 2)),
          ),
          child: T(s,
              style: ts(10,
                  color: a ? t.ivory : t.muted, weight: FontWeight.w600)),
        ),
      );
    }

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [seg('My zones'), seg('Whole club')]),
    );
  }

  Widget _bell(BuildContext context) {
    final t = context.tk;
    final read = ref.watch(dmReadProvider);
    final count =
        sup ? 4 : dmNotifications.where((n) => !read.contains(n.$1)).length;
    return Stack(key: _bellKey, clipBehavior: Clip.none, children: [
      IconBtn(Icons.notifications_none, onTap: () {
        if (sup || executive) {
          openNotificationCenter(context);
        } else {
          showAnchoredPopover(context,
              anchor: _bellKey,
              width: 328,
              builder: (_) => const _DmNotifications());
        }
      }),
      if (count > 0)
        PositionedDirectional(
          top: -4,
          end: -4,
          child: Container(
            constraints: const BoxConstraints(minWidth: 16),
            height: 16,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: t.yellow, borderRadius: BorderRadius.circular(8)),
            child: Text('$count',
                style:
                    ts(8, color: AppTokens.onYellow, weight: FontWeight.w700)),
          ),
        ),
    ]);
  }

  Widget _userButton(BuildContext context) {
    final t = context.tk;
    final acc = accounts[widget.role]!;
    return Tap(
      key: _userKey,
      onTap: () => showAnchoredPopover(context,
          anchor: _userKey,
          width: 224,
          builder: (_) => _UserMenu(role: widget.role)),
      // Duty Manager keeps the name chip on desktop, avatar only on tablet/mobile.
      child: sup || executive || MediaQuery.sizeOf(context).width < 1024
          ? Avatar(acc.initials, size: 40)
          : Container(
              height: 40,
              padding: const EdgeInsetsDirectional.only(start: 4, end: 10),
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: t.line),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Avatar(acc.initials, size: 30),
                const SizedBox(width: 8),
                Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      T(acc.name, style: ts(10, weight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      RoleBadge(widget.role.label),
                    ]),
                const SizedBox(width: 8),
                Icon(Icons.expand_more, size: 16, color: t.muted),
              ]),
            ),
    );
  }
}

class _DmNotifications extends ConsumerStatefulWidget {
  const _DmNotifications();
  @override
  ConsumerState<_DmNotifications> createState() => _DmNotificationsState();
}

class _DmNotificationsState extends ConsumerState<_DmNotifications> {
  bool all = false;

  void _open(String id) {
    ref.read(dmReadProvider.notifier).state = {...ref.read(dmReadProvider), id};
    Navigator.of(context).pop();
    final a = ref.read(actionsProvider);
    if (id.startsWith('CFG')) {
      a.navigate(AppPage.settings);
    } else if (id.startsWith('TSK')) {
      a.openTask(id);
    } else if (id.startsWith('INSP')) {
      a.navigate(AppPage.quality);
    } else {
      a.openFacility(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    final read = ref.watch(dmReadProvider);
    final items = all ? dmNotifications : dmNotifications.take(3).toList();
    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(children: [
              Expanded(
                  child: T('Notifications',
                      style: ts(13, weight: FontWeight.w600))),
              LinkButton('Mark all as read', size: 9, onTap: () {
                ref.read(dmReadProvider.notifier).state = {
                  for (final n in dmNotifications) n.$1
                };
              }),
            ]),
          ),
          Divider(height: 1, color: t.line),
          Flexible(
            child:
                ListView(shrinkWrap: true, padding: EdgeInsets.zero, children: [
              for (final n in items)
                Tap(
                  onTap: () => _open(n.$1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: t.lineSoft))),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Dot(toneColor(n.$4))),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${n.$1} · ${context.tr(n.$2)}',
                                      style: ts(11,
                                          weight: read.contains(n.$1)
                                              ? FontWeight.w400
                                              : FontWeight.w600,
                                          color: read.contains(n.$1)
                                              ? t.muted
                                              : t.ivory)),
                                  const SizedBox(height: 3),
                                  T(n.$3, style: ts(9, color: t.muted2)),
                                ]),
                          ),
                          DirIcon(Icons.chevron_right,
                              size: 14, color: t.muted2),
                        ]),
                  ),
                ),
            ]),
          ),
          Tap(
            onTap: () => setState(() => all = !all),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: T(all ? 'Show recent' : 'View all notifications',
                    style: ts(10, color: t.yellow, weight: FontWeight.w600)),
              ),
            ),
          ),
        ]);
  }
}

class _UserMenu extends ConsumerWidget {
  const _UserMenu({required this.role});
  final Role role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tk;
    final acc = accounts[role]!;
    final actions = ref.read(actionsProvider);
    Widget row(String label,
            {Widget? trailing, VoidCallback? onTap, Color? color}) =>
        Tap(
          onTap: onTap,
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Expanded(child: T(label, style: ts(11, color: color ?? t.ivory))),
              if (trailing != null) trailing,
            ]),
          ),
        );
    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Avatar(acc.initials, size: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      T(acc.name, style: ts(11, weight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Text(
                          role == Role.executive
                              ? '${acc.staffId} · ${context.tr(role.label)} · ${context.tr('Read-only access')}'
                              : '${acc.staffId} · ${context.tr(role.label)} · ${context.tr('Shift')} ${acc.shift}',
                          style: ts(8, color: t.muted2)),
                    ]),
              ),
            ]),
          ),
          Divider(height: 1, color: t.line),
          const SizedBox(height: 6),
          row('My Profile', onTap: () {
            Navigator.of(context).pop();
            openProfilePanel(context, role);
          }),
          row('Preferences', onTap: () {
            Navigator.of(context).pop();
            openProfilePanel(context, role);
          }),
          row('Language',
              trailing: Text(context.isArabic ? 'EN' : 'العربية',
                  style: ts(10, color: t.muted)),
              onTap: () => actions.toggleLanguage()),
          row('Role & permissions', onTap: () {
            Navigator.of(context).pop();
            actions.navigate(AppPage.roleMatrix);
          }),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const DashedTag('Demo'),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final r in Role.values)
                  AppChip(
                    label: r.label,
                    active: r == role,
                    onTap: () {
                      Navigator.of(context).pop();
                      actions.switchRole(r);
                    },
                  ),
              ]),
            ]),
          ),
          Divider(height: 1, color: t.line),
          row('Sign Out', color: t.coral, onTap: () {
            Navigator.of(context).pop();
            actions.logout();
          }),
          const SizedBox(height: 6),
        ]);
  }
}
