import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_data.dart';
import '../data/models.dart';
import '../l10n/tr.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';

class Sidebar extends ConsumerWidget {
  const Sidebar(
      {super.key,
      required this.page,
      required this.role,
      this.inDrawer = false,
      this.onNavigated});
  final AppPage page;
  final Role role;

  /// Rendered inside the tablet/mobile navigation drawer.
  final bool inDrawer;
  final VoidCallback? onNavigated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tk;
    final actions = ref.read(actionsProvider);
    final acc = accounts[role]!;
    void go(AppPage p) {
      actions.navigate(p);
      onNavigated?.call();
    }

    return Container(
      width: inDrawer ? null : 224,
      decoration: BoxDecoration(
        color: t.sidebar,
        border: BorderDirectional(end: BorderSide(color: t.line)),
      ),
      padding: EdgeInsets.fromLTRB(
          16, inDrawer ? 24 + MediaQuery.paddingOf(context).top : 32, 16, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Tap(
              onTap: () => go(AppPage.excellence),
              child: Text('OPTIMO', style: ts(18, color: t.yellow, spacing: 5)),
            ),
          ),
        ),
        SizedBox(height: inDrawer ? 24 : 40),
        Expanded(
          child: ListView(padding: EdgeInsets.zero, children: [
            for (final p in navFor(role)) ...[
              _NavItem(page: p, active: p == page, onTap: () => go(p)),
              const SizedBox(height: 8),
            ],
          ]),
        ),
        if (role == Role.dutyManager)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: t.lineSoft),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Eyebrow('MAIN CLUB'),
              const SizedBox(height: 8),
              Row(children: [
                Dot(t.green),
                const SizedBox(width: 8),
                Flexible(
                    child: T('42 devices online',
                        style: ts(11, weight: FontWeight.w500))),
              ]),
              const SizedBox(height: 4),
              T('Riyadh · All systems normal', style: ts(9, color: t.muted2)),
            ]),
          )
        else
          Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
                border: Border(top: BorderSide(color: t.lineSoft))),
            child: Row(children: [
              Avatar(acc.initials, size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.tr(acc.name),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ts(11, weight: FontWeight.w500)),
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
  const _NavItem(
      {required this.page, required this.active, required this.onTap});
  final AppPage page;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool hover = false;
  bool focused = false;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    final a = widget.active;
    return Semantics(
      button: true,
      selected: a,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (v) => setState(() => hover = v),
        onShowFocusHighlight: (v) => setState(() => focused = v),
        actions: {
          ActivateIntent:
              CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onTap())
        },
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: a ? t.surface2 : (hover ? t.surface : Colors.transparent),
              borderRadius: BorderRadius.circular(8),
              border: focused ? Border.all(color: t.yellow, width: 1.5) : null,
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
              Icon(pageIcon(widget.page),
                  size: 18, color: a ? t.yellow : t.muted),
              const SizedBox(width: 12),
              Expanded(
                child: T(widget.page.label,
                    maxLines: 1,
                    style: ts(11,
                        color: a ? t.ivory : t.muted,
                        weight: a ? FontWeight.w600 : FontWeight.w500)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
