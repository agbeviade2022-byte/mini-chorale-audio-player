-- =====================================================
-- VÉRIFIER VOTRE COMPTE ET LES PROFILS
-- =====================================================

-- 1. Vérifier tous les comptes dans auth.users
SELECT 
    '👥 TOUS LES COMPTES' as info,
    id,
    email,
    email_confirmed_at,
    created_at,
    last_sign_in_at
FROM auth.users
ORDER BY created_at DESC;

-- 2. Vérifier spécifiquement votre compte
SELECT 
    '🔍 VOTRE COMPTE' as info,
    id,
    email,
    email_confirmed_at,
    created_at,
    last_sign_in_at
FROM auth.users
WHERE email = 'kodjodavid2025@gmail.com';

-- 3. Vérifier tous les profils (avec email depuis auth.users)
SELECT 
    '📋 TOUS LES PROFILS' as info,
    p.id,
    au.email,
    p.full_name,
    p.role,
    p.created_at
FROM profiles p
LEFT JOIN auth.users au ON p.id = au.id
ORDER BY p.created_at DESC;

-- 4. Vérifier si votre profil existe
SELECT 
    '🔍 VOTRE PROFIL' as info,
    p.id,
    au.email,
    p.full_name,
    p.role,
    p.created_at
FROM profiles p
LEFT JOIN auth.users au ON p.id = au.id
WHERE au.email = 'kodjodavid2025@gmail.com';

-- 5. Vérifier les admins système
SELECT 
    '🔐 ADMINS SYSTÈME' as info,
    sa.id,
    sa.user_id,
    sa.email,
    sa.role,
    sa.actif
FROM system_admins sa
ORDER BY created_at DESC;

-- 6. Vérifier les membres de chorales
SELECT 
    '🎵 MEMBRES DE CHORALES' as info,
    m.id,
    m.user_id,
    m.role as role_chorale,
    c.nom as chorale,
    au.email
FROM membres m
JOIN chorales c ON m.chorale_id = c.id
LEFT JOIN auth.users au ON m.user_id = au.id
ORDER BY m.created_at DESC;

-- =====================================================
-- DIAGNOSTIC
-- =====================================================
/*
INTERPRÉTATION:

1. Si vous voyez plusieurs comptes avec des emails différents:
   → Il y a plusieurs utilisateurs dans la base

2. Si votre compte kodjodavid2025@gmail.com existe mais le profil est différent:
   → Problème de synchronisation entre auth.users et profiles

3. Si vous voyez un autre email dans "last_sign_in_at":
   → Vous êtes connecté avec un autre compte

4. Si le profil n'existe pas pour kodjodavid2025@gmail.com:
   → Le profil n'a pas été créé automatiquement

SOLUTIONS:

A. Se déconnecter complètement:
   - Dans l'app: Se déconnecter
   - Vider le cache Hive
   - Se reconnecter avec kodjodavid2025@gmail.com

B. Créer le profil manuellement (si manquant):
   Voir le script fix_profil.sql

C. Supprimer les autres comptes (si nécessaire):
   Voir le script nettoyer_comptes.sql
*/
