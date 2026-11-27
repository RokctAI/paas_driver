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

import 'package:flutter/widgets.dart' show StringCharacters, immutable;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:base_sdk/src/models/data/profile_data.dart';

/// The few account details a device keeps after Log out, so the sign-in
/// page can offer a one-tap "Welcome back" (Ray, 2026-11-27, approved after
/// the Claude app's Log out dialog): name, email or phone, and picture.
/// Never a token or password: signing back in still asks for the password.
///
/// Kept for [keepFor] from the moment of Log out, then dropped on the next
/// read. "Remove from this device" in the Log out dialog skips [remember].
@immutable
class RememberedAccount {
  const RememberedAccount({
    required this.name,
    this.email,
    this.phone,
    this.img,
    required this.savedAt,
  });

  static const Duration keepFor = Duration(days: 30);
  static const String storageKey = 'keyRememberedAccount';

  final String name;
  final String? email;
  final String? phone;
  final String? img;
  final DateTime savedAt;

  /// What the sign-in field is filled with: the email, else the phone.
  String? get login => (email?.isNotEmpty ?? false) ? email : phone;

  /// The first letter shown when there is no picture.
  String get initial =>
      name.isEmpty ? '?' : name.characters.first.toUpperCase();

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'phone': phone,
    'img': img,
    'saved_at': savedAt.toUtc().toIso8601String(),
  };

  static RememberedAccount? fromJson(Map<String, dynamic> json) {
    final saved = DateTime.tryParse(json['saved_at'] as String? ?? '');
    final name = json['name'] as String? ?? '';
    if (saved == null) return null;
    return RememberedAccount(
      name: name,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      img: json['img'] as String?,
      savedAt: saved,
    );
  }

  /// Keeps [user]'s details on this device. Does nothing when the user has
  /// neither an email nor a phone, since there is nothing to sign in with.
  static Future<void> remember(ProfileData? user, {DateTime? now}) async {
    if (user == null) return;
    final email = user.email?.trim();
    final phone = user.phone?.trim();
    if ((email?.isEmpty ?? true) && (phone?.isEmpty ?? true)) return;
    final name = [user.firstname, user.lastname]
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .join(' ');
    final account = RememberedAccount(
      name: name.isEmpty
          ? (email?.isNotEmpty ?? false ? email! : phone!)
          : name,
      email: (email?.isEmpty ?? true) ? null : email,
      phone: (phone?.isEmpty ?? true) ? null : phone,
      img: user.img,
      savedAt: now ?? DateTime.now(),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, jsonEncode(account.toJson()));
  }

  /// The kept account, or null when none is kept or it is older than
  /// [keepFor] (an expired one is removed here).
  static Future<RememberedAccount?> read({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return null;
    RememberedAccount? account;
    try {
      account = fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      account = null;
    }
    if (account == null ||
        (now ?? DateTime.now()).difference(account.savedAt) > keepFor) {
      await prefs.remove(storageKey);
      return null;
    }
    return account;
  }

  /// Removes the kept account ("Remove" on the Welcome back card).
  static Future<void> forget() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }
}
