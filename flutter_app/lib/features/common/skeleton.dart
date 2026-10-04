import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

class DashboardSkeleton extends StatefulWidget {
  const DashboardSkeleton({super.key});
  @override
  State<DashboardSkeleton> createState() => _DashboardSkeletonState();
}

class _DashboardSkeletonState extends State<DashboardSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  Widget block(double h) => AnimatedBuilder(
        animation: c,
        builder: (context, _) {
          final x = -1.0 + c.value * 3;
          return Container(
            height: h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment(x - 1, 0),
                end: Alignment(x + 1, 0),
                colors: [kTokens.surface, kTokens.surface2, kTokens.surface],
              ),
            ),
          );
        },
      );

  @override
  Widget build(BuildContext context) => Column(children: [
        Row(children: [
          Expanded(child: block(220)),
          const SizedBox(width: 24),
          Expanded(child: block(220)),
          const SizedBox(width: 24),
          Expanded(child: block(220)),
        ]),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(flex: 8, child: block(520)),
          const SizedBox(width: 24),
          Expanded(flex: 4, child: block(520)),
        ]),
      ]);
}
