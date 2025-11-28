class Chorale {
  final String id;
  final String nom;
  final String slug;
  final String? description;
  final String? logoUrl;
  final String? couleurTheme;
  final String? emailContact;
  final String? telephone;
  final String? adresse;
  final String? ville;
  final String? pays;
  final String? siteWeb;
  final int nombreMembres;
  final String statut;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Chorale({
    required this.id,
    required this.nom,
    required this.slug,
    this.description,
    this.logoUrl,
    this.couleurTheme,
    this.emailContact,
    this.telephone,
    this.adresse,
    this.ville,
    this.pays,
    this.siteWeb,
    this.nombreMembres = 0,
    this.statut = 'actif',
    required this.createdAt,
    this.updatedAt,
  });

  factory Chorale.fromJson(Map<String, dynamic> json) {
    return Chorale(
      id: json['id'] as String,
      nom: json['nom'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      logoUrl: json['logo_url'] as String?,
      couleurTheme: json['couleur_theme'] as String?,
      emailContact: json['email_contact'] as String?,
      telephone: json['telephone'] as String?,
      adresse: json['adresse'] as String?,
      ville: json['ville'] as String?,
      pays: json['pays'] as String?,
      siteWeb: json['site_web'] as String?,
      nombreMembres: json['nombre_membres'] as int? ?? 0,
      statut: json['statut'] as String? ?? 'actif',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'slug': slug,
      'description': description,
      'logo_url': logoUrl,
      'couleur_theme': couleurTheme,
      'email_contact': emailContact,
      'telephone': telephone,
      'adresse': adresse,
      'ville': ville,
      'pays': pays,
      'site_web': siteWeb,
      'nombre_membres': nombreMembres,
      'statut': statut,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Chorale copyWith({
    String? id,
    String? nom,
    String? slug,
    String? description,
    String? logoUrl,
    String? couleurTheme,
    String? emailContact,
    String? telephone,
    String? adresse,
    String? ville,
    String? pays,
    String? siteWeb,
    int? nombreMembres,
    String? statut,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Chorale(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      couleurTheme: couleurTheme ?? this.couleurTheme,
      emailContact: emailContact ?? this.emailContact,
      telephone: telephone ?? this.telephone,
      adresse: adresse ?? this.adresse,
      ville: ville ?? this.ville,
      pays: pays ?? this.pays,
      siteWeb: siteWeb ?? this.siteWeb,
      nombreMembres: nombreMembres ?? this.nombreMembres,
      statut: statut ?? this.statut,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
