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

// The driver's Profile settings form RENDERING as the profile's DETAIL
// PANE, pinned after the guided tour died on it (paas_driver run
// 34219676531, both tablet legs; the phone sheet was fine):
//
//   No Material widget found.
//   IconButton widgets require a Material widget ancestor ...
//   IconButton  lib/presentation/pages/profile/widgets/edit_profile_modal.dart:156
//   A RenderFlex overflowed by 99702 pixels on the right.
//   Row  lib/presentation/pages/profile/widgets/edit_profile_modal.dart:124
//   constraints: BoxConstraints(0.0<=w<=314.2, 0.0<=h<=Infinity)
//   size: Size(314.2, 100000.0)
//
// The frame: base's routed profile host (`GenericProfileRoutePage`) puts
// a detail in a `PlaneHost` plane - Row → Expanded → Planes → Builder -
// straight under the MaterialApp. No Scaffold, no sheet, no Material at
// all between the app and the detail's first widget. The sheet the phone
// opens sits on the bottom-sheet route's Material (and on
// `DriverSheetSurface`), which is why the same form was fine there.
// Embedded, every IconButton and TextFormField in the form threw the
// first error; Flutter replaces a widget that failed to build with an
// `ErrorWidget`, whose render box asks for 100000 x 100000, and the
// avatar Stack in the header row hands it an UNBOUNDED width (a Row's
// non-flex child) - the second error is the first one's box.
//
// The template itself cannot be pumped from this package: its import
// chain carries the composer's `${package}` placeholder (the same reason
// the driver home and order card tests read theirs). So the widget tests
// below pump the header row the template draws - the real `ShopAvatar`
// and `UnderlinedBorderTextField` templates, which carry no placeholder -
// inside the real `PlaneHost`, at both tour widths, and pin the
// mechanism: bare, the row throws exactly those two errors; under the
// shell the template installs (a transparent Material and the avatar
// Stack bounded to its own square) it renders clean. The source tests pin
// that the template carries that shell, and that the sheet path is the
// one it always was.

import 'dart:io';

import 'package:base_sdk/src/presentation/adaptive/planes.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remixicon/remixicon.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../templates/components/driver/shop_avarat.dart';
import '../templates/components/driver/text_fields/underline_bordered_text_field.dart';

const String _template =
    'templates/pages/driver/profile/widgets/edit_profile_modal.dart';

const _headerKey = ValueKey('profile-settings-header-row');
const _avatarKey = ValueKey('profile-settings-avatar');

/// The seam PlaneHost puts between planes (its default gap).
const double _gap = 14;

/// The template's horizontal padding around the header (16.w, 1:1 here).
const double _inset = 16;

/// The header row the template draws under its title: the avatar Stack -
/// `ShopAvatar`, the dark overlay square, the camera `IconButton` -
/// beside the Expanded first-name field. [boundedAvatar] is the fix: the
/// Stack sized to the avatar's own 50.r square, so no child of it can
/// size the row. [camera] stands in for the IconButton where a test
/// needs the box a failed build leaves behind without failing a build.
Widget _headerRow({required bool boundedAvatar, Widget? camera}) {
  final Widget avatar = Stack(
    alignment: Alignment.center,
    children: [
      ShopAvatar(
        radius: 16,
        size: 50,
        padding: 6,
        bgColor: AppStyle.black.withValues(alpha: 0.27),
      ),
      Container(
        width: 50.r,
        height: 50.r,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          color: AppStyle.black.withValues(alpha: 0.27),
        ),
      ),
      camera ??
          IconButton(
            icon: Icon(Remix.camera_fill, color: AppStyle.white, size: 20.r),
            onPressed: () {},
          ),
    ],
  );
  return Row(
    key: _headerKey,
    children: [
      KeyedSubtree(
        key: _avatarKey,
        child: boundedAvatar
            ? SizedBox.square(dimension: 50.r, child: avatar)
            : avatar,
      ),
      16.horizontalSpace,
      Expanded(
        child: UnderlinedBorderTextField(
          label: AppHelpers.getTranslation(TrKeys.firstname),
          initialText: '',
        ),
      ),
    ],
  );
}

/// The form's list as the template lays it out: a shrink-wrapped ListView
/// whose first item is the padded column the header row sits in.
Widget _form(Widget header) => ListView(
  physics: const BouncingScrollPhysics(),
  padding: EdgeInsets.zero,
  shrinkWrap: true,
  children: [
    Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(children: [header]),
    ),
  ],
);

/// The embedded shell as 1.21.5 returned it: the form top-aligned under
/// the plane's safe area, nothing else.
Widget _bareShell(Widget body) => Align(
  alignment: Alignment.topCenter,
  child: SafeArea(
    child: Padding(
      padding: EdgeInsets.only(top: 16.h),
      child: body,
    ),
  ),
);

/// The embedded shell the fix installs: the same, on a transparent
/// Material so the plane's surface still shows through.
Widget _materialShell(Widget body) =>
    Material(type: MaterialType.transparency, child: _bareShell(body));

/// The host's theme (core `templates/app_widget.dart`): Material 2. It
/// matters here - an M3 IconButton builds without a Material, the M2 one
/// the composed app draws asserts it, exactly as the tour saw.
ThemeData _hostTheme() =>
    ThemeData(useMaterial3: false, brightness: Brightness.light);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await LocalStorage.init();
  });

  /// Pumps what [detail] builds where base's routed profile host puts an
  /// opened detail: the LAST plane of a `PlaneHost` under the MaterialApp, the
  /// profile spanning two planes before it, ScreenUtil 1:1 on the window
  /// (as on any non-compact window). Every error Flutter reports while
  /// the frame builds and lays out is collected and returned, so a tree
  /// that throws several times (each field, then the overflow) can be
  /// examined in full instead of failing the test on the first.
  Future<List<FlutterErrorDetails>> pumpInDetailPlane(
    WidgetTester tester, {
    required double width,
    required WidgetBuilder detail,
  }) async {
    final size = Size(width, 1280);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final errors = <FlutterErrorDetails>[];
    final prior = FlutterError.onError;
    FlutterError.onError = errors.add;
    try {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: size,
          builder: (context, _) => MaterialApp(
            theme: _hostTheme(),
            home: PlaneHost(
              stack: [
                const PlanePage(
                  name: 'profile',
                  span: PlaneSpan.two,
                  builder: _stage,
                ),
                PlanePage(name: 'detail', builder: detail),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
    } finally {
      FlutterError.onError = prior;
    }
    return errors;
  }

  /// The width the header row gets in the detail plane: the plane less
  /// the template's insets.
  double headerWidth(double screen, int planes) =>
      (screen - (planes - 1) * _gap) / planes - 2 * _inset;

  bool noMaterial(FlutterErrorDetails e) =>
      e.exception.toString().contains('No Material widget found');
  bool overflow(FlutterErrorDetails e) =>
      e.exception.toString().contains('A RenderFlex overflowed by');

  group('the bare form in the detail plane (1.21.5)', () {
    for (final (screen, planes) in const [(1066.0, 3), (800.0, 2)]) {
      testWidgets('$screen dp, $planes planes: no Material, and the error box '
          'overflows the header row', (tester) async {
        final errors = await pumpInDetailPlane(
          tester,
          width: screen,
          detail: (_) => _bareShell(_form(_headerRow(boundedAvatar: false))),
        );
        // The tour's constraint on the row: 314.2 at 1066 dp, 361 at
        // 800 dp.
        expect(
          tester.getSize(find.byKey(_headerKey)).width,
          moreOrLessEquals(headerWidth(screen, planes), epsilon: 0.5),
        );
        expect(errors.where(noMaterial), isNotEmpty);
        expect(errors.where(overflow), hasLength(1));
        // The 100000-wide error box is the avatar's IconButton, and it
        // is what sized the row.
        expect(
          find.descendant(
            of: find.byKey(_avatarKey),
            matching: find.byType(ErrorWidget),
          ),
          findsOneWidget,
        );
        expect(tester.getSize(find.byKey(_headerKey)).height, 100000);
      });
    }
  });

  group('the shell the fix installs', () {
    for (final (screen, planes) in const [(1066.0, 3), (800.0, 2)]) {
      testWidgets('$screen dp, $planes planes: the header renders clean, the '
          'avatar its own square', (tester) async {
        final errors = await pumpInDetailPlane(
          tester,
          width: screen,
          detail: (_) => _materialShell(_form(_headerRow(boundedAvatar: true))),
        );
        expect(errors, isEmpty);
        expect(tester.takeException(), isNull);
        expect(find.byType(ErrorWidget), findsNothing);
        expect(find.byIcon(Remix.camera_fill), findsOneWidget);
        expect(find.byType(TextFormField), findsOneWidget);
        expect(
          tester.getSize(find.byKey(_headerKey)).width,
          moreOrLessEquals(headerWidth(screen, planes), epsilon: 0.5),
        );
        expect(tester.getSize(find.byKey(_avatarKey)), const Size(50, 50));
      });
    }

    for (final bounded in const [false, true]) {
      testWidgets(
        bounded
            ? 'bounded, the avatar square holds even the 100000-wide box a '
                  'failed build leaves behind'
            : 'the Material alone is not enough: unbounded, the avatar hands '
                  'that box to the row',
        (tester) async {
          // The second half of the fix, against exactly the box Flutter
          // put in the Stack on the tablet: an ErrorWidget in the
          // camera's place, under the Material so nothing else fails.
          final errors = await pumpInDetailPlane(
            tester,
            width: 800,
            detail: (_) => _materialShell(
              _form(
                _headerRow(
                  boundedAvatar: bounded,
                  camera: ErrorWidget.withDetails(),
                ),
              ),
            ),
          );
          expect(errors.where(noMaterial), isEmpty);
          expect(errors.where(overflow), hasLength(bounded ? 0 : 1));
          expect(
            tester.getSize(find.byKey(_avatarKey)),
            bounded ? const Size(50, 50) : isNot(const Size(50, 50)),
          );
        },
      );
    }
  });

  testWidgets('the sheet frame: the same row under a Material at phone '
      'width was never the problem', (tester) async {
    // What showCustomModalBottomSheet's route gives the sheet: a Material
    // (the BottomSheet's) above the form. The 1.21.5 header renders clean
    // there - the frame, not the form, was the difference.
    const size = Size(390, 844);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: size,
        builder: (context, _) => MaterialApp(
          theme: _hostTheme(),
          home: Material(
            child: Builder(
              builder: (_) => _form(_headerRow(boundedAvatar: false)),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(ErrorWidget), findsNothing);
    expect(find.byIcon(Remix.camera_fill), findsOneWidget);
  });

  group('the template', () {
    // Code only: the template's own comments describe the shell.
    final src = File(_template)
        .readAsLinesSync()
        .where((line) => !line.trimLeft().startsWith('//'))
        .join('\n');
    final embedded = src.indexOf('if (widget.embedded) {');
    final sheet = src.indexOf('return DriverSheetSurface(child: body);');

    test('has an embedded branch before the sheet return', () {
      expect(embedded, isNot(-1));
      expect(sheet, greaterThan(embedded));
    });

    test('the embedded branch returns the form on a transparent Material', () {
      final branch = src.substring(embedded, sheet);
      expect(
        branch,
        contains('Material(\n        type: MaterialType.transparency,'),
        reason:
            'the detail plane is a bare box: the IconButtons and '
            'TextFormFields in the form need a Material above them, and '
            'a transparent one keeps the plane\'s surface',
      );
    });

    test('the sheet path keeps its own surface, no Material of its own', () {
      // The bottom-sheet route already provides one; the sheet is what
      // it always was.
      expect(src.substring(sheet), startsWith('return DriverSheetSurface'));
      expect('MaterialType.transparency'.allMatches(src), hasLength(1));
      expect(src.indexOf('MaterialType.transparency'), lessThan(sheet));
    });

    test('the header avatar Stack is bounded to its own square', () {
      expect(
        src,
        matches(
          RegExp(
            r'SizedBox\.square\(\s*dimension:\s*50\.r,\s*child:\s*Stack\(',
          ),
        ),
        reason:
            'a Row hands a non-flex child unbounded width; sized to the '
            'avatar square, nothing inside the Stack can size the row',
      );
    });
  });
}

Widget _stage(BuildContext context) => const SizedBox.expand();
