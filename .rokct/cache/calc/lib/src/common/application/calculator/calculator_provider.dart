import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'calculator_notifier.dart';
import 'calculator_state.dart';

final calculatorProvider =
    StateNotifierProvider.autoDispose<CalculatorNotifier, CalculatorState>(
  (ref) => CalculatorNotifier(),
);
