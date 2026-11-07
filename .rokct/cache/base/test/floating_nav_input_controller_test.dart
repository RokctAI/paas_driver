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


// FloatingNavInput.controller: a chat that keeps an unsent draft per
// conversation passes its own controller, so the words outlive the bar.

import 'package:base_sdk/base_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(FloatingNavInput input) => ProviderScope(
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, _) => MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: FloatingBottomNav(mode: FloatingNavControlsMode(actions: const [], input: input)),
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('a passed controller shows its draft and is cleared on send', (tester) async {
    final draft = TextEditingController(text: 'half a thought');
    final sent = <String>[];
    await tester.pumpWidget(_host(FloatingNavInput(placeholder: 'Message', controller: draft, onSubmit: sent.add)));
    expect(find.text('half a thought'), findsOneWidget);
    // The draft is already there, so send shows without typing.
    await tester.tap(find.byTooltip('Message'));
    await tester.pump();
    expect(sent, ['half a thought']);
    expect(draft.text, isEmpty);
    // The bar never disposes the caller's controller.
    await tester.pumpWidget(const SizedBox());
    draft.text = 'still usable';
    expect(draft.text, 'still usable');
    draft.dispose();
  });

  testWidgets('without a controller the bar keeps its own', (tester) async {
    final sent = <String>[];
    await tester.pumpWidget(_host(FloatingNavInput(placeholder: 'Message', onSubmit: sent.add)));
    await tester.enterText(find.byType(TextField), 'hello');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();
    expect(sent, ['hello']);
  });
}
