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

/// The wire translation keys the manager's consignment-load surfaces use.
///
/// `lib/` references translation keys by WIRE STRING, not through
/// base_sdk's `TrKeys`: this package analyzes against raw base_sdk, where
/// the composer-injected constants do not exist (the [CollectKeys]
/// precedent next door). The values are declared in `manifest.json` under
/// the manager block, and `AppHelpers.getTranslation` humanizes any key
/// the translation store has not been seeded with yet.
abstract final class LoadKeys {
  // The list.
  static const String loads = 'loads';
  static const String openLoads = 'open_loads';
  static const String closedLoads = 'closed_loads';
  static const String issueLoad = 'issue_load';
  static const String noLoads = 'no_loads';
  static const String linesOnLoad = 'lines_on_load';
  static const String remainingOfIssued = 'remaining_of_issued';
  static const String issuedOn = 'issued_on';
  static const String closedOn = 'closed_on';

  // The detail's line table.
  static const String issued = 'issued';
  static const String sold = 'sold';
  static const String returned = 'returned';
  static const String remaining = 'remaining';
  static const String unitPrice = 'unit_price';
  static const String variance = 'variance';
  static const String varianceValue = 'variance_value';

  // Closing.
  static const String closeLoad = 'close_load';
  static const String closeLoadAndCharge = 'close_load_and_charge';
  static const String closingChargesTheDriver =
      'closing_charges_the_driver_for_what_is_missing';
  static const String nothingIsMissingSoNothingIsCharged =
      'nothing_is_missing_so_nothing_is_charged';
  static const String willBeChargedToTheDriversWallet =
      'will_be_charged_to_the_drivers_wallet';
  static const String loadClosed = 'load_closed';
  static const String loadWasAlreadyClosed = 'load_was_already_closed';
  static const String couldNotCloseLoad = 'could_not_close_load';

  // Issuing.
  static const String chooseADeliveryman = 'choose_a_deliveryman';
  static const String noDeliverymenOnFile = 'no_deliverymen_on_file';
  static const String onTheLoad = 'on_the_load';
  static const String tapAProductToPutItOnTheLoad =
      'tap_a_product_to_put_it_on_the_load';
  static const String loadValue = 'load_value';
  static const String issueToDriver = 'issue_to_driver';
  static const String issuingTakesTheStockOffTheShelf =
      'issuing_takes_the_stock_off_the_shelf';
  static const String couldNotIssueLoad = 'could_not_issue_load';
  static const String onHand = 'on_hand';
}
