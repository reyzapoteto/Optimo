import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_data.dart';
import '../data/models.dart';
import '../l10n/tr.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';

class LiveLabel extends StatelessWidget {
  const LiveLabel({super.key});
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Dot(kTokens.green),
        const SizedBox(width: 8),
        const Eyebrow('LIVE OPERATIONS', color: null),
        const SizedBox(width: 4),
        const Eyebrow('· UPDATED NOW'),
      ]);
}

/// Page header used by every non-home page: live label, serif title, description and actions.
class PageIntro extends ConsumerWidget {
  const PageIntro({super.key, required this.page, this.actions = const []});
  final AppPage page;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authProvider);
    final w = MediaQuery.sizeOf(context).width;
    final responsive = role != null;
    final size = responsive && w < 768
        ? 24.0
        : (responsive && w < 1024
            ? 28.0
            : (role == Role.supervisor ? 30.0 : 34.0));
    final text =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const LiveLabel(),
      const SizedBox(height: 10),
      Text(context.tr(page.label),
          style: AppFonts.title(size, arabic: context.isArabic)),
      const SizedBox(height: 8),
      T(pageDescriptions[page] ?? '', style: ts(12, color: kTokens.muted)),
    ]);
    return Padding(
      padding: EdgeInsets.only(bottom: responsive && w < 768 ? 16 : 28),
      child: LayoutBuilder(builder: (context, c) {
        if (c.maxWidth < 900 || actions.isEmpty) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                text,
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(spacing: 8, runSpacing: 8, children: actions),
                ],
              ]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(child: text),
          const SizedBox(width: 24),
          Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: actions),
        ]);
      }),
    );
  }
}
