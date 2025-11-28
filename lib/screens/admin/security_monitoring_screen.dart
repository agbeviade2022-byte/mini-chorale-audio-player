import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_chorale_audio_player/services/security_monitoring_service.dart';
import 'package:mini_chorale_audio_player/services/otp_auth_service.dart';

/// Écran de monitoring de sécurité
/// Accessible uniquement aux Super Admin
class SecurityMonitoringScreen extends ConsumerStatefulWidget {
  const SecurityMonitoringScreen({super.key});

  @override
  ConsumerState<SecurityMonitoringScreen> createState() =>
      _SecurityMonitoringScreenState();
}

class _SecurityMonitoringScreenState
    extends ConsumerState<SecurityMonitoringScreen> {
  final _monitoringService = SecurityMonitoringService();
  final _otpService = OtpAuthService();

  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = true;
  String? _selectedSeverity;
  bool? _showResolved;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stats = await _monitoringService.getSecurityStats();
      final alerts = await _monitoringService.getSecurityAlerts(
        limit: 50,
        severity: _selectedSeverity,
        resolved: _showResolved,
      );

      setState(() {
        _stats = stats;
        _alerts = alerts;
      });
    } catch (e) {
      print('❌ Erreur chargement données: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resolveAlert(String alertId) async {
    final currentUser = _otpService.getCurrentUser();
    if (currentUser == null) return;

    final result = await _monitoringService.resolveAlert(
      alertId: alertId,
      adminId: currentUser.id,
    );

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alerte résolue'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Erreur'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoring de Sécurité'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Statistiques
                  _buildStatsSection(),
                  const SizedBox(height: 24),

                  // Filtres
                  _buildFiltersSection(),
                  const SizedBox(height: 16),

                  // Liste des alertes
                  _buildAlertsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsSection() {
    final totalLast7Days = _stats['total_last_7_days'] ?? 0;
    final unresolved = _stats['unresolved'] ?? 0;
    final criticalUnresolved = _stats['critical_unresolved'] ?? 0;
    final bySeverity = _stats['by_severity'] as Map<String, dynamic>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistiques (7 derniers jours)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Cartes de stats
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total',
                totalLast7Days.toString(),
                Icons.analytics,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Non résolues',
                unresolved.toString(),
                Icons.warning_amber,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Critiques',
                criticalUnresolved.toString(),
                Icons.error,
                Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Élevées',
                (bySeverity['high'] ?? 0).toString(),
                Icons.priority_high,
                Colors.deepOrange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtres',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Filtre gravité
            DropdownButtonFormField<String?>(
              value: _selectedSeverity,
              decoration: const InputDecoration(
                labelText: 'Gravité',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Toutes')),
                DropdownMenuItem(value: 'low', child: Text('✅ Faible')),
                DropdownMenuItem(value: 'medium', child: Text('⚠️ Moyen')),
                DropdownMenuItem(value: 'high', child: Text('🚨 Élevé')),
                DropdownMenuItem(value: 'critical', child: Text('🔴 Critique')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedSeverity = value;
                });
                _loadData();
              },
            ),
            const SizedBox(height: 12),

            // Filtre statut
            DropdownButtonFormField<bool?>(
              value: _showResolved,
              decoration: const InputDecoration(
                labelText: 'Statut',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Toutes')),
                DropdownMenuItem(value: false, child: Text('Non résolues')),
                DropdownMenuItem(value: true, child: Text('Résolues')),
              ],
              onChanged: (value) {
                setState(() {
                  _showResolved = value;
                });
                _loadData();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsSection() {
    if (_alerts.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.green),
                SizedBox(height: 16),
                Text(
                  'Aucune alerte',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Tout va bien ! 🎉',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alertes (${_alerts.length})',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        ..._ alerts.map((alert) => _buildAlertCard(alert)),
      ],
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final severity = alert['severity'] as String;
    final alertType = alert['alert_type'] as String;
    final email = alert['email'] as String?;
    final createdAt = alert['created_at'] as String?;
    final resolvedAt = alert['resolved_at'] as String?;
    final details = alert['details'] as Map<String, dynamic>?;

    final isResolved = resolvedAt != null;
    final requiresAction = _monitoringService.requiresImmediateAction(alert);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isResolved ? Colors.grey[100] : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                // Badge gravité
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Color(int.parse(
                      _monitoringService.getSeverityColor(severity).substring(1),
                      radix: 16,
                    ) + 0xFF000000),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${_monitoringService.getSeverityIcon(severity)} ${_monitoringService.getSeverityLabel(severity)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Badge action requise
                if (requiresAction)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '⚡ Action requise',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                const Spacer(),

                // Date
                Text(
                  _monitoringService.formatAlertDate(createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Type d'alerte
            Text(
              _monitoringService.getAlertTypeLabel(alertType),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Email
            if (email != null) ...[
              Row(
                children: [
                  Icon(Icons.email, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    email,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Détails
            if (details != null && details.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  details.toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Actions
            if (!isResolved) ...[
              ElevatedButton.icon(
                onPressed: () => _resolveAlert(alert['id']),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Résoudre'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
                  const SizedBox(width: 4),
                  Text(
                    'Résolue ${_monitoringService.formatAlertDate(resolvedAt)}',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
