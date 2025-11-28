import 'package:supabase_flutter/supabase_flutter.dart';

/// Service de monitoring de sécurité
/// Gère les alertes et le suivi des activités suspectes
class SecurityMonitoringService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Obtenir les alertes de sécurité
  /// 
  /// Paramètres:
  /// - limit: Nombre d'alertes à récupérer (défaut: 50)
  /// - severity: Filtrer par gravité (low, medium, high, critical)
  /// - resolved: Filtrer par statut (true = résolues, false = non résolues, null = toutes)
  Future<List<Map<String, dynamic>>> getSecurityAlerts({
    int limit = 50,
    String? severity,
    bool? resolved,
  }) async {
    try {
      print('🔍 Récupération des alertes de sécurité...');

      final response = await _supabase.rpc('get_security_alerts', params: {
        'p_limit': limit,
        'p_severity': severity,
        'p_resolved': resolved,
      });

      if (response == null) {
        return [];
      }

      final alerts = List<Map<String, dynamic>>.from(response);
      print('✅ ${alerts.length} alertes récupérées');

      return alerts;
    } catch (e) {
      print('❌ Erreur getSecurityAlerts: $e');
      return [];
    }
  }

  /// Résoudre une alerte de sécurité
  /// 
  /// Paramètres:
  /// - alertId: ID de l'alerte à résoudre
  /// - adminId: ID de l'admin qui résout l'alerte
  Future<Map<String, dynamic>> resolveAlert({
    required String alertId,
    required String adminId,
  }) async {
    try {
      print('✅ Résolution de l\'alerte: $alertId');

      final response = await _supabase.rpc('resolve_security_alert', params: {
        'p_alert_id': alertId,
        'p_admin_id': adminId,
      });

      if (response == null) {
        return {
          'success': false,
          'error': 'server_error',
          'message': 'Erreur serveur',
        };
      }

      return response as Map<String, dynamic>;
    } catch (e) {
      print('❌ Erreur resolveAlert: $e');
      return {
        'success': false,
        'error': 'exception',
        'message': 'Erreur: ${e.toString()}',
      };
    }
  }

  /// Obtenir les statistiques de sécurité
  Future<Map<String, dynamic>> getSecurityStats() async {
    try {
      print('📊 Récupération des statistiques de sécurité...');

      // Alertes par gravité
      final alertsBySeverity = await _supabase
          .from('security_alerts')
          .select('severity')
          .gte('created_at', DateTime.now().subtract(const Duration(days: 7)).toIso8601String());

      // Alertes non résolues
      final unresolvedAlerts = await _supabase
          .from('security_alerts')
          .select('id')
          .is_('resolved_at', null);

      // Alertes critiques
      final criticalAlerts = await _supabase
          .from('security_alerts')
          .select('id')
          .eq('severity', 'critical')
          .is_('resolved_at', null);

      // Compter par gravité
      final severityCounts = <String, int>{
        'low': 0,
        'medium': 0,
        'high': 0,
        'critical': 0,
      };

      for (var alert in alertsBySeverity) {
        final severity = alert['severity'] as String;
        severityCounts[severity] = (severityCounts[severity] ?? 0) + 1;
      }

      return {
        'total_last_7_days': alertsBySeverity.length,
        'unresolved': unresolvedAlerts.length,
        'critical_unresolved': criticalAlerts.length,
        'by_severity': severityCounts,
      };
    } catch (e) {
      print('❌ Erreur getSecurityStats: $e');
      return {
        'total_last_7_days': 0,
        'unresolved': 0,
        'critical_unresolved': 0,
        'by_severity': {},
      };
    }
  }

  /// Obtenir les tentatives de connexion suspectes
  Future<List<Map<String, dynamic>>> getSuspiciousLogins({
    int limit = 20,
  }) async {
    try {
      final response = await _supabase
          .from('security_alerts')
          .select()
          .in_('alert_type', [
            'rate_limit_exceeded',
            'otp_brute_force_attempt',
            'login_attempt_invalid_email',
          ])
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Erreur getSuspiciousLogins: $e');
      return [];
    }
  }

  /// Obtenir les activités récentes d'un utilisateur
  Future<List<Map<String, dynamic>>> getUserActivity({
    required String email,
    int limit = 10,
  }) async {
    try {
      final response = await _supabase
          .from('security_alerts')
          .select()
          .eq('email', email)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Erreur getUserActivity: $e');
      return [];
    }
  }

  /// Stream des alertes en temps réel
  Stream<List<Map<String, dynamic>>> watchSecurityAlerts({
    String? severity,
  }) {
    try {
      var query = _supabase
          .from('security_alerts')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false);

      return query.map((data) {
        final alerts = List<Map<String, dynamic>>.from(data);
        if (severity != null) {
          return alerts.where((a) => a['severity'] == severity).toList();
        }
        return alerts;
      });
    } catch (e) {
      print('❌ Erreur watchSecurityAlerts: $e');
      return Stream.value([]);
    }
  }

  /// Obtenir le badge de gravité (couleur)
  String getSeverityColor(String severity) {
    switch (severity) {
      case 'low':
        return '#4CAF50'; // Vert
      case 'medium':
        return '#FF9800'; // Orange
      case 'high':
        return '#F44336'; // Rouge
      case 'critical':
        return '#9C27B0'; // Violet
      default:
        return '#9E9E9E'; // Gris
    }
  }

  /// Obtenir l'icône de gravité
  String getSeverityIcon(String severity) {
    switch (severity) {
      case 'low':
        return '✅';
      case 'medium':
        return '⚠️';
      case 'high':
        return '🚨';
      case 'critical':
        return '🔴';
      default:
        return 'ℹ️';
    }
  }

  /// Obtenir le label de gravité
  String getSeverityLabel(String severity) {
    switch (severity) {
      case 'low':
        return 'Faible';
      case 'medium':
        return 'Moyen';
      case 'high':
        return 'Élevé';
      case 'critical':
        return 'Critique';
      default:
        return 'Inconnu';
    }
  }

  /// Obtenir le label du type d'alerte
  String getAlertTypeLabel(String alertType) {
    switch (alertType) {
      case 'rate_limit_exceeded':
        return 'Limite de tentatives dépassée';
      case 'rate_limit_blocked':
        return 'Compte temporairement bloqué';
      case 'otp_brute_force_attempt':
        return 'Tentative de force brute';
      case 'login_attempt_invalid_email':
        return 'Tentative avec email invalide';
      case 'otp_generated':
        return 'Code OTP généré';
      case 'login_success':
        return 'Connexion réussie';
      case 'cleanup_executed':
        return 'Nettoyage automatique';
      default:
        return alertType;
    }
  }

  /// Vérifier si une alerte nécessite une action immédiate
  bool requiresImmediateAction(Map<String, dynamic> alert) {
    final severity = alert['severity'] as String;
    final resolved = alert['resolved_at'] != null;

    return (severity == 'critical' || severity == 'high') && !resolved;
  }

  /// Formater la date de l'alerte
  String formatAlertDate(String? dateStr) {
    if (dateStr == null) return 'N/A';

    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) {
        return 'À l\'instant';
      } else if (diff.inMinutes < 60) {
        return 'Il y a ${diff.inMinutes} min';
      } else if (diff.inHours < 24) {
        return 'Il y a ${diff.inHours}h';
      } else if (diff.inDays < 7) {
        return 'Il y a ${diff.inDays}j';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateStr;
    }
  }
}
