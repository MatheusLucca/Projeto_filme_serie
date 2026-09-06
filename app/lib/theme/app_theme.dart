import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/title_item.dart';

/// Design tokens for the "contador de videocassete" identity: a warm-ink
/// base with an amber signal accent, poster titles set in a heavy display
/// face, and progress/counters set in monospace so episode numbers read
/// like a tape counter ticking over.
class AppColors {
  AppColors._();

  // Base surfaces.
  static const inkDark = Color(0xFF1B1F23);
  static const inkElevatedDark = Color(0xFF23282E);
  static const fogLight = Color(0xFFE9E5DC);
  static const cardLight = Color(0xFFF6F4EF);

  // Text.
  static const textDark = Color(0xFF1B1F23);
  static const textLight = Color(0xFFF2EFE9);
  static const mutedOnLight = Color(0xFF6B6459);
  static const mutedOnDark = Color(0xFF9C978C);

  // Signal accent — the amber "REC" light. Primary action color.
  static const signal = Color(0xFFFF7A3D);
  static const signalOnLight = Color(0xFFC85A22);

  // Rating stars — brushed brass, kept distinct from the signal accent.
  static const brass = Color(0xFFCBA35C);

  // Per-category "channel" colors used as the ticket's spine stripe.
  static const filme = Color(0xFFFF7A3D);
  static const serie = Color(0xFF2FA6A0);
  static const anime = Color(0xFFC0447A);
  static const desenho = Color(0xFF6FA85B);

  static const danger = Color(0xFFD64545);
  static const success = Color(0xFF4C9A6A);
}

extension TitleTypeColor on TitleType {
  Color get channelColor {
    switch (this) {
      case TitleType.filme:
        return AppColors.filme;
      case TitleType.serie:
        return AppColors.serie;
      case TitleType.anime:
        return AppColors.anime;
      case TitleType.desenho:
        return AppColors.desenho;
    }
  }
}

class AppFonts {
  AppFonts._();

  /// Poster-style display face, used sparingly for titles and headers.
  static TextStyle display({double size = 20, Color? color, double? height}) =>
      GoogleFonts.archivoBlack(fontSize: size, color: color, height: height);

  /// Tape-counter face, used for episode/season counters and labels that
  /// should read as instrumentation rather than prose.
  static TextStyle mono({
    double size = 12,
    FontWeight weight = FontWeight.w600,
    Color? color,
    double? letterSpacing,
  }) =>
      GoogleFonts.ibmPlexMono(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing ?? 0.2,
      );
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? AppColors.inkDark : AppColors.fogLight;
    final surface = isDark ? AppColors.inkElevatedDark : AppColors.cardLight;
    final onSurface = isDark ? AppColors.textLight : AppColors.textDark;
    final muted = isDark ? AppColors.mutedOnDark : AppColors.mutedOnLight;
    final signal = isDark ? AppColors.signal : AppColors.signalOnLight;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: signal,
      onPrimary: Colors.white,
      secondary: AppColors.serie,
      onSecondary: Colors.white,
      error: AppColors.danger,
      onError: Colors.white,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: isDark ? const Color(0xFF2C323A) : const Color(0xFFE2DDD1),
      outline: isDark ? const Color(0xFF3A4149) : const Color(0xFFD8D2C4),
      inverseSurface: isDark ? AppColors.fogLight : AppColors.inkDark,
      onInverseSurface: isDark ? AppColors.textDark : AppColors.textLight,
    );

    final baseText = GoogleFonts.ibmPlexSansTextTheme(
      isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    );

    final textTheme = baseText.copyWith(
      headlineSmall: AppFonts.display(size: 24, color: onSurface),
      titleLarge: AppFonts.display(size: 18, color: onSurface),
      titleMedium: GoogleFonts.archivo(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: onSurface,
        height: 1.15,
      ),
      titleSmall: GoogleFonts.archivo(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      bodyMedium: baseText.bodyMedium?.copyWith(color: onSurface),
      bodySmall: baseText.bodySmall?.copyWith(color: muted),
      labelLarge: GoogleFonts.ibmPlexSans(fontWeight: FontWeight.w600, color: onSurface),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      textTheme: textTheme,
      dividerColor: colorScheme.outline,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppFonts.display(size: 20, color: onSurface),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: colorScheme.outline, width: 1),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        labelStyle: AppFonts.mono(size: 11, color: onSurface),
        side: BorderSide(color: colorScheme.outline),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: signal, width: 1.5),
        ),
        hintStyle: TextStyle(color: muted),
        labelStyle: TextStyle(color: muted),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: signal,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          side: BorderSide(color: colorScheme.outline),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: signal),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: signal,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: signal,
        linearTrackColor: colorScheme.surfaceContainerHighest,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStatePropertyAll(signal),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: onSurface,
        unselectedLabelColor: muted,
        labelStyle: GoogleFonts.archivo(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: GoogleFonts.archivo(fontWeight: FontWeight.w600, fontSize: 13),
        indicatorColor: signal,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
      ),
      listTileTheme: ListTileThemeData(iconColor: muted, textColor: onSurface),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.fogLight : AppColors.inkDark,
        contentTextStyle: TextStyle(color: isDark ? AppColors.textDark : AppColors.textLight),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
