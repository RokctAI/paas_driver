import 'package:base_sdk/src/models/data/translation.dart';

/// Sections/tables wire models, in merchants_sdk's own terms (ADR-005: this
/// SDK and orders_sdk may not import each other, so each declares its own).
///
/// Field names and JSON keys deliberately mirror orders_sdk's
/// `ShopSection`/`TableData` so the host adapter that bridges the two seams
/// can map field-by-field mechanically. IDs are strings here because Frappe
/// document names ("SEC-0001") are strings; the legacy Laravel ints parse
/// fine through `toString()`.
///
/// `fromJson` is tolerant of both list shapes: the legacy dashboard's
/// `{data: [...]}` envelope and the bare `frappe.get_all` list that
/// `seller_operations.get_seller_sections` / `get_seller_tables` return
/// today (`{name, title}` / `{name, table_number, capacity}` — mapped onto
/// the legacy keys; the delta is recorded in
/// `docs/frappe-endpoint-contract.md`).
class SellerShopSection {
  SellerShopSection({this.id, this.area, this.img, this.translation});

  String? id;
  String? area;
  String? img;
  Translation? translation;

  factory SellerShopSection.fromJson(Map<String, dynamic> json) =>
      SellerShopSection(
        id: (json['id'] ?? json['name'])?.toString(),
        area: json['area']?.toString(),
        img: json['img']?.toString(),
        translation: json['translation'] != null
            ? Translation.fromJson(json['translation'])
            : (json['title'] != null
                ? Translation(title: json['title'].toString())
                : null),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'area': area,
        'img': img,
        if (translation != null) 'translation': translation!.toJson(),
      };
}

class SellerTableData {
  SellerTableData({
    this.id,
    this.name,
    this.shopSectionId,
    this.chairCount,
    this.active,
    this.shopSection,
  });

  String? id;
  String? name;
  String? shopSectionId;
  int? chairCount;
  bool? active;
  SellerShopSection? shopSection;

  factory SellerTableData.fromJson(Map<String, dynamic> json) =>
      SellerTableData(
        id: (json['id'] ?? json['name'])?.toString(),
        name: (json['table_number'] ?? json['name'])?.toString(),
        shopSectionId: json['shop_section_id']?.toString(),
        chairCount: int.tryParse(
          (json['chair_count'] ?? json['capacity'] ?? '').toString(),
        ),
        active: json['active'] is bool
            ? json['active']
            : (json['active'] == null ? null : json['active'] == 1),
        shopSection: json['shop_section'] != null
            ? SellerShopSection.fromJson(
                Map<String, dynamic>.from(json['shop_section']),
              )
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'shop_section_id': shopSectionId,
        'chair_count': chairCount,
        'active': active,
        if (shopSection != null) 'shop_section': shopSection!.toJson(),
      };
}

class SellerSectionsResponse {
  SellerSectionsResponse({this.data});

  List<SellerShopSection>? data;

  factory SellerSectionsResponse.fromJson(dynamic json) {
    final List<dynamic>? list = json is List
        ? json
        : (json is Map ? json['data'] as List<dynamic>? : null);
    return SellerSectionsResponse(
      data: list
          ?.map(
            (v) => SellerShopSection.fromJson(Map<String, dynamic>.from(v)),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (data != null) 'data': data!.map((v) => v.toJson()).toList(),
      };
}

class SellerTablesResponse {
  SellerTablesResponse({this.data});

  List<SellerTableData>? data;

  factory SellerTablesResponse.fromJson(dynamic json) {
    final List<dynamic>? list = json is List
        ? json
        : (json is Map ? json['data'] as List<dynamic>? : null);
    return SellerTablesResponse(
      data: list
          ?.map(
            (v) => SellerTableData.fromJson(Map<String, dynamic>.from(v)),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (data != null) 'data': data!.map((v) => v.toJson()).toList(),
      };
}
