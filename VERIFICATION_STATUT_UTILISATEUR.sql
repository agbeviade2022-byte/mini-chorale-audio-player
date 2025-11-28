-- =====================================================
-- VÉRIFICATION : Statut utilisateur
-- =====================================================

SELECT '🔍 VÉRIFICATION STATUT UTILISATEUR' as info;

-- ============================================
-- ÉTAPE 1 : Vérifier tous les utilisateurs
-- ============================================

SELECT '📋 ÉTAPE 1 : Liste complète des utilisateurs' as etape;

SELECT 
    au.id as user_id,
    au.email,
    au.email_confirmed_at,
    au.created_at as compte_cree_le,
    p.full_name,
    p.statut_validation,
    p.statut_membre,
    p.role,
    c.nom as chorale,
    CASE 
        WHEN au.email_confirmed_at IS NULL THEN '❌ Email non confirmé'
        ELSE '✅ Email confirmé'
    END as statut_email,
    CASE 
        WHEN p.statut_validation = 'valide' THEN '✅ Validé - Peut se connecter'
        WHEN p.statut_validation = 'en_attente' THEN '⏳ En attente - Doit attendre validation Super Admin'
        WHEN p.statut_validation = 'refuse' THEN '❌ Refusé - Ne peut pas se connecter'
        ELSE '⚠️ Statut inconnu'
    END as statut_connexion
FROM auth.users au
LEFT JOIN profiles p ON au.id = p.user_id
LEFT JOIN chorales c ON p.chorale_id = c.id
ORDER BY au.created_at DESC;

-- ============================================
-- ÉTAPE 2 : Compter par statut
-- ============================================

SELECT '📋 ÉTAPE 2 : Répartition par statut' as etape;

SELECT 
    p.statut_validation,
    COUNT(*) as nombre,
    CASE 
        WHEN p.statut_validation = 'valide' THEN '✅ Peuvent se connecter'
        WHEN p.statut_validation = 'en_attente' THEN '⏳ Doivent attendre validation'
        WHEN p.statut_validation = 'refuse' THEN '❌ Bloqués'
    END as description
FROM profiles p
GROUP BY p.statut_validation
ORDER BY 
    CASE p.statut_validation
        WHEN 'valide' THEN 1
        WHEN 'en_attente' THEN 2
        WHEN 'refuse' THEN 3
    END;

-- ============================================
-- ÉTAPE 3 : Vérifier les emails confirmés mais non validés
-- ============================================

SELECT '📋 ÉTAPE 3 : Emails confirmés mais en attente de validation' as etape;

SELECT 
    au.email,
    p.full_name,
    au.email_confirmed_at,
    p.statut_validation,
    EXTRACT(DAY FROM (NOW() - p.created_at))::INTEGER as jours_attente,
    '⏳ Email confirmé mais attend validation Super Admin' as statut
FROM auth.users au
JOIN profiles p ON au.id = p.user_id
WHERE au.email_confirmed_at IS NOT NULL
AND p.statut_validation = 'en_attente'
ORDER BY p.created_at ASC;

-- Compter
SELECT 
    COUNT(*) as nombre,
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ Aucun utilisateur en attente avec email confirmé'
        WHEN COUNT(*) = 1 THEN '⏳ 1 utilisateur attend la validation du Super Admin'
        ELSE '⏳ ' || COUNT(*) || ' utilisateurs attendent la validation du Super Admin'
    END as statut
FROM auth.users au
JOIN profiles p ON au.id = p.user_id
WHERE au.email_confirmed_at IS NOT NULL
AND p.statut_validation = 'en_attente';

-- ============================================
-- ÉTAPE 4 : Flux de validation expliqué
-- ============================================

SELECT '📋 ÉTAPE 4 : Flux de validation' as etape;

SELECT 
    'FLUX DE VALIDATION' as titre,
    '1. Utilisateur s''inscrit dans Flutter' as etape_1,
    '2. Email confirmé (automatique ou manuel)' as etape_2,
    '3. Profil créé avec statut_validation = en_attente' as etape_3,
    '4. Utilisateur essaie de se connecter → Bloqué' as etape_4,
    '5. Super Admin valide dans le dashboard' as etape_5,
    '6. statut_validation passe à valide' as etape_6,
    '7. Utilisateur peut maintenant se connecter' as etape_7;

-- ============================================
-- RÉSUMÉ
-- ============================================

SELECT '📊 RÉSUMÉ' as info;

SELECT 
    'Total utilisateurs' as element,
    COUNT(*)::text as valeur
FROM auth.users
UNION ALL
SELECT 
    'Emails confirmés' as element,
    COUNT(*)::text as valeur
FROM auth.users
WHERE email_confirmed_at IS NOT NULL
UNION ALL
SELECT 
    'Membres validés' as element,
    COUNT(*)::text as valeur
FROM profiles
WHERE statut_validation = 'valide'
UNION ALL
SELECT 
    'Membres en attente' as element,
    COUNT(*)::text as valeur
FROM profiles
WHERE statut_validation = 'en_attente'
UNION ALL
SELECT 
    'Membres refusés' as element,
    COUNT(*)::text as valeur
FROM profiles
WHERE statut_validation = 'refuse';

-- ============================================
-- ACTION À FAIRE
-- ============================================

SELECT '💡 ACTION À FAIRE' as info;

SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM profiles 
            WHERE statut_validation = 'en_attente'
        )
        THEN '⏳ Aller dans le dashboard → Validation des membres → Valider les membres en attente'
        ELSE '✅ Aucun membre en attente de validation'
    END as action;
