# 🔗 Configuration Deep Link pour confirmation d'email

## 🎯 OBJECTIF

Rediriger l'utilisateur vers l'app Flutter après confirmation d'email, au lieu de `localhost`.

---

## 📱 ÉTAPE 1 : Configurer le Deep Link dans Flutter

### **1.1 Android (`android/app/src/main/AndroidManifest.xml`)**

```xml
<activity
    android:name=".MainActivity"
    android:exported="true"
    android:launchMode="singleTop"
    android:theme="@style/LaunchTheme"
    android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
    android:hardwareAccelerated="true"
    android:windowSoftInputMode="adjustResize">
    
    <!-- Deep Link pour Supabase -->
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        
        <!-- Votre schéma personnalisé -->
        <data
            android:scheme="com.example.mini_chorale_audio_player"
            android:host="callback" />
    </intent-filter>
    
    <!-- Launcher intent filter (déjà existant) -->
    <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
    </intent-filter>
</activity>
```

### **1.2 iOS (`ios/Runner/Info.plist`)**

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.example.mini_chorale_audio_player</string>
        </array>
    </dict>
</array>
```

---

## 🔧 ÉTAPE 2 : Configurer Supabase

### **2.1 Dans Supabase Dashboard**

1. ✅ **Authentication** → **URL Configuration**
2. ✅ **Site URL** : `com.example.mini_chorale_audio_player://callback`
3. ✅ **Redirect URLs** : Ajouter `com.example.mini_chorale_audio_player://callback`

### **2.2 Dans le code Flutter**

Modifier `lib/main.dart` pour gérer le deep link :

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _handleIncomingLinks();
    _handleInitialUri();
  }

  // Gérer les liens entrants (app déjà ouverte)
  void _handleIncomingLinks() {
    _sub = uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        print('📱 Deep link reçu: $uri');
        _handleDeepLink(uri);
      }
    }, onError: (err) {
      print('❌ Erreur deep link: $err');
    });
  }

  // Gérer le lien initial (app fermée)
  Future<void> _handleInitialUri() async {
    try {
      final uri = await getInitialUri();
      if (uri != null) {
        print('📱 Deep link initial: $uri');
        _handleDeepLink(uri);
      }
    } catch (e) {
      print('❌ Erreur récupération URI initial: $e');
    }
  }

  // Traiter le deep link
  void _handleDeepLink(Uri uri) {
    // Supabase gère automatiquement le callback
    // L'utilisateur sera redirigé vers l'écran approprié
    print('✅ Email confirmé via deep link');
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ...
    );
  }
}
```

---

## 📦 ÉTAPE 3 : Ajouter la dépendance

### **Dans `pubspec.yaml` :**

```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.0.0
  uni_links: ^0.5.1  # ✅ AJOUTER
```

### **Installer :**

```bash
flutter pub get
```

---

## 🎨 ÉTAPE 4 : Améliorer l'UX

### **4.1 Page de confirmation personnalisée**

Créer une page web qui s'affiche après confirmation :

```html
<!-- public/email-confirmed.html -->
<!DOCTYPE html>
<html>
<head>
    <title>Email confirmé</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body {
            font-family: Arial, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            margin: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        }
        .container {
            background: white;
            padding: 40px;
            border-radius: 10px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
            text-align: center;
            max-width: 400px;
        }
        .success-icon {
            font-size: 64px;
            margin-bottom: 20px;
        }
        h1 {
            color: #333;
            margin-bottom: 10px;
        }
        p {
            color: #666;
            margin-bottom: 30px;
        }
        .btn {
            background: #667eea;
            color: white;
            padding: 12px 30px;
            border: none;
            border-radius: 5px;
            font-size: 16px;
            cursor: pointer;
            text-decoration: none;
            display: inline-block;
        }
        .btn:hover {
            background: #5568d3;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="success-icon">✅</div>
        <h1>Email confirmé !</h1>
        <p>Votre adresse email a été confirmée avec succès.</p>
        <p>Vous pouvez maintenant vous connecter à l'application.</p>
        <a href="com.example.mini_chorale_audio_player://callback" class="btn">
            Ouvrir l'application
        </a>
        <p style="margin-top: 20px; font-size: 12px; color: #999;">
            L'application devrait s'ouvrir automatiquement.<br>
            Sinon, cliquez sur le bouton ci-dessus.
        </p>
    </div>
    
    <script>
        // Redirection automatique vers l'app après 2 secondes
        setTimeout(() => {
            window.location.href = 'com.example.mini_chorale_audio_player://callback';
        }, 2000);
    </script>
</body>
</html>
```

### **4.2 Héberger cette page**

Hébergez cette page sur :
- Netlify
- Vercel
- GitHub Pages
- Votre propre serveur

Puis configurez dans Supabase :
```
Site URL: https://votre-domaine.com/email-confirmed.html
```

---

## 🧪 ÉTAPE 5 : Tester

### **Test 1 : Inscription**

1. ✅ Créer un nouveau compte
2. ✅ Vérifier l'email reçu
3. ✅ Cliquer sur le lien de confirmation

**Résultat attendu :**
- Page de confirmation s'affiche
- App Flutter s'ouvre automatiquement
- Utilisateur peut se connecter

### **Test 2 : Deep Link**

```bash
# Android
adb shell am start -W -a android.intent.action.VIEW -d "com.example.mini_chorale_audio_player://callback"

# iOS (simulateur)
xcrun simctl openurl booted "com.example.mini_chorale_audio_player://callback"
```

---

## 📋 CHECKLIST

- [ ] AndroidManifest.xml modifié
- [ ] Info.plist modifié (iOS)
- [ ] Dépendance `uni_links` ajoutée
- [ ] Code de gestion deep link ajouté dans main.dart
- [ ] Supabase Site URL configuré
- [ ] Supabase Redirect URLs configuré
- [ ] Page de confirmation créée (optionnel)
- [ ] Page hébergée (optionnel)
- [ ] Test avec vraie inscription
- [ ] Test deep link manuel

---

## 🎯 RÉSULTAT FINAL

**Flux complet :**

```
1. Utilisateur s'inscrit
   ↓
2. Email de confirmation envoyé
   ↓
3. Utilisateur clique sur le lien
   ↓
4. Page web "Email confirmé" s'affiche
   ↓
5. Redirection automatique vers l'app Flutter
   ↓
6. App s'ouvre
   ↓
7. Utilisateur peut se connecter
```

---

**Date de création :** 2025-11-21  
**Version :** 1.0
