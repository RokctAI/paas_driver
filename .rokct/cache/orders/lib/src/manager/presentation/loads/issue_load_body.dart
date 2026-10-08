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

// ISSUE A LOAD — /load/issue: pick the driver, pick the shelf rows and
// their quantities, read the load back, send it.
//
// The PRODUCT PICKER is not a new one. The manager create-order flow's
// picker (search field, category chips, the ProductsBody rows) is host
// composition code — it installs into the app and imports the host's own
// components — so this body takes it as a slot: the installed page hands
// the picker in, and every tap comes back through [onPickProduct] as the
// ProductData the same rows already carry. All the arithmetic stays here,
// where it is testable.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:orders_sdk/src/manager/application/loads/issue_load_provider.dart';
import 'package:orders_sdk/src/manager/application/loads/shop_loads_provider.dart';
import 'package:orders_sdk/src/manager/domain/load_draft.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/data/load_data.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/data/product_data.dart';
import 'package:orders_sdk/src/manager/presentation/drivers/driver_keys.dart';

import 'load_keys.dart';
import 'loads_list.dart';
import 'package:remixicon/remixicon.dart';

/// The issue-load body. [pickerBuilder] draws the host's product picker
/// and calls the callback it is handed for every product tapped.
class IssueLoadBody extends ConsumerStatefulWidget {
  final Widget Function(
    BuildContext context,
    void Function(ProductData product) onPickProduct,
  )
  pickerBuilder;

  /// The load that was issued; the host takes the shop to its detail.
  final void Function(LoadData load) onIssued;

  /// Opens the shop's own-driver roster (/load/drivers). The picker above
  /// offers exactly what that roster allows, so the way to change what is
  /// on offer belongs next to it rather than three screens away. The host
  /// owns routing, so it is a callback; left null the action is absent and
  /// the picker is unchanged, which is what a host that has not installed
  /// the roster page gets.
  final Future<void> Function()? onManageDrivers;

  const IssueLoadBody({
    super.key,
    required this.pickerBuilder,
    required this.onIssued,
    this.onManageDrivers,
  });

  @override
  ConsumerState<IssueLoadBody> createState() => _IssueLoadBodyState();
}

class _IssueLoadBodyState extends ConsumerState<IssueLoadBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(issueLoadProvider.notifier).fetchDrivers();
    });
  }

  /// Off to the roster and back. The picker is refetched on return because
  /// the roster is exactly what it lists: a driver added there has to show
  /// up here without the shop leaving the screen and coming back.
  Future<void> _manageDrivers() async {
    await widget.onManageDrivers?.call();
    if (!mounted) return;
    await ref.read(issueLoadProvider.notifier).fetchDrivers();
  }

  Future<void> _issue() async {
    final LoadData? load = await ref.read(issueLoadProvider.notifier).issue();
    if (!mounted) return;
    if (load == null) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(AppHelpers.getTranslation(LoadKeys.couldNotIssueLoad)),
        ),
      );
      return;
    }
    // The list the shop comes back to already carries it, without a
    // second round trip: `create_load` answered the whole load.
    ref.read(shopLoadsProvider.notifier).addIssuedLoad(load);
    widget.onIssued(load);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(issueLoadProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Text(
            AppHelpers.getTranslation(LoadKeys.issueLoad),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppStyle.interSemi(size: 24, color: AppStyle.inkFor(Theme.of(context).brightness)),
          ),
        ),
        const SizedBox(height: 14),
        DeliverymanPicker(
          drivers: state.drivers,
          selectedId: state.deliverymanId,
          isLoading: state.isLoadingDrivers,
          onSelect: (id) =>
              ref.read(issueLoadProvider.notifier).selectDeliveryman(id),
          onManageDrivers: widget.onManageDrivers == null
              ? null
              : _manageDrivers,
        ),
        const SizedBox(height: 14),
        Expanded(
          child: widget.pickerBuilder(
            context,
            (product) => ref.read(issueLoadProvider.notifier).addProduct(product),
          ),
        ),
        LoadDraftReview(
          lines: state.lines,
          onSetQuantity: (line, quantity) =>
              ref.read(issueLoadProvider.notifier).setQuantity(line, quantity),
          canIssue: state.canIssue,
          isSubmitting: state.isSubmitting,
          onIssue: _issue,
        ),
      ],
    );
  }
}

/// The driver row: every driver the shop may load, one tap each.
class DeliverymanPicker extends StatelessWidget {
  final List<LoadDeliveryman> drivers;
  final String? selectedId;
  final bool isLoading;
  final ValueChanged<String> onSelect;

  /// "Manage drivers": opens the shop's own-driver roster. Null when the
  /// host has not wired it, and then nothing is drawn for it.
  final VoidCallback? onManageDrivers;

  const DeliverymanPicker({
    super.key,
    required this.drivers,
    required this.onSelect,
    this.selectedId,
    this.isLoading = false,
    this.onManageDrivers,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 16, end: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  AppHelpers.getTranslation(LoadKeys.chooseADeliveryman),
                  style: AppStyle.interNormal(
                    size: 12,
                    color: AppStyle.secondaryInkFor(Theme.of(context).brightness),
                  ),
                ),
              ),
              if (onManageDrivers != null)
                TextButton(
                  onPressed: onManageDrivers,
                  child: Text(
                    AppHelpers.getTranslation(DriverKeys.manageDrivers),
                    style: AppStyle.interSemi(
                      size: 12,
                      color: AppStyle.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (isLoading && drivers.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (drivers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              AppHelpers.getTranslation(LoadKeys.noDeliverymenOnFile),
              style: AppStyle.interNormal(
                size: 12,
                color: AppStyle.secondaryInkFor(Theme.of(context).brightness),
              ),
            ),
          )
        else
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: drivers.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final driver = drivers[index];
                final bool active = driver.id == selectedId;
                return InkWell(
                  onTap: () => onSelect(driver.id),
                  borderRadius: BorderRadius.circular(100),
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: active ? AppStyle.primary : AppStyle.cardFor(Theme.of(context).brightness),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: active ? AppStyle.primary : AppStyle.strokeFor(Theme.of(context).brightness),
                      ),
                    ),
                    child: Text(
                      driver.name,
                      style: AppStyle.interSemi(
                        size: 12.5,
                        color: active
                            ? AppStyle.inkFor(Theme.of(context).brightness)
                            : AppStyle.inkFor(Theme.of(context).brightness),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

/// The review foot: what is on the load, what it is worth at shelf prices,
/// and the one button that sends it.
class LoadDraftReview extends StatelessWidget {
  final List<LoadDraftLine> lines;
  final void Function(LoadDraftLine line, num quantity) onSetQuantity;
  final bool canIssue;
  final bool isSubmitting;
  final VoidCallback onIssue;

  const LoadDraftReview({
    super.key,
    required this.lines,
    required this.onSetQuantity,
    required this.canIssue,
    required this.isSubmitting,
    required this.onIssue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppStyle.cardFor(Theme.of(context).brightness),
        border: Border(top: BorderSide(color: AppStyle.subtleStrokeFor(Theme.of(context).brightness))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppHelpers.getTranslation(LoadKeys.onTheLoad),
                  style: AppStyle.interNormal(
                    size: 12,
                    color: AppStyle.secondaryInkFor(Theme.of(context).brightness),
                  ),
                ),
              ),
              Text(
                '${AppHelpers.getTranslation(LoadKeys.loadValue)} '
                '${AppHelpers.numberFormat(number: draftLoadValue(lines))}',
                style: AppStyle.interSemi(
                  size: 13,
                  color: AppStyle.inkFor(Theme.of(context).brightness),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (lines.isEmpty)
            Text(
              AppHelpers.getTranslation(LoadKeys.tapAProductToPutItOnTheLoad),
              style: AppStyle.interNormal(
                size: 12,
                color: AppStyle.secondaryInkFor(Theme.of(context).brightness),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 168),
              child: ListView(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                children: [
                  for (final line in lines)
                    LoadDraftLineRow(
                      line: line,
                      onSetQuantity: (quantity) =>
                          onSetQuantity(line, quantity),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          InkWell(
            onTap: canIssue ? onIssue : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: canIssue ? AppStyle.primary : AppStyle.strokeFor(Theme.of(context).brightness),
                borderRadius: BorderRadius.circular(12),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      AppHelpers.getTranslation(LoadKeys.issueToDriver),
                      style: AppStyle.interSemi(
                        size: 15,
                        color: canIssue
                            ? AppStyle.blackColor
                            : AppStyle.secondaryInkFor(Theme.of(context).brightness),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppHelpers.getTranslation(
              LoadKeys.issuingTakesTheStockOffTheShelf,
            ),
            textAlign: TextAlign.center,
            style: AppStyle.interNormal(
              size: 11,
              color: AppStyle.secondaryInkFor(Theme.of(context).brightness),
            ),
          ),
        ],
      ),
    );
  }
}

/// One drafted line with its stepper; the plus stops at what the shelf
/// holds, because issuing is what takes the goods off it.
class LoadDraftLineRow extends StatelessWidget {
  final LoadDraftLine line;
  final ValueChanged<num> onSetQuantity;

  const LoadDraftLineRow({
    super.key,
    required this.line,
    required this.onSetQuantity,
  });

  @override
  Widget build(BuildContext context) {
    final bool atCeiling =
        line.available > 0 && line.quantity >= line.available;
    Widget step({
      required IconData icon,
      required VoidCallback? onTap,
    }) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppStyle.strokeFor(Theme.of(context).brightness)),
        ),
        child: Icon(
          icon,
          size: 15,
          color: onTap == null
              ? AppStyle.faintFor(Theme.of(context).brightness)
              : AppStyle.inkFor(Theme.of(context).brightness),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyle.interSemi(
                    size: 13,
                    color: AppStyle.inkFor(Theme.of(context).brightness),
                  ),
                ),
                Text(
                  '${AppHelpers.numberFormat(number: line.unitPrice)} · '
                  '${AppHelpers.getTranslation(LoadKeys.onHand)} '
                  '${formatLoadQuantity(line.available)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyle.interNormal(
                    size: 11,
                    color: AppStyle.secondaryInkFor(Theme.of(context).brightness),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          step(
            icon: Remix.subtract_line,
            onTap: () => onSetQuantity(line.quantity - 1),
          ),
          SizedBox(
            width: 40,
            child: Text(
              formatLoadQuantity(line.quantity),
              textAlign: TextAlign.center,
              style: AppStyle.interSemi(
                size: 14,
                color: AppStyle.inkFor(Theme.of(context).brightness),
              ),
            ),
          ),
          step(
            icon: Remix.add_line,
            onTap: atCeiling
                ? null
                : () => onSetQuantity(line.quantity + 1),
          ),
        ],
      ),
    );
  }
}
