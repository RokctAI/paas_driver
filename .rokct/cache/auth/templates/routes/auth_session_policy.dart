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
