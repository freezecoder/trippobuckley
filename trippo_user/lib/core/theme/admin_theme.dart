import 'package:flutter/material.dart';

/// Admin-specific theme configuration
/// Professional dark theme for admin dashboard
class AdminTheme {
  // Private constructor to prevent instantiation
  AdminTheme._();

  // Admin Color Palette
  static const Color primaryColor = Color(0xFF1E3A8A); // Dark Blue
  static const Color secondaryColor = Color(0xFF10B981); // Green (success)
  static const Color warningColor = Color(0xFFF59E0B); // Amber
  static const Color dangerColor = Color(0xFFEF4444); // Red
  static const Color backgroundColor = Color(0xFFF9FAFB); // Light gray
  static const Color cardBackground = Color(0xFFFFFFFF); // White
  static const Color textPrimary = Color(0xFF111827); // Dark gray
  static const Color textSecondary = Color(0xFF6B7280); // Medium gray
  static const Color dividerColor = Color(0xFFE5E7EB); // Light gray
  static const Color hoverColor = Color(0xFFF3F4F6); // Very light gray

  // Status Colors
  static const Color successColor = Color(0xFF10B981); // Green
  static const Color errorColor = Color(0xFFEF4444); // Red
  static const Color infoColor = Color(0xFF3B82F6); // Blue
  static const Color pendingColor = Color(0xFFF59E0B); // Amber

  // Chart Colors
  static const List<Color> chartColors = [
    Color(0xFF3B82F6), // Blue
    Color(0xFF10B981), // Green
    Color(0xFFF59E0B), // Amber
    Color(0xFFEF4444), // Red
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
  ];

  /// Get admin theme data
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: cardBackground,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundColor,
      
      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(8),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: const TextStyle(
          fontFamily: 'Inter',
          color: textSecondary,
        ),
        hintStyle: const TextStyle(
          fontFamily: 'Inter',
          color: textSecondary,
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),

      // Tab Bar Theme
      tabBarTheme: const TabBarThemeData(
        labelColor: primaryColor,
        unselectedLabelColor: textSecondary,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),

      // Text Theme
      textTheme: const TextTheme(
        // Headings
        displayLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Poppons',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        
        // Body text
        bodyLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        
        // Labels
        labelLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        labelMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        labelSmall: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
      ),
    );
  }

  /// Get color for status
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'approved':
      case 'completed':
      case 'verified':
      case 'paid':
        return successColor;
      case 'inactive':
      case 'rejected':
      case 'cancelled':
      case 'suspended':
        return dangerColor;
      case 'pending':
      case 'ongoing':
      case 'processing':
        return pendingColor;
      default:
        return textSecondary;
    }
  }

  /// Get icon for action type
  static IconData getActionIcon(String actionType) {
    if (actionType.contains('activate')) return Icons.check_circle;
    if (actionType.contains('deactivate')) return Icons.cancel;
    if (actionType.contains('delete')) return Icons.delete;
    if (actionType.contains('suspend')) return Icons.block;
    if (actionType.contains('verify')) return Icons.verified;
    if (actionType.contains('update')) return Icons.edit;
    if (actionType.contains('add')) return Icons.add_circle;
    if (actionType.contains('remove')) return Icons.remove_circle;
    return Icons.info;
  }
}

