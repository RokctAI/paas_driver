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

import 'package:base_sdk/src/services/app_helpers.dart';

/// True when a sign-in failure is the backend never answering (base_sdk's
/// authored couldNotReachServer / serverTookTooLong lines) rather than a
/// refusal the server actually sent. [LoginNotifier.login] treats it as the
/// app being used offline and takes the offline path without a toast.
bool loginFailureMeansOffline(String failure) =>
    AppHelpers.isAuthoredConnectionMessage(failure);
