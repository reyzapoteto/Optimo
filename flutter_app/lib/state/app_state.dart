import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/mock_data.dart';
import '../data/models.dart';
import '../l10n/tr.dart';

/// Overridden in main() with the loaded instance.
final prefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

/// Router instance, assigned in app.dart so actions can navigate.
late GoRouter appRouter;

final authProvider = StateProvider<Role?>((ref) => null);
final langProvider = StateProvider<AppLang>((ref) => AppLang.en);
final scopeProvider = StateProvider<String>((ref) => 'My zones');
final focusFacilityProvider = StateProvider<String?>((ref) => null);
final focusTaskProvider = StateProvider<String?>((ref) => null);
final bootingProvider = StateProvider<bool>((ref) => false);

/// 0 = Online, 1 = Delayed data, 2 = Offline.
final connectionProvider = StateProvider<int>((ref) => 0);

/// Simple app toast (bottom end).
final toastProvider = StateProvider<String?>((ref) => null);

const _ownershipKey = 'optimo-ownership';

class OwnershipNotifier extends Notifier<Map<String, Ownership>> {
  @override
  Map<String, Ownership> build() {
    final prefs = ref.read(prefsProvider);
    final raw = prefs.getString(_ownershipKey);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        return decoded.map((k, v) => MapEntry(k, Ownership.fromJson(v as Map<String, dynamic>)));
      } catch (_) {}
    }
    return Map.of(initialOwnership);
  }

  void _persist() {
    ref.read(prefsProvider).setString(
          _ownershipKey,
          jsonEncode(state.map((k, v) => MapEntry(k, v.toJson()))),
        );
  }

  void set(String id, Ownership value) {
    state = {...state, id: value};
    _persist();
  }

  void modify(String id, Ownership Function(Ownership current) fn) {
    set(id, fn(state[id] ?? const Ownership()));
  }
}

final ownershipProvider = NotifierProvider<OwnershipNotifier, Map<String, Ownership>>(OwnershipNotifier.new);

final resolvedFacilitiesProvider = Provider<List<Facility>>((ref) {
  final own = ref.watch(ownershipProvider);
  return [for (final f in facilities) resolveFacility(f, own)];
});

/// Notifies GoRouter when auth changes.
class AuthListenable extends ChangeNotifier {
  void ping() => notifyListeners();
}

final authListenableProvider = Provider<AuthListenable>((ref) {
  final l = AuthListenable();
  ref.listen<Role?>(authProvider, (_, __) => l.ping());
  ref.onDispose(l.dispose);
  return l;
});

Timer? _toastTimer;
Timer? _bootTimer;

/// Imperative app actions mirroring the React App component callbacks.
class AppActions {
  AppActions(this.ref);
  final Ref ref;

  GoRouter get _router => appRouter;

  void toast(String message, {int ms = 2600}) {
    _toastTimer?.cancel();
    ref.read(toastProvider.notifier).state = message;
    _toastTimer = Timer(Duration(milliseconds: ms), () {
      ref.read(toastProvider.notifier).state = null;
    });
  }

  void enter(Role role) {
    ref.read(authProvider.notifier).state = role;
    ref.read(focusFacilityProvider.notifier).state = null;
    ref.read(focusTaskProvider.notifier).state = null;
    ref.read(bootingProvider.notifier).state = true;
    _bootTimer?.cancel();
    _bootTimer = Timer(const Duration(milliseconds: 700), () {
      ref.read(bootingProvider.notifier).state = false;
    });
    _router.go('/${AppPage.excellence.slug}');
  }

  void switchRole(Role role) => enter(role);

  void logout() {
    ref.read(authProvider.notifier).state = null;
    _router.go('/login');
  }

  /// Sidebar navigation clears focus.
  void navigate(AppPage page) {
    ref.read(focusFacilityProvider.notifier).state = null;
    ref.read(focusTaskProvider.notifier).state = null;
    _router.go('/${page.slug}');
  }

  void go(AppPage page) => _router.go('/${page.slug}');

  void openFacility(String id) {
    ref.read(focusFacilityProvider.notifier).state = id;
    _router.go('/${AppPage.excellence.slug}');
  }

  void openTask(String id) {
    ref.read(focusTaskProvider.notifier).state = id;
    _router.go('/${AppPage.tasks.slug}');
  }

  void toggleLanguage() {
    final n = ref.read(langProvider.notifier);
    n.state = n.state == AppLang.en ? AppLang.ar : AppLang.en;
  }
}

final actionsProvider = Provider<AppActions>((ref) => AppActions(ref));
