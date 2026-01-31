class Product {
  final String name;
  final String description;
  final double price;
  final String category;
  final String image;
  final bool isBoosted;
  final DateTime? boostExpiresAt;
  final String? boostStatus;
  final String? rejectionReason;

  Product({
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.image,
    this.isBoosted = false,
    this.boostExpiresAt,
    this.boostStatus,
    this.rejectionReason,
  });
}