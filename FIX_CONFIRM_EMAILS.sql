-- =====================================================
-- FIX : Confirmer tous les emails non confirmés
-- =====================================================
-- Permet aux utilisateurs de se connecter immédiatement
-- =====================================================

SELECT '📧 CONFIRMATION DES EMAILS' as info;

-- ============================================
-- ÉTAPE 1 : Voir les emails non confirmés
-- ============================================

SELECT '📋 ÉTAPE 1 : Emails non confirmés' as etape;

SELECT 
    au.id,
    au.email,
    au.created_at,
    au.email_confirmed_at,
    p.full_name,
    p.statut_validation,
    CASE 
        WHEN au.email_confirmed_at IS NULL THEN '❌ Non confirmé'
        ELSE '✅ Confirmé'
    END as statut_email
FROM auth.users au
LEFT JOIN profiles p ON au.id = p.user_id
ORDER BY au.created_at DESC;

-- ============================================
-- ÉTAPE 2 : Confirmer TOUS les emails
-- ============================================

SELECT '📋 ÉTAPE 2 : Confirmation de tous les emails' as etape;

-- Confirmer tous les emails non confirmés
UPDATE auth.users
SET 
    email_confirmed_at = COALESCE(email_confirmed_at, NOW()),
    updated_at = NOW()
WHERE email_confirmed_at IS NULL;

SELECT '✅ Emails confirmés' as status;

-- ============================================
-- ÉTAPE 3 : Vérification
-- ============================================

SELECT '📋 ÉTAPE 3 : Vérification' as etape;

-- Compter les emails
SELECT 
    COUNT(*) as total_utilisateurs,
    COUNT(email_confirmed_at) as emails_confirmes,
    COUNT(*) - COUNT(email_confirmed_at) as emails_non_confirmes,
    CASE 
        WHEN COUNT(*) = COUNT(email_confirmed_at) THEN '✅ Tous les emails sont confirmés'
        ELSE '⚠️ Il reste des emails non confirmés'
    END as statut
FROM auth.users;

-- Liste des utilisateurs avec leur statut
SELECT 
    au.email,
    au.email_confirmed_at,
    p.full_name,
    p.statut_validation,
    p.role,
    CASE 
        WHEN au.email_confirmed_at IS NOT NULL THEN '✅ Email confirmé'
        ELSE '❌ Email non confirmé'
    END as statut_email,
    CASE 
        WHEN p.statut_validation = 'valide' THEN '✅ Membre validé'
        WHEN p.statut_validation = 'en_attente' THEN '⏳ En attente'
        WHEN p.statut_validation = 'refuse' THEN '❌ Refusé'
        ELSE '⚠️ Statut inconnu'
    END as statut_validation_texte
FROM auth.users au
LEFT JOIN profiles p ON au.id = p.user_id
ORDER BY au.created_at DESC;

-- ============================================
-- RÉSULTAT
-- ============================================

SELECT '✅✅✅ CONFIRMATION TERMINÉE ✅✅✅' as resultat;
SELECT 'Tous les utilisateurs peuvent maintenant se connecter' as note;
SELECT '⚠️ Pour désactiver la confirmation d''email pour les futurs utilisateurs:' as important;
SELECT 'Supabase Dashboard → Authentication → Settings → Email Confirmation → OFF' as action;
