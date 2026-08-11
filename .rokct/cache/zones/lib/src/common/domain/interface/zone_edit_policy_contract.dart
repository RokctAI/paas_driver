/// Whether the current user may redraw a delivery zone.
///
/// Host-supplied, because the restriction is flavour-specific rather than a
/// property of zones themselves. The driver app gates editing on the
/// platform's `driver_can_edit_credentials` setting (operators who assign
/// routes centrally turn it off); a merchant drawing their own shop's
/// catchment has no equivalent concept.
///
/// Hosts that have no restriction register nothing — `deliveryZoneProvider`
/// then leaves [DeliveryZoneNotifier] on its permissive default. Relying on
/// "the driver setting key happens to be absent" would be a coincidence, not
/// a policy, so the absence of a registration is the explicit way to say
/// "unrestricted".
///
/// Only the contract lives here. Each flavour's *implementation* stays in its
/// own app, deliberately: the driver rule reads a setting
/// (`driver_can_edit_credentials`) that means nothing to any other consumer of
/// this SDK, and shipping it in the shared layer would hand that concept to
/// every future consumer. "Driver is the only consumer today" is not the same
/// as "this is common".
abstract class ZoneEditPolicy {
  bool canEdit();
}
