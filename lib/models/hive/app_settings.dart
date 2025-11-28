import 'package:hive/hive.dart';

part 'app_settings.g.dart';

/// Modèle Hive pour stocker les paramètres de l'application
@HiveType(typeId: 1)
class AppSettings extends HiveObject {
  /// Thème de l'application (light, dark, system)
  @HiveField(0)
  String theme;

  /// Pupitre sélectionné par défaut
  @HiveField(1)
  String? defaultPupitre;

  /// Volume par défaut (0.0 à 1.0)
  @HiveField(2)
  double volume;

  /// Activer le mode hors ligne
  @HiveField(3)
  bool offlineMode;

  /// Téléchargement automatique des favoris
  @HiveField(4)
  bool autoDownloadFavorites;

  /// Qualité audio (low, medium, high)
  @HiveField(5)
  String audioQuality;

  /// Activer les notifications
  @HiveField(6)
  bool notificationsEnabled;

  /// Langue de l'application
  @HiveField(7)
  String language;

  /// Dernière mise à jour des paramètres
  @HiveField(8)
  DateTime lastUpdated;

  AppSettings({
    this.theme = 'system',
    this.defaultPupitre,
    this.volume = 0.8,
    this.offlineMode = false,
    this.autoDownloadFavorites = false,
    this.audioQuality = 'high',
    this.notificationsEnabled = true,
    this.language = 'fr',
    required this.lastUpdated,
  });

  /// Paramètres par défaut
  factory AppSettings.defaults() {
    return AppSettings(
      theme: 'system',
      volume: 0.8,
      offlineMode: false,
      autoDownloadFavorites: false,
      audioQuality: 'high',
      notificationsEnabled: true,
      language: 'fr',
      lastUpdated: DateTime.now(),
    );
  }

  /// Copier avec modifications
  AppSettings copyWith({
    String? theme,
    String? defaultPupitre,
    double? volume,
    bool? offlineMode,
    bool? autoDownloadFavorites,
    String? audioQuality,
    bool? notificationsEnabled,
    String? language,
    DateTime? lastUpdated,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      defaultPupitre: defaultPupitre ?? this.defaultPupitre,
      volume: volume ?? this.volume,
      offlineMode: offlineMode ?? this.offlineMode,
      autoDownloadFavorites: autoDownloadFavorites ?? this.autoDownloadFavorites,
      audioQuality: audioQuality ?? this.audioQuality,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      language: language ?? this.language,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Conversion vers Map
  Map<String, dynamic> toMap() {
    return {
      'theme': theme,
      'defaultPupitre': defaultPupitre,
      'volume': volume,
      'offlineMode': offlineMode,
      'autoDownloadFavorites': autoDownloadFavorites,
      'audioQuality': audioQuality,
      'notificationsEnabled': notificationsEnabled,
      'language': language,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// Conversion depuis Map
  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      theme: map['theme'] as String? ?? 'system',
      defaultPupitre: map['defaultPupitre'] as String?,
      volume: (map['volume'] as num?)?.toDouble() ?? 0.8,
      offlineMode: map['offlineMode'] as bool? ?? false,
      autoDownloadFavorites: map['autoDownloadFavorites'] as bool? ?? false,
      audioQuality: map['audioQuality'] as String? ?? 'high',
      notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
      language: map['language'] as String? ?? 'fr',
      lastUpdated: DateTime.parse(map['lastUpdated'] as String),
    );
  }
}
