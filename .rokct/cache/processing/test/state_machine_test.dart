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

import 'package:flutter_test/flutter_test.dart';
import 'package:processing_sdk/processing_sdk.dart';

void main() {
  group('ProcessingStateMachine', () {
    test('allows documented transitions', () {
      expect(
        ProcessingStateMachine.canTransition(
          ProcessingState.draft,
          ProcessingState.submitted,
        ),
        isTrue,
      );
      expect(
        ProcessingStateMachine.canTransition(
          ProcessingState.submitted,
          ProcessingState.accepted,
        ),
        isTrue,
      );
    });

    test('rejects undeclared transitions', () {
      expect(
        ProcessingStateMachine.canTransition(
          ProcessingState.draft,
          ProcessingState.completed,
        ),
        isFalse,
      );
      expect(
        ProcessingStateMachine.canTransition(
          ProcessingState.completed,
          ProcessingState.draft,
        ),
        isFalse,
      );
    });

    test('terminal states have no exits', () {
      expect(ProcessingStateMachine.isTerminal(ProcessingState.completed),
          isTrue);
      expect(ProcessingStateMachine.isTerminal(ProcessingState.cancelled),
          isTrue);
      expect(
          ProcessingStateMachine.isTerminal(ProcessingState.failed), isFalse);
    });
  });
}
