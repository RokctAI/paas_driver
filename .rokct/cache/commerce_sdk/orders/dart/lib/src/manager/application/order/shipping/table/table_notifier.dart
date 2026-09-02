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
import 'package:base_sdk/src/handlers/api_result.dart';

import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orders_sdk/src/manager/domain/interface/pos_sections_tables.dart';

import 'table_state.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';

class TableNotifier extends StateNotifier<TableState> {
  String _query = '';
  bool _hasMore = true;
  int _page = 0;
  Timer? _timer;

  final PosSectionsTablesFacade _sectionsTables;

  TableNotifier(this._sectionsTables)
      : super(TableState(textController: TextEditingController()));

  void clearSelectTableInfo() {
    state = state.copyWith(selectTable: null, selectedIndex: 0);
    state.textController?.text = '';
  }

  void setSelectTable(int index) {
    final selectTable = state.tables[index];
    state = state.copyWith(selectedIndex: index, selectTable: selectTable);
    state.textController?.text = selectTable.name ?? '';
  }

  Future<void> _search({
    RefreshController? refreshController,
    required String? sectionId,
  }) async {
    refreshController?.resetNoData();
    _page = 0;
    _hasMore = true;
    state = state.copyWith(isLoading: true);
    final response = await _sectionsTables.getTables(
      query: _query.isEmpty ? null : _query.trim(),
      page: ++_page,
      shopSectionId: sectionId,
    );
    response.when(
      success: (data) {
        final List<TableData> tables = data.data ?? [];
        state = state.copyWith(tables: tables, isLoading: false);
        _hasMore = tables.length >= 14;
      },
      failure: (fail, status) {
        debugPrint('===> search table fail $fail');
        state = state.copyWith(isLoading: false);
      },
    );
  }

  void setQuery({
    RefreshController? refreshController,
    required String text,
    required String? sectionId,
  }) {
    if (text.trim() == _query) {
      return;
    }
    _query = text.trim();
    _timer?.cancel();
    _timer = Timer(
      const Duration(milliseconds: 300),
      () {
        _search(refreshController: refreshController,sectionId: sectionId);
      },
    );
  }

  Future<void> fetchMoreTables({
    RefreshController? refreshController,
    required String? sectionId,
  }) async {
    if (!_hasMore) {
      refreshController?.loadNoData();
      return;
    }
    final response = await _sectionsTables.getTables(
      query: _query.isEmpty ? null : _query.trim(),
      page: ++_page,
      shopSectionId: sectionId,
    );
    response.when(
      success: (data) {
        List<TableData> tables = List.from(state.tables);
        tables.addAll(data.data ?? []);
        _hasMore = (data.data?.length ?? 0) >= 14;
        state = state.copyWith(tables: tables);
        refreshController?.loadComplete();
      },
      failure: (fail, status) {
        refreshController?.loadFailed();
        debugPrint('===> fetch more tables fail $fail');
      },
    );
  }

  Future<void> refreshTables({
    RefreshController? refreshController,
    required String? sectionId,
  }) async {
    debugPrint('===> refresh tables function called');
    _page = 0;
    final response = await _sectionsTables.getTables(
      query: _query.isEmpty ? null : _query.trim(),
      page: ++_page,
      shopSectionId: sectionId,
    );
    response.when(
      success: (data) {
        final List<TableData> tables = data.data ?? [];
        state = state.copyWith(tables: tables);
        _hasMore = tables.length >= 14;
        refreshController?.refreshCompleted();
        refreshController?.resetNoData();
      },
      failure: (fail, status) {
        debugPrint('===> refresh tables fail $fail');
        refreshController?.refreshFailed();
      },
    );
  }

  Future<void> initialFetchTables({
    RefreshController? refreshController,
    String? sectionId,
  }) async {
    _query = '';
    if (state.tables.isNotEmpty) {
      if (state.selectTable == null) {
        final selectTable = state.tables[0];
        state = state.copyWith(selectedIndex: 0, selectTable: selectTable);
        state.textController?.text = selectTable.name ?? "";
      }
    }
    _hasMore = true;
    _page = 0;
    state = state.copyWith(isLoading: true);
    final response = await _sectionsTables.getTables(
      query: _query.isEmpty ? null : _query.trim(),
      shopSectionId: sectionId,
      page: ++_page,
    );
    response.when(
      success: (data) {
        final List<TableData> tables = data.data ?? [];
        TableData? selectTable;
        if (tables.isNotEmpty && state.selectTable == null) {
          selectTable = tables[0];
        } else {
          selectTable = state.selectTable;
        }
        state = state.copyWith(
          tables: tables,
          selectTable: selectTable,
          selectedIndex: 0,
          isLoading: false,
        );
        if (selectTable != null) {
          state.textController?.text = selectTable.name ?? '';
        }
        _hasMore = tables.length >= 14;
      },
      failure: (error, status) {
        debugPrint('====> fetch tables fail $error');
        state = state.copyWith(isLoading: false);
      },
    );
  }
}
