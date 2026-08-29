enum TitleType { filme, serie, anime, desenho }

enum WatchStatus { queroVer, assistindo, visto }

extension TitleTypeLabel on TitleType {
  String get label {
    switch (this) {
      case TitleType.filme:
        return 'Filme';
      case TitleType.serie:
        return 'Série';
      case TitleType.anime:
        return 'Anime';
      case TitleType.desenho:
        return 'Desenho';
    }
  }
}

extension WatchStatusLabel on WatchStatus {
  String get label {
    switch (this) {
      case WatchStatus.queroVer:
        return 'Quero ver';
      case WatchStatus.assistindo:
        return 'Assistindo';
      case WatchStatus.visto:
        return 'Visto';
    }
  }
}

class TitleItem {
  final int? id;
  final String name;
  final TitleType type;
  final WatchStatus status;
  final String? posterPath;
  final int season;
  final int episode;
  final int? totalEpisodes;
  final int? rating;
  final String? notes;
  final String? overview;
  final DateTime createdAt;
  final DateTime updatedAt;

  TitleItem({
    this.id,
    required this.name,
    required this.type,
    this.status = WatchStatus.queroVer,
    this.posterPath,
    this.season = 1,
    this.episode = 1,
    this.totalEpisodes,
    this.rating,
    this.notes,
    this.overview,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  TitleItem copyWith({
    int? id,
    String? name,
    TitleType? type,
    WatchStatus? status,
    String? posterPath,
    int? season,
    int? episode,
    int? totalEpisodes,
    int? rating,
    String? notes,
    String? overview,
    DateTime? updatedAt,
  }) {
    return TitleItem(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      status: status ?? this.status,
      posterPath: posterPath ?? this.posterPath,
      season: season ?? this.season,
      episode: episode ?? this.episode,
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      rating: rating ?? this.rating,
      notes: notes ?? this.notes,
      overview: overview ?? this.overview,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'status': status.name,
      'poster_path': posterPath,
      'season': season,
      'episode': episode,
      'total_episodes': totalEpisodes,
      'rating': rating,
      'notes': notes,
      'overview': overview,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory TitleItem.fromMap(Map<String, Object?> map) {
    return TitleItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: TitleType.values.byName(map['type'] as String),
      status: WatchStatus.values.byName(map['status'] as String),
      posterPath: map['poster_path'] as String?,
      season: map['season'] as int? ?? 1,
      episode: map['episode'] as int? ?? 1,
      totalEpisodes: map['total_episodes'] as int?,
      rating: map['rating'] as int?,
      notes: map['notes'] as String?,
      overview: map['overview'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
