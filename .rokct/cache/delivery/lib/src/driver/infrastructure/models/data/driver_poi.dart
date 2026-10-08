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

/// POINTS OF INTEREST, THE DRIVER'S HALF — the shapes map's `api.poi.*`
/// defs answer with.
///
/// The model, in the words it was approved in: a POI is a PLACE, and it is
/// SHARED LOCAL KNOWLEDGE. The driver files one as he passes, with or
/// without a sale at it, and the next driver on that round inherits it.
///
/// Two things about it are the server's alone and are never decided here:
///
///  * WHO IT BELONGS TO. A point is scoped to the shop of the load the
///    driver was working unless an admin has marked his contributions
///    platform-wide. Off a load it is one of the shops he DELIVERS FOR —
///    never a shop he owns, because a driver does not own one (Ray,
///    2026-09-18) — and when there is more than one of those the driver
///    names it himself from [DriverPoiShopChoices]. The client still sends
///    neither the platform-wide flag nor the author; `create` has no
///    argument for either, so nothing on this side can widen his reach.
///  * WHO RUNS IT, AS AN ACCOUNT. The driver types a first name, a last
///    name and a number; the server looks the number up and links the
///    point to the account that holds it, or makes one. `ownerUser` is
///    read-only here for the same reason the two below are: naming an
///    owner is his, deciding which account that owner IS is not. A number
///    already on file under ANOTHER first name comes back as a
///    [DriverPoiOwnerClash] rather than a point, and the driver answers
///    it.
///  * WHETHER IT IS ALREADY THERE. Two drivers passing the same corner
///    must leave ONE point on it, so `create` may answer with the point
///    that already stands, named by [duplicateOf]. A caller treats that as
///    a selection, not as a failure.
///
/// Hand-written `fromJson`, like the sibling `driver_load.dart`, so the
/// slice stays analyzable without a build_runner pass. Every field is
/// tolerant of absence: a shell whose serializer has not caught up must
/// degrade to a blank, never to a crash.
library;

/// One kind of place, as the admin-extendable vocabulary holds it.
class DriverPoiType {
  const DriverPoiType({
    required this.id,
    this.title,
    this.takesCustomType = false,
    this.customerVisible = false,
  });

  /// The Location Type docname — what `create` sends as `type`.
  final String id;

  /// What the chip reads. Falls back to [id], which IS the word for this
  /// doctype (it names itself after its own text).
  final String? title;

  /// True for the catch-all type: the one that asks the driver what kind
  /// of place this is, in his own words.
  final bool takesCustomType;

  /// True when points of this kind are shown on the customer map. Shown on
  /// the chip so the driver knows the difference between filing something
  /// for the round and filing something the public will see.
  final bool customerVisible;

  /// THE KINDS OF PLACE THAT ARE A BUSINESS SOMEBODY RUNS, so a point of
  /// one of them is not filed without the owner's first name.
  ///
  /// The client mirror of the server's own `OWNER_REQUIRED_POI_TYPES` (map
  /// api/poi/poi.py), matched on the Location Type docname exactly as the
  /// server matches it. Mirrored rather than fetched so the commit can stay
  /// inert instead of sending a call it knows will be refused; the SERVER
  /// is still the one that decides, and a type it requires an owner for
  /// that this set has not heard of is refused there.
  static const Set<String> ownerRequiredIds = {
    'spaza shop',
    'stockist',
    'other',
  };

  String get label => (title ?? '').trim().isEmpty ? id : title!.trim();

  /// True when filing this kind of place needs the owner's first name.
  bool get needsOwner => ownerRequiredIds.contains(id);

  factory DriverPoiType.fromJson(Map<String, dynamic> json) => DriverPoiType(
        id: _asString(json['name']) ?? '',
        title: _asString(json['location_type_name']),
        takesCustomType: _asBool(json['takes_custom_type']),
        customerVisible: _asBool(json['customer_visible']),
      );

  static List<DriverPoiType> listFrom(dynamic body) {
    final unwrapped = unwrapPoi(body);
    if (unwrapped is! List) return const [];
    return unwrapped
        .whereType<Map>()
        .map((row) => DriverPoiType.fromJson(Map<String, dynamic>.from(row)))
        .where((type) => type.id.isNotEmpty)
        .toList(growable: false);
  }
}

/// One point of interest.
class DriverPoi {
  const DriverPoi({
    required this.id,
    this.label,
    this.type,
    this.customType,
    this.typeLabel,
    this.latitude,
    this.longitude,
    this.address,
    this.ownerName,
    this.ownerPhone,
    this.ownerUser,
    this.note,
    this.shopId,
    this.isPlatformWide = false,
    this.createdByDeliveryman,
    this.active = true,
    this.distanceKm,
    this.duplicateOf,
  });

  /// The Point Of Interest docname.
  final String id;

  /// The name of the place as the driver who filed it wrote it.
  final String? label;

  /// The Location Type docname.
  final String? type;

  /// The driver's own words for the kind of place, carried only when
  /// [type] is the catch-all one.
  final String? customType;

  /// What a screen prints for the kind of place: the server strikes it so
  /// the map pin, the list row and the sheet cannot disagree.
  final String? typeLabel;

  final double? latitude;
  final double? longitude;
  final String? address;

  /// Who runs the place, as the driver was told at the door: first and
  /// last name as one line. Driver-side only — the customer read does not
  /// carry it.
  final String? ownerName;

  /// The number the driver was given, as it was typed.
  final String? ownerPhone;

  /// The platform account that owner is, when the server found or made
  /// one. Never sent: the server decides it from the number.
  final String? ownerUser;

  /// The note the driver left for the next driver. Never shown to a
  /// customer — the customer read does not even carry it.
  final String? note;

  final String? shopId;

  /// Whether this point reaches past its shop. Read-only here: the server
  /// decides it from the author's admin-set profile flag.
  final bool isPlatformWide;

  final String? createdByDeliveryman;
  final bool active;

  /// How far the point was from the position that asked, when the answer
  /// was a nearby read.
  final double? distanceKm;

  /// Set when `create` answered with a point that ALREADY STOOD within the
  /// duplicate radius. The caller selects that point instead of filing a
  /// second one on the same corner.
  final String? duplicateOf;

  bool get wasAlreadyThere => (duplicateOf ?? '').isNotEmpty;

  bool get hasCoordinates =>
      latitude != null &&
      longitude != null &&
      !(latitude == 0 && longitude == 0);

  /// The kind of place, as one line: the server's own [typeLabel] when it
  /// sent one, else the driver's words, else the type.
  String get kind {
    for (final candidate in [typeLabel, customType, type]) {
      final text = (candidate ?? '').trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  /// What a pin or a row titles itself with. Never empty: a point with no
  /// label still has a kind, and a point with neither still has an id.
  String get title {
    final named = (label ?? '').trim();
    if (named.isNotEmpty) return named;
    final byKind = kind;
    return byKind.isNotEmpty ? byKind : id;
  }

  factory DriverPoi.fromJson(Map<String, dynamic> json) => DriverPoi(
        id: _asString(json['name']) ?? '',
        label: _asString(json['label']),
        type: _asString(json['type']),
        customType: _asString(json['custom_type']),
        typeLabel: _asString(json['type_label']),
        latitude: _asDouble(json['latitude']),
        longitude: _asDouble(json['longitude']),
        address: _asString(json['address']),
        ownerName: _asString(json['owner_name']),
        ownerPhone: _asString(json['owner_phone']),
        ownerUser: _asString(json['owner_user']),
        note: _asString(json['note']),
        shopId: _asString(json['shop']),
        isPlatformWide: _asBool(json['is_platform_wide']),
        createdByDeliveryman: _asString(json['created_by_deliveryman']),
        active: json['active'] == null ? true : _asBool(json['active']),
        distanceKm: _asDouble(json['distance_km']),
        duplicateOf: _asString(json['duplicate_of']),
      );

  static List<DriverPoi> listFrom(dynamic body) {
    final unwrapped = unwrapPoi(body);
    if (unwrapped is List) {
      return unwrapped
          .whereType<Map>()
          .map((row) => DriverPoi.fromJson(Map<String, dynamic>.from(row)))
          .where((point) => point.id.isNotEmpty)
          .toList(growable: false);
    }
    if (unwrapped is Map && unwrapped.isNotEmpty) {
      final one = DriverPoi.fromJson(Map<String, dynamic>.from(unwrapped));
      return one.id.isEmpty ? const [] : [one];
    }
    return const [];
  }

  static DriverPoi? oneFrom(dynamic body) {
    final unwrapped = unwrapPoi(body);
    if (unwrapped is Map && unwrapped.isNotEmpty) {
      final one = DriverPoi.fromJson(Map<String, dynamic>.from(unwrapped));
      return one.id.isEmpty ? null : one;
    }
    return null;
  }
}

/// One sale made at a point.
class DriverPoiSale {
  const DriverPoiSale({
    required this.orderId,
    this.createdAt,
    this.total = 0,
    this.deliveryman,
    this.customer,
    this.paymentStatus,
  });

  final String orderId;
  final String? createdAt;
  final num total;
  final String? deliveryman;
  final String? customer;
  final String? paymentStatus;

  factory DriverPoiSale.fromJson(Map<String, dynamic> json) => DriverPoiSale(
        orderId: _asString(json['name']) ?? '',
        createdAt: _asString(json['creation']),
        total: _asNum(json['total_price']),
        deliveryman: _asString(json['deliveryman']),
        customer: _asString(json['user']),
        paymentStatus: _asString(json['payment_status']),
      );
}

/// `get_poi_sales`'s answer: the point, what has been sold at it, and the
/// three figures a driver reads before he knocks.
class DriverPoiSales {
  const DriverPoiSales({
    this.poi,
    this.sales = const [],
    this.count = 0,
    this.total = 0,
    this.lastVisit,
  });

  final DriverPoi? poi;
  final List<DriverPoiSale> sales;

  /// The server's own count, which may exceed [sales] when the list was
  /// paged. Never recomputed from the list for that reason.
  final int count;
  final num total;
  final String? lastVisit;

  /// True once the point has been sold at. A point with no history is the
  /// normal state of a point filed for the knowledge alone.
  bool get hasHistory => count > 0 || sales.isNotEmpty;

  factory DriverPoiSales.fromJson(dynamic body) {
    final map = _asMap(unwrapPoi(body));
    final rows = map['sales'];
    return DriverPoiSales(
      poi: DriverPoi.oneFrom(map['poi']),
      sales: rows is List
          ? rows
              .whereType<Map>()
              .map((row) =>
                  DriverPoiSale.fromJson(Map<String, dynamic>.from(row)))
              .toList(growable: false)
          : const [],
      count: _asInt(map['count']) ?? 0,
      total: _asNum(map['total']),
      lastVisit: _asString(map['last_visit']),
    );
  }
}

/// ONE SHOP THE DRIVER MAY TAG A PLACE TO.
///
/// Ray, 2026-09-18: "driver doesnt own a shop, he either deliver for every
/// shop in the platform or specific ones if choosen". So this is a shop he
/// DELIVERS FOR, never a shop he owns, and the server is the one that says
/// which.
class DriverPoiShop {
  const DriverPoiShop({required this.id, this.title});

  /// The Shop docname — what `create` sends as `shop`.
  final String id;

  /// What the picker reads. Falls back to [id], which is a shop's own name
  /// on a site whose display name was never filled in.
  final String? title;

  String get label => (title ?? '').trim().isEmpty ? id : title!.trim();

  factory DriverPoiShop.fromJson(Map<String, dynamic> json) => DriverPoiShop(
        id: _asString(json['name']) ?? '',
        title: _asString(json['shop_name']),
      );
}

/// THE SHOPS THIS DRIVER MAY TAG A PLACE TO, and whether that list is the
/// whole platform.
///
/// [unrestricted] is the server saying it holds NO choice for him, so
/// [shops] is every shop rather than a chosen few. The sheet shows the same
/// picker either way — the difference is only what it is a picker OF.
class DriverPoiShopChoices {
  const DriverPoiShopChoices({
    this.shops = const [],
    this.unrestricted = false,
  });

  final List<DriverPoiShop> shops;
  final bool unrestricted;

  /// One shop is not a question. The sheet fills it in and says nothing.
  bool get isSettled => shops.length == 1;

  /// Two or more and the driver himself has to say which, because the
  /// server will not guess.
  bool get needsChoosing => shops.length > 1;

  DriverPoiShop? get only => shops.length == 1 ? shops.first : null;

  factory DriverPoiShopChoices.fromJson(dynamic body) {
    final map = _asMap(unwrapPoi(body));
    final rows = map['shops'];
    return DriverPoiShopChoices(
      shops: rows is List
          ? rows
              .whereType<Map>()
              .map((row) =>
                  DriverPoiShop.fromJson(Map<String, dynamic>.from(row)))
              .where((shop) => shop.id.isNotEmpty)
              .toList(growable: false)
          : const [],
      unrestricted: _asBool(map['unrestricted']),
    );
  }
}

/// WHO A NUMBER BELONGS TO — `lookup_poi_owner`'s answer.
///
/// Read as the driver finishes typing the number, for two reasons: so an
/// owner the platform already knows is filled in rather than typed again,
/// and so the driver SEES that he is about to file the fourth place of
/// somebody who already runs three.
class DriverPoiOwner {
  const DriverPoiOwner({
    this.found = false,
    this.firstName,
    this.lastName,
    this.placesCount = 0,
  });

  /// True when the number is held by an account. False is the normal
  /// answer for a spaza nobody has filed before.
  final bool found;

  final String? firstName;
  final String? lastName;

  /// How many places this account already runs.
  final int placesCount;

  /// The name as one line, or empty when the account carries none.
  String get fullName => [
        (firstName ?? '').trim(),
        (lastName ?? '').trim(),
      ].where((part) => part.isNotEmpty).join(' ');

  factory DriverPoiOwner.fromJson(dynamic body) {
    final map = _asMap(unwrapPoi(body));
    return DriverPoiOwner(
      found: _asBool(map['found']),
      firstName: _asString(map['first_name']),
      lastName: _asString(map['last_name']),
      placesCount: _asInt(map['places_count']) ?? 0,
    );
  }
}

/// THE NUMBER IS ON FILE UNDER SOMEBODY ELSE — the server's refusal,
/// carried as a value the screen can answer rather than as a failure.
///
/// The server raises `PoiOwnerMismatch` and writes NOTHING when the number
/// belongs to an account whose first name is not the one the driver typed.
/// It is a QUESTION, not an error: the app names [firstName] and asks
/// whether it is the same person, and a yes re-sends the create with
/// `owner_confirmed_user`.
class DriverPoiOwnerClash {
  const DriverPoiOwnerClash({this.firstName, this.detail});

  /// The first name the account carries, as the server named it. What the
  /// dialog has to say — without it there is no question to ask.
  final String? firstName;

  /// The server's own sentence, for telemetry. Never a driver's line.
  final String? detail;

  /// The exception class name the server answers this with, matched on
  /// rather than on English (see map api/poi/poi.py `PoiOwnerMismatch`).
  static const String excType = 'PoiOwnerMismatch';
}

/// WHAT A CREATE ANSWERED: the point, or the owner clash that stopped it.
///
/// Two outcomes and no third, because a create either filed something (or
/// handed back the point that already stood there — still a [point]) or it
/// hit the one refusal the driver can answer. Everything else is an
/// ordinary failure and never reaches this shape.
class DriverPoiFiling {
  const DriverPoiFiling.filed(DriverPoi this.point) : ownerClash = null;

  const DriverPoiFiling.ownerClash(DriverPoiOwnerClash this.ownerClash)
      : point = null;

  final DriverPoi? point;
  final DriverPoiOwnerClash? ownerClash;

  bool get needsOwnerConfirmation => ownerClash != null;
}

/// Peels the repo's usual `{"data": ...}` envelope (and a stray `message`
/// one) off a gateway answer — the tolerance `DriverLoad.unwrap` set.
dynamic unwrapPoi(dynamic body) {
  var current = body;
  for (var depth = 0; depth < 2; depth++) {
    if (current is Map && current.containsKey('message')) {
      current = current['message'];
      continue;
    }
    if (current is Map && current.containsKey('data')) {
      current = current['data'];
      continue;
    }
    break;
  }
  return current;
}

Map<String, dynamic> _asMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};

String? _asString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = (value ?? '').toString().trim().toLowerCase();
  return text == '1' || text == 'true' || text == 'yes';
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('${value ?? ''}');
}

double? _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value == null) return null;
  return double.tryParse(value.toString().trim());
}

num _asNum(dynamic value) {
  if (value is num) return value;
  if (value == null) return 0;
  return num.tryParse(value.toString().trim()) ?? 0;
}
