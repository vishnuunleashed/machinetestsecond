import 'package:flutter/material.dart';

/// Placeholder app theme. Centralizes the seed color and produces light/dark
/// [ThemeData] so screens never build their own ThemeData inline.
class AppTheme {
  const AppTheme._();

  static const Color seedColor = Colors.deepPurple;

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
      );
}
