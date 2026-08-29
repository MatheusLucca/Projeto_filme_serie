import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _tmdbKeyPref = 'tmdb_api_key';

  /// Returns the key saved by the user in Settings, falling back to the
  /// TMDB_API_KEY defined in the local (untracked) .env file, if present.
  Future<String?> getTmdbApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_tmdbKeyPref);
    if (saved != null && saved.isNotEmpty) return saved;
    if (!dotenv.isInitialized) return null;
    final fromEnv = dotenv.env['TMDB_API_KEY'];
    return (fromEnv != null && fromEnv.isNotEmpty) ? fromEnv : null;
  }

  /// The key actually saved by the user (ignores the .env fallback) — used
  /// so the Settings screen doesn't show the .env default as if the user
  /// had typed it.
  Future<String?> getSavedTmdbApiKey() async {
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
