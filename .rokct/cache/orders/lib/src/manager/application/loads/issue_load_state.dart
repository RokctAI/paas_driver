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

import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:orders_sdk/src/manager/domain/load_draft.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/data/load_data.dart';

part 'issue_load_state.freezed.dart';

/// The load being put together on /load/issue: who it goes to, what goes
/// on it, and whether it is on the wire yet.
@freezed
abstract class IssueLoadState with _$IssueLoadState {
  const factory IssueLoadState({
    @Default(false) bool isLoadingDrivers,
    @Default([]) List<LoadDeliveryman> drivers,
    String? deliverymanId,
    @Default([]) List<LoadDraftLine> lines,
    @Default(false) bool isSubmitting,
  }) = _IssueLoadState;

  const IssueLoadState._();

  /// The shop cannot issue a load to nobody, nor an empty one.
  bool get canIssue =>
      !isSubmitting && canIssueLoad(deliverymanId: deliverymanId, lines: lines);

  num get draftValue => draftLoadValue(lines);
}
