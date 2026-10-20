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

import 'package:base_sdk/src/domain/interface/notification.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/models/response/notification_response.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/telemetry.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../infrastructure/repositories/notification_repository.dart';
import 'notification_list_language.dart';

/// The signed-in user's notification list, from the comms endpoints:
/// api.notification.get_user_notifications (list), read_one_notification
/// (tap on an unread row) and read_all_notifications (header action).
///
/// Default chosen: list is newest-first as the server returns it, shows
/// unread and read rows together, and tapping an unread row marks only that
/// row read. Errors show one friendly line; the server detail goes to
/// TelemetryClient.
class NotificationInboxPage extends StatefulWidget {
  const NotificationInboxPage({super.key});

  @override
  State<NotificationInboxPage> createState() => _NotificationInboxPageState();
}

class _NotificationInboxPageState extends State<NotificationInboxPage> {
  List<NotificationModel> _items = const [];
  bool _loading = true;
  bool _failed = false;
  bool _loadingMore = false;
  bool _moreFailed = false;
  bool _hasMore = true;
  int _page = 1;

  NotificationRepositoryFacade get _repo =>
      GetIt.instance<NotificationRepositoryFacade>();

  bool get _available =>
      GetIt.instance.isRegistered<NotificationRepositoryFacade>();

  int get _unread => _items.where((n) => n.readAt == null).length;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    if (!_available) {
      setState(() {
        _loading = false;
        _failed = true;
      });
      return;
    }
    setState(() {
      _loading = true;
      _failed = false;
      _moreFailed = false;
    });
    final result = await _repo.getNotifications(page: 1);
    if (!mounted) return;
    result.when(
      success: (data) => setState(() {
        _items = data.data ?? const [];
        _page = 1;
        _hasMore = _items.length >= NotificationRepositoryImpl.pageSize;
        _loading = false;
      }),
      failure: (error, status) {
        _report('notification_list_failed', error, status);
        setState(() {
          _loading = false;
          _failed = true;
        });
      },
    );
  }

  /// Loads the next page; stops once a page comes back short.
  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _loading) return;
    setState(() {
      _loadingMore = true;
      _moreFailed = false;
    });
    final result = await _repo.getNotifications(page: _page + 1);
    if (!mounted) return;
    result.when(
      success: (data) => setState(() {
        final rows = data.data ?? const <NotificationModel>[];
        _items = [..._items, ...rows];
        _page += 1;
        _hasMore = rows.length >= NotificationRepositoryImpl.pageSize;
        _loadingMore = false;
      }),
      failure: (error, status) {
        _report('notification_list_more_failed', error, status);
        // Keep what is shown; the end row turns into "Tap to retry" and
        // nothing reloads until the user taps it.
        setState(() {
          _loadingMore = false;
          _moreFailed = true;
        });
      },
    );
  }

  Future<void> _openRow(NotificationModel item) async {
    final id = item.id;
    if (item.readAt != null || id == null) return;
    final result = await _repo.readOne(id: id);
    if (!mounted) return;
    result.when(
      success: (_) => setState(() => item.readAt = DateTime.now()),
      failure: (error, status) {
        _report('notification_read_one_failed', error, status);
        AppHelpers.showCheckTopSnackBar(
          context,
          AppHelpers.getTranslation(TrKeys.somethingWentWrongWithTheServer),
        );
      },
    );
  }

  Future<void> _readAll() async {
    final result = await _repo.readAll();
    if (!mounted) return;
    result.when(
      success: (_) => setState(() {
        final now = DateTime.now();
        for (final item in _items) {
          item.readAt ??= now;
        }
      }),
      failure: (error, status) {
        _report('notification_read_all_failed', error, status);
        AppHelpers.showCheckTopSnackBar(
          context,
          AppHelpers.getTranslation(TrKeys.somethingWentWrongWithTheServer),
        );
      },
    );
  }

  void _report(String type, Object? error, Object? status) {
    unawaited(TelemetryClient.I.logError(
      type: type,
      context: {'status': status, 'error': error},
    ));
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final unread = _unread;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppHelpers.getTranslation(TrKeys.notifications)),
        actions: [
          if (unread > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: NotificationReadAllAction(
                  onTap: () => unawaited(_readAll()),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _body(brightness),
      ),
    );
  }

  Widget _body(Brightness brightness) {
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_failed && _items.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Center(
            child: Text(
              AppHelpers.getTranslation(TrKeys.somethingWentWrongWithTheServer),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }
    if (_items.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Center(
            child: Text(
              AppHelpers.getTranslation(TrKeys.nothingFound),
              style: TextStyle(color: AppStyle.inkFor(brightness)),
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      itemCount: _items.length + (_hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        if (index >= _items.length) {
          if (_moreFailed) {
            return InkWell(
              onTap: () => unawaited(_loadMore()),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    AppHelpers.getTranslation(
                        TrKeys.somethingWentWrongWithTheServer) +
                        ' - Tap to retry',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }
          // End of the list: ask for the next page after this frame (a
          // setState during build is not allowed).
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) unawaited(_loadMore());
          });
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final item = _items[index];
        return NotificationRow(
          notification: item,
          onTap: () => unawaited(_openRow(item)),
        );
      },
    );
  }
}
