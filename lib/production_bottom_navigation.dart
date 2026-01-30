import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_page.dart';
import 'profile_page.dart';
import 'search_page.dart';
import 'category_selection_screen.dart';
import 'auth/auth_controller.dart';
import 'components/login_bottom_sheet.dart';

class ProductionBottomNavigation extends StatefulWidget {
  const ProductionBottomNavigation({super.key});

  @override
  _ProductionBottomNavigationState createState() =>
      _ProductionBottomNavigationState();
}

class _ProductionBottomNavigationState extends State<ProductionBottomNavigation>
    with TickerProviderStateMixin {
  /// Controller to handle PageView and also handles initial page
  final PageController _pageController = PageController(initialPage: 0);

  /// Controller to handle bottom nav bar and also handles initial page
  final NotchBottomBarController _controller = NotchBottomBarController(index: 0);

  int maxCount = 5;

  void _showLoginBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return const LoginBottomSheet();
      },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// widget list - excluding profile page since it's handled separately
    final List<Widget> bottomBarPages = [
      const HomePage(), // Home
      const SearchPage(), // Search
      const CategorySelectionScreen(), // Post Product
      Container(), // Chat
      const ProfilePage(), // Profile
    ];

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(
          bottomBarPages.length,
          (index) => bottomBarPages[index]
        ),
      ),
      extendBody: true,
      bottomNavigationBar: (bottomBarPages.length <= maxCount)
          ? AnimatedNotchBottomBar(
              /// Provide NotchBottomBarController
              notchBottomBarController: _controller,
              color: const Color.fromARGB(255, 50, 50, 50), // Changed to light dark background
              showLabel: false, // Minimal labels as requested
              textOverflow: TextOverflow.visible,
              maxLine: 1,
              shadowElevation: 5,
              kBottomRadius: 16.0, // Reduced from 28.0 to make it less bulky
              notchColor: const Color.fromARGB(255, 50, 50, 50), // Changed to match background

              /// restart app if you change removeMargins
              removeMargins: true, // Changed to true to remove side gaps
              bottomBarWidth: double.infinity, // Changed to fill available width
              showShadow: false,
              durationInMilliSeconds: 300,

              itemLabelStyle: const TextStyle(fontSize: 10),

              elevation: 1,
              bottomBarItems: [
                BottomBarItem(
                  inActiveItem: Icon(
                    Icons.home_outlined,
                    color: Colors.white.withOpacity(0.6), // Slightly transparent white for inactive state
                    size: 20, // Reduced from 24 to make it more compact
                  ),
                  activeItem: Icon(
                    Icons.home,
                    color: Colors.white, // White for better contrast on dark
                    size: 20, // Reduced from 24 to make it more compact
                  ),
                  itemLabel: 'Home',
                ),
                BottomBarItem(
                  inActiveItem: Icon(
                    Icons.search_outlined,
                    color: Colors.white.withOpacity(0.6), // Slightly transparent white for inactive state
                    size: 20, // Reduced from 24 to make it more compact
                  ),
                  activeItem: Icon(
                    Icons.search,
                    color: Colors.white, // White for better contrast on dark
                    size: 20, // Reduced from 24 to make it more compact
                  ),
                  itemLabel: 'Search',
                ),
                BottomBarItem(
                  inActiveItem: Icon(
                    Icons.add_circle_outline,
                    color: Colors.white.withOpacity(0.6), // Slightly transparent white for inactive state
                    size: 24, // Reduced from 32 to make it more compact
                  ),
                  activeItem: Icon(
                    Icons.add_circle,
                    color: Colors.orange, // Changed to orange for contrast against dark
                    size: 24, // Reduced from 32 to make it more compact
                  ),
                  itemLabel: 'Post',
                ),
                BottomBarItem(
                  inActiveItem: Icon(
                    Icons.chat_outlined,
                    color: Colors.white.withOpacity(0.6), // Slightly transparent white for inactive state
                    size: 20, // Reduced from 24 to make it more compact
                  ),
                  activeItem: Icon(
                    Icons.chat,
                    color: Colors.white, // White for better contrast on dark
                    size: 20, // Reduced from 24 to make it more compact
                  ),
                  itemLabel: 'Chat',
                ),
                BottomBarItem(
                  inActiveItem: Icon(
                    Icons.person_outline,
                    color: Colors.white.withOpacity(0.6), // Slightly transparent white for inactive state
                    size: 20, // Reduced from 24 to make it more compact
                  ),
                  activeItem: Icon(
                    Icons.person,
                    color: Colors.white, // White for better contrast on dark
                    size: 20, // Reduced from 24 to make it more compact
                  ),
                  itemLabel: 'Profile',
                ),
              ],
              onTap: (index) {
                final authController = Provider.of<AuthController>(context, listen: false);
                final isLoggedIn = authController.state.user != null;

                if (index == 2) { // Post tab index
                  if (!isLoggedIn) {
                    // Show login bottom sheet if not logged in
                    _showLoginBottomSheet(context);
                    return;
                  }
                  // If logged in, navigate to post page
                  _pageController.jumpToPage(index);
                } else if (index == 3) { // Chat tab index
                  if (!isLoggedIn) {
                    // Show login bottom sheet if not logged in
                    _showLoginBottomSheet(context);
                    return;
                  }
                  // If logged in, navigate to chat page
                  _pageController.jumpToPage(index);
                } else {
                  _pageController.jumpToPage(index);
                }
              },
              kIconSize: 24.0,
            )
          : null,
    );
  }
}