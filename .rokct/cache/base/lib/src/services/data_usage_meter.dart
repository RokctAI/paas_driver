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

import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:base_sdk/src/services/local_storage.dart';

/// Which kind of network a byte travelled over.
enum DataNetwork { wifi, mobile }

/// One period's totals, split by network.
@immutable
class DataUsageTotals {
  final int wifi;
  final int mobile;

  const DataUsageTotals({this.wifi = 0, this.mobile = 0});

  int get total => wifi + mobile;

  @override
  bool operator ==(Object other) =>
      other is DataUsageTotals && other.wifi == wifi && other.mobile == mobile;

  @override
  int get hashCode => Object.hash(wifi, mobile);
}

/// Counts the data the app itself sends and receives, on the device.
///
/// Ray, 2026-11-06: the profile shows days in the app, and he wanted the
/// data used beside it, so a tab left open overnight can't quietly eat a
/// bundle. Nothing here asks the operating system: the meter sees only
/// the requests that go through base_sdk's [HttpService] (via
/// [DataUsageInterceptor]) and through any `package:http` client wrapped
/// in [MeteredHttpClient]. It counts bodies plus a small allowance per
/// request for headers, so it reads close to, but a little under, what
/// the phone's own data screen shows for the app (which also sees
/// images, maps and push).
///
/// Totals are kept for today and for this calendar month, each split into
/// Wi-Fi and mobile. Anything that is not a mobile network (Wi-Fi,
/// Ethernet, a VPN on Wi-Fi) counts as Wi-Fi. Writes to storage are
/// batched, a few seconds after the last request.
class DataUsageMeter extends ChangeNotifier {
  DataUsageMeter._();

  static final DataUsageMeter instance = DataUsageMeter._();

  /// Storage key for the one record ([LocalStorage.setJson]).
  static const String storageKey = 'data_usage.v1';

  /// Bytes added to each request and each response for the headers and
  /// framing nobody hands us. A typical JSON call carries 300-700 bytes
  /// of headers each way.
  static const int headerAllowance = 400;

  /// Clock seam for tests.
  @visibleForTesting
  static DateTime Function() now = DateTime.now;

  /// Network seam for tests. Null asks connectivity_plus.
  @visibleForTesting
  static DataNetwork? networkOverride;

  static const Duration _flushDelay = Duration(seconds: 5);

  String _day = '';
  String _month = '';
  DataUsageTotals _today = const DataUsageTotals();
  DataUsageTotals _thisMonth = const DataUsageTotals();
  bool _loaded = false;
  Timer? _flush;
  DataNetwork _network = DataNetwork.wifi;
  StreamSubscription<List<ConnectivityResult>>? _watch;

  DataUsageTotals get today {
    _load();
    _roll();
    return _today;
  }

  DataUsageTotals get thisMonth {
    _load();
    _roll();
    return _thisMonth;
  }

  /// Adds [bytes] (sent or received) to today and this month.
  void record(int bytes) {
    if (bytes <= 0) return;
    _load();
    _roll();
    _listen();
    final net = networkOverride ?? _network;
    _today = _add(_today, net, bytes);
    _thisMonth = _add(_thisMonth, net, bytes);
    _flush ??= Timer(_flushDelay, () {
      _flush = null;
      unawaited(save());
    });
    notifyListeners();
  }

  /// Writes the totals now. Called on a timer after [record].
  Future<void> save() async {
    _flush?.cancel();
    _flush = null;
    await LocalStorage.setJson(storageKey, {
      'day': _day,
      'month': _month,
      'dayWifi': _today.wifi,
      'dayMobile': _today.mobile,
      'monthWifi': _thisMonth.wifi,
      'monthMobile': _thisMonth.mobile,
    });
  }

  /// Forgets everything in memory (tests; a fresh read follows).
  @visibleForTesting
  void resetForTest() {
    _flush?.cancel();
    _flush = null;
    unawaited(_watch?.cancel());
    _watch = null;
    _loaded = false;
    _day = '';
    _month = '';
    _today = const DataUsageTotals();
    _thisMonth = const DataUsageTotals();
    _network = DataNetwork.wifi;
  }

  static DataUsageTotals _add(DataUsageTotals t, DataNetwork n, int bytes) =>
      n == DataNetwork.mobile
      ? DataUsageTotals(wifi: t.wifi, mobile: t.mobile + bytes)
      : DataUsageTotals(wifi: t.wifi + bytes, mobile: t.mobile);

  static String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _monthKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

  void _load() {
    if (_loaded) return;
    _loaded = true;
    final r = LocalStorage.getJson(storageKey) ?? const {};
    int n(String k) => (r[k] as num?)?.toInt() ?? 0;
    _day = r['day'] as String? ?? '';
    _month = r['month'] as String? ?? '';
    _today = DataUsageTotals(wifi: n('dayWifi'), mobile: n('dayMobile'));
    _thisMonth = DataUsageTotals(
      wifi: n('monthWifi'),
      mobile: n('monthMobile'),
    );
  }

  // A new day starts today at zero; a new month starts both at zero.
  void _roll() {
    final t = now();
    final day = _dayKey(t);
    final month = _monthKey(t);
    if (month != _month) {
      _month = month;
      _thisMonth = const DataUsageTotals();
    }
    if (day != _day) {
      _day = day;
      _today = const DataUsageTotals();
    }
  }

  void _listen() {
    if (_watch != null || networkOverride != null) return;
    try {
      final c = Connectivity();
      _watch = c.onConnectivityChanged.listen(_onNet, onError: (_) {});
      c.checkConnectivity().then(_onNet, onError: (_) {});
    } catch (_) {
      // No plugin (tests, an unsupported desktop): count as Wi-Fi.
    }
  }

  void _onNet(List<ConnectivityResult> r) {
    final onWifi =
        r.contains(ConnectivityResult.wifi) ||
        r.contains(ConnectivityResult.ethernet);
    _network = !onWifi && r.contains(ConnectivityResult.mobile)
        ? DataNetwork.mobile
        : DataNetwork.wifi;
  }

  /// A short size such as "820 KB", "4.2 MB" or "1.3 GB".
  static String format(int bytes) {
    const kb = 1024;
    const mb = kb * 1024;
    const gb = mb * 1024;
    String one(double v) =>
        v < 10 ? v.toStringAsFixed(1) : v.toStringAsFixed(0);
    if (bytes >= gb) return '${one(bytes / gb)} GB';
    if (bytes >= mb) return '${one(bytes / mb)} MB';
    return '${(bytes / kb).ceil()} KB';
  }

  /// Best guess at the bytes a Dio/http body takes on the wire.
  static int bodySize(Object? data) {
    if (data == null) return 0;
    if (data is String) return utf8.encode(data).length;
    if (data is List<int>) return data.length;
    if (data is FormData) return data.length;
    if (data is Map || data is List) {
      try {
        return utf8.encode(jsonEncode(data)).length;
      } catch (_) {
        return 0;
      }
    }
    return 0;
  }
}

/// Feeds every call made through a Dio client into [DataUsageMeter].
/// [HttpService] adds it to the clients it builds.
class DataUsageInterceptor extends Interceptor {
  const DataUsageInterceptor();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    DataUsageMeter.instance.record(
      DataUsageMeter.headerAllowance + DataUsageMeter.bodySize(options.data),
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _count(response);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final r = err.response;
    if (r != null) _count(r);
    handler.next(err);
  }

  static void _count(Response r) {
    final length = int.tryParse(r.headers.value('content-length') ?? '');
    DataUsageMeter.instance.record(
      DataUsageMeter.headerAllowance +
          (length ?? DataUsageMeter.bodySize(r.data)),
    );
  }
}

/// A `package:http` client that feeds what it sends and receives into
/// [DataUsageMeter]. Streams (such as a live chat) are counted as the
/// bytes arrive.
class MeteredHttpClient extends http.BaseClient {
  MeteredHttpClient([http.Client? inner]) : _inner = inner ?? http.Client();

  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final meter = DataUsageMeter.instance;
    final sent = request is http.Request
        ? request.bodyBytes.length
        : (request.contentLength ?? 0);
    meter.record(DataUsageMeter.headerAllowance + sent);
    final res = await _inner.send(request);
    meter.record(DataUsageMeter.headerAllowance);
    final counted = res.stream.map((chunk) {
      meter.record(chunk.length);
      return chunk;
    });
    return http.StreamedResponse(
      counted,
      res.statusCode,
      contentLength: res.contentLength,
      request: res.request,
      headers: res.headers,
      isRedirect: res.isRedirect,
      persistentConnection: res.persistentConnection,
      reasonPhrase: res.reasonPhrase,
    );
  }

  @override
  void close() => _inner.close();
}
