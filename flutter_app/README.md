# OPTIMO Ops (Flutter)

A Flutter port of the React prototype in `../src` (Hospitality Excellence Center).

## Run

```bash
cd flutter_app
# Platform folders (web/, macos/, windows/) are not committed. Generate them once:
flutter create . --platforms=web,macos,windows
flutter pub get
flutter run -d chrome
```

## Demo sign-in

| Role | Staff ID | Password |
|---|---|---|
| Duty Manager | DM-002 | any, 4 or more characters |
| Supervisor | SUP-014 | any, 4 or more characters |

- `SUP-099` (or 4 failed attempts) shows the locked-account state.
- `OFFLINE` shows the no-connection state. This stands in for `navigator.onLine`.

## Structure

- `lib/theme`: design tokens (`AppTokens`, a ThemeExtension) and the dark Material 3 theme
- `lib/l10n`: the Arabic copy map, generated from `App.tsx`, plus the `context.tr()` helper
- `lib/data`: mock data and models
- `lib/state`: Riverpod providers (auth, language, scope, ownership persisted with shared_preferences)
- `lib/shell`: sidebar, header, popovers, drawers, toasts, shift pulse bar
- `lib/widgets`: shared UI primitives
- `lib/features/*`: one folder per page
