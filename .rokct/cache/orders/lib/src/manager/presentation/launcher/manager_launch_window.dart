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

// FRAMES 53f and 53l of design strip section 53 (approved, Ray
// 2026-09-01) - the manager window on the launcher canvas: the orders
// waiting on the manager, and the takings figure deliberately absent.
//
// What this widget IS: the content of the launcher's manager window. The
// launcher owns the placement and the chrome (design frame 53g); this
// file owns only what sits inside. It reaches the launcher through the
// manifest (integrations under launch_sdk's `// @launcher-windows`
// marker), never through an import: orders_sdk's lib/ imports only
// base_sdk (ADR-005).
//
// The three things a later edit could quietly undo:
//
//   * NO TAKINGS. Ray ruled earnings and balance off the canvas on 53e
//     (driver mode); sales figures are money by exactly the reasoning he
//     gave - the launcher is the home screen with no auth in front of it
//     - so today's takings are omitted here too. That is the frame's
//     stated extension of his ruling (53f, chip 1289), and it is one
//     word to reverse; until then [ManagerLaunchQueue] carries no amount
//     and nothing here formats a currency.
//   * THE COUNT IS THE ACTION. "Waiting on you" and the number of orders
//     to accept are what a manager acts on; the money is inside the app.
//   * A DATALESS STATE THAT STILL WORKS. Ray: "data dont show on
//     launcher when another mode is active". [ManagerLaunchWindow.dataless]
//     renders the action and no count, so the window is "useful and
//     tappable without data" (53g) by construction.

import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/enums.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:orders_sdk/src/manager/domain/interface/seller_orders.dart';
import 'package:orders_sdk/src/manager/infrastructure/repositories/demo_seller_orders_repository.dart';

/// Translation wire keys owned by this window. Referenced by string, not
/// through composer-injected `TrKeys` constants, because lib/ analyzes and
/// tests against raw base_sdk where those constants do not exist
/// (`seller_form_helpers` precedent); `AppHelpers.getTranslation` humanizes
/// them until the translation store carries rows. Declared in manifest.json
/// `tr_keys` so the composed app seeds them.
abstract final class ManagerLaunchWindowKeys {
  static const String ordersToAccept = 'orders_to_accept';
  static const String waitingOnYou = 'waiting_on_you';
  static const String openOrders = 'open_orders';
}

/// What the window shows: how many orders are waiting to be accepted.
/// No amount, by design - see the file header.
class ManagerLaunchQueue {
  const ManagerLaunchQueue({required this.waiting});

  /// Orders in the `new` column - the ones the manager has not yet
  /// accepted.
  final int waiting;
}

/// Reads the queue through the same facade the manager order board reads
/// - the `SellerOrdersRepositoryFacade` the manager DI hook registers,
/// which in demo builds is the seeded `DemoSellerOrdersRepository`. A
/// composition that never registered the facade (the launcher composes no
/// manager DI) gets the demo repository when the build is a demo build and
/// nothing otherwise; a failing call is a null queue, never an exception -
/// the launcher canvas must not crash because a backend is away.
abstract final class ManagerLaunchWindowLoader {
  static Future<ManagerLaunchQueue?> load({
    SellerOrdersRepositoryFacade? repository,
  }) async {
    final SellerOrdersRepositoryFacade? repo = repository ?? _resolve();
    if (repo == null) return null;
    try {
      return switch (await repo.getOrders(status: OrderStatus.open, page: 1)) {
        Success(:final data) => ManagerLaunchQueue(
            // The statistic block is the board's own counter; a bare list
            // (today's gateway envelope) counts the page instead.
            waiting: data.data?.statistic?.newOrdersCount ??
                data.data?.orders?.length ??
                0,
          ),
        Failure() => null,
      };
    } catch (_) {
      return null;
    }
  }

  static SellerOrdersRepositoryFacade? _resolve() {
    final GetIt getIt = GetIt.instance;
    if (getIt.isRegistered<SellerOrdersRepositoryFacade>()) {
      return getIt.get<SellerOrdersRepositoryFacade>();
    }
    return AppConstants.isDemo ? DemoSellerOrdersRepository() : null;
  }
}

/// The manager window's content (frames 53f, 53l).
///
/// With data: "Orders to accept", the "Waiting on you" count, and an Open
/// orders action that opens the app. Dataless
/// ([ManagerLaunchWindow.dataless]): the action alone. Never a takings
/// figure in either.
///
/// Dark first, through AppStyle's tokens (the same card/ink/stroke roles
/// the order board uses), so the window follows the launcher's theme.
class ManagerLaunchWindow extends StatefulWidget {
  /// The window with data. [queue] short-circuits the loader (tests, a
  /// host that already holds the count); otherwise [load] runs once on
  /// mount and defaults to [ManagerLaunchWindowLoader.load].
  const ManagerLaunchWindow({
    super.key,
    required this.onOpen,
    this.queue,
    this.load,
  }) : showData = true;

  /// The window without data, for a mode that is not the active one.
  const ManagerLaunchWindow.dataless({super.key, required this.onOpen})
      : showData = false,
        queue = null,
        load = null;

  /// Opens the manager app - the launcher's own way of starting it.
  final VoidCallback onOpen;

  final bool showData;
  final ManagerLaunchQueue? queue;
  final Future<ManagerLaunchQueue?> Function()? load;

  static const Key openKey = ValueKey<String>('manager-launch-window-open');
  static const Key countKey = ValueKey<String>('manager-launch-window-count');

  @override
  State<ManagerLaunchWindow> createState() => _ManagerLaunchWindowState();
}

class _ManagerLaunchWindowState extends State<ManagerLaunchWindow> {
  ManagerLaunchQueue? _queue;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (!widget.showData) return;
    if (widget.queue != null) {
      _queue = widget.queue;
      _loaded = true;
      return;
    }
    (widget.load ?? ManagerLaunchWindowLoader.load)().then((queue) {
      if (!mounted) return;
      setState(() {
        _queue = queue;
        _loaded = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final String openOrders =
        AppHelpers.getTranslation(ManagerLaunchWindowKeys.openOrders);
    if (!widget.showData) {
      return Align(
        alignment: Alignment.centerLeft,
        child: _Pill(
          key: ManagerLaunchWindow.openKey,
          label: openOrders,
          onTap: widget.onOpen,
        ),
      );
    }
    if (!_loaded) return const SizedBox.shrink();
    final ManagerLaunchQueue? queue = _queue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          AppHelpers.getTranslation(ManagerLaunchWindowKeys.ordersToAccept),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppStyle.interSemi(size: 14, color: AppStyle.textPrimary),
        ),
        // The count is the only figure on the window. When the read
        // failed there is no number to show and the row is simply not
        // drawn: the app is the truth, one tap away.
        if (queue != null) ...<Widget>[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: Text(
                  AppHelpers.getTranslation(
                    ManagerLaunchWindowKeys.waitingOnYou,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyle.interNormal(
                    size: 12,
                    color: AppStyle.textDarkSecondary,
                  ),
                ),
              ),
              Text(
                '${queue.waiting}',
                key: ManagerLaunchWindow.countKey,
                style: AppStyle.interSemi(
                  size: 28,
                  color: AppStyle.textPrimary,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 10),
        _Pill(
          key: ManagerLaunchWindow.openKey,
          label: openOrders,
          onTap: widget.onOpen,
        ),
      ],
    );
  }
}

/// The single action, in the brand colour so it is the one thing on the
/// window that asks for a tap.
class _Pill extends StatelessWidget {
  const _Pill({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppStyle.primary,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            label,
            style: AppStyle.interSemi(size: 13, color: AppStyle.blackColor),
          ),
        ),
      ),
    );
  }
}
