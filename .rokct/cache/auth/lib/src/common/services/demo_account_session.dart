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

import 'package:base_sdk/src/models/models.dart';
import 'package:base_sdk/src/services/demo_session.dart';

/// Lands the runtime demo switch for the account a credential exchange
/// came back with - "demo login in production" (Ray 2026-09-08).
///
/// Called by `LoginNotifier._establishSession` strictly AFTER the real
/// backend has accepted the credentials and the composed session policy
/// has admitted the role. The decision rests on one thing: the backend's
/// server-asserted `is_demo_account` marker on the login payload's user
/// ([UserModel.isDemoAccount]). A marked account (a real account on the
/// production backend, one per role) turns [DemoSession] on; any other
/// account turns it off, so a demo session left by an earlier sign-in
/// can never leak into a real one. Nothing here reads the typed address
/// or the password, and nothing here renders: the account is a real
/// person to the user and no screen says demo.
///
/// Phase 1: flipping the session changes nothing a user can see beyond
/// the flag. Phase 2 (SDK data wiring) re-registers the data
/// repositories on `DemoSession.instance.addListener`, which is what
/// serves the session from the in-app fixtures.
Future<void> applyDemoAccountSession(UserModel? user) {
  if (user?.isDemoAccount ?? false) {
    return DemoSession.instance.activate();
  }
  return DemoSession.instance.clear();
}
