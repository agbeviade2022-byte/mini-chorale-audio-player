// Modèle pour le futur module d'abonnement
class Subscription {
  final String id;
  final String choraleName;
  final String adminId;
  final String plan; // 'basic', 'premium', etc.
  final DateTime activeUntil;
  final String status; // 'active', 'expired', 'cancelled'
  final DateTime createdAt;

  Subscription({
    required this.id,
    required this.choraleName,
    required this.adminId,
    required this.plan,
    required this.activeUntil,
    required this.status,
    required this.createdAt,
  });

  // Conversion depuis Map (Supabase)
  factory Subscription.fromMap(Map<String, dynamic> map) {
    return Subscription(
      id: map['id'] as String,
      choraleName: map['chorale_name'] as String,
      adminId: map['admin_id'] as String,
      plan: map['plan'] as String,
      activeUntil: DateTime.parse(map['active_until'] as String),
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // Conversion vers Map (Supabase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chorale_name': choraleName,
      'admin_id': adminId,
      'plan': plan,
      'active_until': activeUntil.toIso8601String(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Vérifier si l'abonnement est actif
  bool get isActive =>
      status == 'active' && activeUntil.isAfter(DateTime.now());

  // CopyWith pour modifications
  Subscription copyWith({
    String? id,
    String? choraleName,
    String? adminId,
    String? plan,
    DateTime? activeUntil,
    String? status,
    DateTime? createdAt,
  }) {
    return Subscription(
      id: id ?? this.id,
      choraleName: choraleName ?? this.choraleName,
      adminId: adminId ?? this.adminId,
      plan: plan ?? this.plan,
      activeUntil: activeUntil ?? this.activeUntil,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
