import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/database_provider.dart';
import 'providers/business_profile_provider.dart';
import 'services/business_profile_service.dart';
import 'services/sales_reminder_service.dart';
import 'screens/assistant_screen.dart';
import 'screens/customers_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/products_screen.dart';
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

class SamosaTrackerApp extends ConsumerWidget {
  const SamosaTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(businessProfileProvider);
    final appName = profileAsync.maybeWhen(
      data: (profile) => profile.name.isEmpty ? 'Akira Bites' : profile.name,
      orElse: () => 'Akira Bites',
    );
    return MaterialApp(
      title: appName,
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
      case _NavSection.products:
        return const ProductsScreen();
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

  List<_NavSection> _bottomSections(Set<String> modules) {
    final sections = <_NavSection>[_NavSection.dashboard];
    if (modules.contains(BusinessModules.salesManagement)) {
      sections.add(_NavSection.sales);
    }
    if (modules.contains(BusinessModules.productManagement) ||
        modules.contains(BusinessModules.whatsappOrdering)) {
      sections.add(_NavSection.orders);
    }
    if (modules.contains(BusinessModules.productManagement)) {
      sections.add(_NavSection.products);
    }
    if (modules.contains(BusinessModules.expenseTracking)) {
      sections.add(_NavSection.expenses);
    }
    if (modules.contains(BusinessModules.profitCalculation)) {
      sections.add(_NavSection.profit);
    }
    return sections;
  }

  List<_NavSection> _allowedSections(Set<String> modules) {
    final allowed = <_NavSection>{
      ..._bottomSections(modules),
      _NavSection.assistant,
      _NavSection.settings,
    };
    if (modules.contains(BusinessModules.customerManagement)) {
      allowed.add(_NavSection.customers);
    }
    if (modules.contains(BusinessModules.productionTracking)) {
      allowed.add(_NavSection.production);
    }
    return allowed.toList();
  }

  void _setBottomSection(List<_NavSection> visibleBottomSections, int index) {
    setState(() {
      _activeSection = visibleBottomSections[index];
    });
  }

  void _setDrawerSection(_NavSection section) {
    Navigator.of(context).pop();
    setState(() => _activeSection = section);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(businessProfileProvider).maybeWhen(
          data: (value) => value,
          orElse: () => const BusinessProfile(
            name: 'Akira Bites',
            whatsappPhone: '',
            type: BusinessType.foodVendor,
            enabledModules: {
              BusinessModules.salesManagement,
              BusinessModules.productManagement,
              BusinessModules.customerManagement,
              BusinessModules.expenseTracking,
              BusinessModules.profitCalculation,
              BusinessModules.reportsAnalytics,
              BusinessModules.whatsappOrdering,
              BusinessModules.productionTracking,
            },
          ),
        );
    final bottomSections = _bottomSections(profile.enabledModules);
    final allowedSections = _allowedSections(profile.enabledModules);
    final effectiveSection = allowedSections.contains(_activeSection)
        ? _activeSection
        : _NavSection.dashboard;
    final selectedBottomIndex = bottomSections.contains(effectiveSection)
        ? bottomSections.indexOf(effectiveSection)
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: ref.watch(businessProfileProvider).maybeWhen(
              data: (profile) =>
                  Text(profile.name.isEmpty ? 'Akira Bites' : profile.name),
              orElse: () => const Text('Akira Bites'),
            ),
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
                selected: effectiveSection == _NavSection.assistant,
                onTap: () => _setDrawerSection(_NavSection.assistant),
              ),
              if (profile.enabledModules
                  .contains(BusinessModules.productionTracking))
                ListTile(
                  leading: const Icon(Icons.inventory_2_outlined),
                  title: const Text('Production'),
                  selected: effectiveSection == _NavSection.production,
                  onTap: () => _setDrawerSection(_NavSection.production),
                ),
              if (profile.enabledModules
                  .contains(BusinessModules.customerManagement))
                ListTile(
                  leading: const Icon(Icons.people_outline),
                  title: const Text('Customers'),
                  selected: effectiveSection == _NavSection.customers,
                  onTap: () => _setDrawerSection(_NavSection.customers),
                ),
              if (profile.enabledModules
                  .contains(BusinessModules.productManagement))
                ListTile(
                  leading: const Icon(Icons.inventory_2_outlined),
                  title: const Text('Products'),
                  selected: effectiveSection == _NavSection.products,
                  onTap: () => _setDrawerSection(_NavSection.products),
                ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Settings'),
                selected: effectiveSection == _NavSection.settings,
                onTap: () => _setDrawerSection(_NavSection.settings),
              ),
            ],
          ),
        ),
      ),
      body: _screenFor(effectiveSection),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedBottomIndex,
        onDestinationSelected: (index) => _setBottomSection(bottomSections, index),
        destinations: bottomSections.map((section) {
          switch (section) {
            case _NavSection.dashboard:
              return const NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Dashboard',
              );
            case _NavSection.sales:
              return const NavigationDestination(
                icon: Icon(Icons.sell_outlined),
                selectedIcon: Icon(Icons.sell),
                label: 'Sales',
              );
            case _NavSection.orders:
              return const NavigationDestination(
                icon: Icon(Icons.shopping_bag_outlined),
                selectedIcon: Icon(Icons.shopping_bag),
                label: 'Orders',
              );
            case _NavSection.expenses:
              return const NavigationDestination(
                icon: Icon(Icons.money_off_csred_outlined),
                selectedIcon: Icon(Icons.money_off_csred),
                label: 'Expenses',
              );
            case _NavSection.products:
              return const NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2),
                label: 'Products',
              );
            case _NavSection.profit:
              return const NavigationDestination(
                icon: Icon(Icons.trending_up_outlined),
                selectedIcon: Icon(Icons.trending_up),
                label: 'Profit',
              );
            case _NavSection.assistant:
            case _NavSection.production:
            case _NavSection.customers:
            case _NavSection.settings:
              return const NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Dashboard',
              );
          }
        }).toList(),
      ),
    );
  }
}

enum _NavSection {
  dashboard,
  sales,
  orders,
  products,
  expenses,
  profit,
  assistant,
  production,
  customers,
  settings,
}
