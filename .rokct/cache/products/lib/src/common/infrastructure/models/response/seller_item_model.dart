// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
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
