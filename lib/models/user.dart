class AppUser {
  final String id;
  final String userId;
  final String fullName;
  final String role; // 'super_admin', 'admin', 'membre', ou 'user'
  final DateTime createdAt;
  final String? email;

  AppUser({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.role,
    required this.createdAt,
    this.email,
  });

  // Conversion depuis Map (Supabase)
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: (map['id'] ?? '') as String,
      userId: (map['user_id'] ?? '') as String,
      fullName: (map['full_name'] ?? 'Utilisateur') as String,
      role: (map['role'] ?? 'user') as String,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      email: map['email'] as String?,
    );
  }

  // Conversion vers Map (Supabase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'full_name': fullName,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      if (email != null) 'email': email,
    };
  }

  // Vérifier si l'utilisateur est admin (admin ou super_admin)
  bool get isAdmin => role == 'admin' || role == 'super_admin';
  
  // Vérifier si l'utilisateur est super admin
  bool get isSuperAdmin => role == 'super_admin';
  
  // Vérifier si l'utilisateur est membre
  bool get isMembre => role == 'membre';
  
  // Vérifier si l'utilisateur est un utilisateur basique
  bool get isUser => role == 'user';

  // CopyWith pour modifications
  AppUser copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? role,
    DateTime? createdAt,
    String? email,
  }) {
    return AppUser(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      email: email ?? this.email,
    );
  }
}
