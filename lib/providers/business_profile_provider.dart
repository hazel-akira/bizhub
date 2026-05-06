import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/business_profile_service.dart';

final businessProfileProvider = FutureProvider<BusinessProfile>((ref) async {
  return BusinessProfileService.instance.getProfile();
});
