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

/// The board column moved into orders_sdk with the approved 33a redesign
/// (`presentation/board/board_column.dart`) so it analyzes and tests as
/// package code — the card no longer needs host-path imports. This shim
/// keeps any composed import of the old template path compiling.
export 'package:orders_sdk/src/manager/presentation/board/board_column.dart'
    show BoardOrderColumn, BoardDragData, BoardCountPill;
