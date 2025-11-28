-- =====================================================
-- DIAGNOSTIC: Vérifier les tables existantes
-- =====================================================
-- Ce script vérifie quelles tables existent déjà dans votre base Supabase

-- =====================================================
-- 1. LISTER TOUTES LES TABLES PUBLIQUES
-- =====================================================

SELECT 
    tablename,
    schemaname
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- =====================================================
-- 2. VÉRIFIER LES TABLES SPÉCIFIQUES
-- =====================================================

SELECT 
    table_name,
    CASE 
        WHEN table_name IN (
            SELECT tablename FROM pg_tables WHERE schemaname = 'public'
        ) THEN '✅ Existe'
        ELSE '❌ Manquante'
    END as statut
FROM (
    VALUES 
        ('profiles'),
        ('chants'),
        ('favoris'),
        ('playlists'),
        ('playlist_chants'),
        ('ecoutes'),
        ('chorales'),
        ('membres'),
        ('plans'),
        ('subscriptions')
) AS t(table_name)
ORDER BY table_name;

-- =====================================================
-- 3. VÉRIFIER RLS SUR LES TABLES EXISTANTES
-- =====================================================

SELECT 
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- =====================================================
-- 4. LISTER LES POLICIES RLS ACTIVES
-- =====================================================

SELECT 
    schemaname,
    tablename,
    policyname,
    cmd as operation
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- =====================================================
-- 5. COMPTER LES ENREGISTREMENTS DANS LES TABLES
-- =====================================================

-- Profiles (devrait exister)
SELECT 'profiles' as table_name, COUNT(*) as nb_records 
FROM profiles
UNION ALL
-- Chants (si existe)
SELECT 'chants' as table_name, COUNT(*) as nb_records 
FROM chants
WHERE EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'chants')
UNION ALL
-- Favoris (si existe)
SELECT 'favoris' as table_name, COUNT(*) as nb_records 
FROM favoris
WHERE EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'favoris')
UNION ALL
-- Playlists (si existe)
SELECT 'playlists' as table_name, COUNT(*) as nb_records 
FROM playlists
WHERE EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'playlists')
UNION ALL
-- Chorales (si existe)
SELECT 'chorales' as table_name, COUNT(*) as nb_records 
FROM chorales
WHERE EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'chorales')
UNION ALL
-- Plans (si existe)
SELECT 'plans' as table_name, COUNT(*) as nb_records 
FROM plans
WHERE EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'plans')
ORDER BY table_name;

-- =====================================================
-- INTERPRÉTATION DES RÉSULTATS
-- =====================================================

/*
SCÉNARIO 1: Seule la table "profiles" existe
→ Vous devez exécuter create_tables_no_rls.sql

SCÉNARIO 2: Les tables chorales, membres, plans existent
→ Vérifier si RLS est activé (rls_enabled = true)
→ Si oui, exécuter fix_all_rls.sql

SCÉNARIO 3: Toutes les tables existent avec RLS désactivé
→ Tout est bon ! Relancez juste l'app

SCÉNARIO 4: Les tables existent avec des policies RLS
→ Exécuter fix_all_rls.sql pour les désactiver
*/
