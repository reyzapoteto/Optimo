import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../l10n/tr.dart';
import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';

class PermissionState extends ConsumerWidget {
  const PermissionState({super.key, required this.page, required this.role});
  final AppPage page;
  final Role role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tk;
    final p = context.tr(page.label);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: t.surface2,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: t.line),
              ),
              child: Icon(Icons.lock_outline, color: t.yellow, size: 22),
            ),
            const SizedBox(height: 20),
            const Eyebrow('ACCESS RESTRICTED'),
            const SizedBox(height: 10),
            Text('$p ${context.tr('is managed by administrators')}',
                textAlign: TextAlign.center,
                style: ts(24, weight: FontWeight.w500)),
            const SizedBox(height: 12),
            Text(
              context.isArabic
                  ? '${context.tr("Your")} ${context.tr(role.label)} ${context.tr("account can't open")} $p.'
                  : "Your ${role.label} account can't open $p. SLA rules, thresholds, devices, users and SOPs are changed by a System Administrator. Ask an administrator if a change is needed.",
              textAlign: TextAlign.center,
              style: ts(12, color: t.muted, height: 1.6),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Back to Excellence Center',
              kind: BtnKind.primary,
              onPressed: () =>
                  ref.read(actionsProvider).navigate(AppPage.excellence),
            ),
          ]),
        ),
      ),
    );
  }
}
