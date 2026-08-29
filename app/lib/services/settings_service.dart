import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _tmdbKeyPref = 'tmdb_api_key';

  Future<String?> getTmdbApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tmdbKeyPref);
  }

  Future<void> setTmdbApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    if (key.trim().isEmpty) {
      await prefs.remove(_tmdbKeyPref);
    } else {
      await prefs.setString(_tmdbKeyPref, key.trim());
    }
  }
}
