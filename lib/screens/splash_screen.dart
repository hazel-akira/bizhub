import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late AnimationController _logoController;
  late AnimationController _imageController;
  late AnimationController _progressController;

  late Animation<double> _logoFade;
  late Animation<Offset> _leftImageSlide;
  late Animation<Offset> _rightImageSlide;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();

    // Logo fade animation
    _logoController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );

    // Image slide animation
    _imageController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));

    _leftImageSlide = Tween<Offset>(
      begin: const Offset(-1.5, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _imageController, curve: Curves.easeOut),
    );

    _rightImageSlide = Tween<Offset>(
      begin: const Offset(1.5, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _imageController, curve: Curves.easeOut),
    );

    // Progress animation
    _progressController =
        AnimationController(vsync: this, duration: const Duration(seconds: 3));

    _progressAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    // Start animations
    _logoController.forward();

    Future.delayed(const Duration(milliseconds: 500), () {
      _imageController.forward();
    });

    _progressController.forward();

    // Navigate after animation
    Timer(const Duration(seconds: 4), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const MainNavScreen(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _imageController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFE65100),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            /// 🔥 LOGO FADE
            FadeTransition(
              opacity: _logoFade,
              child: Image.asset(
                'assets/images/logo.png',
                height: 140,
              ),
            ),

            const SizedBox(height: 20),

            /// 🧾 APP NAME
            FadeTransition(
              opacity: _logoFade,
              child: const Text(
                "Akira Bites",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            const SizedBox(height: 40),

            /// 🍽️ SLIDING IMAGES
            Row(
              children: [
                Expanded(
                  child: SlideTransition(
                    position: _leftImageSlide,
                    child: Image.asset(
                      'assets/images/beef_samosa.jpeg',
                      width: screenWidth * 0.3,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SlideTransition(
                    position: _rightImageSlide,
                    child: Image.asset(
                      'assets/images/chicken_samosa.jpeg',
                      width: screenWidth * 0.3,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            /// ⏳ PROGRESS BAR
            AnimatedBuilder(
              animation: _progressAnim,
              builder: (context, child) {
                return Column(
                  children: [
                    LinearProgressIndicator(
                      value: _progressAnim.value,
                      minHeight: 6,
                      backgroundColor: Colors.white24,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Loading... ${( _progressAnim.value * 100).toInt()}%",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}