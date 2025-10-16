/// 🎨 FRONTEND COMPONENTS - Theme Info Widget
///
/// ⭐ RIVERPOD LEVEL 2-3 DEMONSTRATION ⭐
/// Advanced Theme Information with Provider Analytics
///
/// EDUCATIONAL VALUE:
/// - LEVEL 2: Multiple provider watching for theme coordination
/// - LEVEL 3: Provider combinations for complex UI state
/// - Theme analytics and information display
/// - Advanced provider-driven UI components
///
/// ARCHITECTURE PATTERNS:
/// 1. Multi-provider watching for theme analysis
/// 2. Provider-driven theme analytics
/// 3. Complex UI state derived from multiple providers
/// 4. Theme accessibility and performance information

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/theme_providers.dart';

/// ⭐ LEVEL 2-3: Advanced Theme Information Display
///
/// DEMONSTRATES:
/// - Multiple provider watching for comprehensive theme info
/// - Provider combinations for complex UI analytics
/// - Theme accessibility and performance analysis
/// - Advanced provider-driven information components
class ThemeInfoWidget extends ConsumerWidget {
  const ThemeInfoWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    /// ⭐ LEVEL 2: Multi-Provider Watching
    /// Watching multiple theme-related providers for comprehensive info
    final currentTheme = ref.watch(themeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final lightTheme = ref.watch(lightThemeProvider);
    final darkTheme = ref.watch(darkThemeProvider);

    /// ⭐ LEVEL 3: Provider-Derived Analytics
    /// Complex theme analysis derived from multiple providers
    final activeThemeData = themeMode == ThemeMode.dark
        ? darkTheme
        : lightTheme;
    final themeAnalytics = _analyzeTheme(activeThemeData, currentTheme);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header Section
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.palette,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Theme Information',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Current: ${_getThemeDisplayName(currentTheme)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// ⭐ LEVEL 3: Theme Analytics Grid
            /// Complex information display derived from provider combinations
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: [
                _buildInfoTile(
                  'Active Mode',
                  themeMode.name.toUpperCase(),
                  Icons.brightness_6,
                  themeAnalytics['modeColor'] as Color,
                ),
                _buildInfoTile(
                  'Brightness',
                  activeThemeData.brightness.name.toUpperCase(),
                  Icons.contrast,
                  themeAnalytics['brightnessColor'] as Color,
                ),
                _buildInfoTile(
                  'Primary Color',
                  _colorToHex(activeThemeData.primaryColor),
                  Icons.color_lens,
                  activeThemeData.primaryColor,
                ),
                _buildInfoTile(
                  'Accessibility',
                  themeAnalytics['accessibilityScore'] as String,
                  Icons.accessibility,
                  themeAnalytics['accessibilityColor'] as Color,
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// ⭐ LEVEL 3: Theme Performance Analysis
            /// Advanced provider-driven performance information
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.analytics,
                        size: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Theme Performance',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  /// Performance Metrics
                  ...(themeAnalytics['performanceMetrics']
                          as List<Map<String, dynamic>>)
                      .map(
                        (metric) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: metric['color'] as Color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${metric['label']}: ',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                metric['value'] as String,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: metric['color'] as Color,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// Theme Recommendations
            if (themeAnalytics['recommendations'].isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.lightbulb_outline, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    'Recommendations',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              ...(themeAnalytics['recommendations'] as List<String>).map(
                (recommendation) => Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Text(
                    recommendation,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// ⭐ LEVEL 3: Theme Analysis Logic
  /// Complex theme analytics derived from multiple providers
  Map<String, dynamic> _analyzeTheme(
    ThemeData themeData,
    AppTheme currentTheme,
  ) {
    final brightness = themeData.brightness;
    final primaryColor = themeData.primaryColor;

    // Accessibility analysis
    final contrastRatio = _calculateContrastRatio(
      primaryColor,
      brightness == Brightness.light ? Colors.white : Colors.black,
    );

    String accessibilityScore;
    Color accessibilityColor;

    if (contrastRatio >= 7.0) {
      accessibilityScore = 'AAA';
      accessibilityColor = Colors.green;
    } else if (contrastRatio >= 4.5) {
      accessibilityScore = 'AA';
      accessibilityColor = Colors.orange;
    } else {
      accessibilityScore = 'FAIL';
      accessibilityColor = Colors.red;
    }

    // Performance metrics
    final performanceMetrics = [
      {
        'label': 'Render Performance',
        'value': brightness == Brightness.dark ? 'Optimized' : 'Standard',
        'color': brightness == Brightness.dark ? Colors.green : Colors.blue,
      },
      {
        'label': 'Battery Impact',
        'value': brightness == Brightness.dark ? 'Low' : 'Medium',
        'color': brightness == Brightness.dark ? Colors.green : Colors.orange,
      },
      {
        'label': 'Eye Strain',
        'value': brightness == Brightness.dark ? 'Reduced' : 'Standard',
        'color': brightness == Brightness.dark ? Colors.green : Colors.grey,
      },
    ];

    // Recommendations
    final recommendations = <String>[];
    if (brightness == Brightness.light) {
      recommendations.add('Consider dark theme for battery saving');
    }
    if (contrastRatio < 4.5) {
      recommendations.add('Improve color contrast for better accessibility');
    }

    return {
      'modeColor': currentTheme == AppTheme.dark
          ? Colors.indigo
          : Colors.orange,
      'brightnessColor': brightness == Brightness.dark
          ? Colors.indigo
          : Colors.orange,
      'accessibilityScore': accessibilityScore,
      'accessibilityColor': accessibilityColor,
      'performanceMetrics': performanceMetrics,
      'recommendations': recommendations,
    };
  }

  /// Helper: Info Tile Builder
  Widget _buildInfoTile(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Helper: Theme Display Name
  String _getThemeDisplayName(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return 'Light';
      case AppTheme.dark:
        return 'Dark';
      case AppTheme.system:
        return 'System';
    }
  }

  /// Helper: Color to Hex
  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase().substring(2)}';
  }

  /// Helper: Contrast Ratio Calculation
  double _calculateContrastRatio(Color color1, Color color2) {
    double luminance1 = _calculateLuminance(color1);
    double luminance2 = _calculateLuminance(color2);

    double lighter = luminance1 > luminance2 ? luminance1 : luminance2;
    double darker = luminance1 > luminance2 ? luminance2 : luminance1;

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Helper: Luminance Calculation
  double _calculateLuminance(Color color) {
    double r = color.red / 255.0;
    double g = color.green / 255.0;
    double b = color.blue / 255.0;

    r = r <= 0.03928 ? r / 12.92 : pow((r + 0.055) / 1.055, 2.4) as double;
    g = g <= 0.03928 ? g / 12.92 : pow((g + 0.055) / 1.055, 2.4) as double;
    b = b <= 0.03928 ? b / 12.92 : pow((b + 0.055) / 1.055, 2.4) as double;

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }
}
