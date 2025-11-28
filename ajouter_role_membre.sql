-- =====================================================
-- AJOUTER LE RÔLE 'membre' À LA CONTRAINTE
-- =====================================================
-- Permet d'utiliser le rôle 'membre' dans la table profiles
-- =====================================================

-- =====================================================
-- 1. VÉRIFIER LA CONTRAINTE ACTUELLE
-- =====================================================

SELECT 
    '📋 CONTRAINTE ACTUELLE' as info,
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint
WHERE conname = 'profiles_role_check';

-- =====================================================
-- 2. SUPPRIMER L'ANCIENNE CONTRAINTE
-- =====================================================

ALTER TABLE profiles 
DROP CONSTRAINT IF EXISTS profiles_role_check;

-- =====================================================
-- 3. CRÉER LA NOUVELLE CONTRAINTE AVEC 'membre'
-- =====================================================

ALTER TABLE profiles
ADD CONSTRAINT profiles_role_check 
CHECK (role IN ('user', 'membre', 'admin', 'super_admin'));

-- =====================================================
-- 4. VÉRIFIER LA NOUVELLE CONTRAINTE
-- =====================================================

SELECT 
    '✅ NOUVELLE CONTRAINTE' as info,
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint
WHERE conname = 'profiles_role_check';

-- =====================================================
-- 5. TESTER LES RÔLES AUTORISÉS
-- =====================================================

-- Test: Créer un profil temporaire avec chaque rôle
DO $$
DECLARE
    v_test_id UUID;
BEGIN
    -- Test rôle 'user'
    v_test_id := gen_random_uuid();
    INSERT INTO profiles (id, full_name, role) VALUES (v_test_id, 'Test User', 'user');
    DELETE FROM profiles WHERE id = v_test_id;
    RAISE NOTICE '✅ Rôle "user" autorisé';
    
    -- Test rôle 'membre'
    v_test_id := gen_random_uuid();
    INSERT INTO profiles (id, full_name, role) VALUES (v_test_id, 'Test Membre', 'membre');
    DELETE FROM profiles WHERE id = v_test_id;
    RAISE NOTICE '✅ Rôle "membre" autorisé';
    
    -- Test rôle 'admin'
    v_test_id := gen_random_uuid();
    INSERT INTO profiles (id, full_name, role) VALUES (v_test_id, 'Test Admin', 'admin');
    DELETE FROM profiles WHERE id = v_test_id;
    RAISE NOTICE '✅ Rôle "admin" autorisé';
    
    -- Test rôle 'super_admin'
    v_test_id := gen_random_uuid();
    INSERT INTO profiles (id, full_name, role) VALUES (v_test_id, 'Test Super Admin', 'super_admin');
    DELETE FROM profiles WHERE id = v_test_id;
    RAISE NOTICE '✅ Rôle "super_admin" autorisé';
    
    RAISE NOTICE '🎉 Tous les rôles sont autorisés !';
END $$;

-- =====================================================
-- RÉSULTAT ATTENDU
-- =====================================================
-- ✅ Contrainte profiles_role_check modifiée
-- ✅ Rôles autorisés: user, membre, admin, super_admin
-- ✅ Tous les tests passent
-- =====================================================
