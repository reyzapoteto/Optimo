import 'package:flutter/material.dart';
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
    final forbidden = role == Role.supervisor && page == AppPage.settings;
    final toast = ref.watch(toastProvider);
    final t = context.tk;

    final showPulse =
        role == Role.supervisor && page != AppPage.excellence && page != AppPage.roleMatrix && !booting && !forbidden;

    Widget content;
    if (booting) {
      content = const DashboardSkeleton();
    } else if (forbidden) {
      content = PermissionState(page: page, role: role);
    } else {
      content = _pageFor(page, role);
    }

    return Scaffold(
      backgroundColor: t.canvas,
      body: Stack(children: [
        Row(children: [
          Sidebar(page: page, role: role),
          Expanded(
            child: Column(children: [
              AppHeader(page: page, role: role),
              if (showPulse) const ShiftPulseBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: content,
                ),
              ),
            ]),
          ),
        ]),
        if (role == Role.supervisor) const SupervisorToasts(),
        if (toast != null)
          PositionedDirectional(
            end: 32,
            bottom: 32,
            child: Material(
              color: t.surface3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: t.green.withOpacity(0.27)),
              ),
              elevation: 10,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('✓', style: ts(12, color: t.green)),
                  const SizedBox(width: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: T(toast, style: ts(11)),
                  ),
                ]),
              ),
            ),
          ),
      ]),
    );
  }

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
