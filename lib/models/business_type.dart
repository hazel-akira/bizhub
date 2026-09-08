class BusinessTypeOption {
  const BusinessTypeOption({
    required this.id,
    required this.label,
    required this.description,
    this.group = 'Other',
    this.emoji = '🏷️',
  });

  final String id;
  final String label;
  final String description;
  final String group;
  final String emoji;

  String get displayLabel => _displayLabels[id] ?? label;

  String get displayEmoji => _emojis[id] ?? emoji;

  static List<BusinessTypeOption> sorted(List<BusinessTypeOption> types) {
    const order = [
      'mama_mboga',
      'butchery',
      'dairy_shop',
      'poultry_shop',
      'grocery_shop',
      'wholesale',
      'liquor_store',
      'gas_water',
      'boutique',
      'beauty_shop',
      'shoe_store',
      'salon',
      'cybercafe',
      'agrovet',
      'hardware_store',
      'food_vendor',
      'small_restaurant',
      'pharmacy',
      'electronics_shop',
    ];
    final copy = [...types];
    copy.sort((a, b) {
      final ai = order.indexOf(a.id);
      final bi = order.indexOf(b.id);
      return (ai == -1 ? 999 : ai).compareTo(bi == -1 ? 999 : bi);
    });
    return copy;
  }

  factory BusinessTypeOption.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    return BusinessTypeOption(
      id: id,
      label: json['label'] as String,
      description: json['description'] as String? ?? '',
      group: json['group'] as String? ?? 'Other',
      emoji: json['emoji'] as String? ?? _emojis[id] ?? '🏷️',
    );
  }

  bool get isFoodBusiness =>
      id == 'food_vendor' || id == 'small_restaurant';

  static const _emojis = <String, String>{
    'mama_mboga': '🥦',
    'butchery': '🥩',
    'dairy_shop': '🥛',
    'poultry_shop': '🥚',
    'grocery_shop': '🏪',
    'wholesale': '🛍️',
    'liquor_store': '🍷',
    'gas_water': '⛽',
    'boutique': '👗',
    'beauty_shop': '💄',
    'shoe_store': '👟',
    'salon': '💇',
    'cybercafe': '🖨️',
    'agrovet': '🌾',
    'hardware_store': '⚒️',
    'food_vendor': '🍽️',
    'small_restaurant': '🍛',
    'pharmacy': '💊',
    'electronics_shop': '📱',
  };

  static const _displayLabels = <String, String>{
    'mama_mboga': 'Fresh Foods (Mama Mboga)',
    'butchery': 'Butchery',
    'dairy_shop': 'Milk Bar / Dairy',
    'poultry_shop': 'Poultry & Egg Supply',
    'grocery_shop': 'General Retail Kiosk',
    'wholesale': 'Wholesale Store',
    'liquor_store': 'Wines & Spirits',
    'gas_water': 'Gas & Water Refill',
    'boutique': 'Clothing Boutique',
    'beauty_shop': 'Cosmetics Shop',
    'shoe_store': 'Shoe Store',
    'salon': 'Salon / Kinyozi',
    'cybercafe': 'Cyber Cafe',
    'agrovet': 'Agrovets',
    'hardware_store': 'Hardware Store',
  };
}
