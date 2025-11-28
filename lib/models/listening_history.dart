class ListeningHistory {
  final String id;
  final String userId;
  final String chantId;
  final DateTime timestamp;
  final int durationListened; // En secondes
  final bool completed; // A écouté jusqu'à la fin

  ListeningHistory({
    required this.id,
    required this.userId,
    required this.chantId,
    required this.timestamp,
    required this.durationListened,
    this.completed = false,
  });

  // Conversion depuis Map (Supabase)
  factory ListeningHistory.fromMap(Map<String, dynamic> map) {
    return ListeningHistory(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      chantId: map['chant_id'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      durationListened: map['duration_listened'] as int,
      completed: map['completed'] as bool? ?? false,
    );
  }

  // Conversion vers Map (Supabase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'chant_id': chantId,
      'timestamp': timestamp.toIso8601String(),
      'duration_listened': durationListened,
      'completed': completed,
    };
  }

  // Copie avec modifications
  ListeningHistory copyWith({
    String? id,
    String? userId,
    String? chantId,
    DateTime? timestamp,
    int? durationListened,
    bool? completed,
  }) {
    return ListeningHistory(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      chantId: chantId ?? this.chantId,
      timestamp: timestamp ?? this.timestamp,
      durationListened: durationListened ?? this.durationListened,
      completed: completed ?? this.completed,
    );
  }
}

// Statistiques d'écoute
class ListeningStats {
  final int totalListens;
  final int totalDuration; // En secondes
  final int uniqueChants;
  final Map<String, int> topChants; // chantId -> nombre d'écoutes
  final DateTime? lastListened;

  ListeningStats({
    required this.totalListens,
    required this.totalDuration,
    required this.uniqueChants,
    required this.topChants,
    this.lastListened,
  });
}
