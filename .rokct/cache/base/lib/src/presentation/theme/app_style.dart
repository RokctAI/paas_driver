// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, version 3.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppStyle {
  AppStyle._();

  /// The app's brand primary, injectable via [injectBrandColors].
  ///
  /// Deliberately NOT `const`: base_sdk must not own an app's brand colour.
  /// The default is Juvo orange, which every Juvo app (customer, driver,
  /// manager, pos) shares — so nothing changes visually until an app
  /// injects. The point of making it injectable is that a per-app change
  /// then happens in that app's HOME SDK (a manager-specific primary is set
  /// from merchants_sdk) rather than by editing the shared kernel.
  ///
  /// Because this is now a getter rather than a compile-time constant, it
  /// cannot appear inside a `const` expression — use the non-const form
  /// (e.g. `CircularProgressIndicator(color: AppStyle.primary)`, not
  /// `const CircularProgressIndicator(...)`).
  static Color _primary = const Color(0xFFFF6600);
  static Color get primary => _primary;

  /// Brand fade used by chart/graph fills (e.g. revenue's income chart):
  /// tracks the injected [primary], so it re-brands with the palette.
  /// Getter, not const - [primary] is brand-mutable.
  static List<Color> get primaryGradient => [
        primary.withOpacity(0.5),
        transparent,
      ];
  static const Color bottomNavigationBarColor = Color(0xFF191919);

  // Dark-surface tokens (page background, raised card surfaces, hairline
  // strokes, secondary text greys). Pages use these — never raw hex — and
  // the values are INJECTED per composed app: the kernel ships neutral
  // defaults only, and each app's brand palette arrives at boot through
  // [injectBrandColors], called from the app's SDK-installed theme shim
  // (lib/presentation/theme/). Mutable statics by design — same
  // pattern as [shimmerBase]/[shimmerHighlight] above.
  // Mode flag — dark-first. The host sets this once per build from the app's
  // themeMode (see app_widget). Every surface token below resolves against it,
  // so pages keep their historical *Dark token names but get the light value
  // in light mode. `context` isn't needed: it's a single app-wide mode.
  static bool isDark = true;

  static void setBrightness(Brightness b) => isDark = b == Brightness.dark;

  // Dark backing values (injectable per composed app via injectBrandColors).
  static Color _surfaceDark = const Color(0xFF101010);
  static Color _cardDark = const Color(0xFF1C1C1C);
  static Color _cardDarkAlt = const Color(0xFF181818);
  static Color _strokeDark = const Color(0xFF2E2E2E);
  static Color _strokeDarkSubtle = const Color(0xFF282828);
  static Color _textDarkSecondary = const Color(0xFF8C8C8C);
  static Color _textDarkFaint = const Color(0xFF7C7C7C);

  // Light counterparts — a soft, warm-neutral light theme (no pure-white
  // glare): the page sits a touch grey, cards a hair brighter for lift.
  static Color _surfaceLight = const Color(0xFFECECEF);
  static Color _cardLight = const Color(0xFFF9F9FB);
  static Color _cardLightAlt = const Color(0xFFF1F1F4);
  static Color _strokeLight = const Color(0xFFD9D9DE);
  static Color _strokeLightSubtle = const Color(0xFFE4E4E9);
  static Color _textLightSecondary = const Color(0xFF5B5B62);
  static Color _textLightFaint = const Color(0xFF8C8C94);

  // Foreground ink that flips with mode. Pages that used [white] for text now
  // use [textPrimary] so labels read on both the dark and light surfaces.
  static const Color _inkDark = Color(0xFFFFFFFF);
  static const Color _inkLight = Color(0xFF1B1B20);

  // Mode-resolving surface tokens.
  static Color get surfaceDark => isDark ? _surfaceDark : _surfaceLight;
  static Color get cardDark => isDark ? _cardDark : _cardLight;
  static Color get cardDarkAlt => isDark ? _cardDarkAlt : _cardLightAlt;
  static Color get strokeDark => isDark ? _strokeDark : _strokeLight;
  static Color get strokeDarkSubtle =>
      isDark ? _strokeDarkSubtle : _strokeLightSubtle;
  static Color get textDarkSecondary =>
      isDark ? _textDarkSecondary : _textLightSecondary;
  static Color get textDarkFaint => isDark ? _textDarkFaint : _textLightFaint;
  static Color get textPrimary => isDark ? _inkDark : _inkLight;

  /// [textPrimary] resolved against an EXPLICIT brightness instead of the
  /// app-wide [isDark] flag — for widgets that take their mode from the
  /// inherited theme (`Theme.of(context).brightness`).
  ///
  /// Reading [isDark] registers no dependency on anything, so a widget whose
  /// only mode input is a static keeps the previous mode's ink until
  /// something else happens to rebuild it. A widget that reads the theme
  /// instead is rebuilt by the mode change itself and asks for its ink here.
  /// Same two values as [textPrimary]; same spirit as the polarity-pinned
  /// [surfaceLightRaw]/[surfaceDarkRaw] pair.
  static Color inkFor(Brightness brightness) =>
      brightness == Brightness.dark ? _inkDark : _inkLight;

  /// [textDarkSecondary] resolved against an EXPLICIT brightness, for the
  /// same reason [inkFor] exists: a widget whose only mode input is the
  /// app-wide [isDark] static registers no dependency, so nothing
  /// reschedules it when the mode flips and it keeps the previous mode's
  /// secondary ink. A widget that reads the inherited theme instead is
  /// rebuilt by the mode change itself and asks for its secondary ink here.
  /// Same two values as [textDarkSecondary]; no new colour.
  static Color secondaryInkFor(Brightness brightness) =>
      brightness == Brightness.dark ? _textDarkSecondary : _textLightSecondary;

  /// [textDarkFaint] resolved against an EXPLICIT brightness. Same reason as
  /// [inkFor] and [secondaryInkFor]: the faintest ink role, for a widget
  /// that takes its mode from the inherited theme rather than from the
  /// app-wide [isDark] static. Same two values as [textDarkFaint].
  static Color faintFor(Brightness brightness) =>
      brightness == Brightness.dark ? _textDarkFaint : _textLightFaint;

  /// [surfaceDark] resolved against an EXPLICIT brightness — the page
  /// background role, for a widget that takes its mode from the inherited
  /// theme. Same two values as [surfaceDark], and NOT to be confused with
  /// the polarity-pinned [surfaceLightRaw]/[surfaceDarkRaw] pair, which
  /// exists for building the host MaterialApp's paired ThemeData and must
  /// never resolve at all. This one answers "what background does THIS
  /// brightness want", which is the question a Scaffold in a themed
  /// subtree is asking.
  static Color surfaceFor(Brightness brightness) =>
      brightness == Brightness.dark ? _surfaceDark : _surfaceLight;

  /// [cardDark] resolved against an EXPLICIT brightness — the raised card
  /// fill, the most-asked-for role in this family: almost every shared
  /// component that draws a surface of its own draws this one. Same reason
  /// as [inkFor]: a widget whose only mode input is the app-wide [isDark]
  /// static registers no dependency on anything, so a theme-mode flip
  /// schedules no rebuild of it and it keeps the previous mode's fill until
  /// something else happens to rebuild it. A widget that reads the
  /// inherited theme instead is rebuilt by the flip itself and asks for its
  /// fill here. Same two values as [cardDark]; no new colour.
  static Color cardFor(Brightness brightness) =>
      brightness == Brightness.dark ? _cardDark : _cardLight;

  /// [cardDarkAlt] resolved against an EXPLICIT brightness — the SECOND
  /// card fill, a hair off [cardFor], for a panel that has to read as
  /// distinct from the card it sits on (a social button's ground, a nested
  /// well). Same reason as [cardFor]; same two values as [cardDarkAlt].
  static Color cardAltFor(Brightness brightness) =>
      brightness == Brightness.dark ? _cardDarkAlt : _cardLightAlt;

  /// [strokeDark] resolved against an EXPLICIT brightness — the hairline
  /// border role. Same reason as [cardFor]: a border named from the
  /// app-wide static outlives the mode it was chosen for, which on a
  /// stroke is the most visible way to get this wrong (a dark hairline
  /// left on a light card reads as a mistake). Same two values as
  /// [strokeDark].
  static Color strokeFor(Brightness brightness) =>
      brightness == Brightness.dark ? _strokeDark : _strokeLight;

  /// [strokeDarkSubtle] resolved against an EXPLICIT brightness — the
  /// quieter hairline, for a divider inside a card rather than around one.
  /// Same reason as [strokeFor]; same two values as [strokeDarkSubtle].
  static Color subtleStrokeFor(Brightness brightness) =>
      brightness == Brightness.dark ? _strokeDarkSubtle : _strokeLightSubtle;

  // Polarity-PINNED page backgrounds (never mode-resolving): for building
  // the host MaterialApp's paired ThemeData — `theme:` must stay light and
  // `darkTheme:` dark regardless of the current [isDark] flag. They track
  // the injected brand palette. Page code should keep using the
  // mode-resolving getters above.
  static Color get surfaceLightRaw => _surfaceLight;
  static Color get surfaceDarkRaw => _surfaceDark;

  /// Brand-palette injection seam: a composed app overrides the DARK backing
  /// values at boot (before the first frame). Only the parameters an app
  /// passes change; the light counterparts keep the kernel's neutral defaults.
  static void injectBrandColors({
    Color? primary,
    Color? surfaceDark,
    Color? cardDark,
    Color? cardDarkAlt,
    Color? strokeDark,
    Color? strokeDarkSubtle,
    Color? textDarkSecondary,
    Color? textDarkFaint,
  }) {
    _primary = primary ?? _primary;
    _surfaceDark = surfaceDark ?? _surfaceDark;
    _cardDark = cardDark ?? _cardDark;
    _cardDarkAlt = cardDarkAlt ?? _cardDarkAlt;
    _strokeDark = strokeDark ?? _strokeDark;
    _strokeDarkSubtle = strokeDarkSubtle ?? _strokeDarkSubtle;
    _textDarkSecondary = textDarkSecondary ?? _textDarkSecondary;
    _textDarkFaint = textDarkFaint ?? _textDarkFaint;
  }
  static const Color enterOrderButton = Color(0xFFF4F8F7);
  static const Color tabBarBorderColor = Color(0xFFDEDFE1);
  static const Color orderButtonColor = Color(0xFF323232);
  static const Color dotColor = Color(0xFFBDBEC1);
  static const Color switchBg = Color(0xFFD3D3D3);
  static const Color white = Color(0xFFFFFFFF);
  static const Color transparent = Color(0x00FFFFFF);

  /// The ONE system-chrome style every composed app runs under: both bars
  /// fully transparent (the app draws full frame behind them — no OS scrim
  /// either), with white status/nav icons, because these apps' top and
  /// bottom regions are dark-on-dark by design (dark theme + brand
  /// primaries), so light icons are what keeps the clock/battery visible.
  /// Referenced by the composed main.dart (boot default), the shell theme's
  /// AppBarTheme.systemOverlayStyle (Material AppBars otherwise repaint the
  /// navigation bar opaque black via SystemUiOverlayStyle.light) and the
  /// splash's edge-to-edge re-assert. A screen with a genuinely light top
  /// region can still override locally with an
  /// AnnotatedRegion<SystemUiOverlayStyle>.
  static const SystemUiOverlayStyle systemUiOverlay = SystemUiOverlayStyle(
    statusBarColor: transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarColor: transparent,
    systemNavigationBarDividerColor: transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarContrastEnforced: false,
  );
  static const Color black = Color(0xFF232B2F);
  static const Color blackWithOpacity = Color(0x20232B2F);
  static const Color whiteWithOpacity = Color(0x90FFFFFF);
  static const Color dontHaveAccBtnBack = Color(0xFFF8F8F8);
  static const Color mainBack = Color(0xFFF4F4F4);
  static const Color borderColor = Color(0xFFE6E6E6);
  static const Color textGrey = Color(0xFF898989);
  static const Color buttonFont = Color(0xFFFFFFFF);
  // Added during the 2026-07 refork for composed-app template pages that
  // referenced the retired core_sdk theme surface.
  static const Color blackColor = Color(0xFF000000);
  static const Color subCategory = Color(0xFFF6F6F6);
  static const Color textHint = Color(0xFF939393);
  static const Color green = Color(0xFF16AA16);
  static const Color icons = Color(0xFF232B2F);
  static const Color text = Color(0xFF898989);

  static const Color recommendBg = Color(0xFFE8C7B0);
  static const Color bannerBg = Color(0xFFF3DED4);
  static const Color bgGrey = Color(0xFFF4F5F8);
  static const Color outlineButtonBorder = Color(0xFFD2D2D7);
  static const Color bottomNavigationBack = Color.fromRGBO(0, 0, 0, 0.06);
  static const Color unselectedBottomItem = Color(0xFFA1A1A1);
  static const Color hintColor = Color(0xFFA7A7A7);
  static const Color unselectedTab = Color(0xFF929292);
  static const Color newStoreDataBorder = Color(0xDCDCDCC9);
  static const Color differBorderColor = Color(0xFFE0E0E0);
  static const Color starColor = Color(0xFFFFA826);
  static const Color doorColor = Color(0xFFFFC636);
  static const Color dragElement = Color(0xFFC4C5C7);
  static const Color addProductSearchedToBasket = Color.fromRGBO(0, 0, 0, 0.62);
  static const Color rate = Color(0xFFFFB800);
  static const Color red = Color(0xFFFF3D00);
  static const Color redBg = Color(0xFFFFF2EE);
  // Pending-status pair (tint background + strong foreground) used by the
  // manager food cards installed from orders_sdk/products_sdk templates.
  static const Color pending = Color(0xFFFEFAF2);
  static const Color pendingDark = Color(0xFFF19204);
  static const Color blue = Color(0xFF03758E);
  static const Color blueBonus = Color(0xFF0D5FFF);
  static const Color divider = Color.fromRGBO(0, 0, 0, 0.04);
  static const Color reviewText = Color(0xFF88887E);
  static const Color bannerGradient1 = Color.fromRGBO(0, 0, 0, 0.5);
  static const Color bannerGradient2 = Color.fromRGBO(0, 0, 0, 0);
  static const Color brandTitleDivider = Color(0xFF999999);
  static const Color discountProduct = Color(0xFFD21234);
  static const Color notificationTime = Color(0xFF8B8B8B);
  static const Color separatorDot = Color(0xFFD9D9D9);
  static Color shimmerBase = Colors.grey.shade300;
  static Color shimmerHighlight = Colors.grey.shade100;
  static const Color locationAddress = Color(0xFF343434);
  static const Color selectedItemsText = Color(0xFFA0A09C);
  static const Color iconButtonBack = Color(0xFFE9E9E6);
  static const Color shadowCart = Color.fromRGBO(194, 194, 194, 0.65);
  static const Color extrasInCart = Color(0xFF9EA3A8);
  static const Color notDoneOrderStatus = Color(0xFFF5F6F6);
  static const Color unselectedBottomBarBack = Color(0xFFEFEFEF);
  static const Color unselectedBottomBarItem = Color(0xFFB9B9B9);
  static const Color bottomNavigationShadow = Color.fromRGBO(
    207,
    207,
    207,
    0.65,
  );
  static const Color profileModalBack = Color(0xFFF5F5F5);
  static const Color arrowRightProfileButton = Color(0xFFCCCCCC);
  static const Color customMarkerShadow = Color.fromRGBO(117, 117, 117, 0.29);
  static const Color selectedTextFromModal = Color(0xFF202020);
  static const Color verticalDivider = Color(0xFFDDDDDA);
  static const Color unselectedOrderStatus = Color(0xFFE9E9E9);
  static const Color borderRadio = Color(0xFFB8B8B8);
  static const Color shippingType = Color(0xFF95999D);
  static const Color attachmentBorder = Color(0xFFDCDCDC);
  static const Color orderStatusProgressBack = Color(0xFFE7E7E7);
  static const Color shadow = Color(0x3FD8D8D8);
  static const Color shadowBottom = Color(0x33000000);

  /// dark theme based colors
  static const Color mainBackDark = Color(0xFF1E272E);
  static const Color dontHaveAnAccBackDark = Color(0xFF2B343B);
  static const Color dragElementDark = Color(0xFFE5E5E5);
  static const Color shimmerBaseDark = Color.fromRGBO(117, 117, 117, 0.29);
  static const Color shimmerHighlightDark = Color.fromRGBO(194, 194, 194, 0.65);
  static const Color borderDark = Color(0xFF494B4D);
  static const Color partnerChatBack = Color(0xFF1A222C);
  static const Color yourChatBack = Color(0xFF25303F);

  /// font style
  ///
  /// Every helper's `color` defaults to the mode-resolving [textPrimary]
  /// (white on dark, near-black ink on light) so the fleet's color-omitting
  /// call sites read correctly in BOTH modes. A nullable parameter rather
  /// than a const default because [textPrimary] resolves against [isDark]
  /// at call time; call sites that pass a color are untouched.

  static interBold({
    double size = 18,
    Color? color,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.inter(
        fontSize: size.sp,
        fontWeight: FontWeight.bold,
        color: color ?? textPrimary,
        letterSpacing: letterSpacing.sp,
        decoration: TextDecoration.none,
      );

  static interSemi({
    double size = 18,
    Color? color,
    TextDecoration decoration = TextDecoration.none,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.inter(
        fontSize: size.sp,
        fontWeight: FontWeight.w700,
        color: color ?? textPrimary,
        letterSpacing: letterSpacing.sp,
        decoration: decoration,
      );

  static interNoSemi({
    double size = 18,
    Color? color,
    TextDecoration decoration = TextDecoration.none,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.inter(
        fontSize: size.sp,
        fontWeight: FontWeight.w600,
        color: color ?? textPrimary,
        letterSpacing: letterSpacing.sp,
        decoration: decoration,
      );

  static interNormal({
    double size = 16,
    Color? color,
    TextDecoration textDecoration = TextDecoration.none,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.inter(
        fontSize: size.sp,
        fontWeight: FontWeight.w500,
        color: color ?? textPrimary,
        letterSpacing: letterSpacing.sp,
        decoration: textDecoration,
      );

  static interRegular({
    double size = 16,
    Color? color,
    TextDecoration textDecoration = TextDecoration.none,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: FontWeight.w400,
        color: color ?? textPrimary,
        letterSpacing: letterSpacing.sp,
        decoration: textDecoration,
      );

  ///Juvo Font Styles - Using Montserrat
  static logoFontBold({
    double size = 18,
    Color? color,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.montserrat(
        fontSize: size.sp,
        fontWeight: FontWeight.w700, // Bold 700
        color: color ?? textPrimary,
        letterSpacing: letterSpacing.sp,
        decoration: TextDecoration.none,
      );

  static logoFontBoldItalic({
    double size = 18,
    Color? color,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.montserrat(
        fontSize: size.sp,
        fontWeight: FontWeight.w700, // Bold 700
        fontStyle: FontStyle.italic,
        color: color ?? textPrimary,
        letterSpacing: letterSpacing.sp,
        decoration: TextDecoration.none,
      );

  static logoFontBlackItalic({
    double size = 18,
    Color? color,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.montserrat(
        fontSize: size.sp,
        fontWeight: FontWeight.w900, // Black 900
        fontStyle: FontStyle.italic,
        color: color ?? textPrimary,
        letterSpacing: letterSpacing.sp,
        decoration: TextDecoration.none,
      );

  // Logo Motto styles - Using Montserrat
  static logoMottoRegular({
    double size = 16,
    Color? color,
    TextDecoration textDecoration = TextDecoration.none,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.montserrat(
        fontSize: size.sp,
        fontWeight: FontWeight.w400, // Regular 400
        color: color ?? textPrimary,
        letterSpacing: letterSpacing.sp,
        decoration: textDecoration,
      );

  static logoMottoRegularItalic({
    double size = 16,
    Color? color,
    TextDecoration textDecoration = TextDecoration.none,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.montserrat(
        fontSize: size.sp,
        fontWeight: FontWeight.w400, // Regular 400
        fontStyle: FontStyle.italic,
        color: color ?? textPrimary,
        letterSpacing: letterSpacing.sp,
        decoration: textDecoration,
      );
}
