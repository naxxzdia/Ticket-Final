import 'package:shared_preferences/shared_preferences.dart';

class ProfilePrefs {
  static const _keyLocation = 'profile_location';
  ProfilePrefs._();
  static final instance = ProfilePrefs._();

  Future<void> setLocation(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null || value.trim().isEmpty) {
      await prefs.remove(_keyLocation);
    } else {
      await prefs.setString(_keyLocation, value.trim());
    }
  }

  Future<String?> getLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_keyLocation);
    if (v == null || v.trim().isEmpty) return null;
    return v;
  }
}
