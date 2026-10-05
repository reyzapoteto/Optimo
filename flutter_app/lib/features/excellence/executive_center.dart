import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../l10n/tr.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import 'charts.dart';

class ExecutiveCenter extends ConsumerWidget {
  const ExecutiveCenter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.read(actionsProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(spacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Icon(Icons.lock_outline, size: 14, color: context.tk.yellow),
        T('Read-only executive overview', style: ts(10, color: context.tk.muted)),
      ]),
      const SizedBox(height: 18),
      SpanRow(spans: const [3, 3, 3, 3], breakpoint: 1040, children: const [
        _ExecutiveKpi('Operational readiness', '89%', '16 of 18 showers ready', Tone.ready),
        _ExecutiveKpi('SLA compliance', '94%', 'Response and completion', Tone.attention),
        _ExecutiveKpi('Quality pass rate', '96%', 'Up 2% this period', Tone.ready),
        _ExecutiveKpi('Open issues', '4', '1 high severity', Tone.critical),
      ]),
      const SizedBox(height: 24),
      SpanRow(spans: const [8, 4], breakpoint: 1080, children: [
        const PerformanceChart(),
        Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SectionHead(
              eyebrow: 'MANAGEMENT ATTENTION',
              title: 'Priority overview',
              trailing: LinkButton('All issues', arrow: true, onTap: () => actions.navigate(AppPage.issues)),
            ),
            const SizedBox(height: 16),
            const _AttentionRow('SH-04', 'Service response approaching SLA', Tone.attention),
            const _AttentionRow('WC-03', 'Device offline · status unverified', Tone.critical),
            const _AttentionRow('BIN-02', 'Service threshold approaching', Tone.attention),
          ]),
        ),
      ]),
      const SizedBox(height: 24),
      Panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionHead(
            eyebrow: 'EXECUTIVE BRIEFING',
            title: 'Club performance at a glance',
            trailing: LinkButton('Open reports', arrow: true, onTap: () => actions.navigate(AppPage.reports)),
          ),
          const SizedBox(height: 18),
          Text(
            'Service performance remains within target across the Main Club. Readiness is stable, '
            'quality is trending upward, and one high-severity issue requires management awareness.',
            style: ts(12, color: context.tk.muted, height: 1.7),
          ),
          const SizedBox(height: 20),
          Wrap(spacing: 32, runSpacing: 16, children: const [
            _BriefMetric('Response SLA', '93%'),
            _BriefMetric('Completion SLA', '95%'),
            _BriefMetric('Inspections passed', '48 / 50'),
            _BriefMetric('Devices online', '41 / 42'),
          ]),
        ]),
      ),
    ]);
  }
}

class _ExecutiveKpi extends StatelessWidget {
  const _ExecutiveKpi(this.label, this.value, this.detail, this.tone);
  final String label, value, detail;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Dot(toneColor(tone)),
          const SizedBox(width: 8),
          Expanded(child: T(label, style: ts(11, color: t.muted))),
        ]),
        const SizedBox(height: 18),
        Text(value, style: AppFonts.title(38, arabic: context.isArabic)),
        const SizedBox(height: 8),
        T(detail, style: ts(10, color: t.muted2)),
      ]),
    );
  }
}

class _AttentionRow extends StatelessWidget {
  const _AttentionRow(this.id, this.label, this.tone);
  final String id, label;
  final Tone tone;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(children: [
          Dot(toneColor(tone)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(id, style: ts(10, weight: FontWeight.w600)),
            const SizedBox(height: 3),
            T(label, style: ts(9, color: context.tk.muted)),
          ])),
        ]),
      );
}

class _BriefMetric extends StatelessWidget {
  const _BriefMetric(this.label, this.value);
  final String label, value;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 160,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: AppFonts.title(28, arabic: context.isArabic)),
          const SizedBox(height: 4),
          T(label, style: ts(9, color: context.tk.muted2)),
        ]),
      );
}
