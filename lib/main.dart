import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/database_provider.dart';
import 'services/sales_reminder_service.dart';
import 'screens/assistant_screen.dart';
import 'screens/customers_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/production_screen.dart';
import 'screens/profit_tracker_screen.dart';
import 'screens/sales_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: SamosaTrackerApp(),
    ),
  );
}

class SamosaTrackerApp extends StatelessWidget {
  const SamosaTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Akira Bites',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D47A1),
          brightness: Brightness.light,
          primary: const Color(0xFF0D47A1),
          error: const Color(0xFFD32F2F),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class MainNavScreen extends ConsumerStatefulWidget {
  const MainNavScreen({super.key});

  @override
  ConsumerState<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends ConsumerState<MainNavScreen>
    with WidgetsBindingObserver {
  int _currentBottomIndex = 0;
  _NavSection _activeSection = _NavSection.dashboard;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncSalesReminder();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncSalesReminder();
    }
  }

  Future<void> _syncSalesReminder() async {
    try {
      final db = ref.read(databaseProvider);
      final todaySales = await db.getSalesForDate(DateTime.now());
      await SalesReminderService.instance.syncDailyReminder(
        hasSalesToday: todaySales.isNotEmpty,
      );
    } catch (_) {
      // Ignore reminder sync failures to keep app navigation stable.
    }
  }

  Widget _screenFor(_NavSection section) {
    switch (section) {
      case _NavSection.dashboard:
        return const DashboardScreen();
      case _NavSection.sales:
        return const SalesScreen();
      case _NavSection.orders:
        return const OrdersScreen();
      case _NavSection.expenses:
        return const ExpensesScreen();
      case _NavSection.profit:
        return const ProfitTrackerScreen();
      case _NavSection.assistant:
        return const AssistantScreen();
      case _NavSection.production:
        return const ProductionScreen();
      case _NavSection.customers:
        return const CustomersScreen();
      case _NavSection.settings:
        return const SettingsScreen();
    }
  }

  void _setBottomSection(int index) {
    setState(() {
      _currentBottomIndex = index;
      _activeSection = switch (index) {
        0 => _NavSection.dashboard,
        1 => _NavSection.sales,
        2 => _NavSection.orders,
        3 => _NavSection.expenses,
        4 => _NavSection.profit,
        _ => _NavSection.dashboard,
      };
    });
  }

  void _setDrawerSection(_NavSection section) {
    Navigator.of(context).pop();
    setState(() => _activeSection = section);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Akira Bites'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            children: [
              const ListTile(
                title: Text(
                  'More Pages',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.smart_toy_outlined),
                title: const Text('Assistant'),
                selected: _activeSection == _NavSection.assistant,
                onTap: () => _setDrawerSection(_NavSection.assistant),
              ),
              ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: const Text('Production'),
                selected: _activeSection == _NavSection.production,
                onTap: () => _setDrawerSection(_NavSection.production),
              ),
              ListTile(
                leading: const Icon(Icons.people_outline),
                title: const Text('Customers'),
                selected: _activeSection == _NavSection.customers,
                onTap: () => _setDrawerSection(_NavSection.customers),
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Settings'),
                selected: _activeSection == _NavSection.settings,
                onTap: () => _setDrawerSection(_NavSection.settings),
              ),
            ],
          ),
        ),
      ),
      body: _screenFor(_activeSection),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentBottomIndex,
        onDestinationSelected: _setBottomSection,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.sell_outlined),
            selectedIcon: Icon(Icons.sell),
            label: 'Sales',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            selectedIcon: Icon(Icons.shopping_bag),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.money_off_csred_outlined),
            selectedIcon: Icon(Icons.money_off_csred),
            label: 'Expenses',
          ),
          NavigationDestination(
            icon: Icon(Icons.trending_up_outlined),
            selectedIcon: Icon(Icons.trending_up),
            label: 'Profit',
          ),
        ],
      ),
    );
  }
}

enum _NavSection {
  dashboard,
  sales,
  orders,
  expenses,
  profit,
  assistant,
  production,
  customers,
  settings,
}
