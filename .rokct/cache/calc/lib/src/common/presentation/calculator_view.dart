import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/calculator/calculator_provider.dart';
import '../domain/number.dart';
import '../domain/operator.dart';

/// Full-screen calculator UI, ported from paas_manager lib/calc/main.dart
/// (CalculatorPage) with its logic moved into [CalculatorNotifier].
///
/// Lives in lib (not only in the installed template) so a composition can
/// also embed it directly; the installed /calc route page is a thin
/// wrapper around this widget.
class CalculatorView extends ConsumerWidget {
  const CalculatorView({super.key});

  static const _backgroundColor = Color(0xFF22252D);
  static const _keyColor = Color(0xFF2A2D37);
  static const _accentColor = Color(0xFFFF5A66);
  static const _functionColor = Color(0xFF26F4CE);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(calculatorProvider);

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) > 0) {
            Navigator.of(context).maybePop();
          }
        },
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    Positioned(
                      top: 10,
                      left: 10,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.6,
                        child: ListView.builder(
                          shrinkWrap: true,
                          reverse: true,
                          itemCount: state.history.length,
                          itemBuilder: (context, index) {
                            final result = state
                                .history[state.history.length - 1 - index];
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 2.0),
                              child: Text(
                                '${result.firstNum} ${result.operator?.symbol} ${result.secondNum} = ${result.result}',
                                style: TextStyle(
                                    color: Colors.grey[500], fontSize: 14),
                                textAlign: TextAlign.right,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          state.display,
                          style: const TextStyle(
                              fontSize: 48, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      _buildButtonRow(ref, const ['MC', 'MR', 'M-', 'M+']),
                      _buildButtonRow(ref, const ['C', '±', '%', '÷']),
                      _buildButtonRow(ref, const ['7', '8', '9', '×']),
                      _buildButtonRow(ref, const ['4', '5', '6', '-']),
                      _buildButtonRow(ref, const ['1', '2', '3', '+']),
                      _buildButtonRow(ref, const ['0', '.', '=']),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButtonRow(WidgetRef ref, List<String> buttons) {
    return Expanded(
      child: Row(
        children: buttons.map((button) => _buildButton(ref, button)).toList(),
      ),
    );
  }

  void _onPressed(WidgetRef ref, String text) {
    final notifier = ref.read(calculatorProvider.notifier);
    if (const ['÷', '×', '-', '+'].contains(text)) {
      notifier.onOperatorPressed(CalculatorOperator(text));
    } else if (text == '=' || text == 'C') {
      notifier.onResultPressed(text);
    } else if (const ['MC', 'MR', 'M-', 'M+'].contains(text)) {
      notifier.onMemoryPressed(text);
    } else if (text == '±') {
      notifier.onNumberPressed(SymbolNumber());
    } else if (text == '.') {
      notifier.onNumberPressed(DecimalNumber());
    } else if (text == '%') {
      notifier.onPercentPressed();
    } else {
      notifier.onNumberPressed(NormalNumber(text));
    }
  }

  Widget _buildButton(WidgetRef ref, String text) {
    final Color buttonColor;
    final Color textColor;
    if (const ['MC', 'MR', 'M-', 'M+'].contains(text)) {
      buttonColor = _keyColor;
      textColor = _accentColor;
    } else if (const ['C', '±', '%'].contains(text)) {
      buttonColor = _keyColor;
      textColor = _functionColor;
    } else if (const ['÷', '×', '-', '+', '='].contains(text)) {
      buttonColor = _accentColor;
      textColor = Colors.white;
    } else {
      buttonColor = _keyColor;
      textColor = Colors.white;
    }

    final buttonContent = Text(
      text,
      style: TextStyle(fontSize: 20, color: textColor),
    );

    if (text == 'C') {
      return Expanded(
        flex: 1,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: GestureDetector(
            onDoubleTap: () =>
                ref.read(calculatorProvider.notifier).clearHistory(),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(24),
              ),
              onPressed: () => _onPressed(ref, text),
              child: buttonContent,
            ),
          ),
        ),
      );
    }

    return Expanded(
      flex: text == '0' ? 2 : 1,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            shape: text == '0' ? const StadiumBorder() : const CircleBorder(),
            padding: const EdgeInsets.all(24),
          ),
          onPressed: () => _onPressed(ref, text),
          child: buttonContent,
        ),
      ),
    );
  }
}
