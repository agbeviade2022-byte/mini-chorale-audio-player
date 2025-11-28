-- =====================================================
-- DEBUG : Membres en attente - Nom et email manquants
-- =====================================================

-- 1. Vérifier les utilisateurs en attente dans profiles
SELECT 
    '1️⃣ Utilisateurs en attente dans profiles' as etape;

SELECT 
    user_id,
    full_name,
    role,
    statut_validation,
    created_at
FROM profiles
WHERE statut_validation = 'en_attente'
ORDER BY created_at DESC;

-- 2. Vérifier si ces utilisateurs existent dans auth.users
SELECT 
    '2️⃣ Vérification dans auth.users' as etape;

SELECT 
    p.user_id,
    p.full_name,
    au.email,
    CASE 
        WHEN au.id IS NOT NULL THEN '✅ Email trouvé'
        ELSE '❌ Pas dans auth.users'
    END as statut
FROM profiles p
LEFT JOIN auth.users au ON p.user_id = au.id
WHERE p.statut_validation = 'en_attente'
ORDER BY p.created_at DESC;

-- 3. Tester la vue membres_en_attente
SELECT 
    '3️⃣ Test de la vue membres_en_attente' as etape;

SELECT 
    user_id,
    email,
    full_name,
    telephone,
    jours_attente,
    statut_validation
FROM membres_en_attente;

-- 4. Vérifier les utilisateurs sans full_name
SELECT 
    '4️⃣ Utilisateurs sans nom' as etape;

SELECT 
    user_id,
    full_name,
    au.email,
    CASE 
        WHEN full_name IS NULL OR full_name = '' THEN '❌ Nom manquant'
        ELSE '✅ Nom OK'
    END as statut_nom
FROM profiles p
JOIN auth.users au ON p.user_id = au.id
WHERE statut_validation = 'en_attente';

-- 5. CORRECTION : Mettre à jour les noms manquants
SELECT 
    '🔧 CORRECTION : Mise à jour des noms manquants' as etape;

UPDATE profiles p
SET full_name = COALESCE(
    NULLIF(p.full_name, ''),
    au.raw_user_meta_data->>'full_name',
    SPLIT_PART(au.email, '@', 1)
)
FROM auth.users au
WHERE p.user_id = au.id
AND (p.full_name IS NULL OR p.full_name = '')
AND p.statut_validation = 'en_attente';

-- 6. Vérification après correction
SELECT 
    '✅ Vérification après correction' as etape;

SELECT 
    user_id,
    full_name,
    email,
    telephone,
    jours_attente
FROM membres_en_attente
ORDER BY created_at DESC;

-- 7. Créer des profils pour les utilisateurs orphelins en attente
SELECT 
    '🔧 Création des profils manquants' as etape;

INSERT INTO profiles (user_id, full_name, role, statut_validation, created_at)
SELECT 
    au.id,
    COALESCE(
        au.raw_user_meta_data->>'full_name',
        SPLIT_PART(au.email, '@', 1)
    ) as full_name,
    'membre' as role,
    'en_attente' as statut_validation,
    au.created_at
FROM auth.users au
WHERE NOT EXISTS (SELECT 1 FROM profiles WHERE user_id = au.id)
ON CONFLICT (user_id) DO NOTHING;

-- 8. Résumé final
SELECT 
    '📊 RÉSUMÉ FINAL' as etape;

SELECT 
    COUNT(*) as total_en_attente,
    COUNT(CASE WHEN full_name IS NOT NULL AND full_name != '' THEN 1 END) as avec_nom,
    COUNT(CASE WHEN email IS NOT NULL THEN 1 END) as avec_email
FROM membres_en_attente;

SELECT '✅ Diagnostic et correction terminés' as status;
