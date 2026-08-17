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

class DeliveryVehicleType {
  final String key;
  final String name;
  final int? maxWeight;
  final String? base;
  final int? maxWeightKg;
  final double? baseRate;
  final String? description;
  final bool? active;
  final int? sortOrder;
  final int? id;

  DeliveryVehicleType({
    required this.key,
    required this.name,
    this.maxWeight,
    this.base,
    this.maxWeightKg,
    this.baseRate,
    this.description,
    this.active,
    this.sortOrder,
    this.id,
  });

  factory DeliveryVehicleType.fromJson(Map<String, dynamic> json) {
    return DeliveryVehicleType(
      key: json['key'],
      name: json['name'],
      maxWeight: json['maxWeight'] ?? json['max_weight_kg'],
      base: json['base']?.toString(),
      maxWeightKg: json['max_weight_kg'],
      baseRate: json['base_rate'] != null
          ? double.tryParse(json['base_rate'].toString())
          : null,
      description: json['description'],
      active: json['active'],
      sortOrder: json['sort_order'],
      id: json['id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'name': name,
      'maxWeight': maxWeight,
      'base': base,
      'max_weight_kg': maxWeightKg,
      'base_rate': baseRate,
      'description': description,
      'active': active,
      'sort_order': sortOrder,
      'id': id,
    };
  }

  int get weightCapacity => maxWeight ?? maxWeightKg ?? 0;

  double get basePrice =>
      baseRate ?? (base != null ? double.tryParse(base!) ?? 0.0 : 0.0);

  bool canHandle(int weightKg) {
    return weightCapacity == 0 || weightKg <= weightCapacity;
  }

  String get displayNameWithCapacity {
    if (weightCapacity > 0) {
      return '$name (Max: ${weightCapacity}kg)';
    }
    return name;
  }

  String get formattedBasePrice {
    return 'R${basePrice.toStringAsFixed(2)}';
  }

  bool get isRetailVehicle {
    return weightCapacity <= 100 && weightCapacity > 0;
  }

  bool get isAgricultureVehicle {
    return weightCapacity > 100;
  }

  double calculateDeliveryCost({
    double distance = 0,
    int weightKg = 0,
    double distanceRatePerKm = 2.0,
    double extraWeightRate = 0.5,
  }) {
    double baseCost = basePrice;
    double distanceCost = distance * distanceRatePerKm;

    double weightCost = 0;
    if (weightCapacity > 0 && weightKg > (weightCapacity * 0.5)) {
      weightCost = (weightKg - (weightCapacity * 0.5)) * extraWeightRate;
    }

    return baseCost + distanceCost + weightCost;
  }

  double get efficiency {
    if (basePrice <= 0) return 0;
    return weightCapacity / basePrice;
  }

  DeliveryVehicleType copyWith({
    String? key,
    String? name,
    int? maxWeight,
    String? base,
    int? maxWeightKg,
    double? baseRate,
    String? description,
    bool? active,
    int? sortOrder,
    int? id,
  }) {
    return DeliveryVehicleType(
      key: key ?? this.key,
      name: name ?? this.name,
      maxWeight: maxWeight ?? this.maxWeight,
      base: base ?? this.base,
      maxWeightKg: maxWeightKg ?? this.maxWeightKg,
      baseRate: baseRate ?? this.baseRate,
      description: description ?? this.description,
      active: active ?? this.active,
      sortOrder: sortOrder ?? this.sortOrder,
      id: id ?? this.id,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeliveryVehicleType && other.key == key;
  }

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() {
    return 'DeliveryVehicleType(key: $key, name: $name, maxWeight: $maxWeight, base: $base)';
  }

  static List<DeliveryVehicleType> getRetailVehicles(
      List<DeliveryVehicleType> vehicles) {
    return vehicles.where((v) => v.isRetailVehicle).toList();
  }

  static List<DeliveryVehicleType> getAgricultureVehicles(
      List<DeliveryVehicleType> vehicles) {
    return vehicles.where((v) => v.isAgricultureVehicle).toList();
  }

  static List<DeliveryVehicleType> getSuitableVehicles(
    List<DeliveryVehicleType> vehicles,
    int weightKg,
  ) {
    return vehicles.where((v) => v.canHandle(weightKg)).toList()
      ..sort((a, b) {
        int capacityComparison = a.weightCapacity.compareTo(b.weightCapacity);
        if (capacityComparison != 0) return capacityComparison;
        return a.basePrice.compareTo(b.basePrice);
      });
  }

  static DeliveryVehicleType? getMostEconomical(
    List<DeliveryVehicleType> vehicles,
    int weightKg,
  ) {
    final suitable = getSuitableVehicles(vehicles, weightKg);
    if (suitable.isEmpty) return null;
    suitable.sort((a, b) => a.basePrice.compareTo(b.basePrice));
    return suitable.first;
  }

  static DeliveryVehicleType? getMostEfficient(
    List<DeliveryVehicleType> vehicles,
    int weightKg,
  ) {
    final suitable = getSuitableVehicles(vehicles, weightKg);
    if (suitable.isEmpty) return null;
    suitable.sort((a, b) => b.efficiency.compareTo(a.efficiency));
    return suitable.first;
  }
}
