import 'package:flutter/material.dart';

import '../services/app_tour_service.dart';

class AppIntroPage {
  const AppIntroPage({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;
}

/// Full-screen swipe intro shown once after first login (replayable from Settings).
class AppIntroScreen extends StatefulWidget {
  const AppIntroScreen({
    super.key,
    required this.nextBuilder,
    this.markCompleted = true,
  });

  /// Screen to open after Skip / Get started (usually [MainNavScreen]).
  final WidgetBuilder nextBuilder;

  /// When false (Settings replay while already in-app), just pop instead.
  final bool markCompleted;

  @override
  State<AppIntroScreen> createState() => _AppIntroScreenState();
}

class _AppIntroScreenState extends State<AppIntroScreen> {
  final _controller = PageController();
  int _index = 0;

  static const _pages = <AppIntroPage>[
    AppIntroPage(
      icon: Icons.storefront_outlined,
      title: 'Welcome to your shop hub',
      body:
          'Track sales, stock, costs, and profit in one place — built for day-to-day store operations.',
      color: Color(0xFF2D5A3D),
    ),
    AppIntroPage(
      icon: Icons.sell_outlined,
      title: 'Record sales fast',
      body:
          'Use the Sales tab to take cash, M-Pesa, or credit sales. Receipts stay linked to your inventory.',
      color: Color(0xFFC75B12),
    ),
    AppIntroPage(
      icon: Icons.inventory_2_outlined,
      title: 'Keep stock under control',
      body:
          'Add products, watch quantities, and avoid selling what you do not have.',
      color: Color(0xFF1565C0),
    ),
    AppIntroPage(
      icon: Icons.menu_open,
      title: 'More tools in the menu',
      body:
          'Open the side menu for customers, staff, settings, M-Pesa, and KRA eTIMS options.',
      color: Color(0xFF6A1B9A),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (widget.markCompleted) {
      await AppTourService.instance.markIntroCompleted();
    }
    if (!mounted) return;

    final canPop = Navigator.of(context).canPop();
    if (canPop && !widget.markCompleted) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: widget.nextBuilder),
    );
  }

  void _next() {
    if (_index >= _pages.length - 1) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final page = _pages[_index];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final p = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 112,
                          height: 112,
                          decoration: BoxDecoration(
                            color: p.color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(p.icon, size: 56, color: p.color),
                        ),
                        const SizedBox(height: 36),
                        Text(
                          p.title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          p.body,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active
                        ? page.color
                        : theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(99),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                    backgroundColor: page.color,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    _index >= _pages.length - 1 ? 'Get started' : 'Next',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
