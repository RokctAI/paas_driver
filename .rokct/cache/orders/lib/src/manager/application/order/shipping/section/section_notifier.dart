import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orders_sdk/src/manager/domain/interface/pos_sections_tables.dart';

import 'section_state.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';

class SectionNotifier extends StateNotifier<SectionState> {
  String _query = '';
  bool _hasMore = true;
  int _page = 0;
  Timer? _timer;

  final PosSectionsTablesFacade _sectionsTables;

  SectionNotifier(this._sectionsTables)
      : super(SectionState(textController: TextEditingController()));

  void clearSelectSectionInfo() {
    state = state.copyWith(selectSection: null, selectedIndex: 0);
    state.textController?.text = '';
  }

  void setSelectSection(int index) {
    final selectSection = state.sections[index];
    state = state.copyWith(selectedIndex: index, selectSection: selectSection);
    state.textController?.text = selectSection.translation?.title ?? '';
  }

  Future<void> _search({RefreshController? refreshController}) async {
    refreshController?.resetNoData();
    _page = 0;
    _hasMore = true;
    state = state.copyWith(isLoading: true);
    final response = await _sectionsTables.getSections(
      query: _query.isEmpty ? null : _query.trim(),
      page: ++_page,
    );
    response.when(
      success: (data) {
        final List<ShopSection> sections = data.data ?? [];
        state = state.copyWith(sections: sections, isLoading: false);
        _hasMore = sections.length >= 14;
      },
      failure: (fail, status) {
        debugPrint('===> search section fail $fail');
        state = state.copyWith(isLoading: false);
      },
    );
  }

  void setQuery({
    RefreshController? refreshController,
    required String text,
  }) {
    if (text.trim() == _query) {
      return;
    }
    _query = text.trim();
    _timer?.cancel();
    _timer = Timer(
      const Duration(milliseconds: 300),
      () {
        _search(refreshController: refreshController);
      },
    );
  }

  Future<void> fetchMoreSections({RefreshController? refreshController}) async {
    if (!_hasMore) {
      refreshController?.loadNoData();
      return;
    }
    final response = await _sectionsTables.getSections(
      query: _query.isEmpty ? null : _query.trim(),
      page: ++_page,
    );
    response.when(
      success: (data) {
        List<ShopSection> sections = List.from(state.sections);
        sections.addAll(data.data ?? []);
        _hasMore = (data.data?.length ?? 0) >= 14;
        state = state.copyWith(sections: sections);
        refreshController?.loadComplete();
      },
      failure: (fail, status) {
        refreshController?.loadFailed();
        debugPrint('===> fetch more sections fail $fail');
      },
    );
  }

  Future<void> refreshSections({RefreshController? refreshController}) async {
    debugPrint('===> refresh sections function called');
    _page = 0;
    final response = await _sectionsTables.getSections(
      query: _query.isEmpty ? null : _query.trim(),
      page: ++_page,
    );
    response.when(
      success: (data) {
        final List<ShopSection> sections = data.data ?? [];
        state = state.copyWith(sections: sections);
        _hasMore = sections.length >= 14;
        refreshController?.refreshCompleted();
        refreshController?.resetNoData();
      },
      failure: (fail, status) {
        debugPrint('===> refresh sections fail $fail');
        refreshController?.refreshFailed();
      },
    );
  }

  Future<void> initialFetchSections({RefreshController? refreshController}) async {
    _query = '';
    if (state.sections.isNotEmpty) {
      if (state.selectSection == null) {
        final selectSection = state.sections[0];
        state = state.copyWith(selectedIndex: 0, selectSection: selectSection);
        state.textController?.text = selectSection.translation?.title ?? "";
      }
    }
    _hasMore = true;
    _page = 0;
    state = state.copyWith(isLoading: true);
    final response = await _sectionsTables.getSections(
      query: _query.isEmpty ? null : _query.trim(),
      page: ++_page,
    );
    response.when(
      success: (data) {
        final List<ShopSection> sections = data.data ?? [];
        ShopSection? selectSection;
        if (sections.isNotEmpty) {
          selectSection = sections[0];
        }
        state = state.copyWith(
          sections: sections,
          selectSection: selectSection,
          selectedIndex: 0,
          isLoading: false,
        );
        if (selectSection != null) {
          state.textController?.text = selectSection.translation?.title ?? '';
        }
        _hasMore = sections.length >= 14;
      },
      failure: (error, status) {
        debugPrint('====> fetch sections fail $error');
        state = state.copyWith(isLoading: false);
      },
    );
  }
}
