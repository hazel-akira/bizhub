import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Increment to ask [MainNavScreen] to start the in-app coach tour again.
final coachTourReplayTickProvider = StateProvider<int>((ref) => 0);

/// Increment to ask navigation hosts to open the swipe intro again.
final introReplayTickProvider = StateProvider<int>((ref) => 0);
