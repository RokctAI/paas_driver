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

import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:base_sdk/src/models/data/address_old_data.dart';
import 'package:base_sdk/src/models/data/location.dart';
import 'package:base_sdk/src/models/response/driver_show_response.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/storage_keys.dart';

/// Courier-only local-storage slice carried out of paas_driver's host
/// `LocalStorage` (setDeliveryInfo / setOnline / getOnline).
///
/// base_sdk's LocalStorage can READ the vehicle record (`getDeliveryInfo`,
/// key `keyCarInfo`) but never writes it, and knows nothing about the
/// online flag. This helper writes through the SAME SharedPreferences store
/// and the SAME key strings, so `LocalStorage.getDeliveryInfo()` keeps
/// returning what this class persists.
///
/// RETENTION POLICY (mirrors base's getDeliveryInfo doc): vehicle info is
/// externally-controlled — owners must fetch-live-then-cache and use the
/// stored value only as an offline fallback.
abstract class CourierStorage {
  CourierStorage._();

  /// Same literal the host used; base's StorageKeys has no counterpart.
  static const String _keyOnline = 'keyOnline';

  /// Frame 49d's shift-ended stamp: the minute this phone last saw the
  /// driver toggle OFF duty, ISO-8601. Courier-only, like [_keyOnline].
  static const String _keyShiftEndedAt = 'keyShiftEndedAt';

  static Future<void> setDeliveryInfo(DeliveryResponse? info) async {
    final preferences = _cached ??= await SharedPreferences.getInstance();
    final String infoString = (info != null) ? jsonEncode(info.toJson()) : '';
    await preferences.setString(StorageKeys.keyCarInfo, infoString);
  }

  static Future<void> setOnline(bool online) async {
    final preferences = _cached ??= await SharedPreferences.getInstance();
    await preferences.setBool(_keyOnline, online);
  }

  /// Synchronous like the host original. [DriverDeliveryDependencies.register]
  /// pre-warms [_cached] during bootstrap (before any page builds), so this
  /// read never races; an unwarmed read degrades to the host's own default
  /// (offline), never a crash.
  static bool getOnline() => _cached?.getBool(_keyOnline) ?? false;

  /// Records (or, with null, clears) when the driver went off duty —
  /// design strip frame 49d's "SHIFT ENDED 17:04". The frame flagged the
  /// time as unsourced because `setOnline` stores a bool only; this is
  /// the client-side local timestamp it asked for. Written by the same
  /// toggle that writes [_keyOnline], so the two cannot disagree.
  static Future<void> setShiftEndedAt(DateTime? endedAt) async {
    final preferences = _cached ??= await SharedPreferences.getInstance();
    if (endedAt == null) {
      await preferences.remove(_keyShiftEndedAt);
    } else {
      await preferences.setString(_keyShiftEndedAt, endedAt.toIso8601String());
    }
  }

  /// Synchronous like [getOnline], for the same reason: the home sheet
  /// reads it during build. Null when nothing was recorded, or when the
  /// stored value does not parse (never a crash on a bad string).
  static DateTime? getShiftEndedAt() {
    final raw = _cached?.getString(_keyShiftEndedAt);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  static SharedPreferences? _cached;

  /// Pre-warms the synchronous [getOnline] path.
  static Future<void> init() async {
    _cached = await SharedPreferences.getInstance();
  }

  /// Persists the courier's live map position through base_sdk's
  /// selected-address slot (key `keyAddressSelected`). The legacy host
  /// stored a bare LatLng JSON under that key; base's LocalStorage now owns
  /// the slot with an [AddressData] shape, so the coordinates travel inside
  /// `AddressData.location` and read back through the
  /// `AddressData.latitude`/`longitude` getters (base_sdk 1.9.0) the courier
  /// pages already use.
  static Future<void> saveSelectedLocation(LatLng latLng) =>
      LocalStorage.setAddressSelected(
        AddressData(
          location: LocationModel(
            latitude: latLng.latitude,
            longitude: latLng.longitude,
          ),
        ),
      );
}
