import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../l10n/tr.dart';
import '../../shell/page_intro.dart';
import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import 'trend_chart.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});
  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  String period = 'Last 30 days';
  String zone = 'All Zones';
  String facility = 'All Facilities';

  @override
  Widget build(BuildContext context) {
    final t = context.tk;
    final sla = facility == 'Waste Bins' ? '92.4%' : (zone == 'Changing Rooms' ? '94.9%' : '95.8%');
    final resp = period == 'Last 7 days' ? '01:46' : (zone == 'Pool' ? '01:38' : '01:52');
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PageIntro(page: AppPage.reports, actions: [
        AppDropdown(
          label: 'PERIOD',
          value: period,
          options: const ['Last 7 days', 'Last 30 days', 'This quarter'],
          onChanged: (v) => setState(() => period = v),
        ),
        AppDropdown(
          label: 'ZONE',
          value: zone,
          options: const ['All Zones', 'Changing Rooms', 'Pool', 'Training'],
          onChanged: (v) => setState(() => zone = v),
        ),
        AppDropdown(
          label: 'FACILITY',
          value: facility,
          options: const ['All Facilities', 'Showers', 'Toilets', 'Waste Bins'],
          onChanged: (v) => setState(() => facility = v),
        ),
        AppButton(label: 'Export report', onPressed: () => ref.read(actionsProvider).toast('Export ready')),
      ]),
      StatGrid(children: [
        StatCard(label: 'SLA performance', value: sla, detail: '+2.4% vs prior period'),
        StatCard(label: 'Average response', value: resp, detail: '8 sec inside target'),
        const StatCard(label: 'Tasks completed', value: '684', detail: '+6.2% this period'),
        const StatCard(label: 'Facility downtime', value: '2h 18m', detail: '-14% this period'),
      ]),
      const SizedBox(height: 24),
      SpanRow(spans: const [2, 1], children: [
        ReportTrendChart(period: period, zone: zone, facilityType: facility),
        Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionHead(eyebrow: 'BY FACILITY TYPE', title: 'Service standard'),
            const SizedBox(height: 20),
            for (final b in const [('Showers', 97), ('Toilets', 95), ('Waste Bins', 92), ('Pool Facilities', 98)])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: T(b.$1, style: ts(11))),
                    Text('${b.$2}%', style: ts(11, weight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: b.$2 / 100,
                      minHeight: 6,
                      color: t.yellow,
                      backgroundColor: AppTokens.track,
                    ),
                  ),
                ]),
              ),
          ]),
        ),
      ]),
    ]);
  }
}
