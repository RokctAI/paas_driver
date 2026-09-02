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

# Copyright (c) 2025 ROKCT INTELLIGENCE (PTY) LTD
# For license information, please see license.txt

import frappe
from frappe.tests.utils import FrappeTestCase
from paas.api.brand.brand import create_brand, get_brands, get_brand_by_uuid, update_brand, delete_brand


class TestBrand(FrappeTestCase):
    def setUp(self):
        frappe.set_user("Administrator")
        # Cleanup
        frappe.db.delete("Brand", {"title": "Test Brand"})

    def tearDown(self):
        frappe.db.rollback()

    def test_brand_crud(self):
        # 1. Create
        brand_data = {
            "title": "Test Brand",
            "slug": "test-brand",
            "active": 1
        }
        brand = create_brand(brand_data)
        self.assertTrue(brand['uuid'])
        self.assertEqual(brand['title'], "Test Brand")

        # 2. Get List
        brands = get_brands()
        self.assertTrue(len(brands) > 0)

        # 3. Get by UUID
        fetched_brand = get_brand_by_uuid(brand['uuid'])
        self.assertEqual(fetched_brand['title'], "Test Brand")

        # 4. Update
        updated_data = {"title": "Updated Brand"}
        update_brand(brand['uuid'], updated_data)
        self.assertEqual(
            frappe.db.get_value(
                "Brand", {
                    "uuid": brand['uuid']}, "title"), "Updated Brand")

        # 5. Delete
        delete_brand(brand['uuid'])
        self.assertFalse(frappe.db.exists("Brand", {"uuid": brand['uuid']}))
