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

/// The login screen's silencer (Ray, 2026-10-04: "Login screen on loading
/// still shows a backend error before anything is done").
///
/// The page probes the backend by itself on load (languages, translations).
/// Those probes are background work: when they fail the user has done
/// nothing, so no backend or no-connection error is shown. Only an action
/// the user took (a submit, a tap) may surface one. Offline is never an
/// error either way — failures still go to telemetry/debug output.
bool shouldSurfaceLoginError({required bool userInitiated}) => userInitiated;
