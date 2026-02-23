import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:driver/infrastructure/services/services.dart';
import 'package:driver/infrastructure/models/models.dart';

abstract class Style {
  Style._();

  /// ###################### Colors ##########################
  static const white = Colors.white;

  static const transparent = Colors.transparent;

  static const blueColor = Color(0xff03758E);

  static const bgGrey = Color(0xFFF4F5F8);

  static const Color hintColor = Color(0xFFA7A7A7);

  static const textGrey = Color(0xFF898989);
  static const differBorderColor = Color(0xFF898989);

  static const greenColor = Color(0xff16AA16);

  static const redColor = Color(0xffFF3D00);

  static const progressColor = Color(0xffF26110);

  static const orangeColor = Color(0xffF19204);

  static const bgRedColor = Color(0xffFFF2EE);

  static const pendingDark = Color(0xFFF19204);

  static const greyColor = Color(0xffF4F5F8);

  static const iconsColor = Color(0xff232B2F);

  static const textColor = Color(0xff898989);

  static const black = Color(0xff000000);

  static const blackColor = Color(0xff000000);

  static const blackColorOpacity = Color(0x06000000);

  static const bottomNavigationBarColor = Color(0xff191919);

  static const bottomSheetIconColor = Color(0xffC4C5C7);

  static const iconColor = Color(0xffC4C4C4);

  static const shimmerBase = Color(0xFFE0E0E0);

  static const shimmerHighlight = Color(0xFFF5F5F5);

  static const tabBarBorderColor = Color(0xFFDEDFE1);

  static const toggleColor = Color(0xFFE7E7E7);

  static const toggleShadowColor = Color(0xFF6B6B6B);

  static const logOutBgColor = Color(0xFFB9B9B9);

  static const borderColor = Color(0xFFF2F2F2);

  static const addCountColor = Color(0xFFF7F7F7);

  static const discountColor = Color(0xFFF3F3F3);

  static const shadowColor = Color(0xFF7D7D7D);

  static Color get primary =>
      _getColorFromSettings('primary_color', const Color(0xFF83EA00));

  static Color get buttonFontColor =>
      _getColorFromSettings('primary_button_font_color', black);

  static Color _getColorFromSettings(String key, Color defaultColor) {
    final settings = LocalStorage.getSettingsList();
    final setting = settings.firstWhere(
      (s) => s.key == key,
      orElse: () => SettingsData(),
    );

    if (setting.value == null) return defaultColor;

    try {
      return Color(int.parse('0xFF${setting.value!.substring(1, 7)}'));
    } catch (e) {
      return defaultColor;
    }
  }

  /// @@@@@@@@@@@@@@@@@ Fonts @@@@@@@@@@@@@@@@@@@@@@@@

  static TextStyle interBold({
    double size = 18,
    Color color = Style.black,
    double letterSpacing = 0,
  }) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: FontWeight.bold,
    color: color,
    decoration: TextDecoration.none,
    letterSpacing: letterSpacing,
  );

  static TextStyle interSemi({
    double size = 18,
    Color color = Style.black,
    TextDecoration decoration = TextDecoration.none,
    double letterSpacing = 0,
  }) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: FontWeight.w700,
    color: color,
    letterSpacing: letterSpacing,
    decoration: decoration,
  );

  static TextStyle interNormal({
    double size = 16,
    Color color = Style.black,
    double letterSpacing = 0,
    TextDecoration textDecoration = TextDecoration.none,
  }) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: FontWeight.w500,
    color: color,
    letterSpacing: letterSpacing,
    decoration: textDecoration,
  );

  static TextStyle interRegular({
    double size = 16,
    Color color = Style.black,
    double letterSpacing = 0,
    TextDecoration textDecoration = TextDecoration.none,
    FontStyle? fontStyle,
  }) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: FontWeight.w400,
    color: color,
    letterSpacing: letterSpacing,
    decoration: textDecoration,
    fontStyle: fontStyle,
  );
}
