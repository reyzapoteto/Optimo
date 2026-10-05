import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/tr.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models.dart';
import '../features/common/permission_state.dart';
import '../features/common/skeleton.dart';
import '../features/excellence/excellence_center.dart';
import '../features/issues/issues_page.dart';
import '../features/quality/quality_page.dart';
import '../features/reports/reports_page.dart';
import '../features/role_matrix/role_matrix_page.dart';
import '../features/schedule/schedule_page.dart';
import '../features/settings/settings_page.dart';
import '../features/tasks/tasks_page.dart';
import '../features/team/team_page.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import 'header.dart';
import 'pulse_bar.dart';
import 'responsive.dart';
import 'sidebar.dart';
import 'supervisor_toasts.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.page});
  final AppPage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authProvider);
    if (role == null) return const SizedBox.shrink();
    final booting = ref.watch(bootingProvider);
    final forbidden = (role == Role.supervisor && page == AppPage.settings) ||
        (role == Role.executive &&
            {AppPage.tasks, AppPage.schedule, AppPage.team, AppPage.settings}
                .contains(page));
    final toast = ref.watch(toastProvider);
    final t = context.tk;

    final showPulse = role == Role.supervisor &&
        page != AppPage.excellence &&
        page != AppPage.roleMatrix &&
        !booting &&
        !forbidden;

    Widget content;
    if (booting) {
      content = const DashboardSkeleton();
    } else if (forbidden) {
      content = PermissionState(page: page, role: role);
    } else {
      content = _pageFor(page, role);
    }

    // Supervisor and Executive adapt to the viewport; Duty Manager keeps its fixed desktop layout.
    final responsive = isResponsiveRole(role);
    final tier = responsive ? context.tier : Tier.wide;
    final useDrawer =
        responsive && (tier == Tier.mobile || tier == Tier.tablet);
    final pad = pagePaddingFor(tier);
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      key: _scaffoldKey(role),
      backgroundColor: t.canvas,
      drawer: useDrawer
          ? Drawer(
              width: 280,
              backgroundColor: t.sidebar,
              shape: const RoundedRectangleBorder(),
              semanticLabel: context.tr('Navigation'),
              child: CallbackShortcuts(
                bindings: {
                  const SingleActivator(LogicalKeyboardKey.escape): () =>
                      _scaffoldKey(role).currentState?.closeDrawer(),
                },
                child: FocusScope(
                  autofocus: true,
                  child: Sidebar(
                    page: page,
                    role: role,
                    inDrawer: true,
                    onNavigated: () =>
                        _scaffoldKey(role).currentState?.closeDrawer(),
                  ),
                ),
              ),
            )
          : null,
      drawerEnableOpenDragGesture: useDrawer,
      body: Stack(children: [
        Row(children: [
          if (!useDrawer) Sidebar(page: page, role: role),
          Expanded(
            child: Column(children: [
              AppHeader(
                page: page,
                role: role,
                onMenu: useDrawer
                    ? () => _scaffoldKey(role).currentState?.openDrawer()
                    : null,
              ),
              if (showPulse) const ShiftPulseBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: responsive
                      ? EdgeInsets.fromLTRB(pad, pad, pad,
                          pad + safeBottom + (toast != null ? 72 : 0))
                      : const EdgeInsets.all(32),
                  child: content,
                ),
              ),
            ]),
          ),
        ]),
        if (role == Role.supervisor) const SupervisorToasts(),
        if (toast != null)
          PositionedDirectional(
            end: responsive ? pad : 32,
            bottom: responsive ? pad + safeBottom : 32,
            child: Material(
              color: t.surface3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: t.green.withOpacity(0.27)),
              ),
              elevation: 10,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('✓', style: ts(12, color: t.green)),
                  const SizedBox(width: 10),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                        maxWidth: responsive
                            ? (MediaQuery.sizeOf(context).width - pad * 2 - 64)
                                .clamp(160, 380)
                            : 380),
                    child: T(toast, style: ts(11)),
                  ),
                ]),
              ),
            ),
          ),
      ]),
    );
  }

  static final _keys = <Role, GlobalKey<ScaffoldState>>{};
  static GlobalKey<ScaffoldState> _scaffoldKey(Role role) =>
      _keys.putIfAbsent(role, () => GlobalKey<ScaffoldState>());

  Widget _pageFor(AppPage page, Role role) {
    switch (page) {
      case AppPage.excellence:
        return ExcellenceCenter(key: ValueKey(role), role: role);
      case AppPage.tasks:
        return const TasksPage();
      case AppPage.schedule:
        return const SchedulePage();
      case AppPage.team:
        return const TeamPage();
      case AppPage.quality:
        return const QualityPage();
      case AppPage.issues:
        return const IssuesPage();
      case AppPage.reports:
        return const ReportsPage();
      case AppPage.settings:
        return const SettingsPage();
      case AppPage.roleMatrix:
        return const RoleMatrixPage();
    }
  }
}
