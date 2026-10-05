import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../l10n/tr.dart';
import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import 'inspector.dart';

const twinModes = ['Service Status', 'Occupancy', 'Bin Levels', 'Devices'];

(String, Tone) modeValue(Facility f, String mode) {
  switch (mode) {
    case 'Occupancy':
      final o = f.occupancy;
      if (o == null) return ('Not monitored', Tone.muted);
      return (
        o,
        o == 'Occupied'
            ? Tone.attention
            : (o == 'Unknown' ? Tone.muted : Tone.ready)
      );
    case 'Bin Levels':
      return f.isBin ? (f.status, f.tone) : ('Not applicable', Tone.muted);
    case 'Devices':
      final d = f.deviceStatus ?? 'Unknown';
      return (
        d,
        d == 'Offline'
            ? Tone.critical
            : (d == 'Delayed' ? Tone.attention : Tone.ready)
      );
    default:
      return (f.status, f.tone);
  }
}

class DigitalTwin extends ConsumerStatefulWidget {
  const DigitalTwin({
    super.key,
    required this.role,
    required this.selectedId,
    required this.onSelect,
    required this.attentionFilter,
    required this.onClearFilter,
  });
  final Role role;
  final String? selectedId;
  final ValueChanged<String?> onSelect;
  final bool attentionFilter;
  final VoidCallback onClearFilter;

  @override
  ConsumerState<DigitalTwin> createState() => _DigitalTwinState();
}

class _DigitalTwinState extends ConsumerState<DigitalTwin> {
  String mode = 'Service Status';
  double scale = 1, panX = 0, panY = 0, orbitX = 0, orbitY = 0;
  String? hoverId;
  bool panning = false;

  @override
  void initState() {
    super.initState();
    if (widget.selectedId != null) _focus(widget.selectedId!, notify: false);
  }

  @override
  void didUpdateWidget(covariant DigitalTwin old) {
    super.didUpdateWidget(old);
    if (widget.selectedId != null && widget.selectedId != old.selectedId) {
      _focus(widget.selectedId!, notify: false);
    }
  }

  void _focus(String id, {bool notify = true}) {
    final list = ref.read(resolvedFacilitiesProvider);
    Facility? f;
    for (final x in list) {
      if (x.id == id) f = x;
    }
    if (f == null) return;
    final fx = f.x, fy = f.y;
    setState(() {
      scale = 1.3;
      panX = ((38 - (6 + fx * .88)) * 8).clamp(-260.0, 260.0);
      panY = ((45 - (12 + fy * .76)) * 5).clamp(-120.0, 120.0);
      orbitX = fx > 50 ? -1.5 : 1.5;
      orbitY = 1;
    });
    if (notify) widget.onSelect(id);
  }

  void _reset() => setState(() {
        scale = 1;
        panX = panY = orbitX = orbitY = 0;
        widget.onSelect(null);
      });

  bool _faded(Facility f) {
    if (mode == 'Bin Levels' && !f.isBin) return true;
    if (mode == 'Occupancy' && f.isBin) return true;
    if (widget.attentionFilter &&
        !(f.tone == Tone.attention ||
            f.tone == Tone.critical ||
            f.tone == Tone.cleaning)) {
      return true;
    }
    if (widget.selectedId != null && widget.selectedId != f.id) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    final list = ref.watch(resolvedFacilitiesProvider);
    Facility? selected;
    for (final f in list) {
      if (f.id == widget.selectedId) selected = f;
    }
    final relevant =
        list.where((f) => !_faded(f) || f.id == widget.selectedId).length;

    // Phones: stacked header, wrapping toolbars, shorter map, 44px controls,
    // and the inspector as a full-width overlay sheet.
    final mobile = MediaQuery.sizeOf(context).width < 768;
    final hp = mobile ? 16.0 : 24.0;
    final ctl = mobile ? 44.0 : 32.0;
    final heading =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Eyebrow('LIVE SPATIAL OPERATIONS'),
      const SizedBox(height: 6),
      Wrap(
          spacing: 10,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            T('OPTIMO Live Digital Twin',
                style: ts(18, weight: FontWeight.w500)),
            const DashedTag('Illustrative demo layout'),
          ]),
      const SizedBox(height: 6),
      T(
          mobile
              ? 'Drag to orbit · Pinch or use + / − to zoom · Tap a facility to investigate.'
              : 'Drag to orbit · Shift-drag to pan · Select a facility to investigate.',
          style: ts(mobile ? 12 : 10, color: t.muted2, height: 1.5)),
    ]);
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (mobile)
          Padding(
            padding: EdgeInsets.fromLTRB(hp, 16, hp, 16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  heading,
                  const SizedBox(height: 12),
                  Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: _LocateField(
                          facilities: list, onPick: (id) => _focus(id))),
                ]),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Eyebrow('LIVE SPATIAL OPERATIONS'),
                      const SizedBox(height: 6),
                      Wrap(
                          spacing: 10,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            T('OPTIMO Live Digital Twin',
                                style: ts(18, weight: FontWeight.w500)),
                            const DashedTag('Illustrative demo layout'),
                          ]),
                      const SizedBox(height: 6),
                      T('Drag to orbit · Shift-drag to pan · Select a facility to investigate.',
                          style: ts(10, color: t.muted2)),
                    ]),
              ),
              _LocateField(facilities: list, onPick: (id) => _focus(id)),
            ]),
          ),
        Container(
          color: AppTokens.modebar,
          padding: EdgeInsets.symmetric(horizontal: hp, vertical: 10),
          child: Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Padding(
                          padding: EdgeInsetsDirectional.only(end: 4),
                          child: Eyebrow('VIEW MODE')),
                      for (final m in twinModes)
                        AppChip(
                            label: m,
                            active: mode == m,
                            onTap: () => setState(() => mode = m)),
                    ]),
                Text(
                    '${context.tr('Main Club')} › ${context.tr('Ground Floor')} › ${context.tr('Washroom / Changing Area')}',
                    style: ts(mobile ? 12 : 9, color: t.muted2)),
                if (widget.attentionFilter)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTokens.filterBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTokens.filterBorder),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const StatusPill('Readiness filter',
                          tone: Tone.attention),
                      const SizedBox(width: 10),
                      T('Showing facilities requiring attention',
                          style: ts(9, color: t.muted)),
                      const SizedBox(width: 10),
                      LinkButton('Clear filter ×',
                          size: 9, onTap: widget.onClearFilter),
                    ]),
                  ),
              ]),
        ),
        SizedBox(
          height: mobile ? 420 : 560,
          child: Stack(children: [
            Positioned.fill(child: _viewport(context, list)),
            PositionedDirectional(
              top: 16,
              end: selected != null && !mobile ? 336 : 16,
              child: Column(children: [
                IconBtn(Icons.add,
                    size: ctl,
                    iconSize: 16,
                    onTap: () =>
                        setState(() => scale = (scale + 0.15).clamp(1.0, 1.8))),
                const SizedBox(height: 6),
                IconBtn(Icons.remove,
                    size: ctl,
                    iconSize: 16,
                    onTap: () =>
                        setState(() => scale = (scale - 0.15).clamp(1.0, 1.8))),
                const SizedBox(height: 6),
                IconBtn(Icons.center_focus_strong_outlined,
                    size: ctl,
                    iconSize: 16,
                    tooltip: 'Reset view',
                    onTap: _reset),
              ]),
            ),
            PositionedDirectional(
              start: 16,
              top: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xD911120E),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: t.line),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('N',
                      style: ts(9, color: t.yellow, weight: FontWeight.w700)),
                  const SizedBox(width: 4),
                  Text('${(scale * 100).round()}%',
                      style: ts(9, color: t.muted)),
                  const SizedBox(width: 8),
                  T('Elevated cutaway', style: ts(9, color: t.muted2)),
                ]),
              ),
            ),
            PositionedDirectional(
              start: 16,
              bottom: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xD911120E),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: t.line),
                ),
                constraints: BoxConstraints(
                    maxWidth:
                        MediaQuery.sizeOf(context).width - (mobile ? 96 : 120)),
                child: mode == 'Service Status'
                    ? Wrap(spacing: 8, runSpacing: 6, children: [
                        for (final k in const [
                          ('Ready', Tone.ready),
                          ('Service Required', Tone.attention),
                          ('Cleaning', Tone.cleaning),
                          ('Out of Service', Tone.critical),
                        ])
                          StatusPill(k.$1, tone: k.$2),
                      ])
                    : Text(
                        '${context.tr(mode)} · $relevant ${context.tr('relevant facilities')}',
                        style: ts(9, color: t.muted)),
              ),
            ),
            if (selected != null)
              PositionedDirectional(
                top: mobile ? 8 : 16,
                bottom: mobile ? 8 : 16,
                end: mobile ? 8 : 16,
                start: mobile ? 8 : null,
                child: Inspector(
                    width: mobile ? null : 304,
                    facility: selected,
                    role: widget.role,
                    onClose: () => widget.onSelect(null)),
              ),
          ]),
        ),
      ]),
    );
  }

  Widget _viewport(BuildContext context, List<Facility> list) {
    return Listener(
      onPointerDown: (e) {
        panning = HardwareKeyboard.instance.isShiftPressed ||
            e.buttons == kSecondaryMouseButton;
      },
      onPointerMove: (e) {
        final d = e.delta;
        setState(() {
          if (panning) {
            panX = (panX + d.dx).clamp(-260.0, 260.0);
            panY = (panY + d.dy).clamp(-160.0, 160.0);
          } else {
            orbitX = (orbitX + d.dx * .018).clamp(-5.0, 5.0);
            orbitY = (orbitY - d.dy * .012).clamp(-2.0, 4.0);
          }
        });
      },
      onPointerSignal: (e) {
        if (e is PointerScrollEvent) {
          setState(() => scale =
              (scale + (e.scrollDelta.dy < 0 ? 0.08 : -0.08)).clamp(1.0, 1.8));
        }
      },
      child: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
              colors: [Color(0xFF20221E), Color(0xFF0C0D0B)], radius: 0.9),
        ),
        child: ClipRect(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: LayoutBuilder(builder: (context, c) {
              final w = c.maxWidth * 0.88;
              final h = w * 941 / 1671;
              final m = Matrix4.identity()
                ..translate(panX + orbitX * 2, panY + orbitY * 2)
                ..scale(scale, scale)
                ..multiply(Matrix4.skewX(orbitX * 0.12 * 3.1415926535 / 180));
              return Stack(children: [
                Positioned(
                  left: c.maxWidth * 0.06,
                  top: (c.maxHeight - h) / 2,
                  width: w,
                  height: h,
                  child: Transform(
                    transform: m,
                    alignment: Alignment.center,
                    child: Stack(clipBehavior: Clip.none, children: [
                      Positioned.fill(
                        child: Image.asset(
                            'assets/images/optimo-digital-twin-isolated.png',
                            fit: BoxFit.contain),
                      ),
                      for (final f in list)
                        Positioned(
                          left: f.x / 100 * w - 6,
                          top: f.y / 100 * h - 6,
                          child: _marker(context, f),
                        ),
                    ]),
                  ),
                ),
              ]);
            }),
          ),
        ),
      ),
    );
  }

  Widget _marker(BuildContext context, Facility f) {
    final t = context.tk;
    final mv = modeValue(f, mode);
    final tone = mode == 'Service Status' ? f.tone : mv.$2;
    final c = toneColor(tone);
    final selected = widget.selectedId == f.id;
    final hovering = hoverId == f.id;
    return Opacity(
      opacity: _faded(f) ? 0.46 : 1,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => hoverId = f.id),
        onExit: (_) => setState(() => hoverId = null),
        child: GestureDetector(
          onTap: () => _focus(f.id),
          child: Stack(clipBehavior: Clip.none, children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: selected ? 12 : 10,
                height: selected ? 12 : 10,
                decoration: BoxDecoration(
                  color: c.withOpacity(0.35),
                  shape: BoxShape.circle,
                  border: Border.all(color: c, width: 2),
                  boxShadow: [
                    if (selected || f.priority)
                      BoxShadow(color: c.withOpacity(0.5), blurRadius: 10)
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xD911120E),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: selected ? c : t.lineSoft),
                ),
                child: Text(f.id,
                    style: ts(8, color: t.ivory, weight: FontWeight.w600)),
              ),
            ]),
            if (hovering)
              Positioned(
                left: 0,
                bottom: 20,
                child: Container(
                  width: 150,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: t.surface3,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: t.line),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(f.id, style: ts(10, weight: FontWeight.w600)),
                        Text(context.tr(f.type), style: ts(9, color: t.muted2)),
                        const SizedBox(height: 3),
                        Text(context.tr(mv.$1),
                            style: ts(9, color: toneColor(mv.$2))),
                      ]),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

class _LocateField extends StatefulWidget {
  const _LocateField({required this.facilities, required this.onPick});
  final List<Facility> facilities;
  final ValueChanged<String> onPick;

  @override
  State<_LocateField> createState() => _LocateFieldState();
}

class _LocateFieldState extends State<_LocateField> {
  final ctrl = TextEditingController();
  final portal = OverlayPortalController();
  final link = LayerLink();
  final focus = FocusNode();

  @override
  void initState() {
    super.initState();
    focus.addListener(() {
      if (!focus.hasFocus) {
        Future<void>.delayed(const Duration(milliseconds: 150), () {
          if (mounted && !focus.hasFocus) portal.hide();
        });
      }
    });
  }

  @override
  void dispose() {
    ctrl.dispose();
    focus.dispose();
    super.dispose();
  }

  List<Facility> get matches {
    final q = ctrl.text.trim().toUpperCase();
    if (q.isEmpty) return const [];
    return widget.facilities
        .where((f) =>
            f.id.contains(q) ||
            f.type.toUpperCase().contains(q) ||
            f.zone.toUpperCase().contains(q))
        .take(4)
        .toList();
  }

  void _pick(String id) {
    widget.onPick(id);
    ctrl.clear();
    portal.hide();
    focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    return CompositedTransformTarget(
      link: link,
      child: OverlayPortal(
        controller: portal,
        overlayChildBuilder: (_) {
          final m = matches;
          return CompositedTransformFollower(
            link: link,
            targetAnchor: Alignment.bottomLeft,
            offset: const Offset(0, 6),
            child: Align(
              alignment: Alignment.topLeft,
              child: Material(
                color: t.surface3,
                elevation: 10,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: t.line)),
                child: SizedBox(
                  width: 184,
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (m.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: T('No facility found',
                                style: ts(10, color: t.muted)),
                          )
                        else
                          for (final f in m)
                            Tap(
                              onTap: () => _pick(f.id),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(f.id,
                                          style:
                                              ts(11, weight: FontWeight.w600)),
                                      Text(
                                          '${context.tr(f.type)} · ${context.tr(f.zone)}',
                                          style: ts(9, color: t.muted2)),
                                    ]),
                              ),
                            ),
                      ]),
                ),
              ),
            ),
          );
        },
        child: SizedBox(
          width: 184,
          child: AppTextField(
            controller: ctrl,
            focusNode: focus,
            height: 40,
            prefixIcon: Icons.search,
            placeholder: 'Locate facility',
            onChanged: (v) {
              final up = v.toUpperCase();
              if (up != v) {
                ctrl.value = ctrl.value.copyWith(
                    text: up,
                    selection: TextSelection.collapsed(offset: up.length));
              }
              if (up.trim().isEmpty) {
                portal.hide();
              } else {
                portal.show();
              }
              setState(() {});
            },
            onSubmitted: (_) {
              final m = matches;
              if (m.isNotEmpty) _pick(m.first.id);
            },
          ),
        ),
      ),
    );
  }
}
