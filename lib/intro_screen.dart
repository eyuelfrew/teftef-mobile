import 'package:flutter/material.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _IntroScreenState createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<IntroSlide> _slides = [
    IntroSlide(
      title: "Welcome to Tef Tef",
      titleAmharic: "እንኳን ደህና መጡ",
      description: "Your one-stop platform to buy and sell amazing products",
      descriptionAmharic: "ለመግዛት እና ለመሸጥ የሚገኙበት አንድ ቦታ ያለው ተመራጭ መድረክ",
      icon: Icons.storefront,
    ),
    IntroSlide(
      title: "Post Your Products",
      titleAmharic: "እርስዎ ማስታወቂያዎችን ይለኩ",
      description: "Easily list your products and reach thousands of potential buyers",
      descriptionAmharic: "በቀላሉ ማስታወቂያዎችዎን ይለኩ እና ስዎ ሊሸጡ የሚችሉ ሰዎችን ያግኙ",
      icon: Icons.add_business,
    ),
    IntroSlide(
      title: "Find Great Deals",
      titleAmharic: "ደማቅ ገናቶችን ያግኙ",
      description: "Browse through thousands of products at competitive prices",
      descriptionAmharic: "በተመሳሳይ ዋጋ ሊሸጡ የሚችሉ ስዎ ምርቶችን ያሰስሉ",
      icon: Icons.shopping_cart,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Clean white background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    return _buildSlide(_slides[index]);
                  },
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _buildPageIndicators(),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage < _slides.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      // Navigate to sign in page
                      Navigator.pushReplacementNamed(context, '/signin');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black, // Dark button for contrast
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _currentPage == _slides.length - 1 ? "Get Started" : "Next",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // Skip sign-in and go directly to home
                  Navigator.pushReplacementNamed(context, '/home');
                },
                child: const Text(
                  "Skip for now",
                  style: TextStyle(
                    color: Colors.black45,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlide(IntroSlide slide) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            slide.icon,
            size: 80,
            color: Colors.orange, // Vibrant icon
          ),
        ),
        const SizedBox(height: 32),
        Text(
          "ተፍ ተፍ",
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.black, // Dark text
          ),
        ),
        const SizedBox(height: 8),
        Text(
          slide.titleAmharic,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          slide.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          slide.descriptionAmharic,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black45,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          slide.description,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black38,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPageIndicators() {
    return List<Widget>.generate(_slides.length, (index) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: _currentPage == index ? 24 : 8,
        height: 8,
        decoration: BoxDecoration(
          color: _currentPage == index ? Colors.black : Colors.black12,
          borderRadius: BorderRadius.circular(4),
        ),
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class IntroSlide {
  final String title;
  final String titleAmharic;
  final String description;
  final String descriptionAmharic;
  final IconData icon;

  IntroSlide({
    required this.title,
    required this.titleAmharic,
    required this.description,
    required this.descriptionAmharic,
    required this.icon,
  });
}