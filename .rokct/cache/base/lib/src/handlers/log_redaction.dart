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

/// One place that decides what a log line is allowed to say.
///
/// A request URI is the single most-logged object in the stack — Dio's
/// `LogInterceptor` prints it on every request and on every failure, the
/// network error funnel forwards it to telemetry, and a debug build's
/// console is copied verbatim into CI job logs, which are retained and
/// (for a public repo) world-readable. Any credential that travels as a
/// query parameter is therefore a credential in plain text in a log.
///
/// The rule here is deliberately blunt: a parameter whose NAME is known
/// to carry a credential never has its VALUE printed, whatever the value
/// happens to be. Redaction is by name, never by matching the secret
/// itself, so nothing needs to know the secret in order to hide it and a
/// rotated key is covered the moment it is rotated.
library;

/// What a redacted value is replaced with. Deliberately not empty and not
/// a fixed-width mask: a reader of the log can tell "a value was here and
/// was withheld" apart from "the parameter was absent".
const String kRedactedValue = 'REDACTED';

/// Query-parameter names whose values must never reach a log.
///
/// Lower-case; matching is case-insensitive. These are the names in use
/// across the HTTP APIs this kernel and its feature SDKs talk to — a
/// routing provider takes `api_key`, a places provider takes `key`, and
/// so on. Add rather than replace: an unknown name is not redacted, so a
/// new credential parameter has to be declared here.
const Set<String> kSensitiveQueryParameters = <String>{
  'access_token',
  'access-token',
  'accesstoken',
  'api-key',
  'api_key',
  'apikey',
  'auth',
  'auth_token',
  'authorization',
  'client_secret',
  'id_token',
  'key',
  'passwd',
  'password',
  'private_key',
  'pwd',
  'refresh_token',
  'secret',
  'session_key',
  'sig',
  'signature',
  'subscription-key',
  'token',
  'x-api-key',
};

/// Header names whose values must never reach a log.
///
/// The fix for a credential in a query string is to move it into a header
/// — which only helps if the header is not printed either, and Dio's
/// `LogInterceptor` prints request headers verbatim when asked to. The
/// `x-goog-api-key` / `x-rapidapi-key` entries are the provider header
/// names the feature SDKs already send through this kernel's client.
const Set<String> kSensitiveHeaders = <String>{
  'api-key',
  'authorization',
  'cookie',
  'proxy-authorization',
  'set-cookie',
  'x-api-key',
  'x-auth-token',
  'x-goog-api-key',
  'x-rapidapi-key',
};

/// Whether [name] names a query parameter that carries a credential.
bool isSensitiveQueryParameter(String name) =>
    kSensitiveQueryParameters.contains(name.trim().toLowerCase());

/// Whether [name] names a header that carries a credential.
bool isSensitiveHeader(String name) =>
    kSensitiveHeaders.contains(name.trim().toLowerCase());

/// [uri] with the value of every sensitive query parameter replaced by
/// [kRedactedValue]. Everything else — scheme, host, path, fragment, the
/// order and encoding of the remaining parameters — is left exactly as it
/// was, so a redacted URI is still worth reading in a bug report.
///
/// Returns [uri] itself when there is nothing to redact.
Uri redactUri(Uri uri) {
  final String query = uri.query;
  if (query.isEmpty) return uri;
  final String redacted = _redactQueryString(query);
  if (redacted == query) return uri;
  return uri.replace(query: redacted);
}

/// [uri] rendered as a string with its sensitive query parameters
/// redacted. Never throws: an unparseable value is redacted textually.
String redactUriString(String uri) => redactLogText(uri);

/// A log line with every credential in it withheld.
///
/// Applies to any text, not just a bare URI, because the objects that end
/// up in logs are rarely bare URIs: a `DioException.toString()`, a
/// JSON-encoded telemetry payload with a `url` field, a `LogInterceptor`
/// header line. Two rewrites are made:
///
///   * `?api_key=<value>` / `&token=<value>` anywhere in the text — the
///     value up to the next separator is replaced;
///   * a line that IS a header, `authorization: <value>` — the whole
///     value is replaced.
///
/// Null becomes the empty string; anything else is `toString()`d first.
String redactLogText(Object? value) {
  if (value == null) return '';
  final String text = value is String ? value : value.toString();
  if (text.isEmpty) return text;
  return text
      .replaceAllMapped(
        _queryParameterPattern,
        (Match m) => '${m[1]}$kRedactedValue',
      )
      .replaceAllMapped(
        _headerLinePattern,
        (Match m) => '${m[1]}$kRedactedValue',
      );
}

/// A copy of [headers] with the value of every sensitive header replaced.
/// Key order and every other entry are preserved.
Map<String, dynamic> redactHeaders(Map<String, dynamic> headers) {
  return <String, dynamic>{
    for (final MapEntry<String, dynamic> e in headers.entries)
      e.key: isSensitiveHeader(e.key) ? kRedactedValue : e.value,
  };
}

/// Rewrites a raw `a=1&b=2` query string in place, preserving the
/// encoding and order of everything it does not redact.
String _redactQueryString(String query) {
  final List<String> parts = query.split('&');
  bool touched = false;
  for (int i = 0; i < parts.length; i++) {
    final int eq = parts[i].indexOf('=');
    if (eq <= 0) continue;
    final String name = safeDecodeQueryComponent(parts[i].substring(0, eq));
    if (!isSensitiveQueryParameter(name)) continue;
    parts[i] = '${parts[i].substring(0, eq + 1)}$kRedactedValue';
    touched = true;
  }
  return touched ? parts.join('&') : query;
}

/// Percent-decoding a query component must never throw — a malformed
/// escape is not a reason to lose the redaction, or to fail a request on
/// the way to stripping a credential out of it.
String safeDecodeQueryComponent(String raw) {
  try {
    return Uri.decodeQueryComponent(raw);
  } catch (_) {
    return raw;
  }
}

/// `?api_key=` / `&token=` (also `;` and `#`, which appear in URIs that
/// have been through string surgery) followed by the value. The value
/// runs to the next parameter separator or to whatever ends the URI in
/// running text — whitespace, a quote, a bracket, a comma.
final RegExp _queryParameterPattern = RegExp(
  '([?&;#]\\s*(?:${kSensitiveQueryParameters.map(RegExp.escape).join('|')})'
  '\\s*=)'
  '[^&\\s"\'<>\\]}),]*',
  caseSensitive: false,
);

/// A whole line that is a header: `authorization: Bearer abc`. Anchored to
/// the start of a line so a header NAME quoted inside a JSON body (
/// `"error": "Authorization field missing"`) is left alone.
final RegExp _headerLinePattern = RegExp(
  '^([ \\t]*(?:${kSensitiveHeaders.map(RegExp.escape).join('|')})'
  '[ \\t]*:[ \\t]*)'
  '.*\$',
  caseSensitive: false,
  multiLine: true,
);
