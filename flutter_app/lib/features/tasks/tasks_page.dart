import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../l10n/tr.dart';
import '../../shell/page_intro.dart';
import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/detail_drawer.dart';

class TasksPage extends ConsumerStatefulWidget {
  const TasksPage({super.key});
  @override
  ConsumerState<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends ConsumerState<TasksPage> {
  final search = TextEditingController();
  String status = 'All';
  String zone = 'All Zones';
  String priority = 'All Priorities';
  bool filters = false;
  bool asc = false;
  int pageIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = ref.read(focusTaskProvider);
      if (id != null && mounted) {
        openDetail(context, 'Task Detail', id);
        ref.read(focusTaskProvider.notifier).state = null;
      }
    });
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  List<TaskRow> get rows {
    final q = search.text.trim().toLowerCase();
    final zoneMap = {
      'Changing Room': ['Changing Area A', 'Changing Room B', 'Shower Area', 'Toilet Area', 'Vanity Area'],
      'Functional Training': ['Personal Training'],
      'Pool': ['Pool'],
      'Lounge': ['Lounge'],
    };
    final list = taskRows.where((r) {
      if (status != 'All' && r.status != status) return false;
      if (priority != 'All Priorities' && r.priority != priority) return false;
      if (zone != 'All Zones' && !(zoneMap[zone] ?? const <String>[]).contains(r.location)) return false;
      if (q.isNotEmpty &&
          !('${r.id} ${r.facility} ${r.assignee} ${r.location} ${r.type}').toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList();
    list.sort((a, b) => asc ? a.id.compareTo(b.id) : b.id.compareTo(a.id));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    final list = rows;
    final pages = (list.length / 5).ceil().clamp(1, 99);
    final pi = pageIndex.clamp(0, pages - 1);
    final slice = list.skip(pi * 5).take(5).toList();
    const statuses = ['All', 'New', 'Accepted', 'In Progress', 'Blocked', 'Completed', 'Canceled'];

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const PageIntro(page: AppPage.tasks),
      const StatGrid(children: [
        StatCard(label: 'Open tasks', value: '6', detail: '2 need assignment', tone: Tone.attention),
        StatCard(label: 'Within response SLA', value: '96%', detail: '24 of 25 today'),
        StatCard(label: 'Avg. completion', value: '08:42', detail: '1m 18s faster'),
        StatCard(label: 'Blocked', value: '1', detail: 'Awaiting maintenance', tone: Tone.critical),
      ]),
      const SizedBox(height: 24),
      Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
        SearchField(
          placeholder: 'Search facilities, tasks or people',
          controller: search,
          onChanged: (_) => setState(() => pageIndex = 0),
        ),
        AppButton(label: 'Filters', icon: Icons.filter_list, onPressed: () => setState(() => filters = !filters)),
        AppButton(
          label: 'Create Task',
          icon: Icons.add,
          kind: BtnKind.primary,
          onPressed: () => showSideDrawer(context, width: 440, builder: (_) => const TaskForm()),
        ),
      ]),
      if (filters) ...[
        const SizedBox(height: 12),
        Panel(
          padding: const EdgeInsets.all(16),
          child: Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.end, children: [
            AppDropdown(
              label: 'ZONE',
              value: zone,
              options: const ['All Zones', 'Changing Room', 'Functional Training', 'Pool', 'Lounge'],
              onChanged: (v) => setState(() => zone = v),
            ),
            AppDropdown(
              label: 'PRIORITY',
              value: priority,
              options: const ['All Priorities', 'Urgent', 'High', 'Medium', 'Low'],
              onChanged: (v) => setState(() => priority = v),
            ),
            AppButton(
              label: 'Clear Filters',
              kind: BtnKind.ghost,
              onPressed: () => setState(() {
                zone = 'All Zones';
                priority = 'All Priorities';
              }),
            ),
          ]),
        ),
      ],
      const SizedBox(height: 16),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final s in statuses)
          AppChip(
            label: s,
            active: status == s,
            count: s == 'All' ? taskRows.length : taskRows.where((r) => r.status == s).length,
            onTap: () => setState(() {
              status = s;
              pageIndex = 0;
            }),
          ),
      ]),
      const SizedBox(height: 16),
      Panel(
        padding: EdgeInsets.zero,
        child: list.isEmpty
            ? EmptyState(
                title: 'No search results',
                body: 'Try a facility ID, task ID, or employee name.',
                action: 'Clear search',
                onAction: () => setState(() {
                  search.clear();
                  status = 'All';
                }),
              )
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                LayoutBuilder(builder: (context, c) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: c.maxWidth < 1040 ? 1040 : c.maxWidth,
                      child: Column(children: [
                        _header(context),
                        for (final r in slice) _row(context, r),
                      ]),
                    ),
                  );
                }),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Text(
                        '${context.tr('Showing')} ${pi * 5 + 1}–${pi * 5 + slice.length} ${context.tr('of')} ${list.length} ${context.tr('tasks')}',
                        style: ts(10, color: t.muted)),
                    const Spacer(),
                    AppButton(label: 'Previous', compact: true, onPressed: pi > 0 ? () => setState(() => pageIndex = pi - 1) : null),
                    const SizedBox(width: 8),
                    AppButton(
                        label: 'Next', compact: true, onPressed: pi < pages - 1 ? () => setState(() => pageIndex = pi + 1) : null),
                  ]),
                ),
              ]),
      ),
    ]);
  }

  static const _flex = [12, 8, 13, 13, 9, 12, 8, 10, 10, 4];

  Widget _cells(List<Widget> cells) => Row(children: [
        for (var i = 0; i < cells.length; i++) Expanded(flex: _flex[i], child: cells[i]),
      ]);

  Widget _header(BuildContext context) {
    final t = context.tk;
    TextStyle h = ts(9, color: t.muted2, weight: FontWeight.w700, spacing: 0.8);
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: t.line))),
      child: _cells([
        Tap(
          onTap: () => setState(() => asc = !asc),
          child: Row(children: [T('Task ID', style: h), const SizedBox(width: 4), Text(asc ? '↑' : '↓', style: h)]),
        ),
        T('Facility', style: h),
        T('Location', style: h),
        T('Type', style: h),
        T('Priority', style: h),
        T('Assignee', style: h),
        T('Source', style: h),
        T('Status', style: h),
        T('Response SLA', style: h),
        const SizedBox(),
      ]),
    );
  }

  Widget _row(BuildContext context, TaskRow r) {
    final t = context.tk;
    final pTone = r.priority == 'Urgent' ? Tone.critical : (r.priority == 'High' ? Tone.attention : Tone.muted);
    final sTone = r.status == 'Completed' ? Tone.ready : (r.status == 'New' ? Tone.attention : Tone.cleaning);
    return Tap(
      onTap: () => openDetail(context, 'Task Detail', r.id),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: t.lineSoft))),
        child: _cells([
          Text(r.id, style: ts(11, weight: FontWeight.w600)),
          Text(r.facility, style: ts(11)),
          T(r.location, style: ts(11, color: t.muted), maxLines: 1),
          T(r.type, style: ts(11), maxLines: 1),
          Align(alignment: AlignmentDirectional.centerStart, child: StatusPill(r.priority, tone: pTone)),
          T(r.assignee, style: ts(11), maxLines: 1),
          T(r.source, style: ts(11, color: t.muted)),
          Align(alignment: AlignmentDirectional.centerStart, child: StatusPill(r.status, tone: sTone)),
          T(r.sla, style: ts(11, color: r.sla == 'Breached' ? t.coral : t.ivory)),
          DirIcon(Icons.chevron_right, size: 16, color: t.muted2),
        ]),
      ),
    );
  }
}

class TaskForm extends ConsumerStatefulWidget {
  const TaskForm({super.key});
  @override
  ConsumerState<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends ConsumerState<TaskForm> {
  final facility = TextEditingController();
  final desc = TextEditingController();
  String type = 'Cleaning';
  String priority = 'High';
  String assignee = 'Select employee';
  bool created = false;
  String? error;

  @override
  void dispose() {
    facility.dispose();
    desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    if (created) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('✓', style: ts(28, color: t.green)),
          const SizedBox(height: 12),
          T('Task created', style: ts(22, weight: FontWeight.w500)),
          const SizedBox(height: 8),
          T('The task is ready for assignment and SLA tracking.', style: ts(11, color: t.muted), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          AppButton(label: 'View Task', kind: BtnKind.primary, onPressed: () => Navigator.of(context).pop()),
        ]),
      );
    }
    return Column(children: [
      Expanded(
        child: ListView(padding: const EdgeInsets.all(32), children: [
          Row(children: [
            const Expanded(child: Eyebrow('MANUAL TASK')),
            IconBtn(Icons.close, size: 32, onTap: () => Navigator.of(context).pop()),
          ]),
          const SizedBox(height: 6),
          T('Create operational task', style: ts(22, weight: FontWeight.w500)),
          const SizedBox(height: 24),
          const FieldLabel('Facility *'),
          AppTextField(controller: facility, placeholder: 'e.g. SH-04', error: error),
          const SizedBox(height: 16),
          const FieldLabel('Task Type *'),
          AppDropdown(
              expand: true,
              value: type,
              options: const ['Cleaning', 'Inspection', 'Replenishment', 'Maintenance'],
              onChanged: (v) => setState(() => type = v)),
          const SizedBox(height: 16),
          const FieldLabel('Priority'),
          AppDropdown(
              expand: true,
              value: priority,
              options: const ['Urgent', 'High', 'Medium', 'Low'],
              onChanged: (v) => setState(() => priority = v)),
          const SizedBox(height: 16),
          const FieldLabel('Assignee'),
          AppDropdown(
              expand: true,
              value: assignee,
              options: const ['Select employee', 'Ahmed Hassan', 'Sara Omar', 'M. Khalid', 'N. Faisal'],
              onChanged: (v) => setState(() => assignee = v)),
          const SizedBox(height: 16),
          const FieldLabel('Description'),
          AppTextField(controller: desc, placeholder: 'Add concise operational context', maxLines: 4),
        ]),
      ),
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: t.line))),
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          AppButton(label: 'Cancel', onPressed: () => Navigator.of(context).pop()),
          const SizedBox(width: 8),
          AppButton(
            label: 'Create Task',
            kind: BtnKind.primary,
            onPressed: () {
              if (facility.text.trim().isEmpty) {
                setState(() => error = 'Facility is required');
                return;
              }
              setState(() => created = true);
            },
          ),
        ]),
      ),
    ]);
  }
}
