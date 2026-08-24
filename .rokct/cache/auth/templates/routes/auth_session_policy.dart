// Copyright (c) 2026 RokctAI
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

// ignore_for_file: unused_import
// Host composition file (ADR-005), installed by auth_sdk — the
// session-policy shell. auth_sdk owns the auth FLOWS; which accounts this
// particular app admits, and where each allowed role lands, is composition
// DATA declared in a manifest "session_policy" key (normally by the app's
// home SDK, gated under "app_type" — e.g. merchants_sdk declaring the
// manager policy only for manager builds; at most ONE installed SDK may
// declare it, like brand_hook). sdk_installer_base.py's
// update_session_policy() turns that declaration into the single
// DeclaredSessionPolicy assignment injected between the markers below —
// the exact same manifest -> marker-block pipeline update_registration_steps()
// uses for auth's registration contributions.
//
// With no declared policy the marker block stays empty, AuthSessionPolicy.I
// keeps its built-in default (allow every account, land on the legacy
// `isDemo ? replaceUiTypeRoute : goHome` branch), and the app behaves
// exactly as it did before this shell existed.
//
// [applyComposedSessionPolicy] is invoked by the installed
// auth_route_pages.dart LoginRoute wrapper before the login page builds —
// the login entry point every sign-in path goes through (base_sdk's splash
// sends tokenless users to /login) — so the policy is in force for every
// credential exchange without main.dart needing another wiring point.

import 'package:auth_sdk/src/common/domain/interface/auth_session_policy.dart';

// @generated-session-policy-imports-start
// @generated-session-policy-imports-end

void applyComposedSessionPolicy() {
  // @generated-session-policy-start
  // @generated-session-policy-end
}
