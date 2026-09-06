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

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:orders_sdk/src/manager/application/orders/accepted/accepted_orders_provider.dart';
import 'package:orders_sdk/src/manager/application/orders/cooking/cooking_orders_provider.dart';
import 'package:orders_sdk/src/manager/application/orders/new/new_orders_provider.dart';
import 'package:orders_sdk/src/manager/application/orders/on_a_way/on_a_way_orders_provider.dart';
import 'package:orders_sdk/src/manager/application/orders/ready/ready_orders_provider.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';

import '../board/board_column.dart';
import '../board/board_status.dart';

/// Chip 675 (frame 37a): the yielded orders board — the ALL-declaring
/// workspace of section 33 compressed onto ONE plane. Its columns fold to
/// a single rail of mini cards under their colour-coded headers with the
/// count pills, still readable, one Back away. It reads the same queue
/// providers the board already fetched (the workspace beneath this route
/// keeps them warm), so nothing is refetched to draw it; nothing on it is
/// tappable — Back is how the board comes back.
///
/// Active columns only (New / Accepted / Cooking / Ready / On the way, the
/// waiter rule hiding On the way); a column with nothing in it is not
/// drawn, so the rail is as tall as the work it holds.
class WalkInBoardRail extends ConsumerWidget {
  const WalkInBoardRail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? role = LocalStorage.getUser()?.role;
    final newState = ref.watch(newOrdersProvider);
    final acceptedState = ref.watch(acceptedOrdersProvider);
    final cookingState = ref.watch(cookingOrdersProvider);
    final readyState = ref.watch(readyOrdersProvider);
    final onWayState = ref.watch(onAWayOrdersProvider);
    final sections = <_RailSection>[
      _RailSection(BoardStatus.newOrder, newState.orders, newState.totalCount),
      _RailSection(
        BoardStatus.accepted,
        acceptedState.orders,
        acceptedState.totalCount,
      ),
      _RailSection(
        BoardStatus.cooking,
        cookingState.orders,
        cookingState.totalCount,
      ),
      _RailSection(BoardStatus.ready, readyState.orders, readyState.totalCount),
      if (role != BoardRules.waiterRole)
        _RailSection(
          BoardStatus.onWay,
          onWayState.orders,
          onWayState.totalCount,
        ),
    ].where((s) => s.orders.isNotEmpty).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
      physics: const BouncingScrollPhysics(),
      children: [
        Text(
          AppHelpers.getTranslation(TrKeys.orders),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppStyle.interSemi(size: 24, color: AppStyle.textPrimary),
        ),
        if (sections.isEmpty) ...[
          const SizedBox(height: 24),
          // 'no_orders' is a manifest-declared key; lib/ reads it by wire
          // string (the board card's 'no_name' precedent).
          Text(
            AppHelpers.getTranslation('no_orders'),
            style: AppStyle.interNormal(
              size: 13,
              color: AppStyle.textDarkSecondary,
            ),
          ),
        ],
        for (final section in sections) ...[
          const SizedBox(height: 24),
          _RailHeader(section: section),
          const SizedBox(height: 12),
          for (final order in section.orders) _RailCard(order: order),
        ],
      ],
    );
  }
}

class _RailSection {
  final BoardStatus status;
  final List<OrderData> orders;
  final int count;

  const _RailSection(this.status, this.orders, this.count);
}

/// The colour-coded column head folded to a rail heading: status dot,
/// the column title (the wire key through getTranslation, as the board
/// names its columns) and the board's own count pill.
class _RailHeader extends StatelessWidget {
  final _RailSection section;

  const _RailHeader({required this.section});

  @override
  Widget build(BuildContext context) {
    final Color color = section.status.color;
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            AppHelpers.getTranslation(section.status.wire),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppStyle.interSemi(size: 15, color: color),
          ),
        ),
        const SizedBox(width: 8),
        BoardCountPill(
          status: section.status,
          count: section.count > 0 ? section.count : section.orders.length,
        ),
      ],
    );
  }
}

/// One mini order card: number and total on the first line, customer and
/// payment on the second — the board card's facts, folded to two lines.
class _RailCard extends StatelessWidget {
  final OrderData order;

  const _RailCard({required this.order});

  String get _name {
    final first = order.user?.firstname ?? AppHelpers.getTranslation('no_name');
    final last = order.user?.lastname ?? '';
    return '$first $last'.trim();
  }

  String? get _payment {
    final tag = order.transaction?.paymentSystem?.tag;
    if (tag == null || tag.isEmpty) return null;
    return AppHelpers.getTranslation(tag);
  }

  @override
  Widget build(BuildContext context) {
    final payment = _payment;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppStyle.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppStyle.strokeDarkSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '№ ${order.id ?? ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyle.interSemi(
                    size: 14,
                    color: AppStyle.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                AppHelpers.numberFormat(
                  number: order.totalPrice ?? 0,
                  symbol: order.currency?.symbol,
                ),
                style: AppStyle.interSemi(
                  size: 14,
                  color: AppStyle.textDarkSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            payment == null ? _name : '$_name · $payment',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppStyle.interNormal(
              size: 12.5,
              color: AppStyle.textDarkSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
