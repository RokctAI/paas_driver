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

/// One row on the shop's OWN-DRIVER roster, exactly the three keys
/// `api.shop_drivers.list_shop_drivers` answers:
/// `{deliveryman, full_name, active}`.
///
/// [id] is the driver's User id — the same handle `create_load` takes on
/// `deliveryman` and the same one [LoadDeliveryman.id] carries, so a row
/// picked here can go straight onto a load with no translation.
class ShopDriver {
  final String id;
  final String name;

  /// A row the shop has retired keeps its place on the roster but stops
  /// counting as one of the shop's drivers, so the surface can show it
  /// dimmed rather than making a removal look like a deletion.
  final bool active;

  const ShopDriver({required this.id, required this.name, this.active = true});

  factory ShopDriver.fromJson(Map<String, dynamic> json) {
    final String id = json['deliveryman']?.toString() ?? '';
    final String name = json['full_name']?.toString() ?? '';
    final Object? active = json['active'];
    return ShopDriver(
      id: id,
      name: name.isEmpty ? id : name,
      active: active == null || active == true || active == 1 || active == '1',
    );
  }
}
