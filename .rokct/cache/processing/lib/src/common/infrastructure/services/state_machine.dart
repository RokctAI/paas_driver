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

// compliance-ignore-file: obs-flutter-trace (pure re-export of base_sdk's ProcessingStateMachine; no HTTP calls in this file)

// Moved to base_sdk (2026-07-24) — see processing_contract.dart in this
// same directory for why. Re-exported here for existing consumers.
export 'package:base_sdk/src/domain/interface/processing_contract.dart'
    show ProcessingStateMachine;
