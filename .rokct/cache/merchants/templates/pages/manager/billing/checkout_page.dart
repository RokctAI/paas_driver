// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:remixicon/remixicon.dart';

import 'package:base_sdk/src/constants/app_constants.dart';
// ApiResult's `when` lives in the freezed extension declared by this
// library, so the import is load-bearing even though no type is named.
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/presentation/components/floating_nav/floating_bottom_nav.dart';
import 'package:base_sdk/src/presentation/components/helper/common_image.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:merchants_sdk/src/manager/application/pos_cart/pos_cart_provider.dart';
import 'package:merchants_sdk/src/manager/application/pos_cart/pos_cart_state.dart';
import 'package:merchants_sdk/src/manager/domain/interface/pos_orders.dart';
import 'package:merchants_sdk/src/manager/utils/pos_connectivity.dart';
import 'package:merchants_sdk/src/manager/utils/pos_pay_verification.dart';
import 'package:merchants_sdk/src/manager/utils/pos_receipt_printer.dart';

// The POS checkout — approved design 2026-08-28 (strip section 11,
// frames 11c–11i, "approved: 11i, 11c-h" per Ray 19:32Z):
//   * the 171-pattern page header (chip 304): the bare host top-row —
//     interSemi 18 textPrimary title on the page surface, trailing slots
//     empty, NO app bar (GenericProfilePage `_TopRow`'s language);
//   * In-store | Send for delivery fulfillment toggle (312/313) and the
//     Cash | QR (pay-link) method toggle (288/289);
//   * QR: the pay-link QR card the customer scans and pays on their own
//     phone (290), with the online phase gate "I've Scanned, Wait for
//     Code" (291);
//   * customer attach — the "Billing to" card (305) with the credit
//     outstanding "owes" chip (306); REQUIRED before credit/partial
//     unlocks (the debt lands on a real customer's wallet);
//   * credit / partly-paid (11g/11h): "Amount paying now" (307) with the
//     Full / R0-all-on-credit quick actions (308), the remainder-due
//     banner (309) with the Shop.credit_allowance gate line (310), the
//     summary's Paying-now / On-credit split rows (292), and the finish
//     button's takes/records sublabel (311). All-on-credit rides the
//     merged credit machinery end to end; partly-paid records the
//     paid-now Transaction and the remainder auto-collects FIFO from
//     the customer's next wallet top-up;
//   * send-for-delivery (11i): the delivery address card (314) and
//     "Send for delivery & Finish" (315) — the sale enters the NORMAL
//     order queue at Ready through the EXISTING seller create-order
//     pipeline (Ray: "you just need to add scanned ones to that
//     pipeline"); a credit marking rides along per the settlement rules;
//   * receipt-style order summary (292) and the dual finish: "Print
//     Receipt & Finish" — atomic print-then-record (293) — and "Finish
//     without Receipt" (294);
//   * OFFLINE INVERSION (frames 11e/11f): when the till is offline the
//     phase gate is replaced by straight-to-code entry — offline banner
//     (295), 6-digit confirmation code (296). The QR STAYS: the
//     customer's phone is online even when the till is not; the code and
//     the pay-link both carry the PAYING-NOW amount, verified locally by
//     PosPayVerification, zero server contact.
//
// OFFLINE-FIRST PIPELINE (Ray's rulings): every finished sale goes
// through PosOrdersFacade.submitSale — local drift store FIRST, then the
// existing SyncEngine order.create queue; checkout never blocks on the
// network, and the sale goes up with the status it is in ('delivered'
// in-store, 'ready' send-for-delivery — an offline delivery sale HOLDS
// at Ready until the sync drains it). With no facade registered the
// checkout degrades honestly: no customer/credit surface, local-only
// completion (demo builds register the mock).
//
// ONE BACK (strip section 12, merged core#125): the floating nav's
// back-only pill (FloatingNavBack) is this screen's single back
// affordance — no PopButton, no app-bar arrow.
//
// Installed by the manifest to lib/presentation/pages/billing/ with the
// /pos-checkout route; @RoutePage(name: 'PosCheckoutRoute') so the host's
// generated router owns the route class. BillingPage reaches it by path,
// so both templates compile without the host router (standalone test
// harness compiles them directly).

@RoutePage(name: 'PosCheckoutRoute')
class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

enum _PayMethod { cash, qr }

enum _Fulfillment { inStore, delivery }

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  _PayMethod _method = _PayMethod.qr;
  _Fulfillment _fulfillment = _Fulfillment.inStore;

  /// Null while the probe runs; the offline inversion renders on false.
  bool? _online;

  /// Online phase gate (chip 291): the cashier taps "I've Scanned, Wait
  /// for Code" once the customer has scanned, and the code entry appears.
  bool _scannedGatePassed = false;

  /// Set when a typed 6-digit code verified locally; cleared on edits.
  bool _codeVerified = false;
  bool _codeRejected = false;
  final TextEditingController _codeController = TextEditingController();

  /// Credit / partly-paid state (chips 305–311). The customer attach is
  /// REQUIRED before any of it unlocks.
  PosCustomer? _customer;
  double? _customerOutstanding;
  final TextEditingController _paidNowController = TextEditingController();
  String _prefilledForOrderId = '';

  /// Send-for-delivery address (chip 314).
  String _address = '';

  /// A submit in flight — the finish buttons ignore re-taps.
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    unawaited(_probe());
  }

  @override
  void dispose() {
    _codeController.dispose();
    _paidNowController.dispose();
    super.dispose();
  }

  Future<void> _probe() async {
    final online = await PosConnectivity.check();
    if (mounted) setState(() => _online = online);
  }

  PosOrdersFacade? get _posOrders => GetIt.I.isRegistered<PosOrdersFacade>()
      ? GetIt.I<PosOrdersFacade>()
      : null;

  String get _shopId =>
      (LocalStorage.getShopJson()?['id'])?.toString() ?? '';

  /// Per-shop shared secret for the offline code (see PosPayVerification:
  /// the shop uuid today, a rotating secret in the backend contract).
  String get _sharedSecret =>
      (LocalStorage.getShopJson()?['uuid'])?.toString() ?? _shopId;

  /// Whether this shop completes sales on credit at all
  /// (Shop.enable_credit; absent means enabled — the allowance solvency
  /// guard is the backend's, surfaced in the gate line).
  bool get _creditEnabled {
    final flag = LocalStorage.getShopJson()?['enable_credit'];
    return flag != 0 && flag != false && flag != '0';
  }

  /// The shop's item-commission rate, for the gate line's fronting
  /// figure (chip 310): at a counter sale the shop fronts the item
  /// commission — there is no delivery fee.
  double get _commissionRate =>
      double.tryParse(
        LocalStorage.getShopJson()?['percentage']?.toString() ?? '',
      ) ??
      0;

  /// Chip 307's value: the amount collected right now. Empty/invalid
  /// entry (and no attached customer) means the full total.
  double _payingNow(PosCartState state) {
    if (_customer == null) return state.total;
    final raw = _paidNowController.text.trim().replaceAll(',', '.');
    final parsed = double.tryParse(raw);
    if (parsed == null) return state.total;
    return posRoundCents(parsed.clamp(0, state.total).toDouble());
  }

  double _remainder(PosCartState state) =>
      posRoundCents(state.total - _payingNow(state));

  bool _creditActive(PosCartState state) =>
      _customer != null && _remainder(state) > 0.005;

  /// The pay link the customer scans (chip 290), carrying the PAYING-NOW
  /// amount (the credit remainder never rides the link). Keyed to the
  /// STABLE order id (minted once in the cart notifier — never here in
  /// build, a held-build finding), so the QR does not re-key
  /// mid-checkout.
  String _payLink(PosCartState state) =>
      '${AppConstants.baseUrl}/pos/pay?order=${state.orderId}'
      '&amount=${_payingNow(state).toStringAsFixed(2)}&shop=$_shopId';

  void _onCodeChanged(String code) {
    final state = ref.read(posCartProvider);
    if (code.length < 6) {
      if (_codeVerified || _codeRejected) {
        setState(() {
          _codeVerified = false;
          _codeRejected = false;
        });
      }
      return;
    }
    final ok = PosPayVerification.verify(
      enteredCode: code,
      orderId: state.orderId,
      amount: _payingNow(state),
      shopId: _shopId,
      sharedSecret: _sharedSecret,
    );
    setState(() {
      _codeVerified = ok;
      _codeRejected = !ok;
    });
  }

  /// The dual finish (chips 293/294, and 315 for send-for-delivery).
  /// With a receipt the print is ATOMIC: the sale is only recorded after
  /// the printer returns — a throwing printer leaves the sale open (the
  /// Spazafy checkout recorded first and a dead printer silently ate
  /// receipts). The pipeline submit is OFFLINE-FIRST (local store +
  /// sync queue) so it never blocks on the network; a submit failure is
  /// a local storage failure and leaves the sale open too.
  Future<void> _finish({required bool withReceipt}) async {
    if (_finishing) return;
    final state = ref.read(posCartProvider);
    if (state.isEmpty) return;
    final facade = _posOrders;
    final delivery = _fulfillment == _Fulfillment.delivery;

    if (delivery && facade != null) {
      if (_customer == null) {
        AppHelpers.showCheckTopSnackBar(
          context,
          AppHelpers.getTranslation(TrKeys.deliveryNeedsCustomer),
        );
        return;
      }
      if (_address.trim().isEmpty) {
        AppHelpers.showCheckTopSnackBar(
          context,
          AppHelpers.getTranslation(TrKeys.deliveryNeedsAddress),
        );
        return;
      }
    }

    _finishing = true;
    try {
      if (withReceipt && !delivery) {
        try {
          await PosReceiptPrinter.print(
            state.orderId,
            state.lines
                .map((l) => PosReceiptLine(
                      title: l.title,
                      quantity: l.quantity,
                      lineTotal: l.lineTotal,
                    ))
                .toList(),
            state.total,
          );
        } catch (e) {
          if (mounted) {
            AppHelpers.showCheckTopSnackBar(
              context,
              AppHelpers.getTranslation(TrKeys.printFailed),
            );
          }
          return;
        }
      }

      if (facade != null) {
        final draft = PosSaleDraft(
          orderId: state.orderId,
          lines: [
            for (final line in state.lines)
              PosDraftLine(
                productId: line.product.id ?? '',
                quantity: line.quantity,
              ),
          ],
          total: state.total,
          deliveryType: delivery ? 'delivery' : 'pickup',
          // Ray's ruling: the sale goes up with the status it is IN — an
          // in-store sale is already handed over ('delivered'); a packed
          // send-for-delivery sale is 'ready' (and HOLDS there locally
          // while offline, until the sync drains it).
          status: delivery ? 'ready' : 'delivered',
          customerId: _customer?.id,
          phone: _customer?.phone,
          address: delivery ? _address.trim() : null,
          paidNow: _payingNow(state),
          onCredit: _creditActive(state),
        );
        final result = await facade.submitSale(draft);
        var submitted = false;
        String? failure;
        result.when(
          success: (_) => submitted = true,
          failure: (error, statusCode) => failure = error,
        );
        if (!submitted) {
          if (mounted) {
            AppHelpers.showCheckTopSnackBar(
              context,
              failure ??
                  AppHelpers.getTranslation(
                    TrKeys.somethingWentWrongWithTheServer,
                  ),
            );
          }
          return;
        }
      }

      ref.read(posCartProvider.notifier).finishSale();
      if (!mounted) return;
      setState(() {
        _customer = null;
        _customerOutstanding = null;
        _address = '';
        _paidNowController.clear();
        _prefilledForOrderId = '';
      });
      AppHelpers.showCheckTopSnackBarDone(
        context,
        AppHelpers.getTranslation(TrKeys.saleCompleted),
      );
      // Plain Navigator (the floating back pill's own default) so the
      // page never needs the host's router at runtime — the standalone
      // harness pumps it directly.
      unawaited(Navigator.of(context).maybePop());
    } finally {
      _finishing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(posCartProvider);
    // Prefill the paying-now entry once per order (the stable order id
    // is minted in the notifier, so this cannot re-fire per rebuild).
    if (_prefilledForOrderId != state.orderId && state.total > 0) {
      _prefilledForOrderId = state.orderId;
      _paidNowController.text = state.total.toStringAsFixed(2);
    }
    final facade = _posOrders;
    final offline = _online == false;
    final showQr = _method == _PayMethod.qr;
    final showCodeEntry = showQr && (offline || _scannedGatePassed);
    final showGate = showQr && !offline && !_scannedGatePassed;
    final delivery = _fulfillment == _Fulfillment.delivery;
    final creditActive = _creditActive(state);
    return Scaffold(
      backgroundColor: AppStyle.surfaceDark,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.all(16.r),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _header(context),
                    20.verticalSpace,
                    _shopRow(context),
                    20.verticalSpace,
                    if (facade != null) ...[
                      _fulfillmentToggle(context),
                      14.verticalSpace,
                    ],
                    _methodToggle(context),
                    20.verticalSpace,
                    if (showQr) ...[
                      if (offline)
                        _offlineBanner(context)
                      else
                        _qrHintBanner(context),
                      20.verticalSpace,
                      _qrCard(context, state),
                      20.verticalSpace,
                      if (showGate) _phaseGate(context),
                      if (showCodeEntry) _codeEntryCard(context),
                      20.verticalSpace,
                    ],
                    if (facade != null) ...[
                      _billingToCard(context),
                      14.verticalSpace,
                      if (delivery) ...[
                        _deliversToCard(context),
                        14.verticalSpace,
                      ],
                      if (_customer != null && _creditEnabled) ...[
                        _amountPayingNowCard(context, state),
                        14.verticalSpace,
                      ],
                      if (creditActive) ...[
                        _remainderBanner(context, state),
                        14.verticalSpace,
                      ],
                      6.verticalSpace,
                    ],
                    _summary(context, state),
                    20.verticalSpace,
                    _finishButtons(context, state),
                    120.verticalSpace,
                  ]),
                ),
              ),
            ],
          ),
          // The floating nav's back-only pill (FloatingNavBack, core#125 —
          // design strip section 12's one-back rule): the shared pill
          // housing carrying only the leading back segment, this screen's
          // ONE back affordance. Back-only (empty tab list) because the
          // shell's root tabs are not reachable from this pushed route.
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FloatingBottomNav(
                mode: FloatingNavTabsMode(
                  tabs: const [],
                  currentIndex: 0,
                  onSelect: (_) {},
                  back: FloatingNavBack(
                    icon: Remix.arrow_left_wide_fill,
                    label: AppHelpers.getTranslation(TrKeys.back),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Chip 304: the 171-pattern page header — GenericProfilePage
  /// `_TopRow`'s language: a bare row on the page surface, interSemi 18
  /// textPrimary leading title with ellipsis, trailing slots empty. The
  /// big-title app-bar block is gone (Ray 2026-08-28).
  Widget _header(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            AppHelpers.getTranslation(TrKeys.checkout),
            style: AppStyle.interSemi(
              size: 18.sp,
              color: AppStyle.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _shopRow(BuildContext context) {
    final shopJson = LocalStorage.getShopJson();
    return Row(
      children: [
        CommonImage(
          url: shopJson?['logo_img'] as String?,
          width: 56.r,
          height: 56.r,
          radius: 28,
        ),
        14.horizontalSpace,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (shopJson?['translation']?['title'] as String?) ?? '',
              style: AppStyle.interSemi(size: 18),
            ),
            2.verticalSpace,
            Text(
              AppHelpers.getTranslation(TrKeys.activeTransaction),
              style: AppStyle.interRegular(
                size: 13,
                color: AppStyle.textDarkSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Chips 312/313: the In-store | Send for delivery fulfillment toggle
  /// (added per Ray 15:23Z — "are you sure till cant update status to
  /// ready and a deliveryman come and collect?").
  Widget _fulfillmentToggle(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _methodPill(
            icon: Remix.store_2_line,
            label: AppHelpers.getTranslation(TrKeys.inStore),
            selected: _fulfillment == _Fulfillment.inStore,
            onTap: () =>
                setState(() => _fulfillment = _Fulfillment.inStore),
          ),
        ),
        14.horizontalSpace,
        Expanded(
          child: _methodPill(
            icon: Remix.e_bike_2_line,
            label: AppHelpers.getTranslation(TrKeys.sendForDelivery),
            selected: _fulfillment == _Fulfillment.delivery,
            onTap: () =>
                setState(() => _fulfillment = _Fulfillment.delivery),
          ),
        ),
      ],
    );
  }

  /// Chips 288/289: the Cash | QR / Pay link method toggle.
  Widget _methodToggle(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _methodPill(
            icon: Remix.cash_line,
            label: AppHelpers.getTranslation(TrKeys.cash),
            selected: _method == _PayMethod.cash,
            onTap: () => setState(() => _method = _PayMethod.cash),
          ),
        ),
        14.horizontalSpace,
        Expanded(
          child: _methodPill(
            icon: Remix.qr_code_line,
            label: AppHelpers.getTranslation(TrKeys.qrPayLink),
            selected: _method == _PayMethod.qr,
            onTap: () {
              setState(() => _method = _PayMethod.qr);
              // Re-probe when entering the QR flow — the inversion should
              // reflect the till's connectivity at decision time.
              unawaited(_probe());
            },
          ),
        ),
      ],
    );
  }

  Widget _methodPill({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final color = selected ? AppStyle.blue : AppStyle.textPrimary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52.r,
        decoration: BoxDecoration(
          color: selected
              ? AppStyle.blue.withOpacity(0.08)
              : AppStyle.cardDark,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: selected ? AppStyle.blue : AppStyle.strokeDark,
            width: 1.r,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20.r, color: color),
            8.horizontalSpace,
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppStyle.interSemi(size: 15, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qrHintBanner(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppStyle.cardDarkAlt,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppStyle.strokeDarkSubtle, width: 1.r),
      ),
      child: Row(
        children: [
          Icon(Remix.qr_scan_2_line, size: 24.r, color: AppStyle.blue),
          12.horizontalSpace,
          Expanded(
            child: Text(
              AppHelpers.getTranslation(TrKeys.letCustomerScanQr),
              style: AppStyle.interRegular(size: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// Chip 295: the offline inversion banner.
  Widget _offlineBanner(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        // Red tint over the mode surface rather than the fixed light
        // redBg constant, so the banner reads in dark mode too.
        color: AppStyle.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: AppStyle.red.withOpacity(0.4),
          width: 1.r,
        ),
      ),
      child: Row(
        children: [
          Icon(Remix.wifi_off_line, size: 24.r, color: AppStyle.red),
          12.horizontalSpace,
          Expanded(
            child: Text(
              AppHelpers.getTranslation(TrKeys.tillOfflineBanner),
              style: AppStyle.interRegular(size: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// Chip 290: the pay-link QR card. Deliberately white in BOTH modes —
  /// scanners want quiet-zone contrast, and the render keeps it so.
  Widget _qrCard(BuildContext context, PosCartState state) {
    return Center(
      child: Container(
        // Keyed for the standalone harness (PrettyQrView.data returns a
        // package-private widget type, so tests find the card by key).
        key: const Key('posPayQrCard'),
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: AppStyle.white,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: SizedBox(
          width: 220.r,
          height: 220.r,
          child: PrettyQrView.data(
            data: _payLink(state),
            decoration: const PrettyQrDecoration(
              shape: PrettyQrSmoothSymbol(color: Color(0xFF000000)),
            ),
          ),
        ),
      ),
    );
  }

  /// Chip 291: the online phase gate.
  Widget _phaseGate(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _scannedGatePassed = true),
      child: Container(
        width: double.infinity,
        height: 56.r,
        decoration: BoxDecoration(
          color: AppStyle.blue.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: AppStyle.blue.withOpacity(0.5),
            width: 1.r,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          AppHelpers.getTranslation(TrKeys.iveScannedWaitForCode),
          style: AppStyle.interSemi(size: 15, color: AppStyle.blue),
        ),
      ),
    );
  }

  /// Chip 296: the 6-digit confirmation code entry (offline inversion —
  /// and the online post-gate phase). Verified locally, zero server
  /// contact (PosPayVerification), against the PAYING-NOW amount.
  Widget _codeEntryCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: AppStyle.blue.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppStyle.blue.withOpacity(0.35),
          width: 1.r,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              AppHelpers.getTranslation(TrKeys.confirmByCode),
              style: AppStyle.interSemi(size: 20, color: AppStyle.blue),
            ),
          ),
          10.verticalSpace,
          Center(
            child: Text(
              AppHelpers.getTranslation(TrKeys.enterSixDigitCode),
              textAlign: TextAlign.center,
              style: AppStyle.interRegular(
                size: 14,
                color: AppStyle.textDarkSecondary,
              ),
            ),
          ),
          18.verticalSpace,
          Text(
            AppHelpers.getTranslation(TrKeys.sixDigitCode),
            style: AppStyle.interSemi(size: 12),
          ),
          4.verticalSpace,
          TextField(
            controller: _codeController,
            onChanged: _onCodeChanged,
            keyboardType: TextInputType.number,
            maxLength: 6,
            style: AppStyle.interSemi(size: 20, letterSpacing: 2),
            decoration: InputDecoration(
              counterText: '',
              hintText: AppHelpers.getTranslation(TrKeys.typeHere),
              hintStyle: AppStyle.interRegular(
                size: 16,
                color: AppStyle.textDarkFaint,
              ),
            ),
          ),
          if (_codeVerified) ...[
            10.verticalSpace,
            Row(
              children: [
                Icon(
                  Remix.checkbox_circle_fill,
                  size: 18.r,
                  color: AppStyle.green,
                ),
                6.horizontalSpace,
                Text(
                  AppHelpers.getTranslation(TrKeys.paymentConfirmed),
                  style:
                      AppStyle.interSemi(size: 14, color: AppStyle.green),
                ),
              ],
            ),
          ] else if (_codeRejected) ...[
            10.verticalSpace,
            Text(
              AppHelpers.getTranslation(TrKeys.invalidCode),
              style: AppStyle.interRegular(size: 13, color: AppStyle.red),
            ),
          ],
        ],
      ),
    );
  }

  /// Chips 305/306: the "Billing to" customer attach card with the
  /// credit-outstanding "owes" chip. Optional for a full cash/QR sale,
  /// REQUIRED before credit/partial unlocks.
  Widget _billingToCard(BuildContext context) {
    final customer = _customer;
    final outstanding = _customerOutstanding ?? 0;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppStyle.cardDark,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                AppHelpers.getTranslation(TrKeys.billingTo).toUpperCase(),
                style: AppStyle.interSemi(
                  size: 12,
                  color: AppStyle.textDarkSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => unawaited(_pickCustomer(context)),
                child: Text(
                  AppHelpers.getTranslation(
                    customer == null
                        ? TrKeys.addCustomer
                        : TrKeys.changeCustomer,
                  ),
                  style:
                      AppStyle.interSemi(size: 14, color: AppStyle.blue),
                ),
              ),
            ],
          ),
          if (customer != null) ...[
            12.verticalSpace,
            Row(
              children: [
                Container(
                  width: 44.r,
                  height: 44.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppStyle.blue.withOpacity(0.12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    customer.initials,
                    style: AppStyle.interSemi(
                      size: 15,
                      color: AppStyle.blue,
                    ),
                  ),
                ),
                12.horizontalSpace,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.fullName,
                        style: AppStyle.interSemi(size: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      2.verticalSpace,
                      Text(
                        customer.phone ?? '',
                        style: AppStyle.interRegular(
                          size: 13,
                          color: AppStyle.textDarkSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (outstanding > 0.005) ...[
                  8.horizontalSpace,
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 5.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppStyle.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(100.r),
                      border: Border.all(
                        color: AppStyle.primary.withOpacity(0.5),
                        width: 1.r,
                      ),
                    ),
                    child: Text(
                      '${_decap(AppHelpers.getTranslation(TrKeys.owes))} ${AppHelpers.numberFormat(number: outstanding)}',
                      style: AppStyle.interSemi(
                        size: 12,
                        color: AppStyle.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Chip 314: the delivery address card — tap Change to enter/edit the
  /// attached customer's shipping address; the delivery fee joins the
  /// order downstream (the normal pipeline computes it).
  Widget _deliversToCard(BuildContext context) {
    final hasAddress = _address.trim().isNotEmpty;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppStyle.cardDark,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Remix.map_pin_2_line,
                size: 16.r,
                color: AppStyle.textDarkSecondary,
              ),
              6.horizontalSpace,
              Text(
                AppHelpers.getTranslation(TrKeys.deliversTo).toUpperCase(),
                style: AppStyle.interSemi(
                  size: 12,
                  color: AppStyle.textDarkSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => unawaited(_editAddress(context)),
                child: Text(
                  AppHelpers.getTranslation(TrKeys.changeCustomer),
                  style:
                      AppStyle.interSemi(size: 14, color: AppStyle.blue),
                ),
              ),
            ],
          ),
          10.verticalSpace,
          Text(
            hasAddress
                ? _address
                : AppHelpers.getTranslation(TrKeys.addDeliveryAddress),
            style: hasAddress
                ? AppStyle.interSemi(size: 15)
                : AppStyle.interRegular(
                    size: 14,
                    color: AppStyle.textDarkFaint,
                  ),
          ),
          4.verticalSpace,
          Text(
            AppHelpers.getTranslation(TrKeys.deliveryFeeJoins),
            style: AppStyle.interRegular(
              size: 13,
              color: AppStyle.textDarkSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Chips 307/308: the "Amount paying now" card — prefilled with the
  /// total; editing below the total splits the sale. Quick actions: Full
  /// and "R0 — all on credit".
  Widget _amountPayingNowCard(BuildContext context, PosCartState state) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppStyle.cardDark,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppHelpers.getTranslation(TrKeys.amountPayingNow).toUpperCase(),
            style: AppStyle.interSemi(
              size: 12,
              color: AppStyle.textDarkSecondary,
              letterSpacing: 1.2,
            ),
          ),
          8.verticalSpace,
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  // Keyed for the standalone harness (the page can carry
                  // several TextFields at once).
                  key: const Key('posPaidNowField'),
                  controller: _paidNowController,
                  onChanged: (_) => setState(() {}),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: AppStyle.interSemi(size: 28),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 6.h),
                    hintText: state.total.toStringAsFixed(2),
                    hintStyle: AppStyle.interSemi(
                      size: 28,
                      color: AppStyle.textDarkFaint,
                    ),
                  ),
                ),
              ),
              10.horizontalSpace,
              Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Text(
                  '${_decap(AppHelpers.getTranslation(TrKeys.payingOf))} ${AppHelpers.numberFormat(number: state.total)} ${AppHelpers.getTranslation(TrKeys.total).toLowerCase()}',
                  style: AppStyle.interRegular(
                    size: 14,
                    color: AppStyle.textDarkSecondary,
                  ),
                ),
              ),
            ],
          ),
          12.verticalSpace,
          Wrap(
            spacing: 10.w,
            runSpacing: 8.h,
            children: [
              _quickAmountChip(
                label:
                    '${AppHelpers.getTranslation(TrKeys.fullAmount)} ${AppHelpers.numberFormat(number: state.total)}',
                onTap: () => setState(() {
                  _paidNowController.text =
                      state.total.toStringAsFixed(2);
                }),
              ),
              _quickAmountChip(
                label:
                    '${AppHelpers.numberFormat(number: 0)} ${AppHelpers.getTranslation(TrKeys.allOnCredit)}',
                onTap: () => setState(() {
                  _paidNowController.text = '0';
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickAmountChip({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
        decoration: BoxDecoration(
          color: AppStyle.cardDarkAlt,
          borderRadius: BorderRadius.circular(100.r),
          border: Border.all(color: AppStyle.strokeDarkSubtle, width: 1.r),
        ),
        child: Text(
          label,
          style: AppStyle.interSemi(size: 13),
        ),
      ),
    );
  }

  /// Chips 309/310: the remainder-due banner — the remainder completes
  /// as a CREDIT order on the customer's account and auto-collects in
  /// full from their next wallet top-up (oldest debt first) — with the
  /// Shop.credit_allowance gate line (at a counter sale the shop fronts
  /// the item commission; there is no delivery fee).
  Widget _remainderBanner(BuildContext context, PosCartState state) {
    final remainder = _remainder(state);
    final fronting = posRoundCents(state.total * _commissionRate / 100);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppStyle.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: AppStyle.primary.withOpacity(0.55),
          width: 1.r,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Remix.wallet_3_line,
                size: 20.r,
                color: AppStyle.primary,
              ),
              10.horizontalSpace,
              Expanded(
                child: Text(
                  '${AppHelpers.numberFormat(number: remainder)} ${_decap(AppHelpers.getTranslation(TrKeys.creditRemainder))}',
                  style: AppStyle.interRegular(size: 14),
                ),
              ),
            ],
          ),
          10.verticalSpace,
          Divider(height: 1.h, color: AppStyle.primary.withOpacity(0.25)),
          10.verticalSpace,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Remix.shield_check_line,
                size: 18.r,
                color: AppStyle.blue,
              ),
              10.horizontalSpace,
              Expanded(
                child: Text(
                  _creditEnabled
                      ? '${AppHelpers.getTranslation(TrKeys.creditAvailableFronts)} ${AppHelpers.numberFormat(number: fronting)} ${AppHelpers.getTranslation(TrKeys.commissionAllowanceCovers)}'
                      : AppHelpers.getTranslation(TrKeys.creditUnavailable),
                  style: AppStyle.interRegular(
                    size: 13,
                    color: AppStyle.textDarkSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Chip 292: the receipt-style order summary — with the Paying-now /
  /// On-credit split rows when a credit split is active (11g).
  Widget _summary(BuildContext context, PosCartState state) {
    final creditActive = _creditActive(state);
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppStyle.cardDark,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          if (!creditActive) ...[
            Row(
              children: [
                Text(
                  AppHelpers.getTranslation(TrKeys.items),
                  style: AppStyle.interRegular(
                    size: 14,
                    color: AppStyle.textDarkSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  _trimQty(state.itemCount),
                  style: AppStyle.interRegular(size: 14),
                ),
              ],
            ),
            10.verticalSpace,
            Divider(height: 1.h, color: AppStyle.strokeDarkSubtle),
            10.verticalSpace,
          ],
          Row(
            children: [
              Text(
                AppHelpers.getTranslation(TrKeys.total),
                style: AppStyle.interSemi(size: 18),
              ),
              const Spacer(),
              Text(
                AppHelpers.numberFormat(number: state.total),
                style: AppStyle.interSemi(size: 20, color: AppStyle.blue),
              ),
            ],
          ),
          if (creditActive) ...[
            10.verticalSpace,
            Divider(height: 1.h, color: AppStyle.strokeDarkSubtle),
            10.verticalSpace,
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${AppHelpers.getTranslation(TrKeys.payingNow)} · ${AppHelpers.getTranslation(_method == _PayMethod.cash ? TrKeys.cash : TrKeys.qrPayLink)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyle.interRegular(
                      size: 14,
                      color: AppStyle.textDarkSecondary,
                    ),
                  ),
                ),
                8.horizontalSpace,
                Text(
                  AppHelpers.numberFormat(number: _payingNow(state)),
                  style: AppStyle.interSemi(size: 15),
                ),
              ],
            ),
            10.verticalSpace,
            Divider(height: 1.h, color: AppStyle.strokeDarkSubtle),
            10.verticalSpace,
            Row(
              children: [
                Text(
                  AppHelpers.getTranslation(TrKeys.onCredit),
                  style: AppStyle.interRegular(
                    size: 14,
                    color: AppStyle.textDarkSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  AppHelpers.numberFormat(number: _remainder(state)),
                  style: AppStyle.interSemi(
                    size: 15,
                    color: AppStyle.primary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Chips 293/294 — and 315 when Send for delivery is selected: the
  /// primary button becomes "Send for delivery & Finish" (the sale
  /// enters the normal order queue at Ready). Chip 311: the split's
  /// takes/records sublabel.
  Widget _finishButtons(BuildContext context, PosCartState state) {
    final delivery = _fulfillment == _Fulfillment.delivery;
    final creditActive = _creditActive(state);
    final String primaryLabel = AppHelpers.getTranslation(
      delivery ? TrKeys.sendForDeliveryFinish : TrKeys.printReceipt,
    );
    final String? primarySub = delivery
        ? AppHelpers.getTranslation(TrKeys.entersOrderQueue)
        : creditActive
            ? '${_decap(AppHelpers.getTranslation(TrKeys.takes))} ${AppHelpers.numberFormat(number: _payingNow(state))} ${_decap(AppHelpers.getTranslation(TrKeys.nowWord))} · ${_decap(AppHelpers.getTranslation(TrKeys.records))} ${AppHelpers.numberFormat(number: _remainder(state))} ${_decap(AppHelpers.getTranslation(TrKeys.due))}'
            : null;
    return Column(
      children: [
        GestureDetector(
          onTap: () => unawaited(_finish(withReceipt: !delivery)),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(minHeight: 56.r),
            padding:
                EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
            decoration: BoxDecoration(
              color: AppStyle.primary,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  primaryLabel,
                  textAlign: TextAlign.center,
                  style: AppStyle.interSemi(
                    size: 16,
                    color: AppStyle.blackColor,
                  ),
                ),
                if (primarySub != null) ...[
                  2.verticalSpace,
                  Text(
                    primarySub,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyle.interRegular(
                      size: 12,
                      color: AppStyle.blackColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        14.verticalSpace,
        GestureDetector(
          onTap: () => unawaited(_finish(withReceipt: false)),
          child: Container(
            width: double.infinity,
            height: 56.r,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppStyle.blue, width: 1.r),
            ),
            alignment: Alignment.center,
            child: Text(
              AppHelpers.getTranslation(TrKeys.finish),
              style: AppStyle.interSemi(size: 16, color: AppStyle.blue),
            ),
          ),
        ),
      ],
    );
  }

  /// Chip 305's picker: the shop-scoped customer search (the same
  /// create-order picker data, reused at checkout).
  Future<void> _pickCustomer(BuildContext context) async {
    final facade = _posOrders;
    if (facade == null) return;
    final picked = await showModalBottomSheet<PosCustomer>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: MediaQuery.viewInsetsOf(sheetContext),
        child: _CustomerPickerSheet(facade: facade),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _customer = picked;
      _customerOutstanding = null;
    });
    final outstanding = await facade.customerCreditOutstanding(picked.id);
    if (mounted && _customer?.id == picked.id) {
      setState(() => _customerOutstanding = outstanding);
    }
  }

  /// Chip 314's editor: plain address entry (the manager flow's shipping
  /// address field, at the till).
  Future<void> _editAddress(BuildContext context) async {
    final controller = TextEditingController(text: _address);
    final entered = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppStyle.cardDark,
        title: Text(
          AppHelpers.getTranslation(TrKeys.deliversTo),
          style: AppStyle.interSemi(size: 18),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppStyle.interSemi(size: 16),
          decoration: InputDecoration(
            hintText: AppHelpers.getTranslation(TrKeys.addDeliveryAddress),
            hintStyle: AppStyle.interRegular(
              size: 15,
              color: AppStyle.textDarkFaint,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              AppHelpers.getTranslation(TrKeys.cancel),
              style: AppStyle.interSemi(
                size: 14,
                color: AppStyle.textDarkSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text),
            child: Text(
              AppHelpers.getTranslation(TrKeys.done),
              style: AppStyle.interSemi(size: 14, color: AppStyle.blue),
            ),
          ),
        ],
      ),
    );
    if (entered != null && mounted) {
      setState(() => _address = entered.trim());
    }
  }

  /// De-capitalizes ONLY the first character of a humanized fallback so
  /// mid-sentence fragments read as designed ("owes R89.50", "takes ...
  /// now") while interior casing (CREDIT, Ready) survives.
  static String _decap(String s) =>
      s.isEmpty ? s : s[0].toLowerCase() + s.substring(1);

  static String _trimQty(double quantity) {
    if (quantity == quantity.roundToDouble()) {
      return quantity.round().toString();
    }
    return quantity.toString();
  }
}

/// The "Billing to" card's picker sheet: a debounced search over the
/// shop's customers with one-tap attach (pops the picked customer).
class _CustomerPickerSheet extends StatefulWidget {
  const _CustomerPickerSheet({required this.facade});

  final PosOrdersFacade facade;

  @override
  State<_CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<_CustomerPickerSheet> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  List<PosCustomer> _results = const [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    unawaited(_search(''));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(_search(text));
    });
  }

  Future<void> _search(String text) async {
    setState(() => _searching = true);
    final result =
        await widget.facade.searchCustomers(query: text.trim());
    if (!mounted) return;
    result.when(
      success: (customers) => setState(() {
        _results = customers;
        _searching = false;
      }),
      failure: (error, statusCode) => setState(() => _searching = false),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppStyle.surfaceDark,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
      ),
      padding: EdgeInsets.all(16.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            onChanged: _onChanged,
            style: AppStyle.interSemi(size: 16),
            decoration: InputDecoration(
              prefixIcon: Icon(
                Remix.user_line,
                size: 20.r,
                color: AppStyle.textDarkSecondary,
              ),
              hintText:
                  AppHelpers.getTranslation(TrKeys.searchCustomers),
              hintStyle: AppStyle.interRegular(
                size: 15,
                color: AppStyle.textDarkFaint,
              ),
              filled: true,
              fillColor: AppStyle.cardDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          12.verticalSpace,
          if (_searching)
            Padding(
              padding: EdgeInsets.all(24.r),
              child: const CircularProgressIndicator.adaptive(),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _results.length,
                separatorBuilder: (context, index) => 8.verticalSpace,
                itemBuilder: (context, index) {
                  final customer = _results[index];
                  // Material ancestor for the tile's ink — the sheet's
                  // decorated container would otherwise hide it (and
                  // trip the framework's debug assertion in tests).
                  return Material(
                    color: Colors.transparent,
                    child: ListTile(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8.w),
                    leading: Container(
                      width: 40.r,
                      height: 40.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppStyle.blue.withOpacity(0.12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        customer.initials,
                        style: AppStyle.interSemi(
                          size: 14,
                          color: AppStyle.blue,
                        ),
                      ),
                    ),
                    title: Text(
                      customer.fullName,
                      style: AppStyle.interSemi(size: 15),
                    ),
                    subtitle: customer.phone == null
                        ? null
                        : Text(
                            customer.phone!,
                            style: AppStyle.interRegular(
                              size: 13,
                              color: AppStyle.textDarkSecondary,
                            ),
                          ),
                      onTap: () =>
                          Navigator.of(context).pop(customer),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
