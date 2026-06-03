import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppStyle {

  // ================= COLORS =================

  static const Color primaryColor = Color(0xFF2294D6);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color borderColor = Color(0xFFDCE3EB);
  static const Color whiteColor = Colors.white;

  // ================= GRADIENT =================

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2294D6), Color(0xFF1A6FA3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ================= MEDIA QUERY =================

  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static bool isMobile(BuildContext context) {
    return screenWidth(context) < 600;
  }

  static bool isTablet(BuildContext context) {
    return screenWidth(context) >= 600 &&
        screenWidth(context) < 1024;
  }

  static bool isDesktop(BuildContext context) {
    return screenWidth(context) >= 1024;
  }

  // ================= RESPONSIVE SIZE =================

  static double responsiveWidth(
    BuildContext context,
    double value,
  ) {
    return screenWidth(context) * (value / 375);
  }

  static double responsiveHeight(
    BuildContext context,
    double value,
  ) {
    return screenHeight(context) * (value / 812);
  }

  static double responsiveText(
    BuildContext context,
    double size,
  ) {
    double scale = screenWidth(context) / 375;
    return size * scale;
  }

  // ================= LOGIN PAGE FONT (MANROPE) =================

  static TextStyle text({
    required BuildContext context,
    double size = 14,
    Color color = textPrimary,
    FontWeight weight = FontWeight.w400,
    double height = 1.4,
  }) {
    return GoogleFonts.manrope(
      fontSize: responsiveText(context, size),
      color: color,
      fontWeight: weight,
      height: height,
    );
  }

  // ================= ONBOARDING FONT (MANROPE, NO CONTEXT) =================
  // Used by onboarding widgets that are stateless and have no BuildContext
  // available at the point where text style is needed (e.g. inside ShaderMask).

  static TextStyle textStatic({
    double size = 14,
    Color color = textPrimary,
    FontWeight weight = FontWeight.w400,
    double height = 1.4,
  }) {
    return GoogleFonts.manrope(
      fontSize: size,
      color: color,
      fontWeight: weight,
      height: height,
    );
  }

  // ================= CHECK-IN PAGE FONT (PLUS JAKARTA SANS) =================

  static TextStyle jakartaText({
    required BuildContext context,
    double size = 14,
    Color color = textPrimary,
    FontWeight weight = FontWeight.w400,
    double height = 1.4,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: responsiveText(context, size),
      color: color,
      fontWeight: weight,
      height: height,
    );
  }
}