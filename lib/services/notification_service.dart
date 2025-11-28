import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Initialiser le service de notifications
  Future<void> initialize() async {
    if (_initialized) return;

    // Configuration Android
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Configuration iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Demander la permission sur Android 13+
    await _requestPermission();

    _initialized = true;
    print('✅ Service de notifications initialisé');
  }

  /// Demander la permission de notifications
  Future<bool> _requestPermission() async {
    if (await Permission.notification.isGranted) {
      return true;
    }

    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Callback quand une notification est tapée
  void _onNotificationTapped(NotificationResponse response) {
    print('📱 Notification tapée: ${response.payload}');
    // TODO: Navigation vers l'écran approprié selon le payload
  }

  /// Afficher une notification de téléchargement terminé
  Future<void> showDownloadComplete(String chantTitle) async {
    final androidDetails = AndroidNotificationDetails(
      'downloads',
      'Téléchargements',
      channelDescription: 'Notifications pour les téléchargements de chants',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF6366F1), // Couleur primaire
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      '✅ Téléchargement terminé',
      '"$chantTitle" est maintenant disponible hors ligne',
      details,
      payload: 'download_complete:$chantTitle',
    );

    print('📥 Notification téléchargement: $chantTitle');
  }

  /// Afficher une notification d'erreur de téléchargement
  Future<void> showDownloadError(String chantTitle) async {
    final androidDetails = AndroidNotificationDetails(
      'downloads',
      'Téléchargements',
      channelDescription: 'Notifications pour les téléchargements de chants',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFEF4444), // Rouge
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      '❌ Erreur de téléchargement',
      'Impossible de télécharger "$chantTitle"',
      details,
      payload: 'download_error:$chantTitle',
    );

    print('❌ Notification erreur: $chantTitle');
  }

  /// Afficher une notification de lecture en cours (pour le contrôle média)
  Future<void> showNowPlaying(String chantTitle, String author) async {
    final androidDetails = AndroidNotificationDetails(
      'playback',
      'Lecture en cours',
      channelDescription: 'Contrôles de lecture audio',
      importance: Importance.low,
      priority: Priority.low,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF6366F1),
      ongoing: true, // Ne peut pas être balayée
      showWhen: false,
      playSound: false,
      enableVibration: false,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      0, // ID fixe pour la notification de lecture
      '🎵 $chantTitle',
      author,
      details,
      payload: 'now_playing',
    );
  }

  /// Masquer la notification de lecture
  Future<void> hideNowPlaying() async {
    await _notifications.cancel(0);
  }

  /// Afficher une notification de progression de téléchargement
  Future<void> showDownloadProgress(String chantTitle, int progress, String chantId) async {
    final androidDetails = AndroidNotificationDetails(
      'downloads',
      'Téléchargements',
      channelDescription: 'Notifications pour les téléchargements de chants',
      importance: Importance.low,
      priority: Priority.low,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF6366F1),
      showProgress: true,
      maxProgress: 100,
      progress: progress,
      ongoing: true,
      playSound: false,
      enableVibration: false,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Utiliser l'ID du chant pour avoir une notification unique
    final notificationId = chantId.hashCode.abs() % 100000;
    
    await _notifications.show(
      notificationId,
      '📥 Téléchargement en cours',
      '$chantTitle - $progress%',
      details,
      payload: 'download_progress:$chantTitle',
    );
  }

  /// Masquer la notification de progression de téléchargement
  Future<void> hideDownloadProgress(String chantId) async {
    final notificationId = chantId.hashCode.abs() % 100000;
    await _notifications.cancel(notificationId);
  }

  /// Annuler une notification de progression
  Future<void> cancelDownloadProgress(String chantTitle) async {
    await _notifications.cancel(chantTitle.hashCode);
  }

  /// Annuler toutes les notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
