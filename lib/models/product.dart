/// Represents a sellable product (e.g. Ndengu samosa, Meat samosa).
class Product {
  final int id;
  final String name;
  final double price;
  final String? unit;
  final String? category;
  final String? imagePath;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    this.unit,
    this.category,
    this.imagePath,
  });

  Product copyWith({
    int? id,
    String? name,
    double? price,
    String? unit,
    String? category,
    String? imagePath,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      imagePath: imagePath ?? this.imagePath,
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
          price == other.price &&
          category == other.category &&
          imagePath == other.imagePath;

  @override
  int get hashCode => Object.hash(id, name, price, category, imagePath);
}
