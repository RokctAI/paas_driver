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


import 'package:flutter/material.dart';
import 'package:base_sdk/src/presentation/theme/theme.dart';

class ButtonEffectAnimation extends StatefulWidget {
  final bool disabled;
  final Widget child;
  final VoidCallback? onTap;

  const ButtonEffectAnimation({
    super.key,
    this.disabled = true,
    required this.child,
    this.onTap,
  });

  @override
  State createState() => _ButtonEffectAnimationState();
}

class _ButtonEffectAnimationState extends State<ButtonEffectAnimation>
    with TickerProviderStateMixin {
  AnimationController? _controllerA;

  var squareScaleA = 0.95;

  @override
  void initState() {
    _controllerA = AnimationController(
      vsync: this,
      lowerBound: 0.95,
      upperBound: 1.0,
      duration: const Duration(milliseconds: 80),
    );
    _controllerA!.addListener(() {
      setState(() {
        squareScaleA = _controllerA!.value;
      });
    });

    _controllerA!.forward(from: 0.0);
    super.initState();
  }

  @override
  void dispose() {
    _controllerA!.dispose();
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
              if (!widget.disabled) {}
            },
            child: Transform.scale(
              scale: squareScaleA,
              child: GestureDetector(
                onTap: widget.onTap,
                child: Container(
                  color: AppStyle.transparent,
                  child: widget.child,
                ),
              ),
            ),
          )
        : GestureDetector(onTap: widget.onTap, child: widget.child);
  }
}
