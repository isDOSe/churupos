import 'package:flutter/material.dart';

import 'colors.dart';

ThemeData buildAppTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  const scheme = ColorScheme.dark(
    primary: AppColors.ultra,
    onPrimary: AppColors.ink,
    secondary: AppColors.amber,
    onSecondary: AppColors.voidBlack,
    surface: AppColors.panel,
    onSurface: AppColors.ink,
    error: AppColors.rose,
    onError: AppColors.ink,
    outline: AppColors.line,
  );

  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.voidBlack,
    canvasColor: AppColors.voidBlack,
    splashFactory: InkSparkle.splashFactory,
    textTheme: base.textTheme.apply(
      fontFamily: 'Poppins',
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: AppColors.amber,
      selectionColor: AppColors.ultra.withValues(alpha: 0.3),
      selectionHandleColor: AppColors.ultra,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      modalBackgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.line,
      thickness: 1,
      space: 1,
    ),
    iconTheme: const IconThemeData(color: AppColors.ink, size: 20),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: AppColors.raised,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(6),
      ),
      textStyle: const TextStyle(
        fontFamily: 'Poppins',
        color: AppColors.ink,
        fontSize: 12,
      ),
    ),
  );
}
