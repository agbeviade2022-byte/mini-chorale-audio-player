-- =====================================================
-- FIX URGENT : Désactiver RLS temporairement
-- =====================================================

SELECT '🔧 FIX URGENT : Désactivation RLS' as info;

-- ============================================
-- ÉTAPE 1 : Désactiver RLS sur profiles
-- ============================================

SELECT '📋 ÉTAPE 1 : Désactivation RLS profiles' as etape;

-- Désactiver RLS
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;

SELECT 'profiles' as table_name, 
       '✅ RLS désactivé' as statut;

-- ============================================
-- ÉTAPE 2 : Désactiver RLS sur chorales
-- ============================================

SELECT '📋 ÉTAPE 2 : Désactivation RLS chorales' as etape;

-- Désactiver RLS
ALTER TABLE chorales DISABLE ROW LEVEL SECURITY;

SELECT 'chorales' as table_name, 
       '✅ RLS désactivé' as statut;

-- ============================================
-- ÉTAPE 3 : Désactiver RLS sur chants
-- ============================================

SELECT '📋 ÉTAPE 3 : Désactivation RLS chants' as etape;

-- Désactiver RLS
ALTER TABLE chants DISABLE ROW LEVEL SECURITY;

SELECT 'chants' as table_name, 
       '✅ RLS désactivé' as statut;

-- ============================================
-- ÉTAPE 4 : Vérifier l'état
-- ============================================

SELECT '📋 ÉTAPE 4 : Vérification' as etape;

-- Vérifier que RLS est bien désactivé
SELECT 
    tablename,
    rowsecurity as rls_active,
    CASE 
        WHEN rowsecurity = false THEN '✅ RLS désactivé'
        ELSE '❌ RLS encore activé'
    END as statut
FROM pg_tables
WHERE tablename IN ('profiles', 'chorales', 'chants')
ORDER BY tablename;

-- ============================================
-- ÉTAPE 5 : Tester l'accès
-- ============================================

SELECT '📋 ÉTAPE 5 : Tests d''accès' as etape;

-- Test 1 : Chorales
SELECT 
    'chorales' as table_name,
    COUNT(*) as nb_lignes,
    '✅ Accessible' as statut
FROM chorales;

-- Test 2 : Profiles
SELECT 
    'profiles' as table_name,
    COUNT(*) as nb_lignes,
    '✅ Accessible' as statut
FROM profiles;

-- Test 3 : Chants
SELECT 
    'chants' as table_name,
    COUNT(*) as nb_lignes,
    '✅ Accessible' as statut
FROM chants;

-- ============================================
-- RÉSULTAT
-- ============================================

SELECT '✅✅✅ RLS DÉSACTIVÉ ✅✅✅' as resultat;
SELECT 'Le dashboard devrait maintenant fonctionner' as note1;
SELECT 'Rafraîchissez le navigateur (F5)' as note2;
SELECT '⚠️ ATTENTION : RLS désactivé = moins sécurisé' as avertissement;
SELECT 'Nous réactiverons RLS avec des politiques correctes plus tard' as plan;

-- ============================================
-- NOTES IMPORTANTES
-- ============================================

/*
⚠️ SÉCURITÉ TEMPORAIREMENT RÉDUITE

Avec RLS désactivé :
- ✅ Le dashboard fonctionne
- ✅ Pas de récursion
- ✅ Pas d'erreur 500
- ⚠️ Tous les utilisateurs authentifiés peuvent tout voir
- ⚠️ Pas de filtrage par chorale

PROCHAINES ÉTAPES :
1. Tester que le dashboard fonctionne
2. Créer des politiques RLS simples et sans récursion
3. Réactiver RLS progressivement

POUR RÉACTIVER RLS PLUS TARD :
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE chorales ENABLE ROW LEVEL SECURITY;
ALTER TABLE chants ENABLE ROW LEVEL SECURITY;
*/
