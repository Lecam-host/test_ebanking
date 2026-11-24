import 'package:flutter/material.dart';
import 'package:test_ebanking/core/presentation/app_colors.dart';

/// Police du kit, déclarée dans pubspec.yaml.
const appFontFamily = 'Poppins';

/// Thème de l'app, d'après le kit Figma : un seul endroit pour les couleurs,
/// les champs et les boutons, que tous les écrans reprennent.
///
/// `fontFamily` du thème ne couvre que les textes qui héritent du thème : les
/// styles écrits en entier ici (en-tête, boutons) la reprennent eux-mêmes.
ThemeData buildAppTheme() {
  OutlineInputBorder border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(15),
    borderSide: BorderSide(color: color),
  );

  return ThemeData(
    fontFamily: appFontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      surface: Colors.white,
      onSurface: AppColors.text,
      error: AppColors.red,
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: appFontFamily,
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: const TextStyle(color: AppColors.placeholder, fontSize: 14),
      // 44 de haut, comme sur la maquette : ligne de 24 + 2 × 10.
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: border(AppColors.border),
      enabledBorder: border(AppColors.border),
      disabledBorder: border(AppColors.surfaceTint),
      focusedBorder: border(AppColors.primary),
      errorBorder: border(AppColors.red),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.surfaceTint,
        disabledForegroundColor: Colors.white,
        textStyle: const TextStyle(
          fontFamily: appFontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(
          fontFamily: appFontFamily,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
