-- =====================================================
-- SCRIPT DE VÉRIFICATION COMPLÈTE SUPABASE
-- =====================================================
-- Exécutez ce script pour vérifier que tout est bien configuré

-- =====================================================
-- 1. LISTER TOUTES LES TABLES
-- =====================================================

SELECT 
    '📋 TABLES EXISTANTES' as section,
    tablename as nom_table,
    CASE 
        WHEN rowsecurity THEN '🔒 RLS Activé (PROBLÈME!)'
        ELSE '✅ RLS Désactivé (OK)'
    END as statut_rls
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- =====================================================
-- 2. VÉRIFIER LES POLICIES RLS ACTIVES
-- =====================================================

SELECT 
    '🔐 POLICIES RLS' as section,
    tablename as table_name,
    policyname as policy_name,
    '⚠️ À SUPPRIMER' as action
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- =====================================================
-- 3. VÉRIFIER LES PLANS
-- =====================================================

SELECT 
    '💰 PLANS' as section,
    nom,
    prix_mensuel,
    max_membres,
    max_chants,
    max_stockage_mb
FROM plans
ORDER BY prix_mensuel;

-- =====================================================
-- 4. VÉRIFIER LES CHORALES
-- =====================================================

SELECT 
    '🎵 CHORALES' as section,
    nom,
    slug,
    statut,
    total_membres,
    total_chants,
    created_at
FROM chorales
ORDER BY created_at DESC;

-- =====================================================
-- 5. VÉRIFIER LES CHANTS
-- =====================================================

SELECT 
    '🎼 CHANTS' as section,
    COUNT(*) as nombre_total,
    COUNT(CASE WHEN type = 'normal' THEN 1 END) as chants_normaux,
    COUNT(CASE WHEN type = 'pupitre' THEN 1 END) as chants_pupitre
FROM chants;

-- =====================================================
-- 6. VÉRIFIER LES MEMBRES
-- =====================================================

SELECT 
    '👥 MEMBRES' as section,
    COUNT(*) as nombre_total,
    COUNT(DISTINCT chorale_id) as nombre_chorales,
    COUNT(DISTINCT user_id) as nombre_utilisateurs
FROM membres;

-- =====================================================
-- 7. VÉRIFIER LES FAVORIS
-- =====================================================

SELECT 
    '❤️ FAVORIS' as section,
    COUNT(*) as nombre_total,
    COUNT(DISTINCT user_id) as utilisateurs_avec_favoris
FROM favoris;

-- =====================================================
-- 8. VÉRIFIER LES PLAYLISTS
-- =====================================================

SELECT 
    '📝 PLAYLISTS' as section,
    COUNT(*) as nombre_total,
    COUNT(CASE WHEN publique THEN 1 END) as playlists_publiques,
    COUNT(CASE WHEN NOT publique THEN 1 END) as playlists_privees
FROM playlists;

-- =====================================================
-- 9. VÉRIFIER LES COLONNES DES TABLES PRINCIPALES
-- =====================================================

SELECT 
    '📊 STRUCTURE TABLES' as section,
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name IN ('plans', 'chorales', 'membres', 'chants', 'favoris', 'playlists')
ORDER BY table_name, ordinal_position;

-- =====================================================
-- 10. RÉSUMÉ FINAL
-- =====================================================

SELECT 
    '✅ RÉSUMÉ' as section,
    'Tables créées' as verification,
    COUNT(DISTINCT tablename)::text || ' tables' as resultat
FROM pg_tables
WHERE schemaname = 'public'
UNION ALL
SELECT 
    '✅ RÉSUMÉ',
    'RLS désactivé',
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ Aucune table avec RLS'
        ELSE '⚠️ ' || COUNT(*)::text || ' tables avec RLS activé'
    END
FROM pg_tables
WHERE schemaname = 'public' AND rowsecurity = true
UNION ALL
SELECT 
    '✅ RÉSUMÉ',
    'Policies RLS',
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ Aucune policy'
        ELSE '⚠️ ' || COUNT(*)::text || ' policies à supprimer'
    END
FROM pg_policies
WHERE schemaname = 'public'
UNION ALL
SELECT 
    '✅ RÉSUMÉ',
    'Plans créés',
    COUNT(*)::text || ' plans'
FROM plans
UNION ALL
SELECT 
    '✅ RÉSUMÉ',
    'Chorales créées',
    COUNT(*)::text || ' chorales'
FROM chorales
UNION ALL
SELECT 
    '✅ RÉSUMÉ',
    'Chants disponibles',
    COUNT(*)::text || ' chants'
FROM chants;

-- =====================================================
-- INTERPRÉTATION DES RÉSULTATS
-- =====================================================

/*
✅ CONFIGURATION CORRECTE SI:
- Toutes les tables ont "RLS Désactivé"
- Aucune policy RLS active
- 4 plans créés (Gratuit, Standard, Premium, Entreprise)
- Au moins 1 chorale créée (Ma Chorale)

⚠️ PROBLÈMES SI:
- Des tables ont "RLS Activé" → Exécuter fix_all_rls.sql
- Des policies RLS existent → Exécuter fix_all_rls.sql
- Moins de 4 plans → Réexécuter create_tables_minimal.sql
- Aucune chorale → Réexécuter create_tables_minimal.sql

🎯 PROCHAINES ÉTAPES:
Si tout est ✅, relancez votre app Flutter:
flutter run

Vous devriez voir:
✅ Hive initialisé avec succès
🏆 Session restaurée depuis Hive
🌐 Chargement depuis Supabase...
✅ Connexion réussie
*/
