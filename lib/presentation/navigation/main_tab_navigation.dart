import 'package:flutter/foundation.dart';

class MainTabNavigation {
  MainTabNavigation._();

  static final ValueNotifier<int> selectedIndex = ValueNotifier<int>(0);

  static void goTo(int index) {
    if (selectedIndex.value == index) return;
    selectedIndex.value = index;
  }
}
