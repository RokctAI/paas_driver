import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:base_sdk/src/models/response/driver_show_response.dart';
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

  static SharedPreferences? _cached;

  /// Pre-warms the synchronous [getOnline] path.
  static Future<void> init() async {
    _cached = await SharedPreferences.getInstance();
  }
}
