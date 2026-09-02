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


class FilterModel {
  List<double>? price;
  String? rating;
  int? offer;
  String? sort;
  bool? isFreeDelivery;
  bool? isDeal;
  bool? isOpen;

  FilterModel({
    this.price,
    this.rating = "",
    this.offer,
    this.sort = "",
    this.isFreeDelivery = false,
    this.isDeal = false,
    this.isOpen = true,
  });
}
