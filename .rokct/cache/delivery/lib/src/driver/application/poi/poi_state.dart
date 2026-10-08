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

import 'package:delivery_sdk/src/driver/infrastructure/models/data/driver_poi.dart';

/// Plain immutable state for the points-of-interest slice. Hand-written
/// `copyWith`, like the sibling `load_state.dart`, so the slice stays
/// analyzable without a build_runner pass.
class DriverPoiState {
  const DriverPoiState({
    this.points = const [],
    this.types = const [],
    this.isLoading = false,
    this.loadedOnce = false,
    this.isSubmitting = false,
    this.latitude,
    this.longitude,
    this.selected,
    this.lastCreated,
    this.lastWasAlreadyThere = false,
    this.sales,
    this.isLoadingSales = false,
    this.shopChoices,
    this.isLoadingShops = false,
    this.ownerLookup,
    this.isLookingUpOwner = false,
    this.ownerClash,
  });

  /// The points near the last position asked about, in the server's order
  /// (nearest first).
  final List<DriverPoi> points;

  /// The admin-extendable vocabulary, as the type chips read it.
  final List<DriverPoiType> types;

  final bool isLoading;

  /// A read has completed, so an empty list means "nothing filed here
  /// yet", not "we have not looked". The empty line must never show before
  /// the first answer.
  final bool loadedOnce;

  /// A create is in flight; the commit goes inert so a double-tap cannot
  /// file the same corner twice.
  final bool isSubmitting;

  /// The position the held [points] were read for.
  final double? latitude;
  final double? longitude;

  /// The point the driver is standing at, as he named it — what a sale is
  /// attributed to.
  final DriverPoi? selected;

  /// The point the last create answered with, whether it was filed or
  /// already stood there.
  final DriverPoi? lastCreated;

  /// True when that answer was a point that ALREADY STOOD within the
  /// duplicate radius, so the screen can say so plainly instead of
  /// claiming a new pin.
  final bool lastWasAlreadyThere;

  /// The sales history of the point whose sheet is open.
  final DriverPoiSales? sales;
  final bool isLoadingSales;

  /// The shops this driver may tag a place to, once the server has said.
  /// Null until it has been asked — which is not the same as "none", and
  /// the picker must not claim he delivers for nobody before it knows.
  final DriverPoiShopChoices? shopChoices;
  final bool isLoadingShops;

  /// Who the number the driver typed belongs to, once the server has said.
  /// Null until it has been asked, which is not the same as "nobody": the
  /// sheet must not claim the number is new before it knows.
  final DriverPoiOwner? ownerLookup;
  final bool isLookingUpOwner;

  /// The one refusal that is a QUESTION: the number is on file under
  /// another first name. Held so the sheet can ask, and cleared the moment
  /// it has been answered — a stale clash would ask twice.
  final DriverPoiOwnerClash? ownerClash;

  /// True once the server has said the number belongs to somebody.
  bool get ownerIsOnFile => ownerLookup?.found == true;

  /// The shop a sheet opened off no load should file against without
  /// asking: the single shop he delivers for. Null whenever there is a
  /// choice to make, or whenever nobody has said yet.
  String? get settledShopId =>
      shopChoices?.isSettled == true ? shopChoices!.only?.id : null;

  /// True once the server has said he delivers for more than one shop, so
  /// the sheet has to ask which before it can file anything.
  bool get mustChooseShop => shopChoices?.needsChoosing == true;

  bool get hasPoints => points.isNotEmpty;

  /// The type that asks the driver to describe the place himself. Null
  /// until the vocabulary has been read.
  DriverPoiType? get customTypeOption {
    for (final type in types) {
      if (type.takesCustomType) return type;
    }
    return null;
  }

  DriverPoi? pointById(String id) {
    for (final point in points) {
      if (point.id == id) return point;
    }
    if (selected?.id == id) return selected;
    if (lastCreated?.id == id) return lastCreated;
    return null;
  }

  DriverPoiState copyWith({
    List<DriverPoi>? points,
    List<DriverPoiType>? types,
    bool? isLoading,
    bool? loadedOnce,
    bool? isSubmitting,
    double? latitude,
    double? longitude,
    DriverPoi? selected,
    bool clearSelected = false,
    DriverPoi? lastCreated,
    bool? lastWasAlreadyThere,
    DriverPoiSales? sales,
    bool clearSales = false,
    bool? isLoadingSales,
    DriverPoiShopChoices? shopChoices,
    bool? isLoadingShops,
    DriverPoiOwner? ownerLookup,
    bool clearOwnerLookup = false,
    bool? isLookingUpOwner,
    DriverPoiOwnerClash? ownerClash,
    bool clearOwnerClash = false,
  }) =>
      DriverPoiState(
        points: points ?? this.points,
        types: types ?? this.types,
        isLoading: isLoading ?? this.isLoading,
        loadedOnce: loadedOnce ?? this.loadedOnce,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        selected: clearSelected ? null : (selected ?? this.selected),
        lastCreated: lastCreated ?? this.lastCreated,
        lastWasAlreadyThere:
            lastWasAlreadyThere ?? this.lastWasAlreadyThere,
        sales: clearSales ? null : (sales ?? this.sales),
        isLoadingSales: isLoadingSales ?? this.isLoadingSales,
        shopChoices: shopChoices ?? this.shopChoices,
        isLoadingShops: isLoadingShops ?? this.isLoadingShops,
        ownerLookup:
            clearOwnerLookup ? null : (ownerLookup ?? this.ownerLookup),
        isLookingUpOwner: isLookingUpOwner ?? this.isLookingUpOwner,
        ownerClash: clearOwnerClash ? null : (ownerClash ?? this.ownerClash),
      );
}
