import 'dart:ui';
import '../constants/app_color.dart';
import 'package:flutter/material.dart';


final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xff0F1F1C),
  // scaffoldBackgroundColor: Colors.black,

  colorScheme:  ColorScheme.dark(
    secondary: AppColors.secondary,
    primary: AppColors.primary,
    // surface: Color(0xff1E2E2B),
    surface: AppColors.darkSurface,
    onPrimary: Colors.black,
    onSurface: Colors.white,
    error: AppColors.red,
  ),

  appBarTheme:  AppBarTheme(
    backgroundColor: AppColors.darkSurface,
    foregroundColor: Colors.white,
    elevation: 0,
  ),
);
