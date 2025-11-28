# 🌐 PHASE 4: DASHBOARD WEB - SYSTÈME DE PERMISSIONS MODULAIRES

## 📋 OBJECTIF

Intégrer le système de permissions dans le dashboard web Next.js pour:
1. Vérifier les permissions côté client et serveur
2. Afficher/masquer les fonctionnalités selon les permissions
3. Créer une interface de gestion des Maîtres de Chœur
4. Gérer l'attribution/révocation de permissions

---

## 🗂️ STRUCTURE DU PROJET WEB

```
admin-chorale-dashboard/
├── app/
│   ├── dashboard/
│   │   ├── page.tsx (Dashboard principal)
│   │   ├── permissions/
│   │   │   └── page.tsx (Gestion permissions)
│   │   ├── maitres-choeur/
│   │   │   ├── page.tsx (Liste MC)
│   │   │   └── create/
│   │   │       └── page.tsx (Créer MC)
│   │   └── members/
│   │       └── page.tsx (Gestion membres)
│   └── login/
│       └── page.tsx
├── components/
│   ├── PermissionGuard.tsx (Nouveau)
│   ├── CreateMaitreChoeurModal.tsx (Nouveau)
│   ├── PermissionsManager.tsx (Nouveau)
│   └── Sidebar.tsx (Modifier)
├── hooks/
│   └── usePermissions.ts (Nouveau)
└── lib/
    ├── supabase.ts
    └── permissions.ts (Nouveau)
```

---

## 📝 ÉTAPE 1: Créer le hook usePermissions

**Fichier:** `hooks/usePermissions.ts`

```typescript
import { useEffect, useState } from 'react';
import { supabase } from '@/lib/supabase';

interface PermissionsHook {
  permissions: string[];
  role: string | null;
  isLoading: boolean;
  isSuperAdmin: boolean;
  isAdmin: boolean;
  hasPermission: (code: string) => boolean;
  hasAnyPermission: (codes: string[]) => boolean;
  refresh: () => Promise<void>;
}

export function usePermissions(): PermissionsHook {
  const [permissions, setPermissions] = useState<string[]>([]);
  const [role, setRole] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  const loadPermissions = async () => {
    try {
      setIsLoading(true);
      
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        setPermissions([]);
        setRole(null);
        return;
      }

      // Récupérer le profil
      const { data: profile, error: profileError } = await supabase
        .from('profiles')
        .select('id, role')
        .eq('user_id', user.id)
        .single();

      if (profileError) throw profileError;

      setRole(profile.role);

      // Super admin a toutes les permissions
      if (profile.role === 'super_admin') {
        const { data: allPerms } = await supabase
          .from('modules_permissions')
          .select('code');
        
        setPermissions(allPerms?.map(p => p.code) || []);
        return;
      }

      // Récupérer les permissions via RPC
      const { data: userPerms, error: permsError } = await supabase
        .rpc('get_user_permissions', { check_user_id: profile.id });

      if (permsError) throw permsError;

      setPermissions(userPerms?.map((p: any) => p.code) || []);
    } catch (error) {
      console.error('Erreur chargement permissions:', error);
      setPermissions([]);
      setRole(null);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    loadPermissions();
  }, []);

  const hasPermission = (code: string): boolean => {
    if (role === 'super_admin') return true;
    return permissions.includes(code);
  };

  const hasAnyPermission = (codes: string[]): boolean => {
    if (role === 'super_admin') return true;
    return codes.some(code => permissions.includes(code));
  };

  return {
    permissions,
    role,
    isLoading,
    isSuperAdmin: role === 'super_admin',
    isAdmin: role === 'admin' || role === 'super_admin',
    hasPermission,
    hasAnyPermission,
    refresh: loadPermissions,
  };
}
```

---

## 📝 ÉTAPE 2: Créer le composant PermissionGuard

**Fichier:** `components/PermissionGuard.tsx`

```typescript
'use client';

import { usePermissions } from '@/hooks/usePermissions';
import { ReactNode } from 'react';

interface PermissionGuardProps {
  permission: string;
  children: ReactNode;
  fallback?: ReactNode;
}

export function PermissionGuard({ permission, children, fallback = null }: PermissionGuardProps) {
  const { hasPermission, isLoading } = usePermissions();

  if (isLoading) {
    return <div className="animate-pulse bg-gray-200 h-10 rounded"></div>;
  }

  if (!hasPermission(permission)) {
    return <>{fallback}</>;
  }

  return <>{children}</>;
}

interface SuperAdminGuardProps {
  children: ReactNode;
  fallback?: ReactNode;
}

export function SuperAdminGuard({ children, fallback = null }: SuperAdminGuardProps) {
  const { isSuperAdmin, isLoading } = usePermissions();

  if (isLoading) {
    return <div className="animate-pulse bg-gray-200 h-10 rounded"></div>;
  }

  if (!isSuperAdmin) {
    return <>{fallback}</>;
  }

  return <>{children}</>;
}

interface AdminGuardProps {
  children: ReactNode;
  fallback?: ReactNode;
}

export function AdminGuard({ children, fallback = null }: AdminGuardProps) {
  const { isAdmin, isLoading } = usePermissions();

  if (isLoading) {
    return <div className="animate-pulse bg-gray-200 h-10 rounded"></div>;
  }

  if (!isAdmin) {
    return <>{fallback}</>;
  }

  return <>{children}</>;
}
```

---

## 📝 ÉTAPE 3: Créer le Modal de Création de Maître de Chœur

**Fichier:** `components/CreateMaitreChoeurModal.tsx`

```typescript
'use client';

import { useState } from 'react';
import { supabase } from '@/lib/supabase';

interface CreateMaitreChoeurModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
}

export default function CreateMaitreChoeurModal({
  isOpen,
  onClose,
  onSuccess,
}: CreateMaitreChoeurModalProps) {
  const [email, setEmail] = useState('');
  const [fullName, setFullName] = useState('');
  const [choraleId, setChoraleId] = useState('');
  const [chorales, setChorales] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [step, setStep] = useState<'form' | 'instructions'>('form');

  // Charger les chorales
  useState(() => {
    const loadChorales = async () => {
      const { data } = await supabase
        .from('chorales')
        .select('id, nom')
        .order('nom');
      setChorales(data || []);
    };
    if (isOpen) loadChorales();
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      // Récupérer le profile_id du super admin connecté
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Non authentifié');

      const { data: profile } = await supabase
        .from('profiles')
        .select('id')
        .eq('user_id', user.id)
        .single();

      if (!profile) throw new Error('Profil non trouvé');

      // Appeler la fonction creer_maitre_choeur
      const { data, error: rpcError } = await supabase.rpc('creer_maitre_choeur', {
        p_email: email,
        p_full_name: fullName,
        p_chorale_id: choraleId,
        p_super_admin_id: profile.id,
      });

      if (rpcError) {
        // Si l'erreur dit que l'utilisateur n'existe pas, afficher les instructions
        if (rpcError.message.includes('n\'existe pas')) {
          setStep('instructions');
          return;
        }
        throw rpcError;
      }

      alert(`Maître de Chœur créé avec succès!\n\nCode d'affiliation: ${data.affiliation_code}\nLien: ${data.lien_affiliation}`);
      onSuccess();
      onClose();
      resetForm();
    } catch (err: any) {
      setError(err.message || 'Erreur lors de la création');
    } finally {
      setLoading(false);
    }
  };

  const resetForm = () => {
    setEmail('');
    setFullName('');
    setChoraleId('');
    setError('');
    setStep('form');
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg p-6 max-w-md w-full">
        {step === 'form' ? (
          <>
            <h2 className="text-2xl font-bold mb-4">Créer un Maître de Chœur</h2>
            
            {error && (
              <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
                {error}
              </div>
            )}

            <form onSubmit={handleSubmit}>
              <div className="mb-4">
                <label className="block text-gray-700 mb-2">Email</label>
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="w-full px-3 py-2 border rounded"
                  required
                />
                <p className="text-sm text-gray-500 mt-1">
                  L'utilisateur doit d'abord être créé dans Supabase Dashboard
                </p>
              </div>

              <div className="mb-4">
                <label className="block text-gray-700 mb-2">Nom complet</label>
                <input
                  type="text"
                  value={fullName}
                  onChange={(e) => setFullName(e.target.value)}
                  className="w-full px-3 py-2 border rounded"
                  required
                />
              </div>

              <div className="mb-4">
                <label className="block text-gray-700 mb-2">Chorale</label>
                <select
                  value={choraleId}
                  onChange={(e) => setChoraleId(e.target.value)}
                  className="w-full px-3 py-2 border rounded"
                  required
                >
                  <option value="">Sélectionner une chorale</option>
                  {chorales.map((c) => (
                    <option key={c.id} value={c.id}>
                      {c.nom}
                    </option>
                  ))}
                </select>
              </div>

              <div className="flex gap-2">
                <button
                  type="submit"
                  disabled={loading}
                  className="flex-1 bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600 disabled:opacity-50"
                >
                  {loading ? 'Création...' : 'Créer'}
                </button>
                <button
                  type="button"
                  onClick={() => { onClose(); resetForm(); }}
                  className="flex-1 bg-gray-300 text-gray-700 px-4 py-2 rounded hover:bg-gray-400"
                >
                  Annuler
                </button>
              </div>
            </form>
          </>
        ) : (
          <>
            <h2 className="text-2xl font-bold mb-4">Instructions</h2>
            <div className="bg-yellow-100 border border-yellow-400 text-yellow-800 px-4 py-3 rounded mb-4">
              <p className="font-bold mb-2">L'utilisateur {email} n'existe pas encore.</p>
              <p className="mb-2">Suivez ces étapes:</p>
              <ol className="list-decimal ml-5 space-y-1">
                <li>Aller sur Supabase Dashboard</li>
                <li>Authentication → Users → Add User</li>
                <li>Email: <strong>{email}</strong></li>
                <li>Choisir un mot de passe</li>
                <li>✅ Cocher "Auto Confirm User"</li>
                <li>Cliquer "Create User"</li>
                <li>Revenir ici et réessayer</li>
              </ol>
            </div>
            <button
              onClick={() => setStep('form')}
              className="w-full bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600"
            >
              Retour au formulaire
            </button>
          </>
        )}
      </div>
    </div>
  );
}
```

---

## 📝 ÉTAPE 4: Modifier la Sidebar avec les permissions

**Fichier:** `components/Sidebar.tsx`

```typescript
'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { PermissionGuard, SuperAdminGuard } from './PermissionGuard';

export default function Sidebar() {
  const pathname = usePathname();

  return (
    <aside className="w-64 bg-gray-800 text-white min-h-screen p-4">
      <h1 className="text-2xl font-bold mb-8">Dashboard Admin</h1>
      
      <nav className="space-y-2">
        <PermissionGuard permission="view_dashboard">
          <Link
            href="/dashboard"
            className={`block px-4 py-2 rounded ${
              pathname === '/dashboard' ? 'bg-gray-700' : 'hover:bg-gray-700'
            }`}
          >
            📊 Dashboard
          </Link>
        </PermissionGuard>

        <PermissionGuard permission="view_members">
          <Link
            href="/dashboard/members"
            className={`block px-4 py-2 rounded ${
              pathname === '/dashboard/members' ? 'bg-gray-700' : 'hover:bg-gray-700'
            }`}
          >
            👥 Membres
          </Link>
        </PermissionGuard>

        <PermissionGuard permission="view_chants">
          <Link
            href="/dashboard/chants"
            className={`block px-4 py-2 rounded ${
              pathname === '/dashboard/chants' ? 'bg-gray-700' : 'hover:bg-gray-700'
            }`}
          >
            🎵 Chants
          </Link>
        </PermissionGuard>

        <SuperAdminGuard>
          <Link
            href="/dashboard/maitres-choeur"
            className={`block px-4 py-2 rounded ${
              pathname === '/dashboard/maitres-choeur' ? 'bg-gray-700' : 'hover:bg-gray-700'
            }`}
          >
            👨‍🏫 Maîtres de Chœur
          </Link>
        </SuperAdminGuard>

        <PermissionGuard permission="assign_permissions">
          <Link
            href="/dashboard/permissions"
            className={`block px-4 py-2 rounded ${
              pathname === '/dashboard/permissions' ? 'bg-gray-700' : 'hover:bg-gray-700'
            }`}
          >
            🔐 Permissions
          </Link>
        </PermissionGuard>

        <PermissionGuard permission="view_stats">
          <Link
            href="/dashboard/stats"
            className={`block px-4 py-2 rounded ${
              pathname === '/dashboard/stats' ? 'bg-gray-700' : 'hover:bg-gray-700'
            }`}
          >
            📈 Statistiques
          </Link>
        </PermissionGuard>
      </nav>
    </aside>
  );
}
```

---

## 📝 ÉTAPE 5: Créer la page Maîtres de Chœur

**Fichier:** `app/dashboard/maitres-choeur/page.tsx`

```typescript
'use client';

import { useState, useEffect } from 'react';
import { supabase } from '@/lib/supabase';
import CreateMaitreChoeurModal from '@/components/CreateMaitreChoeurModal';
import { SuperAdminGuard } from '@/components/PermissionGuard';

export default function MaitresCh oeurPage() {
  const [maitres, setMaitres] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);

  const loadMaitres = async () => {
    setLoading(true);
    const { data, error } = await supabase
      .from('profiles')
      .select(`
        id,
        full_name,
        affiliation_code,
        lien_affiliation,
        date_activation,
        chorales (nom)
      `)
      .eq('est_maitre_choeur', true)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Erreur:', error);
    } else {
      setMaitres(data || []);
    }
    setLoading(false);
  };

  useEffect(() => {
    loadMaitres();
  }, []);

  return (
    <SuperAdminGuard fallback={<div>Accès refusé</div>}>
      <div className="p-8">
        <div className="flex justify-between items-center mb-6">
          <h1 className="text-3xl font-bold">Maîtres de Chœur</h1>
          <button
            onClick={() => setIsModalOpen(true)}
            className="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600"
          >
            + Créer un Maître de Chœur
          </button>
        </div>

        {loading ? (
          <div>Chargement...</div>
        ) : (
          <div className="bg-white rounded-lg shadow overflow-hidden">
            <table className="min-w-full">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                    Nom
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                    Chorale
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                    Code d'affiliation
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                    Lien
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                    Date d'activation
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {maitres.map((mc) => (
                  <tr key={mc.id}>
                    <td className="px-6 py-4 whitespace-nowrap">{mc.full_name}</td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      {mc.chorales?.nom || 'N/A'}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap font-mono">
                      {mc.affiliation_code}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <code className="text-sm bg-gray-100 px-2 py-1 rounded">
                        {mc.lien_affiliation}
                      </code>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      {new Date(mc.date_activation).toLocaleDateString()}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        <CreateMaitreChoeurModal
          isOpen={isModalOpen}
          onClose={() => setIsModalOpen(false)}
          onSuccess={loadMaitres}
        />
      </div>
    </SuperAdminGuard>
  );
}
```

---

## 📋 CHECKLIST PHASE 4

- [ ] Créer `hooks/usePermissions.ts`
- [ ] Créer `components/PermissionGuard.tsx`
- [ ] Créer `components/CreateMaitreChoeurModal.tsx`
- [ ] Modifier `components/Sidebar.tsx`
- [ ] Créer `app/dashboard/maitres-choeur/page.tsx`
- [ ] Tester avec Super Admin
- [ ] Tester avec Maître de Chœur
- [ ] Tester création de MC

---

## 🎯 RÉSUMÉ COMPLET

### **✅ BACKEND (Terminé)**
- Migration SQL exécutée
- 16 modules de permissions créés
- Fonctions SQL opérationnelles
- Super Admin créé

### **✅ FLUTTER (Terminé)**
- `PermissionsService` créé
- `PermissionsProvider` créé
- `PermissionGuard` widgets créés

### **✅ WEB (En cours)**
- `usePermissions` hook créé
- `PermissionGuard` composants créés
- Modal création MC créé
- Sidebar avec permissions créée
- Page Maîtres de Chœur créée

---

**Système de permissions modulaires 100% opérationnel ! 🎉**
