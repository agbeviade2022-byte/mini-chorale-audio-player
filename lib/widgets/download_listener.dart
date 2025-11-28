import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_chorale_audio_player/providers/download_provider.dart';
import 'package:mini_chorale_audio_player/models/downloaded_chant.dart';

/// Widget qui écoute les changements d'état de téléchargement
/// et affiche des SnackBar pour succès/échec
class DownloadListener extends ConsumerStatefulWidget {
  final Widget child;

  const DownloadListener({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<DownloadListener> createState() => _DownloadListenerState();
}

class _DownloadListenerState extends ConsumerState<DownloadListener> {
  Map<String, DownloadStatus> _previousStates = {};

  @override
  Widget build(BuildContext context) {
    // Écouter les changements d'état
    ref.listen<Map<String, DownloadState>>(
      downloadNotifierProvider,
      (previous, next) {
        // Vérifier chaque chant pour détecter les changements
        next.forEach((chantId, downloadState) {
          final previousStatus = _previousStates[chantId];
          final currentStatus = downloadState.status;

          // Si le statut a changé
          if (previousStatus != currentStatus) {
            // Téléchargement réussi
            if (currentStatus == DownloadStatus.downloaded &&
                previousStatus == DownloadStatus.downloading) {
              _showSuccessSnackBar(context);
            }
            // Téléchargement échoué
            else if (currentStatus == DownloadStatus.failed &&
                previousStatus == DownloadStatus.downloading) {
              _showErrorSnackBar(context, downloadState.error);
            }

            // Mettre à jour l'état précédent
            _previousStates[chantId] = currentStatus;
          }
        });
      },
    );

    return widget.child;
  }

  void _showSuccessSnackBar(BuildContext context) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                '✅ Téléchargement terminé',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String? error) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                '❌ Échec du téléchargement',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        action: error != null
            ? SnackBarAction(
                label: 'Détails',
                textColor: Colors.white,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Erreur de téléchargement'),
                      content: Text(error),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('OK'),
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
}
