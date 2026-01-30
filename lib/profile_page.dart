import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_controller.dart';
import 'components/login_bottom_sheet.dart';
import 'my_products_page.dart';

import 'auth/phone_verification_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isDarkTheme = false;

  @override
  void initState() {
    super.initState();
    // Refresh profile from backend when visiting the page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthController>(context, listen: false).refreshProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final authState = authController.state;

    // Show login bottom sheet if user is not logged in
    if (authState.user == null && !authState.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showLoginBottomSheet(context);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 50, 50, 50),
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: const Text(
          "My Profile",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          if (authState.user != null)
            IconButton(
              onPressed: () {
                authController.signOut();
              },
              icon: const Icon(Icons.logout, color: Colors.white, size: 20),
            ),
        ],
      ),
      body: authState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : authState.user == null
              ? _buildGuestContent()
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Header with Dark Background
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        decoration: const BoxDecoration(
                          color: Color.fromARGB(255, 50, 50, 50),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(32),
                            bottomRight: Radius.circular(32),
                          ),
                        ),
                        child: _buildUserHeader(authState.backendUser ?? authState.user),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Phone Verification Warning
                            if (authState.backendUser != null && 
                                authState.backendUser!['is_phone_verified'] == false)
                              _buildVerificationWarning(),
                            
                            const SizedBox(height: 8),
                            // Menu Items
                      _buildMenuItem(
                        icon: Icons.inventory_2_outlined,
                        iconColor: Colors.orange,
                        label: "My Products",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MyProductsPage(),
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.workspace_premium,
                        iconColor: Colors.teal,
                        label: "My Featured Ads",
                      ),
                      _buildThemeToggle(),
                      _buildMenuItem(
                        icon: Icons.subscriptions_outlined,
                        iconColor: Colors.teal,
                        label: "Subscription",
                      ),
                      _buildMenuItem(
                        icon: Icons.history_edu,
                        iconColor: Colors.teal,
                        label: "Transaction History",
                      ),
                      _buildMenuItem(
                        icon: Icons.rate_review_outlined,
                        iconColor: Colors.teal,
                        label: "My Reviews",
                      ),
                      _buildMenuItem(
                        icon: Icons.assignment_outlined,
                        iconColor: Colors.teal,
                        label: "My Job Applications",
                      ),
                      _buildMenuItem(
                        icon: Icons.notifications_none,
                        iconColor: Colors.teal,
                        label: "Notifications",
                      ),
                      _buildMenuItem(
                        icon: Icons.favorite_border,
                        iconColor: Colors.teal,
                        label: "Favorites",
                      ),
                      _buildMenuItem(
                        icon: Icons.star_border,
                        iconColor: Colors.teal,
                        label: "Rate us",
                      ),
                      _buildMenuItem(
                        icon: Icons.contact_support_outlined,
                        iconColor: Colors.teal,
                        label: "Contact us",
                      ),
                      _buildMenuItem(
                        icon: Icons.info_outline,
                        iconColor: Colors.teal,
                        label: "About us",
                      ),
                      _buildMenuItem(
                        icon: Icons.description_outlined,
                        iconColor: Colors.teal,
                        label: "Terms & Conditions",
                      ),
                          const SizedBox(height: 100), // Space for bottom navigation
                        ],
                      ),
                    ),
                  ],
                ),
    ));
  }

  Widget _buildVerificationWarning() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Your phone number is not verified",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PhoneVerificationPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Verify Now"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestContent() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.account_circle,
            size: 100,
            color: Colors.grey,
          ),
          const SizedBox(height: 24),
          const Text(
            "Not Signed In",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            "Sign in to access your profile and other features",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              _showLoginBottomSheet(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Sign In",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ignore: strict_top_level_inference
  Widget _buildUserHeader(user) {
    String? photoUrl;
    String? displayName;
    String? email;
    String? phoneNumber;
    bool isVerified = false;

    if (user is Map) {
      photoUrl = user['profile_pic'] ?? user['photoURL'];
      displayName = user['first_name'] != null 
          ? "${user['first_name']} ${user['last_name'] ?? ''}" 
          : user['displayName'];
      email = user['email'];
      phoneNumber = user['phone_number'];
      isVerified = user['is_phone_verified'] ?? false;
    } else {
      photoUrl = user.photoURL;
      displayName = user.displayName;
      email = user.email;
      phoneNumber = user.phoneNumber;
    }

    return Row(
      children: [
        Stack(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isVerified ? Colors.teal : Colors.grey.shade300, 
                  width: 2
                ),
                color: Colors.white,
              ),
              child: photoUrl != null
                  ? ClipOval(
                      child: Image.network(
                        photoUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.person, size: 50, color: Colors.grey);
                        },
                      ),
                    )
                  : const Icon(Icons.person, size: 50, color: Colors.grey),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFF1B4D3E),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, size: 14, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName ?? "User",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                email ?? "No email",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              if (phoneNumber != null && phoneNumber.isNotEmpty)
                Text(
                  phoneNumber,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.teal,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const SizedBox(height: 8),
              if (!isVerified)
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4D3E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    minimumSize: const Size(0, 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Get Verification Badge",
                    style: TextStyle(fontSize: 12),
                  ),
                )
              else
                Row(
                  children: [
                    const Icon(Icons.verified, color: Colors.teal, size: 16),
                    const SizedBox(width: 4),
                    const Text(
                      "Verified Profile",
                      style: TextStyle(
                        color: Colors.teal,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        onTap: onTap ?? () {},
      ),
    );
  }

  Widget _buildThemeToggle() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.teal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.light_mode_outlined, color: Colors.teal, size: 20),
        ),
        title: const Text(
          "Dark Theme",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Switch(
          value: _isDarkTheme,
          onChanged: (value) {
            setState(() {
              _isDarkTheme = value;
            });
          },
          activeColor: Colors.teal,
        ),
      ),
    );
  }

  void _showLoginBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return LoginBottomSheet();
      },
    );
  }
}
