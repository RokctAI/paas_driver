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

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:remixicon/remixicon.dart';
// The manager zone slice lives in zones_sdk's own src/manager/ role folder
// (ported from paas_manager's application/restaurant/delivery_zone/ in the
// 2026-08 refork). Deep import rather than the zones_sdk.dart barrel: the
// barrel is common-only because the composer strips the other role's
// lib/src/<role>/ folder from every host's cache, and this page only exists
// in manager hosts, where src/manager/ survives.
import 'package:zones_sdk/src/manager/application/delivery_zone/delivery_zone_provider.dart';
import 'package:zones_sdk/src/manager/application/delivery_zone/delivery_zone_notifier.dart';
import 'package:zones_sdk/src/manager/application/delivery_zone/delivery_zone_state.dart';
import 'package:zones_sdk/src/common/services/zone_geometry.dart';

import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/adaptive/breakpoints.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/presentation/components/blur_wrap.dart';
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/components/floating_nav/floating_bottom_nav.dart';
import 'package:base_sdk/src/constants/app_constants.dart';

// The manager delivery-zone editor, rebuilt to the approved section-39
// frames (39a tablet saved-zone editor, 39b tablet drawing state, 39c phone
// fold; chips 735-742):
//
//  * /delivery-zone keeps its ALL claim (735): the map is full-bleed across
//    the whole stage in every window — no seams, no neighbors — exactly the
//    19b/20b/37c map ruling. Whatever pushed this page pops off stage.
//  * The one polygon keeps the shipped notifier styling (736) when closed;
//    while the shape is open the page draws the tapped edges solid and the
//    CLOSING edge dashed (741) over a faint fill.
//  * Every vertex wears a draggable handle (737) — a white dot in a primary
//    ring — and the panel offers Undo last point (742), both riding the
//    notifier's pointsHistory stack.
//  * At plane widths the zone details panel (739) floats at the top-START
//    corner in the floating-affordance grammar: name, Saved/Drawing state,
//    point count, the client-side derived coverage figure (km², computed by
//    zone_geometry — no backend call) and the tap-to-add line (738). On the
//    phone it collapses to the slim status pill.
//  * Save (740) sits behind the shipped `length > 3` gate: bottom-centre at
//    plane widths, START-anchored on the phone; while the gate is unmet the
//    slot holds the N-more-points hint instead.
//  * Back is the corner pill (canonical 347) at the bottom-END corner —
//    the shipped PopButton re-homed per the two-state rule.
@RoutePage(name: 'ManagerDeliveryZoneRoute')
class ManagerDeliveryZonePage extends ConsumerStatefulWidget {
  const ManagerDeliveryZonePage({super.key});

  @override
  ConsumerState<ManagerDeliveryZonePage> createState() =>
      _DeliveryZonePageState();
}

class _DeliveryZonePageState extends ConsumerState<ManagerDeliveryZonePage> {
  /// The vertex handle bitmap (chip 737): a white dot in a primary ring,
  /// drawn once off-screen. Handles simply don't render for the frame or
  /// two before it resolves.
  BitmapDescriptor? _vertexHandle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(deliveryZoneProvider.notifier).fetchDeliveryZone();
      _buildVertexHandle();
    });
  }

  Future<void> _buildVertexHandle() async {
    // Drawn at 3x the 24-logical-pixel display size so the dot stays crisp
    // on dense screens; BitmapDescriptor.bytes scales it back down.
    const double sizePx = 72;
    const Offset center = Offset(sizePx / 2, sizePx / 2);
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(
      recorder,
      const Rect.fromLTWH(0, 0, sizePx, sizePx),
    );
    canvas.drawCircle(center, sizePx / 2, Paint()..color = AppStyle.primary);
    canvas.drawCircle(
      center,
      sizePx / 2 - 14,
      Paint()..color = AppStyle.white,
    );
    final ui.Image image = await recorder
        .endRecording()
        .toImage(sizePx.toInt(), sizePx.toInt());
    final ByteData? bytes = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    if (!mounted || bytes == null) return;
    setState(() {
      _vertexHandle = BitmapDescriptor.bytes(
        bytes.buffer.asUint8List(),
        width: 24,
      );
    });
  }

  /// One draggable handle per vertex (chip 737). Dragging a dot moves that
  /// vertex through the notifier, which snapshots the previous ring so the
  /// move is undoable.
  Set<Marker> _handles(DeliveryZoneState state, DeliveryZoneNotifier event) {
    final BitmapDescriptor? icon = _vertexHandle;
    if (icon == null) return const <Marker>{};
    return <Marker>{
      for (int i = 0; i < state.tappedPoints.length; i++)
        Marker(
          markerId: MarkerId('vertex-$i'),
          position: state.tappedPoints[i],
          icon: icon,
          anchor: const Offset(0.5, 0.5),
          draggable: true,
          onDragEnd: (position) => event.moveTappedPoint(i, position),
        ),
    };
  }

  /// The drawing-in-progress overlay (chip 741): tapped edges solid, the
  /// closing edge — the one the next tap will replace — dashed. Only while
  /// the shape is open; a closed shape is the polygon's own solid stroke.
  Set<Polyline> _drawingEdges(DeliveryZoneState state) {
    final List<LatLng> points = state.tappedPoints;
    if (state.isShapeClosed || points.length < 2) return const <Polyline>{};
    return <Polyline>{
      Polyline(
        polylineId: const PolylineId('tapped-edges'),
        points: points,
        color: AppStyle.primary,
        width: 4,
      ),
      if (points.length > 2)
        Polyline(
          polylineId: const PolylineId('closing-edge'),
          points: [points.last, points.first],
          color: AppStyle.primary,
          width: 4,
          patterns: [PatternItem.dash(18.r), PatternItem.gap(12.r)],
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.textGrey,
      resizeToAvoidBottomInset: false,
      body: Consumer(
        builder: (context, ref, child) {
          final state = ref.watch(deliveryZoneProvider);
          final event = ref.read(deliveryZoneProvider.notifier);
          // The tablet/phone fold (39a vs 39c) rides the shared window
          // classification, not a device check.
          final bool wide = windowSizeOf(context).isAtLeastMedium;
          return Stack(
            children: [
              state.isLoading
                  ? Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: AppStyle.white,
                    )
                  : GoogleMap(
                      tiltGesturesEnabled: false,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      polygons: state.polygon,
                      polylines: _drawingEdges(state),
                      markers: _handles(state, event),
                      onTap: event.addTappedPoint,
                      initialCameraPosition: CameraPosition(
                        bearing: 0,
                        target: LatLng(
                          state.polygon.isNotEmpty
                              ? state.polygon.first.points.first.latitude
                              : AppHelpers.getInitialLatitude() ??
                                    AppConstants.demoLatitude,
                          state.polygon.isNotEmpty
                              ? state.polygon.first.points.first.longitude
                              : AppHelpers.getInitialLongitude() ??
                                    AppConstants.demoLongitude,
                        ),
                        tilt: 0,
                        zoom: 11,
                      ),
                    ),
              // The zone details overlay (739): panel at the top-START
              // corner at plane widths, slim status pill on the phone.
              // Overlays only — they never take planes.
              if (!state.isLoading)
                if (wide)
                  _ZonePanel(state: state, event: event)
                else
                  _ZoneStatusPill(state: state, event: event),
              // The bottom slot: Save behind the shipped gate (740), the
              // one-more-point hint while the gate is unmet (741), and the
              // corner Back pill (347) at the bottom-END.
              if (!state.isLoading)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 150),
                  bottom: 16.r,
                  left: 16.r,
                  right: 16.r,
                  child: SafeArea(
                    child: wide
                        ? _wideBottomSlot(context, state, event)
                        : _phoneBottomRow(context, state, event),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Plane widths (39a/39b): Save delivery zone bottom-centre when the
  /// shipped gate is met, else the N-more-points hint chip; the corner
  /// Back pill anchors the END corner either way.
  Widget _wideBottomSlot(
    BuildContext context,
    DeliveryZoneState state,
    DeliveryZoneNotifier event,
  ) {
    return Row(
      children: [
        // Mirror spacer so the centre slot stays truly centred despite the
        // END-corner back pill.
        const Expanded(child: SizedBox.shrink()),
        state.isShapeClosed
            ? SizedBox(
                width: 420.w,
                child: CustomButton(
                  title: AppHelpers.getTranslation('save.delivery.zone'),
                  isLoading: state.isSaving,
                  onPressed: () => event.updateDeliveryZone(
                    updateSuccess: context.router.maybePop,
                  ),
                ),
              )
            : _MorePointsHint(count: state.tappedPoints.length),
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: _backPill(),
          ),
        ),
      ],
    );
  }

  /// The phone fold (39c): Save anchors START, Back is the corner pill at
  /// the END — the shipped pop|Save overlay row in the two-state language
  /// with the sides swapped (the 37d precedent). The shipped gate still
  /// governs Save's existence; while it is unmet the START slot carries
  /// the hint instead.
  Widget _phoneBottomRow(
    BuildContext context,
    DeliveryZoneState state,
    DeliveryZoneNotifier event,
  ) {
    return Row(
      children: [
        Expanded(
          child: state.isShapeClosed
              ? CustomButton(
                  title: AppHelpers.getTranslation(TrKeys.save),
                  isLoading: state.isSaving,
                  onPressed: () => event.updateDeliveryZone(
                    updateSuccess: context.router.maybePop,
                  ),
                )
              : Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: _MorePointsHint(count: state.tappedPoints.length),
                ),
        ),
        8.horizontalSpace,
        _backPill(),
      ],
    );
  }

  /// The corner Back pill (canonical 347) — the plane layout's back
  /// control, placed by this page at the bottom-END corner.
  Widget _backPill() {
    return FloatingBackPill(
      back: FloatingNavBack(
        icon: Remix.arrow_left_wide_fill,
        label: AppHelpers.getTranslation(TrKeys.back),
      ),
    );
  }
}

/// Shared translucent dark housing for the zone overlays — near-solid so
/// the panel reads as a raised object over the map tiles in either theme.
class _OverlaySurface extends StatelessWidget {
  final Widget child;
  final double radius;

  const _OverlaySurface({required this.child, required this.radius});

  @override
  Widget build(BuildContext context) {
    return BlurWrap(
      radius: BorderRadius.circular(radius),
      child: Container(
        decoration: BoxDecoration(
          color: AppStyle.bottomNavigationBarColor.withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: child,
      ),
    );
  }
}

/// The Saved/Drawing state pill on the panel and the phone status pill.
class _StatePill extends StatelessWidget {
  final bool saved;

  const _StatePill({required this.saved});

  @override
  Widget build(BuildContext context) {
    final Color tone = saved ? AppStyle.green : AppStyle.primary;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.r, vertical: 4.r),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(100.r),
      ),
      child: Text(
        AppHelpers.getTranslation(saved ? TrKeys.saved : 'drawing'),
        style: AppStyle.interSemi(size: 13, color: tone),
      ),
    );
  }
}

/// The zone details panel (chip 739) — plane widths only: name + state
/// pill, the one-shape line, point count, the derived coverage figure or
/// the shape-not-closed line, the tap-to-add hint (738), and Undo last
/// point (742) while there is an edit to undo.
class _ZonePanel extends StatelessWidget {
  final DeliveryZoneState state;
  final DeliveryZoneNotifier event;

  const _ZonePanel({required this.state, required this.event});

  @override
  Widget build(BuildContext context) {
    final bool saved = !state.isDirty && state.tappedPoints.isNotEmpty;
    final int count = state.tappedPoints.length;
    return PositionedDirectional(
      top: 16.r,
      start: 16.r,
      child: SafeArea(
        child: _OverlaySurface(
          radius: 20.r,
          child: Container(
            width: 340.w,
            padding: EdgeInsets.all(18.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppHelpers.getTranslation(TrKeys.deliveryZone),
                        style: AppStyle.interBold(
                          size: 20,
                          color: AppStyle.white,
                        ),
                      ),
                    ),
                    _StatePill(saved: saved),
                  ],
                ),
                6.verticalSpace,
                Text(
                  AppHelpers.getTranslation('where.this.shop.delivers'),
                  style: AppStyle.interRegular(
                    size: 14,
                    color: AppStyle.textGrey,
                  ),
                ),
                14.verticalSpace,
                _detailRow(
                  icon: Remix.map_pin_line,
                  text: saved
                      ? '$count ${AppHelpers.getTranslation('points')}'
                      : '$count ${AppHelpers.getTranslation('points.placed')}',
                ),
                10.verticalSpace,
                _detailRow(
                  icon: Remix.shape_2_line,
                  text: state.isShapeClosed
                      // Derived client-side from the ring — the state
                      // carries only points, no backend area field.
                      ? '≈ ${zoneAreaSquareKm(state.tappedPoints).toStringAsFixed(1)} '
                          '${AppHelpers.getTranslation('km2')} '
                          '${AppHelpers.getTranslation('covered')}'
                      : AppHelpers.getTranslation('shape.not.closed.yet'),
                ),
                14.verticalSpace,
                Divider(
                  height: 1,
                  color: AppStyle.white.withValues(alpha: 0.12),
                ),
                14.verticalSpace,
                _detailRow(
                  icon: Remix.add_circle_line,
                  text: AppHelpers.getTranslation(
                    state.isShapeClosed
                        ? 'tap.the.map.to.add.a.point.new.points.extend.the.shape'
                        : 'tap.the.map.to.add.a.point.save.unlocks.at.4',
                  ),
                  muted: true,
                ),
                if (state.canUndo) ...[
                  14.verticalSpace,
                  _UndoButton(onUndo: event.undoLastPoint),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String text,
    bool muted = false,
  }) {
    final Color tone = muted ? AppStyle.textGrey : AppStyle.white;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18.r, color: tone),
        10.horizontalSpace,
        Expanded(
          child: Text(
            text,
            style: muted
                ? AppStyle.interRegular(size: 14, color: tone)
                : AppStyle.interSemi(size: 15, color: tone),
          ),
        ),
      ],
    );
  }
}

/// Undo last point (chip 742) — the one correction affordance short of
/// leaving the page.
class _UndoButton extends StatelessWidget {
  final VoidCallback onUndo;

  const _UndoButton({required this.onUndo});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppStyle.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onUndo,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 12.r),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppStyle.white.withValues(alpha: 0.22),
            ),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Remix.arrow_go_back_line,
                size: 18.r,
                color: AppStyle.white,
              ),
              8.horizontalSpace,
              Text(
                AppHelpers.getTranslation('undo.last.point'),
                style: AppStyle.interSemi(size: 15, color: AppStyle.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The phone fold's slim status pill (739's collapse): name, point count,
/// Saved/Drawing — plus a compact undo action while an edit is undoable,
/// so the phone keeps the correction affordance without the panel.
class _ZoneStatusPill extends StatelessWidget {
  final DeliveryZoneState state;
  final DeliveryZoneNotifier event;

  const _ZoneStatusPill({required this.state, required this.event});

  @override
  Widget build(BuildContext context) {
    final bool saved = !state.isDirty && state.tappedPoints.isNotEmpty;
    final int count = state.tappedPoints.length;
    return Positioned(
      top: 12.r,
      left: 16.r,
      right: 16.r,
      child: SafeArea(
        child: _OverlaySurface(
          radius: 100.r,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.r, vertical: 10.r),
            child: Row(
              children: [
                Icon(
                  Remix.map_pin_line,
                  size: 18.r,
                  color: AppStyle.white,
                ),
                10.horizontalSpace,
                Expanded(
                  child: Text(
                    '${AppHelpers.getTranslation(TrKeys.deliveryZone)} · '
                    '$count ${AppHelpers.getTranslation('points')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyle.interSemi(
                      size: 15,
                      color: AppStyle.white,
                    ),
                  ),
                ),
                if (state.canUndo) ...[
                  8.horizontalSpace,
                  Semantics(
                    button: true,
                    label: AppHelpers.getTranslation('undo.last.point'),
                    child: GestureDetector(
                      onTap: event.undoLastPoint,
                      child: Icon(
                        Remix.arrow_go_back_line,
                        size: 18.r,
                        color: AppStyle.white,
                      ),
                    ),
                  ),
                ],
                8.horizontalSpace,
                _StatePill(saved: saved),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The gate-unmet hint (chip 741's bottom line): how many points the shape
/// still needs before the shipped `length > 3` gate unlocks Save. Nothing
/// renders before the first tap — the panel/pill already carries the
/// tap-to-add line.
class _MorePointsHint extends StatelessWidget {
  final int count;

  const _MorePointsHint({required this.count});

  @override
  Widget build(BuildContext context) {
    if (count < 1 || count > 3) return const SizedBox.shrink();
    final String key = switch (4 - count) {
      1 => '1.more.point.to.close.the.shape',
      2 => '2.more.points.to.close.the.shape',
      _ => '3.more.points.to.close.the.shape',
    };
    return _OverlaySurface(
      radius: 100.r,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.r, vertical: 12.r),
        child: Text(
          AppHelpers.getTranslation(key),
          style: AppStyle.interSemi(size: 15, color: AppStyle.white),
        ),
      ),
    );
  }
}
