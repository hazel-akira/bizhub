import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../main.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _progressController;

  late Animation<double> _logoFade;
  late Animation<double> _progressAnim;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _progressAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _logoController.forward();
    _progressController.forward();

    Timer(const Duration(seconds: 3), _tryNavigate);
  }

  void _tryNavigate() {
    if (_navigated || !mounted) return;
    final auth = ref.read(authProvider);
    if (auth.isLoading) return;
    _goNext(auth.isAuthenticated);
  }

  void _goNext(bool isAuthenticated) {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            isAuthenticated ? const MainNavScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (!next.isLoading && !_navigated) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && !_navigated) {
            _goNext(next.isAuthenticated);
          }
        });
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFE65100),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _logoFade,
              child: Image.asset('assets/images/logo.png', height: 140),
            ),
            const SizedBox(height: 20),
            FadeTransition(
              opacity: _logoFade,
              child: const Text(
                'BizHub',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            FadeTransition(
              opacity: _logoFade,
              child: const Text(
                'Business platform for every shop',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 32),
            FadeTransition(
              opacity: _logoFade,
              child: Icon(
                Icons.storefront_outlined,
                size: 80,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 40),
            AnimatedBuilder(
              animation: _progressAnim,
              builder: (context, child) {
                return Column(
                  children: [
                    LinearProgressIndicator(
                      value: _progressAnim.value,
                      minHeight: 6,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Loading... ${(_progressAnim.value * 100).toInt()}%',
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
