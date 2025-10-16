/// 🎨 FRONTEND COMPONENTS - Theme Toggle Widget
///
/// ⭐ RIVERPOD LEVEL 1-2 DEMONSTRATION ⭐
/// Simple State Management with Enhanced UI
///
/// EDUCATIONAL VALUE:
/// - LEVEL 1: Basic StateProvider patterns for simple state
/// - LEVEL 2: Provider watching and reading with UI coordination
/// - Clean theme switching with immediate visual feedback
/// - Beautiful animated theme transitions
///
/// ARCHITECTURE PATTERNS:
/// 1. StateProvider for simple theme state management
/// 2. Provider reading for state mutations
/// 3. Provider watching for reactive UI updates
/// 4. Animated theme transitions with provider integration

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/theme_providers.dart';

/// ⭐ LEVEL 1-2: Enhanced Theme Toggle with Smooth Animations
///
/// DEMONSTRATES:
/// - StateProvider usage for simple theme state
/// - Provider watching for reactive UI updates
/// - Provider reading for state mutations
/// - Beautiful animated theme switching experience
class ThemeToggleWidget extends ConsumerWidget {
  const ThemeToggleWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    /// ⭐ LEVEL 1: Basic Provider Watching
    /// Simple state watching for reactive UI updates
    final currentTheme = ref.watch(themeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        // Enhanced background for better visibility with stronger contrast
        color: isDark
            ? Colors.white.withOpacity(0.2) // Increased opacity for dark theme
            : Colors.black.withOpacity(
                0.12,
              ), // Increased opacity for light theme
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.5) // Stronger border for dark theme
              : Colors.black.withOpacity(
                  0.3,
                ), // Stronger border for light theme
          width: 1.5, // Thicker border
        ),
      ),
      child: PopupMenuButton<AppTheme>(
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Icon(
            _getThemeIcon(currentTheme),
            key: ValueKey(currentTheme),
            color: _getThemeColor(currentTheme, context),
            size: 22, // Slightly larger icon
          ),
        ),
        tooltip: 'Switch Theme (${_getThemeDisplayName(currentTheme)})',
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,

        /// ⭐ LEVEL 2: Provider State Mutation
        /// Using ref.read() to update state through provider
        onSelected: (AppTheme theme) {
          // Simple StateProvider mutation - LEVEL 1 pattern
          ref.read(themeProvider.notifier).state = theme;
        },
        itemBuilder: (context) => AppTheme.values
            .where(
              (theme) => theme != AppTheme.system,
            ) // Filter out system theme
            .map((theme) {
              final isSelected = currentTheme == theme;

              return PopupMenuItem(
                value: theme,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: isSelected
                        ? Theme.of(context).primaryColor.withOpacity(0.1)
                        : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      /// Theme Icon with Animation
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? _getThemeColor(theme, context).withOpacity(0.2)
                              : Colors.transparent,
                        ),
                        child: Icon(
                          _getThemeIcon(theme),
                          color: _getThemeColor(theme, context),
                          size: 20,
                        ),
                      ),

                      const SizedBox(width: 12),

                      /// Theme Label
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _getThemeDisplayName(theme),
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : null,
                              ),
                            ),
                            Text(
                              _getThemeDescription(theme),
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ),

                      /// Selection Indicator
                      if (isSelected)
                        AnimatedScale(
                          duration: const Duration(milliseconds: 200),
                          scale: isSelected ? 1.0 : 0.0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).primaryColor,
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            })
            .toList(),
      ),
    );
  }

  /// ⭐ LEVEL 2: Theme Helper Methods
  /// Smart theme presentation logic with provider integration

  IconData _getThemeIcon(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return Icons.light_mode;
      case AppTheme.dark:
        return Icons.dark_mode;
      case AppTheme.system:
        return Icons.settings_brightness;
    }
  }

  Color _getThemeColor(AppTheme theme, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (theme) {
      case AppTheme.light:
        return isDark
            ? Colors.orange.shade200
            : Colors.orange.shade800; // More contrast
      case AppTheme.dark:
        return isDark
            ? Colors.indigo.shade200
            : Colors.indigo.shade800; // More contrast
      case AppTheme.system:
        return isDark
            ? Colors.blue.shade200
            : Colors.blue.shade800; // More contrast
    }
  }

  String _getThemeDisplayName(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return 'Light Theme';
      case AppTheme.dark:
        return 'Dark Theme';
      case AppTheme.system:
        return 'System Theme';
    }
  }

  String _getThemeDescription(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return 'Bright and clean interface';
      case AppTheme.dark:
        return 'Easy on the eyes';
      case AppTheme.system:
        return 'Follows system preference';
    }
  }
}
