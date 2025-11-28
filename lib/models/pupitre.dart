class Pupitre {
  static const String tenor = 'Ténor';
  static const String basse = 'Basse';
  static const String soprano = 'Soprano';
  static const String alto = 'Alto';

  static const List<String> all = [
    tenor,
    basse,
    soprano,
    alto,
  ];

  // Obtenir la couleur associée au pupitre
  static int getColorForPupitre(String pupitre) {
    switch (pupitre) {
      case tenor:
        return 0xFFFF9800; // Orange
      case basse:
        return 0xFF2196F3; // Bleu
      case soprano:
        return 0xFFE91E63; // Rose
      case alto:
        return 0xFF9C27B0; // Violet
      default:
        return 0xFF9E9E9E; // Gris
    }
  }

  // Obtenir l'icône associée au pupitre
  static String getIconForPupitre(String pupitre) {
    switch (pupitre) {
      case tenor:
        return '🎤';
      case basse:
        return '🎵';
      case soprano:
        return '🎶';
      case alto:
        return '🎼';
      default:
        return '🎵';
    }
  }
}
