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
