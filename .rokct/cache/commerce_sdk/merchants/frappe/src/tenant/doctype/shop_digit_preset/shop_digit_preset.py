# Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.

# Shop Digit Preset — one row of the till keypad's digit→product map
# (design strip section 42, chips 803/804/805: the DIGIT PRESETS grid on
# the Quick flow surface). A shop maps digits 1–9 to products it sells
# over and over; with `Shop.keypad_autodial` on and NOTHING on the till's
# ticket, pressing that digit drops the mapped product straight on. A
# digit with no row here is inert on the till — deliberately quiet, not
# an error (chip 805).
#
# Child table of Shop (`digit_presets`). The digit is unique per shop:
# `seller_shop.update_quick_flow_settings` is the only writer and it
# rebuilds the whole table from the client's map, so a digit can never
# hold two products.

import frappe
from frappe.model.document import Document


class ShopDigitPreset(Document):
    pass
