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
from paas.api.ads_package.ads_package import create_ads_package, get_ads_packages


class TestAdsPackage(FrappeTestCase):
    def tearDown(self):
        frappe.db.rollback()

    def test_ads_package_crud(self):
        # 1. Create Ads Package
        data = {
            "title": "Premium Banner",
            "price": 50,
            "time_type": "day",
            "time": 7
        }
        package = create_ads_package(data)
        self.assertEqual(package.title, "Premium Banner")
        self.assertEqual(package.price, 50)

        # 2. Get Ads Packages
        packages = get_ads_packages()
        self.assertTrue(len(packages) > 0)
        self.assertEqual(packages[0].title, "Premium Banner")
