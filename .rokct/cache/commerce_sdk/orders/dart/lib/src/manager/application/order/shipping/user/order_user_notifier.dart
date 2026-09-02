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

import 'order_user_state.dart';
import 'package:orders_sdk/src/manager/domain/interface/pos_customers.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

class OrderUserNotifier extends StateNotifier<OrderUserState> {
  final PosCustomersFacade _usersRepository;
  String _query = '';
  bool _hasMore = true;
  int _page = 0;
  Timer? _timer;

  OrderUserNotifier(this._usersRepository)
      : super(OrderUserState(userTextController: TextEditingController()));

  void addCreatedUser(UserData? user) {
    List<UserData> users = List.from(state.users);
    if (user != null) {
      users.insert(0, user);
    }
    state = state.copyWith(users: users);
  }

  void clearSelectedUserInfo() {
    state = state.copyWith(selectedUser: null, selectedIndex: 0);
    state.userTextController?.text = '';
  }

  void setSelectedUser(int index) {
    final selectedUser = state.users[index];
    state = state.copyWith(selectedIndex: index, selectedUser: selectedUser);
    state.userTextController?.text =
        '${selectedUser.firstname ?? AppHelpers.getTranslation(TrKeys.noName)} ${selectedUser.lastname ?? ''}';
  }

  setPhone(String value){
    state=state.copyWith(selectedUser: state.selectedUser?.copyWith(phone: value));
  }

  Future<void> _search({RefreshController? refreshController}) async {
    refreshController?.resetNoData();
    _page = 0;
    _hasMore = true;
    state = state.copyWith(isLoading: true);
    final response = await _usersRepository.searchUsers(
      query: _query.isEmpty ? null : _query.trim(),
      page: ++_page,
    );
    response.when(
      success: (data) {
        final List<UserData> users = data.data ?? [];
        state = state.copyWith(users: users, isLoading: false);
        _hasMore = users.length >= 14;
      },
      failure: (fail,status) {
        debugPrint('===> search user fail $fail');
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

  Future<void> fetchMoreUsers({RefreshController? refreshController}) async {
    if (!_hasMore) {
      refreshController?.loadNoData();
      return;
    }
    final response = await _usersRepository.searchUsers(
      query: _query.isEmpty ? null : _query.trim(),
      page: ++_page,
    );
    response.when(
      success: (data) {
        final List<UserData> newUsers = data.data ?? [];
        List<UserData> users = List.from(state.users);
        users.addAll(newUsers);
        _hasMore = newUsers.length >= 14;
        state = state.copyWith(users: users);
        refreshController?.loadComplete();
      },
      failure: (fail,status) {
        refreshController?.loadFailed();
        debugPrint('===> fetch more users fail $fail');
      },
    );
  }

  Future<void> refreshUsers({RefreshController? refreshController}) async {
    debugPrint('===> refresh users function called');
    _page = 0;
    final response = await _usersRepository.searchUsers(
      query: _query.isEmpty ? null : _query.trim(),
      page: ++_page,
    );
    response.when(
      success: (data) {
        final List<UserData> users = data.data ?? [];
        state = state.copyWith(users: users);
        _hasMore = users.length >= 14;
        refreshController?.refreshCompleted();
        refreshController?.resetNoData();
      },
      failure: (fail,status) {
        debugPrint('===> refresh users fail $fail');
        refreshController?.refreshFailed();
      },
    );
  }

  Future<void> initialFetchUsers({RefreshController? refreshController}) async {
    _query = '';
    if (state.users.isNotEmpty) {
      if (state.selectedUser == null) {
        final selectedUser = state.users[0];
        state = state.copyWith(selectedIndex: 0, selectedUser: selectedUser);
        state.userTextController?.text =
            '${selectedUser.firstname ?? AppHelpers.getTranslation(TrKeys.noName)} ${selectedUser.lastname ?? ''}';
      }
      return;
    }
    _hasMore = true;
    _page = 0;
    state = state.copyWith(isLoading: true);
    final response = await _usersRepository.searchUsers(
      query: _query.isEmpty ? null : _query.trim(),
      page: ++_page,
    );
    response.when(
      success: (data) {
        final List<UserData> users = data.data ?? [];
        UserData? selectedUser;
        if (users.isNotEmpty) {
          selectedUser = users[0];
        }
        state = state.copyWith(
          users: users,
          selectedUser: selectedUser,
          selectedIndex: 0,
          isLoading: false,
        );
        if (selectedUser != null) {
          state.userTextController?.text =
              '${selectedUser.firstname} ${selectedUser.lastname ?? ''}';
        }
        _hasMore = users.length >= 14;
      },
      failure: (error,status) {
        debugPrint('====> fetch users fail $error');
        state = state.copyWith(isLoading: false);
      },
    );
  }
}
