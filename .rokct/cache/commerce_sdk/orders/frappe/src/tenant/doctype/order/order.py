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
# Copyright (c) 2025 ROKCT INTELLIGENCE (PTY) LTD
# For license information, please see license.txt
import frappe
from frappe.model.document import Document


class Order(Document):
    def before_save(self):
        self.calculate_totals()
        self.set_contains_adult_items()
        self.complete_at_ready_if_due()

    def on_update(self):
        self.settle_if_due()
        # Credit-delivery settlement BEFORE the auto-pay trigger: if
        # this same save also sweeps the order to Paid, the settlement
        # it fires must already see credit_settled and pay the shop the
        # full total while skipping driver and platform shares.
        self.settle_credit_if_delivered()
        self.auto_pay_if_credit_collected()

    def settle_if_due(self):
        """Seller settlement trigger.

        Delivered is written by at least three callers (customer/admin
        update_order_status, seller update_seller_order_status, zones'
        driver update_driver_order_status) and payment_status "Paid" by
        more (COD confirmation, wallet debit, gateways) — all through
        doc.save(), and Order has no doc_events — so the controller is
        the one place every path funnels through. settle_order itself
        re-checks the `settled` flag under a row lock, making this safe
        to call on every save.
        """
        if self.status != "Delivered" or self.payment_status != "Paid":
            return
        if self.get("settled"):
            return
        # Relative import into the composed api tree: this doctype file
        # is installed at `{app_name}/orders/doctype/order/` while the
        # api tree lands at `{app_name}/orders/tenant/api/order/`, so
        # `...tenant` resolves without naming `{app_name}` — the same
        # deliberate pattern (and rationale) documented in forex's
        # forex_strategy_version.py controller.
        from ...tenant.api.order.settlement import settle_order

        settle_order(self)

    def settle_credit_if_delivered(self):
        """Credit-delivery settlement trigger.

        An order Delivered while still payment_status "Credit" pays the
        deliveryman AND the platform shares immediately, all fronted by
        the shop, which alone carries the credit risk
        (settlement.settle_credit_delivery — once-only via the
        credit_settled flag re-checked under a row lock). Fires on
        whichever of Delivered / Credit lands second, since drivers may
        convert to credit before or after marking Delivered.
        """
        if self.status != "Delivered" or self.payment_status != "Credit":
            return
        if self.get("credit_settled"):
            return
        # Same composed-tree relative import as settle_if_due above.
        from ...tenant.api.order.settlement import settle_credit_delivery

        settle_credit_delivery(self)

    def auto_pay_if_credit_collected(self):
        """Wallet auto-pay trigger for Credit orders.

        zones' confirm_credit_collection credits the customer's wallet
        with the cash collected and THEN saves this Order (cumulative
        credit_collected_amount), so this controller sees every
        collection land with the top-up already on the balance. The
        trigger is deliberately state-based (a Credit order with any
        collection recorded) rather than delta-based: auto-pay itself
        only moves money while the wallet covers a full order, so
        re-running it on an unrelated save of the same order is a
        harmless no-op. Orders flipped Paid by the auto-pay re-enter
        on_update with payment_status "Paid" and fall out at the first
        check here; auto_pay_credit_orders carries its own frappe.flags
        re-entrancy latch as well, so the loop can never nest.
        """
        if self.payment_status != "Credit":
            return
        if float(self.get("credit_collected_amount") or 0) <= 0:
            return
        # Same composed-tree relative import as settle_if_due above.
        from ...tenant.api.order.settlement import auto_pay_credit_orders

        auto_pay_credit_orders(self.user)

    def complete_at_ready_if_due(self):
        """Auto-complete at Ready (design strip section 42, chips 799/800).

        A shop that hands the customer their goods across the counter has
        nothing to tap after "Ready" — the customer is already standing
        there. With `Shop.auto_complete_at_ready` on, an order written to
        "Ready" is written straight through to "Delivered" instead, and
        NOBODY confirms the hand-over. That is the whole point and it is
        also the whole risk, which is why the setting is off by default
        and the surface says so in as many words.

        This runs in `before_save`, deliberately: the status is rewritten
        BEFORE the row is written, so there is no second save, no
        recursion guard to get wrong, and `on_update`'s settlement
        triggers see the final "Delivered" exactly once on the same pass.

        Two hard guards, neither of them cosmetic:

        * PICKUP ONLY. `settle_order` pays the deliveryman the full
          `delivery_fee` the moment a Delivered order with a `deliveryman`
          settles, so auto-completing an order that still has to travel
          would pay for a delivery nobody made — and would tell the
          customer their parcel arrived while it sat on the counter. An
          order that is not a pickup is never completed by this rule, no
          matter how the shop set the switch.
        * NEW ROWS ARE EXEMPT. A seller-origin (POS) sale is created
          already holding "Ready" when it is packed for delivery
          (`create_order`'s `_is_pos_order` branch); flipping that on
          insert would complete a sale that has not left the shop. The
          rule only fires on a REAL transition into Ready.
        """
        if self.status != "Ready" or self.is_new() or not self.shop:
            return
        previous = self.get_doc_before_save()
        if previous is not None and previous.status == "Ready":
            # Already Ready before this save — an unrelated edit, not the
            # transition the rule listens for.
            return
        # `delivery_type` is a free Data field and the fleet writes it in
        # both cases ("Pickup" from the customer checkout, 'pickup' from
        # the till), so compare case-insensitively.
        if str(self.get("delivery_type") or "").strip().lower() != "pickup":
            return
        if not frappe.db.get_value("Shop", self.shop, "auto_complete_at_ready"):
            return
        self.status = "Delivered"

    def set_contains_adult_items(self):
        """Flag the order when any order item's Product is 18+ (adults only)."""
        contains_adult = 0
        product_ids = [
            item.product for item in (self.order_items or []) if item.product
        ]
        if product_ids:
            adult_count = frappe.db.count(
                "Product",
                {"name": ["in", product_ids], "is_adult": 1},
            )
            contains_adult = 1 if adult_count else 0
        self.contains_adult_items = contains_adult

    def calculate_totals(self):
        # Calculate total price from order items
        total_price = sum(
            item.price *
            item.quantity for item in self.order_items)
        total_discount = sum(item.discount or 0 for item in self.order_items)

        # Calculate shop tax
        # Calculate shop tax
        shop_tax = 0
        if self.shop:
            shop = frappe.get_doc("Shop", self.shop)
            if shop.tax:
                shop_tax = total_price * (shop.tax / 100)

        total_price += shop_tax

        # Apply coupon
        if self.coupon_code:
            coupon = frappe.db.get_value("Coupon", {"code": self.coupon_code}, [
                                         "discount_type", "discount_amount"], as_dict=True)
            if coupon:
                if coupon.discount_type == "Percentage":
                    coupon_discount = total_price * \
                        (coupon.discount_amount / 100)
                else:
                    coupon_discount = coupon.discount_amount
                total_discount += coupon_discount

        total_price -= total_discount

        # Add service fee
        service_fee = 0
        if frappe.db.exists("DocType", "Permission Settings"):
            service_fee = frappe.db.get_single_value(
                "Permission Settings", "service_fee") or 0

        total_price += service_fee
        total_price += self.delivery_fee or 0

        # Commission fee
        commission_fee = 0
        if self.shop:
            # Assuming commission percentage is stored on the Shop doctype
            if shop.percentage:
                commission_fee = total_price * (shop.percentage / 100)

        self.total_price = total_price
        self.tax = shop_tax
        self.total_discount = total_discount
        self.service_fee = service_fee
        self.commission_fee = commission_fee
