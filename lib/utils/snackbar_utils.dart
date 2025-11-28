import 'package:flutter/material.dart';

/// Utilitaires pour afficher des SnackBar cohérents dans toute l'application
class SnackBarUtils {
  /// Afficher un SnackBar de succès
  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  /// Afficher un SnackBar d'erreur
  static void showError(BuildContext context, String message, {String? details}) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        action: details != null
            ? SnackBarAction(
                label: 'Détails',
                textColor: Colors.white,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Détails de l\'erreur'),
                      content: Text(details),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
              )
            : null,
      ),
    );
  }

  /// Afficher un SnackBar d'information
  static void showInfo(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  /// Afficher un SnackBar d'avertissement
  static void showWarning(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  /// Afficher un SnackBar pour l'ajout d'un chant
  static void showChantAdded(BuildContext context, String titre) {
    showSuccess(context, '✅ "$titre" ajouté avec succès');
  }

  /// Afficher un SnackBar pour la modification d'un chant
  static void showChantUpdated(BuildContext context, String titre) {
    showSuccess(context, '✅ "$titre" modifié avec succès');
  }

  /// Afficher un SnackBar pour la suppression d'un chant
  static void showChantDeleted(BuildContext context, String titre) {
    showSuccess(context, '✅ "$titre" supprimé avec succès');
  }

  /// Afficher un SnackBar pour une erreur d'ajout
  static void showChantAddError(BuildContext context, String error) {
    showError(context, '❌ Erreur lors de l\'ajout', details: error);
  }

  /// Afficher un SnackBar pour une erreur de modification
  static void showChantUpdateError(BuildContext context, String error) {
    showError(context, '❌ Erreur lors de la modification', details: error);
  }

  /// Afficher un SnackBar pour une erreur de suppression
  static void showChantDeleteError(BuildContext context, String error) {
    showError(context, '❌ Erreur lors de la suppression', details: error);
  }
}
