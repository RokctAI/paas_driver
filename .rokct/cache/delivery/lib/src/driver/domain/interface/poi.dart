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

/// Narrow contract for the driver's points-of-interest surface.
///
/// The endpoints behind it are map's `api.poi.*` defs. This SDK does NOT
/// depend on a map SDK (ADR-005: an SDK's `lib/` imports only base_sdk), so
/// the calls ride base_sdk's universal platform gateway by prefix-free
/// dotted name, exactly as [DriverLoadRepositoryFacade] calls commerce's
/// `api.order.load.*`.
///
/// THE MODEL, which every screen on this seam must honour:
///
///  * a POI is a PLACE and it is SHARED. The driver files one as he passes,
///    with or without a sale at it, and the round keeps it.
///  * SCOPE IS THE SERVER'S. A point goes to the shop of the load he is
///    working unless an admin has marked his contributions platform-wide.
///    Off a load it goes to one of the shops he DELIVERS FOR — Ray,
///    2026-09-18: "driver doesnt own a shop, he either deliver for every
///    shop in the platform or specific ones if choosen" — and [myShops]
///    is how a screen learns which those are so the driver can name one.
///    [create]'s `shop` NARROWS within that set and can never widen it:
///    there is still no platform-wide argument and no author argument, so
///    a client that wanted to widen its own reach has nothing to send.
///  * ONE CORNER, ONE POINT. [create] may answer with the point that
///    already stands there (`duplicateOf` set). That is a SELECTION, not a
///    failure: the caller carries on with the point it was handed.
///  * A PLACE HAS AN OWNER AND THE OWNER IS A PERSON. [create] carries the
///    first name, last name and number the driver was given; the SERVER
///    matches that number against the accounts it holds and links the one
///    it finds, so one person running four spazas is one account with four
///    places. [lookupOwner] is the same match asked in advance, so the
///    sheet can fill an owner in rather than make him type a name the
///    platform already has. There is no `owner_user` argument: which
///    account an owner IS is the server's answer, not the driver's.
///  * THE ONE REFUSAL THE DRIVER CAN ANSWER. A number on file under
///    another first name comes back as a [DriverPoiOwnerClash] on
///    [DriverPoiFiling] instead of a point, and nothing was written. The
///    app asks him whether it is the same person and re-sends with
///    `ownerConfirmedUser`.
///  * [route] is ordered by the SERVER, by the same optimiser the order and
///    parcel route uses. Nothing on this side re-sorts its answer.
library;

import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/driver_poi.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/route_stop.dart';

abstract class DriverPoiRepositoryFacade {
  /// The kinds of place a point may be — the admin-extendable vocabulary,
  /// seeded server-side on first ask. Exactly one of them takes a typed
  /// description (`takesCustomType`).
  Future<ApiResult<List<DriverPoiType>>> types();

  /// The points in scope near a position, nearest first, each carrying its
  /// own distance. An empty list is the normal state of a round nobody has
  /// filed anything on yet.
  Future<ApiResult<List<DriverPoi>>> nearby({
    required double latitude,
    required double longitude,
    double? radiusKm,
    String? type,
    String? shop,
  });

  /// Files a point. [customType] is required by the server for the
  /// catch-all type and ignored for every other one; [ownerFirstName] is
  /// required by it for the kinds of place that ARE a business (a spaza
  /// shop, a stockist, the catch-all) and optional for a landmark or a
  /// gate.
  ///
  /// Answers the created point, or the point that already stood within the
  /// duplicate radius with `duplicateOf` naming it — and, as the one
  /// refusal that is a question rather than a failure, the owner clash on
  /// [DriverPoiFiling].
  ///
  /// [ownerConfirmedUser] answers THAT question and nothing else: the
  /// number is on file under another first name, and the driver has said it
  /// is the same person anyway.
  Future<ApiResult<DriverPoiFiling>> create({
    required String label,
    required String type,
    required double latitude,
    required double longitude,
    String? customType,
    String? shop,
    String? address,
    String? note,
    String? ownerFirstName,
    String? ownerLastName,
    String? ownerPhone,
    bool ownerConfirmedUser = false,
  });

  /// Who a number belongs to, and how many places that person already
  /// runs. `found: false` is the normal answer for an owner the platform
  /// has never met.
  Future<ApiResult<DriverPoiOwner>> lookupOwner({required String phone});

  /// The shops this driver may tag a place to, and whether that list is
  /// the whole platform (`unrestricted`).
  ///
  /// What the Add-a-place sheet's picker reads. One shop is filled in
  /// silently; two or more are offered, because the server will not guess
  /// which round a point belongs to. A driver on a load never needs this:
  /// the load names its own shop.
  Future<ApiResult<DriverPoiShopChoices>> myShops();

  /// The visible points as a DRIVE: the server's own stop list, ordered by
  /// the fleet's optimiser from the given position.
  Future<ApiResult<List<RouteStopData>>> route({
    double? latitude,
    double? longitude,
    String? type,
    String? shop,
  });

  /// What has been sold at a point, with the count, the total and the last
  /// visit. A point with no history answers an empty one rather than a
  /// failure.
  Future<ApiResult<DriverPoiSales>> sales({
    required String poi,
    int limit = 50,
  });
}
