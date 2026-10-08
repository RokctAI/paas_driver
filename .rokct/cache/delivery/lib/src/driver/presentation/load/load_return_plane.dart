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

// `/load/return` — STOCK BACK TO THE SHOP.
//
// The same steppers as the sell screen, capped at the same remaining
// figure, and NO TOTAL: a return is not a sale and putting a money figure
// on it would read like a refund. What it does carry is the one fact that
// makes returning worth the driver's minute — anything he does not return
// before the load closes is charged to his wallet at the load price.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:remixicon/remixicon.dart';

import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/components/floating_nav/floating_bottom_nav.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

import 'package:delivery_sdk/src/driver/application/load/load_draft.dart';
import 'package:delivery_sdk/src/driver/application/load/load_provider.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/driver_load.dart';
import 'package:delivery_sdk/src/driver/presentation/load/load_line_tiles.dart';
import 'package:delivery_sdk/src/driver/presentation/load/load_missing_notice.dart';

class LoadReturnPlane extends ConsumerStatefulWidget {
  const LoadReturnPlane({super.key, this.loadOrder});

  /// Which load is being returned against. Null falls back to the driver's
  /// only open load.
  final String? loadOrder;

  static Future<void> push(BuildContext context, String loadOrder) {
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => LoadReturnPlane(loadOrder: loadOrder)),
    );
  }

  @override
  ConsumerState<LoadReturnPlane> createState() => _LoadReturnPlaneState();
}

class _LoadReturnPlaneState extends ConsumerState<LoadReturnPlane> {
  LoadDraft _draft = const LoadDraft();

  DriverLoad? get _load {
    final state = ref.read(driverLoadProvider);
    final id = widget.loadOrder;
    if (id != null && id.isNotEmpty) return state.loadById(id);
    final open = state.openLoads;
    return open.length == 1 ? open.first : null;
  }

  Future<void> _confirm(DriverLoad load) async {
    final returned = await ref.read(driverLoadProvider.notifier).returnStock(
          load: load,
          draft: _draft,
          context: context,
        );
    if (!returned || !mounted) return;
    setState(() => _draft = const LoadDraft());
    AppHelpers.showCheckTopSnackBarDone(
      context,
      AppHelpers.getTranslation('return_recorded'),
    );
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(driverLoadProvider);
    final load = _load;
    if (load == null) {
      return const LoadMissingNotice(titleKey: 'return_to_shop');
    }
    final lines = load.sellableLines;
    return Scaffold(
      backgroundColor: AppStyle.surfaceFor(Theme.of(context).brightness),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: ListView(
                key: const Key('loadReturnPlane'),
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 92.h),
                children: [
                  Text(
                    AppHelpers.getTranslation('return_to_shop'),
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
                  10.verticalSpace,
                  Text(
                    AppHelpers.getTranslation(
                      'what_you_dont_return_is_charged_to_your_wallet_when_the_'
                      'load_closes',
                    ),
                    style: AppStyle.interRegular(
                      size: 12,
                      color: AppStyle.faintFor(Theme.of(context).brightness),
                    ),
                  ),
                  20.verticalSpace,
                  CustomButton(
                    key: const Key('loadReturnConfirm'),
                    title: AppHelpers.getTranslation('confirm_return'),
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
