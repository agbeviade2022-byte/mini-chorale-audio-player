class Category {
  final String id;
  final String nom;
  final DateTime createdAt;

  Category({
    required this.id,
    required this.nom,
    required this.createdAt,
  });

  // Conversion depuis Map (Supabase)
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      nom: map['nom'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // Conversion vers Map (Supabase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // CopyWith pour modifications
  Category copyWith({
    String? id,
    String? nom,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Catégories par défaut
  static List<String> get defaultCategories => [
        'Répétition',
        'Messe',
        'Adoration',
        'Noël',
        'Pâques',
      ];
}
