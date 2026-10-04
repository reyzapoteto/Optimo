import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_data.dart';
import '../data/models.dart';
import '../l10n/tr.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';

Future<void> openProfilePanel(BuildContext context, Role role) =>
    showSideDrawer(context, width: 392, builder: (_) => ProfilePanel(role: role));

class ProfilePanel extends ConsumerStatefulWidget {
  const ProfilePanel({super.key, required this.role});
  final Role role;
  @override
  ConsumerState<ProfilePanel> createState() => _ProfilePanelState();
}

class _ProfilePanelState extends ConsumerState<ProfilePanel> {
  late final TextEditingController name = TextEditingController(text: accounts[widget.role]!.name);
  late final TextEditingController email = TextEditingController(text: accounts[widget.role]!.email);
  bool editing = false;
  bool alerts = true;
  bool shiftUpdates = true;
  bool saved = false;
  Timer? _t;

  @override
  void dispose() {
    _t?.cancel();
    name.dispose();
    email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    final acc = accounts[widget.role]!;
    final lang = ref.watch(langProvider);
    Widget toggle(String title, String body, bool v, ValueChanged<bool> on) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                T(title, style: ts(11, weight: FontWeight.w600)),
                const SizedBox(height: 3),
                T(body, style: ts(9, color: t.muted2)),
              ]),
            ),
            AppSwitch(value: v, onChanged: on),
          ]),
        );
    return Column(children: [
      Expanded(
        child: ListView(padding: const EdgeInsets.all(32), children: [
          Row(children: [
            const Expanded(child: Eyebrow('ACCOUNT')),
            IconBtn(Icons.close, size: 32, onTap: () => Navigator.of(context).pop()),
          ]),
          const SizedBox(height: 6),
          T('My Profile', style: ts(24, weight: FontWeight.w500)),
          const SizedBox(height: 24),
          Row(children: [
            Avatar(acc.initials, size: 48),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name.text, style: ts(14, weight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('${context.tr(widget.role.label)} · ${context.tr('Main Club')} · ${context.tr(acc.scope)}',
                    style: ts(10, color: t.muted)),
              ]),
            ),
          ]),
          const SizedBox(height: 28),
          const FieldLabel('Name'),
          AppTextField(controller: name, enabled: editing),
          const SizedBox(height: 16),
          const FieldLabel('Email'),
          AppTextField(controller: email, enabled: false),
          const SizedBox(height: 16),
          const FieldLabel('Preferred Language'),
          AppDropdown(
            expand: true,
            value: lang == AppLang.ar ? 'العربية' : 'English',
            options: const ['English', 'العربية'],
            onChanged: (v) => ref.read(langProvider.notifier).state = v == 'English' ? AppLang.en : AppLang.ar,
          ),
          const SizedBox(height: 28),
          const Eyebrow('NOTIFICATION PREFERENCES'),
          const SizedBox(height: 6),
          toggle('Operational alerts', 'Service, SLA and critical facility updates', alerts, (v) => setState(() => alerts = v)),
          toggle('Shift updates', 'Assignments and schedule changes', shiftUpdates, (v) => setState(() => shiftUpdates = v)),
          if (saved) ...[
            const SizedBox(height: 12),
            Row(children: [
              Icon(Icons.check, size: 14, color: t.green),
              const SizedBox(width: 8),
              T('Changes saved successfully.', style: ts(11, color: t.green)),
            ]),
          ],
        ]),
      ),
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: t.line))),
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          if (!editing)
            AppButton(label: 'Edit Profile', kind: BtnKind.primary, onPressed: () => setState(() => editing = true))
          else ...[
            AppButton(
              label: 'Cancel',
              onPressed: () => setState(() {
                editing = false;
                name.text = acc.name;
              }),
            ),
            const SizedBox(width: 8),
            AppButton(
              label: 'Save Changes',
              kind: BtnKind.primary,
              onPressed: () {
                setState(() {
                  editing = false;
                  saved = true;
                });
                _t?.cancel();
                _t = Timer(const Duration(milliseconds: 2400), () {
                  if (mounted) setState(() => saved = false);
                });
              },
            ),
          ],
        ]),
      ),
    ]);
  }
}
