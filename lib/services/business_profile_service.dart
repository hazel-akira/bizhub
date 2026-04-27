import 'package:shared_preferences/shared_preferences.dart';

enum BusinessType { foodVendor, retailShop, salon }

class BusinessModules {
  static const String salesManagement = 'sales_management';
  static const String productManagement = 'product_management';
  static const String customerManagement = 'customer_management';
  static const String expenseTracking = 'expense_tracking';
  static const String profitCalculation = 'profit_calculation';
  static const String reportsAnalytics = 'reports_analytics';
  static const String whatsappOrdering = 'whatsapp_ordering';
  static const String productionTracking = 'production_tracking';

  static const List<String> all = [
    salesManagement,
    productManagement,
    customerManagement,
    expenseTracking,
    profitCalculation,
    reportsAnalytics,
    whatsappOrdering,
    productionTracking,
  ];
}

class BusinessProfile {
  final String name;
  final String whatsappPhone;
  final BusinessType type;
  final Set<String> enabledModules;

  const BusinessProfile({
    required this.name,
    required this.whatsappPhone,
    required this.type,
    required this.enabledModules,
  });
}

class BusinessProfileService {
  BusinessProfileService._();
  static final BusinessProfileService instance = BusinessProfileService._();

  static const _nameKey = 'business_profile_name';
  static const _whatsAppPhoneKey = 'business_profile_whatsapp_phone';
  static const _typeKey = 'business_profile_type';
  static const _modulesKey = 'business_profile_enabled_modules';
  static const _defaultName = 'Akira Bites';

  Set<String> _defaultModulesFor(BusinessType type) {
    switch (type) {
      case BusinessType.foodVendor:
        return {
          BusinessModules.salesManagement,
          BusinessModules.productManagement,
          BusinessModules.customerManagement,
          BusinessModules.expenseTracking,
          BusinessModules.profitCalculation,
          BusinessModules.reportsAnalytics,
          BusinessModules.whatsappOrdering,
          BusinessModules.productionTracking,
        };
      case BusinessType.retailShop:
        return {
          BusinessModules.salesManagement,
          BusinessModules.productManagement,
          BusinessModules.customerManagement,
          BusinessModules.expenseTracking,
          BusinessModules.profitCalculation,
          BusinessModules.reportsAnalytics,
          BusinessModules.whatsappOrdering,
        };
      case BusinessType.salon:
        return {
          BusinessModules.salesManagement,
          BusinessModules.customerManagement,
          BusinessModules.expenseTracking,
          BusinessModules.profitCalculation,
          BusinessModules.reportsAnalytics,
          BusinessModules.whatsappOrdering,
        };
    }
  }

  String labelForType(BusinessType type) {
    switch (type) {
      case BusinessType.foodVendor:
        return 'Food Vendor';
      case BusinessType.retailShop:
        return 'Retail Shop';
      case BusinessType.salon:
        return 'Salon';
    }
  }

  String labelForModule(String module) {
    switch (module) {
      case BusinessModules.salesManagement:
        return 'Sales Management';
      case BusinessModules.productManagement:
        return 'Product Management';
      case BusinessModules.customerManagement:
        return 'Customer Management';
      case BusinessModules.expenseTracking:
        return 'Expense Tracking';
      case BusinessModules.profitCalculation:
        return 'Profit Calculation';
      case BusinessModules.reportsAnalytics:
        return 'Reports & Analytics';
      case BusinessModules.whatsappOrdering:
        return 'WhatsApp Ordering';
      case BusinessModules.productionTracking:
        return 'Production Tracking';
      default:
        return module;
    }
  }

  Future<BusinessProfile> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final typeName = prefs.getString(_typeKey);
    final type = BusinessType.values.firstWhere(
      (value) => value.name == typeName,
      orElse: () => BusinessType.foodVendor,
    );
    final savedModules = prefs.getStringList(_modulesKey) ?? const [];
    final validSavedModules = savedModules
        .where((m) => BusinessModules.all.contains(m))
        .toSet();
    final enabledModules = validSavedModules.isEmpty
        ? _defaultModulesFor(type)
        : validSavedModules;
    return BusinessProfile(
      name: (prefs.getString(_nameKey) ?? _defaultName).trim(),
      whatsappPhone: (prefs.getString(_whatsAppPhoneKey) ?? '').trim(),
      type: type,
      enabledModules: enabledModules,
    );
  }

  Future<void> saveProfile(BusinessProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, profile.name.trim());
    await prefs.setString(_whatsAppPhoneKey, profile.whatsappPhone.trim());
    await prefs.setString(_typeKey, profile.type.name);
    await prefs.setStringList(
      _modulesKey,
      profile.enabledModules.where((m) => BusinessModules.all.contains(m)).toList(),
    );
  }

  Set<String> modulesForType(BusinessType type) => _defaultModulesFor(type);
}
