-- =====================================================
-- CRÉER UN UTILISATEUR ADMIN POUR TESTER LES PERMISSIONS
-- =====================================================

SELECT '🔧 CRÉATION : Utilisateur admin de test' as info;

-- ⚠️⚠️⚠️ REMPLACEZ L'EMAIL ICI ⚠️⚠️⚠️
DO $$
DECLARE
    test_email TEXT := 'admin.test@chorale.com';  -- 👈 CHANGEZ ICI
    test_user_id UUID;
BEGIN
    -- Stocker l'email dans une variable de session temporaire
    PERFORM set_config('app.test_email', test_email, true);
END $$;

-- ============================================
-- OPTION 1 : Changer le rôle d'un utilisateur existant
-- ============================================

SELECT '📋 OPTION 1 : Changer le rôle d''un utilisateur existant' as section;

-- Afficher les utilisateurs actuels
SELECT 
    p.user_id,
    au.email,
    p.full_name,
    p.role,
    CASE 
        WHEN p.role = 'super_admin' THEN '🔴 Super Admin (toutes permissions)'
        WHEN p.role = 'admin' THEN '🟠 Admin (permissions personnalisables)'
        WHEN p.role = 'membre' THEN '🟢 Membre (aucune permission admin)'
        ELSE '⚪ Autre'
    END as description
FROM profiles p
INNER JOIN auth.users au ON p.user_id = au.id
ORDER BY p.role;

-- ============================================
-- MÉTHODE A : Changer AGREVIADE en admin (pour tester)
-- ============================================

SELECT '📋 MÉTHODE A : Changer AGREVIADE en admin' as methode;

-- ⚠️ DÉCOMMENTEZ CETTE LIGNE POUR CHANGER LE RÔLE
-- UPDATE profiles 
-- SET role = 'admin'
-- WHERE user_id = (
--     SELECT id FROM auth.users WHERE email = 'agbeviade2017@gmail.com'
-- );

-- Vérifier le changement
-- SELECT 
--     au.email,
--     p.full_name,
--     p.role
-- FROM profiles p
-- INNER JOIN auth.users au ON p.user_id = au.id
-- WHERE au.email = 'agbeviade2017@gmail.com';

-- ============================================
-- MÉTHODE B : Créer un nouvel utilisateur admin
-- ============================================

SELECT '📋 MÉTHODE B : Créer un nouvel utilisateur admin' as methode;

-- ⚠️ IMPORTANT : Vous devez créer l'utilisateur via l'application Flutter d'abord
-- Puis exécutez cette requête pour changer son rôle en 'admin'

-- Exemple : Changer le rôle d'un utilisateur par son email
-- UPDATE profiles 
-- SET role = 'admin'
-- WHERE user_id = (
--     SELECT id FROM auth.users WHERE email = 'VOTRE_EMAIL_ICI@example.com'
-- );

-- ============================================
-- OPTION 2 : Créer des permissions de test
-- ============================================

SELECT '📋 OPTION 2 : Attribuer des permissions à AGREVIADE (test)' as section;

-- Récupérer le user_id d'AGREVIADE
DO $$
DECLARE
    agreviade_user_id UUID;
BEGIN
    SELECT user_id INTO agreviade_user_id
    FROM profiles p
    INNER JOIN auth.users au ON p.user_id = au.id
    WHERE au.email = 'agbeviade2017@gmail.com';
    
    IF agreviade_user_id IS NOT NULL THEN
        -- Supprimer les permissions existantes
        DELETE FROM user_permissions WHERE user_id = agreviade_user_id;
        
        -- Ajouter quelques permissions de test
        INSERT INTO user_permissions (user_id, module_code)
        VALUES 
            (agreviade_user_id, 'add_chants'),
            (agreviade_user_id, 'view_members')
        ON CONFLICT DO NOTHING;
        
        RAISE NOTICE '✅ Permissions de test ajoutées pour AGREVIADE';
    ELSE
        RAISE NOTICE '❌ AGREVIADE non trouvé';
    END IF;
END $$;

-- ============================================
-- VÉRIFICATION
-- ============================================

SELECT '📋 VÉRIFICATION : Permissions actuelles' as section;

-- Afficher les permissions de tous les utilisateurs
SELECT 
    au.email,
    p.full_name,
    p.role,
    COALESCE(
        (
            SELECT string_agg(module_code, ', ')
            FROM user_permissions up
            WHERE up.user_id = p.user_id
        ),
        'Aucune permission spécifique'
    ) as permissions
FROM profiles p
INNER JOIN auth.users au ON p.user_id = au.id
ORDER BY p.role, p.full_name;

-- ============================================
-- GUIDE D'UTILISATION
-- ============================================

SELECT '📋 GUIDE : Comment tester les permissions' as guide;

SELECT '
POUR TESTER LES PERMISSIONS, VOUS AVEZ 3 OPTIONS :

1️⃣ OPTION 1 : Changer temporairement AGREVIADE en admin
   - Décommentez la ligne UPDATE dans "MÉTHODE A"
   - Exécutez le script
   - Rafraîchissez le dashboard
   - Les boutons seront cliquables
   - Remettez en super_admin après les tests

2️⃣ OPTION 2 : Créer un nouvel utilisateur admin
   - Inscrivez un nouvel utilisateur via l''app Flutter
   - Validez-le en tant qu''admin
   - Changez son rôle en "admin" avec MÉTHODE B
   - Connectez-vous avec ce compte dans le dashboard

3️⃣ OPTION 3 : Garder les super_admins
   - Les super_admins ont toutes les permissions automatiquement
   - C''est le comportement normal
   - Pas besoin de gérer les permissions individuellement

RECOMMANDATION :
- Gardez au moins 1 super_admin (vous)
- Créez des comptes "admin" pour les autres administrateurs
- Utilisez les permissions pour contrôler ce que chaque admin peut faire
' as instructions;

-- ============================================
-- RÉSULTAT
-- ============================================

SELECT '✅ SCRIPT TERMINÉ' as resultat;
SELECT 'Choisissez une option ci-dessus et décommentez le code correspondant' as action;
