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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:base_sdk/src/presentation/adaptive/planes.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:kitchen_sdk/src/manager/application/kitchen/kitchen_provider.dart';
import 'package:kitchen_sdk/src/manager/presentation/kitchen/kitchen_detail_page.dart';
import 'package:kitchen_sdk/src/manager/presentation/kitchen/kitchen_order_card.dart';
import 'package:kitchen_sdk/src/manager/presentation/kitchen/kitchen_status.dart';

/// The kitchen queue workspace (the plane flow's root): header with the
/// live count, search and the chime bell; the POS filter chips with
/// counts; the order cards — a grid two cards per granted plane on wide
/// windows (34a: four a row when the queue holds two planes), the
/// full-width card list on phones (34b); and the board's "View more · +N"
/// paging control.
class KitchenQueueView extends ConsumerStatefulWidget {
  const KitchenQueueView({super.key});

  @override
  ConsumerState<KitchenQueueView> createState() => _KitchenQueueViewState();
}

class _KitchenQueueViewState extends ConsumerState<KitchenQueueView> {
  bool _searching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kitchenProvider);
    final planes = Planes.maybeOf(context);
    final bool wide = (planes?.count ?? 1) > 1;

    // Wide-screen auto-select (POS auto-select of the first order): the
    // detail plane stays filled, so the approved 34a never shows a bare
    // stage. Never on a phone — there a selection pushes a page.
    if (wide && state.selectedId == null && state.orders.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(kitchenProvider.notifier).autoSelectFirst();
      });
    }

    // Two cards per plane granted to the queue (34a: 4-per-row on two
    // planes); the phone keeps the single-column list.
    final int columns = wide ? 2 * (planes?.span ?? 1) : 1;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(liveCount: state.countOf(KitchenFilter.all)),
          const SizedBox(height: 12),
          _filterChips(),
          const SizedBox(height: 12),
          Expanded(
            child: state.isLoading && state.orders.isEmpty
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : state.orders.isEmpty
                ? Center(
                    child: Text(
                      AppHelpers.getTranslation('no_orders'),
                      style: AppStyle.interNormal(
                        size: 12,
                        color: AppStyle.textDarkSecondary,
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async => ref
                        .read(kitchenProvider.notifier)
                        .fetchOrders(isRefresh: true),
                    child: columns == 1
                        ? _phoneList()
                        : _grid(columns: columns),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _header({required int liveCount}) {
    final notifier = ref.read(kitchenProvider.notifier);
    final hasActivity = ref.watch(
      kitchenProvider.select((s) => s.hasNewActivity),
    );
    return Row(
      children: [
        Text(
          AppHelpers.getTranslation('kitchen'),
          style: AppStyle.interBold(size: 22, color: AppStyle.textPrimary),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: AppStyle.strokeDark),
          ),
          child: Text(
            '$liveCount ${AppHelpers.getTranslation('live')}',
            style: AppStyle.interNormal(
              size: 11,
              color: AppStyle.textDarkSecondary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        // The POS notifier carries an order-number query; the POS page
        // showed no box of its own (it lived on the scaffold), so the
        // manager screen folds it behind a header toggle.
        Expanded(
          child: _searching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: notifier.setQuery,
                  style: AppStyle.interNormal(
                    size: 13,
                    color: AppStyle.textPrimary,
                  ),
                  cursorColor: AppStyle.primary,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: AppHelpers.getTranslation(TrKeys.search),
                    hintStyle: AppStyle.interNormal(
                      size: 13,
                      color: AppStyle.textDarkFaint,
                    ),
                    border: InputBorder.none,
                  ),
                )
              : const SizedBox.shrink(),
        ),
        _iconButton(
          icon: _searching ? Icons.close : Icons.search,
          onTap: () {
            setState(() => _searching = !_searching);
            if (!_searching) {
              _searchController.clear();
              notifier.setQuery('');
            }
          },
        ),
        const SizedBox(width: 8),
        _iconButton(
          icon: Icons.notifications_none,
          dot: hasActivity,
          onTap: notifier.clearActivity,
        ),
      ],
    );
  }

  Widget _iconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool dot = false,
  }) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppStyle.cardDark,
          shape: BoxShape.circle,
          border: Border.all(color: AppStyle.strokeDark),
        ),
        child: Stack(
          children: [
            Center(child: Icon(icon, size: 16, color: AppStyle.textPrimary)),
            if (dot)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppStyle.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _filterChips() {
    final state = ref.watch(kitchenProvider);
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final filter in KitchenFilter.values)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: InkWell(
                onTap: () =>
                    ref.read(kitchenProvider.notifier).selectFilter(filter),
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: state.filter == filter
                        ? AppStyle.primary
                        : AppStyle.cardDark,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: state.filter == filter
                          ? AppStyle.primary
                          : AppStyle.strokeDark,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppHelpers.getTranslation(filter.labelKey),
                        style: state.filter == filter
                            ? AppStyle.interSemi(
                                size: 12,
                                color: AppStyle.textPrimary,
                              )
                            : AppStyle.interNormal(
                                size: 12,
                                color: AppStyle.textDarkSecondary,
                              ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: state.filter == filter
                              ? Colors.black.withValues(alpha: 0.22)
                              : AppStyle.cardDarkAlt,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          '${state.countOf(filter)}',
                          style: AppStyle.interSemi(
                            size: 10.5,
                            color: state.filter == filter
                                ? AppStyle.textPrimary
                                : AppStyle.textDarkFaint,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _viewMore() {
    final moreCount = ref.watch(kitchenProvider.select((s) => s.moreCount));
    if (moreCount <= 0) return const SizedBox.shrink();
    return InkWell(
      onTap: () => ref.read(kitchenProvider.notifier).fetchOrders(),
      borderRadius: BorderRadius.circular(100),
      child: Container(
        height: 34,
        margin: const EdgeInsets.fromLTRB(6, 4, 6, 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppStyle.strokeDark),
        ),
        child: Center(
          child: Text(
            '${AppHelpers.getTranslation('view_more')}  ·  +$moreCount',
            style: AppStyle.interSemi(
              size: 11.5,
              color: AppStyle.textDarkSecondary,
            ),
          ),
        ),
      ),
    );
  }

  /// Phone tap (34c): select, then PUSH the detail as a real route — it
  /// covers the home shell including its centered floating nav, which is
  /// the 12:36Z nav-fold moment; the route carries the corner back pill.
  /// The selection clears when the route pops, however it pops.
  Future<void> _openPhoneDetail(BuildContext context, String? orderId) async {
    final notifier = ref.read(kitchenProvider.notifier);
    notifier.selectOrder(orderId);
    await KitchenDetailPage.push(context);
    notifier.selectOrder(null);
  }

  Widget _phoneList() {
    final state = ref.watch(kitchenProvider);
    return ListView(
      padding: const EdgeInsets.only(bottom: 90),
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      children: [
        for (final order in state.orders)
          KitchenOrderCard(
            order: order,
            compact: true,
            selected: order.id == state.selectedId,
            onTap: () => _openPhoneDetail(context, order.id),
          ),
        _viewMore(),
      ],
    );
  }

  Widget _grid({required int columns}) {
    final state = ref.watch(kitchenProvider);
    final notifier = ref.read(kitchenProvider.notifier);
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 6),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              mainAxisExtent: 168,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final order = state.orders[index];
                return KitchenOrderCard(
                  order: order,
                  selected: order.id == state.selectedId,
                  onTap: () => notifier.selectOrder(order.id),
                );
              },
              childCount: state.orders.length,
            ),
          ),
        ),
        SliverToBoxAdapter(child: _viewMore()),
        const SliverPadding(padding: EdgeInsets.only(bottom: 84)),
      ],
    );
  }
}
