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

# Tenant context: session.user validation
import frappe
from paas.api.repeating_order import create_repeating_order
from paas.api.payment.payment import tokenize_card, process_wallet_top_up
from frappe.utils import add_days, nowdate


def verify_flow():
    trace_id = None
    """
    Verify auto order flow with trace context.
    """
    frappe.set_user("Administrator")

    # 1. Create a Test Order
    order = frappe.get_doc(
        {
            "doctype": "Order",
            "user": "Administrator",
            "grand_total": 100,
            "items": [],  # Simplified
        }
    )
    order.flags.ignore_permissions = True
    order.insert()

    # 2. Create Saved Card
    card = tokenize_card("4242424242424242", "Test User", "12/25", "123")
    # tokenize_card returns the Saved Card docname, not the gateway reuse
    # credential -- that is a Password field and stays server-side. The
    # docname is the handle the charge endpoints take.
    saved_card = card["name"]
    print(f"Card Saved: {saved_card}")

    # 3. Ensure Wallet is Empty
    user_doc = frappe.get_doc("User", "Administrator")
    user_doc.wallet_balance = 0
    user_doc.ringfenced_balance = 0
    user_doc.save(ignore_permissions=True)

    # 4. Attempt Create Repeating Order (Should Fail)
    print("\nAttempting Create Repeating Order (Expect Failure)...")
    try:
        create_repeating_order(
            original_order=order.name,
            cron_pattern="0 0 * * *",  # Daily
            start_date=nowdate(),
            end_date=add_days(nowdate(), 7),
            payment_method="Wallet",
            saved_card=None,
        )
        print("ERROR: Should have failed due to insufficient balance!")
    except Exception as e:
        if "Suggest Topup" in str(e):
            print(f"SUCCESS: Caught expected error: {e}")
        else:
            print(f"FAILURE: Caught unexpected error: {e}")

    # 5. Top Up Wallet
    print("\nProcessing Top Up...")
    process_wallet_top_up(amount=1000, saved_card=saved_card)

    user_doc.reload()
    print(f"New Wallet Balance: {user_doc.wallet_balance}")

    # 6. Retry Create Repeating Order (Should Success)
    print("\nRetrying Create Repeating Order...")
    try:
        data = create_repeating_order(
            original_order=order.name,
            cron_pattern="0 0 * * *",
            start_date=nowdate(),
            end_date=add_days(nowdate(), 7),
            payment_method="Wallet",
            saved_card=None,
        )
        print(f"SUCCESS: Auto Order Created: {data}")
    except Exception as e:
        print(f"FAILURE: {e}")

    frappe.db.rollback()  # Clean up


if __name__ == "__main__":
    verify_flow()
