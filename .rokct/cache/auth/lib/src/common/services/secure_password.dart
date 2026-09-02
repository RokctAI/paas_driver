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

// compliance-ignore-file: obs-flutter-trace (false positive: this file makes
// no network calls at all — it is a pure Random.secure password generator with
// only dart:convert/dart:math imports; the check fires solely because the
// file's path contains "services")

import 'dart:convert';
import 'dart:math';

/// Cryptographically random password generator for backend accounts whose
/// password the user never sees (deferred/offline-registered accounts).
///
/// [byteLength] random bytes from [Random.secure] (the OS CSPRNG), encoded
/// base64url with the `=` padding stripped — 32 bytes encodes to 43
/// characters of `[A-Za-z0-9_-]`, i.e. 256 bits of entropy, far past any
/// online- or offline-guessing horizon and safely under typical password
/// length caps.
///
/// Deliberately a plain function in a file with no base_sdk/drift imports:
/// callers that only need password generation (tests included) can import
/// it without dragging in the offline database types that only resolve
/// after a host app's build_runner pass.
String generateSecurePassword({int byteLength = 32}) {
  final rng = Random.secure();
  final bytes = List<int>.generate(byteLength, (_) => rng.nextInt(256));
  return base64UrlEncode(bytes).replaceAll('=', '');
}
