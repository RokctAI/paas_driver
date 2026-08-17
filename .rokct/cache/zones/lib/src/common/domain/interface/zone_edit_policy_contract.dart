// Copyright (c) 2026 RokctAI
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

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
