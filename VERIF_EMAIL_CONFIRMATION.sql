-- =====================================================
-- VÉRIFICATION : Email confirmation à l'inscription
-- =====================================================

SELECT '🔍 VÉRIFICATION : Email confirmation' as titre;

-- ============================================
-- 1. Vérifier les utilisateurs sans email confirmé
-- ============================================

SELECT '📋 1. Utilisateurs sans email confirmé' as section;

SELECT 
    id,
    email,
    email_confirmed_at,
    created_at,
    CASE 
        WHEN email_confirmed_at IS NOT NULL THEN '✅ Email confirmé'
        ELSE '❌ Email non confirmé'
    END as statut_email,
    CASE 
        WHEN email_confirmed_at IS NULL THEN '⚠️ Utilisateur peut se connecter sans confirmer'
        ELSE '✅ OK'
    END as alerte
FROM auth.users
ORDER BY created_at DESC;

-- ============================================
-- 2. Statistiques de confirmation d'email
-- ============================================

SELECT '📋 2. Statistiques' as section;

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
    'Emails non confirmés' as element,
    COUNT(*)::text as valeur
FROM auth.users
WHERE email_confirmed_at IS NULL

UNION ALL

SELECT 
    'Pourcentage confirmés' as element,
    ROUND(
        (COUNT(*) FILTER (WHERE email_confirmed_at IS NOT NULL)::numeric / 
         NULLIF(COUNT(*), 0) * 100), 2
    )::text || '%' as valeur
FROM auth.users;

-- ============================================
-- 3. Vérifier les profils liés aux emails non confirmés
-- ============================================

SELECT '📋 3. Profils avec email non confirmé' as section;

SELECT 
    p.id as profile_id,
    p.user_id,
    au.email,
    au.email_confirmed_at,
    p.full_name,
    p.role,
    p.statut_validation,
    CASE 
        WHEN au.email_confirmed_at IS NULL THEN '⚠️ Email non confirmé mais profil actif'
        ELSE '✅ OK'
    END as alerte
FROM profiles p
INNER JOIN auth.users au ON p.user_id = au.id
WHERE au.email_confirmed_at IS NULL;

-- ============================================
-- 4. Recommandations
-- ============================================

SELECT '📋 4. Recommandations' as section;

SELECT 
    CASE 
        WHEN (SELECT COUNT(*) FROM auth.users WHERE email_confirmed_at IS NULL) > 0 
        THEN '⚠️ ATTENTION: Des utilisateurs peuvent se connecter sans confirmer leur email'
        ELSE '✅ Tous les emails sont confirmés'
    END as statut,
    CASE 
        WHEN (SELECT COUNT(*) FROM auth.users WHERE email_confirmed_at IS NULL) > 0 
        THEN 'Activez la confirmation d''email obligatoire dans Supabase Dashboard > Authentication > Settings'
        ELSE 'Configuration correcte'
    END as action_recommandee;

-- ============================================
-- RÉSULTAT
-- ============================================

SELECT '✅ VÉRIFICATION TERMINÉE' as resultat;
SELECT 'Vérifiez les alertes ci-dessus' as note;
