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

// `/load/sell` — THE SALE AT THE DOOR.
//
// A stepper per line capped at what the server says is remaining, a
// running total struck at the load's own unit prices, an optional note,
// and a confirm that comes back with the order id and the cash to collect.
//
// THE SALE IS CASH AND IT IS BORN SETTLED. `create_load_sale` writes the
// child order Delivered and Paid server-side, so there is no "mark
// delivered" step after this screen and no place to add one. What the
// driver owes the shop for it is the wallet's business, not this screen's.
//
// AND IF HE NAMED A PLACE, HE IS ASKED WHETHER HE IS AT IT. A sale
// attributed to a point is what teaches the round "this corner buys", so a
// sale booked at a point two streets away teaches the round something
// false. Past `PoiProximity.confirmMetres` the confirm ASKS, naming the
// distance and the place — and it never refuses: a van day has too many
// honest reasons to be further off than a fix likes, and a screen that
// blocks the sale is a screen that loses the money.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:remixicon/remixicon.dart';

import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/components/floating_nav/floating_bottom_nav.dart';
import 'package:base_sdk/src/presentation/components/text_fields/outline_bordered_text_field.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

import 'package:delivery_sdk/src/common/application/poi/poi_proximity.dart';
import 'package:delivery_sdk/src/driver/application/load/load_draft.dart';
import 'package:delivery_sdk/src/driver/application/load/load_provider.dart';
import 'package:delivery_sdk/src/driver/application/poi/poi_provider.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/driver_load.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/driver_poi.dart';
import 'package:delivery_sdk/src/driver/presentation/load/load_line_tiles.dart';
import 'package:delivery_sdk/src/driver/presentation/load/load_missing_notice.dart';
import 'package:delivery_sdk/src/driver/presentation/poi/poi_selector.dart';

class LoadSalePlane extends ConsumerStatefulWidget {
  const LoadSalePlane({super.key, this.loadOrder});

  /// Which load is being sold from. Null falls back to the driver's only
  /// open load, which is the shape of almost every van day.
  final String? loadOrder;

  static Future<void> push(BuildContext context, String loadOrder) {
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => LoadSalePlane(loadOrder: loadOrder)),
    );
  }

  @override
  ConsumerState<LoadSalePlane> createState() => _LoadSalePlaneState();
}

class _LoadSalePlaneState extends ConsumerState<LoadSalePlane> {
  LoadDraft _draft = const LoadDraft();
  final TextEditingController _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  DriverLoad? get _load {
    final state = ref.read(driverLoadProvider);
    final id = widget.loadOrder;
    if (id != null && id.isNotEmpty) return state.loadById(id);
    final open = state.openLoads;
    return open.length == 1 ? open.first : null;
  }

  Future<void> _confirm(DriverLoad load) async {
    // The place he named, if he named one. Read at commit time rather than
    // held on this screen, so the point he picked in the sheet a second ago
    // is the point the sale carries.
    final poi = ref.read(driverPoiProvider).selected;
    // Named a place? Then he says he is standing at it, and how far off he
    // actually is decides whether that goes unquestioned.
    if (poi != null && !await _standingThere(poi)) return;
    if (!mounted) return;
    final sale = await ref.read(driverLoadProvider.notifier).sell(
          load: load,
          draft: _draft,
          poi: poi?.id,
          // CUSTOMER SELECTION IS DELIBERATELY NOT HERE YET. With no
          // customer the server books the sale on the driver's own
          // account, which is exactly what a walk-in at the van is. A
          // picker lands when commerce grows a walk-in customer create
          // for this seam; until then offering a field that can only
          // send null would be a lie about what the button does.
          customer: null,
          note: _note.text,
          context: context,
        );
    if (sale == null || !mounted) return;
    setState(() => _draft = const LoadDraft());
    // The next sale is at the next door: a point named for this one must
    // not silently ride along.
    ref.read(driverPoiProvider.notifier).select(null);
    _showSold(sale);
  }

  /// Whether the sale may be booked at [point] — either because he is at
  /// it, or because he said to carry on anyway.
  ///
  /// An UNKNOWN distance goes through unquestioned: a phone that would not
  /// give a fix is not evidence that he is somewhere else, and a refused
  /// location permission must not turn into a dialog on every sale (see
  /// [PoiProximity.needsConfirming]).
  Future<bool> _standingThere(DriverPoi point) async {
    final metres = await ref.read(driverPoiProvider.notifier).metresFrom(point);
    if (!PoiProximity.needsConfirming(metres)) return true;
    if (!mounted) return false;
    final answer = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('loadSalePoiFarDialog'),
        backgroundColor: AppStyle.cardFor(Theme.of(context).brightness),
        title: Text(
          AppHelpers.getTranslation('are_you_at_this_place'),
          style: AppStyle.interSemi(size: 16, color: AppStyle.inkFor(Theme.of(context).brightness)),
        ),
        content: Text(
          '${AppHelpers.getTranslation('you_are')} ${metres!.round()} m '
          '${AppHelpers.getTranslation('from')} ${point.title}. '
          '${AppHelpers.getTranslation('continue_anyway')}',
          style: AppStyle.interRegular(
            size: 13,
            color: AppStyle.secondaryInkFor(Theme.of(context).brightness),
          ),
        ),
        actions: [
          TextButton(
            key: const Key('loadSalePoiFarCancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              AppHelpers.getTranslation(TrKeys.cancel),
              style: AppStyle.interSemi(
                size: 14,
                color: AppStyle.secondaryInkFor(Theme.of(context).brightness),
              ),
            ),
          ),
          TextButton(
            key: const Key('loadSalePoiFarConfirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              AppHelpers.getTranslation('continue_word'),
              style: AppStyle.interSemi(size: 14, color: AppStyle.primary),
            ),
          ),
        ],
      ),
    );
    return answer == true;
  }

  /// The receipt. NOT dismissible: it carries the order id the driver may
  /// have to read out and the cash he has to take, and a stray drag is not
  /// an acknowledgement. Done closes it AND leaves this screen, so he lands
  /// back on the load list — already redrawn, because the sale's own answer
  /// carried the new remaining figures into the slice.
  void _showSold(DriverLoadSale sale) {
    final planeNavigator = Navigator.of(context);
    AppHelpers.showCustomModalBottomSheet(
      context: context,
      isDarkMode: (Theme.of(context).brightness == Brightness.dark),
      isDrag: false,
      isDismissible: false,
      modal: LoadSaleDoneSheet(
        sale: sale,
        onDone: (sheetContext) {
          Navigator.of(sheetContext).maybePop();
          planeNavigator.maybePop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(driverLoadProvider);
    final load = _load;
    if (load == null) {
      return const LoadMissingNotice(titleKey: 'sell_from_load');
    }
    final lines = load.sellableLines;
    final total = _draft.totalFor(load);
    return Scaffold(
      backgroundColor: AppStyle.surfaceFor(Theme.of(context).brightness),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: ListView(
                key: const Key('loadSalePlane'),
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 92.h),
                children: [
                  Text(
                    AppHelpers.getTranslation('sell_from_load'),
                    style: AppStyle.interSemi(size: 21),
                  ),
                  4.verticalSpace,
                  Text(
                    load.shopTitle ?? load.id,
                    style: AppStyle.interRegular(
                      size: 13,
                      color: AppStyle.secondaryInkFor(Theme.of(context).brightness),
                    ),
                  ),
                  20.verticalSpace,
                  const _WalkInCustomerRow(),
                  10.verticalSpace,
                  // WHERE the sale happened, beside WHO it was for. The
                  // customer row can only say "the driver's own account"
                  // in this version; this one is the answer the round
                  // actually learns from, and it is optional.
                  PoiSelectorRow(shop: load.shopId),
                  16.verticalSpace,
                  for (final line in lines)
                    LoadLineStepperRow(
                      line: line,
                      quantity: _draft.quantityFor(line),
                      cap: LoadDraft.capFor(line),
                      onIncrement: () =>
                          setState(() => _draft = _draft.increment(line)),
                      onDecrement: () =>
                          setState(() => _draft = _draft.decrement(line)),
                    ),
                  6.verticalSpace,
                  OutlinedBorderTextField(
                    key: const Key('loadSaleNote'),
                    label: AppHelpers.getTranslation('note_optional'),
                    textController: _note,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  20.verticalSpace,
                  _TotalRow(
                    total: total,
                    units: _draft.totalUnitsFor(load),
                  ),
                  16.verticalSpace,
                  CustomButton(
                    key: const Key('loadSaleConfirm'),
                    title: AppHelpers.getTranslation('confirm_sale'),
                    background: AppStyle.primary,
                    textColor: AppStyle.blackColor,
                    isLoading: state.isSubmitting,
                    onPressed: _draft.isEmpty || state.isSubmitting
                        ? null
                        : () => _confirm(load),
                  ),
                ],
              ),
            ),
            PositionedDirectional(
              end: 16,
              bottom: 16,
              child: FloatingBackPill(
                back: FloatingNavBack(
                  icon: Remix.arrow_left_s_line,
                  label: AppHelpers.getTranslation(TrKeys.back),
                  onTap: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The customer field, as far as it goes in this version: the one case the
/// server can actually book. See `_confirm`'s comment — the picker lands
/// with commerce's walk-in customer create, and the row says so plainly
/// rather than pretending to be a chooser.
class _WalkInCustomerRow extends StatelessWidget {
  const _WalkInCustomerRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('loadSaleCustomer'),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppStyle.cardFor(Theme.of(context).brightness),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppStyle.strokeFor(Theme.of(context).brightness)),
      ),
      child: Row(
        children: [
          Icon(Remix.user_line, size: 18.r, color: AppStyle.secondaryInkFor(Theme.of(context).brightness)),
          10.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppHelpers.getTranslation('customer'),
                  style: AppStyle.interRegular(
                    size: 11,
                    color: AppStyle.faintFor(Theme.of(context).brightness),
                  ),
                ),
                2.verticalSpace,
                Text(
                  AppHelpers.getTranslation('myself_walk_in'),
                  style: AppStyle.interSemi(
                    size: 14,
                    color: AppStyle.inkFor(Theme.of(context).brightness),
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

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.total, required this.units});

  final num total;
  final int units;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppStyle.cardAltFor(Theme.of(context).brightness),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppStyle.subtleStrokeFor(Theme.of(context).brightness)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${AppHelpers.getTranslation('cash_to_collect')} · $units '
              '${AppHelpers.getTranslation(units == 1 ? 'item' : 'items')}',
              style: AppStyle.interRegular(
                size: 13,
                color: AppStyle.secondaryInkFor(Theme.of(context).brightness),
              ),
            ),
          ),
          8.horizontalSpace,
          Text(
            AppHelpers.numberFormat(number: total),
            key: const Key('loadSaleTotal'),
            style: AppStyle.interSemi(size: 20, color: AppStyle.inkFor(Theme.of(context).brightness)),
          ),
        ],
      ),
    );
  }
}

/// The receipt: the order id the shop can look the sale up by, and the
/// cash figure to take at the door.
class LoadSaleDoneSheet extends StatelessWidget {
  const LoadSaleDoneSheet({super.key, required this.sale, this.onDone});

  final DriverLoadSale sale;

  /// Handed the sheet's own context so the caller can close the sheet and
  /// the screen behind it in one step.
  final void Function(BuildContext sheetContext)? onDone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const Key('loadSaleDoneSheet'),
      padding: EdgeInsets.fromLTRB(
        16.w,
        20.h,
        16.w,
        MediaQuery.paddingOf(context).bottom + 20.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppHelpers.getTranslation('sale_recorded'),
            style: AppStyle.interSemi(size: 18, color: AppStyle.inkFor(Theme.of(context).brightness)),
          ),
          8.verticalSpace,
          if (sale.orderId != null)
            Text(
              '${AppHelpers.getTranslation('order')} ${sale.orderId}',
              key: const Key('loadSaleDoneOrderId'),
              style: AppStyle.interRegular(
                size: 13,
                color: AppStyle.secondaryInkFor(Theme.of(context).brightness),
              ),
            ),
          16.verticalSpace,
          Text(
            AppHelpers.getTranslation('collect'),
            style: AppStyle.interRegular(
              size: 12,
              color: AppStyle.faintFor(Theme.of(context).brightness),
            ),
          ),
          4.verticalSpace,
          Text(
            AppHelpers.numberFormat(number: sale.amount),
            key: const Key('loadSaleDoneAmount'),
            style: AppStyle.interSemi(size: 28, color: AppStyle.inkFor(Theme.of(context).brightness)),
          ),
          20.verticalSpace,
          CustomButton(
            key: const Key('loadSaleDoneClose'),
            title: AppHelpers.getTranslation(TrKeys.done),
            background: AppStyle.primary,
            textColor: AppStyle.blackColor,
            onPressed: () {
              final done = onDone;
              if (done != null) {
                done(context);
              } else {
                Navigator.of(context).maybePop();
              }
            },
          ),
        ],
      ),
    );
  }
}
