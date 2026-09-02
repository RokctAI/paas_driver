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

import 'package:kitchen_sdk/src/manager/presentation/kitchen/kitchen_status.dart';

/// One dish line of a kitchen order (an Order Item child row plus its
/// product title), as `api.cook.get_kitchen_orders` emits it.
class KitchenDishData {
  /// The Order Item child-row docname — the id
  /// `api.cook.update_kitchen_dish_status` takes.
  final String? id;

  final String? title;
  final int quantity;

  /// Null when the site is not migrated for prep_status yet — the UI
  /// treats that as pending.
  final DishStatus? prepStatus;

  const KitchenDishData({
    this.id,
    this.title,
    this.quantity = 1,
    this.prepStatus,
  });

  DishStatus get status => prepStatus ?? DishStatus.pending;

  KitchenDishData copyWith({DishStatus? prepStatus}) => KitchenDishData(
    id: id,
    title: title,
    quantity: quantity,
    prepStatus: prepStatus ?? this.prepStatus,
  );

  factory KitchenDishData.fromJson(Map<String, dynamic> json) =>
      KitchenDishData(
        id: (json['id'] ?? json['name'])?.toString(),
        title: json['title']?.toString(),
        quantity: int.tryParse('${json['quantity'] ?? 1}') ?? 1,
        prepStatus: DishStatus.fromWire(json['prep_status']?.toString()),
      );
}

/// One order in the kitchen queue.
class KitchenOrderData {
  /// The Order docname (Frappe hash string) — never a numeric id.
  final String? id;

  final KitchenStatus status;
  final String? deliveryType;

  /// The cook-visible customer note (approved 34a/34c amber card).
  final String? note;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<KitchenDishData> dishes;

  const KitchenOrderData({
    this.id,
    this.status = KitchenStatus.accepted,
    this.deliveryType,
    this.note,
    this.createdAt,
    this.updatedAt,
    this.dishes = const [],
  });

  KitchenOrderData copyWith({
    KitchenStatus? status,
    List<KitchenDishData>? dishes,
  }) => KitchenOrderData(
    id: id,
    status: status ?? this.status,
    deliveryType: deliveryType,
    note: note,
    createdAt: createdAt,
    updatedAt: updatedAt,
    dishes: dishes ?? this.dishes,
  );

  /// The card's dish-preview line data (approved 34a: "3 dishes ·
  /// Beef Kota ×2, Chips…" — the composing happens in the widget so the
  /// count word can be translated).
  List<DishStatus> get dishStatuses => [for (final d in dishes) d.status];

  factory KitchenOrderData.fromJson(Map<String, dynamic> json) =>
      KitchenOrderData(
        id: (json['id'] ?? json['name'])?.toString(),
        status:
            KitchenStatus.fromWire(json['status']?.toString()) ??
            KitchenStatus.accepted,
        deliveryType: json['delivery_type']?.toString(),
        note: json['note']?.toString(),
        createdAt: DateTime.tryParse('${json['creation'] ?? ''}'),
        updatedAt: DateTime.tryParse('${json['modified'] ?? ''}'),
        dishes: [
          for (final item in (json['items'] as List? ?? const []))
            if (item is Map<String, dynamic>) KitchenDishData.fromJson(item),
        ],
      );
}
