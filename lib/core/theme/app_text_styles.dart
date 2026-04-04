import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle heading1(BuildContext context) => GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface,
        letterSpacing: -0.5,
      );

  static TextStyle heading2(BuildContext context) => GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
        letterSpacing: -0.3,
      );

  static TextStyle heading3(BuildContext context) => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      );

  static TextStyle bodyLarge(BuildContext context) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: Theme.of(context).colorScheme.onSurface,
      );

  static TextStyle bodyMedium(BuildContext context) => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: Theme.of(context).colorScheme.onSurface,
      );

  static TextStyle bodySmall(BuildContext context) => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );

  static TextStyle labelLarge(BuildContext context) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
        letterSpacing: 0.1,
      );

  static TextStyle labelSmall(BuildContext context) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: 0.1,
      );

  static TextStyle price(BuildContext context) => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.primary,
      );

  static TextStyle priceSmall(BuildContext context) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.primary,
      );

  static TextStyle tokenLarge(BuildContext context) => GoogleFonts.inter(
        fontSize: 42,
        fontWeight: FontWeight.w800,
        color: Theme.of(context).colorScheme.primary,
        letterSpacing: 2,
      );

  static TextStyle caption(BuildContext context) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );
}
