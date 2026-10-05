import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../l10n/tr.dart';
import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';

enum _Mode { signin, recovery, sent }

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _id = TextEditingController();
  final _pw = TextEditingController();
  _Mode mode = _Mode.signin;
  bool show = false;
  bool remember = true;
  bool loading = false;
  int attempts = 0;
  String? formError;
  String? idError;
  String? pwError;

  @override
  void dispose() {
    _id.dispose();
    _pw.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final id = _id.text.trim().toUpperCase();
    setState(() {
      idError = id.isEmpty ? 'Staff ID is required' : null;
      pwError = mode == _Mode.signin && _pw.text.isEmpty
          ? 'Password is required'
          : null;
      formError = null;
    });
    if (idError != null || pwError != null) return;
    if (mode == _Mode.recovery) {
      setState(() => mode = _Mode.sent);
      return;
    }
    setState(() => loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => loading = false);
    // Flutter has no navigator.onLine; Staff ID "OFFLINE" simulates the offline state.
    if (id == 'OFFLINE') {
      setState(
          () => formError = 'No connection. Check your network and retry.');
      return;
    }
    if (id == 'SUP-099' || attempts >= 4) {
      setState(() =>
          formError = 'Your account is locked. Contact an administrator.');
      return;
    }
    final role = roleForStaffId(id);
    if (role == null || _pw.text.length < 4) {
      setState(() {
        attempts++;
        formError = 'Staff ID or password is incorrect.';
      });
      return;
    }
    ref.read(actionsProvider).enter(role);
  }

  void _prefill(Role role) {
    setState(() {
      _id.text = accounts[role]!.staffId;
      _pw.text = 'optimo-demo';
      idError = null;
      pwError = null;
      formError = null;
    });
  }

  void _enterManagerWorkspace() {
    _prefill(Role.dutyManager);
    ref.read(actionsProvider).enter(Role.dutyManager);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    return Scaffold(
      backgroundColor: t.canvas,
      body: SafeArea(
        child: LayoutBuilder(builder: (context, c) {
          final wide = c.maxWidth >= 1100;
          final form = _formSide(context);
          if (!wide) return form;
          final formWidth = (c.maxWidth * 0.4).clamp(480.0, 680.0).toDouble();
          return Row(children: [
            SizedBox(width: formWidth, child: form),
            Expanded(child: _photo(context)),
          ]);
        }),
      ),
    );
  }

  Widget _photo(BuildContext context) {
    final t = context.tk;
    return Stack(fit: StackFit.expand, children: [
      Image.asset('assets/images/optimo-exterior.png',
          fit: BoxFit.cover, alignment: const Alignment(-0.76, 0)),
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.centerStart,
            end: AlignmentDirectional.centerEnd,
            colors: [t.canvas, t.canvas.withOpacity(0.2), Colors.transparent],
            stops: const [0, 0.25, 1],
          ),
        ),
      ),
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
            stops: const [0, 0.5],
          ),
        ),
      ),
      PositionedDirectional(
        start: 48,
        bottom: 48,
        end: 48,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Eyebrow('RIYADH · MAIN CLUB'),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: T(
                'Physical excellence, translated into operational intelligence.',
                style: ts(24, weight: FontWeight.w400, height: 1.3)),
          ),
        ]),
      ),
    ]);
  }

  Widget _formSide(BuildContext context) {
    final t = context.tk;
    return LayoutBuilder(builder: (context, c) {
      final mobile = c.maxWidth < 600;
      final narrowMobile = c.maxWidth < 400;
      final horizontal = narrowMobile ? 20.0 : (mobile ? 24.0 : 48.0);
      final headerTop = mobile ? 20.0 : 40.0;
      final bodyVertical = c.maxHeight < 700 ? 20.0 : 32.0;
      return Container(
        color: t.canvas,
        child: Column(children: [
          Padding(
            padding: EdgeInsets.fromLTRB(horizontal, headerTop, horizontal, 0),
            child: Row(children: [
              Text('OPTIMO',
                  style: ts(mobile ? 16 : 18, color: t.yellow, spacing: 5)),
              const Spacer(),
              LanguageSwitch(height: mobile ? 36 : 40),
            ]),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                    horizontal: horizontal, vertical: bodyVertical),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: _body(context, compact: mobile),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                horizontal, 0, horizontal, mobile ? 16 : 28),
            child: T(
              'OPTIMO internal operations · Authorized access only',
              style: ts(9, color: t.muted2),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ),
        ]),
      );
    });
  }

  Widget _body(BuildContext context, {required bool compact}) {
    final t = context.tk;
    if (mode == _Mode.sent) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              shape: BoxShape.circle, border: Border.all(color: t.green)),
          child: Text('✓', style: ts(18, color: t.green)),
        ),
        const SizedBox(height: 20),
        const Eyebrow('RECOVERY SENT'),
        const SizedBox(height: 10),
        T('Check your inbox',
            style: ts(compact ? 30 : 34, weight: FontWeight.w500)),
        const SizedBox(height: 10),
        Text(
            '${context.tr('A recovery link has been sent to the work email for')} ${_id.text.trim().toUpperCase()}.',
            style: ts(12, color: t.muted, height: 1.5)),
        const SizedBox(height: 28),
        AppButton(
          label: 'Back to sign in',
          kind: BtnKind.primary,
          expand: true,
          onPressed: () => setState(() => mode = _Mode.signin),
        ),
      ]);
    }
    final recovery = mode == _Mode.recovery;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (recovery) ...[
        Tap(
          onTap: () => setState(() {
            mode = _Mode.signin;
            idError = null;
          }),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            DirIcon(Icons.arrow_back, size: 14, color: t.muted),
            const SizedBox(width: 6),
            T('Back to sign in',
                style: ts(10, color: t.muted, weight: FontWeight.w600)),
          ]),
        ),
        const SizedBox(height: 24),
      ],
      Eyebrow(recovery ? 'ACCOUNT RECOVERY' : 'HOSPITALITY EXCELLENCE CENTER'),
      const SizedBox(height: 12),
      T(recovery ? 'Recover access' : 'Welcome back',
          style: ts(compact ? 32 : 38, weight: FontWeight.w500, height: 1.1)),
      const SizedBox(height: 10),
      T(
        recovery
            ? "Enter your Staff ID and we'll send a secure recovery link to your work email."
            : 'Sign in to access club operations.',
        style: ts(12, color: t.muted, height: 1.5),
      ),
      const SizedBox(height: 28),
      if (formError != null) ...[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: t.coral.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: t.coral.withOpacity(0.4)),
          ),
          child: Row(children: [
            Icon(Icons.error_outline, size: 16, color: t.coral),
            const SizedBox(width: 10),
            Expanded(child: T(formError!, style: ts(11, color: t.coral))),
          ]),
        ),
        const SizedBox(height: 20),
      ],
      const FieldLabel('Staff ID'),
      AppTextField(
        controller: _id,
        placeholder: 'e.g. SUP-014',
        error: idError,
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _submit(),
      ),
      if (!recovery) ...[
        const SizedBox(height: 18),
        const FieldLabel('Password'),
        AppTextField(
          controller: _pw,
          placeholder: '••••••••••',
          obscure: !show,
          error: pwError,
          onSubmitted: (_) => _submit(),
          suffix: Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: TextButton(
              onPressed: () => setState(() => show = !show),
              child: T(show ? 'Hide' : 'Show',
                  style: ts(10, color: t.muted, weight: FontWeight.w600)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (context, constraints) {
          final stackOptions =
              constraints.maxWidth < 320 || (compact && context.isArabic);
          final rememberOption = Tap(
            onTap: () => setState(() => remember = !remember),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: remember ? t.yellow : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: remember ? t.yellow : t.line),
                  ),
                  child: remember
                      ? const Icon(Icons.check,
                          size: 12, color: AppTokens.onYellow)
                      : null,
                ),
                const SizedBox(width: 8),
                T('Remember me', style: ts(11, color: t.muted)),
              ]),
            ),
          );
          final forgotPassword = LinkButton('Forgot Password?',
              size: 11,
              onTap: () => setState(() {
                    mode = _Mode.recovery;
                    formError = null;
                  }));
          if (stackOptions) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                rememberOption,
                const SizedBox(height: 8),
                forgotPassword,
              ],
            );
          }
          return Row(children: [
            rememberOption,
            const Spacer(),
            forgotPassword,
          ]);
        }),
      ],
      const SizedBox(height: 24),
      AppButton(
        label: recovery
            ? 'Send recovery link'
            : (loading ? 'Signing In' : 'Sign In'),
        kind: BtnKind.primary,
        expand: true,
        loading: loading,
        trailingIcon: recovery || loading ? null : Icons.arrow_forward,
        onPressed: _submit,
      ),
      if (!recovery) ...[
        const SizedBox(height: 24),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.lock_outline, size: 16, color: t.muted2),
          const SizedBox(width: 10),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              T('Secure operational access',
                  style: ts(11, weight: FontWeight.w600)),
              const SizedBox(height: 3),
              T('Your role is set by your account. No public registration.',
                  style: ts(10, color: t.muted)),
            ]),
          ),
        ]),
        const SizedBox(height: 24),
        CustomPaint(
          painter: DashedRectPainter(color: t.line, radius: 10),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const DashedTag('Demo'),
                const SizedBox(width: 8),
                T('Prefill example account', style: ts(10, color: t.muted)),
              ]),
              const SizedBox(height: 10),
              AppButton(
                label: 'Open Manager workspace',
                kind: BtnKind.primary,
                icon: Icons.admin_panel_settings_outlined,
                expand: true,
                onPressed: _enterManagerWorkspace,
              ),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final r in Role.values)
                  AppChip(
                    label: r.label,
                    active:
                        _id.text.trim().toUpperCase() == accounts[r]!.staffId,
                    onTap: () => _prefill(r),
                  ),
              ]),
            ]),
          ),
        ),
      ],
    ]);
  }
}
