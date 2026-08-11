class SellerOrderItem {
  final int? id;
  final int? productId;
  final int? quantity;
  final double? tax;
  final double? discount;
  final double? price;
  final String? description;
  final SellerItemProduct? product;

  SellerOrderItem({
    this.id,
    this.productId,
    this.quantity,
    this.tax,
    this.discount,
    this.price,
    this.description,
    this.product,
  });

  factory SellerOrderItem.fromJson(Map<String, dynamic> json) => SellerOrderItem(
        id: json["id"],
        productId: json["product_id"],
        quantity: json["quantity"],
        tax: (json["tax"] as num?)?.toDouble(),
        discount: (json["discount"] as num?)?.toDouble(),
        price: (json["price"] as num?)?.toDouble(),
        description: json["description"],
        product: json["product"] == null ? null : SellerItemProduct.fromJson(json["product"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "product_id": productId,
        "quantity": quantity,
        "tax": tax,
        "discount": discount,
        "price": price,
        "description": description,
        "product": product?.toJson(),
      };
}

class SellerItemProduct {
  final int? id;
  final String? name;

  SellerItemProduct({this.id, this.name});

  factory SellerItemProduct.fromJson(Map<String, dynamic> json) => SellerItemProduct(
        id: json["id"],
        name: json["name"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
      };
}
