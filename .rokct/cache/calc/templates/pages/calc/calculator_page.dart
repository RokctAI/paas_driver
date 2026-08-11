import 'package:auto_route/auto_route.dart';
import 'package:calc_sdk/calc_sdk.dart';
import 'package:flutter/material.dart';

@RoutePage()
class CalculatorPage extends StatelessWidget {
  const CalculatorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CalculatorView();
  }
}
