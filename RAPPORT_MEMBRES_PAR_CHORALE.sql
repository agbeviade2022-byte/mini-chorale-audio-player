-- =====================================================
-- RAPPORT : Membres par chorale
-- =====================================================

SELECT '📊 RAPPORT : Qui est dans quelle chorale ?' as info;

-- ============================================
-- RAPPORT 1 : Vue d'ensemble
-- ============================================

SELECT '📋 RAPPORT 1 : Vue d''ensemble' as rapport;

SELECT 
    COALESCE(c.nom, '❌ Aucune chorale') as chorale,
    COUNT(*) as nb_membres,
    COUNT(CASE WHEN p.statut_validation = 'valide' THEN 1 END) as nb_valides,
    COUNT(CASE WHEN p.statut_validation = 'en_attente' THEN 1 END) as nb_en_attente,
    COUNT(CASE WHEN p.statut_validation = 'refuse' THEN 1 END) as nb_refuses,
    CASE 
        WHEN COUNT(*) > 10 THEN '🟢 Grande chorale'
        WHEN COUNT(*) > 5 THEN '🟡 Moyenne chorale'
        WHEN COUNT(*) > 0 THEN '🔵 Petite chorale'
        ELSE '⚪ Vide'
    END as taille
FROM profiles p
LEFT JOIN chorales c ON p.chorale_id = c.id
WHERE p.role IN ('membre', 'admin')
GROUP BY c.nom, c.id
ORDER BY nb_membres DESC, c.nom;

-- ============================================
-- RAPPORT 2 : Liste détaillée par chorale
-- ============================================

SELECT '📋 RAPPORT 2 : Liste détaillée' as rapport;

SELECT 
    COALESCE(c.nom, '❌ Aucune chorale') as chorale,
    p.full_name as nom_complet,
    au.email,
    p.role,
    p.statut_validation,
    p.telephone,
    TO_CHAR(p.created_at, 'DD/MM/YYYY') as date_inscription,
    CASE 
        WHEN p.role = 'super_admin' THEN '🔴 Super Admin'
        WHEN p.role = 'admin' THEN '🟠 Admin'
        WHEN p.role = 'membre' AND p.statut_validation = 'valide' THEN '🟢 Membre validé'
        WHEN p.role = 'membre' AND p.statut_validation = 'en_attente' THEN '🟡 En attente'
        WHEN p.role = 'membre' AND p.statut_validation = 'refuse' THEN '🔴 Refusé'
        ELSE '⚪ Autre'
    END as badge
FROM profiles p
INNER JOIN auth.users au ON p.user_id = au.id
LEFT JOIN chorales c ON p.chorale_id = c.id
ORDER BY 
    CASE WHEN c.nom IS NULL THEN 1 ELSE 0 END,
    c.nom,
    CASE 
        WHEN p.role = 'super_admin' THEN 1
        WHEN p.role = 'admin' THEN 2
        WHEN p.role = 'membre' THEN 3
        ELSE 4
    END,
    p.full_name;

-- ============================================
-- RAPPORT 3 : Statistiques par chorale
-- ============================================

SELECT '📋 RAPPORT 3 : Statistiques détaillées' as rapport;

WITH chorale_stats AS (
    SELECT 
        c.id as chorale_id,
        c.nom as chorale_nom,
        COUNT(DISTINCT p.user_id) as total_membres,
        COUNT(DISTINCT CASE WHEN p.role = 'admin' THEN p.user_id END) as nb_admins,
        COUNT(DISTINCT CASE WHEN p.role = 'membre' THEN p.user_id END) as nb_membres,
        COUNT(DISTINCT ch.id) as nb_chants,
        AVG(EXTRACT(EPOCH FROM (NOW() - p.created_at))/86400)::INTEGER as anciennete_moyenne_jours
    FROM chorales c
    LEFT JOIN profiles p ON p.chorale_id = c.id
    LEFT JOIN chants ch ON ch.chorale_id = c.id
    GROUP BY c.id, c.nom
)
SELECT 
    chorale_nom as chorale,
    total_membres,
    nb_admins,
    nb_membres,
    nb_chants,
    anciennete_moyenne_jours || ' jours' as anciennete_moyenne,
    CASE 
        WHEN total_membres = 0 THEN '⚪ Aucun membre'
        WHEN nb_admins = 0 THEN '⚠️ Pas d''admin'
        WHEN nb_chants = 0 THEN '⚠️ Pas de chants'
        ELSE '✅ Active'
    END as statut
FROM chorale_stats
ORDER BY total_membres DESC, chorale_nom;

-- ============================================
-- RAPPORT 4 : Membres sans chorale
-- ============================================

SELECT '📋 RAPPORT 4 : Membres sans chorale' as rapport;

SELECT 
    p.full_name as nom_complet,
    au.email,
    p.role,
    p.statut_validation,
    TO_CHAR(p.created_at, 'DD/MM/YYYY') as date_inscription,
    EXTRACT(DAY FROM (NOW() - p.created_at))::INTEGER || ' jours' as depuis,
    CASE 
        WHEN p.role = 'super_admin' THEN '✅ Normal (super admin)'
        WHEN p.role = 'admin' THEN '⚠️ Admin sans chorale'
        WHEN p.role = 'membre' AND p.statut_validation = 'valide' THEN '❌ À attribuer une chorale'
        WHEN p.role = 'membre' AND p.statut_validation = 'en_attente' THEN '🟡 En attente de validation'
        ELSE '⚪ Autre'
    END as action_requise
FROM profiles p
INNER JOIN auth.users au ON p.user_id = au.id
WHERE p.chorale_id IS NULL
ORDER BY 
    CASE 
        WHEN p.role = 'membre' AND p.statut_validation = 'valide' THEN 1
        WHEN p.role = 'admin' THEN 2
        WHEN p.role = 'membre' AND p.statut_validation = 'en_attente' THEN 3
        ELSE 4
    END,
    p.created_at DESC;

-- ============================================
-- RAPPORT 5 : Chorales avec leurs chants
-- ============================================

SELECT '📋 RAPPORT 5 : Chorales et leurs chants' as rapport;

SELECT 
    c.nom as chorale,
    COUNT(DISTINCT p.user_id) as nb_membres,
    COUNT(DISTINCT ch.id) as nb_chants,
    STRING_AGG(DISTINCT ch.titre, ', ' ORDER BY ch.titre) as chants,
    CASE 
        WHEN COUNT(DISTINCT ch.id) = 0 THEN '⚠️ Aucun chant'
        WHEN COUNT(DISTINCT ch.id) < 5 THEN '🔵 Peu de chants'
        WHEN COUNT(DISTINCT ch.id) < 10 THEN '🟢 Bon répertoire'
        ELSE '🌟 Riche répertoire'
    END as statut_repertoire
FROM chorales c
LEFT JOIN profiles p ON p.chorale_id = c.id AND p.role IN ('membre', 'admin')
LEFT JOIN chants ch ON ch.chorale_id = c.id
GROUP BY c.id, c.nom
ORDER BY nb_chants DESC, nb_membres DESC;

-- ============================================
-- RAPPORT 6 : Résumé global
-- ============================================

SELECT '📋 RAPPORT 6 : Résumé global' as rapport;

SELECT 
    'Total chorales' as metrique,
    COUNT(DISTINCT c.id)::TEXT as valeur
FROM chorales c

UNION ALL

SELECT 
    'Total membres (tous rôles)' as metrique,
    COUNT(*)::TEXT as valeur
FROM profiles

UNION ALL

SELECT 
    'Membres avec chorale' as metrique,
    COUNT(*)::TEXT as valeur
FROM profiles
WHERE chorale_id IS NOT NULL

UNION ALL

SELECT 
    'Membres sans chorale' as metrique,
    COUNT(*)::TEXT as valeur
FROM profiles
WHERE chorale_id IS NULL

UNION ALL

SELECT 
    'Membres validés' as metrique,
    COUNT(*)::TEXT as valeur
FROM profiles
WHERE statut_validation = 'valide'

UNION ALL

SELECT 
    'Membres en attente' as metrique,
    COUNT(*)::TEXT as valeur
FROM profiles
WHERE statut_validation = 'en_attente'

UNION ALL

SELECT 
    'Total chants' as metrique,
    COUNT(*)::TEXT as valeur
FROM chants

UNION ALL

SELECT 
    'Chorale la plus grande' as metrique,
    (
        SELECT c.nom || ' (' || COUNT(p.user_id)::TEXT || ' membres)'
        FROM chorales c
        LEFT JOIN profiles p ON p.chorale_id = c.id
        GROUP BY c.id, c.nom
        ORDER BY COUNT(p.user_id) DESC
        LIMIT 1
    ) as valeur;

-- ============================================
-- RAPPORT 7 : Actions recommandées
-- ============================================

SELECT '📋 RAPPORT 7 : Actions recommandées' as rapport;

-- Membres à attribuer à une chorale
SELECT 
    '❌ URGENT' as priorite,
    'Attribuer une chorale' as action,
    COUNT(*) as nb_concernes,
    STRING_AGG(p.full_name, ', ') as membres
FROM profiles p
WHERE p.chorale_id IS NULL
AND p.role = 'membre'
AND p.statut_validation = 'valide'
HAVING COUNT(*) > 0

UNION ALL

-- Membres en attente de validation
SELECT 
    '🟡 IMPORTANT' as priorite,
    'Valider les membres' as action,
    COUNT(*) as nb_concernes,
    STRING_AGG(p.full_name, ', ') as membres
FROM profiles p
WHERE p.statut_validation = 'en_attente'
HAVING COUNT(*) > 0

UNION ALL

-- Chorales sans admin
SELECT 
    '⚠️ ATTENTION' as priorite,
    'Attribuer un admin' as action,
    COUNT(DISTINCT c.id) as nb_concernes,
    STRING_AGG(DISTINCT c.nom, ', ') as chorales
FROM chorales c
LEFT JOIN profiles p ON p.chorale_id = c.id AND p.role = 'admin'
WHERE p.user_id IS NULL
HAVING COUNT(DISTINCT c.id) > 0

UNION ALL

-- Chorales sans chants
SELECT 
    '🔵 À FAIRE' as priorite,
    'Ajouter des chants' as action,
    COUNT(DISTINCT c.id) as nb_concernes,
    STRING_AGG(DISTINCT c.nom, ', ') as chorales
FROM chorales c
LEFT JOIN chants ch ON ch.chorale_id = c.id
WHERE ch.id IS NULL
HAVING COUNT(DISTINCT c.id) > 0;

-- ============================================
-- RÉSULTAT
-- ============================================

SELECT '✅✅✅ RAPPORT TERMINÉ ✅✅✅' as resultat;
SELECT 'Analysez les rapports ci-dessus pour gérer vos chorales' as note;
