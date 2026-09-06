// Copyright (C) 2024-2026 ROKCT INTELLIGENCE (PTY) LTD
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
import 'package:base_sdk/src/presentation/components/app_bars/custom_app_bar.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:comms_sdk/src/common/di/comms_di.dart';
import 'package:delivery_sdk/src/common/di/delivery_di.dart';
import 'package:delivery_sdk/src/driver/di/driver_delivery_di.dart';
import 'package:map_sdk/src/common/di/map_sdk_di.dart';
import 'package:merchants_sdk/src/common/di/merchants_di.dart';
import 'package:orders_sdk/src/common/di/orders_di.dart';
import 'package:products_sdk/src/common/di/products_di.dart';
import 'package:revenue_sdk/src/driver/di/driver_revenue_di.dart';
import 'package:users_sdk/src/common/di/users_di.dart';
import 'package:zones_sdk/src/common/di/zones_di.dart';

import 'package:driver/presentation/component/driver_avatar.dart';
import 'package:driver/presentation/pages/profile/courier_statistics_provider.dart';
import 'package:driver/presentation/pages/profile/profile_page.dart';
import 'package:driver/presentation/pages/profile/widgets/sections_item.dart';

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
/// The profile has no section registry to populate and no role gate to
/// resolve — the register is a fixed list in delivery_sdk's template, and the
/// one gate on it (`if (!AppConstants.isDemo)`, which hides "Delete account")
/// resolves from the same dart-define the data does.
void registerScreen() {}

/// TODO(harness) 6/8 - the widget under test.
///
/// The real [ProfilePage], wrapped the way `lib/presentation/app_widget.dart`
/// wraps every screen: a ProviderScope, ScreenUtilInit at the app's 375x812
/// compact design size, and a MaterialApp carrying the app's own light and
/// dark ThemeData. No overrides — the providers resolve against the demo DI
/// registered above.
Widget buildScreen({required bool dark}) {
  return ProviderScope(
    child: ScreenUtilInit(
      useInheritedMediaQuery: false,
      designSize: const Size(375, 812),
      builder: (context, child) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: false,
          brightness: Brightness.light,
          scaffoldBackgroundColor: AppStyle.surfaceLightRaw,
        ),
        darkTheme: ThemeData(
          useMaterial3: false,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppStyle.surfaceDarkRaw,
        ),
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        home: const _CourierJourney(child: ProfilePage()),
      ),
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
/// of the page. The section rows are keyed by their own `title`, so adding a
/// row appends a number instead of renumbering the ones already discussed.
List<ElementSpec> elementSpecs() {
  return <ElementSpec>[
    ElementSpec(
      key: 'delivery.driver.profile.app_bar',
      label: 'Identity header - avatar, name, phone, sign-out',
      finder: find.byType(CustomAppBar),
    ),
    ElementSpec(
      key: 'delivery.driver.profile.avatar',
      label: 'Courier avatar - photo and rating badge',
      finder: find.byType(DriverAvatar),
    ),
    ElementSpec(
      key: 'delivery.driver.profile.balance_card',
      label: 'Balance card - wallet balance and last profit',
      finder: find.byType(IntrinsicHeight),
    ),
    ElementSpec.each(
      keyOf: (i, w) =>
          'delivery.driver.profile.section_row.${(w as SectionsItem).title}',
      labelOf: (i, w) => 'Section row - ${(w as SectionsItem).title}',
      finder: find.byType(SectionsItem),
    ),
    // NOT numbered: the Scaffold's floatingActionButton (the back pill +
    // "Online helper" call button) is VIEWPORT-anchored, not content-anchored,
    // so its measured bottom is always the bottom of the probe viewport. The
    // mechanism's height fixed-point takes the maximum measured bottom, so
    // including it would pin every frame to kProbeHeight. It is still in the
    // picture; it just cannot carry a chip.
  ];
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
