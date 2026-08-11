import 'operator.dart';

/// A single in-progress or completed calculation.
///
/// Ported unchanged from paas_manager lib/calc/result.dart. Kept mutable on
/// purpose: the notifier uses one instance as its working scratchpad and
/// snapshots it into history via [CalculationResult.from].
class CalculationResult {
  String? firstNum;
  String? secondNum;
  CalculatorOperator? operator;
  num? result;
  bool complete = false;

  CalculationResult();

  CalculationResult.from(CalculationResult other) {
    firstNum = other.firstNum;
    secondNum = other.secondNum;
    operator = other.operator;
    result = other.result;
    complete = other.complete;
  }
}
