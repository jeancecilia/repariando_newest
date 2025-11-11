import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color PRIMARY_COLOR = Color(0xFFF55D17);
  static const Color SECONDAY_COLOR = Color(0xFFFA982B);
  static const Color LITE_PRIMARY_COLOR = Color(0xFFFEEEE8);
  static const Color BACKGROUND_COLOR = Colors.white;
  static const Color HINT_COLOR = Color(0xFFA0AEC0);
  static const Color FIELD_BACKGROUND_COLOR = Color(0xFFF7FAFC);
  static const Color BORDER_COLOR = Color(0xFFE3E3E3);
  static const Color TEXT_COLOR = Color(0xFF111D2E);
  static const Color BROWN_ORANGE_COLOR = Color(0xFFFA982C);
  static const Color BLUE_COLOR = Color(0xFF3ACCE6);
  static const Color GREEN_COLOR = Color.fromARGB(255, 6, 138, 1);

  static const Color YELLOW_COLOR = Color(0xFFFCD021);
  static const Color PROFILE_BACKGROUND_COLOR = Color(0xFFFFFAF8);
  static const Duration SPLASH_ANIMATION_DURATION = Duration(seconds: 2);
  static const Duration SLIDE_ANIMATION_DURATION = Duration(milliseconds: 600);
  static const Duration TRANSITION_DURATION = Duration(milliseconds: 800);
  static const Duration SHORT_TRANSITION_DURATION = Duration(milliseconds: 300);
  static const int SPLASH_DURATION = 3000;
  static const double LOGO_SIZE = 60.0;
  static const double SPLASH_LOGO_WDITH = 280.0;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: PRIMARY_COLOR,
      scaffoldBackgroundColor: BACKGROUND_COLOR,
      colorScheme: ColorScheme.fromSeed(
        seedColor: PRIMARY_COLOR,
        brightness: Brightness.light,
        primary: PRIMARY_COLOR,
        secondary: SECONDAY_COLOR,
        surface: BACKGROUND_COLOR,
        onSurface: TEXT_COLOR,
      ),

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: BACKGROUND_COLOR,
        foregroundColor: TEXT_COLOR,
        elevation: 0,
        titleTextStyle: appBarTitleStyle,
        centerTitle: true,
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PRIMARY_COLOR,
          foregroundColor: Colors.white,
          textStyle: buttonTextStyle,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.manrope(color: TEXT_COLOR, fontSize: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: BORDER_COLOR),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: BORDER_COLOR),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: BORDER_COLOR),
        ),
      ),

      // Text Theme
      textTheme: TextTheme(
        headlineLarge: headlineLarge,
        headlineMedium: appointmentHeadingTextStyle,
        headlineSmall: scheduleTimeHeading,
        titleLarge: workshopNameStyle,
        titleMedium: serviceNameStyle,
        titleSmall: sectionHeaderStyle,
        bodyLarge: serviceDetailParagraph,
        bodyMedium: workshopServicesStyle,
        bodySmall: workshopAddressStyle,
        labelLarge: buttonTextStyle,
        labelMedium: chatButtonTextStyle,
        labelSmall: bookButtonTextStyle,
      ),
    );
  }

  // Text Styles (keeping your existing styles for custom usage)
  static final TextStyle headlineLarge = GoogleFonts.manrope(
    fontSize: 40,
    fontWeight: FontWeight.w500,
    color: TEXT_COLOR,
    letterSpacing: 0,
  );

  static final TextStyle buttonTextStyle = GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  // Workshop Profile Text Styles
  static final TextStyle appBarTitleStyle = GoogleFonts.manrope(
    color: Colors.black,
    fontSize: 21,
    fontWeight: FontWeight.w600,
  );

  static final TextStyle appointmentHeadingTextStyle = GoogleFonts.manrope(
    color: Colors.black,
    fontSize: 20,
    fontWeight: FontWeight.w900,
  );

  static final TextStyle scheduleTimeHeading = GoogleFonts.manrope(
    color: Colors.black,
    fontSize: 19,
    fontWeight: FontWeight.w700,
  );

  static final TextStyle workshopNameStyle = GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: TEXT_COLOR,
  );

  static final TextStyle workshopHoursStyle = GoogleFonts.manrope(
    fontStyle: FontStyle.italic,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: PRIMARY_COLOR,
  );

  static final TextStyle workshopServicesStyle = GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: TEXT_COLOR,
  );

  static final TextStyle serviceDetailParagraph = GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: TEXT_COLOR,
  );

  static final TextStyle workshopAddressStyle = GoogleFonts.manrope(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    fontStyle: FontStyle.italic,
    color: TEXT_COLOR,
  );

  static final TextStyle contactUsTextStyle = GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: TEXT_COLOR,
  );

  static final TextStyle chatButtonTextStyle = GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static final TextStyle sectionHeaderStyle = GoogleFonts.manrope(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static final TextStyle serviceNameStyle = GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: TEXT_COLOR,
  );

  static final TextStyle viewDetailsTextStyle = GoogleFonts.manrope(
    fontSize: 12,
    color: TEXT_COLOR,
  );

  static final TextStyle serviceDescriptionStyle = GoogleFonts.manrope(
    fontStyle: FontStyle.italic,
    fontSize: 12,
    color: TEXT_COLOR,
  );

  static final TextStyle bookButtonTextStyle = GoogleFonts.manrope(
    fontSize: 12,
    color: TEXT_COLOR,
    fontWeight: FontWeight.w500,
  );

  static final TextStyle labelStyle = GoogleFonts.manrope(
    color: Color(0xFF0A0D1C),
    fontWeight: FontWeight.w600,
    fontSize: 16,
  );

  // Decorations (keeping your existing decorations for custom usage)
  static final BoxDecoration primaryButtonDecoration = BoxDecoration(
    color: PRIMARY_COLOR,
    borderRadius: BorderRadius.circular(16),
  );

  static final BoxDecoration workshopProfileContainerDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(10),
    color: LITE_PRIMARY_COLOR,
  );

  static final BoxDecoration chatButtonDecoration = BoxDecoration(
    color: const Color(0xFFFF5C00),
    borderRadius: BorderRadius.circular(16),
  );

  static final BoxDecoration serviceItemDecoration = BoxDecoration(
    color: BROWN_ORANGE_COLOR,
    borderRadius: BorderRadius.circular(12),
  );

  static final BoxDecoration bookButtonDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
  );

  // Input Decorations (keeping your existing decorations for custom usage)
  static final InputDecoration textFieldDecoration = InputDecoration(
    filled: true,
    fillColor: Colors.white,
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    hintStyle: GoogleFonts.manrope(color: TEXT_COLOR, fontSize: 11),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: BORDER_COLOR),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: BORDER_COLOR),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: BORDER_COLOR),
    ),
  );

  static final InputDecoration outlineTextFieldDecoration = InputDecoration(
    hintText: "Find a workshop near you",
    prefixIcon: Icon(Icons.search),
    contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide(color: AppTheme.TEXT_COLOR, width: 2),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide(color: AppTheme.TEXT_COLOR, width: 2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide(color: AppTheme.TEXT_COLOR, width: 2),
    ),
  );
}
