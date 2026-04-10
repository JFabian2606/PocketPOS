class Product {
  int? id;
  String name;
  double price;
  int stock;
  String category;

  Product({
    this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.category,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'],
        name: json['name'],
        price: json['price'],
        stock: json['stock'],
        category: json['category'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'stock': stock,
        'category': category,
      };
}
