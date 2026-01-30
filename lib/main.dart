import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:teftef/models/product.dart';
import 'intro_screen.dart';
import 'sign_in_page.dart';
import 'product_list_page.dart';
import 'product_detail_page.dart';
import 'chat_page.dart';
import 'search_page.dart';
import 'production_bottom_navigation.dart';
import 'profile_page.dart';
import 'edit_product_page.dart';
import 'auth/auth_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
      ],
      child: MaterialApp(
        title: 'Tef Tef - ተፍ ተፍ',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.black,
            primary: Colors.black,
            secondary: Colors.white,
          ),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const IntroScreen(),
          '/signin': (context) => const SignInPage(),
          '/home': (context) => const ProductionBottomNavigation(),
          '/search': (context) => const SearchPage(),
          '/category': (context) => ProductListPage(
            category: ModalRoute.of(context)?.settings.arguments as String?,
          ),
          '/product': (context) => ProductDetailPage(
            product: ModalRoute.of(context)?.settings.arguments as Product,
          ),
          '/chat': (context) => ChatPage(
            product: ModalRoute.of(context)?.settings.arguments as Product,
          ),
          '/profile': (context) => ProfilePage(),
          '/edit_product': (context) => EditProductPage(
            product: ModalRoute.of(context)?.settings.arguments,
          ),
        },
      ),
    );
  }
}
