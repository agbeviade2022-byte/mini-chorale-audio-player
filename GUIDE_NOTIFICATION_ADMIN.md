# 📧 GUIDE : Notification du super admin

## 🎯 OBJECTIF

**Notifier le super admin quand :**
1. ✅ Un nouvel utilisateur s'inscrit
2. ✅ Un utilisateur confirme son email
3. ✅ Un utilisateur est prêt pour validation

---

## 📊 SITUATION ACTUELLE

### **❌ PROBLÈME**

Le super admin **NE SAIT PAS** quand :
- Un nouvel utilisateur s'inscrit
- Un utilisateur confirme son email
- Il doit valider un membre

**Il doit :**
- ❌ Rafraîchir manuellement le dashboard
- ❌ Vérifier régulièrement s'il y a de nouveaux membres

---

## ✅ SOLUTION : Système de notifications

### **FONCTIONNALITÉS**

1. ✅ **Notification à l'inscription**
   - Quand un utilisateur s'inscrit
   - Message : "Nouvel utilisateur inscrit (email non confirmé)"

2. ✅ **Notification à la confirmation d'email**
   - Quand un utilisateur confirme son email
   - Message : "Email confirmé - Prêt pour validation"

3. ✅ **Badge de notification**
   - Affiche le nombre de notifications non lues
   - Dans le dashboard admin

4. ✅ **Liste des notifications**
   - Page dédiée aux notifications
   - Marquer comme lu
   - Filtrer par type

---

## 🔧 IMPLÉMENTATION

### **ÉTAPE 1 : Créer le système de notifications SQL**

```bash
# Exécuter CREATE_EMAIL_NOTIFICATION_ADMIN.sql
```

**Ce script crée :**
- ✅ Table `admin_notifications`
- ✅ Trigger sur `auth.users` (INSERT et UPDATE)
- ✅ Fonctions RPC pour le dashboard
- ✅ Politiques RLS

---

### **ÉTAPE 2 : Ajouter dans le dashboard React**

#### **2.1 Créer le composant NotificationBell**

```typescript
// components/NotificationBell.tsx
'use client'
import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase'
import { Bell } from 'lucide-react'

interface Notification {
  id: number
  type: string
  titre: string
  message: string
  user_email: string
  user_full_name: string
  lu: boolean
  created_at: string
}

export default function NotificationBell() {
  const [notifications, setNotifications] = useState<Notification[]>([])
  const [unreadCount, setUnreadCount] = useState(0)
  const [showDropdown, setShowDropdown] = useState(false)

  useEffect(() => {
    fetchNotifications()
    
    // Rafraîchir toutes les 30 secondes
    const interval = setInterval(fetchNotifications, 30000)
    return () => clearInterval(interval)
  }, [])

  async function fetchNotifications() {
    try {
      const { data, error } = await supabase
        .rpc('get_admin_notifications', {
          p_limit: 10,
          p_only_unread: false
        })

      if (error) throw error

      setNotifications(data || [])
      setUnreadCount(data?.filter((n: Notification) => !n.lu).length || 0)
    } catch (error) {
      console.error('Erreur:', error)
    }
  }

  async function markAsRead(notificationId: number) {
    try {
      await supabase.rpc('mark_notification_read', {
        p_notification_id: notificationId
      })
      fetchNotifications()
    } catch (error) {
      console.error('Erreur:', error)
    }
  }

  return (
    <div className="relative">
      {/* Bell icon with badge */}
      <button
        onClick={() => setShowDropdown(!showDropdown)}
        className="relative p-2 hover:bg-gray-100 rounded-full"
      >
        <Bell className="w-6 h-6 text-gray-600" />
        {unreadCount > 0 && (
          <span className="absolute top-0 right-0 bg-red-500 text-white text-xs rounded-full w-5 h-5 flex items-center justify-center">
            {unreadCount}
          </span>
        )}
      </button>

      {/* Dropdown */}
      {showDropdown && (
        <div className="absolute right-0 mt-2 w-96 bg-white rounded-lg shadow-lg border border-gray-200 z-50">
          <div className="p-4 border-b border-gray-200">
            <h3 className="font-semibold text-gray-900">Notifications</h3>
            <p className="text-sm text-gray-600">{unreadCount} non lue(s)</p>
          </div>
          
          <div className="max-h-96 overflow-y-auto">
            {notifications.length === 0 ? (
              <div className="p-4 text-center text-gray-500">
                Aucune notification
              </div>
            ) : (
              notifications.map((notif) => (
                <div
                  key={notif.id}
                  className={`p-4 border-b border-gray-100 hover:bg-gray-50 cursor-pointer ${
                    !notif.lu ? 'bg-blue-50' : ''
                  }`}
                  onClick={() => markAsRead(notif.id)}
                >
                  <div className="flex justify-between items-start">
                    <div className="flex-1">
                      <p className="font-semibold text-sm text-gray-900">
                        {notif.titre}
                      </p>
                      <p className="text-sm text-gray-600 mt-1">
                        {notif.message}
                      </p>
                      <p className="text-xs text-gray-400 mt-2">
                        {new Date(notif.created_at).toLocaleString('fr-FR')}
                      </p>
                    </div>
                    {!notif.lu && (
                      <div className="w-2 h-2 bg-blue-500 rounded-full ml-2 mt-1"></div>
                    )}
                  </div>
                </div>
              ))
            )}
          </div>
        </div>
      )}
    </div>
  )
}
```

#### **2.2 Ajouter dans le header du dashboard**

```typescript
// app/dashboard/layout.tsx
import NotificationBell from '@/components/NotificationBell'

export default function DashboardLayout({ children }) {
  return (
    <div>
      <header className="bg-white shadow-sm">
        <div className="flex items-center justify-between p-4">
          <h1>Dashboard Admin</h1>
          
          {/* Ajouter la cloche de notification */}
          <NotificationBell />
        </div>
      </header>
      
      <main>{children}</main>
    </div>
  )
}
```

---

### **ÉTAPE 3 : Tester**

#### **Test 1 : Nouvelle inscription**

1. ✅ Créer un nouveau compte dans l'app Flutter
2. ✅ Vérifier qu'une notification apparaît dans le dashboard
3. ✅ Message : "Nouvelle inscription - Email non confirmé"

#### **Test 2 : Confirmation d'email**

1. ✅ Confirmer l'email (cliquer sur le lien)
2. ✅ Vérifier qu'une nouvelle notification apparaît
3. ✅ Message : "Email confirmé - Prêt pour validation"

#### **Test 3 : Badge de notification**

1. ✅ Vérifier que le badge affiche le bon nombre
2. ✅ Cliquer sur une notification
3. ✅ Vérifier que le badge se met à jour

---

## 📊 FLUX COMPLET

```
1. Utilisateur s'inscrit
   ↓
2. Trigger SQL → Notification "Nouvelle inscription"
   ↓
3. Dashboard affiche badge (1)
   ↓
4. Utilisateur confirme son email
   ↓
5. Trigger SQL → Notification "Email confirmé"
   ↓
6. Dashboard affiche badge (2)
   ↓
7. Super admin clique sur la cloche
   ↓
8. Voit les 2 notifications
   ↓
9. Clique sur "Email confirmé"
   ↓
10. Redirigé vers la page de validation
    ↓
11. Valide le membre
```

---

## 🎨 AMÉLIORATIONS POSSIBLES

### **1. Email réel au super admin**

Utiliser Supabase Edge Functions pour envoyer un vrai email :

```typescript
// supabase/functions/send-admin-email/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

serve(async (req) => {
  const { type, user_email, user_name } = await req.json()
  
  // Envoyer email via SendGrid, Resend, etc.
  await sendEmail({
    to: 'admin@chorale.com',
    subject: `Nouvelle notification : ${type}`,
    body: `L'utilisateur ${user_name} (${user_email}) a ${type}`
  })
  
  return new Response('OK')
})
```

### **2. Notification push dans le dashboard**

Utiliser Supabase Realtime pour des notifications en temps réel :

```typescript
// Dans NotificationBell.tsx
useEffect(() => {
  const channel = supabase
    .channel('admin-notifications')
    .on(
      'postgres_changes',
      {
        event: 'INSERT',
        schema: 'public',
        table: 'admin_notifications'
      },
      (payload) => {
        // Nouvelle notification reçue
        setNotifications(prev => [payload.new, ...prev])
        setUnreadCount(prev => prev + 1)
        
        // Jouer un son
        new Audio('/notification.mp3').play()
      }
    )
    .subscribe()

  return () => {
    supabase.removeChannel(channel)
  }
}, [])
```

### **3. Notification mobile (Flutter)**

Créer une page admin dans Flutter avec les mêmes notifications.

---

## 📋 CHECKLIST

- [ ] Exécuter `CREATE_EMAIL_NOTIFICATION_ADMIN.sql`
- [ ] Créer `components/NotificationBell.tsx`
- [ ] Ajouter dans le header du dashboard
- [ ] Tester avec une nouvelle inscription
- [ ] Tester avec une confirmation d'email
- [ ] Vérifier que le badge fonctionne
- [ ] (Optionnel) Ajouter email réel
- [ ] (Optionnel) Ajouter Realtime
- [ ] (Optionnel) Ajouter page admin Flutter

---

## 🎯 RÉSULTAT FINAL

**Le super admin sera notifié :**
- ✅ En temps réel (avec Realtime)
- ✅ Badge visible dans le dashboard
- ✅ Liste des notifications cliquables
- ✅ Redirection vers la page de validation
- ✅ (Optionnel) Email envoyé

---

**Date de création :** 2025-11-21  
**Auteur :** Cascade AI  
**Version :** 1.0
