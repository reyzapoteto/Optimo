import 'package:flutter/widgets.dart';

import '../data/models.dart';

/// Layout tiers for the Supervisor and Manager / Executive workspaces.
/// The Duty Manager layout is intentionally not tiered.
enum Tier { mobile, tablet, compact, wide }

Tier tierFor(double width) {
  if (width < 768) return Tier.mobile;
  if (width < 1024) return Tier.tablet;
  if (width < 1440) return Tier.compact;
  return Tier.wide;
}

extension ResponsiveContext on BuildContext {
  Tier get tier => tierFor(MediaQuery.sizeOf(this).width);
}

bool isResponsiveRole(Role role) =>
    role == Role.supervisor ||
    role == Role.executive ||
    role == Role.dutyManager;

/// Page padding per tier: 32 wide, 24 compact/tablet, 16 mobile.
double pagePaddingFor(Tier t) =>
    switch (t) { Tier.wide => 32, Tier.mobile => 16, _ => 24 };

/// Equal card padding per tier: 24, or 16 on mobile.
EdgeInsets cardPaddingFor(Tier t) => EdgeInsets.all(t == Tier.mobile ? 16 : 24);
