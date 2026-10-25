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

import 'package:flutter/widgets.dart';

/// Registry of the widgets a guide can point at. Wrap a target in a
/// [GuideAnchor] with the same id a [GuideStep] names in its `anchor`.
///
/// One anchor id must be mounted at most once at a time: a GlobalKey cannot
/// be attached to two elements.
class GuideAnchors {
  GuideAnchors._();

  static final Map<String, GlobalKey> _keys = {};

  static GlobalKey keyFor(String id) => _keys.putIfAbsent(id, GlobalKey.new);

  /// True when the anchor is mounted and laid out right now.
  static bool isOnScreen(String id) {
    final box = _keys[id]?.currentContext?.findRenderObject();
    return box is RenderBox && box.attached && box.hasSize;
  }

  /// The anchor's rectangle in the coordinate space of [ancestor], or null
  /// when it is not on screen.
  static Rect? rectIn(String id, RenderBox ancestor) {
    final box = _keys[id]?.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    final topLeft = box.localToGlobal(Offset.zero, ancestor: ancestor);
    return topLeft & box.size;
  }
}

/// Marks a widget as the target of a guide step. Renders [child] unchanged.
class GuideAnchor extends StatelessWidget {
  final String id;
  final Widget child;

  const GuideAnchor({super.key, required this.id, required this.child});

  @override
  Widget build(BuildContext context) =>
      KeyedSubtree(key: GuideAnchors.keyFor(id), child: child);
}
