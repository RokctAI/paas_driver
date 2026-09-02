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

import '../../domain/interface/processing_contract.dart';

class ProcessingSdkState {
  final bool isLoading;
  final List<ProcessingContract> contracts;
  final String? error;

  const ProcessingSdkState({
    this.isLoading = false,
    this.contracts = const [],
    this.error,
  });

  ProcessingSdkState copyWith({
    bool? isLoading,
    List<ProcessingContract>? contracts,
    String? error,
  }) {
    return ProcessingSdkState(
      isLoading: isLoading ?? this.isLoading,
      contracts: contracts ?? this.contracts,
      error: error,
    );
  }
}
