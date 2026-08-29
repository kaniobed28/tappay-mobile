import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ---------------------------------------------------------------------------
/// TapPay design system
/// A calm, premium fintech look: deep indigo→violet brand, mint success accent,
/// airy surfaces, soft shadows, generous radii, confident typography.
/// ---------------------------------------------------------------------------

class AppColors {
  // Brand
  static const brand = Color(0xFF5B4BFF);
  static const brandDeep = Color(0xFF7A34E8);
  static const accent = Color(0xFF00C2A8); // mint / teal — success + "receive"

  // Semantic
  static const success = Color(0xFF12B886);
  static const danger = Color(0xFFEF4457);
  static const warning = Color(0xFFF5A524);

  // Neutrals
  static const bg = Color(0xFFF6F7FB);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF1F2F8);
  static const border = Color(0xFFEBEDF4);
  static const ink = Color(0xFF0E1020);
  static const inkSoft = Color(0xFF6A7080);
  static const inkFaint = Color(0xFFA2A8B6);
}

/// Reusable gradients.
class AppGradients {
  static const brand = LinearGradient(
    colors: [Color(0xFF6A5BFF), Color(0xFF8B3BEA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const mint = LinearGradient(
    colors: [Color(0xFF16C9AE), Color(0xFF04A88F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const night = LinearGradient(
    colors: [Color(0xFF1B1E36), Color(0xFF2A2352)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Spacing scale (4-pt based).
class AppSpace {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 20.0;
  static const xxl = 28.0;
  static const xxxl = 40.0;
}

/// Corner radii.
class AppRadius {
  static const chip = 999.0;
  static const s = 12.0;
  static const m = 16.0;
  static const l = 20.0;
  static const xl = 28.0;
}

/// Soft, layered shadows (never the default Material drop shadow).
class AppShadows {
  static List<BoxShadow> card = [
    BoxShadow(color: const Color(0xFF0E1020).withValues(alpha: 0.04), blurRadius: 18, offset: const Offset(0, 8)),
  ];
  static List<BoxShadow> raised = [
    BoxShadow(color: const Color(0xFF0E1020).withValues(alpha: 0.06), blurRadius: 28, offset: const Offset(0, 14)),
  ];
  static List<BoxShadow> brandGlow = [
    BoxShadow(color: AppColors.brand.withValues(alpha: 0.28), blurRadius: 26, offset: const Offset(0, 14)),
  ];
}

/// Motion tokens.
class AppMotion {
  static const fast = Duration(milliseconds: 160);
  static const base = Duration(milliseconds: 240);
  static const slow = Duration(milliseconds: 420);
  static const curve = Curves.easeOutCubic;
}

class AppTheme {
  // Back-compat aliases used across the app.
  static const Color brand = AppColors.brand;
  static const Color accent = AppColors.accent;

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      primary: AppColors.brand,
      secondary: AppColors.accent,
      surface: AppColors.surface,
    );

    final text = const TextTheme(
      displaySmall: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5, color: AppColors.ink),
      headlineMedium: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.4, color: AppColors.ink),
      headlineSmall: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.3, color: AppColors.ink),
      titleLarge: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.2, color: AppColors.ink),
      titleMedium: TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink),
      bodyLarge: TextStyle(color: AppColors.ink, height: 1.4),
      bodyMedium: TextStyle(color: AppColors.inkSoft, height: 1.4),
      labelLarge: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.1),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bg,
      textTheme: text,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        titleTextStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink, letterSpacing: -0.2),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.m)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.1),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size.fromHeight(54),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.m)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.brand, textStyle: const TextStyle(fontWeight: FontWeight.w600)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: AppColors.inkFaint),
        labelStyle: const TextStyle(color: AppColors.inkSoft),
        prefixIconColor: AppColors.inkSoft,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.m),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.m),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.m),
          borderSide: const BorderSide(color: AppColors.brand, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.m),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        height: 66,
        indicatorColor: AppColors.brand.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: s.contains(WidgetState.selected) ? AppColors.brand : AppColors.inkSoft,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(color: s.contains(WidgetState.selected) ? AppColors.brand : AppColors.inkSoft),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
      ),
    );
  }
}

/// Formats a minor-unit amount (pesewas/kobo) as "GHS 35.00".
String formatAmount(int minorUnits, String currency) {
  final major = minorUnits / 100.0;
  return '$currency ${major.toStringAsFixed(2)}';
}

/// Splits an amount into (currency, integer, fraction) for rich display.
({String currency, String whole, String fraction}) amountParts(int minorUnits, String currency) {
  final major = minorUnits / 100.0;
  final s = major.toStringAsFixed(2).split('.');
  return (currency: currency, whole: s[0], fraction: s[1]);
}
