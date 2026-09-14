import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/layout.dart';
import 'providers/api_data_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/business_api_provider.dart';
import 'providers/business_profile_provider.dart';
import 'providers/business_theme_provider.dart';
import 'providers/database_provider.dart';
import 'screens/login_screen.dart';
import 'services/sales_reminder_service.dart';
import 'screens/assistant_screen.dart';
import 'screens/customers_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/production_screen.dart';
import 'screens/profit_tracker_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/sales_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/staff_screen.dart';
import 'widgets/access_denied_page.dart';

void main() {
  runApp(
    const ProviderScope(
      child: BizHubApp(),
    ),
  );
}

class BizHubApp extends ConsumerWidget {
  const BizHubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(businessThemeProvider);

    return MaterialApp(
      title: 'Akira Flow',
      debugShowCheckedModeBanner: false,
      theme: theme,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: AppLayout.clampedTextScaler(mq.textScaler),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
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
      final useCloud = ref.read(useCloudDataProvider);
      final hasSalesToday = useCloud
          ? (await ref.read(apiTodaySalesProvider.future)).isNotEmpty
          : (await ref.read(databaseProvider).getSalesForDate(DateTime.now()))
              .isNotEmpty;

      await SalesReminderService.instance.syncDailyReminder(
        hasSalesToday: hasSalesToday,
      );
    } catch (_) {}
  }

  List<_BottomNavItem> _bottomNavItems() {
    final config = ref.read(businessTypeConfigProvider);
    final access = ref.read(staffAccessProvider);
    final items = <_BottomNavItem>[
      const _BottomNavItem(
        section: _NavSection.dashboard,
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        label: 'Home',
      ),
    ];

    if (access.canOpenSales) {
      items.add(
        const _BottomNavItem(
          section: _NavSection.sales,
          icon: Icons.sell_outlined,
          selectedIcon: Icons.sell,
          label: 'Sales',
        ),
      );
    }

    if (access.canOpenInventory && config.showInventoryNav) {
      items.add(
        const _BottomNavItem(
          section: _NavSection.inventory,
          icon: Icons.inventory_2_outlined,
          selectedIcon: Icons.inventory_2,
          label: 'Stock',
        ),
      );
    } else if (access.canOpenOrders && config.showOrdersNav) {
      items.add(
        const _BottomNavItem(
          section: _NavSection.orders,
          icon: Icons.shopping_bag_outlined,
          selectedIcon: Icons.shopping_bag,
          label: 'Orders',
        ),
      );
    }

    if (access.canOpenReports) {
      items.add(
        const _BottomNavItem(
          section: _NavSection.reports,
          icon: Icons.assessment_outlined,
          selectedIcon: Icons.assessment,
          label: 'Reports',
        ),
      );
    }

    if (access.canOpenExpenses) {
      items.add(
        const _BottomNavItem(
          section: _NavSection.expenses,
          icon: Icons.money_off_csred_outlined,
          selectedIcon: Icons.money_off_csred,
          label: 'Costs',
        ),
      );
    }

    if (access.canOpenProfit && config.showProfitNav) {
      items.add(
        const _BottomNavItem(
          section: _NavSection.profit,
          icon: Icons.trending_up_outlined,
          selectedIcon: Icons.trending_up,
          label: 'Profit',
        ),
      );
    }

    return items;
  }

  bool _canOpenSection(_NavSection section) {
    final config = ref.read(businessTypeConfigProvider);
    final access = ref.read(staffAccessProvider);
    switch (section) {
      case _NavSection.dashboard:
        return true;
      case _NavSection.sales:
        return access.canOpenSales;
      case _NavSection.orders:
        return access.canOpenOrders && config.showOrdersNav;
      case _NavSection.expenses:
        return access.canOpenExpenses;
      case _NavSection.profit:
        return access.canOpenProfit && config.showProfitNav;
      case _NavSection.assistant:
        return access.canOpenAssistant;
      case _NavSection.production:
        return access.canOpenProduction && config.showProductionDrawer;
      case _NavSection.inventory:
        return access.canOpenInventory && config.showInventoryNav;
      case _NavSection.reports:
        return access.canOpenReports;
      case _NavSection.customers:
        return access.canOpenCustomers;
      case _NavSection.settings:
        return access.canOpenSettings;
    }
  }

  Widget _screenFor(_NavSection section) {
    if (!_canOpenSection(section)) {
      return const AccessDeniedBody();
    }

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
      case _NavSection.inventory:
        return const InventoryScreen();
      case _NavSection.reports:
        return const ReportsScreen();
      case _NavSection.customers:
        return const CustomersScreen();
      case _NavSection.settings:
        return const SettingsScreen();
    }
  }

  void _setBottomSection(int index) {
    final items = _bottomNavItems();
    if (index < 0 || index >= items.length) return;
    setState(() {
      _currentBottomIndex = index;
      _activeSection = items[index].section;
    });
  }

  void _setDrawerSection(_NavSection section) {
    Navigator.of(context).pop();
    if (!_canOpenSection(section)) return;
    setState(() => _activeSection = section);
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(businessTypeConfigProvider);
    final auth = ref.watch(authProvider);
    final access = ref.watch(staffAccessProvider);
    final palette = ref.watch(businessThemePaletteProvider);
    final bottomItems = _bottomNavItems();
    if (_currentBottomIndex >= bottomItems.length ||
        !_canOpenSection(_activeSection)) {
      _currentBottomIndex = 0;
      _activeSection = bottomItems.isNotEmpty
          ? bottomItems.first.section
          : _NavSection.dashboard;
    } else {
      final matched = bottomItems.indexWhere(
        (item) => item.section == _activeSection,
      );
      if (matched >= 0) _currentBottomIndex = matched;
    }

    final appBarTitle = auth.user?.businessName ?? config.appTitle;

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle, overflow: TextOverflow.ellipsis),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            children: [
              Consumer(
                builder: (context, ref, _) {
                  final user = ref.watch(authProvider).user;
                  return UserAccountsDrawerHeader(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          palette.primary,
                          Color.lerp(
                            palette.primary,
                            palette.secondary,
                            0.4,
                          )!,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    currentAccountPicture: CircleAvatar(
                      backgroundColor: palette.accent.withValues(alpha: 0.9),
                      child: Text(
                        (user?.name.isNotEmpty == true
                                ? user!.name[0]
                                : '?')
                            .toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    accountName: Text(user?.name ?? 'Signed in'),
                    accountEmail: Text(
                      user?.businessTypeLabel ?? user?.email ?? '',
                    ),
                  );
                },
              ),
              const ListTile(
                title: Text(
                  'More pages',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              if (access.canOpenReports)
                ListTile(
                  leading: const Icon(Icons.assessment_outlined),
                  title: const Text('Reports'),
                  selected: _activeSection == _NavSection.reports,
                  onTap: () => _setDrawerSection(_NavSection.reports),
                ),
              if (access.canOpenAssistant)
                ListTile(
                  leading: const Icon(Icons.smart_toy_outlined),
                  title: const Text('Assistant'),
                  selected: _activeSection == _NavSection.assistant,
                  onTap: () => _setDrawerSection(_NavSection.assistant),
                ),
              if (access.canOpenOrders && config.showOrdersNav)
                ListTile(
                  leading: const Icon(Icons.shopping_bag_outlined),
                  title: const Text('Orders'),
                  selected: _activeSection == _NavSection.orders,
                  onTap: () => _setDrawerSection(_NavSection.orders),
                ),
              if (access.canOpenInventory && config.showInventoryNav)
                ListTile(
                  leading: const Icon(Icons.inventory_2_outlined),
                  title: const Text('Inventory'),
                  selected: _activeSection == _NavSection.inventory,
                  onTap: () => _setDrawerSection(_NavSection.inventory),
                ),
              if (access.canOpenProduction && config.showProductionDrawer)
                ListTile(
                  leading: const Icon(Icons.bakery_dining_outlined),
                  title: const Text('Production'),
                  selected: _activeSection == _NavSection.production,
                  onTap: () => _setDrawerSection(_NavSection.production),
                ),
              if (access.canOpenCustomers)
                ListTile(
                  leading: const Icon(Icons.people_outline),
                  title: const Text('Customers'),
                  selected: _activeSection == _NavSection.customers,
                  onTap: () => _setDrawerSection(_NavSection.customers),
                ),
              if (access.canOpenStaff)
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('Staff & roles'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const StaffScreen()),
                    );
                  },
                ),
              if (access.canOpenSettings)
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('Settings'),
                  selected: _activeSection == _NavSection.settings,
                  onTap: () => _setDrawerSection(_NavSection.settings),
                ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sign out'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await ref.read(authProvider.notifier).logout();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: _screenFor(_activeSection),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentBottomIndex,
        onDestinationSelected: _setBottomSection,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: bottomItems
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _BottomNavItem {
  const _BottomNavItem({
    required this.section,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final _NavSection section;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

enum _NavSection {
  dashboard,
  sales,
  orders,
  expenses,
  profit,
  assistant,
  production,
  inventory,
  reports,
  customers,
  settings,
}
