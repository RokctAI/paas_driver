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

/// The wire translation keys the collected-in-person surface uses
/// (design strip section 43, chips 810-821).
///
/// `lib/` references translation keys by WIRE STRING, not through
/// base_sdk's `TrKeys`: this package analyzes against raw base_sdk,
/// where the composer-injected constants do not exist. Same reasoning
/// (and the same products_sdk precedent) as this SDK's other lib-side
/// keys; the values are declared in `manifest.json` under the manager
/// block, and `AppHelpers.getTranslation` humanizes any key the
/// translation store has not been seeded with yet.
abstract final class CollectKeys {
  // 811 - the deliveryman row, empty state.
  static const String noDriverAssignedYet = 'no_driver_assigned_yet';
  static const String nobodyDispatched =
      'nobody_has_been_dispatched_for_this_order';

  // 812 - the deliveryman row, assigned state.
  static const String onACallout = 'on_a_callout';
  static const String assigned = 'assigned';
  static const String pickedUp = 'picked_up';

  // 813 - the action lane, and its offline relabel (43e).
  static const String customerIsHereConvertToPickup =
      'customer_is_here_convert_to_pickup';
  static const String handOverNowConvertWhenBackOnline =
      'hand_over_now_convert_when_back_online';

  // 814 - the outcome line, no driver.
  static const String noDriverWasOnItYetSoThe =
      'no_driver_was_on_it_yet_so_the';
  static const String deliveryFeeGoesBackToTheCustomersWallet =
      'delivery_fee_goes_back_to_the_customers_wallet';
  static const String theMomentYouConvert = 'the_moment_you_convert';

  // 815 - the outcome line, driver assigned.
  static const String aDriverWasAlreadyOnThisOneSoThe =
      'a_driver_was_already_on_this_one_so_the';
  static const String feeIsKept = 'fee_is_kept';
  static const String itCoversTheCalloutHisTaskCancels =
      'it_covers_the_callout_and_his_task_cancels';

  // 816 - the till line.
  static const String feeComesBackIfNoDriverWasOnItYet =
      'fee_comes_back_if_no_driver_was_on_it_yet';
  static const String thisOneHadADriverOnItSoItDoesNot =
      'this_one_had_a_driver_on_it_so_it_does_not';

  // 817/818/819 - the confirm guard.
  static const String handOverAndConvertToPickup =
      'hand_over_and_convert_to_pickup';
  static const String goods = 'goods';
  static const String handedToTheCustomerNow = 'handed_to_the_customer_now';
  static const String neverWithheldNeverForfeited =
      'never_withheld_never_forfeited_whatever_else_happens_here';
  static const String deliveryTypeRow = 'delivery_type';
  static const String onThisOrder = 'on_this_order';
  static const String deliveryFeeRow = 'delivery_fee';
  static const String keptNotRefunded = 'kept_not_refunded';
  static const String itCoversTheDriversCallout =
      'it_covers_the_drivers_callout_he_already_drove_for_it';
  static const String refundedToHerWallet = 'refunded_to_the_customers_wallet';
  static const String noDriverWasEverOnIt = 'no_driver_was_ever_on_it';
  static const String driverTaskRow = 'driver_task';
  static const String isUnassignedAndHisTaskCancels =
      'is_unassigned_and_his_task_cancels_in_the_driver_app';
  static const String nobodyToStandDown = 'nobody_to_stand_down';
  static const String handOverAndConvert = 'hand_over_and_convert';

  // 43e - the offline note that replaces 814/815.
  static const String offlineHandOverNote =
      'the_customer_gets_the_order_now_either_way_the_driver_check_and_'
      'the_wallet_credit_live_on_the_server';

  // Outcomes, after the fact.
  static const String feeRefundedToWallet = 'fee_refunded_to_wallet';
  static const String feeKeptCoversTheDriversCallout =
      'fee_kept_covers_the_drivers_callout';
  static const String collectedInPerson = 'collected_in_person';
  static const String conversionQueuedForSync = 'conversion_queued_for_sync';
}
