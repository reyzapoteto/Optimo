import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models.dart';
import '../l10n/tr.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';

// ---------------------------------------------------------------------------
// Icons
// ---------------------------------------------------------------------------

IconData pageIcon(AppPage p) {
  switch (p) {
    case AppPage.excellence:
      return Icons.monitor_heart_outlined;
    case AppPage.tasks:
      return Icons.checklist_rounded;
    case AppPage.schedule:
      return Icons.calendar_today_outlined;
    case AppPage.team:
      return Icons.group_outlined;
    case AppPage.quality:
      return Icons.verified_user_outlined;
    case AppPage.issues:
      return Icons.warning_amber_rounded;
    case AppPage.reports:
      return Icons.bar_chart_rounded;
    case AppPage.settings:
      return Icons.settings_outlined;
    case AppPage.roleMatrix:
      return Icons.lock_outline;
  }
}

/// Icon that mirrors in RTL (chevrons, arrows).
class DirIcon extends StatelessWidget {
  const DirIcon(this.icon, {super.key, this.size = 16, this.color});
  final IconData icon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final i = Icon(icon, size: size, color: color);
    return rtl ? Transform.flip(flipX: true, child: i) : i;
  }
}

// ---------------------------------------------------------------------------
// Text
// ---------------------------------------------------------------------------

/// Translated text.
class T extends StatelessWidget {
  const T(this.text,
      {super.key, this.style, this.maxLines, this.overflow, this.textAlign});
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) => Text(
        context.tr(text),
        style: style,
        maxLines: maxLines,
        overflow: overflow ?? (maxLines != null ? TextOverflow.ellipsis : null),
        textAlign: textAlign,
      );
}

TextStyle ts(double size,
        {Color? color,
        FontWeight weight = FontWeight.w400,
        double? spacing,
        double? height}) =>
    TextStyle(
        fontSize: size,
        color: color ?? kTokens.ivory,
        fontWeight: weight,
        letterSpacing: spacing,
        height: height);

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => T(text,
      style: ts(9,
          color: color ?? kTokens.muted2,
          weight: FontWeight.w700,
          spacing: context.isArabic ? 0 : 1.4));
}

class SectionHead extends StatelessWidget {
  const SectionHead(
      {super.key,
      required this.eyebrow,
      required this.title,
      this.trailing,
      this.titleSize = 18});
  final String eyebrow;
  final String title;
  final Widget? trailing;
  final double titleSize;

  @override
  Widget build(BuildContext context) {
    final head =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Eyebrow(eyebrow),
      const SizedBox(height: 6),
      T(title, style: ts(titleSize, weight: FontWeight.w500)),
    ]);
    if (trailing == null) return head;
    // Narrow cards: move the trailing control below the title instead of clipping it.
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth < 480) {
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          head,
          const SizedBox(height: 12),
          trailing!,
        ]);
      }
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: head),
        trailing!,
      ]);
    });
  }
}

// ---------------------------------------------------------------------------
// Buttons
// ---------------------------------------------------------------------------

enum BtnKind { primary, secondary, ghost, destructive, danger }

class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.kind = BtnKind.secondary,
    this.icon,
    this.trailingIcon,
    this.compact = false,
    this.expand = false,
    this.loading = false,
    this.translate = true,
  });
  final String label;
  final VoidCallback? onPressed;
  final BtnKind kind;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool compact;
  final bool expand;
  final bool loading;
  final bool translate;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    final enabled = widget.onPressed != null && !widget.loading;
    Color bg = Colors.transparent;
    Color fg = t.ivory;
    Color? border;
    switch (widget.kind) {
      case BtnKind.primary:
        bg = _hover && enabled ? AppTokens.primaryHover : t.yellow;
        fg = AppTokens.onYellow;
        break;
      case BtnKind.secondary:
        bg = _hover && enabled ? t.surface3 : t.surface2;
        border = t.line;
        break;
      case BtnKind.ghost:
        fg = _hover && enabled ? t.ivory : t.muted;
        break;
      case BtnKind.destructive:
        fg = t.coral;
        border = t.coral.withOpacity(0.5);
        bg = _hover && enabled ? t.coral.withOpacity(0.08) : Colors.transparent;
        break;
      case BtnKind.danger:
        bg = _hover && enabled ? AppTokens.dangerHover : t.coral;
        fg = AppTokens.onYellow;
        break;
    }
    final label = widget.translate ? context.tr(widget.label) : widget.label;
    final child = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.loading) ...[
          SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: fg)),
          const SizedBox(width: 8),
        ] else if (widget.icon != null) ...[
          DirIcon(widget.icon!, size: 16, color: fg),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(label,
              overflow: TextOverflow.ellipsis,
              style: ts(10, color: fg, weight: FontWeight.w600)),
        ),
        if (widget.trailingIcon != null) ...[
          const SizedBox(width: 8),
          DirIcon(widget.trailingIcon!, size: 16, color: fg),
        ],
      ],
    );
    return Opacity(
      opacity: enabled || widget.loading ? 1 : 0.4,
      child: MouseRegion(
        cursor:
            enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: enabled ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            constraints: BoxConstraints(minHeight: widget.compact ? 32 : 40),
            padding: EdgeInsets.symmetric(horizontal: widget.compact ? 12 : 16),
            alignment: widget.expand ? Alignment.center : null,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
              border: border != null ? Border.all(color: border) : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class LinkButton extends StatelessWidget {
  const LinkButton(this.label,
      {super.key, this.onTap, this.color, this.arrow = false, this.size = 10});
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final bool arrow;
  final double size;

  @override
  Widget build(BuildContext context) => MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            T(label,
                style: ts(size,
                    color: color ?? kTokens.yellow, weight: FontWeight.w600)),
            if (arrow) ...[
              const SizedBox(width: 4),
              DirIcon(Icons.arrow_forward,
                  size: 12, color: color ?? kTokens.yellow),
            ],
          ]),
        ),
      );
}

class IconBtn extends StatelessWidget {
  const IconBtn(this.icon,
      {super.key,
      this.onTap,
      this.size = 40,
      this.iconSize = 18,
      this.tooltip,
      this.color,
      this.bordered = true});
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final String? tooltip;
  final Color? color;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final w = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bordered ? kTokens.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: bordered ? Border.all(color: kTokens.line) : null,
          ),
          child: Icon(icon, size: iconSize, color: color ?? kTokens.muted),
        ),
      ),
    );
    return tooltip == null
        ? w
        : Tooltip(message: context.tr(tooltip!), child: w);
  }
}

/// Generic tappable with pointer cursor.
class Tap extends StatelessWidget {
  const Tap({super.key, required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => MouseRegion(
        cursor: onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
            behavior: HitTestBehavior.opaque, onTap: onTap, child: child),
      );
}

// ---------------------------------------------------------------------------
// Pills, chips, tags
// ---------------------------------------------------------------------------

class StatusPill extends StatelessWidget {
  const StatusPill(this.text,
      {super.key, this.tone = Tone.muted, this.translate = true});
  final String text;
  final Tone tone;
  final bool translate;

  @override
  Widget build(BuildContext context) {
    final c = toneColor(tone);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Flexible(
        child: Text(translate ? context.tr(text) : text,
            overflow: TextOverflow.ellipsis,
            style: ts(9, color: c, weight: FontWeight.w600)),
      ),
    ]);
  }
}

class Dot extends StatelessWidget {
  const Dot(this.color, {super.key, this.size = 6});
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

class DashedTag extends StatelessWidget {
  const DashedTag(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: DashedRectPainter(color: kTokens.muted2, radius: 4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: T(text,
              style: ts(8, color: kTokens.muted, weight: FontWeight.w600)),
        ),
      );
}

class DashedRectPainter extends CustomPainter {
  DashedRectPainter(
      {required this.color, this.radius = 8, this.dash = 4, this.gap = 3});
  final Color color;
  final double radius, dash, gap;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
          RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final m in path.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + dash), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedRectPainter old) => old.color != color;
}

class AppChip extends StatelessWidget {
  const AppChip(
      {super.key,
      required this.label,
      this.active = false,
      this.onTap,
      this.count,
      this.translate = true});
  final String label;
  final bool active;
  final VoidCallback? onTap;
  final int? count;
  final bool translate;

  @override
  Widget build(BuildContext context) => Tap(
        onTap: onTap,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: active ? AppTokens.chipActiveBg : kTokens.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: active ? AppTokens.chipActiveBorder : kTokens.line),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(translate ? context.tr(label) : label,
                style: ts(10,
                    color: active ? kTokens.yellow : kTokens.muted,
                    weight: FontWeight.w600)),
            if (count != null) ...[
              const SizedBox(width: 6),
              Text('$count',
                  style:
                      ts(9, color: active ? kTokens.yellow : kTokens.muted2)),
            ],
          ]),
        ),
      );
}

class Avatar extends StatelessWidget {
  const Avatar(this.initials, {super.key, this.size = 32, this.color});
  final String initials;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: color ?? AppTokens.avatar, shape: BoxShape.circle),
        child: Text(initials, style: ts(size * 0.32, weight: FontWeight.w600)),
      );
}

class RoleBadge extends StatelessWidget {
  const RoleBadge(this.role, {super.key});
  final String role;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: AppTokens.badgeBorder),
          borderRadius: BorderRadius.circular(4),
        ),
        child: T(role,
            style: ts(8, color: kTokens.yellow, weight: FontWeight.w600)),
      );
}

// ---------------------------------------------------------------------------
// Containers
// ---------------------------------------------------------------------------

class Panel extends StatelessWidget {
  const Panel(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(24),
      this.height,
      this.radius = 12,
      this.color});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? height;
  final double radius;
  final Color? color;

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: color ?? kTokens.surface,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: kTokens.line),
        ),
        child: child,
      );
}

class StatCard extends StatelessWidget {
  const StatCard(
      {super.key,
      required this.label,
      required this.value,
      required this.detail,
      this.tone = Tone.ready});
  final String label, value, detail;
  final Tone tone;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 136),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: kTokens.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kTokens.line),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          T(label, style: ts(10, color: kTokens.muted)),
          const SizedBox(height: 14),
          Text(value, style: ts(28, weight: FontWeight.w500)),
          const SizedBox(height: 10),
          T(detail,
              style: ts(8, color: toneColor(tone), weight: FontWeight.w600)),
        ]),
      );
}

/// Simple responsive grid: lays children in a row with flex spans (12 col),
/// or stacks them below [breakpoint].
class SpanRow extends StatelessWidget {
  const SpanRow(
      {super.key,
      required this.spans,
      required this.children,
      this.gap = 24,
      this.breakpoint = 900});
  final List<int> spans;
  final List<Widget> children;
  final double gap;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth < breakpoint) {
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(height: gap),
                children[i],
              ],
            ]);
      }
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          Expanded(flex: spans[i], child: children[i]),
        ],
      ]);
    });
  }
}

/// Row of equal stat cards (4 columns, 2 below 1180, 1 below 600).
class StatGrid extends StatelessWidget {
  const StatGrid({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final cols =
            c.maxWidth < 600 ? 1 : (c.maxWidth < 1000 ? 2 : children.length);
        final w = (c.maxWidth - 24 * (cols - 1)) / cols;
        return Wrap(spacing: 24, runSpacing: 24, children: [
          for (final ch in children) SizedBox(width: w, child: ch),
        ]);
      });
}

class EmptyState extends StatelessWidget {
  const EmptyState(
      {super.key, required this.title, this.body, this.action, this.onAction});
  final String title;
  final String? body;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.search, size: 22, color: kTokens.muted2),
            const SizedBox(height: 12),
            T(title, style: ts(14, weight: FontWeight.w500)),
            if (body != null) ...[
              const SizedBox(height: 6),
              T(body!,
                  style: ts(11, color: kTokens.muted),
                  textAlign: TextAlign.center),
            ],
            if (action != null) ...[
              const SizedBox(height: 16),
              AppButton(label: action!, onPressed: onAction),
            ],
          ]),
        ),
      );
}

// ---------------------------------------------------------------------------
// Inputs
// ---------------------------------------------------------------------------

class AppDropdown extends StatefulWidget {
  const AppDropdown({
    super.key,
    required this.options,
    this.value,
    this.onChanged,
    this.label,
    this.height = 48,
    this.minWidth = 128,
    this.expand = false,
  });
  final List<String> options;
  final String? value;
  final ValueChanged<String>? onChanged;
  final String? label;
  final double height;
  final double minWidth;
  final bool expand;

  @override
  State<AppDropdown> createState() => _AppDropdownState();
}

class _AppDropdownState extends State<AppDropdown> {
  late String _local = widget.value ?? widget.options.first;

  String get _value => widget.onChanged != null
      ? (widget.value ?? widget.options.first)
      : _local;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    return PopupMenuButton<String>(
      tooltip: '',
      color: t.surface3,
      elevation: 8,
      position: PopupMenuPosition.under,
      constraints: const BoxConstraints(minWidth: 176),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: t.line)),
      onSelected: (v) {
        if (widget.onChanged != null) {
          widget.onChanged!(v);
        } else {
          setState(() => _local = v);
        }
      },
      itemBuilder: (context) => [
        for (final o in widget.options)
          PopupMenuItem<String>(
            value: o,
            height: 36,
            child: Row(children: [
              Expanded(
                  child: Text(context.tr(o),
                      style: ts(11, color: o == _value ? t.ivory : t.muted))),
              if (o == _value) Text('✓', style: ts(11, color: t.yellow)),
            ]),
          ),
      ],
      child: Container(
        height: widget.height,
        constraints: BoxConstraints(minWidth: widget.minWidth),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: t.line),
        ),
        child: Row(
            mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Flexible(
                fit: widget.expand ? FlexFit.tight : FlexFit.loose,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.label != null)
                      T(widget.label!,
                          style: ts(8,
                              color: t.muted2,
                              weight: FontWeight.w700,
                              spacing: 1)),
                    Text(context.tr(_value),
                        overflow: TextOverflow.ellipsis,
                        style: ts(11, weight: FontWeight.w500)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.expand_more, size: 16, color: t.muted),
            ]),
      ),
    );
  }
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: T(text,
            style: ts(10, color: kTokens.muted, weight: FontWeight.w600)),
      );
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.placeholder,
    this.error,
    this.enabled = true,
    this.maxLines = 1,
    this.obscure = false,
    this.onChanged,
    this.onSubmitted,
    this.suffix,
    this.prefixIcon,
    this.height = 48,
    this.inputFormatters,
    this.translatePlaceholder = true,
    this.focusNode,
  });
  final TextEditingController? controller;
  final String? placeholder;
  final String? error;
  final bool enabled;
  final int maxLines;
  final bool obscure;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;
  final IconData? prefixIcon;
  final double height;
  final List<TextInputFormatter>? inputFormatters;
  final bool translatePlaceholder;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    OutlineInputBorder b(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: c));
    final field = TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      maxLines: obscure ? 1 : maxLines,
      minLines: maxLines > 1 ? maxLines : null,
      obscureText: obscure,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      inputFormatters: inputFormatters,
      style: ts(12, color: enabled ? t.ivory : t.muted),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: enabled ? t.surface : t.surface2,
        hintText: placeholder == null
            ? null
            : (translatePlaceholder ? context.tr(placeholder!) : placeholder),
        hintStyle: ts(12, color: t.muted2),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 16, color: t.muted2)
            : null,
        prefixIconConstraints: const BoxConstraints(minWidth: 40),
        suffixIcon: suffix,
        contentPadding: EdgeInsets.symmetric(
            horizontal: 14, vertical: maxLines > 1 ? 14 : (height - 18) / 2),
        enabledBorder: b(error != null ? t.coral : t.line),
        disabledBorder: b(t.lineSoft),
        focusedBorder: b(error != null ? t.coral : t.yellowSoft),
      ),
    );
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          field,
          if (error != null) ...[
            const SizedBox(height: 6),
            T(error!, style: ts(10, color: t.coral)),
          ],
        ]);
  }
}

class SearchField extends StatelessWidget {
  const SearchField(
      {super.key,
      required this.placeholder,
      this.controller,
      this.onChanged,
      this.width = 320});
  final String placeholder;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: AppTextField(
          controller: controller,
          onChanged: onChanged,
          height: 40,
          prefixIcon: Icons.search,
          placeholder: context.trSearch(placeholder),
          translatePlaceholder: false,
        ),
      );
}

class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Tap(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 34,
          height: 20,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: value ? kTokens.yellow : kTokens.surface3,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: value ? kTokens.yellow : kTokens.line),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 150),
            alignment: value
                ? AlignmentDirectional.centerEnd
                : AlignmentDirectional.centerStart,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                  color: value ? AppTokens.onYellow : kTokens.muted,
                  shape: BoxShape.circle),
            ),
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// Language switch
// ---------------------------------------------------------------------------

class LanguageSwitch extends ConsumerWidget {
  const LanguageSwitch({super.key, this.height = 40});
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    Widget seg(String label, AppLang l) => Tap(
          onTap: () => ref.read(langProvider.notifier).state = l,
          child: Container(
            height: height - 8,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: lang == l ? const Color(0xFF252519) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(label,
                style: ts(10,
                    color: lang == l ? kTokens.yellow : kTokens.muted,
                    weight: FontWeight.w600)),
          ),
        );
    return Container(
      height: height,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: kTokens.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kTokens.line),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        seg('EN', AppLang.en),
        seg('العربية', AppLang.ar),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Overlays
// ---------------------------------------------------------------------------

/// Slide-in drawer on the end side.
Future<T?> showSideDrawer<T>(BuildContext context,
    {required WidgetBuilder builder,
    double width = 420,
    Color? color,
    double scrim = 0.4}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'drawer',
    barrierColor: Colors.black.withOpacity(scrim),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (ctx, a1, a2) {
      return Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Material(
          color: color ?? kTokens.surface2,
          child: Container(
            // Desktop width is preserved; small screens use the full available width.
            width: width.clamp(0.0, MediaQuery.sizeOf(ctx).width),
            height: double.infinity,
            decoration: BoxDecoration(
              border: BorderDirectional(start: BorderSide(color: kTokens.line)),
            ),
            child: Builder(builder: builder),
          ),
        ),
      );
    },
    transitionBuilder: (ctx, anim, _, child) {
      final rtl = Directionality.of(ctx) == TextDirection.rtl;
      return SlideTransition(
        position: Tween<Offset>(
                begin: Offset(rtl ? -0.3 : 0.3, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: FadeTransition(opacity: anim, child: child),
      );
    },
  );
}

/// Centered modal.
Future<T?> showAppModal<T>(BuildContext context,
    {required WidgetBuilder builder, double width = 640}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'modal',
    barrierColor: Colors.black.withOpacity(0.55),
    transitionDuration: const Duration(milliseconds: 160),
    pageBuilder: (ctx, a1, a2) => Center(
      child: Material(
        color: kTokens.surface2,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: kTokens.line)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: width.clamp(0.0, MediaQuery.of(ctx).size.width - 32),
              maxHeight: MediaQuery.of(ctx).size.height - 64),
          child: SizedBox(
              width: width.clamp(0.0, MediaQuery.of(ctx).size.width - 32),
              child: Builder(builder: builder)),
        ),
      ),
    ),
    transitionBuilder: (ctx, anim, _, child) => FadeTransition(
      opacity: anim,
      child: ScaleTransition(
          scale: Tween(begin: 0.97, end: 1.0).animate(anim), child: child),
    ),
  );
}

/// Popover anchored under the widget identified by [anchor], aligned to its end edge.
Future<T?> showAnchoredPopover<T>(BuildContext context,
    {required GlobalKey anchor,
    required WidgetBuilder builder,
    double width = 224}) {
  final box = anchor.currentContext?.findRenderObject() as RenderBox?;
  final origin = box?.localToGlobal(Offset.zero) ?? Offset.zero;
  final size = box?.size ?? Size.zero;
  final rtl = Directionality.of(context) == TextDirection.rtl;
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'popover',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 120),
    pageBuilder: (ctx, a1, a2) {
      final screen = MediaQuery.of(ctx).size;
      double left = rtl ? origin.dx : origin.dx + size.width - width;
      left = left.clamp(8.0, screen.width - width - 8);
      return Stack(children: [
        Positioned(
          left: left,
          top: origin.dy + size.height + 8,
          width: width,
          child: Material(
            color: kTokens.surface3,
            elevation: 12,
            shadowColor: Colors.black,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: kTokens.line)),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: screen.height - origin.dy - size.height - 24),
              child: Builder(builder: builder),
            ),
          ),
        ),
      ]);
    },
    transitionBuilder: (ctx, anim, _, child) =>
        FadeTransition(opacity: anim, child: child),
  );
}

/// Blurred backdrop helper (unused on platforms without filter support).
ui.ImageFilter get softBlur => ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8);
