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


import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

/// "Does this composed app actually have that route?", asked of the host's
/// own generated router.
///
/// [AppRoutes] is a fixed method surface whose bodies are injected per
/// installed SDK, so calling a method no installed SDK declared throws a
/// StateError out of the host's `noSuchMethod`. That is the right answer for
/// a navigation the app cannot do without, and the wrong one for an optional
/// affordance: an SDK that offers "and here is your profile" must be able to
/// offer nothing at all in a compose that has no profile page, rather than
/// crash the moment someone taps it.
///
/// So SDK code asks here first. auto_route keys its [RouteCollection] by
/// route NAME (the same key `_canHandleNavigation` checks before it pushes),
/// which is what an SDK manifest's `routes` entry declares, so the lookup is
/// against the real router rather than against a guess.
abstract final class RoutePresence {
  /// The name base_sdk's manifest mounts the generic profile under:
  /// `{"path": "/generic-profile", "page": "GenericProfileRoute.page"}`, with
  /// `AppRoutes.pushGenericProfileRoute` as its declared navigation. Not
  /// `ProfileRoute` — marketplace_sdk owns that name.
  static const String genericProfileRouteName = 'GenericProfileRoute';

  /// Whether [routeName] is registered on the host's root router.
  ///
  /// False rather than throwing when [context] has no router above it at all,
  /// which is both the widget-test case and any SDK widget rendered outside
  /// the app shell.
  static bool has(BuildContext context, String routeName) {
    final StackRouter? router = StackRouterScope.of(context)?.controller;
    if (router == null) return false;
    return router.root.routeCollection.containsKey(routeName);
  }
}
