// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
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

/// Typed models for `paas.api.user.get_weak_concepts` (Users PR #17) —
/// the student's cross-session weak-concept aggregate.
///
/// Server contract: the endpoint returns the repo's standard `api_response`
/// wrapper (`{"data": {...}, "status_code": 200}`); Frappe's own top-level
/// `message` envelope has already been stripped by base_sdk's
/// FrappeResponseInterceptor by the time `response.data` reaches
/// [WeakConceptsResponse.fromJson]. The payload under `data`:
///
/// ```json
/// {
///   "concepts": [
///     {"subtopic_ref": "quadratic_formula", "label": "Quadratic Formula",
///      "score": 1.42, "incorrect": 2, "skipped": 1, "correct": 4,
///      "attempts": 7, "last_seen": "2026-08-01 10:00:00"}
///   ],
///   "total": 12, "limit": 20, "offset": 0, "days": 90,
///   "source_available": true
/// }
/// ```
///
/// Concepts arrive sorted by `score` descending (weakest first) and the
/// order is preserved here. `source_available: false` with an empty
/// `concepts` list is a VALID state, not an error: the deployment simply
/// does not compose the lms module that writes quiz results. Callers must
/// treat it as "no server data", never as a failure to surface.
class WeakConceptsResponse {
  final List<WeakConcept> concepts;
  final int total;
  final int limit;
  final int offset;
  final int days;
  final bool sourceAvailable;

  const WeakConceptsResponse({
    this.concepts = const [],
    this.total = 0,
    this.limit = 20,
    this.offset = 0,
    this.days = 90,
    this.sourceAvailable = false,
  });

  /// Parses `response.data` — the api_response wrapper — or, defensively,
  /// an already-unwrapped payload map (one carrying a `concepts` key).
  factory WeakConceptsResponse.fromJson(dynamic json) {
    Map<String, dynamic> payload = const {};
    if (json is Map) {
      final data = json['data'];
      if (data is Map) {
        payload = Map<String, dynamic>.from(data);
      } else if (json.containsKey('concepts')) {
        payload = Map<String, dynamic>.from(json);
      }
    }
    final rawConcepts = payload['concepts'];
    return WeakConceptsResponse(
      concepts: [
        if (rawConcepts is List)
          for (final c in rawConcepts)
            if (c is Map) WeakConcept.fromJson(Map<String, dynamic>.from(c)),
      ],
      total: asInt(payload['total'], 0),
      limit: asInt(payload['limit'], 20),
      offset: asInt(payload['offset'], 0),
      days: asInt(payload['days'], 90),
      sourceAvailable: asBool(payload['source_available']),
    );
  }

  Map<String, dynamic> toJson() => {
        'data': {
          'concepts': concepts.map((c) => c.toJson()).toList(),
          'total': total,
          'limit': limit,
          'offset': offset,
          'days': days,
          'source_available': sourceAvailable,
        },
      };

  /// Lenient int coercion: Frappe form-dict round-trips can stringify
  /// numbers, and JSON floats arrive as double.
  static int asInt(dynamic v, int fallback) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  static double asDouble(dynamic v, double fallback) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  /// Frappe booleans commonly arrive as 0/1.
  static bool asBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v == 'true' || v == '1';
    return false;
  }
}

/// One aggregated weak concept: a subtopic the student answered incorrectly
/// or skipped across sessions, with its recency-decayed weakness score.
class WeakConcept {
  /// The stable subtopic slug (e.g. `quadratic_formula_derivation`) —
  /// the join key clients use to look up their own manifest titles.
  final String subtopicRef;

  /// Server-humanized display fallback for [subtopicRef]. Clients that
  /// hold a nicer title (e.g. from a session manifest) should prefer it.
  final String label;

  /// Recency-decayed weakness score; the list is sorted by this, descending.
  final double score;

  final int incorrect;
  final int skipped;
  final int correct;
  final int attempts;

  /// Server datetime string of the most recent attempt; null when absent.
  final String? lastSeen;

  const WeakConcept({
    required this.subtopicRef,
    this.label = '',
    this.score = 0,
    this.incorrect = 0,
    this.skipped = 0,
    this.correct = 0,
    this.attempts = 0,
    this.lastSeen,
  });

  factory WeakConcept.fromJson(Map<String, dynamic> json) => WeakConcept(
        subtopicRef: (json['subtopic_ref'] ?? '').toString(),
        label: (json['label'] ?? '').toString(),
        score: WeakConceptsResponse.asDouble(json['score'], 0),
        incorrect: WeakConceptsResponse.asInt(json['incorrect'], 0),
        skipped: WeakConceptsResponse.asInt(json['skipped'], 0),
        correct: WeakConceptsResponse.asInt(json['correct'], 0),
        attempts: WeakConceptsResponse.asInt(json['attempts'], 0),
        lastSeen: json['last_seen']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'subtopic_ref': subtopicRef,
        'label': label,
        'score': score,
        'incorrect': incorrect,
        'skipped': skipped,
        'correct': correct,
        'attempts': attempts,
        'last_seen': lastSeen,
      };
}
