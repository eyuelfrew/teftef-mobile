import 'package:flutter/material.dart';
import 'home_page.dart';
import 'product_list_page.dart';
import 'components/animated_bottom_nav_bar.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  _MainNavigationPageState createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const HomePage(),
          const ProductListPage(), // Categories page
          Container(), // Post page placeholder
          Container(), // Favorites page placeholder
          Container(), // Profile page placeholder
        ],
      ),
      bottomNavigationBar: AnimatedBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          AnimatedBottomNavBarItem(
            icon: Icons.home,
            label: "Home",
          ),
          AnimatedBottomNavBarItem(
            icon: Icons.category,
            label: "Categories",
          ),
          AnimatedBottomNavBarItem(
            icon: Icons.add_circle,
            label: "Post",
          ),
          AnimatedBottomNavBarItem(
            icon: Icons.favorite,
            label: "Favorites",
          ),
          AnimatedBottomNavBarItem(
            icon: Icons.person,
            label: "Profile",
          ),
        ],
      ),
    );
  }
}