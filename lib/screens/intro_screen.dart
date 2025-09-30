import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'signup_screen.dart';

class OnBoardingPage extends StatelessWidget {
  OnBoardingPage({super.key});

  final List<PageViewModel> pages = [
    PageViewModel(
      title: "Hello! Nadia",
      body: "Welcome to Sakamoto World ~~\nWhere every day is filled with wonder and joy",
      image: Container(
        height: 350,
        width: double.infinity,
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background gradient circle
              Container(
                height: 280,
                width: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0xFFFF6B6B).withOpacity(0.3),
                      Color(0xFFFFE66D).withOpacity(0.1),
                      Colors.transparent,
                    ],
                    stops: [0.3, 0.7, 1.0],
                  ),
                ),
              ),
              // Main image container
              Container(
                height: 200,
                width: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFF6B6B),
                      Color(0xFFFFE66D),
                      Color(0xFF4ECDC4),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFFF6B6B).withOpacity(0.4),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        "assets/images/front.jpg",
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              // Floating elements
              Positioned(
                top: 30,
                right: 40,
                child: Container(
                  height: 20,
                  width: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFF6B6B).withOpacity(0.6),
                  ),
                ),
              ),
              Positioned(
                bottom: 40,
                left: 50,
                child: Container(
                  height: 15,
                  width: 15,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF4ECDC4).withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      decoration: PageDecoration(
        pageColor: Color(0xFFFFF8F0),
        titleTextStyle: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: Color(0xFF2C3E50),
          letterSpacing: 0.5,
        ),
        bodyTextStyle: TextStyle(
          fontSize: 16,
          color: Color(0xFF5D6D7E),
          height: 1.4,
          fontWeight: FontWeight.w400,
        ),
        imagePadding: EdgeInsets.only(top: 60),
        titlePadding: EdgeInsets.only(top: 20),
        bodyPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),
    PageViewModel(
      title: "Spread Joy with Every Moment",
      body: "Embrace the sweetness of life, where friendship, adventure, and a bit of pudding make everything brighter!",
      image: Container(
        height: 350,
        width: double.infinity,
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Animated background particles
              Positioned(
                top: 20,
                left: 60,
                child: Container(
                  height: 8,
                  width: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE74C3C),
                  ),
                ),
              ),
              Positioned(
                top: 60,
                right: 80,
                child: Container(
                  height: 12,
                  width: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFF39C12),
                  ),
                ),
              ),
              // Main container
              Container(
                height: 200,
                width: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFE74C3C),
                      Color(0xFFF39C12),
                      Color(0xFFE67E22),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFE74C3C).withOpacity(0.4),
                      blurRadius: 25,
                      offset: Offset(0, 12),
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        "assets/images/sakamoto2.jpg",
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              // More floating elements
              Positioned(
                bottom: 30,
                right: 30,
                child: Container(
                  height: 25,
                  width: 25,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      decoration: PageDecoration(
        pageColor: Color(0xFFF8F5FF),
        titleTextStyle: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: Color(0xFF2C3E50),
          letterSpacing: 0.3,
        ),
        bodyTextStyle: TextStyle(
          fontSize: 16,
          color: Color(0xFF5D6D7E),
          height: 1.4,
        ),
        imagePadding: EdgeInsets.only(top: 60),
        titlePadding: EdgeInsets.only(top: 20),
        bodyPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),
    PageViewModel(
      title: "A New Beginning with Every Step",
      body: "Where every day brings a fresh start—full of laughter, friendship, and the sweetness of life's simple joys.",
      image: Container(
        height: 350,
        width: double.infinity,
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background glow effect
              Container(
                height: 260,
                width: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0xFF9B59B6).withOpacity(0.2),
                      Color(0xFF3498DB).withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              // Main image
              Container(
                height: 200,
                width: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF9B59B6),
                      Color(0xFF3498DB),
                      Color(0xFF1ABC9C),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF9B59B6).withOpacity(0.4),
                      blurRadius: 30,
                      offset: Offset(0, 15),
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        "assets/images/sakamoto3.jpg",
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              // Decorative elements
              Positioned(
                top: 10,
                left: 30,
                child: Container(
                  height: 18,
                  width: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF9B59B6), Color(0xFF3498DB)],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 70,
                child: Container(
                  height: 10,
                  width: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF1ABC9C),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      decoration: PageDecoration(
        pageColor: Color(0xFFF0FFF4),
        titleTextStyle: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: Color(0xFF2C3E50),
          letterSpacing: 0.3,
        ),
        bodyTextStyle: TextStyle(
          fontSize: 16,
          color: Color(0xFF5D6D7E),
          height: 1.4,
        ),
        imagePadding: EdgeInsets.only(top: 60),
        titlePadding: EdgeInsets.only(top: 20),
        bodyPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),
  ];

  Future<void> onDone(context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ON_BOARDING', false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SignUpScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style for Android
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: IntroductionScreen(
        globalBackgroundColor: Colors.white,
        pages: pages,
        dotsDecorator: DotsDecorator(
          size: const Size(12, 12),
          activeSize: const Size(28, 12),
          color: Colors.grey.shade300,
          activeColor: Color(0xFF3498DB),
          spacing: EdgeInsets.symmetric(horizontal: 6),
          activeShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        showDoneButton: true,
        done: Container(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3498DB), Color(0xFF2980B9)],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF3498DB).withOpacity(0.3),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            "Get Started",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        showSkipButton: true,
        skip: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            "Skip",
            style: TextStyle(
              color: Color(0xFF7F8C8D),
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ),
        showNextButton: true,
        next: Container(
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF3498DB), Color(0xFF2980B9)],
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF3498DB).withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.arrow_forward_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        onDone: () => onDone(context),
        onSkip: () => onDone(context),
        curve: Curves.easeInOutCubic,
        controlsMargin: EdgeInsets.fromLTRB(24, 16, 24, 
          MediaQuery.of(context).padding.bottom + 24),
        controlsPadding: EdgeInsets.zero,
        animationDuration: 300,
        scrollPhysics: BouncingScrollPhysics(),
      ),
    );
  }
}