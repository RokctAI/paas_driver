import 'package:flutter/material.dart';

/// Press-scale feedback wrapper for the add-order FAB, ported from
/// paas_manager `lib/presentation/component/buttons/buttons_bouncing_effect.dart`.
/// base_sdk has no equivalent component; if one lands there later, delete
/// this copy and repoint the import in main_page.dart.
class ButtonsBouncingEffect extends StatefulWidget {
  final bool disabled;
  final Widget child;

  const ButtonsBouncingEffect({
    super.key,
    required this.child,
    this.disabled = true,
  });

  @override
  State createState() => _ButtonsBouncingEffectState();
}

class _ButtonsBouncingEffectState extends State<ButtonsBouncingEffect>
    with TickerProviderStateMixin {
  AnimationController? _controllerA;
  double squareScaleA = 0.95;

  @override
  void initState() {
    _controllerA = AnimationController(
      vsync: this,
      lowerBound: 0.95,
      upperBound: 1.0,
      duration: const Duration(milliseconds: 80),
    );
    _controllerA?.addListener(
      () {
        setState(() {
          squareScaleA = _controllerA!.value;
        });
      },
    );
    _controllerA?.forward(from: 0.0);
    super.initState();
  }

  @override
  void dispose() {
    _controllerA?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.disabled
        ? Listener(
            onPointerDown: (_) {
              _controllerA!.reverse();
            },
            onPointerUp: (_) {
              _controllerA!.forward(from: 1.0);
            },
            child: Transform.scale(
              scale: squareScaleA,
              child: widget.child,
            ),
          )
        : widget.child;
  }
}
