import 'package:flutter/widgets.dart';

import 'arabic_copy.dart';

enum AppLang { en, ar }

/// Provides the active language to the tree so `context.tr` rebuilds on change.
class LangScope extends InheritedWidget {
  const LangScope({super.key, required this.lang, required super.child});

  final AppLang lang;

  static AppLang of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LangScope>()?.lang ??
      AppLang.en;

  @override
  bool updateShouldNotify(LangScope oldWidget) => oldWidget.lang != lang;
}

/// Mirrors the React DOM text-node translation: exact trimmed match against arabicCopy.
String translate(AppLang lang, String text) {
  if (lang == AppLang.en) return text;
  final key = text.trim();
  return arabicCopy[key] ?? text;
}

const String arSearchPlaceholder = 'ابحث عن مرفق أو مهمة أو موظف';

extension TrX on BuildContext {
  AppLang get lang => LangScope.of(this);
  bool get isArabic => LangScope.of(this) == AppLang.ar;
  String tr(String text) => translate(LangScope.of(this), text);
  String trSearch(String text) => isArabic ? arSearchPlaceholder : text;
}
