//lib/utils/styles.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppStyles {
  static TextStyle heading1 = GoogleFonts.roboto(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.onSurfaceColor,
  );

  static TextStyle bodyText = GoogleFonts.roboto(
    fontSize: 16,
    color: AppColors.onSurfaceColor,
  );

  static TextStyle buttonText = GoogleFonts.roboto(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.onPrimaryColor,
  );
}
