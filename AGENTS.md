# figma-make-app

Flutter Web project running inside Figma Make.

## Development Server

A Flutter Web development server is **already running** on `$PORT`. You don't need to start it manually.

- Preview URL: The user can access the running app through the preview panel
- Hot reload: Changes to Dart source files are reflected by the supervised Flutter process

## Project Structure

This is the canonical project structure. Start with task-relevant files below.

- `flutter_app/lib/main.dart` - Flutter entrypoint
- `flutter_app/lib/app.dart` - Application router and root Material app
- `flutter_app/lib/theme/` - OPTIMO tokens, typography, and Material theme
- `flutter_app/lib/state/` - Riverpod application state and actions
- `flutter_app/lib/shell/` - Shared sidebar, header, notifications, and profile UI
- `flutter_app/lib/features/` - Role-aware application pages
- `flutter_app/lib/data/` - Models and prototype data
- `flutter_app/lib/l10n/` - English/Arabic localization and RTL support
- `flutter_app/pubspec.yaml` - Flutter dependencies and asset declarations
- `src/` - Legacy React migration reference; it is not the active runtime

## Dependencies

- Runtime: Flutter 3.24.5 and Dart 3.5
- State: Riverpod
- Routing: go_router
- Typography: google_fonts
- Persistence: shared_preferences

## Styling

Use the shared OPTIMO tokens and theme from `flutter_app/lib/theme/`. Reuse widgets from
`flutter_app/lib/widgets/common.dart` before adding new primitives. Keep Manager/Executive
operational data read-only and preserve Arabic RTL behavior.

## Code quality

- Format Dart with `dart format`.
- Run `flutter analyze --no-fatal-infos --no-fatal-warnings` for static verification.
- Run `flutter build web --release` for production verification.
- Do not start another development server; `.figma/make/dev` owns the Flutter Web process.
