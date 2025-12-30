import 'package:flutter/material.dart';
import 'package:everyday_christian/theme/app_theme_extensions.dart';

extension ThemeContextExtension on BuildContext {
  AppThemeExtension get theme => Theme.of(this).extension<AppThemeExtension>()!;
}
