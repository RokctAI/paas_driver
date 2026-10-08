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

import 'package:base_sdk/base_sdk.dart' show DemoSession;

/// The demo sign-in addresses auth_sdk 1.13.0 signed in locally whatever
/// the network: the five role-mapped @demo.rokct.ai accounts and the demo
/// identity's own address. Kept when 1.14.0 replaced the mock repository
/// with base_sdk's demo interceptor (Ray, 2026-10-03).
const Set<String> demoSignInAddresses = {
  'partner@demo.rokct.ai',
  'admin@demo.rokct.ai',
  'customer@demo.rokct.ai',
  'driver@demo.rokct.ai',
  'manager@demo.rokct.ai',
  'thandi.mokoena@outlook.com',
};

/// Whether [email] is one of [demoSignInAddresses] (trimmed, any case).
bool isDemoSignInAddress(String email) =>
    demoSignInAddresses.contains(email.trim().toLowerCase());

/// Switches the session to demo when [email] is a listed demo address, so
/// the sign-in that follows goes through the real AuthRepository and is
/// answered by base_sdk's DemoGatewayInterceptor from the auth fixtures,
/// with no network. Returns whether it did.
Future<bool> beginDemoSignInIfListed(String email) async {
  if (!isDemoSignInAddress(email)) return false;
  await DemoSession.instance.activate();
  return true;
}
