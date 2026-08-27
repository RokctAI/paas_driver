// Copyright (c) 2026 RokctAI
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

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
