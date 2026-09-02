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

/// State for the severe-weather early-warning feed
/// (`tenant.api.get_weather_warnings`).
///
/// Deliberately NOT an AsyncValue and with no error flag: the product
/// contract for this surface is that any failure - network, auth, missing
/// endpoint, malformed payload - renders as *no warnings at all*. The UI
/// never shows an error, spinner or retry affordance for warnings, so the
/// state never needs to represent one (contrast [WeatherState.hasError],
/// which backs the core weather widget's explicit retry UI).

/// One active severe-weather warning, exactly as rendered by the backend.
///
/// All user-visible text (headline, message) is authored server-side so
/// every client shows identical, centrally approved copy; the client does
/// no meteorology and no wording of its own. Items missing either text
/// field are dropped at parse time - showing nothing is always preferred
/// over showing something broken.
class SevereWeatherWarning {
  /// Warning doc id, e.g. "SWW-2026-00123". Used only for de-dup keys.
  final String id;

  /// flash_flood | flood | destructive_wind | tornado.
  final String eventClass;

  /// Internal severity enum: advisory (soft neighbor-propagation notice:
  /// conditions nearby may reach this area) | heads_up (early notice) |
  /// warning (act now).
  /// NEVER render this value - in South Africa only the national weather
  /// service may issue official severe-weather warnings, so end users must
  /// only ever see the server-rendered strings ([severityLabel],
  /// [headline], [message]).
  final String severity;

  /// User-safe rendering of [severity] (e.g. "Heads-up",
  /// "Please take care") - the only severity text a UI may show. Empty when
  /// the backend did not send one.
  final String severityLabel;

  /// Calm one-liner, e.g. "Flash flooding possible near Messina".
  final String headline;

  /// Friendly full sentence(s) - what is happening and what to do.
  final String message;

  final DateTime? onset;
  final DateTime? validUntil;
  final DateTime? issuedAt;

  const SevereWeatherWarning({
    required this.id,
    required this.eventClass,
    required this.severity,
    this.severityLabel = '',
    required this.headline,
    required this.message,
    this.onset,
    this.validUntil,
    this.issuedAt,
  });

  /// True for the "act now" tier; false for the gentler tiers.
  bool get isActNow => severity == 'warning';

  /// True for the softest tier: a neighbor-propagation notice that
  /// conditions nearby may reach this area.
  bool get isAdvisory => severity == 'advisory';

  /// Urgency weight for "most urgent first" ordering:
  /// advisory (0) < heads_up (1) < warning (2). An unknown severity from a
  /// newer backend ranks with heads_up - the notice still shows with its
  /// server-authored copy at the default presentation, never dropped.
  int get severityRank {
    switch (severity) {
      case 'warning':
        return 2;
      case 'advisory':
        return 0;
      default:
        return 1; // heads_up and any future/unknown tier.
    }
  }

  /// Parses one warning map; returns null (drop silently) when the
  /// user-visible fields are missing or blank.
  static SevereWeatherWarning? tryParse(Map<String, dynamic> raw) {
    final headline = raw['headline'];
    final message = raw['message'];
    if (headline is! String || headline.trim().isEmpty) return null;
    if (message is! String || message.trim().isEmpty) return null;
    return SevereWeatherWarning(
      id: (raw['id'] ?? '').toString(),
      eventClass: (raw['event_class'] ?? '').toString(),
      severity: (raw['severity'] ?? 'heads_up').toString(),
      severityLabel: (raw['severity_label'] ?? '').toString().trim(),
      headline: headline.trim(),
      message: message.trim(),
      onset: _tryParseDate(raw['onset']),
      validUntil: _tryParseDate(raw['valid_until']),
      issuedAt: _tryParseDate(raw['issued_at']),
    );
  }

  static DateTime? _tryParseDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  /// Serializes back to the exact map shape [tryParse] accepts, so the
  /// offline cache can round-trip a warning without a second schema.
  Map<String, dynamic> toJson() => {
        'id': id,
        'event_class': eventClass,
        'severity': severity,
        'severity_label': severityLabel,
        'headline': headline,
        'message': message,
        'onset': onset?.toIso8601String(),
        'valid_until': validUntil?.toIso8601String(),
        'issued_at': issuedAt?.toIso8601String(),
      };

  /// True while now is inside the notice's validity window. Notices without
  /// a `valid_until` bound are NOT considered active here: this gate exists
  /// for the offline-cache path, where an unbounded notice could otherwise
  /// be shown stale forever - the fail-closed choice is to drop it.
  bool isActiveAt(DateTime now) =>
      validUntil != null && validUntil!.isAfter(now);
}

/// Immutable snapshot of the warnings feed. [WeatherWarningsState.empty] is
/// both the initial state and the universal failure state.
class WeatherWarningsState {
  /// Active warnings, most urgent first ("warning" tier before "heads_up"
  /// before "advisory", then earliest onset). Empty on no data AND on any
  /// failure.
  final List<SevereWeatherWarning> warnings;

  /// Data credit rendered wherever a warning is shown. The backend sends it
  /// with every response; the constant is the required fallback so the
  /// credit can never be dropped by a payload hiccup.
  final String attribution;

  final DateTime? generatedAt;

  /// True when [warnings] were served from the offline cache (fetch failed
  /// or no connectivity) rather than a live gateway response. The banner
  /// then adds a subtle freshness marker; nothing else changes.
  final bool fromCache;

  /// When the cached payload was originally fetched; set only with
  /// [fromCache]. Backs the "as of HH:mm" freshness marker.
  final DateTime? cachedAt;

  const WeatherWarningsState({
    this.warnings = const [],
    this.attribution = defaultAttribution,
    this.generatedAt,
    this.fromCache = false,
    this.cachedAt,
  });

  /// Open-Meteo data is CC-BY-4.0: this exact string must stay visible on
  /// every surface that displays warning data.
  static const String defaultAttribution = 'Weather data by Open-Meteo.com';

  static const WeatherWarningsState empty = WeatherWarningsState();

  bool get hasWarnings => warnings.isNotEmpty;

  /// The single most urgent warning, or null - the collapsed banner shows
  /// only this one.
  SevereWeatherWarning? get mostSevere =>
      warnings.isEmpty ? null : warnings.first;

  /// Stable key over the visible warning set; the banner's dismiss-for-today
  /// bookkeeping uses it so NEW warnings reappear after a dismissal.
  String get contentKey =>
      warnings.map((w) => w.id.isEmpty ? w.headline : w.id).join('|');
}
