import 'package:hive/hive.dart';

part 'user_session.g.dart';

/// Modèle Hive pour stocker la session utilisateur
/// Utilisé pour garder l'utilisateur connecté même après fermeture de l'app
@HiveType(typeId: 0)
class UserSession extends HiveObject {
  /// ID de l'utilisateur Supabase
  @HiveField(0)
  String userId;

  /// Email de l'utilisateur
  @HiveField(1)
  String email;

  /// Token d'authentification
  @HiveField(2)
  String? accessToken;

  /// Token de rafraîchissement
  @HiveField(3)
  String? refreshToken;

  /// Date d'expiration du token
  @HiveField(4)
  DateTime? tokenExpiresAt;

  /// Nom complet de l'utilisateur
  @HiveField(5)
  String fullName;

  /// Rôle de l'utilisateur (admin ou user)
  @HiveField(6)
  String role;

  /// URL de la photo de profil
  @HiveField(7)
  String? photoUrl;

  /// Nom de la chorale
  @HiveField(8)
  String? choraleName;

  /// Pupitre de l'utilisateur (soprano, alto, tenor, basse)
  @HiveField(9)
  String? pupitre;

  /// Date de création du compte
  @HiveField(10)
  DateTime createdAt;

  /// Dernière connexion
  @HiveField(11)
  DateTime lastLoginAt;

  UserSession({
    required this.userId,
    required this.email,
    this.accessToken,
    this.refreshToken,
    this.tokenExpiresAt,
    required this.fullName,
    this.role = 'user',
    this.photoUrl,
    this.choraleName,
    this.pupitre,
    required this.createdAt,
    required this.lastLoginAt,
  });

  /// Vérifier si la session est valide
  bool get isValid {
    if (accessToken == null) return false;
    if (tokenExpiresAt == null) return true;
    return DateTime.now().isBefore(tokenExpiresAt!);
  }

  /// Vérifier si l'utilisateur est admin
  bool get isAdmin => role == 'admin';

  /// Copier avec modifications
  UserSession copyWith({
    String? userId,
    String? email,
    String? accessToken,
    String? refreshToken,
    DateTime? tokenExpiresAt,
    String? fullName,
    String? role,
    String? photoUrl,
    String? choraleName,
    String? pupitre,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserSession(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      tokenExpiresAt: tokenExpiresAt ?? this.tokenExpiresAt,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      choraleName: choraleName ?? this.choraleName,
      pupitre: pupitre ?? this.pupitre,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  /// Conversion vers Map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'tokenExpiresAt': tokenExpiresAt?.toIso8601String(),
      'fullName': fullName,
      'role': role,
      'photoUrl': photoUrl,
      'choraleName': choraleName,
      'pupitre': pupitre,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
    };
  }

  /// Conversion depuis Map
  factory UserSession.fromMap(Map<String, dynamic> map) {
    return UserSession(
      userId: map['userId'] as String,
      email: map['email'] as String,
      accessToken: map['accessToken'] as String?,
      refreshToken: map['refreshToken'] as String?,
      tokenExpiresAt: map['tokenExpiresAt'] != null
          ? DateTime.parse(map['tokenExpiresAt'] as String)
          : null,
      fullName: map['fullName'] as String,
      role: map['role'] as String? ?? 'user',
      photoUrl: map['photoUrl'] as String?,
      choraleName: map['choraleName'] as String?,
      pupitre: map['pupitre'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastLoginAt: DateTime.parse(map['lastLoginAt'] as String),
    );
  }
}
