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
