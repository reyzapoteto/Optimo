import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'data/models.dart';
import 'features/login/login_page.dart';
import 'l10n/tr.dart';
import 'shell/shell.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

GoRouter buildRouter(Ref ref) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: ref.read(authListenableProvider),
    redirect: (context, state) {
      final role = ref.read(authProvider);
      final atLogin = state.matchedLocation == '/login';
      if (role == null) return atLogin ? null : '/login';
      if (atLogin) return '/${AppPage.excellence.slug}';
      final slug = state.pathParameters['page'];
      if (slug != null && AppPageX.fromSlug(slug) == null) return '/${AppPage.excellence.slug}';
      return null;
    },
    routes: [
      GoRoute(path: '/login', pageBuilder: (c, s) => const NoTransitionPage(child: LoginPage())),
      GoRoute(
        path: '/:page',
        pageBuilder: (c, s) => NoTransitionPage(
          child: AppShell(page: AppPageX.fromSlug(s.pathParameters['page']) ?? AppPage.excellence),
        ),
      ),
    ],
  );
}

final _routerInstanceProvider = Provider<GoRouter>((ref) {
  final r = buildRouter(ref);
  appRouter = r;
  return r;
});

class OptimoApp extends ConsumerWidget {
  const OptimoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    final router = ref.watch(_routerInstanceProvider);
    final arabic = lang == AppLang.ar;
    return MaterialApp.router(
        title: 'OPTIMO',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(arabic: arabic),
        routerConfig: router,
        builder: (context, child) => LangScope(
          lang: lang,
          child: Directionality(
            textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
    );
  }
}
