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

/// "There are 3 parcels" / "There is 1 parcel": the driver list subtitles,
/// pluralised. Before this the count was glued between "There are" and the
/// plural noun, so one parcel read "There are 1 parcels" (tour 1114b).
String driverCountLine({
  required int count,
  required String singularKey,
  required String pluralKey,
}) {
  final bool one = count == 1;
  final String verb = AppHelpers.getTranslation(one ? 'there_is' : 'there_are');
  final String noun =
      AppHelpers.getTranslation(one ? singularKey : pluralKey).toLowerCase();
  return '$verb $count $noun';
}
