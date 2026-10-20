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

import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/models/models.dart';

/// auth_sdk-local capability for shared sign-in between the fleet's own
/// apps on one phone (Users auth: `api.auth.handoff_mint` /
/// `api.auth.handoff_redeem`).
///
/// Like [SessionTokenRefresh] it is NOT part of base_sdk's fixed
/// AuthRepositoryFacade: auth_sdk's AuthRepository implements it next to
/// the facade and callers check `is SessionHandoffExchange`.
abstract class SessionHandoffExchange {
  /// A one-time sign-in code for the signed-in account, for the app
  /// [targetPackage] only (when given). Null when none could be minted
  /// (signed out, offline, backend refused): the caller then hands over
  /// the local account record or opens the app the ordinary way.
  Future<String?> mintHandoffCode({String? targetPackage});

  /// Spends [code] for a NEW session of this app ([clientId] is this app's
  /// package name). Answers exactly like a password sign-in.
  Future<ApiResult<LoginResponse>> redeemHandoffCode({
    required String code,
    String? clientId,
  });
}
