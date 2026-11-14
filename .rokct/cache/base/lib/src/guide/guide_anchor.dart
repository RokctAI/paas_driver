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

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../services/demo_session.dart';

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
///
/// Two cases attach no GlobalKey, because a second mount of the same id would
/// otherwise throw "Duplicate GlobalKey detected in widget tree":
///
///  * [DemoSession.demoActive]: guides are off there, so nothing ever looks an
///    anchor up. The guided tour replaces `/login` with `/login`, and for the
///    length of that transition the old and new LoginPage (each with its
///    `auth.login.button` anchor) are both mounted.
///  * another [GuideAnchor] with the same [id] is already mounted (a route
///    replaced by itself, a page pushed over its own copy): the first one
///    keeps the key and the later one renders its child unkeyed. When the
///    owner is disposed, the next mounted anchor of that id is rebuilt after
///    the frame and takes the key over, so a guide can still find it.
///
/// Flipping [DemoSession.demoActive] while an anchor is mounted swaps the
/// keyed subtree for the bare child on its next build, which remounts the
/// child's state. Demo sessions start and end at sign-in and sign-out, where
/// the page is replaced anyway.
class GuideAnchor extends StatefulWidget {
  final String id;
  final Widget child;

  const GuideAnchor({super.key, required this.id, required this.child});

  @override
  State<GuideAnchor> createState() => _GuideAnchorState();
}

class _GuideAnchorState extends State<GuideAnchor> {
  /// The mounted anchor that currently holds each id's GlobalKey.
  static final Map<String, _GuideAnchorState> _owners = {};

  /// Every mounted anchor per id, in mount order, so a released key can be
  /// handed to the next one.
  static final Map<String, List<_GuideAnchorState>> _mounted = {};

  bool _owns(String id) {
    final owner = _owners[id];
    if (owner == null || owner == this || !owner.mounted) {
      _owners[id] = this;
      return true;
    }
    return false;
  }

  void _register(String id) => (_mounted[id] ??= []).add(this);

  void _release(String id) {
    final list = _mounted[id];
    list?.remove(this);
    if (list != null && list.isEmpty) _mounted.remove(id);
    if (_owners[id] != this) return;
    _owners.remove(id);
    // The tree is locked while elements unmount, so the next anchor is
    // rebuilt after this frame rather than now.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_owners.containsKey(id)) return;
      for (final next in _mounted[id] ?? const <_GuideAnchorState>[]) {
        if (next.mounted) {
          next.setState(() {});
          break;
        }
      }
    });
    SchedulerBinding.instance.scheduleFrame();
  }

  @override
  void initState() {
    super.initState();
    _register(widget.id);
  }

  @override
  void didUpdateWidget(GuideAnchor old) {
    super.didUpdateWidget(old);
    if (old.id != widget.id) {
      _release(old.id);
      _register(widget.id);
    }
  }

  @override
  void dispose() {
    _release(widget.id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (DemoSession.demoActive || !_owns(widget.id)) return widget.child;
    return KeyedSubtree(
        key: GuideAnchors.keyFor(widget.id), child: widget.child);
  }
}
