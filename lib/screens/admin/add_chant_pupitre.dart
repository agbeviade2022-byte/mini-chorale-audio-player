import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_chorale_audio_player/config/theme.dart';
import 'package:mini_chorale_audio_player/widgets/custom_button.dart';
import 'package:mini_chorale_audio_player/providers/chants_provider.dart';
import 'package:mini_chorale_audio_player/services/supabase_storage_service.dart';
import 'package:mini_chorale_audio_player/models/pupitre.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mini_chorale_audio_player/utils/snackbar_utils.dart';

class AddChantPupitreScreen extends ConsumerStatefulWidget {
  const AddChantPupitreScreen({super.key});

  @override
  ConsumerState<AddChantPupitreScreen> createState() => _AddChantPupitreScreenState();
}

class _AddChantPupitreScreenState extends ConsumerState<AddChantPupitreScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();

  String? _selectedPupitre;
  List<PlatformFile> _selectedFiles = [];
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  int _currentFileIndex = 0;
  
  final _storageService = SupabaseStorageService();

  @override
  void dispose() {
    _titreController.dispose();
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
    
    if (_selectedPupitre == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un pupitre'),
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

    try {
      // Upload en masse depuis fichiers sélectionnés
      for (int i = 0; i < _selectedFiles.length; i++) {
          if (!mounted) break;
          
          setState(() {
            _currentFileIndex = i;
            _uploadProgress = (i / _selectedFiles.length);
          });

          try {
            final file = _selectedFiles[i];
            File? fileToUpload;
            if (!kIsWeb && file.path != null) {
              fileToUpload = File(file.path!);
            }
            
            final extension = file.extension != null 
                ? '.${file.extension}' 
                : '.mp3';
            
            // Utiliser le titre personnalisé ou le nom du fichier
            final titre = _selectedFiles.length == 1 && _titreController.text.isNotEmpty
                ? _titreController.text.trim()
                : file.name.replaceAll(RegExp(r'\.[^.]+$'), '');
            
            final audioUrl = await _storageService.uploadAudioFile(
              file: fileToUpload,
              bytes: kIsWeb ? file.bytes : null,
              fileName: titre,
              fileExtension: extension,
            );

            const duree = 180;
            await ref.read(chantsNotifierProvider.notifier).addChant(
                  titre: titre,
                  categorie: _selectedPupitre!,
                  auteur: _selectedPupitre!,
                  urlAudio: audioUrl,
                  duree: duree,
                  type: 'pupitre',
                );
            successCount++;
          } catch (e) {
            failureCount++;
          }
        }

      if (mounted) {
        if (successCount > 0 && failureCount == 0) {
          // Tous les chants ajoutés avec succès
          if (successCount == 1) {
            SnackBarUtils.showChantAdded(context, _titreController.text.trim());
          } else {
            SnackBarUtils.showSuccess(context, '✅ $successCount chants pupitre ajoutés avec succès');
          }
          Navigator.of(context).pop(true);
        } else if (successCount > 0 && failureCount > 0) {
          // Succès partiel
          SnackBarUtils.showWarning(
            context,
            '⚠️ $successCount réussi(s), $failureCount échec(s)',
          );
          Navigator.of(context).pop(true);
        } else if (failureCount > 0) {
          // Tous ont échoué
          SnackBarUtils.showChantAddError(
            context,
            'Échec de l\'ajout de ${failureCount > 1 ? 'tous les chants' : 'le chant'}',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showChantAddError(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un chant par pupitre'),
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
                  if (_selectedFiles.length == 1 && (value == null || value.isEmpty)) {
                    return 'Veuillez entrer un titre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Pupitre
              DropdownButtonFormField<String>(
                initialValue: _selectedPupitre,
                decoration: const InputDecoration(
                  labelText: 'Pupitre',
                  prefixIcon: Icon(Icons.people),
                ),
                items: Pupitre.all.map((pupitre) {
                  return DropdownMenuItem(
                    value: pupitre,
                    child: Row(
                      children: [
                        Text(
                          Pupitre.getIconForPupitre(pupitre),
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 8),
                        Text(pupitre),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPupitre = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Veuillez sélectionner un pupitre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Zone upload
              _buildUploadSection(),

              const SizedBox(height: 32),

              // Progression upload
              if (_isUploading) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: _uploadProgress,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.secondary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Upload ${_currentFileIndex + 1}/${_selectedFiles.isNotEmpty ? _selectedFiles.length : 1}...',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],

              // Bouton soumettre
              CustomButton(
                text: _selectedFiles.length > 1
                    ? 'Ajouter ${_selectedFiles.length} chants'
                    : 'Ajouter le chant',
                onPressed: _submitForm,
                isLoading: _isUploading,
                icon: Icons.add,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _selectedFiles.isNotEmpty ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.surfaceContainerHighest,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            _selectedFiles.isNotEmpty ? Icons.audiotrack : Icons.upload_file,
            size: 48,
            color: _selectedFiles.isNotEmpty ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.onSurface,
          ),
          const SizedBox(height: 12),
          Text(
            _selectedFiles.isEmpty
                ? 'Aucun fichier sélectionné'
                : '${_selectedFiles.length} fichier(s) sélectionné(s)',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (_selectedFiles.isNotEmpty) ...[
            const SizedBox(height: 8),
            if (_selectedFiles.length == 1) ...[
              Text(
                _selectedFiles.first.name,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                '${_storageService.getFileSizeInMB(_selectedFiles.first).toStringAsFixed(2)} MB',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
              ),
            ] else ...[
              Container(
                constraints: const BoxConstraints(maxHeight: 150),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _selectedFiles.length,
                  itemBuilder: (context, index) {
                    final file = _selectedFiles[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.audiotrack, size: 16, color: Theme.of(context).colorScheme.secondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              file.name,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${_storageService.getFileSizeInMB(file).toStringAsFixed(1)} MB',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.gold,
                                ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
          const SizedBox(height: 16),
          CustomButton(
            text: 'Choisir des fichiers audio',
            onPressed: _pickAudioFiles,
            icon: Icons.folder_open,
            isOutlined: true,
          ),
        ],
      ),
    );
  }
}
