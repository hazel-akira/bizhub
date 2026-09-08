import 'package:flutter/material.dart';

/// Brand colors per business category (Akira Bites SaaS palette).
class BusinessThemePalette {
  const BusinessThemePalette({
    required this.id,
    required this.label,
    required this.primary,
    required this.secondary,
    required this.accent,
    this.surfaceTint,
  });

  final String id;
  final String label;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color? surfaceTint;

  Color get onPrimary =>
      ThemeData.estimateBrightnessForColor(primary) == Brightness.dark
          ? Colors.white
          : Colors.black87;

  Color get primaryContainer => Color.alphaBlend(
        primary.withValues(alpha: 0.12),
        Colors.white,
      );

  Color get scaffoldBackground =>
      surfaceTint ?? Color.alphaBlend(primary.withValues(alpha: 0.04), Colors.white);

  static BusinessThemePalette forType(String? businessTypeId) {
    if (businessTypeId == null || businessTypeId.isEmpty) {
      return _palettes['food_vendor']!;
    }
    return _palettes[businessTypeId] ?? _palettes['food_vendor']!;
  }

  ThemeData toThemeData() {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: secondary,
      tertiary: accent,
      surface: scaffoldBackground,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryContainer,
        foregroundColor: primary,
        elevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        indicatorColor: primary.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          const overflow = TextStyle(
            fontSize: 11,
            height: 1.1,
            overflow: TextOverflow.ellipsis,
          );
          if (states.contains(WidgetState.selected)) {
            return overflow.copyWith(
              fontWeight: FontWeight.w700,
              color: primary,
            );
          }
          return overflow;
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),
    );
  }

  static const _palettes = <String, BusinessThemePalette>{
    'pharmacy': BusinessThemePalette(
      id: 'pharmacy',
      label: 'Pharmacy',
      primary: Color(0xFF1565C0),
      secondary: Color(0xFFFFFFFF),
      accent: Color(0xFF43A047),
    ),
    'food_vendor': BusinessThemePalette(
      id: 'food_vendor',
      label: 'Food Vendor',
      primary: Color(0xFFF57C00),
      secondary: Color(0xFF43A047),
      accent: Color(0xFFFFF8E1),
      surfaceTint: Color(0xFFFFF8E1),
    ),
    'small_restaurant': BusinessThemePalette(
      id: 'small_restaurant',
      label: 'Restaurant',
      primary: Color(0xFFD32F2F),
      secondary: Color(0xFFFF9800),
      accent: Color(0xFFFFC107),
    ),
    'grocery_shop': BusinessThemePalette(
      id: 'grocery_shop',
      label: 'Kiosk / General Shop',
      primary: Color(0xFF2E7D32),
      secondary: Color(0xFFFFFFFF),
      accent: Color(0xFFFF9800),
    ),
    'boutique': BusinessThemePalette(
      id: 'boutique',
      label: 'Fashion',
      primary: Color(0xFF212121),
      secondary: Color(0xFFFFFFFF),
      accent: Color(0xFFD4AF37),
    ),
    'beauty_shop': BusinessThemePalette(
      id: 'beauty_shop',
      label: 'Beauty & Cosmetics',
      primary: Color(0xFFEC407A),
      secondary: Color(0xFF8E24AA),
      accent: Color(0xFFFFFFFF),
    ),
    'electronics_shop': BusinessThemePalette(
      id: 'electronics_shop',
      label: 'Electronics',
      primary: Color(0xFF3949AB),
      secondary: Color(0xFF1E88E5),
      accent: Color(0xFF00BCD4),
    ),
    'hardware_store': BusinessThemePalette(
      id: 'hardware_store',
      label: 'Hardware',
      primary: Color(0xFFEF6C00),
      secondary: Color(0xFF757575),
      accent: Color(0xFF212121),
    ),
    'cybercafe': BusinessThemePalette(
      id: 'cybercafe',
      label: 'Cyber / Tech',
      primary: Color(0xFF0D47A1),
      secondary: Color(0xFF00BCD4),
      accent: Color(0xFFFFFFFF),
    ),
    'butchery': BusinessThemePalette(
      id: 'butchery',
      label: 'Butchery',
      primary: Color(0xFF6D4C41),
      secondary: Color(0xFF8D6E63),
      accent: Color(0xFFEF5350),
    ),
    'mama_mboga': BusinessThemePalette(
      id: 'mama_mboga',
      label: 'Mama Mboga',
      primary: Color(0xFF2E7D32),
      secondary: Color(0xFF81C784),
      accent: Color(0xFFFFEB3B),
    ),
    'dairy_shop': BusinessThemePalette(
      id: 'dairy_shop',
      label: 'Dairy',
      primary: Color(0xFF0277BD),
      secondary: Color(0xFFB3E5FC),
      accent: Color(0xFFFFC107),
    ),
    'poultry_shop': BusinessThemePalette(
      id: 'poultry_shop',
      label: 'Poultry',
      primary: Color(0xFFEF6C00),
      secondary: Color(0xFFFFCC80),
      accent: Color(0xFF6D4C41),
    ),
    'wholesale': BusinessThemePalette(
      id: 'wholesale',
      label: 'Wholesale',
      primary: Color(0xFF37474F),
      secondary: Color(0xFF90A4AE),
      accent: Color(0xFFFF9800),
    ),
    'liquor_store': BusinessThemePalette(
      id: 'liquor_store',
      label: 'Wines & Spirits',
      primary: Color(0xFF4A148C),
      secondary: Color(0xFFCE93D8),
      accent: Color(0xFFFFD54F),
    ),
    'gas_water': BusinessThemePalette(
      id: 'gas_water',
      label: 'Gas & Water',
      primary: Color(0xFF00695C),
      secondary: Color(0xFF4DB6AC),
      accent: Color(0xFFFF7043),
    ),
    'shoe_store': BusinessThemePalette(
      id: 'shoe_store',
      label: 'Shoes',
      primary: Color(0xFF5D4037),
      secondary: Color(0xFFD7CCC8),
      accent: Color(0xFF1565C0),
    ),
    'salon': BusinessThemePalette(
      id: 'salon',
      label: 'Salon / Kinyozi',
      primary: Color(0xFFAD1457),
      secondary: Color(0xFFF48FB1),
      accent: Color(0xFF212121),
    ),
    'agrovet': BusinessThemePalette(
      id: 'agrovet',
      label: 'Agrovet',
      primary: Color(0xFF558B2F),
      secondary: Color(0xFFAED581),
      accent: Color(0xFF6D4C41),
    ),
  };
}
