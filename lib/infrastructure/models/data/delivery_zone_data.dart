class DeliveryZoneData {
  int? id;
  List<List<double>>? address;

  DeliveryZoneData({
    this.id,
    this.address,
  });

  DeliveryZoneData copyWith({
    int? id,
    List<List<double>>? address,
  }) =>
      DeliveryZoneData(
        id: id ?? this.id,
        address: address ?? this.address,
      );

  factory DeliveryZoneData.fromJson(Map<String, dynamic> json) => DeliveryZoneData(
    id: json["id"],
    address: json["address"] == null ? [] : List<List<double>>.from(json["address"]!.map((x) => List<double>.from(x.map((x) => x?.toDouble())))),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "address": address == null ? [] : List<dynamic>.from(address!.map((x) => List<dynamic>.from(x.map((x) => x)))),
  };
}
