import 'dart:ui';

import 'package:flutter/material.dart';

import '../constants/app_color.dart';

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: AppColors.whiteGhost,
  primaryColor: AppColors.primary,

  colorScheme:  ColorScheme.light(
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    surface: Colors.white,
    onPrimary: Colors.white,
    onSurface: Colors.black,
  ),

  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    elevation: 0,
  ),

  textTheme: const TextTheme(
    bodyMedium: TextStyle(fontFamily: 'Poppins'),
  ),
);
