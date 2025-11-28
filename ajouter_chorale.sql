-- =====================================================
-- SCRIPT : AJOUTER UNE NOUVELLE CHORALE
-- =====================================================
-- Utilisez ce script pour ajouter manuellement des chorales
-- dans la base de données Supabase
-- =====================================================

-- =====================================================
-- EXEMPLE 1 : Ajouter une chorale simple
-- =====================================================

INSERT INTO chorales (nom, slug, description, statut)
VALUES (
    'Nom de la Chorale',           -- Nom complet de la chorale
    'nom-de-la-chorale',           -- Slug (URL-friendly, sans espaces ni accents)
    'Description de la chorale',   -- Description (optionnel)
    'actif'                        -- Statut : 'actif' ou 'inactif'
)
ON CONFLICT (slug) DO NOTHING;

-- =====================================================
-- EXEMPLE 2 : Ajouter une chorale avec toutes les infos
-- =====================================================

INSERT INTO chorales (
    nom, 
    slug, 
    description, 
    couleur_theme,
    email_contact,
    telephone,
    adresse,
    ville,
    pays,
    site_web,
    statut
)
VALUES (
    'Chorale Saint-Michel',                    -- Nom
    'chorale-saint-michel',                    -- Slug
    'Chorale paroissiale de Saint-Michel',    -- Description
    '#6366F1',                                 -- Couleur (format hex)
    'contact@chorale-saint-michel.fr',        -- Email
    '+33 1 23 45 67 89',                      -- Téléphone
    '12 Rue de l''Église',                    -- Adresse
    'Paris',                                   -- Ville
    'France',                                  -- Pays
    'https://chorale-saint-michel.fr',        -- Site web
    'actif'                                    -- Statut
)
ON CONFLICT (slug) DO NOTHING;

-- =====================================================
-- EXEMPLES DE CHORALES À AJOUTER
-- =====================================================

-- Chorale 1
INSERT INTO chorales (nom, slug, description, ville, pays, statut)
VALUES ('Chorale des Anges', 'chorale-des-anges', 'Chorale gospel', 'Lyon', 'France', 'actif')
ON CONFLICT (slug) DO NOTHING;

-- Chorale 2
INSERT INTO chorales (nom, slug, description, ville, pays, statut)
VALUES ('Harmonie Vocale', 'harmonie-vocale', 'Chorale classique', 'Marseille', 'France', 'actif')
ON CONFLICT (slug) DO NOTHING;

-- Chorale 3
INSERT INTO chorales (nom, slug, description, ville, pays, statut)
VALUES ('Voix d''Espoir', 'voix-espoir', 'Chorale contemporaine', 'Toulouse', 'France', 'actif')
ON CONFLICT (slug) DO NOTHING;

-- Chorale 4
INSERT INTO chorales (nom, slug, description, ville, pays, statut)
VALUES ('Chœur Céleste', 'choeur-celeste', 'Chorale liturgique', 'Bordeaux', 'France', 'actif')
ON CONFLICT (slug) DO NOTHING;

-- Chorale 5
INSERT INTO chorales (nom, slug, description, ville, pays, statut)
VALUES ('Cantique Nouveau', 'cantique-nouveau', 'Chorale de louange', 'Lille', 'France', 'actif')
ON CONFLICT (slug) DO NOTHING;

-- =====================================================
-- VÉRIFICATION : Lister toutes les chorales
-- =====================================================

SELECT 
    id,
    nom,
    slug,
    ville,
    nombre_membres,
    statut,
    created_at
FROM chorales
ORDER BY nom;

-- =====================================================
-- MODIFIER UNE CHORALE EXISTANTE
-- =====================================================

-- Exemple : Modifier la description
UPDATE chorales
SET description = 'Nouvelle description',
    updated_at = NOW()
WHERE slug = 'nom-de-la-chorale';

-- Exemple : Changer le statut
UPDATE chorales
SET statut = 'inactif',
    updated_at = NOW()
WHERE slug = 'nom-de-la-chorale';

-- =====================================================
-- SUPPRIMER UNE CHORALE (ATTENTION !)
-- =====================================================

-- ⚠️ ATTENTION : Cela supprimera aussi tous les membres !
-- Réassignez d'abord les membres à une autre chorale :

-- Étape 1 : Réassigner les membres
UPDATE profiles
SET chorale_id = (SELECT id FROM chorales WHERE slug = 'chorale-principale')
WHERE chorale_id = (SELECT id FROM chorales WHERE slug = 'chorale-a-supprimer');

-- Étape 2 : Supprimer la chorale
DELETE FROM chorales
WHERE slug = 'chorale-a-supprimer';

-- =====================================================
-- STATISTIQUES DES CHORALES
-- =====================================================

SELECT 
    c.nom as chorale,
    c.ville,
    c.nombre_membres,
    COUNT(p.id) as membres_reels,
    c.statut
FROM chorales c
LEFT JOIN profiles p ON p.chorale_id = c.id
GROUP BY c.id, c.nom, c.ville, c.nombre_membres, c.statut
ORDER BY c.nombre_membres DESC;

-- =====================================================
-- FIN DU SCRIPT
-- =====================================================
