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
  static const _brandGreen = Color(0xFF2D5A3D);
  static const _brandOrange = Color(0xFFC75B12);

  late final AnimationController _introController;
  late final AnimationController _progressController;

  late final Animation<double> _markFade;
  late final Animation<double> _markScale;
  late final Animation<Offset> _markSlide;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _taglineFade;
  late final Animation<double> _progressAnim;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _markFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    _markScale = Tween<double>(begin: 0.82, end: 1).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
      ),
    );
    _markSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    _titleFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.35, 0.7, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.35, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    _taglineFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.55, 0.95, curve: Curves.easeOut),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _progressAnim = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    );

    _introController.forward();
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _progressController.forward();
    });

    Timer(const Duration(milliseconds: 3200), _tryNavigate);
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
    _introController.dispose();
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            children: [
              const Spacer(flex: 3),
              SlideTransition(
                position: _markSlide,
                child: FadeTransition(
                  opacity: _markFade,
                  child: ScaleTransition(
                    scale: _markScale,
                    child: Image.asset(
                      'assets/images/mark.png',
                      height: 148,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SlideTransition(
                position: _titleSlide,
                child: FadeTransition(
                  opacity: _titleFade,
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        height: 1.1,
                      ),
                      children: [
                        TextSpan(
                          text: 'Akira',
                          style: TextStyle(color: _brandGreen),
                        ),
                        TextSpan(
                          text: 'Flow',
                          style: TextStyle(color: _brandOrange),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              FadeTransition(
                opacity: _taglineFade,
                child: Text.rich(
                  TextSpan(
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.8,
                      color: Colors.grey.shade800,
                    ),
                    children: const [
                      TextSpan(text: 'Operate'),
                      TextSpan(
                        text: ' · ',
                        style: TextStyle(color: _brandOrange),
                      ),
                      TextSpan(
                        text: 'Automate',
                        style: TextStyle(color: _brandOrange),
                      ),
                      TextSpan(
                        text: ' · ',
                        style: TextStyle(color: _brandOrange),
                      ),
                      TextSpan(text: 'Scale'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(flex: 2),
              FadeTransition(
                opacity: _taglineFade,
                child: AnimatedBuilder(
                  animation: _progressAnim,
                  builder: (context, child) {
                    return Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: _progressAnim.value,
                            minHeight: 5,
                            backgroundColor: _brandGreen.withValues(alpha: 0.1),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              _brandOrange,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Loading... ${(_progressAnim.value * 100).toInt()}%',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
