import 'package:teftef/models/product.dart';
import 'package:teftef/models/category.dart';

class DataProvider {
  static List<Category> getCategories() {
    return [
      Category(name: "Electronics", image: "assets/th (9).jpg"),
      Category(name: "Fashion", image: "assets/th (10).jpg"),
      Category(name: "Home", image: "assets/th (11).jpg"),
      Category(name: "Books", image: "assets/th (12).jpg"),
      Category(name: "Sports", image: "assets/th (13).jpg"),
      Category(name: "Beauty", image: "assets/th (14).jpg"),
    ];
  }

  static List<Product> getProducts() {
    return [
      Product(
        name: "Wireless Headphones",
        description: "High quality sound with noise cancellation",
        price: 2999.00,
        category: "Electronics",
        image: "assets/th (1).jpg",
      ),
      Product(
        name: "Smart Watch",
        description: "Track your fitness and notifications",
        price: 4999.00,
        category: "Electronics",
        image: "assets/th (2).jpg",
      ),
      Product(
        name: "Designer T-Shirt",
        description: "Cotton blend, comfortable fit",
        price: 899.00,
        category: "Fashion",
        image: "assets/th (3).jpg",
      ),
      Product(
        name: "Coffee Maker",
        description: "Automatic drip coffee maker",
        price: 2499.00,
        category: "Home",
        image: "assets/th (4).jpg",
      ),
      Product(
        name: "Gaming Console",
        description: "Next-gen gaming experience",
        price: 39999.00,
        category: "Electronics",
        image: "assets/th (5).jpg",
      ),
      Product(
        name: "Sneakers",
        description: "Comfortable sports shoes",
        price: 5999.00,
        category: "Fashion",
        image: "assets/th (6).jpg",
      ),
      Product(
        name: "Sofa Set",
        description: "Comfortable 3-seater sofa",
        price: 24999.00,
        category: "Home",
        image: "assets/th (7).jpg",
      ),
      Product(
        name: "Novel Book",
        description: "Bestseller fiction novel",
        price: 799.00,
        category: "Books",
        image: "assets/th (8).jpg",
      ),
    ];
  }

  static List<Product> getProductsByCategory(String category) {
    return getProducts().where((product) => product.category == category).toList();
  }
}