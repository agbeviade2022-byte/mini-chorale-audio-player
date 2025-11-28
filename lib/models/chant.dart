class Chant {
  final String id;
  final String titre;
  final String categorie;
  final String auteur;
  final String urlAudio;
  final int duree; // en secondes
  final DateTime createdAt;
  final String type; // 'normal' ou 'pupitre'
  final String? lyrics;
  final String? partitionUrl;
  final String? choraleId; // ID de la chorale à laquelle appartient le chant

  Chant({
    required this.id,
    required this.titre,
    required this.categorie,
    required this.auteur,
    required this.urlAudio,
    required this.duree,
    required this.createdAt,
    this.type = 'normal',
    this.lyrics,
    this.partitionUrl,
    this.choraleId,
  });

  // Conversion depuis Map (Supabase)
  factory Chant.fromMap(Map<String, dynamic> map) {
    return Chant(
      id: map['id'] as String,
      titre: map['titre'] as String,
      categorie: map['categorie'] as String,
      auteur: map['auteur'] as String,
      urlAudio: map['url_audio'] as String,
      duree: map['duree'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      type: (map['type'] as String?) ?? 'normal',
      lyrics: map['lyrics'] as String?,
      partitionUrl: map['partition_url'] as String?,
      choraleId: map['chorale_id'] as String?,
    );
  }

  // Conversion vers Map (Supabase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titre': titre,
      'categorie': categorie,
      'auteur': auteur,
      'url_audio': urlAudio,
      'duree': duree,
      'created_at': createdAt.toIso8601String(),
      'type': type,
      if (lyrics != null) 'lyrics': lyrics,
      if (partitionUrl != null) 'partition_url': partitionUrl,
      if (choraleId != null) 'chorale_id': choraleId,
    };
  }

  // CopyWith pour modifications
  Chant copyWith({
    String? id,
    String? titre,
    String? categorie,
    String? auteur,
    String? urlAudio,
    int? duree,
    DateTime? createdAt,
    String? type,
    String? lyrics,
    String? partitionUrl,
    String? choraleId,
  }) {
    return Chant(
      id: id ?? this.id,
      titre: titre ?? this.titre,
      categorie: categorie ?? this.categorie,
      auteur: auteur ?? this.auteur,
      urlAudio: urlAudio ?? this.urlAudio,
      duree: duree ?? this.duree,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      lyrics: lyrics ?? this.lyrics,
      partitionUrl: partitionUrl ?? this.partitionUrl,
      choraleId: choraleId ?? this.choraleId,
    );
  }

  // Formater la durée en MM:SS
  String get dureeFormatee {
    final minutes = duree ~/ 60;
    final secondes = duree % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secondes.toString().padLeft(2, '0')}';
  }
}
