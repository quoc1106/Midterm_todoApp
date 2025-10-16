/// Purpose: Quản lý theme state của ứng dụng sử dụng StateProvider (Cấp độ 1 của Riverpod).
/// - themeProvider: StateProvider đơn giản để toggle giữa Light/Dark theme.
/// - Chứng minh "Ease of Use" của Riverpod với state management đơn giản.
/// Team: Đọc phần này để hiểu cách sử dụng StateProvider cho state nguyên thủy (enum).
library theme_providers;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Enum để định nghĩa các theme mode có thể có
enum AppTheme { light, dark, system }

// StateProvider để quản lý theme hiện tại
// Đây là ví dụ hoàn hảo của Cấp độ 1: Quản lý state đơn giản
final themeProvider = StateProvider<AppTheme>((ref) {
  return AppTheme.system; // Default theme
});

// Provider để convert AppTheme sang ThemeMode của Flutter
final themeModeProvider = Provider<ThemeMode>((ref) {
  final appTheme = ref.watch(themeProvider);

  switch (appTheme) {
    case AppTheme.light:
      return ThemeMode.light;
    case AppTheme.dark:
      return ThemeMode.dark;
    case AppTheme.system:
      return ThemeMode.system;
  }
});

// Provider cho Light Theme Data
final lightThemeProvider = Provider<ThemeData>((ref) {
  return ThemeData(
    primarySwatch: Colors.indigo,
    useMaterial3: true,
    brightness: Brightness.light,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.indigo,
      foregroundColor: Colors.white,
      elevation: 2,
    ),
  );
});

// Provider cho Dark Theme Data
final darkThemeProvider = Provider<ThemeData>((ref) {
  return ThemeData(
    primarySwatch: Colors.indigo,
    useMaterial3: true,
    brightness: Brightness.dark,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.grey,
      foregroundColor: Colors.white,
      elevation: 2,
    ),
  );
});
