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

// THE SHOP'S OWN DRIVERS — the roster behind /load/drivers.
//
// Drawn in the standard list language (approved design strip section 38),
// the same header + count pill + round action the loads list uses, because
// it is the same shop reading the same kind of list one screen over.
//
// The screen says out loud what the roster DOES, because it changes what
// the issue-a-load picker will offer: a shop with its own drivers can only
// load those drivers. That is the whole consequence of the button, so it
// sits under the title rather than in a help sheet nobody opens.
//
// The body is package code (so it is widget-tested at every width) and the
// installed page is the host shell that routes to it.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:base_sdk/src/presentation/components/lists/list_language.dart';
import 'package:base_sdk/src/presentation/components/text_fields/search_text_field.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:orders_sdk/src/manager/application/drivers/shop_drivers_provider.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/data/load_data.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/data/shop_driver.dart';

import 'driver_keys.dart';
import 'package:remixicon/remixicon.dart';

/// The roster body: the shop's own drivers, one removable row each, and the
/// one action that opens the add flow.
class ShopDriversBody extends ConsumerStatefulWidget {
  /// Phone shape: one column, compact header metrics.
  final bool compact;

  /// How the add flow is presented. The host owns presentation, so the
  /// default (a modal sheet over this body) is overridable and the widget
  /// tests drive it directly.
  final Future<void> Function(BuildContext context)? openAddFlow;

  const ShopDriversBody({super.key, this.compact = false, this.openAddFlow});

  @override
  ConsumerState<ShopDriversBody> createState() => ShopDriversBodyState();
}

class ShopDriversBodyState extends ConsumerState<ShopDriversBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(shopDriversProvider.notifier).fetchDrivers();
    });
  }

  void _say(String key) {
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(AppHelpers.getTranslation(key))));
  }

  Future<void> _add() async {
    final Future<void> Function(BuildContext)? open = widget.openAddFlow;
    if (open != null) {
      await open(context);
      return;
    }
    showAddShopDriverSheet(context);
  }

  Future<void> _remove(ShopDriver driver) async {
    final bool confirmed = await showRemoveShopDriverDialog(context, driver);
    if (!confirmed || !mounted) return;
    final bool removed = await ref
        .read(shopDriversProvider.notifier)
        .removeDriver(driver.id);
    if (!mounted) return;
    _say(removed ? DriverKeys.driverRemoved : DriverKeys.couldNotRemoveDriver);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shopDriversProvider);
    final List<ShopDriver> rows = state.drivers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListScreenHeader(
          compact: widget.compact,
          title: AppHelpers.getTranslation(DriverKeys.myDrivers),
          countPill: ListCountPill(
            label:
                '${state.activeDrivers.length} '
                '${AppHelpers.getTranslation(DriverKeys.drivers).toLowerCase()}',
          ),
          hint: AppHelpers.getTranslation(DriverKeys.ownDriversExplainer),
          actions: [
            ListRoundAction(
              icon: Remix.user_add_line,
              tooltip: AppHelpers.getTranslation(DriverKeys.addDriver),
              onTap: _add,
            ),
          ],
        ),
        Expanded(
          child: Builder(
            builder: (context) {
              if (state.isLoading && rows.isEmpty) {
                return const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              if (state.hasFailed && rows.isEmpty) {
                return _Notice(
                  text: AppHelpers.getTranslation(
                    DriverKeys.couldNotReadYourDrivers,
                  ),
                );
              }
              if (rows.isEmpty) {
                return _Notice(
                  text: AppHelpers.getTranslation(DriverKeys.noOwnDriversYet),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: rows.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final ShopDriver driver = rows[index];
                  return ShopDriverRow(
                    driver: driver,
                    isBusy: state.pendingId == driver.id,
                    onRemove: () => _remove(driver),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// One roster row: who the driver is, and the one way off the roster.
class ShopDriverRow extends StatelessWidget {
  final ShopDriver driver;
  final bool isBusy;
  final VoidCallback onRemove;

  const ShopDriverRow({
    super.key,
    required this.driver,
    required this.onRemove,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppStyle.cardFor(Theme.of(context).brightness),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppStyle.subtleStrokeFor(Theme.of(context).brightness),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyle.interSemi(
                    size: 14,
                    color: AppStyle.inkFor(Theme.of(context).brightness),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  driver.active
                      ? driver.id
                      : '${driver.id} · '
                            '${AppHelpers.getTranslation(DriverKeys.retired)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyle.interNormal(
                    size: 11.5,
                    color: AppStyle.secondaryInkFor(
                      Theme.of(context).brightness,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isBusy)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              onPressed: onRemove,
              tooltip: AppHelpers.getTranslation(DriverKeys.removeDriver),
              icon: Icon(Remix.user_minus_line, color: AppStyle.red),
            ),
        ],
      ),
    );
  }
}

/// The add flow: search the platform driver list, tap one, it goes on.
///
/// The candidates come from the load module's `list_shop_deliverymen` — the
/// same list the issue-a-load picker draws — minus whoever is already on
/// the roster. That backend narrows to the roster once a shop HAS one, so
/// this list can legitimately come back empty; it says so rather than
/// showing a spinner forever.
class AddShopDriverSheet extends ConsumerStatefulWidget {
  const AddShopDriverSheet({super.key});

  @override
  ConsumerState<AddShopDriverSheet> createState() => AddShopDriverSheetState();
}

class AddShopDriverSheetState extends ConsumerState<AddShopDriverSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(shopDriversProvider.notifier).fetchCandidates();
    });
  }

  Future<void> _pick(LoadDeliveryman driver) async {
    final bool added = await ref
        .read(shopDriversProvider.notifier)
        .addDriver(driver.id);
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(
          AppHelpers.getTranslation(
            added ? DriverKeys.driverAdded : DriverKeys.couldNotAddDriver,
          ),
        ),
      ),
    );
    if (added) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shopDriversProvider);
    final List<LoadDeliveryman> rows = state.addableCandidates;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppHelpers.getTranslation(DriverKeys.addDriver),
            style: AppStyle.interSemi(
              size: 18,
              color: AppStyle.inkFor(Theme.of(context).brightness),
            ),
          ),
          const SizedBox(height: 12),
          SearchTextField(
            hintText: AppHelpers.getTranslation(DriverKeys.searchDrivers),
            bgColor: AppStyle.cardFor(Theme.of(context).brightness),
            isBorder: true,
            onChanged: (value) =>
                ref.read(shopDriversProvider.notifier).setQuery(value),
          ),
          const SizedBox(height: 12),
          if (state.isLoadingCandidates && state.candidates.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (rows.isEmpty)
            _Notice(text: AppHelpers.getTranslation(DriverKeys.noDriversToAdd))
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: rows.length,
                separatorBuilder: (context, index) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final LoadDeliveryman driver = rows[index];
                  final bool busy = state.pendingId == driver.id;
                  return InkWell(
                    onTap: busy ? null : () => _pick(driver),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppStyle.cardFor(Theme.of(context).brightness),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppStyle.strokeFor(
                            Theme.of(context).brightness,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              driver.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppStyle.interSemi(
                                size: 13.5,
                                color: AppStyle.inkFor(
                                  Theme.of(context).brightness,
                                ),
                              ),
                            ),
                          ),
                          if (busy)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            Icon(Remix.add_line, color: AppStyle.primary, size: 20),
                        ],
                      ),
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

/// A plain sentence where a list would be: the roster's empty, failed and
/// nothing-left-to-add states all read the same way.
class _Notice extends StatelessWidget {
  final String text;

  const _Notice({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppStyle.interNormal(
          size: 13,
          color: AppStyle.secondaryInkFor(Theme.of(context).brightness),
        ),
      ),
    );
  }
}

/// Opens the add flow as a sheet over whatever is showing.
void showAddShopDriverSheet(BuildContext context) {
  AppHelpers.showCustomModalBottomSheet(
    context: context,
    modal: const AddShopDriverSheet(),
    isDarkMode: true,
    radius: 12,
  );
}

/// Removing a driver is a decision about future loads, not a tidy-up, so it
/// is confirmed and the confirmation says what stops working.
Future<bool> showRemoveShopDriverDialog(
  BuildContext context,
  ShopDriver driver,
) async {
  final bool? answer = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppStyle.cardFor(Theme.of(context).brightness),
      title: Text(
        AppHelpers.getTranslation(DriverKeys.removeDriverFromRoster),
        style: AppStyle.interSemi(
          size: 16,
          color: AppStyle.inkFor(Theme.of(context).brightness),
        ),
      ),
      content: Text(
        '${driver.name} — '
        '${AppHelpers.getTranslation(DriverKeys.theyCanNoLongerBeLoaded)}',
        style: AppStyle.interNormal(
          size: 13,
          color: AppStyle.secondaryInkFor(Theme.of(context).brightness),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            AppHelpers.getTranslation(DriverKeys.cancel),
            style: AppStyle.interNormal(
              size: 13,
              color: AppStyle.secondaryInkFor(Theme.of(context).brightness),
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            AppHelpers.getTranslation(DriverKeys.removeDriver),
            style: AppStyle.interSemi(size: 13, color: AppStyle.red),
          ),
        ),
      ],
    ),
  );
  return answer ?? false;
}
