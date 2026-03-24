/// Represents a sellable product (e.g. Ndengu samosa, Meat samosa).
class Product {
  final int id;
  final String name;
  final double price;
  final String? unit;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    this.unit,
  });

  Product copyWith({
    int? id,
    String? name,
    double? price,
    String? unit,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      unit: unit ?? this.unit,
    );
  }

  @override
  String toString() => 'Product(id: $id, name: $name, price: $price)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          price == other.price;

  @override
  int get hashCode => Object.hash(id, name, price);
}
