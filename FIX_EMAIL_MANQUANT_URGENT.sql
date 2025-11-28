-- =====================================================
-- FIX URGENT : Email manquant pour "Utilisateur"
-- =====================================================

-- 1. Trouver l'utilisateur avec le nom "Utilisateur"
SELECT 
    '🔍 Recherche de l''utilisateur problématique' as info;

SELECT 
    p.user_id,
    p.full_name,
    p.statut_validation,
    p.created_at,
    au.email,
    CASE 
        WHEN au.id IS NULL THEN '❌ Pas dans auth.users'
        WHEN au.email IS NULL THEN '❌ Email NULL'
        ELSE '✅ Email OK'
    END as diagnostic
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
WHERE p.statut_validation = 'en_attente'
ORDER BY p.created_at DESC;

-- 2. Lister TOUS les utilisateurs de auth.users
SELECT 
    '📋 Liste complète de auth.users' as info;

SELECT 
    id as user_id,
    email,
    created_at,
    CASE 
        WHEN EXISTS (SELECT 1 FROM profiles WHERE user_id = auth.users.id) 
        THEN '✅ A un profil'
        ELSE '❌ Pas de profil'
    END as statut_profil
FROM auth.users
ORDER BY created_at DESC;

-- 3. Créer les profils manquants avec les bons emails
SELECT 
    '🔧 Création des profils manquants' as info;

INSERT INTO profiles (user_id, full_name, role, statut_validation, created_at)
SELECT 
    au.id,
    COALESCE(
        au.raw_user_meta_data->>'full_name',
        SPLIT_PART(au.email, '@', 1),
        'Utilisateur'
    ) as full_name,
    'membre' as role,
    'en_attente' as statut_validation,
    au.created_at
FROM auth.users au
WHERE NOT EXISTS (SELECT 1 FROM profiles WHERE user_id = au.id)
ON CONFLICT (user_id) DO UPDATE
SET full_name = EXCLUDED.full_name;

-- 4. Mettre à jour les noms "Utilisateur" avec l'email
SELECT 
    '🔧 Mise à jour des noms génériques' as info;

UPDATE profiles p
SET full_name = COALESCE(
    au.raw_user_meta_data->>'full_name',
    SPLIT_PART(au.email, '@', 1),
    'Utilisateur_' || SUBSTRING(p.user_id::TEXT, 1, 8)
)
FROM auth.users au
WHERE p.user_id = au.id
AND (p.full_name = 'Utilisateur' OR p.full_name IS NULL OR p.full_name = '');

-- 5. Recréer la vue avec LEFT JOIN
DROP VIEW IF EXISTS membres_en_attente;

CREATE OR REPLACE VIEW membres_en_attente AS
SELECT 
    p.user_id,
    COALESCE(au.email::TEXT, 'email@manquant.com') as email,
    COALESCE(NULLIF(p.full_name, ''), 'Utilisateur_' || SUBSTRING(p.user_id::TEXT, 1, 8)) as full_name,
    p.telephone,
    p.created_at,
    p.statut_validation,
    EXTRACT(DAY FROM (NOW() - p.created_at))::INTEGER as jours_attente
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
WHERE p.statut_validation = 'en_attente'
ORDER BY p.created_at ASC;

-- Permissions
GRANT SELECT ON membres_en_attente TO authenticated;
GRANT SELECT ON membres_en_attente TO anon;

-- 6. Vérification finale
SELECT 
    '✅ VÉRIFICATION FINALE' as info;

SELECT 
    user_id,
    email,
    full_name,
    telephone,
    jours_attente,
    statut_validation
FROM membres_en_attente
ORDER BY created_at DESC;

-- 7. Statistiques
SELECT 
    '📊 STATISTIQUES' as info;

SELECT 
    COUNT(*) as total_membres_attente,
    COUNT(CASE WHEN email != 'email@manquant.com' THEN 1 END) as avec_email_valide,
    COUNT(CASE WHEN full_name NOT LIKE 'Utilisateur%' THEN 1 END) as avec_nom_valide
FROM membres_en_attente;

SELECT '✅ Correction terminée avec succès !' as status;
SELECT '🔄 Rechargez le dashboard (F5) pour voir les changements' as conseil;
