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


import 'dart:async';

import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:base_sdk/src/application/orders_list/orders_list_provider.dart';
import 'package:base_sdk/src/application/shop/shop_provider.dart';
import 'package:base_sdk/src/models/data/order_active_model.dart';
import 'package:base_sdk/src/models/data/shop_data.dart';
import 'package:base_sdk/src/navigation/app_routes.dart';
import 'package:base_sdk/src/presentation/components/shop_avarat.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';

/// One tappable row in a [GlanceCard] — an icon, a line of text, and an
/// optional action. Purely presentational: what the row means (a door
/// countdown, a launcher notification, a task reminder) is entirely up to
/// whichever feature SDK builds the list.
class GlanceCardItem {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  /// Optional avatar (shop logo, tutor portrait, etc.) shown in place of
  /// [icon] for rows that have a real image to show — e.g. an active-order
  /// tracker row. Rows with no avatar fall back to the plain icon, exactly
  /// as before.
  final Widget? avatar;

  /// Row shows a small trailing X when set — for notices that should
  /// persist until the student clears them (a missed session, say) rather
  /// than disappear on their own. Deliberately separate from [onTap] so
  /// tapping the row body and dismissing it are two different actions.
  final VoidCallback? onDismiss;

  /// Optional per-row text style. Absent = the shell's default 13px text,
  /// exactly as before; secondary notice lines (e.g. the active-order
  /// card's weather line) pass a muted style instead.
  final TextStyle? textStyle;

  const GlanceCardItem({
    required this.icon,
    required this.text,
    this.onTap,
    this.avatar,
    this.onDismiss,
    this.textStyle,
  });
}

/// Generic, presentation-only "glance" shell shared by every feature SDK
/// that wants a dismissible-when-quiet summary card at the top of a screen
/// (lms_sdk's session-schedule glance, launch_sdk's home-screen glance,
/// and whatever comes next).
///
/// No business logic lives here (ADR-005: base_sdk is the only cross-SDK-safe
/// dependency) — each consumer decides what counts as "urgent enough to show"
/// and hands this widget the resulting [items]. The shell only owns layout,
/// chrome, and the collapse-to-nothing-when-empty behavior: an empty [items]
/// list renders [SizedBox.shrink], exactly like both prior from-scratch
/// implementations did independently.
class GlanceCard extends StatelessWidget {
  final List<GlanceCardItem> items;

  /// Optional small header label above the item list (the retired core_sdk
  /// widget always showed "Glance"; lms_sdk's version never has one — both
  /// are valid, so this defaults to absent rather than assuming either).
  final String? title;

  final Color? backgroundColor;
  final Color? borderColor;
  final Color? iconColor;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const GlanceCard({
    super.key,
    required this.items,
    this.title,
    this.backgroundColor,
    this.borderColor,
    this.iconColor,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.padding = const EdgeInsets.all(12),
    this.borderRadius = 16,
  });

  /// The row's text style with the current mode's [ink] filled in where the
  /// caller left the colour open. Kept out of [build] so the "caller wins"
  /// rule is stated once.
  static TextStyle _rowStyle(GlanceCardItem item, Color ink) {
    final TextStyle style = item.textStyle ?? const TextStyle(fontSize: 13);
    return style.color == null ? style.copyWith(color: ink) : style;
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    // The shell's own styling lookup, and deliberately a BuildContext one
    // (Ray, 2026-09-19: "glance doesnt change test immediately untill you
    // come back if you switched theme mode").
    //
    // This card used to resolve nothing from the context: its chrome came
    // from AppStyle's statics and its rows' ink was left to whatever
    // ambient DefaultTextStyle a host happened to provide. Neither is a
    // dependency, so a theme-mode change scheduled no rebuild of this
    // element at all - the card kept the previous mode's styling until
    // something else rebuilt it, i.e. until the page was built again from
    // scratch on the way back into the launcher. Reading the inherited
    // theme here is what fixes that: the element now depends on it, so the
    // mode change itself rebuilds this card wherever it is mounted, and the
    // ink is named from AppStyle's ink seam for the mode the theme reports
    // rather than inherited by accident.
    final Color ink = AppStyle.inkFor(Theme.of(context).brightness);

    final accent = iconColor ?? AppStyle.primary;

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppStyle.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? AppStyle.primary.withOpacity(0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: ink,
              ),
            ),
            const SizedBox(height: 8),
          ],
          for (final item in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: item.onTap,
                      child: Row(
                        children: [
                          item.avatar ??
                              Icon(item.icon, size: 18, color: accent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.text,
                              // A per-row style that names its own colour
                              // (the active-order card's muted weather
                              // line) keeps it; one that doesn't, and the
                              // default 13px row, take the mode's ink.
                              style: _rowStyle(item, ink),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (item.onDismiss != null)
                    InkWell(
                      onTap: item.onDismiss,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Icon(Remix.close_line, size: 16, color: accent),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// A [GlanceCard] pre-wired to the current active order (ordersListProvider
/// + shopProvider, both already base_sdk-owned like every other e-commerce
/// domain widget here) — order-tracking apps drop this in as-is instead of
/// building their own order-status row. Same "collapses to nothing when
/// there's nothing to show" behavior as GlanceCard itself, since it's a
/// GlanceCard under the hood; used by both marketplace home layouts.
class ActiveOrderGlanceCard extends ConsumerStatefulWidget {
  const ActiveOrderGlanceCard({super.key});

  @override
  ConsumerState<ActiveOrderGlanceCard> createState() =>
      _ActiveOrderGlanceCardState();
}

class _ActiveOrderGlanceCardState extends ConsumerState<ActiveOrderGlanceCard> {
  Timer? _refreshTimer;
  Timer? _etaTimer;
  final ValueNotifier<OrderActiveModel?> _currentOrderNotifier = ValueNotifier(
    null,
  );
  final ValueNotifier<String> _etaTextNotifier = ValueNotifier('');
  ShopData? _shopData;

  @override
  void initState() {
    super.initState();
    _startPeriodicUpdate();
    _etaTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final order = _currentOrderNotifier.value;
      if (order != null && _shopData != null) {
        _etaTextNotifier.value = _getEtaText(order, _shopData!);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _etaTimer?.cancel();
    _currentOrderNotifier.dispose();
    _etaTextNotifier.dispose();
    super.dispose();
  }

  void _startPeriodicUpdate() {
    _fetchLatestOrderStatus();
    _refreshTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      _fetchLatestOrderStatus();
    });
  }

  Future<void> _fetchLatestOrderStatus() async {
    await ref.read(ordersListProvider.notifier).fetchActiveOrders(context);
    final ordersState = ref.read(ordersListProvider);
    final mostRecentOrder = ordersState.activeOrders.isNotEmpty
        ? ordersState.activeOrders.first
        : null;

    _currentOrderNotifier.value = mostRecentOrder;
    if (mostRecentOrder != null) {
      final shopData = await ref
          .read(shopProvider.notifier)
          .fetchShopData(mostRecentOrder.shop?.id?.toString() ?? '');
      if (!mounted) return;
      setState(() => _shopData = shopData);
      _etaTextNotifier.value = shopData == null
          ? 'N/A'
          : _getEtaText(mostRecentOrder, shopData);
    } else if (_shopData != null) {
      setState(() => _shopData = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    // The same BuildContext lookup the shell above now does, and for the
    // same reason (Ray, 2026-09-19: "glance doesnt change test immediately
    // untill you come back if you switched theme mode"). #242 fixed the
    // shell, but this card's weather line names a colour of ITS own — which
    // the shell deliberately leaves alone — and named it from AppStyle's
    // app-wide isDark static. That is not a dependency, and the line is
    // built inside two ValueListenableBuilders, which only rebuild when
    // their notifier fires: a mode change reached neither, so the notice
    // kept the previous mode's secondary ink until an order or ETA tick
    // happened to rebuild it. Read here, OUTSIDE the builders, so this
    // element depends on the inherited theme and the mode change itself
    // rebuilds the card wherever it is mounted.
    final Brightness brightness = Theme.of(context).brightness;

    return ValueListenableBuilder<OrderActiveModel?>(
      valueListenable: _currentOrderNotifier,
      builder: (context, currentOrder, child) {
        final shopData = _shopData;
        if (currentOrder == null || shopData == null) {
          return const SizedBox.shrink();
        }

        final accent = _statusColor(currentOrder.status);
        final statusLabel = (currentOrder.status ?? '').isNotEmpty
            ? currentOrder.status![0].toUpperCase() +
                currentOrder.status!.substring(1)
            : '';

        // Optional severe-weather line: the backend's server-authored calm
        // one-liner riding along on the order payload (weather_notice.text).
        // Absent or malformed = no line at all — the card renders exactly
        // as it always has.
        final weatherText = currentOrder.weatherNoticeText;

        return ValueListenableBuilder<String>(
          valueListenable: _etaTextNotifier,
          builder: (context, etaText, _) {
            return GlanceCard(
              backgroundColor: accent.withOpacity(0.12),
              borderColor: accent.withOpacity(0.35),
              iconColor: accent,
              items: [
                GlanceCardItem(
                  icon: Remix.truck_line,
                  text:
                      'Order №${(currentOrder.id ?? '').toString()} is $statusLabel — ETA $etaText',
                  avatar: ShopAvatar(
                    radius: 20,
                    shopImage: shopData.logoImg ?? '',
                    size: 36,
                    padding: 0,
                    bgColor: AppStyle.transparent,
                  ),
                  onTap: () => AppRoutes.I.pushOrderProgressRoute(
                    context,
                    orderId: (currentOrder.id ?? ''),
                  ),
                ),
                if (weatherText != null && weatherText.isNotEmpty)
                  // One muted notice line (the lms_sdk schedule-glance
                  // style: small secondary text) under the order row.
                  GlanceCardItem(
                    icon: Remix.cloud_line,
                    text: weatherText,
                    textStyle: TextStyle(
                      fontSize: 12,
                      color: AppStyle.secondaryInkFor(brightness),
                    ),
                    onTap: () => AppRoutes.I.pushOrderProgressRoute(
                      context,
                      orderId: (currentOrder.id ?? ''),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'accepted':
        return Colors.blue;
      case 'processing':
      case 'cooking':
        return Colors.orange;
      case 'ready':
        return Colors.green;
      case 'on_a_way':
      case 'shipped':
        return Colors.deepPurple;
      case 'delivered':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getEtaText(OrderActiveModel order, ShopData shopData) {
    final createdAt = order.createdAt;
    final deliveryTime = shopData.deliveryTime;

    if (createdAt == null) {
      return 'N/A';
    }

    if (deliveryTime == null ||
        deliveryTime.to == null ||
        deliveryTime.type == null) {
      return 'N/A';
    }

    final int deliveryMinutes =
        _convertToMinutes(deliveryTime.to, deliveryTime.type);
    final now = DateTime.now();
    final int elapsedMinutes = now.difference(createdAt).inMinutes;

    if (elapsedMinutes > deliveryMinutes) {
      return 'Delayed';
    }
    return _formatDuration(deliveryMinutes - elapsedMinutes);
  }

  int _convertToMinutes(String? to, String? type) {
    if (to == null || type == null) {
      return 0;
    }

    double value = double.tryParse(to) ?? 0;
    switch (type.toLowerCase()) {
      case 'min':
      case 'minute':
        return value.round();
      case 'hour':
        return (value * 60).round();
      case 'day':
        return (value * 24 * 60).round();
      default:
        return value.round();
    }
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '$hours${remainingMinutes > 0 ? ':${remainingMinutes.toString().padLeft(2, '0')}' : ''}';
  }
}
