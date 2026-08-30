import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/title_item.dart';
import 'settings_service.dart';

class TmdbResult {
  final int id;
  final String title;
  final TitleType type;
  final String? posterPath;
  final String? overview;
  final String? year;

  TmdbResult({
    required this.id,
    required this.title,
    required this.type,
    this.posterPath,
    this.overview,
    this.year,
  });
}

class TmdbSeason {
  final int seasonNumber;
  final String name;
  final int episodeCount;

  TmdbSeason({
    required this.seasonNumber,
    required this.name,
    required this.episodeCount,
  });
}

class TmdbException implements Exception {
  final String message;
  TmdbException(this.message);

  @override
  String toString() => message;
}

class TmdbService {
  static const _baseUrl = 'https://api.themoviedb.org/3';
  static const _imageBaseUrl = 'https://image.tmdb.org/t/p/w342';

  static final Map<String, String?> _episodeNameCache = {};

  final SettingsService _settings = SettingsService();

  Future<List<TmdbResult>> search(String query) async {
    final apiKey = await _settings.getTmdbApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw TmdbException(
        'Configure sua chave da API do TMDB em Configurações para usar a busca automática.',
      );
    }
    if (query.trim().isEmpty) return [];

    final uri = Uri.parse('$_baseUrl/search/multi').replace(queryParameters: {
      'api_key': apiKey,
      'query': query.trim(),
      'language': 'pt-BR',
      'include_adult': 'false',
    });

    final response = await http.get(uri);
    if (response.statusCode == 401) {
      throw TmdbException('Chave de API do TMDB inválida.');
    }
    if (response.statusCode != 200) {
      throw TmdbException('Erro ao consultar o TMDB (${response.statusCode}).');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = (data['results'] as List<dynamic>? ?? []);

    return results
        .where((r) => r['media_type'] == 'movie' || r['media_type'] == 'tv')
        .map((r) {
      final isMovie = r['media_type'] == 'movie';
      final title = (isMovie ? r['title'] : r['name']) as String? ?? 'Sem título';
      final dateStr = (isMovie ? r['release_date'] : r['first_air_date']) as String?;
      return TmdbResult(
        id: r['id'] as int,
        title: title,
        type: isMovie ? TitleType.filme : TitleType.serie,
        posterPath: r['poster_path'] as String?,
        overview: r['overview'] as String?,
        year: (dateStr != null && dateStr.length >= 4) ? dateStr.substring(0, 4) : null,
      );
    }).toList();
  }

  /// Fetches the total episode count for a TV show (all seasons combined).
  /// Returns null on failure or when the result is a movie.
  Future<int?> fetchTotalEpisodes(TmdbResult result) async {
    if (result.type != TitleType.serie) return null;
    final apiKey = await _settings.getTmdbApiKey();
    if (apiKey == null || apiKey.isEmpty) return null;

    try {
      final uri = Uri.parse('$_baseUrl/tv/${result.id}').replace(queryParameters: {
        'api_key': apiKey,
        'language': 'pt-BR',
      });
      final response = await http.get(uri);
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['number_of_episodes'] as int?;
    } catch (_) {
      return null;
    }
  }

  /// Fetches the list of seasons (with episode counts) for a TV show.
  /// Excludes "season 0" (specials). Returns an empty list on failure.
  Future<List<TmdbSeason>> fetchSeasons(TmdbResult result) async {
    if (result.type != TitleType.serie) return [];
    final apiKey = await _settings.getTmdbApiKey();
    if (apiKey == null || apiKey.isEmpty) return [];

    try {
      final uri = Uri.parse('$_baseUrl/tv/${result.id}').replace(queryParameters: {
        'api_key': apiKey,
        'language': 'pt-BR',
      });
      final response = await http.get(uri);
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final seasons = (data['seasons'] as List<dynamic>? ?? []);
      return seasons
          .map((s) => TmdbSeason(
                seasonNumber: s['season_number'] as int? ?? 0,
                name: s['name'] as String? ?? 'Temporada',
                episodeCount: s['episode_count'] as int? ?? 0,
              ))
          .where((s) => s.seasonNumber > 0 && s.episodeCount > 0)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Fetches the episode name/title for a given TV show, season and episode
  /// number. Returns null on failure or when there's no TMDB id.
  Future<String?> fetchEpisodeName(int tmdbId, int season, int episode) async {
    final cacheKey = '$tmdbId-$season-$episode';
    if (_episodeNameCache.containsKey(cacheKey)) {
      return _episodeNameCache[cacheKey];
    }

    final apiKey = await _settings.getTmdbApiKey();
    if (apiKey == null || apiKey.isEmpty) return null;

    try {
      final uri = Uri.parse('$_baseUrl/tv/$tmdbId/season/$season/episode/$episode')
          .replace(queryParameters: {
        'api_key': apiKey,
        'language': 'pt-BR',
      });
      final response = await http.get(uri);
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final name = data['name'] as String?;
      _episodeNameCache[cacheKey] = name;
      return name;
    } catch (_) {
      return null;
    }
  }

  /// Downloads the poster image to local app storage and returns the file path.
  Future<String?> downloadPoster(String posterPath) async {
    try {
      final uri = Uri.parse('$_imageBaseUrl$posterPath');
      final response = await http.get(uri);
      if (response.statusCode != 200) return null;

      final appDir = await getApplicationDocumentsDirectory();
      final postersDir = Directory(p.join(appDir.path, 'posters'));
      if (!await postersDir.exists()) {
        await postersDir.create(recursive: true);
      }
      final filePath = p.join(postersDir.path, '${const Uuid().v4()}.jpg');
      await File(filePath).writeAsBytes(response.bodyBytes);
      return filePath;
    } catch (_) {
      return null;
    }
  }
}
