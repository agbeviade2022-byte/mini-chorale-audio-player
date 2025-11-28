-- =====================================================
-- AUDIT COMPLET : Cohérence Flutter ↔ Dashboard ↔ BDD
-- =====================================================

SELECT '🔍 AUDIT COMPLET DE COHÉRENCE' as info;
SELECT '📅 Date: ' || NOW()::text as date_audit;

-- ============================================
-- PARTIE 1 : STRUCTURE DES TABLES PRINCIPALES
-- ============================================

SELECT '📋 PARTIE 1 : Structure des tables' as section;

-- 1.1 Table profiles
SELECT '🔹 1.1 Table PROFILES' as etape;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    CASE 
        WHEN column_name = 'id' THEN '🔑 PK (auto-increment)'
        WHEN column_name = 'user_id' THEN '🔗 FK → auth.users.id (UUID)'
        WHEN column_name = 'chorale_id' THEN '🔗 FK → chorales.id'
        WHEN column_name = 'role' THEN '👤 Rôle utilisateur'
        WHEN column_name = 'statut_validation' THEN '✅ Statut validation'
        ELSE '📄 ' || column_name
    END as description
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'profiles'
ORDER BY ordinal_position;

-- 1.2 Table chorales
SELECT '🔹 1.2 Table CHORALES' as etape;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    CASE 
        WHEN column_name = 'id' THEN '🔑 PK'
        WHEN column_name = 'nom' THEN '📝 Nom de la chorale'
        WHEN column_name = 'slug' THEN '🔗 Slug unique'
        ELSE '📄 ' || column_name
    END as description
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'chorales'
ORDER BY ordinal_position;

-- 1.3 Table chants
SELECT '🔹 1.3 Table CHANTS' as etape;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    CASE 
        WHEN column_name = 'id' THEN '🔑 PK'
        WHEN column_name = 'chorale_id' THEN '🔗 FK → chorales.id'
        WHEN column_name = 'titre' THEN '🎵 Titre du chant'
        ELSE '📄 ' || column_name
    END as description
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'chants'
ORDER BY ordinal_position;

-- 1.4 Table user_permissions
SELECT '🔹 1.4 Table USER_PERMISSIONS' as etape;

SELECT 
    column_name,
    data_type,
    is_nullable,
    CASE 
        WHEN column_name = 'id' THEN '🔑 PK'
        WHEN column_name = 'user_id' THEN '🔗 FK → profiles.id (INTEGER)'
        WHEN column_name = 'module_code' THEN '🔗 FK → modules_permissions.code'
        ELSE '📄 ' || column_name
    END as description
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'user_permissions'
ORDER BY ordinal_position;

-- ============================================
-- PARTIE 2 : VÉRIFICATION DES TYPES D'ID
-- ============================================

SELECT '📋 PARTIE 2 : Types d''ID' as section;

SELECT '🔹 2.1 Types d''ID par table' as etape;

SELECT 
    'profiles.id' as colonne,
    pg_typeof((SELECT id FROM profiles LIMIT 1))::text as type_reel,
    'INTEGER (auto-increment)' as type_attendu,
    CASE 
        WHEN pg_typeof((SELECT id FROM profiles LIMIT 1))::text = 'integer' THEN '✅ Correct'
        ELSE '❌ Incohérent'
    END as statut
UNION ALL
SELECT 
    'profiles.user_id' as colonne,
    pg_typeof((SELECT user_id FROM profiles WHERE user_id IS NOT NULL LIMIT 1))::text as type_reel,
    'UUID' as type_attendu,
    CASE 
        WHEN pg_typeof((SELECT user_id FROM profiles WHERE user_id IS NOT NULL LIMIT 1))::text = 'uuid' THEN '✅ Correct'
        ELSE '❌ Incohérent'
    END as statut
UNION ALL
SELECT 
    'chorales.id' as colonne,
    pg_typeof((SELECT id FROM chorales LIMIT 1))::text as type_reel,
    'UUID ou INTEGER' as type_attendu,
    '✅ À vérifier' as statut
UNION ALL
SELECT 
    'chants.id' as colonne,
    pg_typeof((SELECT id FROM chants LIMIT 1))::text as type_reel,
    'UUID' as type_attendu,
    CASE 
        WHEN pg_typeof((SELECT id FROM chants LIMIT 1))::text = 'uuid' THEN '✅ Correct'
        ELSE '❌ Incohérent'
    END as statut
UNION ALL
SELECT 
    'user_permissions.user_id' as colonne,
    pg_typeof((SELECT user_id FROM user_permissions LIMIT 1))::text as type_reel,
    'INTEGER (profiles.id)' as type_attendu,
    CASE 
        WHEN pg_typeof((SELECT user_id FROM user_permissions LIMIT 1))::text = 'integer' THEN '✅ Correct'
        ELSE '❌ Incohérent'
    END as statut;

-- ============================================
-- PARTIE 3 : CONTRAINTES DE CLÉ ÉTRANGÈRE
-- ============================================

SELECT '📋 PARTIE 3 : Contraintes FK' as section;

SELECT '🔹 3.1 Foreign Keys existantes' as etape;

SELECT 
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
    tc.constraint_name,
    CASE 
        WHEN tc.table_name = 'profiles' AND kcu.column_name = 'chorale_id' THEN '✅ profiles → chorales'
        WHEN tc.table_name = 'chants' AND kcu.column_name = 'chorale_id' THEN '✅ chants → chorales'
        WHEN tc.table_name = 'user_permissions' AND kcu.column_name = 'user_id' THEN '✅ user_permissions → profiles'
        ELSE '📄 Autre FK'
    END as description
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
AND tc.table_schema = 'public'
AND tc.table_name IN ('profiles', 'chorales', 'chants', 'user_permissions')
ORDER BY tc.table_name, kcu.column_name;

-- ============================================
-- PARTIE 4 : VÉRIFICATION DES RELATIONS
-- ============================================

SELECT '📋 PARTIE 4 : Intégrité des relations' as section;

-- 4.1 Profils avec chorale_id invalide
SELECT '🔹 4.1 Profils → Chorales' as etape;

SELECT 
    COUNT(*) as total_profils,
    COUNT(chorale_id) as profils_avec_chorale,
    COUNT(*) - COUNT(chorale_id) as profils_sans_chorale,
    (SELECT COUNT(*) FROM profiles p 
     LEFT JOIN chorales c ON p.chorale_id = c.id 
     WHERE p.chorale_id IS NOT NULL AND c.id IS NULL) as chorale_id_invalide,
    CASE 
        WHEN (SELECT COUNT(*) FROM profiles p 
              LEFT JOIN chorales c ON p.chorale_id = c.id 
              WHERE p.chorale_id IS NOT NULL AND c.id IS NULL) = 0 
        THEN '✅ Toutes les relations valides'
        ELSE '❌ ' || (SELECT COUNT(*) FROM profiles p 
                       LEFT JOIN chorales c ON p.chorale_id = c.id 
                       WHERE p.chorale_id IS NOT NULL AND c.id IS NULL)::text || ' relation(s) invalide(s)'
    END as statut
FROM profiles;

-- 4.2 Chants avec chorale_id invalide
SELECT '🔹 4.2 Chants → Chorales' as etape;

SELECT 
    COUNT(*) as total_chants,
    COUNT(chorale_id) as chants_avec_chorale,
    COUNT(*) - COUNT(chorale_id) as chants_sans_chorale,
    (SELECT COUNT(*) FROM chants ch 
     LEFT JOIN chorales c ON ch.chorale_id = c.id 
     WHERE ch.chorale_id IS NOT NULL AND c.id IS NULL) as chorale_id_invalide,
    CASE 
        WHEN (SELECT COUNT(*) FROM chants ch 
              LEFT JOIN chorales c ON ch.chorale_id = c.id 
              WHERE ch.chorale_id IS NOT NULL AND c.id IS NULL) = 0 
        THEN '✅ Toutes les relations valides'
        ELSE '❌ ' || (SELECT COUNT(*) FROM chants ch 
                       LEFT JOIN chorales c ON ch.chorale_id = c.id 
                       WHERE ch.chorale_id IS NOT NULL AND c.id IS NULL)::text || ' relation(s) invalide(s)'
    END as statut
FROM chants;

-- 4.3 User_permissions avec user_id invalide
SELECT '🔹 4.3 User_permissions → Profiles' as etape;

SELECT 
    COUNT(*) as total_permissions,
    (SELECT COUNT(*) FROM user_permissions up 
     LEFT JOIN profiles p ON up.user_id = p.id 
     WHERE p.id IS NULL) as user_id_invalide,
    CASE 
        WHEN (SELECT COUNT(*) FROM user_permissions up 
              LEFT JOIN profiles p ON up.user_id = p.id 
              WHERE p.id IS NULL) = 0 
        THEN '✅ Toutes les relations valides'
        ELSE '❌ ' || (SELECT COUNT(*) FROM user_permissions up 
                       LEFT JOIN profiles p ON up.user_id = p.id 
                       WHERE p.id IS NULL)::text || ' relation(s) invalide(s)'
    END as statut
FROM user_permissions;

-- 4.4 Profiles avec user_id invalide (auth.users)
SELECT '🔹 4.4 Profiles → Auth.users' as etape;

SELECT 
    COUNT(*) as total_profils,
    COUNT(user_id) as profils_avec_user_id,
    COUNT(*) - COUNT(user_id) as profils_sans_user_id,
    (SELECT COUNT(*) FROM profiles p 
     LEFT JOIN auth.users au ON p.user_id = au.id 
     WHERE p.user_id IS NOT NULL AND au.id IS NULL) as user_id_invalide,
    CASE 
        WHEN (SELECT COUNT(*) FROM profiles p 
              LEFT JOIN auth.users au ON p.user_id = au.id 
              WHERE p.user_id IS NOT NULL AND au.id IS NULL) = 0 
        THEN '✅ Toutes les relations valides'
        ELSE '❌ ' || (SELECT COUNT(*) FROM profiles p 
                       LEFT JOIN auth.users au ON p.user_id = au.id 
                       WHERE p.user_id IS NOT NULL AND au.id IS NULL)::text || ' relation(s) invalide(s)'
    END as statut
FROM profiles;

-- ============================================
-- PARTIE 5 : COHÉRENCE DES DONNÉES
-- ============================================

SELECT '📋 PARTIE 5 : Cohérence des données' as section;

-- 5.1 Profils sans user_id (doublons potentiels)
SELECT '🔹 5.1 Profils sans user_id' as etape;

SELECT 
    p.id,
    p.full_name,
    p.role,
    p.statut_validation,
    p.created_at,
    '⚠️ Profil sans user_id - À supprimer' as alerte
FROM profiles p
WHERE p.user_id IS NULL
ORDER BY p.created_at DESC;

-- 5.2 Doublons de user_id dans profiles
SELECT '🔹 5.2 Doublons user_id' as etape;

SELECT 
    user_id,
    COUNT(*) as nombre_profils,
    STRING_AGG(id::text, ', ') as profile_ids,
    STRING_AGG(full_name, ', ') as noms,
    '⚠️ Doublon détecté' as alerte
FROM profiles
WHERE user_id IS NOT NULL
GROUP BY user_id
HAVING COUNT(*) > 1;

-- 5.3 Utilisateurs auth.users sans profil
SELECT '🔹 5.3 Users sans profil' as etape;

SELECT 
    au.id as user_id,
    au.email,
    au.created_at,
    '⚠️ User sans profil' as alerte
FROM auth.users au
LEFT JOIN profiles p ON au.id = p.user_id
WHERE p.id IS NULL
ORDER BY au.created_at DESC;

-- ============================================
-- PARTIE 6 : VÉRIFICATION FLUTTER vs DASHBOARD
-- ============================================

SELECT '📋 PARTIE 6 : Flutter vs Dashboard' as section;

-- 6.1 Chorales (Flutter filtre par statut='actif')
SELECT '🔹 6.1 Chorales actives vs toutes' as etape;

SELECT 
    'Total chorales' as type,
    COUNT(*) as nombre,
    '📊 Dashboard affiche toutes' as note
FROM chorales
UNION ALL
SELECT 
    'Chorales actives' as type,
    COUNT(*) as nombre,
    '📱 Flutter affiche seulement actives' as note
FROM chorales
WHERE statut = 'actif';

-- 6.2 Vérifier que les IDs sont compatibles String
SELECT '🔹 6.2 Compatibilité IDs (Flutter attend String)' as etape;

SELECT 
    'chorales.id' as table_colonne,
    pg_typeof((SELECT id FROM chorales LIMIT 1))::text as type_sql,
    CASE 
        WHEN pg_typeof((SELECT id FROM chorales LIMIT 1))::text IN ('uuid', 'character varying', 'text') 
        THEN '✅ Compatible String'
        WHEN pg_typeof((SELECT id FROM chorales LIMIT 1))::text IN ('integer', 'bigint') 
        THEN '⚠️ Numérique - Conversion automatique'
        ELSE '❌ Type incompatible'
    END as compatibilite_flutter
UNION ALL
SELECT 
    'chants.id' as table_colonne,
    pg_typeof((SELECT id FROM chants LIMIT 1))::text as type_sql,
    CASE 
        WHEN pg_typeof((SELECT id FROM chants LIMIT 1))::text IN ('uuid', 'character varying', 'text') 
        THEN '✅ Compatible String'
        WHEN pg_typeof((SELECT id FROM chants LIMIT 1))::text IN ('integer', 'bigint') 
        THEN '⚠️ Numérique - Conversion automatique'
        ELSE '❌ Type incompatible'
    END as compatibilite_flutter;

-- ============================================
-- PARTIE 7 : FONCTIONS RPC UTILISÉES
-- ============================================

SELECT '📋 PARTIE 7 : Fonctions RPC' as section;

SELECT '🔹 7.1 Fonctions RPC disponibles' as etape;

SELECT 
    routine_name as fonction,
    routine_type as type,
    CASE 
        WHEN routine_name = 'get_membres_en_attente' THEN '✅ Validation membres'
        WHEN routine_name = 'valider_membre' THEN '✅ Validation membres'
        WHEN routine_name = 'refuser_membre' THEN '✅ Validation membres'
        WHEN routine_name = 'get_user_permissions' THEN '✅ Permissions'
        WHEN routine_name = 'has_permission' THEN '✅ Permissions'
        ELSE '📄 Autre'
    END as utilisation
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name IN (
    'get_membres_en_attente',
    'valider_membre',
    'refuser_membre',
    'get_user_permissions',
    'has_permission',
    'attribuer_permission',
    'revoquer_permission'
)
ORDER BY routine_name;

-- ============================================
-- PARTIE 8 : RÉSUMÉ FINAL
-- ============================================

SELECT '📊 RÉSUMÉ FINAL' as section;

SELECT 
    '👥 Utilisateurs' as categorie,
    (SELECT COUNT(*) FROM auth.users) as total,
    (SELECT COUNT(*) FROM profiles WHERE user_id IS NOT NULL) as avec_profil,
    (SELECT COUNT(*) FROM profiles WHERE user_id IS NULL) as sans_user_id,
    CASE 
        WHEN (SELECT COUNT(*) FROM profiles WHERE user_id IS NULL) = 0 
        THEN '✅ Cohérent'
        ELSE '⚠️ Profils orphelins'
    END as statut
UNION ALL
SELECT 
    '🎭 Chorales' as categorie,
    (SELECT COUNT(*) FROM chorales) as total,
    (SELECT COUNT(*) FROM chorales WHERE statut = 'actif') as actives,
    (SELECT COUNT(*) FROM profiles WHERE chorale_id IS NOT NULL) as membres_assignes,
    '✅ OK' as statut
UNION ALL
SELECT 
    '🎵 Chants' as categorie,
    (SELECT COUNT(*) FROM chants) as total,
    (SELECT COUNT(*) FROM chants WHERE chorale_id IS NOT NULL) as avec_chorale,
    (SELECT COUNT(*) FROM chants WHERE chorale_id IS NULL) as sans_chorale,
    '✅ OK' as statut
UNION ALL
SELECT 
    '🔐 Permissions' as categorie,
    (SELECT COUNT(*) FROM user_permissions) as total,
    (SELECT COUNT(DISTINCT user_id) FROM user_permissions) as users_avec_permissions,
    (SELECT COUNT(*) FROM modules_permissions) as modules_disponibles,
    '✅ OK' as statut;

-- ============================================
-- ALERTES CRITIQUES
-- ============================================

SELECT '🚨 ALERTES CRITIQUES' as section;

-- Profils sans user_id
SELECT 
    '❌ CRITIQUE' as niveau,
    'Profils sans user_id' as probleme,
    COUNT(*)::text || ' profil(s)' as details,
    'DELETE FROM profiles WHERE user_id IS NULL;' as solution
FROM profiles
WHERE user_id IS NULL
HAVING COUNT(*) > 0

UNION ALL

-- Doublons user_id
SELECT 
    '❌ CRITIQUE' as niveau,
    'Doublons user_id' as probleme,
    COUNT(DISTINCT user_id)::text || ' user_id en double' as details,
    'Supprimer manuellement les doublons' as solution
FROM profiles
WHERE user_id IS NOT NULL
GROUP BY user_id
HAVING COUNT(*) > 1

UNION ALL

-- Relations invalides profiles → chorales
SELECT 
    '⚠️ ATTENTION' as niveau,
    'Profils avec chorale_id invalide' as probleme,
    COUNT(*)::text || ' profil(s)' as details,
    'UPDATE profiles SET chorale_id = NULL WHERE chorale_id NOT IN (SELECT id FROM chorales);' as solution
FROM profiles p
LEFT JOIN chorales c ON p.chorale_id = c.id
WHERE p.chorale_id IS NOT NULL AND c.id IS NULL
HAVING COUNT(*) > 0;

SELECT '✅✅✅ AUDIT TERMINÉ ✅✅✅' as resultat;
SELECT 'Analysez les alertes critiques ci-dessus' as note;
