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

// Moved to base_sdk (2026-07-24) so feature SDKs enforce identical
// state-transition rules without importing processing_sdk directly
// (ADR-005: only base_sdk is imported cross-SDK). Re-exported here so
// processing_sdk's own existing consumers are unaffected.
export 'package:base_sdk/src/domain/interface/processing_contract.dart';
