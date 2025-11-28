import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_chorale_audio_player/config/theme.dart';
import 'package:mini_chorale_audio_player/widgets/custom_button.dart';
import 'package:mini_chorale_audio_player/providers/chants_provider.dart';
import 'package:mini_chorale_audio_player/services/supabase_storage_service.dart';
import 'package:mini_chorale_audio_player/models/category.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mini_chorale_audio_player/utils/snackbar_utils.dart';

class AddChantScreen extends ConsumerStatefulWidget {
  const AddChantScreen({super.key});

  @override
  ConsumerState<AddChantScreen> createState() => _AddChantScreenState();
}

class _AddChantScreenState extends ConsumerState<AddChantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _auteurController = TextEditingController();

  String? _selectedCategory;
  List<PlatformFile> _selectedFiles = [];
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  int _currentFileIndex = 0;
  final _storageService = SupabaseStorageService();

  @override
  void dispose() {
    _titreController.dispose();
    _auteurController.dispose();
    super.dispose();
  }

  Future<void> _pickAudioFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'aac', 'm4a', 'ogg', 'flac'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final validFiles = result.files.where((file) {
          return _storageService.isValidAudioFile(file);
        }).toList();

        if (validFiles.length != result.files.length) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${result.files.length - validFiles.length} fichier(s) rejeté(s) (max 50MB)',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }

        setState(() {
          _selectedFiles = validFiles;
          // Pré-remplir le titre avec le nom du premier fichier
          if (validFiles.length == 1) {
            _titreController.text =
                validFiles.first.name.replaceAll(RegExp(r'\.[^.]+$'), '');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner au moins un fichier audio'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une catégorie'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _currentFileIndex = 0;
    });

    int successCount = 0;
    int failureCount = 0;

    final useCustomTitle =
        _selectedFiles.length == 1 && _titreController.text.trim().isNotEmpty;

    for (int i = 0; i < _selectedFiles.length; i++) {
      final file = _selectedFiles[i];
      setState(() {
        _currentFileIndex = i + 1;
        _uploadProgress = (i / _selectedFiles.length);
      });

      try {
        final titre = useCustomTitle
            ? _titreController.text.trim()
            : file.name.replaceAll(RegExp(r'\.[^.]+$'), '');
        final auteur = _auteurController.text.trim();
        final extension =
            file.extension != null ? '.${file.extension}' : '.mp3';

        final audioUrl = await _storageService.uploadAudioFile(
          file: kIsWeb ? null : File(file.path!),
          bytes: kIsWeb ? file.bytes : null,
          fileName: titre,
          fileExtension: extension,
        );

        await ref.read(chantsNotifierProvider.notifier).addChant(
              titre: titre,
              categorie: _selectedCategory!,
              auteur: auteur.isEmpty ? 'Inconnu' : auteur,
              urlAudio: audioUrl,
              duree: 180,
              type: 'normal',
            );

        successCount++;
      } catch (e) {
        failureCount++;
      }
    }

    setState(() {
      _isUploading = false;
      _uploadProgress = 1.0;
    });

    if (mounted) {
      // Afficher les résultats
      if (successCount > 0 && failureCount == 0) {
        // Tous les chants ajoutés avec succès
        if (successCount == 1) {
          SnackBarUtils.showChantAdded(context, _titreController.text.trim());
        } else {
          SnackBarUtils.showSuccess(context, '✅ $successCount chants ajoutés avec succès');
        }
        Navigator.of(context).pop();
      } else if (successCount > 0 && failureCount > 0) {
        // Succès partiel
        SnackBarUtils.showWarning(
          context,
          '⚠️ $successCount réussi(s), $failureCount échec(s)',
        );
        Navigator.of(context).pop();
      } else if (failureCount > 0) {
        // Tous ont échoué
        SnackBarUtils.showChantAddError(
          context,
          'Échec de l\'ajout de ${failureCount > 1 ? 'tous les chants' : 'le chant'}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un chant'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Titre
              TextFormField(
                controller: _titreController,
                decoration: InputDecoration(
                  labelText: _selectedFiles.length > 1
                      ? 'Titre (optionnel pour plusieurs fichiers)'
                      : 'Titre du chant',
                  prefixIcon: const Icon(Icons.title),
                  hintText: _selectedFiles.length > 1
                      ? 'Les noms de fichiers seront utilisés'
                      : null,
                ),
                validator: (value) {
                  if (_selectedFiles.length == 1 &&
                      (value == null || value.isEmpty)) {
                    return 'Veuillez entrer un titre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Auteur
              TextFormField(
                controller: _auteurController,
                decoration: const InputDecoration(
                  labelText: 'Auteur (optionnel)',
                  prefixIcon: Icon(Icons.person),
                  hintText: 'Laissez vide si inconnu',
                ),
              ),
              const SizedBox(height: 16),

              // Catégorie
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
                  prefixIcon: Icon(Icons.category),
                ),
                items: Category.defaultCategories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Veuillez sélectionner une catégorie';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Sélection fichier(s) audio
              CustomButton(
                text: _selectedFiles.isEmpty
                    ? 'Choisir des fichiers audio'
                    : '${_selectedFiles.length} fichier(s) sélectionné(s)',
                onPressed: () => _pickAudioFiles(),
                icon: Icons.audio_file,
                backgroundColor:
                    _selectedFiles.isEmpty ? AppTheme.gold : Colors.green,
              ),

              if (_selectedFiles.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.lightGrey,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fichiers sélectionnés:',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(_selectedFiles.length, (index) {
                        final file = _selectedFiles[index];
                        final size = _storageService
                            .getFileSizeInMB(file)
                            .toStringAsFixed(2);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.music_note,
                                  size: 20, color: AppTheme.primaryBlue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      file.name
                                          .replaceAll(RegExp(r'\.[^.]+$'), ''),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text('$size MB',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _selectedFiles.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              if (_isUploading) ...[
                LinearProgressIndicator(
                  value: _uploadProgress,
                  backgroundColor: AppTheme.lightGrey,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppTheme.gold),
                  minHeight: 8,
                ),
                const SizedBox(height: 12),
                Text(
                  'Upload en cours... ($_currentFileIndex/${_selectedFiles.length})',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
              ],

              // Bouton soumettre
              CustomButton(
                text: _isUploading
                    ? 'Upload en cours...'
                    : (_selectedFiles.length > 1
                        ? 'Ajouter ${_selectedFiles.length} chants'
                        : 'Ajouter le chant'),
                onPressed: _isUploading ? () {} : () => _submitForm(),
                icon: Icons.cloud_upload,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
