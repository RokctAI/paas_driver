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

// LoadQuietGate: no error toast before the person has done anything.
//
// Ray: being offline or logged out must never be shown as an error, and
// minilauncher 1.2.16 still showed "Something went wrong with the server" on
// the splash / login screen when he opened it, or came back to it, signed
// out. These tests pin the gate the composed app arms in
// BaseSdkDependencies.register: an error toast raised before any touch is
// dropped (its telemetry still goes out), a toast raised by a tap still
// shows, and a return to the app after a long absence counts as a fresh
// start.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';

import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/error_presenter.dart';
import 'package:base_sdk/src/services/load_silence.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/telemetry.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<Map<String, dynamic>> telemetry = <Map<String, dynamic>>[];

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await LocalStorage.init();
  });

  setUp(() {
    telemetry.clear();
    TelemetryClient.configure(transport: (cmd, payload) async {
      telemetry.add(<String, dynamic>{'cmd': cmd, ...payload});
    });
  });

  tearDown(() {
    LoadQuietGate.resetForTesting();
    TelemetryClient.configure(transport: null);
  });

  String serverLine() =>
      AppHelpers.getTranslation(TrKeys.somethingWentWrongWithTheServer);

  /// A screen with an Overlay (for the top toast), a Scaffold (for the
  /// no-connection snackbar) and a button that raises the same server error
  /// the way a sign-in failure would.
  Future<BuildContext> pumpScreen(WidgetTester tester) async {
    late BuildContext screen;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              screen = context;
              return Center(
                child: ElevatedButton(
                  onPressed: () => ErrorPresenter.showTechnical(
                    context,
                    type: 'auth_login_failed',
                    detail: 'Internal Server Error',
                    statusCode: 500,
                  ),
                  child: const Text('Sign in'),
                ),
              );
            },
          ),
        ),
      ),
    );
    return screen;
  }

  /// Lets the tap's own toast run its course, so what follows is judged on
  /// an empty screen.
  Future<void> clearToasts(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.byType(CustomSnackBar), findsNothing);
  }

  Future<void> settleToast(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('armed, before the person has done anything', () {
    testWidgets('a server error from load-time work shows nothing', (
      tester,
    ) async {
      final screen = await pumpScreen(tester);
      LoadQuietGate.arm();

      ErrorPresenter.showTechnical(
        screen,
        type: 'auth_languages_load_failed',
        detail: 'Internal Server Error',
        statusCode: 500,
      );
      await settleToast(tester);

      expect(find.byType(CustomSnackBar), findsNothing);
      expect(find.text(serverLine()), findsNothing);
      // The cause still reaches telemetry; only the screen stays quiet.
      await tester.pump();
      expect(
        telemetry.where((e) => e['cmd'] == TelemetryClient.cmd),
        isNotEmpty,
      );
      await tester.pumpAndSettle();
    });

    testWidgets('a raw error toast shows nothing', (tester) async {
      final screen = await pumpScreen(tester);
      LoadQuietGate.arm();

      AppHelpers.showCheckTopSnackBar(screen, serverLine());
      await settleToast(tester);

      expect(find.byType(CustomSnackBar), findsNothing);
      await tester.pumpAndSettle();
    });

    testWidgets('offline shows no "No internet connection" snackbar', (
      tester,
    ) async {
      final screen = await pumpScreen(tester);
      LoadQuietGate.arm();

      AppHelpers.showNoConnectionSnackBar(screen);
      await settleToast(tester);

      expect(find.text('No internet connection'), findsNothing);
      await tester.pumpAndSettle();
    });
  });

  testWidgets('a tap still shows the error it caused', (tester) async {
    await pumpScreen(tester);
    LoadQuietGate.arm();
    expect(LoadQuietGate.quiet, isTrue);

    await tester.tap(find.text('Sign in'));
    await settleToast(tester);

    expect(LoadQuietGate.quiet, isFalse);
    expect(find.byType(CustomSnackBar), findsOneWidget);
    expect(find.text(serverLine()), findsOneWidget);
    await tester.pumpAndSettle();
  });

  group('coming back to the app', () {
    testWidgets('after a long absence it is a fresh start again', (
      tester,
    ) async {
      final screen = await pumpScreen(tester);
      DateTime clock = DateTime(2026, 10, 8, 12);
      LoadQuietGate.arm();
      LoadQuietGate.now = () => clock;

      await tester.tap(find.text('Sign in'));
      await clearToasts(tester);
      expect(LoadQuietGate.quiet, isFalse);

      clock = clock.add(LoadQuietGate.staleAfter + const Duration(seconds: 1));
      LoadQuietGate.onResume();
      expect(LoadQuietGate.quiet, isTrue);

      AppHelpers.showCheckTopSnackBar(screen, serverLine());
      await settleToast(tester);
      expect(find.byType(CustomSnackBar), findsNothing);
      await tester.pumpAndSettle();
    });

    testWidgets('a short trip (system sign-in UI) keeps the last tap', (
      tester,
    ) async {
      final screen = await pumpScreen(tester);
      DateTime clock = DateTime(2026, 10, 8, 12);
      LoadQuietGate.arm();
      LoadQuietGate.now = () => clock;

      await tester.tap(find.text('Sign in'));
      await clearToasts(tester);

      clock = clock.add(const Duration(seconds: 20));
      LoadQuietGate.onResume();
      expect(LoadQuietGate.quiet, isFalse);

      AppHelpers.showCheckTopSnackBar(screen, serverLine());
      await settleToast(tester);
      expect(find.byType(CustomSnackBar), findsOneWidget);
      await tester.pumpAndSettle();
    });
  });

  testWidgets('unarmed (tests, hand-wired hosts) nothing changes', (
    tester,
  ) async {
    final screen = await pumpScreen(tester);
    expect(LoadQuietGate.quiet, isFalse);

    AppHelpers.showCheckTopSnackBar(screen, serverLine());
    await settleToast(tester);

    expect(find.byType(CustomSnackBar), findsOneWidget);
    await tester.pumpAndSettle();
  });
}
