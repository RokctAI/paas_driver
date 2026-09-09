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

import 'package:auto_route/annotations.dart';
import 'package:charts_flutter/flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:revenue_sdk/src/driver/application/statistics/statistics_provider.dart';
import 'package:revenue_sdk/src/driver/application/statistics/statistics_state.dart';
import 'package:revenue_sdk/src/driver/infrastructure/models/chart.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/adaptive/breakpoints.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/presentation/components/custom_tab_bar.dart';
import 'package:base_sdk/src/presentation/components/title_icon.dart';
import 'package:base_sdk/src/presentation/components/floating_nav/floating_bottom_nav.dart';
import 'package:remixicon/remixicon.dart';
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:revenue_sdk/src/common/infrastructure/models/response/bank_account_record.dart';
import 'package:revenue_sdk/src/common/application/bank/bank_accounts_provider.dart';
import 'package:revenue_sdk/src/common/application/withdraw/withdraw_provider.dart';
import 'package:revenue_sdk/src/common/presentation/bank/bank_account_form_page.dart';
import 'package:revenue_sdk/src/common/presentation/bank/bank_accounts_page.dart';
import 'package:revenue_sdk/src/common/presentation/bank/bank_grammar.dart';
import 'package:revenue_sdk/src/common/presentation/bank/no_bank_account_sheet.dart';
import 'package:revenue_sdk/src/common/presentation/bank/payout_sent_sheet.dart';
import 'package:revenue_sdk/src/common/presentation/payouts/driver_payouts_page.dart';
import 'package:revenue_sdk/src/driver/presentation/wallet/driver_wallet_page.dart';
import 'package:revenue_sdk/src/common/presentation/withdraw/withdraw_sheet.dart';
// Siblings of this file: the installer copies the whole
// templates/pages/driver/income tree into the host's
// lib/presentation/pages/income, so a relative import resolves in the
// composed host exactly as the old `package:${package}/...` form did -
// and, unlike that form, it also resolves HERE, which is what lets
// revenue_sdk's own widget tests build this page (see
// test/driver_income_landscape_test.dart) instead of only grepping it.
import 'app_bar_screen.dart';
import 'statistics_screen.dart';
import 'widgets/income_item.dart';

@RoutePage(name: 'DriverIncomeRoute')
class IncomePage extends ConsumerStatefulWidget {
  const IncomePage({super.key});

  @override
  ConsumerState<IncomePage> createState() => _IncomePageState();
}

class _IncomePageState extends ConsumerState<IncomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _tabs = [
    Tab(
      child: Text(
        AppHelpers.getTranslation(TrKeys.today),
      ),
    ),
    Tab(
      child: Text(
        AppHelpers.getTranslation(TrKeys.weekly),
      ),
    ),
    Tab(
      child: Text(
        AppHelpers.getTranslation(TrKeys.monthly),
      ),
    ),
  ];

  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 0) {
        ref.read(statisticsProvider.notifier).fetchStatistics(
            startTime: DateTime.now(), endTime: DateTime.now());
      } else if (_tabController.index == 1) {
        ref.read(statisticsProvider.notifier).fetchStatistics(
            startTime: DateTime.now(),
            endTime: DateTime.now().subtract(const Duration(days: 7)));
      } else {
        ref.read(statisticsProvider.notifier).fetchStatistics(
            startTime: DateTime.now(),
            endTime: DateTime.now().subtract(const Duration(days: 30)));
      }
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        ref.read(statisticsProvider.notifier).fetchStatistics(
            startTime: DateTime.now(), endTime: DateTime.now());
      },
    );
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // -- Withdraw -----------------------------------------------------------
  //
  // The "Withdraw Money" button shipped as `onPressed: () {}`. It now opens
  // the fleet-keypad withdraw sheet and sends a real payout request through
  // wallet's whitelisted `api.payout.request_payout` def (revenue_sdk's
  // DriverPayoutRepository, over base_sdk's universal platform gateway —
  // paas_driver composes no wallet_sdk, so nothing is imported from it).
  //
  // The server debits the wallet AT REQUEST TIME (the hold), so a successful
  // request means the money has genuinely left; the notifier writes the
  // server's new balance onto the cached profile and this page rebuilds off
  // it, which is why the readout drops the moment the sheet closes.

  /// The balance this page already displays. `LocalStorage` is the same
  /// source the wallet row above uses, so the sheet can never disagree with
  /// what the driver is looking at.
  num get _balance => LocalStorage.getUser()?.wallet?.price ?? 0;

  /// A wallet at or below zero has nothing to withdraw. Going negative is
  /// deliberate and normal for a driver, so this is a plain fact about the
  /// balance, not an error state.
  bool get _canWithdraw => _balance > 0;

  /// The account the request will name. Set from the driver's default, and
  /// changed only by his own tap in the sheet.
  String? _selectedAccountId;

  /// The withdraw path, in the order frame 49n insists on.
  ///
  /// THE ACCOUNTS ARE READ FIRST, BEFORE ANYTHING OPENS. `request_payout`
  /// refuses a driver with no `Payout Bank Account` row
  /// (`payout.py:137-157, 324-328`), and until frames 49n-49q there was no
  /// screen in the app that could create one — so the button shipped here
  /// would have failed on its first tap for every real driver.
  ///
  /// Asking `list_bank_accounts` first means NO REQUEST IS EVER SENT on that
  /// path and NOTHING IS HELD: the driver meets an explanation and a way
  /// forward instead of a refusal, and the server's own wording never
  /// reaches him. Firing `request_payout` blind and translating its refusal
  /// would do the opposite of the house rule.
  Future<void> _openWithdraw() async {
    await ref.read(bankAccountsProvider.notifier).load(context: context);
    if (!mounted) return;

    final accounts = ref.read(bankAccountsProvider).accounts;
    if (accounts.isEmpty) {
      _openNoBankAccountSheet();
      return;
    }
    _selectedAccountId ??= defaultAccount(accounts)?.id ?? accounts.first.id;
    _openWithdrawSheet();
  }

  /// Frame 49n. Not an error card: nothing has failed, and the primary
  /// action is Add a bank account rather than Retry or Close.
  void _openNoBankAccountSheet() {
    AppHelpers.showCustomModalBottomSheet(
      context: context,
      isDarkMode: true,
      modal: NoBankAccountSheet(
        available: _balance,
        onDismiss: () => Navigator.pop(context),
        onAddBankAccount: () async {
          // Dismiss the sheet first: it takes no plane, so pushing the form
          // from income keeps the driver on plane 2 of a one-plane page and
          // the cap is never approached.
          Navigator.pop(context);
          final saved = await BankAccountFormPage.push(context);
          if (!mounted || saved == null) return;
          // He added the account he was asked for. Carry him straight on to
          // the withdrawal rather than returning him to the button he
          // already pressed — the dead end is only really gone when the
          // whole path completes.
          _selectedAccountId = saved.id;
          _openWithdrawSheet();
        },
      ),
    );
  }

  void _openWithdrawSheet() {
    final balanceBefore = _balance;
    AppHelpers.showCustomModalBottomSheet(
      context: context,
      isDarkMode: true,
      modal: Consumer(
        builder: (context, ref, _) {
          final withdraw = ref.watch(withdrawProvider);
          final accounts = ref.watch(bankAccountsProvider).accounts;
          final selectedId = _selectedAccountId;
          return WithdrawSheet(
            available: balanceBefore,
            submitting: withdraw.isSubmitting,
            accounts: accounts,
            selectedAccountId: selectedId,
            onSelectAccount: (id) => setState(() => _selectedAccountId = id),
            onSubmit: (amount) {
              ref.read(withdrawProvider.notifier).requestPayout(
                    context: context,
                    amount: amount,
                    // Named EXPLICITLY rather than left to the server's
                    // default: `_default_account` returns nothing when a
                    // driver has two unmarked rows (`payout.py:137-157`),
                    // and a refusal he could not have predicted is exactly
                    // what this whole batch exists to remove.
                    bankAccount: selectedId,
                    onSuccess: (newBalance) {
                      // The hold is taken; close the sheet and rebuild off
                      // the balance the notifier just cached.
                      Navigator.pop(context);
                      if (!mounted) return;
                      setState(() {});
                      _openPayoutSentSheet(
                        balanceBefore: balanceBefore,
                        amount: amount,
                        newBalance: newBalance ?? balanceBefore - amount,
                      );
                    },
                  );
            },
          );
        },
      ),
    );
  }

  /// Frame 49r. Opened only on an accepted request, and it states the
  /// subtraction rather than claiming a result: the wallet was written down
  /// at `payout.py:345` before the row existed at `:349-368`, so the drop is
  /// already real and a driver who cannot see why is the most expensive
  /// support call this endpoint can produce.
  void _openPayoutSentSheet({
    required num balanceBefore,
    required num amount,
    required num newBalance,
  }) {
    BankAccountRecord? account;
    for (final row in ref.read(bankAccountsProvider).accounts) {
      if (row.id == _selectedAccountId) account = row;
    }
    AppHelpers.showCustomModalBottomSheet(
      context: context,
      isDarkMode: true,
      modal: PayoutSentSheet(
        balanceBefore: balanceBefore,
        amount: amount,
        newBalance: newBalance,
        account: account,
        onDone: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(statisticsProvider);
    // The two-column plane. On a medium+ window (base's window-size class,
    // AppBreakpoints.medium = 600 dp) the transactions section, the order
    // prices and the statistics tiles stack in a LEFT column and the
    // earnings chart stands in a RIGHT column, so the page fits at rest
    // and the chart keeps its full 300.h. That is the SAME width at which
    // base's templates/app_widget.dart stops scaling ScreenUtil from the
    // 375x812 phone design and passes the logical size as the design size
    // (.w/.h 1:1), so the wide branch only ever renders with unscaled
    // units. Compact windows keep the single column exactly as before -
    // this bool is the one switch.
    final isWide = windowSizeOf(context).isAtLeastMedium;
    return Scaffold(
      backgroundColor: AppStyle.surfaceDark,
      // The withdraw bar rides in the Scaffold's bottom slot and the
      // Scaffold RESERVES that slot: no extendBody. The body's viewport
      // ends where the bar begins and the bar keeps its own bottom safe
      // area.
      //
      // What a still of the single column at scroll rest shows is the
      // FOLD, not the bar covering content: the column is taller than the
      // viewport on every phone, and the scroller clips at its bottom
      // edge, which is exactly the opaque button's top edge. The last card
      // (the chart) scrolls fully clear - a body run under the bar with
      // extendBody: true measured the same extent and the same rows under
      // the fold, because the Scaffold hands such a body a bottom inset
      // equal to the bar's height and the scroller padded by it. The
      // 800x1280 tablet, where the single column (1:1) was 84 dp taller
      // than the viewport and the chart card straddled the fold, is what
      // the two-column plane above exists for.
      body: Column(
        children: [
          AbbBarScreen(event: ref.read(statisticsProvider.notifier)),
          16.verticalSpace,
          Expanded(
            // Builder: the inset lives on the BODY's MediaQuery, which the
            // Scaffold provides below this widget's own context.
            child: Builder(
              builder: (context) => isWide
                  ? _wideBody(context, state)
                  : SingleChildScrollView(
                      padding: EdgeInsets.only(
                        right: 16.w,
                        left: 16.w,
                        // The gap the frames leave between the last card and the
                        // bar (the fleet's 12.h). The inset term is zero while
                        // the Scaffold reserves the bottom slot (it strips the
                        // body's bottom padding when a bottomNavigationBar is
                        // set) and only ever carries the slot's height if the
                        // body is made to run under the bar again.
                        bottom: MediaQuery.paddingOf(context).bottom + 12.h,
                      ),
                      child: Column(
                        children: [
                          CustomTabBar(
                            tabController: _tabController,
                            tabs: _tabs,
                          ),
                          24.verticalSpace,
                          _orderPrices(context, state),
                          ..._transactions(context, state),
                          32.verticalSpace,
                          _chart(state),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
      // One bottom overlay (design strip section 12, core#125): the page's
      // withdraw action riding above the floating nav's back-only pill,
      // whose back segment replaces the standalone PopButton as this
      // screen's ONE back affordance. Back-only (empty tab list): the
      // driver app composes no root tab set.
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: REdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: CustomButton(
                    title: AppHelpers.getTranslation(TrKeys.withdrawMoney),
                    // Nothing to withdraw: a wallet at or below
                    // zero. A driver's balance going NEGATIVE is
                    // deliberate and normal (he keeps the cash he
                    // collects and his ledger carries the debt),
                    // so the control is simply inert and the line
                    // under it says why, in plain words.
                    background: _canWithdraw
                        ? AppStyle.primary
                        : AppStyle.strokeDark,
                    textColor: _canWithdraw
                        ? AppStyle.blackColor
                        : AppStyle.textDarkFaint,
                    onPressed: _canWithdraw ? () => _openWithdraw() : () {},
                  ),
                ),
              ],
            ),
          ),
          if (!_canWithdraw) ...[
            6.verticalSpace,
            Padding(
              padding: REdgeInsets.symmetric(horizontal: 16),
              child: Text(
                AppHelpers.getTranslation(TrKeys.insufficientBalance),
                textAlign: TextAlign.center,
                style: AppStyle.interRegular(
                  size: 12,
                  color: AppStyle.textDarkSecondary,
                ),
              ),
            ),
          ],
          FloatingBottomNav(
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
        ],
      ),
    );
  }

  /// The transactions section, shared by every branch: the
  /// "Deliveryman transactions" / "Your payouts" header, the wallet and
  /// bank-account rows and the statistics tiles, in the order the single
  /// column has always stacked them. A list rather than a Column so the
  /// compact branch keeps the same widget tree it had before the wide
  /// branch existed.
  ///
  /// The two halves are also reachable on their own ([_transactionRows]
  /// and [_statistics]) because the landscape plane stands the ROWS beside
  /// the order-price card and keeps the tiles full width underneath; this
  /// list is the portrait order and stays the one definition of it.
  List<Widget> _transactions(BuildContext context, StatisticsState state) =>
      [
        ..._transactionRows(context),
        24.verticalSpace,
        _statistics(state),
      ];

  /// The header and the two tappable rows - everything in the section
  /// above the statistics tiles.
  List<Widget> _transactionRows(BuildContext context) {
    return [
      // Thin wiring only (repo policy: substance lives in
      // analyzable lib/, templates/ is excluded from
      // `flutter analyze` fleet-wide). Both destinations
      // are real pages in revenue_sdk's lib/src/driver.
      // Both inks passed explicitly: base's TitleAndIcon
      // defaults them to the polarity-pinned const
      // AppStyle.black, which is 1.30:1 on surfaceDark.
      TitleAndIcon(
        title: AppHelpers.getTranslation(
            TrKeys.deliverymanTransactions),
        titleColor: AppStyle.textPrimary,
        rightTitle:
            AppHelpers.getTranslation('your_payouts'),
        rightTitleColor: AppStyle.textPrimary,
        // Design strip frame 49k, plane 2 of income: the
        // Requested -> Paid | Rejected trail. The balance
        // drops the moment he taps Withdraw, so this is
        // the screen that explains where the money is.
        onRightTap: () => DriverPayoutsPage.push(context),
      ),
      12.verticalSpace,
      // Design strip frame 49f, the wallet plane. The row
      // itself is unchanged - it is now a way IN to the
      // plane instead of a number with no explanation.
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => DriverWalletPage.push(context),
        child: IncomeItem(
          title: AppHelpers.getTranslation(TrKeys.wallet),
          price: AppHelpers.numberFormat(
              number:
                  LocalStorage.getUser()?.wallet?.price ?? 0),
        ),
      ),
      12.verticalSpace,
      // Design strip frame 49q, plane 2 of income: the saved
      // bank accounts. Reachable on its own and not only
      // through a refused withdrawal, because a driver who
      // has closed an account needs to change it BEFORE the
      // next payout, not while one is being refused.
      GestureDetector(
        key: const Key('incomeBankAccountsRow'),
        behavior: HitTestBehavior.opaque,
        onTap: () => BankAccountsPage.push(context),
        child: IncomeItem(
          title: AppHelpers.getTranslation('bank_accounts'),
          price: '',
        ),
      ),
      // The legacy host row showed the courier's rating from
      // LocalStorage.getUser()?.rate (UserData parsed
      // assign_reviews_avg_rating). base_sdk's ProfileData carries
      // no rating field, so the row is parked until the courier
      // profile slice (delivery_sdk, S-D3) owns that surface.
      // IncomeItem(
      //   title: AppHelpers.getTranslation(TrKeys.rating),
      //   price: "-",
      // ),
    ];
  }

  /// The statistics tiles, full width of whatever column they land in
  /// (statistics_screen.dart sizes them from their own row's constraints).
  Widget _statistics(StatisticsState state) {
    return StatisticsScreen(
        totalOrders: (state.countData?.data?.totalCount ?? 0)
            .toString(),
        todayOrders: (state.countData?.data?.totalTodayCount ?? 0)
            .toString(),
        acceptedOrders: (state
                    .countData?.data?.totalAcceptedCount ??
                0)
            .toString(),
        rejectedOrders: (state
                    .countData?.data?.totalCanceledCount ??
                0)
            .toString(),
        doneOrders: (state.countData?.data?.totalDeliveredCount ??
                0)
            .toString(),
        canceledOrders:
            (state
                        .countData?.data?.totalNewCount ??
                    0)
                .toString(),
        acceptedPer:
            "${((state.countData?.data?.totalAcceptedCount ?? 0) / (state.countData?.data?.totalCount ?? 1) * 100).toStringAsFixed(1)}%",
        rejectedPer:
            "${((state.countData?.data?.totalCanceledCount ?? 0) / (state.countData?.data?.totalCount ?? 1) * 100).toStringAsFixed(1)}%",
        donePer:
            "${((state.countData?.data?.totalDeliveredCount ?? 0) / (state.countData?.data?.totalCount ?? 1) * 100).toStringAsFixed(1)}%",
        canceledPer:
            "${((state.countData?.data?.totalNewCount ?? 0) / (state.countData?.data?.totalCount ?? 1) * 100).toStringAsFixed(1)}%");
  }

  /// Medium+ windows: the segmented control stays full width above two
  /// equal columns. Left, the order prices and the transactions section,
  /// scrolling on its own when it is taller than the viewport; right, the
  /// earnings chart at its full height, top-aligned with the left column's
  /// first card. The right column scrolls too, only so a window shorter
  /// than the chart card (a landscape split) clips nothing.
  Widget _wideBody(BuildContext context, StatisticsState state) {
    // The gap the frames leave between the last card and the bar (the
    // fleet's 12.h), plus the body's bottom inset - zero while the
    // Scaffold reserves the bottom slot; see the compact branch.
    final bottom = MediaQuery.paddingOf(context).bottom + 12.h;
    return Padding(
      padding: EdgeInsets.only(right: 16.w, left: 16.w),
      child: Column(
        children: [
          CustomTabBar(
            tabController: _tabController,
            tabs: _tabs,
          ),
          24.verticalSpace,
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, box) {
                      // The LANDSCAPE plane. This column is bounded here
                      // (it is an Expanded inside the body's Row), so
                      // box.maxHeight is the viewport the scroller below
                      // will get and box.maxWidth is the half-page it has
                      // to spend. Wider than it is tall means the page is
                      // short of the one thing the stacked order-price
                      // card + transaction rows need - height - and has a
                      // surplus of the one thing standing them side by
                      // side costs: width. That is the whole rule; no dp
                      // threshold to drift from the cards' real heights.
                      //
                      // It answers true only on a landscape tablet
                      // (1280x800 and 1706x1066 give this column 616x474
                      // and 829x603) and false on both portrait ones
                      // (800x1280 -> 376x615, 1066x1706 -> 509x603),
                      // which keep the stack Ray approved, unchanged.
                      final landscape = box.maxWidth > box.maxHeight;
                      return SingleChildScrollView(
                        key: const Key('incomeWideLeftColumn'),
                        padding: EdgeInsets.only(bottom: bottom),
                        child: landscape
                            ? _landscapeColumn(context, state)
                            : Column(
                                children: [
                                  _orderPrices(context, state),
                                  ..._transactions(context, state),
                                ],
                              ),
                      );
                    },
                  ),
                ),
                16.horizontalSpace,
                Expanded(
                  child: SingleChildScrollView(
                    key: const Key('incomeWideRightColumn'),
                    padding: EdgeInsets.only(bottom: bottom),
                    child: _chart(state),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The left column of the WIDE plane when that column is landscape
  /// (see the rule in [_wideBody]): the order-price card stands BESIDE
  /// the transaction rows instead of above them, and the statistics tiles
  /// keep the full column width underneath.
  ///
  /// Nothing is hidden, dropped or shrunk - the same four pieces in the
  /// same reading order, left to right then down. The card is 120 dp of
  /// content in a half-page-wide slot it never needed, so lifting the
  /// rows up beside it is the height the tiles were missing: at 1280x800
  /// the stacked column measured 603 dp against a 474 dp viewport (the
  /// Withdraw bar cut the tiles in half in the tour still); this
  /// arrangement measures 451 and the tiles sit whole, above the bar,
  /// with nothing to scroll.
  Widget _landscapeColumn(BuildContext context, StatisticsState state) {
    return Column(
      children: [
        Row(
          // Both sub-columns keep their natural height and hang from the
          // same top edge, so the card and the "Deliveryman transactions"
          // header start on one line.
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _orderPriceCard(context, state)),
            // The seam between the two columns of the plane itself, so
            // the sub-columns read as the same grid.
            16.horizontalSpace,
            Expanded(
              child: Column(children: _transactionRows(context)),
            ),
          ],
        ),
        // The plane's own seam again (the portrait stack's 24 is the gap
        // between two sections of ONE column; here the tiles follow a row
        // that already reads as a band, and the 8 dp it gives back is
        // headroom this short plane can spend on the tiles).
        16.verticalSpace,
        _statistics(state),
      ],
    );
  }

  Column _chart(StatisticsState state) {
    // The SDK's StatisticsNotifier emits plain OrdinalSales rows so
    // revenue_sdk stays chart-library-agnostic; the charts_flutter Series
    // (including the brand-primary bar color the legacy host notifier set) is
    // built here, in the HOST package, whose pubspec owns charts_flutter.
    final List<Series<OrdinalSales, String>> series = [
      Series<OrdinalSales, String>(
        id: 'chart',
        data: state.chartData,
        domainFn: (OrdinalSales sales, _) => sales.day,
        measureFn: (OrdinalSales sales, _) => sales.sales,
        seriesColor: ColorUtil.fromDartColor(AppStyle.primary),
      ),
    ];
    return Column(
      children: [
        // titleColor passed explicitly: base's default is the const
        // AppStyle.black, unreadable on surfaceDark.
        TitleAndIcon(
          title: AppHelpers.getTranslation(TrKeys.earningsChart),
          titleColor: AppStyle.textPrimary,
        ),
        16.verticalSpace,
        Container(
            width: double.infinity,
            height: 300.h,
            decoration: BoxDecoration(
              color: AppStyle.cardDark,
              borderRadius: BorderRadius.circular(10.r),
            ),
            padding: EdgeInsets.all(16.r),
            child: BarChart(
              series,
              animate: true,
              vertical: false,
              animationDuration: const Duration(seconds: 1),
              defaultRenderer: BarRendererConfig(
                  cornerStrategy: const ConstCornerStrategy(6)),
            )),
        // No trailing spacer: the chart is the page's last card and the
        // scroller's own bottom padding (the frames' 12.h) is the gap to
        // the bar. The 32.h that sat here stacked on top of it, so the
        // card stopped 44 dp above the bar at scroll end and the page
        // scrolled 32 dp further than its content.
      ],
    );
  }

  /// The order-price card plus the gap that follows it in a stacked
  /// column. The landscape plane stands the card beside the transaction
  /// rows instead and supplies its own gap, so it calls
  /// [_orderPriceCard] directly.
  Column _orderPrices(BuildContext context, StatisticsState state) {
    return Column(
      children: [
        _orderPriceCard(context, state),
        32.verticalSpace,
      ],
    );
  }

  /// The card itself - "Order price", the last order's total and the
  /// income line under it.
  Widget _orderPriceCard(BuildContext context, StatisticsState state) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppStyle.cardDark,
        borderRadius: BorderRadius.circular(10.r),
      ),
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppHelpers.getTranslation(TrKeys.orderPrice),
            style: AppStyle.interNormal(
                size: 14,
                color: AppStyle.textPrimary,
                letterSpacing: -0.3),
          ),
          16.verticalSpace,
          Text(
            AppHelpers.numberFormat(
                number: state.countData?.data?.lastOrderTotalPrice ?? 0),
            style: AppStyle.interSemi(
                size: 32,
                color: AppStyle.textPrimary,
                letterSpacing: -0.3),
          ),
          4.verticalSpace,
          RichText(
              text: TextSpan(
                  text: AppHelpers.getTranslation(TrKeys.lastIncome),
                  style: AppStyle.interNormal(
                      size: 12,
                      color: AppStyle.textPrimary,
                      letterSpacing: -0.3),
                  children: [
                TextSpan(
                  // Leading space: the label span carries none
                  // ("Last income" is the translation, not "Last
                  // income "), so without it the row read
                  // "Last incomeR45.00". Same shape as the "Today"
                  // row in statistics_screen.dart (" $todayOrders").
                  text:
                      ' ${AppHelpers.numberFormat(number: state.countData?.data?.lastOrderIncome ?? 0)}',
                  style: AppStyle.interSemi(
                      size: 12,
                      color: AppStyle.textPrimary,
                      letterSpacing: -0.3),
                )
              ])),
        ],
      ),
    );
  }
}
