// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.


// The top-snackbar helpers are decoration: handed a context with no Overlay
// ancestor they must do nothing, not throw. `Overlay.of` asserts in that case,
// and an asserting toast takes its caller down with it — which is how a single
// unreachable overlay killed a whole guided-tour run at its sign-in step.

import 'package:base_sdk/base_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';

void main() {
  group('top snackbar helpers without an Overlay ancestor', () {
    late BuildContext overlayless;

    Future<void> pumpOverlayless(WidgetTester tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            overlayless = context;
            return const SizedBox.shrink();
          },
        ),
      );
    }

    testWidgets('showCheckTopSnackBar is a no-op', (tester) async {
      await pumpOverlayless(tester);
      AppHelpers.showCheckTopSnackBar(overlayless, 'boom');
      await tester.pump();
    });

    testWidgets('showCheckTopSnackBarInfo is a no-op', (tester) async {
      await pumpOverlayless(tester);
      AppHelpers.showCheckTopSnackBarInfo(overlayless, 'boom');
      await tester.pump();
    });

    testWidgets('showCheckTopSnackBarDone is a no-op', (tester) async {
      await pumpOverlayless(tester);
      AppHelpers.showCheckTopSnackBarDone(overlayless, 'boom');
      await tester.pump();
    });

    testWidgets('showCheckTopSnackBarInfoCustom is a no-op', (tester) async {
      await pumpOverlayless(tester);
      AppHelpers.showCheckTopSnackBarInfoCustom(overlayless, 'boom');
      await tester.pump();
    });

    testWidgets('errorSnackBar alias is a no-op', (tester) async {
      await pumpOverlayless(tester);
      AppHelpers.errorSnackBar(overlayless, text: 'boom');
      await tester.pump();
    });
  });

  testWidgets('a toast still shows when an Overlay IS in scope', (
    tester,
  ) async {
    late BuildContext withOverlay;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            withOverlay = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    AppHelpers.showCheckTopSnackBarDone(withOverlay, 'saved');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(CustomSnackBar), findsOneWidget);

    await tester.pumpAndSettle();
  });
}
