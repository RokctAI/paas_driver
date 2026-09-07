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

// Render harness for paas_driver — the courier PROFILE screen.
//
// Copied from RokctAI/shared-workflows templates/render-harness/ and worked
// through its eight `TODO(harness)` markers. Everything below the
// "proven mechanism" line is the template verbatim: the height fixed-point
// pass, the real-event-loop drain, the RepaintBoundary capture and the rect
// sidecar are what make the output composable by
// scripts/render/compose_strip.py.
//
// WHY THE PROFILE AND NOT THE HOME. The courier home is this shell's landing
// screen, but it is a full-bleed `GoogleMap` platform view plus Geolocator,
// FirebaseMessaging and WorkManager. Headless, the map surface is a blank
// grey grid (no tiles are ever fetched), so the frame would be a picture of
// nothing. The profile is the next-densest driver-owned surface — identity
// header, balance / earnings cards and the whole settings register — and it
// renders entirely from delivery_sdk's and revenue_sdk's own demo
// repositories.
//
// Data comes from the SDKs, not from here: run with
// `--dart-define=IS_DEMO=true` and the composed app's DI hands back
// DemoCourierRepository, DemoCourierStatisticsRepository, MockAuthRepository
// and friends. See scripts/render/README.md §2.5 in shared-workflows.
//
// Run (after a compose, so lib/ and the SDK caches exist):
//   flutter test --dart-define=IS_DEMO=true test/render/render_screen_test.dart
//   RENDER_SUFFIX=_draft flutter test --dart-define=IS_DEMO=true \
//       test/render/render_screen_test.dart

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// TODO(harness) 1/8 — imports of the code under test. Deep `src/` paths are
// expected: the harness is deliberately coupled to the shipped code.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
// The offline seam google_fonts documents for tests: `httpClient` is
// @visibleForTesting, so the harness can serve the faces committed beside
// this file instead of reaching fonts.gstatic.com.
// ignore: implementation_imports
import 'package:google_fonts/src/google_fonts_base.dart' as google_fonts_base;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:auth_sdk/src/common/di/auth_di.dart';
import 'package:auth_sdk/src/common/services/session_profile.dart';
import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/di/base_di.dart';
import 'package:base_sdk/src/domain/interface/auth.dart';
// ApiResult's `when` is an extension declared in its freezed part, so the
// library that declares it has to be imported for the pattern to be in scope.
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/presentation/adaptive/breakpoints.dart';
import 'package:base_sdk/src/presentation/components/floating_nav/floating_bottom_nav.dart';
import 'package:base_sdk/src/presentation/pages/profile/generic_profile_page.dart';
import 'package:base_sdk/src/presentation/pages/profile/widgets/base_profile_footer.dart';
import 'package:base_sdk/src/presentation/pages/profile/widgets/profile_nav_tile.dart';
import 'package:base_sdk/src/presentation/pages/profile/widgets/profile_section_card.dart';
import 'package:base_sdk/src/presentation/pages/profile/widgets/profile_theme_toggle.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_ui_keys.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:comms_sdk/src/common/di/comms_di.dart';
import 'package:delivery_sdk/src/common/di/delivery_di.dart';
import 'package:delivery_sdk/src/driver/di/driver_delivery_di.dart';
import 'package:delivery_sdk/src/driver/presentation/profile/driver_profile_sections.dart';
import 'package:map_sdk/src/common/di/map_sdk_di.dart';
import 'package:merchants_sdk/src/common/di/merchants_di.dart';
import 'package:orders_sdk/src/common/di/orders_di.dart';
import 'package:products_sdk/src/common/di/products_di.dart';
import 'package:revenue_sdk/src/driver/di/driver_revenue_di.dart';
import 'package:users_sdk/src/common/di/users_di.dart';
import 'package:zones_sdk/src/common/di/zones_di.dart';

import 'package:driver/presentation/pages/profile/courier_statistics_provider.dart';
import 'package:driver/presentation/pages/profile/profile_page.dart';

// ---------------------------------------------------------------------------
// Render settings - phone size the reviews are judged at. Only change these
// if the whole review is moving to a different device class.
// ---------------------------------------------------------------------------

/// Logical width of the frame (iPhone-class phone). The strip composer scales
/// the PNG to the bezel, so this only affects LAYOUT, not output resolution.
const double kLogicalWidth = 390;

/// Device pixel ratio the PNG is captured at (3 = @3x, crisp on any display).
const double kDevicePixelRatio = 3.0;

/// Tall probe viewport for the first pass. Must exceed the tallest screen; the
/// second pass shrinks to the measured content height.
const double kProbeHeight = 2600;

/// Slack below the last element in the final frame, in logical pixels.
const double kBottomPadding = 20;

/// The demo courier this shell signs in as. auth_sdk's MockAuthRepository maps
/// this address to the `deliveryman` role, which is the role delivery_sdk's
/// session policy admits to /home in the driver app.
const String kDemoCourierEmail = 'driver@demo.rokct.ai';

/// TODO(harness) 2/8 - the SDK's own demo data. THIS IS THE MAIN PATH.
///
/// Exactly the registrations the composed `lib/main.dart` makes, in the same
/// order: the generated `@generated-sdk-di` block first, then the
/// `@generated-di-hooks` block's driver-role hooks. With
/// `--dart-define=IS_DEMO=true` those hand back the SDKs' own demo
/// repositories (DemoCourierRepository, DemoCourierStatisticsRepository,
/// MockAuthRepository, MockAddressRepository) instead of the HTTP ones — no
/// fixtures are written here.
///
/// Only the SDKs this screen's widget tree actually resolves are registered;
/// the rest of the composed set (telemetry, hms, desktop, calc, weather,
/// processing, corporate) contributes nothing the profile reads.
Future<void> registerDemoDependencies() async {
  assert(
    AppConstants.isDemo,
    'run with --dart-define=IS_DEMO=true, or the SDKs register their real '
    'HTTP repositories and the render is of a broken, empty screen',
  );
  final GetIt getIt = GetIt.instance;
  BaseSdkDependencies.register(getIt);
  AuthSdkDependencies.register(getIt);
  CommsSdkDependencies.register(getIt);
  DeliverySdkDependencies.register(getIt);
  MapSdkDependencies.register(getIt);
  MerchantsSdkDependencies.register(getIt);
  OrdersSdkDependencies.register(getIt);
  ProductsSdkDependencies.register(getIt);
  UsersSdkDependencies.register(getIt);
  ZonesSdkDependencies.register(getIt);
  // Driver-role DI hooks, mirroring main.dart's @generated-di-hooks block.
  DriverDeliveryDependencies.register(getIt);
  DriverRevenueDependencies.register(getIt);
}

/// TODO(harness) 3/8 - EXCEPTION: device history the demo mode cannot supply.
///
/// The one thing demo mode does not hand a widget test is a SESSION. The
/// profile header reads `LocalStorage.getUser()`, which is written by
/// auth_sdk's `_establishSession` when the courier signs in; a widget test
/// never walks that journey, so on a fresh temp store the header renders
/// nameless.
///
/// So sign in the way the app does: through the REAL
/// `AuthRepositoryFacade.login` (demo mode has already made that
/// MockAuthRepository), map the account with auth_sdk's own
/// `sessionProfileOf`, and persist it through the app's own `LocalStorage`
/// API. Every value on the header is therefore the SDK's demo account, not a
/// number typed in here. Declared in the strip config's notes.
Future<void> seedDeviceHistory(WidgetTester tester) async {
  await tester.runAsync(() async {
    final auth = GetIt.instance.get<AuthRepositoryFacade>();
    final response = await auth.login(
      email: kDemoCourierEmail,
      password: 'demo',
    );
    await response.when(
      success: (data) async {
        await LocalStorage.setToken(data.data?.accessToken ?? '');
        final user = data.data?.user;
        if (user != null) {
          await LocalStorage.setUser(sessionProfileOf(user));
        }
      },
      failure: (failure, status) async {
        throw StateError('demo sign-in failed ($status): $failure');
      },
    );
  });
}

/// TODO(harness) 4/8 - EXCEPTION: stub a service with no demo implementation.
///
/// Empty. Every facade the profile resolves has an `isDemo` twin in its own
/// SDK, so nothing is stubbed here.
void registerExceptionStubs() {}

/// TODO(harness) 5/8 - register sections / routes / gates.
///
/// Deliberately EMPTY, and that is the fidelity point.
///
/// The courier profile is now base_sdk's [GenericProfilePage] host, and its
/// content arrives through `ProfileSectionRegistry` — the header stats slot,
/// the nine navigation rows and the Online-helper section. The registration
/// is not something a harness should perform: the installed
/// `lib/presentation/pages/profile/profile_page.dart` shell calls
/// `registerDriverProfileSections()` from its OWN `initState`, before the
/// host's first build, exactly as it does in the app. Registering the
/// sections here as well would mean the render proved the registry works
/// when driven by a test, not when driven by the shell.
///
/// [verifyFinders] then asserts the sections actually arrived, so a shell
/// that stops registering them fails the run loudly instead of rendering an
/// empty profile that still looks plausible.
///
/// The one gate on the row list (`if (!AppConstants.isDemo)`, which hides
/// "Delete account") resolves from the same dart-define the data does.
void registerScreen() {}

/// TODO(harness) 6/8 - the widget under test.
///
/// The real [ProfilePage] — the composed app's own `/profile` route widget,
/// installed by delivery_sdk into
/// `lib/presentation/pages/profile/profile_page.dart` — wrapped the way
/// `lib/presentation/app_widget.dart` wraps every screen.
///
/// WRAPPING FIDELITY (shared-workflows scripts/render/README.md §2.6). An
/// incomplete wrapper is the one fault this kit cannot absorb: it produces a
/// clean, convincing PNG of a screen no user ever sees, and nothing
/// downstream can tell. Three things are therefore copied from the host
/// rather than approximated:
///
///  1. **The whole route widget, not the page inside it.** [ProfilePage] is
///     not a thin alias for [GenericProfilePage]; it is a `Stack` that hosts
///     the generic profile inside a two-plane `PlaneHost` and parks the
///     screen's one Back affordance itself — the bare pill at the bottom
///     centre on a phone, at the bottom-END corner on plane widths. Pumping
///     `GenericProfilePage` directly would render a profile with no back and
///     no plane host: a screen the driver app does not have.
///  2. **Both ThemeDatas and the themeMode**, with their `appBarTheme`.
///     `theme:` alone, switched on the `dark` flag, renders both frames from
///     ONE ThemeData, so the "dark" frame is the light theme with a
///     brightness flag flipped rather than the app's dark theme. The
///     `appBarTheme.systemOverlayStyle` pin is copied too: the host carries
///     it on both themes and a Material AppBar derives a different style
///     without it.
///  3. **The adaptive design size.** The host does not pin 375x812; it
///     passes the real logical size once the window is past
///     [AppBreakpoints.medium], so `.w`/`.h`/`.sp` resolve ~1:1 on a wide
///     window instead of blowing a phone design up. The frame this harness
///     renders is compact (390 logical px), so the compact branch is what
///     runs — but the rule is copied rather than the outcome, so a future
///     wide frame is honest without another visit here.
///
/// The one deliberate divergence is `MaterialApp` with `home:` instead of the
/// host's `MaterialApp.router`: driving the real auto_route delegate would
/// land the test on the splash/login route and never reach the profile, which
/// is reached in the app by a push from the home map. The route WIDGET is the
/// real one either way, and it is what owns everything on the frame.
///
/// No overrides — the providers resolve against the demo DI registered above.
Widget buildScreen({required bool dark}) {
  return ProviderScope(
    child: LayoutBuilder(
      builder: (context, constraints) {
        // Copied from app_widget.dart: the phone design size applies only to
        // phone-shaped (compact) windows.
        final Size logicalSize = constraints.biggest;
        final bool isCompact = logicalSize.width < AppBreakpoints.medium;
        return ScreenUtilInit(
          useInheritedMediaQuery: false,
          designSize: isCompact ? const Size(375, 812) : logicalSize,
          builder: (context, child) => MaterialApp(
            debugShowCheckedModeBanner: false,
            // Root messenger handle, as the host wires it: SDK services with
            // no BuildContext surface SnackBars through it, and the profile
            // does exactly that on a headless run.
            scaffoldMessengerKey: AppUiKeys.scaffoldMessenger,
            locale: const Locale('en'),
            theme: ThemeData(
              useMaterial3: false,
              brightness: Brightness.light,
              scaffoldBackgroundColor: AppStyle.surfaceLightRaw,
              appBarTheme: const AppBarTheme(
                systemOverlayStyle: AppStyle.systemUiOverlay,
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: false,
              brightness: Brightness.dark,
              scaffoldBackgroundColor: AppStyle.surfaceDarkRaw,
              appBarTheme: const AppBarTheme(
                systemOverlayStyle: AppStyle.systemUiOverlay,
              ),
            ),
            // The host reads this from AppNotifier's isDarkMode; renderVariant
            // seeds the same stored value and calls AppStyle.setBrightness
            // before the first pump, so the Material tree and AppStyle's own
            // mode-resolving tokens agree.
            themeMode: dark ? ThemeMode.dark : ThemeMode.light,
            home: const _CourierJourney(child: ProfilePage()),
          ),
        );
      },
    ),
  );
}

/// The one provider read the courier's own journey performs before profile is
/// ever reached: `home_page.dart`'s `initState` post-frame callback fires
/// `fetchProfileStatistics`, so by the time a courier taps through to the
/// profile the earnings card is filled. Reached directly (as a widget test
/// must), that fetch has never run and the card renders its honest zeroes.
///
/// This wrapper fires the SAME call the home page fires, against the same
/// demo repository, so the frame shows the earnings a courier actually sees.
/// Part of harness marker 3/8, and declared in the strip config's notes.
class _CourierJourney extends ConsumerStatefulWidget {
  const _CourierJourney({required this.child});

  final Widget child;

  @override
  ConsumerState<_CourierJourney> createState() => _CourierJourneyState();
}

class _CourierJourneyState extends ConsumerState<_CourierJourney> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(courierProfileStatisticsProvider.notifier)
          .fetchProfileStatistics(context: context);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// TODO(harness) 7/8 - the elements the review points at.
///
/// `key` is the stable identity the composer binds a number to for the life
/// of the page. Reword `label` freely; never reword `key`.
///
/// These keys are a NEW generation. The courier profile moved onto base_sdk's
/// generic profile host (delivery_sdk 1.21.0), which retired the standalone
/// page's `CustomAppBar` identity header, its two white stat cards and its
/// `SectionsItem` rows. The old `delivery.driver.profile.*` keys named
/// widgets that no longer exist, so they are retired in strip.json rather
/// than rebound to different elements — a number that silently changes
/// meaning is worse than a number that is gone.
///
/// Every finder below is scoped to the real page and resolves to a PUBLIC
/// type or a public `Key`, never to a private one and never to a bare layout
/// widget: `Container`, `Row` and `IntrinsicHeight` all appear a dozen times
/// in this tree and an unscoped match would chip the wrong box. [verifyFinders]
/// asserts the exact arity of each one before anything is measured.
List<ElementSpec> elementSpecs() {
  return <ElementSpec>[
    ElementSpec(
      key: 'driver.profile.theme_toggle',
      label: 'Theme toggle - light/dark pill in the host top row',
      finder: find.byType(ProfileThemeToggle),
    ),
    ElementSpec(
      key: 'driver.profile.identity_card',
      label: 'Identity card - avatar, name, email, role and the edit pencil',
      finder: find.byKey(GenericProfilePage.accountHeaderKey),
    ),
    ElementSpec(
      key: 'driver.profile.stats_row',
      label: 'Courier stats - balance, last profit, delivered orders',
      finder: find.byType(DriverProfileStatsRow),
    ),
    ElementSpec(
      key: 'driver.profile.rows_card',
      label: 'Settings register - the driver row list on one card',
      finder: find.byType(ProfileSectionCard),
    ),
    ElementSpec.each(
      keyOf: (i, w) => 'driver.profile.nav_tile.${(w as ProfileNavTile).title}',
      labelOf: (i, w) => 'Row - ${(w as ProfileNavTile).title}',
      finder: find.byType(ProfileNavTile),
    ),
    ElementSpec(
      key: 'driver.profile.online_helper',
      label: 'Online helper - the support call button',
      finder: find.byType(DriverOnlineHelperSection),
    ),
    ElementSpec(
      key: 'driver.profile.footer',
      label: 'Host footer - app name, version, online dot and usage badge',
      finder: find.byType(BaseProfileFooter),
    ),
    // NOT numbered, deliberately: the bare Back pill ([FloatingBottomNav],
    // asserted present in verifyFinders) is VIEWPORT-anchored rather than
    // content-anchored, so its measured bottom is always the bottom of the
    // probe viewport. The height fixed-point takes the maximum measured
    // bottom, so chipping it would pin every frame to kProbeHeight. Same for
    // the offline SnackBar the headless run raises. Both are in the picture;
    // they just cannot carry a chip.
  ];
}

/// Fails the run, loudly and with a reason, when a finder stops meaning what
/// it meant.
///
/// This exists because the page changed underneath the harness once already:
/// delivery_sdk 1.21.0 deleted `SectionsItem`, and the import alone broke the
/// build — which was the lucky case. The dangerous case is a finder that
/// still resolves but to a different number of widgets: a spec that silently
/// matches zero drops a numbered point off the strip, and one that matches
/// several chips whichever the framework happened to order first. Neither
/// shows up in the PNG.
///
/// So every spec's arity is asserted before a single rect is measured, and
/// the assertions double as a statement of what this screen IS.
void verifyFinders(WidgetTester tester) {
  void expectCount(String what, Finder finder, int count) {
    expect(
      finder,
      findsNWidgets(count),
      reason: 'render harness: expected $count "$what" on the courier '
          'profile, found ${finder.evaluate().length}. The page has changed '
          'under the harness - re-scope elementSpecs() rather than deleting '
          'this check.',
    );
  }

  // The route widget and the host page inside it.
  expectCount('ProfilePage route widget', find.byType(ProfilePage), 1);
  expectCount('GenericProfilePage host', find.byType(GenericProfilePage), 1);

  // The signed-in header, NOT the anonymous one. If seedDeviceHistory's
  // sign-in ever stops taking, the host falls back to its anonymous header
  // and the frame would show a plausible, signed-out profile.
  expectCount(
    'signed-in identity card',
    find.byKey(GenericProfilePage.accountHeaderKey),
    1,
  );
  expect(
    find.byKey(GenericProfilePage.anonymousHeaderKey),
    findsNothing,
    reason: 'render harness: the host is drawing its ANONYMOUS header, so the '
        'demo sign-in in seedDeviceHistory did not take. The frame would be a '
        'signed-out profile that still looks convincing.',
  );

  // delivery_sdk's registered content, proving the shell registered it.
  expectCount('stats row', find.byType(DriverProfileStatsRow), 1);
  expectCount('driver rows section', find.byType(DriverProfileRows), 1);
  expectCount('rows card', find.byType(ProfileSectionCard), 1);
  expectCount(
    'online helper section',
    find.byType(DriverOnlineHelperSection),
    1,
  );

  // Nine rows: the full register minus "Delete account", which the page hides
  // behind `if (!AppConstants.isDemo)` and this run is a demo run.
  expectCount('navigation row', find.byType(ProfileNavTile), 9);
  expect(
    find.widgetWithText(ProfileNavTile, 'Delete account'),
    findsNothing,
    reason: 'render harness: "Delete account" is gated on !AppConstants.isDemo '
        'and this render is IS_DEMO=true, so it must not be on the frame.',
  );

  // Host chrome the route widget itself owns.
  expectCount('host footer', find.byType(BaseProfileFooter), 1);
  expectCount('theme toggle', find.byType(ProfileThemeToggle), 1);
  expectCount('bare Back pill', find.byType(FloatingBottomNav), 1);
}

/// TODO(harness) 8/8 - real fonts.
///
/// Two sources, no network:
///
///  * **Inter** - `AppStyle`'s whole type scale is `GoogleFonts.inter(...)`,
///    and google_fonts fetches faces at runtime. A test has no network, and a
///    silent fetch failure is a silent block-font fallback, so the faces
///    Google itself serves are committed beside this file, named by the
///    SHA-256 google_fonts expects, and handed back through google_fonts'
///    own `@visibleForTesting` http seam. google_fonts then takes its normal
///    path: it verifies each file's length AND checksum before registering
///    it, so the render is provably the real Inter and not a lookalike. A
///    weight nobody committed 404s and fails the run loudly rather than
///    quietly rendering the FlutterTest block font.
///  * **Everything the app already bundles** - MaterialIcons, Remix,
///    flutter_remix - read straight out of the test asset bundle's
///    `FontManifest.json`, so no icon font is committed here and none can
///    drift from the app's own.
///
/// See test/render/fonts/README.md for the hash -> weight table.
Future<void> loadRealFonts() async {
  final fontsDir = Directory('${Directory.current.path}/test/render/fonts');
  if (!fontsDir.existsSync()) {
    throw StateError(
      'no committed Google faces at ${fontsDir.path} - every glyph would fall '
      'back to the FlutterTest block font and the render would be worthless.',
    );
  }
  google_fonts_base.httpClient = _OfflineGoogleFontsClient(fontsDir);

  // Warm every Inter weight AppStyle uses BEFORE the first pump, and wait for
  // the registrations to land. google_fonts registers asynchronously, so
  // without this the first variant lays out with fallback metrics and only
  // re-measures once the faces arrive - which showed up as a dark frame with
  // missing glyphs and a 3px overflow the light frame (rendered after the
  // static font cache was warm) did not have. Deterministic, and identical
  // for both variants.
  await GoogleFonts.pendingFonts(<TextStyle>[
    GoogleFonts.inter(fontWeight: FontWeight.w400),
    GoogleFonts.inter(fontWeight: FontWeight.w500),
    GoogleFonts.inter(fontWeight: FontWeight.w600),
    GoogleFonts.inter(fontWeight: FontWeight.w700),
  ]);

  // THE BLOCK-GLYPH FIX. Two elements rendered as solid white rectangles on
  // an otherwise correct frame - the Back pill's label and the demo avatar's
  // "TM" initials - which reads to a reviewer as a broken page.
  //
  // It is NOT a missing Inter weight: all four faces AppStyle asks for are
  // committed under test/render/fonts/ and warmed above. Measured cause, from
  // a probe that compares laid-out text width (an Ahem block advances exactly
  // one em, so "Back" at 20px is 80.0pt wide in the block font and 43.9pt in
  // real Roboto):
  //
  //   * inside a Material ancestor a bare TextStyle inherits fontFamily
  //     'Roboto' from the theme's Typography - real glyphs, once Roboto is
  //     registered (this is why the SnackBar's "Close" is fine);
  //   * the floating Back pill sits in the route Stack ABOVE the page with no
  //     Material ancestor, so it inherits WidgetsApp's fallback DefaultTextStyle
  //     instead, whose family is 'monospace' (the pill's own code overrides
  //     that style's colour and its debug underline, but not its family);
  //   * the demo avatar is an inline SVG whose <text> asks for
  //     "Helvetica, Arial, sans-serif" (DemoImages.avatar).
  //
  // A device resolves 'monospace', 'Helvetica' and 'Arial' to real system
  // faces. The headless test engine has none of them registered, so both fall
  // through to the Ahem-like block font. Pointing those generic family names
  // at a real face is what a device does; doing it here is what makes the
  // frame show what the app shows. Nothing new is committed for it - Roboto
  // and MaterialIcons ship inside the Flutter SDK's own artifact cache.
  final String? flutterRoot = Platform.environment['FLUTTER_ROOT'];
  final Directory materialFonts = Directory(
    '${flutterRoot ?? ''}/bin/cache/artifacts/material_fonts',
  );
  if (flutterRoot != null && materialFonts.existsSync()) {
    Future<void> loadFiles(String family, List<String> names) async {
      final loader = FontLoader(family);
      var any = false;
      for (final name in names) {
        final file = File('${materialFonts.path}/$name');
        if (!file.existsSync()) continue;
        loader.addFont(
          Future<ByteData>.value(ByteData.view(file.readAsBytesSync().buffer)),
        );
        any = true;
      }
      if (any) await loader.load();
    }

    const List<String> roboto = <String>[
      'Roboto-Regular.ttf',
      'Roboto-Medium.ttf',
      'Roboto-Bold.ttf',
    ];

    await loadFiles('MaterialIcons', ['MaterialIcons-Regular.otf']);
    await loadFiles('Roboto', roboto);

    // The generic family names above, aliased onto the same real face. Roboto
    // is not a monospaced design, so the Back pill's label is proportional
    // here where a device would space it evenly - a difference in metrics, not
    // in whether a reviewer can read the word.
    //
    // The last entry is not a typo. vector_graphics_compiler takes the SVG
    // `font-family` attribute WHOLE - `fontFamily: attributeMap['font-family']`
    // in its parser - so a CSS font stack becomes one family name rather than
    // a fallback list, and the demo avatar's "TM" asks the engine for a family
    // literally called `Helvetica, Arial, sans-serif`. The individual names are
    // registered too, for any asset that names just one.
    for (final String alias in <String>[
      'monospace',
      'Helvetica',
      'Arial',
      'sans-serif',
      'Helvetica, Arial, sans-serif',
    ]) {
      await loadFiles(alias, roboto);
    }
  } else {
    // Not fatal - the committed Inter faces still carry every AppStyle label,
    // and failing here would block the guided tour over a Back-pill glyph.
    // But never silent either: a frame whose Back pill is a white rectangle
    // must say why in the run log rather than leave a reviewer guessing.
    debugPrint(
      '==> render harness: no material_fonts in FLUTTER_ROOT - text that '
      'resolves through a family this engine has not registered (the Back '
      'pill label, the demo avatar initials) will render as blocks',
    );
  }

  // Bundled faces (icon fonts above all) come from the app's own asset
  // bundle. `flutter test` builds the bundle but does not register its fonts
  // with the engine, which is why this loop exists.
  final manifest =
      json.decode(await rootBundle.loadString('FontManifest.json')) as List;
  for (final entry in manifest) {
    final family = (entry as Map<String, dynamic>)['family'] as String?;
    final fonts = entry['fonts'] as List<dynamic>?;
    if (family == null || fonts == null) continue;
    final loader = FontLoader(family);
    for (final font in fonts) {
      final asset = (font as Map<String, dynamic>)['asset'] as String?;
      if (asset == null) continue;
      loader.addFont(rootBundle.load(asset));
    }
    await loader.load();
  }
}

/// Serves google_fonts' own font URLs from the committed faces.
///
/// google_fonts addresses every file as
/// `https://fonts.gstatic.com/s/a/<sha256>.ttf`, so the file name IS the
/// checksum: no hash is hard-coded in this harness, and a google_fonts bump
/// that moves to different faces surfaces as an honest 404 instead of a
/// silently wrong render.
class _OfflineGoogleFontsClient extends http.BaseClient {
  _OfflineGoogleFontsClient(this.fontsDir);

  final Directory fontsDir;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final file = File('${fontsDir.path}/${request.url.pathSegments.last}');
    if (!file.existsSync()) {
      return http.StreamedResponse(
        const Stream<List<int>>.empty(),
        404,
        request: request,
        reasonPhrase:
            'not committed under test/render/fonts - see its README to add it',
      );
    }
    final bytes = file.readAsBytesSync();
    return http.StreamedResponse(
      Stream<List<int>>.value(bytes),
      200,
      contentLength: bytes.length,
      request: request,
    );
  }
}

// ===========================================================================
// Below here is the proven mechanism. Leave it alone.
// ===========================================================================

/// One numbered point: a finder, a stable key, and a human label.
class ElementSpec {
  ElementSpec({required this.key, required this.label, required this.finder})
      : keyOf = null,
        labelOf = null;

  /// A finder that matches SEVERAL widgets (e.g. every settings row); key and
  /// label are derived per match, so the numbering stays per-row.
  ElementSpec.each({
    required this.keyOf,
    required this.labelOf,
    required this.finder,
  })  : key = '',
        label = '';

  final String key;
  final String label;
  final Finder finder;
  final String Function(int index, Widget widget)? keyOf;
  final String Function(int index, Widget widget)? labelOf;
}

class _Measured {
  _Measured(this.key, this.label, this.rect);

  final String key;
  final String label;
  final Rect rect;
}

/// Mocks the path_provider channel so real drift/sqlite stores can open a
/// database in a temp dir. This is the ONLY platform channel the harness
/// fakes - everything else runs its real code path.
void _mockPathProvider(String dir) {
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async => dir);
}

/// The other two channels this harness has to answer for paas_driver. Both
/// answer NULL - nothing is simulated, the absent plugin is simply not allowed
/// to throw an unhandled MissingPluginException that aborts the render:
///
///  * `flutter_secure_storage` - `LocalStorage.setToken` clears the stored
///    refresh contract through it, so the app's REAL session write can run
///    unmodified instead of the harness reimplementing a trimmed version.
///  * `connectivity_plus` - the app subscribes to the connectivity stream on
///    startup. Answering null leaves the app in its genuine headless state
///    (no connectivity events), which is what the frame should show.
void _mockAbsentPlugins() {
  const channels = <String>[
    'plugins.it_nomads.com/flutter_secure_storage',
    'dev.fluttercommunity.plus/connectivity',
    'dev.fluttercommunity.plus/connectivity_status',
  ];
  for (final name in channels) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(MethodChannel(name), (call) async => null);
  }
}

/// Lets REAL async work (drift isolate, futures, file IO) complete, then pumps
/// frames so the resulting setStates land.
///
/// `pumpAndSettle` cannot do this: widget-test fake-async never runs the real
/// event loop, so a screen that waits on a real Future settles as empty.
Future<void> _drain(WidgetTester tester, {int rounds = 8}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 120)),
    );
    await tester.pump(const Duration(milliseconds: 250));
  }
}

List<_Measured> _measure(WidgetTester tester, List<ElementSpec> specs) {
  final measured = <_Measured>[];
  for (final spec in specs) {
    final elements = spec.finder.evaluate().toList();
    for (var i = 0; i < elements.length; i++) {
      try {
        final widget = elements[i].widget;
        measured.add(
          _Measured(
            spec.keyOf?.call(i, widget) ?? spec.key,
            spec.labelOf?.call(i, widget) ?? spec.label,
            tester.getRect(spec.finder.at(i)),
          ),
        );
      } catch (_) {
        // Off-stage or unlaid-out matches are skipped rather than failing the
        // render: a section hidden by a gate is a legitimate outcome.
      }
    }
  }

  // Top-to-bottom, then drop wrappers that share a rect with a more specific
  // match (a decorated card whose child is the row we already measured).
  measured.sort((a, b) => a.rect.top.compareTo(b.rect.top));
  final deduped = <_Measured>[];
  for (final item in measured) {
    final clash = deduped.any(
      (kept) =>
          (kept.rect.top - item.rect.top).abs() < 2 &&
          (kept.rect.height - item.rect.height).abs() < 4,
    );
    if (!clash) deduped.add(item);
  }
  return deduped;
}

/// Renders one variant end to end and writes out/<name>.png + out/<name>.json.
Future<void> renderVariant(
  WidgetTester tester, {
  required bool dark,
  required String name,
  required String dbDir,
}) async {
  final outDir = Directory('${Directory.current.path}/out')
    ..createSync(recursive: true);

  _mockPathProvider(dbDir);
  _mockAbsentPlugins();

  // App-wide state the screen reads before it builds. LocalStorage backs the
  // profile header, the language direction and the stored theme mode; the
  // app's own AppNotifier reads that mode back and calls
  // AppStyle.setBrightness, so both theme systems agree exactly as they do at
  // a real cold start.
  SharedPreferences.setMockInitialValues(<String, Object>{});
  await tester.runAsync(() async {
    await LocalStorage.init();
    await LocalStorage.setAppThemeMode(dark);
  });
  AppStyle.setBrightness(dark ? Brightness.dark : Brightness.light);

  await tester.runAsync(_loadRealFontsOnce);

  // Order matters. Exception stubs go into GetIt FIRST so the SDKs' guarded
  // registrations stand aside; then the SDKs register their own demo
  // implementations; then any device history the demo mode cannot supply.
  registerExceptionStubs();
  await tester.runAsync(registerDemoDependencies);
  await seedDeviceHistory(tester);
  registerScreen();

  tester.view.physicalSize = Size(
    kLogicalWidth * kDevicePixelRatio,
    kProbeHeight * kDevicePixelRatio,
  );
  tester.view.devicePixelRatio = kDevicePixelRatio;
  addTearDown(tester.view.reset);

  final boundaryKey = GlobalKey();
  await tester.pumpWidget(
    RepaintBoundary(
      key: boundaryKey,
      child: buildScreen(dark: dark),
    ),
  );
  await _drain(tester);

  // Pass 1 measures the real content height in the tall probe viewport; pass 2
  // re-renders at exactly that height so the PNG is a full-length strip with
  // no dead space. Two passes are REQUIRED, not an optimisation: screenutil
  // `.h` sizes scale with the viewport, so the height converges to a fixed
  // point rather than being known up front.
  // Before a single rect is taken: prove every finder still means what it
  // meant. A silently over- or under-matching finder is invisible in the
  // PNG, so it has to be caught here or not at all.
  verifyFinders(tester);

  var measured = _measure(tester, elementSpecs());
  expect(
    measured,
    isNotEmpty,
    reason: 'no elements matched - check elementSpecs() and the gates in '
        'registerScreen()',
  );

  final contentBottom =
      measured.map((m) => m.rect.bottom).reduce((a, b) => a > b ? a : b);
  final targetHeight = (contentBottom + kBottomPadding).clamp(
    400.0,
    kProbeHeight,
  );

  tester.view.physicalSize = Size(
    kLogicalWidth * kDevicePixelRatio,
    targetHeight * kDevicePixelRatio,
  );
  await tester.pump(const Duration(milliseconds: 50));
  await _drain(tester, rounds: 4);
  measured = _measure(tester, elementSpecs());

  await tester.runAsync(() async {
    final boundary =
        boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: kDevicePixelRatio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File(
      '${outDir.path}/$name.png',
    ).writeAsBytesSync(bytes!.buffer.asUint8List());

    // Sidecar consumed by scripts/render/compose_strip.py. `number` is a
    // convenience only - the composer re-derives stable global numbers from
    // `key`, so a new element never renumbers the ones already reviewed.
    final sidecar = <String, Object?>{
      'variant': name,
      'logicalWidth': kLogicalWidth,
      'logicalHeight': targetHeight,
      'devicePixelRatio': kDevicePixelRatio,
      'elements': <Object>[
        for (var i = 0; i < measured.length; i++)
          <String, Object?>{
            'number': i + 1,
            'key': measured[i].key,
            'label': measured[i].label,
            'x': measured[i].rect.left,
            'y': measured[i].rect.top,
            'w': measured[i].rect.width,
            'h': measured[i].rect.height,
          },
      ],
    };
    File(
      '${outDir.path}/$name.json',
    ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(sidecar));
  });
}

bool _fontsLoaded = false;
Future<void> _loadRealFontsOnce() async {
  if (_fontsLoaded) return;
  await loadRealFonts();
  _fontsLoaded = true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Fetching stays ON, but `loadRealFonts` swaps google_fonts' http client for
  // one that only ever answers from the faces committed under
  // test/render/fonts. Nothing reaches the network, the render is
  // reproducible offline, and google_fonts still checksums every face it
  // registers. Turning fetching OFF instead would make google_fonts throw
  // before it ever consulted the committed files.
  GoogleFonts.config.allowRuntimeFetching = true;

  final dbDir = Directory.systemTemp.createTempSync('render_harness_db').path;

  // RENDER_SUFFIX distinguishes runs of the SAME harness against different
  // checkouts (e.g. `_draft` for the PR heads, empty for main), so both sets
  // of outputs can sit in one out/ dir and be composed into one page.
  final suffix = Platform.environment['RENDER_SUFFIX'] ?? '';

  // Keep BOTH variants: dark and light are reviewed together, and theme bugs
  // only ever show up in the one nobody rendered.
  testWidgets('render driver profile - dark', (tester) async {
    await renderVariant(
      tester,
      dark: true,
      name: 'driver_profile_dark$suffix',
      dbDir: dbDir,
    );
  });

  testWidgets('render driver profile - light (app default)', (tester) async {
    await renderVariant(
      tester,
      dark: false,
      name: 'driver_profile_light$suffix',
      dbDir: dbDir,
    );
  });
}
