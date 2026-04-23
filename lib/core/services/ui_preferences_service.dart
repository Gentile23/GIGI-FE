import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UiPreferencesService extends ChangeNotifier {
  static const _proBottomBarAccentKey = 'pro_bottom_bar_accent_enabled';

  bool _isLoaded = false;
  bool _proBottomBarAccentEnabled = true;

  bool get isLoaded => _isLoaded;
  bool get proBottomBarAccentEnabled => _proBottomBarAccentEnabled;

  UiPreferencesService() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _proBottomBarAccentEnabled =
          prefs.getBool(_proBottomBarAccentKey) ?? true;
    } catch (e) {
      debugPrint('Error loading UI preferences: $e');
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> setProBottomBarAccentEnabled(bool value) async {
    if (_proBottomBarAccentEnabled == value && _isLoaded) return;

    _proBottomBarAccentEnabled = value;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_proBottomBarAccentKey, value);
    } catch (e) {
      debugPrint('Error saving UI preferences: $e');
    }
  }
}
