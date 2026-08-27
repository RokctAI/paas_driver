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

import 'dart:async';
import 'package:base_sdk/src/handlers/api_result.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:base_sdk/src/services/app_helpers.dart';
import 'create_user_state.dart';
import 'package:orders_sdk/src/manager/domain/interface/pos_customers.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';

class CreateUserNotifier extends StateNotifier<CreateUserState> {
  final PosCustomersFacade _usersRepository;
  String _email = '';
  String _phone = '';
  String _lastname = '';
  String _firstname = '';

  CreateUserNotifier(this._usersRepository) : super(const CreateUserState());

  void setEmail(String value) {
    _email = value.trim();
  }

  void setPhone(String value) {
    _phone = value.trim();
  }

  void setLastname(String value) {
    _lastname = value.trim();
  }

  void setFirstname(String value) {
    _firstname = value.trim();
  }

  Future<void> createUser(BuildContext context,{
    Function(UserData?)? created,
    VoidCallback? failed,
  }) async {
    state = state.copyWith(isLoading: true);
    final response = await _usersRepository.createUser(
      firstname: _firstname,
      lastname: _lastname,
      phone: _phone,
      email: _email,
    );
    response.when(
      success: (data) {
        state = state.copyWith(isLoading: false);
        created?.call(data.data);
      },
      failure: (error,status) {
        debugPrint('====> create user fail $error');
        failed?.call();
        state = state.copyWith(isLoading: false);
        AppHelpers.showCheckTopSnackBar(context, error);
      },
    );
  }
}
