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

// `/load` — MY LOAD. The van as the shop's books see it.
//
// One card per open load: which shop issued it, every line's issued /
// sold / returned / remaining, and the one figure the driver is personally
// carrying — what is still on the van, valued at the load price. Three
// actions, in the order a day goes: Sell, Return, Close load — and a
// fourth that is not part of the day's money at all: Add POI, the place he
// just passed, filed for the round.
//
// THE EMPTY STATE IS ONE SENTENCE AND STAYS ONE SENTENCE. Most drivers on
// most days carry no load. There is nothing to explain, nothing to sign up
// for and nothing to invent: "No load issued to you yet." A later edit
// must not grow a call to action here — the driver cannot issue himself a
// load, only the shop can.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:remixicon/remixicon.dart';

import 'package:base_sdk/src/presentation/components/floating_nav/floating_bottom_nav.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

import 'package:delivery_sdk/src/driver/application/load/load_provider.dart';
import 'package:delivery_sdk/src/driver/application/load/load_state.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/driver_load.dart';
import 'package:delivery_sdk/src/driver/presentation/load/load_close_flow.dart';
import 'package:delivery_sdk/src/driver/presentation/load/load_line_tiles.dart';
import 'package:delivery_sdk/src/driver/presentation/load/load_return_plane.dart';
import 'package:delivery_sdk/src/driver/presentation/load/load_sale_plane.dart';
import 'package:delivery_sdk/src/driver/presentation/poi/add_poi_sheet.dart';

class DriverLoadPlane extends ConsumerStatefulWidget {
  const DriverLoadPlane({super.key});

  /// Pushes the plane over the whole shell (root navigator = the nav fold),
  /// the same way the deposit plane opens from the home sheet.
  static Future<void> push(BuildContext context) {
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => const DriverLoadPlane()),
    );
  }

  @override
  ConsumerState<DriverLoadPlane> createState() => _DriverLoadPlaneState();
}

class _DriverLoadPlaneState extends ConsumerState<DriverLoadPlane> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(driverLoadProvider.notifier).load(context: context);
    });
  }

  Future<void> _refresh() =>
      ref.read(driverLoadProvider.notifier).load(context: context);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(driverLoadProvider);
    final loads = state.openLoads;
    return Scaffold(
      backgroundColor: AppStyle.surfaceFor(Theme.of(context).brightness),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: RefreshIndicator(
                color: AppStyle.primary,
                onRefresh: _refresh,
                child: ListView(
                  key: const Key('driverLoadPlane'),
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 92.h),
                  children: [
                    Text(
                      AppHelpers.getTranslation('my_load'),
                      style: AppStyle.interSemi(size: 21),
                    ),
                    20.verticalSpace,
                    if (loads.isEmpty)
                      _LoadEmptyState(state: state)
                    else
                      for (final load in loads) ...[
                        _LoadCard(load: load),
                        14.verticalSpace,
                      ],
                  ],
                ),
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

/// One plain sentence. Before the first answer it says we are still
/// looking, so "no load" never shows for a load that simply has not
/// arrived yet.
class _LoadEmptyState extends StatelessWidget {
  const _LoadEmptyState({required this.state});

  final DriverLoadState state;

  @override
  Widget build(BuildContext context) {
    final String key;
    if (state.failed) {
      key = 'we_couldnt_read_your_load_try_again_in_a_moment';
    } else if (!state.loadedOnce) {
      key = 'reading_your_load';
    } else {
      key = 'no_load_issued_to_you_yet';
    }
    return Text(
      AppHelpers.getTranslation(key),
      key: const Key('driverLoadEmpty'),
      style: AppStyle.interRegular(
        size: 14,
        color: AppStyle.secondaryInkFor(Theme.of(context).brightness),
      ),
    );
  }
}

class _LoadCard extends ConsumerWidget {
  const _LoadCard({required this.load});

  final DriverLoad load;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(driverLoadProvider).isSubmitting;
    final sellable = load.sellableLines.isNotEmpty;
    return Container(
      key: Key('driverLoadCard-${load.id}'),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppStyle.cardFor(Theme.of(context).brightness),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppStyle.strokeFor(Theme.of(context).brightness)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      load.shopTitle ?? load.shopId ?? load.id,
                      style: AppStyle.interSemi(
                        size: 16,
                        color: AppStyle.inkFor(Theme.of(context).brightness),
                      ),
                    ),
                    4.verticalSpace,
                    Text(
                      _subLine(),
                      style: AppStyle.interRegular(
                        size: 12,
                        color: AppStyle.secondaryInkFor(Theme.of(context).brightness),
                      ),
                    ),
                  ],
                ),
              ),
              8.horizontalSpace,
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppHelpers.numberFormat(number: load.remainingTotal),
                    key: Key('driverLoadRemainingTotal-${load.id}'),
                    style: AppStyle.interSemi(
                      size: 18,
                      color: AppStyle.inkFor(Theme.of(context).brightness),
                    ),
                  ),
                  2.verticalSpace,
                  Text(
                    AppHelpers.getTranslation('still_on_the_van'),
                    style: AppStyle.interRegular(
                      size: 11,
                      color: AppStyle.faintFor(Theme.of(context).brightness),
                    ),
                  ),
                ],
              ),
            ],
          ),
          12.verticalSpace,
          Divider(height: 1, color: AppStyle.subtleStrokeFor(Theme.of(context).brightness)),
          for (final line in load.lines) LoadLineFactRow(line: line),
          Divider(height: 1, color: AppStyle.subtleStrokeFor(Theme.of(context).brightness)),
          12.verticalSpace,
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _CardAction(
                label: AppHelpers.getTranslation('sell'),
                actionKey: 'driverLoadSell-${load.id}',
                enabled: sellable && !busy,
                primary: true,
                onTap: () => LoadSalePlane.push(context, load.id),
              ),
              _CardAction(
                label: AppHelpers.getTranslation('return'),
                actionKey: 'driverLoadReturn-${load.id}',
                enabled: sellable && !busy,
                onTap: () => LoadReturnPlane.push(context, load.id),
              ),
              _CardAction(
                label: AppHelpers.getTranslation('close_load'),
                actionKey: 'driverLoadClose-${load.id}',
                enabled: !busy,
                onTap: () => DriverLoadCloseFlow.confirm(context, ref, load),
              ),
              // A FOURTH ACTION, and the only one that costs him nothing:
              // the place he just drove past is worth filing whether or not
              // he sold anything there. Enabled even on a load he can no
              // longer sell from, for exactly that reason.
              //
              // IT CARRIES THE CARD'S OWN SHOP. The card he tapped IS the
              // answer to "which round is this place on", so the sheet is
              // never left asking — a driver carrying two open loads used
              // to reach a server ask he had no way to answer from here.
              _CardAction(
                label: AppHelpers.getTranslation('add_poi'),
                actionKey: 'driverLoadAddPoi-${load.id}',
                enabled: true,
                onTap: () => AddPoiSheet.open(context, shop: load.shopId),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// "3 lines · 12 on the van", plus the server's own word for the load's
  /// state when it sent one.
  String _subLine() {
    final parts = <String>[
      '${load.lines.length} '
          '${AppHelpers.getTranslation(load.lines.length == 1 ? 'line' : 'lines')}',
      '${loadQtyText(load.remainingQtyTotal)} '
          '${AppHelpers.getTranslation('on_the_van')}',
    ];
    final status = load.loadStatus;
    if (status != null && status.isNotEmpty) {
      parts.add(AppHelpers.getTranslation(status));
    }
    return parts.join(' · ');
  }
}

class _CardAction extends StatelessWidget {
  const _CardAction({
    required this.label,
    required this.actionKey,
    required this.enabled,
    required this.onTap,
    this.primary = false,
  });

  final String label;
  final String actionKey;
  final bool enabled;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final background = primary ? AppStyle.primary : AppStyle.cardAltFor(Theme.of(context).brightness);
    final textColor = primary ? AppStyle.blackColor : AppStyle.inkFor(Theme.of(context).brightness);
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(10.r),
        child: InkWell(
          key: Key(actionKey),
          borderRadius: BorderRadius.circular(10.r),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            child: Text(
              label,
              style: AppStyle.interSemi(size: 13, color: textColor),
            ),
          ),
        ),
      ),
    );
  }
}
