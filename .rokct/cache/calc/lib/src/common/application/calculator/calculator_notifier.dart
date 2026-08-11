import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/number.dart';
import '../../domain/operator.dart';
import '../../domain/result.dart';
import 'calculator_state.dart';

/// Calculator engine, unified from paas_manager's two parallel lib/calc
/// implementations: the feature set (history, memory keys, chained
/// operators) comes from lib/calc/main.dart's CalculatorPageState, the
/// StateNotifier shape from lib/calc/provider/calculator_provider.dart.
class CalculatorNotifier extends StateNotifier<CalculatorState> {
  CalculatorNotifier() : super(const CalculatorState());

  /// Working scratchpad for the in-progress calculation (same pattern as the
  /// original page state); snapshots of it are pushed into [state.history].
  CalculationResult _current = CalculationResult();

  void onNumberPressed(Number number) {
    if (_current.operator == null) {
      _current.firstNum = number.apply(_current.firstNum ?? '0');
    } else {
      _current.secondNum = number.apply(_current.secondNum ?? '0');
    }
    _pickCurrentDisplay();
  }

  void onOperatorPressed(CalculatorOperator operator) {
    if (_current.firstNum != null) {
      if (_current.operator != null && _current.secondNum != null) {
        onResultPressed('=');
      }
      _current.operator = operator;
    }
    _pickCurrentDisplay();
  }

  /// Handles '=' and 'C'.
  void onResultPressed(String display) {
    if (display == '=') {
      if (_current.operator != null &&
          _current.firstNum != null &&
          _current.secondNum != null) {
        _current.result = _current.operator!.calculate(
          double.parse(_current.firstNum!),
          double.parse(_current.secondNum!),
        );
        _current.complete = true;
        _addToHistory(CalculationResult.from(_current));
        final chained = _format(_current.result!);
        _current = CalculationResult();
        _current.firstNum = chained;
      }
    } else if (display == 'C') {
      _current = CalculationResult();
    }
    _pickCurrentDisplay();
  }

  /// Applies '%': divides the operand being typed by 100.
  void onPercentPressed() {
    final current = double.tryParse(state.display);
    if (current == null) return;
    final asText = _format(current / 100);
    if (_current.operator == null) {
      _current.firstNum = asText;
    } else {
      _current.secondNum = asText;
    }
    _pickCurrentDisplay();
  }

  void onMemoryPressed(String operation) {
    final currentValue = double.tryParse(state.display) ?? 0;
    switch (operation) {
      case 'M+':
        state = state.copyWith(memoryValue: state.memoryValue + currentValue);
        break;
      case 'M-':
        state = state.copyWith(memoryValue: state.memoryValue - currentValue);
        break;
      case 'MR':
        final recalled = _format(state.memoryValue);
        if (_current.operator == null) {
          _current.firstNum = recalled;
        } else {
          _current.secondNum = recalled;
        }
        state = state.copyWith(display: recalled);
        break;
      case 'MC':
        state = state.copyWith(memoryValue: 0);
        break;
    }
  }

  void clearHistory() {
    state = state.copyWith(history: const []);
  }

  void _addToHistory(CalculationResult result) {
    final next = [...state.history, result];
    if (next.length > 10) {
      next.removeAt(0);
    }
    state = state.copyWith(history: next);
  }

  void _pickCurrentDisplay() {
    final String display;
    if (_current.result != null) {
      display = _format(_current.result!);
    } else if (_current.secondNum != null) {
      display = _current.secondNum!;
    } else if (_current.firstNum != null) {
      display = _current.firstNum!;
    } else {
      display = '0';
    }
    state = state.copyWith(display: display);
  }

  String _format(num number) {
    if (number == number.toInt()) {
      return number.toInt().toString();
    }
    return number.toString();
  }
}
