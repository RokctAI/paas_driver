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


import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:base_sdk/src/application/profile/profile_notifier.dart';
import 'package:base_sdk/src/application/profile/profile_state.dart';

/// Resolves the account facades only where the composing shell registered
/// them ([ProfileNotifier.fromLocator]): the same three GetIt singletons as
/// before for a shell that registers all three, a no-op account surface —
/// the generic profile host's anonymous mode — for one that registers
/// none, instead of a `GetIt: Object/factory ... is not registered` throw
/// out of the first `ref.watch`.
final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>(
  (ref) => ProfileNotifier.fromLocator(),
);
