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

// DESIGN STRIP SECTION 49 — the driver's home sheet.
//
// Frames 49a (on duty, nothing assigned), 49d (off duty), 49e (the 360
// fold) and 49m (the wallet-floor gate) are all states of THIS ONE
// composition, which is why they land in one file.
//
// WHAT CAME OUT, AND WHY.
//   * three hard-coded stock photographs on a 186.h horizontal ListView
//     — deliveryhero.com, ctfassets.net and unsplash URLs baked into the
//     source. They showed the driver nothing about his own work.
//   * the "Juvo benefit" promo tile.
//   * a Balance tile reading a CACHED `LocalStorage.getUser()?.wallet?
//     .price` whose tap handler had been commented out.
//
// WHAT WENT IN, AND WHERE IT COMES FROM. Everything drawn here was
// already on the wire; nothing new is invented client-side:
//   * chip 931, the day strip — `get_deliveryman_order_report` with
//     today on both bounds. Home never called this endpoint; adopting it
//     is a client change, not a new endpoint.
//   * chip 932, cash on hand — `cash_on_hand` / `cash_order_count`,
//     summed server-side from the COD the driver recorded at the door.
//   * chips 933/934, the queue — `getAvailableOrders`, implemented and
//     simply unconsumed by this screen.
//   * chips 945/970, the off-duty state — `CourierStorage.getOnline()`,
//     which already gates the background location task and the routing
//     poll, plus the wallet position from `get_deliveryman_work_status`.
//   * chips 990/991, the gate — the SAME `get_deliveryman_work_status`,
//     which resolves the SAME allowance the shipped
//     `assert_deliveryman_can_take_work` guard uses. The screen cannot
//     disagree with the guard.
//
// TWO THINGS THE FRAMES FLAGGED AS UNSOURCED, AND WHAT BECAME OF THEM:
//   * frame 49d's "SHIFT ENDED 17:04" — nothing on the server records
//     when duty was toggled (`setOnline` stores a bool). The frame asked
//     for "either a client-side local timestamp or a server field"; the
//     client-side one now exists (CourierStorage.setShiftEndedAt, written
//     by the same toggle) and the strip stamps it while off duty. No
//     stamp for today means the strip says TODAY and nothing more.
//   * chip 934's customer name — `serialize_deliveryman_order` emits no
//     user block at all, which is why the offer card names a SUBURB.
//
// The sheet is now scrollable and height-flexible where it used to be a
// fixed 336.h box, because the gate and the off-duty wallet card are
// taller than the carousel they replace. The weather banner stays docked
// ABOVE the card, exactly where the shipped code put it and for the
// reason the shipped code gave. Its last child clears chip 301, the
// root tab pill the home page floats over it.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:base_sdk/src/navigation/embedded_widgets.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

import 'package:delivery_sdk/src/driver/application/home/driver_home_notifier.dart';
import 'package:delivery_sdk/src/driver/application/home/driver_home_provider.dart';
import 'package:delivery_sdk/src/driver/application/order/order_provider.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/order_detail.dart';
import 'package:delivery_sdk/src/driver/infrastructure/services/courier_storage.dart';
import 'package:delivery_sdk/src/driver/presentation/home/available_work_queue.dart';
import 'package:delivery_sdk/src/driver/presentation/home/cash_on_hand_card.dart';
import 'package:delivery_sdk/src/driver/presentation/home/driver_day_strip.dart';
import 'package:delivery_sdk/src/driver/presentation/home/driver_root_nav.dart';
import 'package:delivery_sdk/src/driver/presentation/home/off_duty_cards.dart';
import 'package:delivery_sdk/src/driver/presentation/home/shift_stamp.dart';
import 'package:delivery_sdk/src/driver/presentation/home/work_paused_gate.dart';

import 'package:delivery_sdk/src/driver/application/home/home_provider.dart';

class BottomSheetScreen extends ConsumerStatefulWidget {
  final bool isScrolling;

  /// Fired when the driver asks for the top-up flow (chip 970 and chip
  /// 990 both carry it). Passed in rather than routed here because the
  /// wallet lives in revenue_sdk and this SDK imports only base_sdk —
  /// the host composition supplies the destination.
  final VoidCallback? onTopUp;

  /// Fired for "Open wallet" / "See what you owe". Same reason.
  final VoidCallback? onOpenWallet;

  const BottomSheetScreen({
    super.key,
    required this.isScrolling,
    this.onTopUp,
    this.onOpenWallet,
  });

  @override
  ConsumerState<BottomSheetScreen> createState() => _BottomSheetScreenState();
}

class _BottomSheetScreenState extends ConsumerState<BottomSheetScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(driverHomeProvider.notifier).refresh();
      if (CourierStorage.getOnline()) {
        ref.read(orderProvider.notifier).fetchAvailableOrders(context);
      } else {
        ref.read(driverHomeProvider.notifier).refreshOpenJobCount();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      bottom: widget.isScrolling ? -280.h : 0,
      // A Stack child positioned on ONE axis only is laid out
      // horizontally unbounded, and `CrossAxisAlignment.stretch` then
      // hands its children w=Infinity — which is exactly what the driver
      // home threw the moment the banner arrived and turned this sheet's
      // single self-sized Container into a stretching Column. Pinning
      // both edges gives the column the stack's width, which is the
      // width this sheet has always drawn at anyway (`_sheetBody` asks
      // for the full screen), so stretch now means "as wide as the
      // sheet" instead of "as wide as infinity".
      left: 0,
      right: 0,
      duration: const Duration(milliseconds: 400),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [_weatherWarningsBanner(), _sheetBody(context)],
      ),
    );
  }

  /// Severe-weather heads-up banner for the courier, rendered through the
  /// cross-SDK embedded-widgets seam (ADR-005): weather_sdk declares the
  /// zero-arg `weatherWarningsBanner` method in its manifest's
  /// `embedded_widgets` list and the installer injects the implementation
  /// into the host's `_HostEmbeddedWidgets`, so this file never imports
  /// weather_sdk.
  ///
  /// The call is dispatched dynamically and guarded because weather_sdk is
  /// OPTIONAL in courier compositions: without it the host has no
  /// `weatherWarningsBanner` implementation (base_sdk's [EmbeddedWidgets]
  /// interface does not declare the method either) and `EmbeddedWidgets.I`
  /// answers through `noSuchMethod` with a StateError - the courier home
  /// must then render nothing extra and never crash. When weather_sdk IS
  /// composed, the banner itself renders `SizedBox.shrink()` unless there
  /// is an active notice, so in the calm case this adds zero layout either
  /// way.
  ///
  /// CHIP 943 keeps it docked above the sheet card (not inside it) —
  /// exactly where the shipped code put it, and for the reason the
  /// shipped code gave.
  Widget _weatherWarningsBanner() {
    Widget? banner;
    try {
      final dynamic embedded = EmbeddedWidgets.I;
      final dynamic built = embedded.weatherWarningsBanner();
      if (built is Widget) banner = built;
    } catch (_) {
      // weather_sdk not composed into this app: show nothing.
    }
    if (banner == null) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 8.h),
      child: banner,
    );
  }

  Widget _sheetBody(BuildContext context) {
    final onDuty = CourierStorage.getOnline();
    final home = ref.watch(driverHomeProvider);

    return Container(
      width: MediaQuery.sizeOf(context).width,
      // Was a fixed 336.h. The composition is now state-dependent — the
      // gate and the off-duty wallet card are taller than the carousel
      // they replace — so the card is capped rather than pinned and
      // scrolls inside the cap.
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.62,
      ),
      decoration: BoxDecoration(
        color: AppStyle.surfaceDark,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(12.r),
          topLeft: Radius.circular(12.r),
        ),
        boxShadow: [
          BoxShadow(
            color: AppStyle.black.withValues(alpha: 0.25),
            blurRadius: 40,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: 8.h,
        // CHIP 301 floats over the sheet's foot; the last card must clear
        // it (frame 49e: the third offer crops at a visible edge above
        // the pill, never under it).
        bottom: MediaQuery.paddingOf(context).bottom +
            16.h +
            driverRootNavClearance(),
        left: 16.w,
        right: 16.w,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 4.h,
            width: 48.w,
            decoration: BoxDecoration(
              color: AppStyle.dragElement,
              borderRadius: BorderRadius.circular(40.r),
            ),
          ),
          14.verticalSpace,
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // CHIP 931 — the same strip on duty and off; frame 49d
                  // reframes it as a closing figure rather than a running
                  // one: "TODAY · SHIFT ENDED 17:04", stamped from the
                  // minute this phone saw the toggle go off (see
                  // shift_stamp.dart). On duty the heading is TODAY.
                  DriverDayStrip(
                    earned: home.report.earned,
                    delivered: home.report.deliveredCount,
                    lastFee: home.report.lastFee,
                    heading: onDuty
                        ? null
                        : driverShiftStampHeading(
                            CourierStorage.getShiftEndedAt(),
                          ),
                  ),
                  10.verticalSpace,
                  // CHIP 932 — survives into the off-duty frame unchanged.
                  // Going off duty does not hand the shop's money back.
                  if (home.report.cashOrderCount > 0) ...[
                    CashOnHandCard(
                      amount: home.report.cashOnHand,
                      orderCount: home.report.cashOrderCount,
                      compact: _isFold(context),
                    ),
                    10.verticalSpace,
                  ],
                  if (!onDuty) ..._offDuty(home) else ..._onDuty(home),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Frame 49e's fold, read from the phone rather than from any box.
  bool _isFold(BuildContext context) =>
      MediaQuery.sizeOf(context).width <= kDriverDayStripFoldWidth;

  /// FRAME 49d — off duty, drawn as a state.
  List<Widget> _offDuty(DriverHomeState home) => [
        OffDutyRestCard(
          openJobsInZone: home.openJobsInZone,
          onGoOnDuty: _goOnDuty,
        ),
        10.verticalSpace,
        // CHIP 970 — the wallet position. Going off duty is the moment a
        // driver can actually do something about a negative balance, and
        // it is the last screen that can tell him before he goes home.
        WalletPositionCard(
          owing: home.workStatus.owing,
          onTopUp: widget.onTopUp ?? _noWalletHost,
          onOpenWallet: widget.onOpenWallet ?? _noWalletHost,
        ),
      ];

  /// FRAMES 49a and 49m — on duty: the queue, or the gate that replaces
  /// it once the SERVER says new work has stopped.
  List<Widget> _onDuty(DriverHomeState home) {
    if (home.isWorkPaused) {
      return [
        WorkPausedGate(
          owing: home.workStatus.owing,
          allowance: home.workStatus.allowance,
          onTopUp: widget.onTopUp ?? _noWalletHost,
          onSeeWhatYouOwe: widget.onOpenWallet ?? _noWalletHost,
        ),
      ];
    }
    final orders = ref.watch(orderProvider).availableOrders;
    return [
      AvailableWorkQueue(
        jobs: orders.map(_toJob).toList(),
        compact: _isFold(context),
        onClaim: _claim,
      ),
    ];
  }

  /// CHIP 934, flattened. Suburbs only — the payload carries no person.
  ///
  /// `distanceKm` is left NULL here rather than guessed: the frame calls
  /// it client-derived from the row's location against the driver's own
  /// position, and this sheet does not hold the driver's position. The
  /// card omits the line rather than showing a number nobody computed.
  AvailableJob _toJob(OrderDetailData order) {
    final tag = order.transaction?.paymentSystem?.tag?.toLowerCase();
    return AvailableJob(
      id: '${order.id ?? ''}',
      shopName: order.shop?.translation?.title ?? '',
      pickupSuburb: order.shop?.translation?.address,
      dropOffSuburb: order.address?.address,
      fee: order.deliveryFee,
      isCash: tag == 'cash',
      cashAmount: tag == 'cash' ? order.totalPrice : null,
    );
  }

  /// CHIP 933's honesty in one call: `attach_order_to_me` succeeds only
  /// while `deliveryman` is still empty, so this is a race, and the
  /// existing goMarket path already surfaces the loss.
  void _claim(AvailableJob job) {
    ref.read(homeProvider.notifier).goMarket(
          context: context,
          orderId: job.id,
          setOrder: true,
          onSuccess: () {
            if (!mounted) return;
            ref.read(driverHomeProvider.notifier).refresh();
          },
        );
  }

  /// The same toggle the top-right control drives — one component, two
  /// states, no second control (chip 930).
  void _goOnDuty() {
    ref.read(homeProvider.notifier).setOnline(context: context);
    if (mounted) setState(() {});
  }

  /// The wallet lives in revenue_sdk. A composition without it gets a
  /// card that still states the position truthfully and simply has
  /// nowhere to send him — better than a button that throws.
  void _noWalletHost() {
    AppHelpers.showCheckTopSnackBar(
      context,
      AppHelpers.getTranslation(TrKeys.comingSoon),
    );
  }
}
