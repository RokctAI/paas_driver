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

// Imported directly (not via handlers.dart) because ApiResult's `when` is an
// EXTENSION declared in the generated `api_result.freezed.dart` part.
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/services/app_connectivity.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/error_presenter.dart';

import 'package:delivery_sdk/src/common/application/poi/poi_proximity.dart';
import 'package:delivery_sdk/src/driver/application/poi/poi_state.dart';
import 'package:delivery_sdk/src/driver/domain/interface/poi.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/driver_poi.dart';
import 'package:delivery_sdk/src/driver/infrastructure/services/courier_location_fix.dart';

/// Radio-level connectivity gate, injectable so the screens' tests can run
/// the whole flow against a fake repository without a platform channel.
typedef ConnectivityCheck = Future<bool> Function();

/// One attempt at the driver's own position, injectable for the same reason.
typedef LocationFix = Future<CourierLocationResult> Function();

/// The driver's points of interest.
///
/// ERROR WORDING (Ray's standing rule): a driver facing failure sees ONE
/// friendly line, never the server's sentence; the verbatim detail rides
/// [ErrorPresenter.showTechnical] to telemetry. Frappe answers a
/// `frappe.throw` with 417, inside [ErrorPresenter.show]'s definitive-4xx
/// band, which is why `show` is deliberately not used here.
///
/// A CREATE THAT ANSWERS AN EXISTING POINT IS A SUCCESS. The server keeps
/// one point per corner and hands back the one that already stands there
/// ([DriverPoi.wasAlreadyThere]). This slice SELECTS that point and says so
/// — it never reports it as a failure and never files a second pin.
///
/// AND A CREATE THAT ANSWERS AN OWNER CLASH IS A QUESTION. The number is on
/// file under another first name and the server wrote nothing; that lands in
/// [DriverPoiState.ownerClash] with NO error shown, because the driver is
/// being asked something, not told he got it wrong. The sheet asks, and a
/// yes re-sends with `ownerConfirmedUser`.
class DriverPoiNotifier extends StateNotifier<DriverPoiState> {
  DriverPoiNotifier(
    this._repository, {
    ConnectivityCheck? isOnline,
    LocationFix? locationFix,
  })  : _isOnline = isOnline ?? AppConnectivity.connectivity,
        _locationFix = locationFix ?? _platformFix,
        super(const DriverPoiState());

  final DriverPoiRepositoryFacade _repository;
  final ConnectivityCheck _isOnline;
  final LocationFix _locationFix;

  /// Telemetry bucket for everything that goes wrong on this surface.
  static const String errorType = 'driver_poi';

  /// How far around the driver a "what is near me" read looks.
  static const double nearbyRadiusKm = 1.5;

  static Future<CourierLocationResult> _platformFix() =>
      CourierLocationFix().current();

  /// Reads the vocabulary once. Safe to call on every entry: a second call
  /// with types already held is a no-op, because the list does not change
  /// between two taps on the same screen.
  Future<void> loadTypes({BuildContext? context}) async {
    if (state.types.isNotEmpty) return;
    final response = await _repository.types();
    response.when(
      success: (types) => state = state.copyWith(types: types),
      failure: (failure, status) => _report(
        context,
        failure: failure,
        status: status,
        op: 'get_poi_types',
        friendly: 'we_couldnt_read_the_place_types_try_again',
      ),
    );
  }

  /// Reads the shops he may tag a place to, once.
  ///
  /// Safe to call on every entry, like [loadTypes]: a second call with an
  /// answer already held is a no-op. A failure leaves [DriverPoiState
  /// .shopChoices] null, which the sheet reads as "nobody has said yet"
  /// rather than as "he delivers for nobody" — it keeps the picker out of
  /// the way and lets the create call raise its own ask.
  Future<void> loadMyShops({BuildContext? context}) async {
    if (state.shopChoices != null || state.isLoadingShops) return;
    state = state.copyWith(isLoadingShops: true);
    final response = await _repository.myShops();
    response.when(
      success: (choices) => state = state.copyWith(
        shopChoices: choices,
        isLoadingShops: false,
      ),
      failure: (failure, status) {
        state = state.copyWith(isLoadingShops: false);
        _report(
          context,
          failure: failure,
          status: status,
          op: 'get_my_poi_shops',
          friendly: 'we_couldnt_read_the_shops_you_deliver_for_try_again',
        );
      },
    );
  }

  /// Reads who a number belongs to, for the owner fields on the sheet.
  ///
  /// Called as the driver finishes typing the number, so it is deliberately
  /// quiet: a failure leaves [DriverPoiState.ownerLookup] null — "nobody
  /// has said" — and shows the driver nothing at all. He is mid-form, and a
  /// convenience that could not run is not a problem he has to read about;
  /// the create call still asks the server the same question and still
  /// raises its own answer.
  ///
  /// An empty number clears the held answer instead of asking about
  /// nothing, so a corrected number never leaves the previous owner's name
  /// on screen.
  /// Takes no `context`, unlike every other read here: a failure shows the
  /// driver nothing, so there is nothing to show it on. A parameter this
  /// method could not use would be a lie about what it does.
  Future<void> lookupOwner(String phone) async {
    final number = phone.trim();
    if (number.isEmpty) {
      state = state.copyWith(clearOwnerLookup: true, isLookingUpOwner: false);
      return;
    }
    if (state.isLookingUpOwner) return;
    state = state.copyWith(isLookingUpOwner: true);
    final response = await _repository.lookupOwner(phone: number);
    response.when(
      success: (owner) => state = state.copyWith(
        ownerLookup: owner,
        isLookingUpOwner: false,
      ),
      failure: (failure, status) => state = state.copyWith(
        isLookingUpOwner: false,
        clearOwnerLookup: true,
      ),
    );
  }

  /// Forgets what the last owner lookup said and the clash it may have
  /// raised. What a sheet calls as it opens, so one driver's form never
  /// starts with the previous one's answer.
  void clearOwner() {
    state = state.copyWith(clearOwnerLookup: true, clearOwnerClash: true);
  }

  /// Reads the points near a position. With no position given, the
  /// driver's own fix is taken first — one shot, and a refusal simply
  /// leaves the list as it was rather than losing the screen.
  Future<void> loadNearby({
    double? latitude,
    double? longitude,
    String? type,
    BuildContext? context,
  }) async {
    if (state.isLoading) return;
    if (!await _isOnline()) {
      if (context != null && context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
      return;
    }
    var lat = latitude;
    var lon = longitude;
    if (lat == null || lon == null) {
      final fix = await _locationFix();
      final position = fix.position;
      if (position == null) {
        // Nothing to measure from. The caller's screen still stands.
        return;
      }
      lat = position.latitude;
      lon = position.longitude;
    }
    state = state.copyWith(isLoading: true, latitude: lat, longitude: lon);
    final response = await _repository.nearby(
      latitude: lat,
      longitude: lon,
      radiusKm: nearbyRadiusKm,
      type: type,
    );
    response.when(
      success: (points) {
        state = state.copyWith(
          points: points,
          isLoading: false,
          loadedOnce: true,
        );
      },
      failure: (failure, status) {
        state = state.copyWith(isLoading: false);
        _report(
          context,
          failure: failure,
          status: status,
          op: 'get_nearby_pois',
          friendly: 'we_couldnt_read_the_places_near_you_try_again',
        );
      },
    );
  }

  /// How far the driver is from [point] RIGHT NOW, in metres, or null when
  /// nobody can say.
  ///
  /// A FRESH FIX, not the position the held list was read for: the question
  /// the sell screen asks with this is "are you standing there", and a fix
  /// from when he opened the screen answers a different one.
  ///
  /// Null for a point with no coordinates and for a phone that would not
  /// give a fix, and [PoiProximity.needsConfirming] treats that null as
  /// "do not ask": a refused permission must not turn into a dialog on
  /// every sale.
  Future<double?> metresFrom(DriverPoi point) async {
    if (!point.hasCoordinates) return null;
    final fix = await _locationFix();
    final position = fix.position;
    if (position == null) return null;
    return metresBetween(
      position.latitude,
      position.longitude,
      point.latitude!,
      point.longitude!,
    );
  }

  /// The point the driver says he is standing at. Null clears it — a sale
  /// with no point named is the normal case and must stay one tap away.
  void select(DriverPoi? point) {
    if (point == null) {
      state = state.copyWith(clearSelected: true);
      return;
    }
    state = state.copyWith(selected: point);
  }

  /// Files a point at the driver's own position (or at one given).
  ///
  /// Returns the point on success — INCLUDING the point that already stood
  /// there, which is why the caller reads [DriverPoi.wasAlreadyThere]
  /// rather than treating a non-null answer as "new pin". Null means either
  /// the attempt failed and this method has already spoken, OR the server
  /// raised the owner clash, which is the one null the caller must look at
  /// [DriverPoiState.ownerClash] for before it gives up: nothing was
  /// written, nothing was reported, and the driver has a question to answer.
  Future<DriverPoi?> create({
    required String label,
    required String type,
    double? latitude,
    double? longitude,
    String? customType,
    String? note,
    String? shop,
    String? ownerFirstName,
    String? ownerLastName,
    String? ownerPhone,
    bool ownerConfirmedUser = false,
    bool select = true,
    BuildContext? context,
  }) async {
    if (state.isSubmitting) return null;
    if (!await _isOnline()) {
      if (context != null && context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
      return null;
    }
    var lat = latitude ?? state.latitude;
    var lon = longitude ?? state.longitude;
    if (lat == null || lon == null) {
      final fix = await _locationFix();
      final position = fix.position;
      if (position == null) {
        if (context != null && context.mounted) {
          AppHelpers.showCheckTopSnackBar(
            context,
            AppHelpers.getTranslation('we_need_your_position_to_add_a_place'),
          );
        }
        return null;
      }
      lat = position.latitude;
      lon = position.longitude;
    }
    // A fresh attempt, so the question the last one raised is no longer
    // pending: whatever this one answers replaces it.
    state = state.copyWith(isSubmitting: true, clearOwnerClash: true);
    final response = await _repository.create(
      label: label,
      type: type,
      latitude: lat,
      longitude: lon,
      customType: customType,
      note: note,
      shop: shop,
      ownerFirstName: ownerFirstName,
      ownerLastName: ownerLastName,
      ownerPhone: ownerPhone,
      ownerConfirmedUser: ownerConfirmedUser,
    );
    DriverPoi? filed;
    response.when(
      success: (answer) {
        final clash = answer.ownerClash;
        final point = answer.point;
        if (clash != null || point == null) {
          // The question, held for the sheet to ask. NOT reported: he is
          // being asked whether it is the same person.
          state = state.copyWith(isSubmitting: false, ownerClash: clash);
          return;
        }
        filed = point;
        state = state.copyWith(
          isSubmitting: false,
          points: _withPoint(point),
          lastCreated: point,
          lastWasAlreadyThere: point.wasAlreadyThere,
          selected: select ? point : null,
        );
      },
      failure: (failure, status) {
        state = state.copyWith(isSubmitting: false);
        _report(
          context,
          failure: failure,
          status: status,
          op: 'create_poi',
          friendly: 'we_couldnt_add_that_place_try_again',
        );
      },
    );
    return filed;
  }

  /// Reads the sales history of a point for its sheet.
  Future<void> loadSales(String poi, {BuildContext? context}) async {
    if (state.isLoadingSales) return;
    state = state.copyWith(isLoadingSales: true, clearSales: true);
    final response = await _repository.sales(poi: poi);
    response.when(
      success: (sales) {
        state = state.copyWith(sales: sales, isLoadingSales: false);
      },
      failure: (failure, status) {
        state = state.copyWith(isLoadingSales: false);
        _report(
          context,
          failure: failure,
          status: status,
          op: 'get_poi_sales',
          friendly: 'we_couldnt_read_what_was_sold_here_try_again',
        );
      },
    );
  }

  /// The held list with [point] swapped in by id, or appended when it is
  /// one the list has never seen. Keeps the nearest-first order the server
  /// sent for everything else.
  List<DriverPoi> _withPoint(DriverPoi point) {
    if (point.id.isEmpty) return state.points;
    var replaced = false;
    final next = state.points.map((held) {
      if (held.id != point.id) return held;
      replaced = true;
      return point;
    }).toList();
    if (!replaced) next.insert(0, point);
    return List<DriverPoi>.unmodifiable(next);
  }

  void _report(
    BuildContext? context, {
    required String failure,
    required int status,
    required String op,
    required String friendly,
  }) {
    if (context == null || !context.mounted) return;
    ErrorPresenter.showTechnical(
      context,
      type: errorType,
      detail: failure,
      statusCode: status,
      friendly: AppHelpers.getTranslation(friendly),
      extra: {'op': op},
    );
  }
}
