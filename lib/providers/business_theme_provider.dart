import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/business_theme.dart';
import 'auth_provider.dart';

final businessThemePaletteProvider = Provider<BusinessThemePalette>((ref) {
  final typeId = ref.watch(authProvider).user?.businessType;
  return BusinessThemePalette.forType(typeId);
});

final businessThemeProvider = Provider<ThemeData>((ref) {
  return ref.watch(businessThemePaletteProvider).toThemeData();
});
