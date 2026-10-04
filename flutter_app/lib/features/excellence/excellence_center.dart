import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import 'dm_center.dart';
import 'supervisor_center.dart';

class ExcellenceCenter extends ConsumerWidget {
  const ExcellenceCenter({super.key, required this.role});
  final Role role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focus = ref.read(focusFacilityProvider);
    return role == Role.dutyManager ? DmCenter(initialFocus: focus) : SupervisorCenter(initialFocus: focus);
  }
}
