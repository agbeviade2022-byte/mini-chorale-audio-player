# Configuration du Storage Supabase

## Problème 400 Bad Request lors de l'upload

Si vous rencontrez une erreur 400 lors de l'upload de fichiers audio, suivez ces étapes :

## 1. Vérifier que le bucket existe

Allez dans **Supabase Dashboard → Storage** et vérifiez que le bucket `audio_files` existe.

## 2. Créer le bucket s'il n'existe pas

### Via l'interface Supabase :
1. Allez dans **Storage**
2. Cliquez sur **New Bucket**
3. Nom : `audio_files`
4. **Cochez "Public bucket"**
5. File size limit : `52428800` (50 MB)
6. Allowed MIME types : `audio/mpeg, audio/mp3, audio/wav, audio/ogg, audio/m4a, audio/mp4`

### Via SQL :
```sql
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'audio_files',
  'audio_files',
  true,
  52428800,
  ARRAY['audio/mpeg', 'audio/mp3', 'audio/wav', 'audio/ogg', 'audio/m4a', 'audio/mp4', 'audio/aac', 'audio/flac']
)
ON CONFLICT (id) DO UPDATE SET
  public = true,
  file_size_limit = 52428800,
  allowed_mime_types = ARRAY['audio/mpeg', 'audio/mp3', 'audio/wav', 'audio/ogg', 'audio/m4a', 'audio/mp4', 'audio/aac', 'audio/flac'];
```

## 3. Configurer les politiques d'accès (RLS)

Exécutez ces commandes SQL dans l'éditeur SQL de Supabase :

```sql
-- Permettre à tout le monde de voir les fichiers audio
DROP POLICY IF EXISTS "Anyone can view audio files" ON storage.objects;
CREATE POLICY "Anyone can view audio files"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'audio_files');

-- Permettre aux admins d'uploader des fichiers
DROP POLICY IF EXISTS "Admins can upload audio files" ON storage.objects;
CREATE POLICY "Admins can upload audio files"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'audio_files' AND
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Permettre aux admins de mettre à jour des fichiers
DROP POLICY IF EXISTS "Admins can update audio files" ON storage.objects;
CREATE POLICY "Admins can update audio files"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'audio_files' AND
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Permettre aux admins de supprimer des fichiers
DROP POLICY IF EXISTS "Admins can delete audio files" ON storage.objects;
CREATE POLICY "Admins can delete audio files"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'audio_files' AND
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.role = 'admin'
    )
  );
```

## 4. Vérifier le rôle de l'utilisateur

Assurez-vous que votre compte est bien admin :

```sql
-- Voir votre profil
SELECT * FROM profiles WHERE user_id = auth.uid();

-- Si vous n'êtes pas admin, mettez à jour :
UPDATE profiles SET role = 'admin' WHERE user_id = auth.uid();
```

## 5. Formats audio supportés

L'application supporte les formats suivants :
- MP3 (`.mp3`) - audio/mpeg
- M4A (`.m4a`) - audio/mp4
- WAV (`.wav`) - audio/wav
- OGG (`.ogg`) - audio/ogg
- AAC (`.aac`) - audio/aac
- FLAC (`.flac`) - audio/flac

## 6. Limites

- Taille maximale par fichier : **50 MB**
- Le nom de fichier sera automatiquement nettoyé (accents et caractères spéciaux supprimés)

## Dépannage

Si l'erreur persiste après avoir suivi ces étapes :

1. **Vérifiez les logs Supabase** : Allez dans **Logs → Storage** pour voir les détails de l'erreur
2. **Testez l'upload via l'interface Supabase** : Essayez d'uploader manuellement un fichier dans le bucket
3. **Vérifiez votre connexion** : Assurez-vous que les credentials Supabase dans votre app sont corrects
4. **Consultez la console du navigateur** : Regardez s'il y a des erreurs CORS ou d'authentification
