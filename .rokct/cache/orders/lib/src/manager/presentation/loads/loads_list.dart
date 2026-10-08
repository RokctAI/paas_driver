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

// THE SHOP'S LOADS, in the standard list language (approved design strip
// section 38: "33 list language = STANDARD for all lists").
//
// Header with the count pill and the Issue-load action, the two real
// statuses as filter tabs (Open / Closed, each with its own count off its
// own `get_shop_loads(status)` call), and the load cards in plane-aligned
// columns. A card carries the four facts the shop reads a load by: the
// driver it went to, when it went out, how many lines it carries, and how
// much of what was issued is still on the van.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:base_sdk/src/presentation/components/lists/list_language.dart';
import 'package:base_sdk/src/presentation/components/lists/list_plane_flow.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:orders_sdk/src/manager/application/loads/shop_loads_provider.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/data/load_data.dart';

import 'load_keys.dart';
import 'package:remixicon/remixicon.dart';

/// The two statuses a load can be in, in the order the list shows them.
const List<String> kShopLoadStatuses = <String>[
  kLoadStatusOpen,
  kLoadStatusClosed,
];

/// The tab colour for a load status: open loads carry the brand accent the
/// board gives live work, closed ones the settled green.
Color loadStatusColor(String status) =>
    status == kLoadStatusClosed ? AppStyle.green : AppStyle.primary;

/// The list body: header, status tabs, cards.
class LoadsList extends ConsumerStatefulWidget {
  /// Tapping a card. On planes the host pushes the detail PANE; on a
  /// phone it opens the detail sheet.
  final void Function(LoadData load) onOpenDetail;

  /// The header's Issue-load action — the host wires it to /load/issue.
  final VoidCallback onIssueLoad;

  /// The load whose detail holds the last plane (brand border).
  final String? selectedLoadId;

  /// Phone shape: one column, compact header metrics.
  final bool compact;

  const LoadsList({
    super.key,
    required this.onOpenDetail,
    required this.onIssueLoad,
    this.selectedLoadId,
    this.compact = false,
  });

  @override
  ConsumerState<LoadsList> createState() => LoadsListState();
}

class LoadsListState extends ConsumerState<LoadsList> {
  int _activeIndex = 0;

  String get activeStatus => kShopLoadStatuses[_activeIndex];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(shopLoadsProvider.notifier).fetchLoads();
    });
  }

  List<LoadData> _bucket(String status) {
    final state = ref.watch(shopLoadsProvider);
    return status == kLoadStatusClosed ? state.closedLoads : state.openLoads;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shopLoadsProvider);
    final List<LoadData> rows = _bucket(activeStatus);
    final int totalCount = state.openLoads.length + state.closedLoads.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListScreenHeader(
          compact: widget.compact,
          title: AppHelpers.getTranslation(LoadKeys.loads),
          countPill: ListCountPill(
            label:
                '$totalCount '
                '${AppHelpers.getTranslation(LoadKeys.loads).toLowerCase()}',
          ),
          actions: [
            ListRoundAction(
              icon: Remix.add_line,
              tooltip: AppHelpers.getTranslation(LoadKeys.issueLoad),
              onTap: widget.onIssueLoad,
            ),
          ],
        ),
        ListFilterTabBar(
          activeIndex: _activeIndex,
          onSelect: (index) => setState(() => _activeIndex = index),
          tabs: [
            for (final status in kShopLoadStatuses)
              ListFilterTab(
                label: AppHelpers.getTranslation(
                  status == kLoadStatusClosed
                      ? LoadKeys.closedLoads
                      : LoadKeys.openLoads,
                ),
                color: loadStatusColor(status),
                count: _bucket(status).length,
              ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: state.isLoading && rows.isEmpty
              ? const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : rows.isEmpty
              ? Center(
                  child: Text(
                    AppHelpers.getTranslation(LoadKeys.noLoads),
                    style: AppStyle.interNormal(
                      size: 12,
                      color: AppStyle.secondaryInkFor(
                        Theme.of(context).brightness,
                      ),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(shopLoadsProvider.notifier).fetchLoads(),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    children: [
                      ListPlaneColumns(
                        children: [
                          for (final load in rows)
                            LoadCard(
                              load: load,
                              selected:
                                  widget.selectedLoadId != null &&
                                  widget.selectedLoadId == load.id,
                              onTap: () => widget.onOpenDetail(load),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

/// One load on the list: driver, when it went out, how many lines, and
/// what is still on the van against what was issued.
class LoadCard extends StatelessWidget {
  final LoadData load;
  final bool selected;
  final VoidCallback onTap;

  const LoadCard({
    super.key,
    required this.load,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = loadStatusColor(load.loadStatus);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.fromLTRB(6, 0, 6, 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppStyle.cardFor(Theme.of(context).brightness),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppStyle.primary
                : AppStyle.subtleStrokeFor(Theme.of(context).brightness),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    load.deliveryman?.name ?? load.id,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyle.interSemi(
                      size: 14,
                      color: AppStyle.inkFor(Theme.of(context).brightness),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_trim(load.remainingQty)} / ${_trim(load.issuedQty)}',
                  style: AppStyle.interSemi(size: 13, color: accent),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _secondLine(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppStyle.interNormal(
                size: 12,
                color: AppStyle.secondaryInkFor(Theme.of(context).brightness),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _secondLine() {
    final parts = <String>[
      '${load.lines.length} '
          '${AppHelpers.getTranslation(LoadKeys.linesOnLoad).toLowerCase()}',
      '${_trim(load.remainingQty)} '
          '${AppHelpers.getTranslation(LoadKeys.remainingOfIssued).toLowerCase()}'
          ' ${_trim(load.issuedQty)}',
    ];
    final DateTime? stamp = load.isClosed ? load.closedAt : load.createdAt;
    if (stamp != null) {
      parts.insert(
        0,
        '${AppHelpers.getTranslation(load.isClosed ? LoadKeys.closedOn : LoadKeys.issuedOn)} '
        '${DateFormat('d MMM · HH:mm').format(stamp)}',
      );
    }
    return parts.join(' · ');
  }
}

/// A quantity the way a shelf reads it: whole numbers stay whole.
String _trim(num value) => value == value.roundToDouble()
    ? value.round().toString()
    : value.toStringAsFixed(2);

/// Public alias so the detail table and the issue screen format the same
/// way as the cards.
String formatLoadQuantity(num value) => _trim(value);
