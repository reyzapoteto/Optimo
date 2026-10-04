import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_data.dart';
import '../data/models.dart';
import '../l10n/tr.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';

class Sidebar extends ConsumerWidget {
  const Sidebar({super.key, required this.page, required this.role});
  final AppPage page;
  final Role role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tk;
    final actions = ref.read(actionsProvider);
    final acc = accounts[role]!;
    return Container(
      width: 224,
      decoration: BoxDecoration(
        color: t.sidebar,
        border: BorderDirectional(end: BorderSide(color: t.line)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Tap(
              onTap: () => actions.navigate(AppPage.excellence),
              child: Text('OPTIMO', style: ts(18, color: t.yellow, spacing: 5)),
            ),
          ),
        ),
        const SizedBox(height: 40),
        for (final p in navFor(role)) ...[
          _NavItem(page: p, active: p == page, onTap: () => actions.navigate(p)),
          const SizedBox(height: 8),
        ],
        const Spacer(),
        if (role == Role.dutyManager)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: t.lineSoft),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Eyebrow('MAIN CLUB'),
              const SizedBox(height: 8),
              Row(children: [
                Dot(t.green),
                const SizedBox(width: 8),
                T('42 devices online', style: ts(11, weight: FontWeight.w500)),
              ]),
              const SizedBox(height: 4),
              T('Riyadh · All systems normal', style: ts(9, color: t.muted2)),
            ]),
          )
        else
          Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: t.lineSoft))),
            child: Row(children: [
              Avatar(acc.initials, size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(context.tr(acc.name), maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(11, weight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  RoleBadge(role.label),
                ]),
              ),
            ]),
          ),
      ]),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({required this.page, required this.active, required this.onTap});
  final AppPage page;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    final a = widget.active;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: a ? t.surface2 : (hover ? t.surface : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            Container(
              width: 3,
              height: 20,
              decoration: BoxDecoration(
                color: a ? t.yellow : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Icon(pageIcon(widget.page), size: 18, color: a ? t.yellow : t.muted),
            const SizedBox(width: 12),
            Expanded(
              child: T(widget.page.label,
                  maxLines: 1, style: ts(11, color: a ? t.ivory : t.muted, weight: a ? FontWeight.w600 : FontWeight.w500)),
            ),
          ]),
        ),
      ),
    );
  }
}
