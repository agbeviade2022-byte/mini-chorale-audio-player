# 🚀 Guide de Test Rapide

## ⚡ Commandes à Exécuter Maintenant

### **1. Installer les dépendances**
```bash
flutter pub get
```
**Attendu** : ✅ "Got dependencies!"

---

### **2. Nettoyer le projet**
```bash
flutter clean
```
**Attendu** : ✅ Nettoyage du dossier build

---

### **3. Vérifier qu'il n'y a pas d'erreurs**
```bash
flutter analyze
```
**Attendé** : ✅ Aucune erreur (quelques warnings sont OK)

---

### **4. Connecter votre appareil Android**

**Via USB** :
1. Brancher le téléphone
2. Activer le débogage USB
3. Vérifier : `flutter devices`

**Via WiFi** (optionnel) :
```bash
adb tcpip 5555
adb connect <IP_PHONE>:5555
```

---

### **5. Lancer en mode release**
```bash
flutter run --release
```

**Important** : Utiliser `--release` pour des performances réelles !

---

## 🧪 Scénarios de Test

### **Test 1 : Connexion normale** ✅
1. Assurez-vous d'être connecté au WiFi/4G
2. Lancez l'app
3. Cliquez sur un chant
4. **Attendu** : Le chant joue normalement

---

### **Test 2 : Mode avion** ✈️
1. Activez le mode avion
2. Essayez de lancer un chant **non téléchargé**
3. **Attendu** : Message "Pas de connexion internet..."
4. Si un chant est téléchargé, il devrait jouer

---

### **Test 3 : Arrière-plan** 📱
1. Lancez un chant
2. Appuyez sur le bouton Home
3. **Attendu** : La musique continue
4. Revenez à l'app : elle ne crash pas

---

### **Test 4 : Rotation écran** 🔄
1. Lancez un chant
2. Tournez l'écran (portrait ↔ paysage)
3. **Attendu** : Pas de crash, lecture continue

---

### **Test 5 : Appel téléphonique** 📞
1. Lancez un chant
2. Recevez un appel (ou simulez)
3. **Attendu** : Musique en pause automatique
4. Après l'appel : peut reprendre

---

### **Test 6 : Multitâche** 🔀
1. Lancez un chant
2. Ouvrez une autre app
3. Revenez à l'app chorale
4. **Attendu** : L'état est préservé

---

## 🐛 Que Faire en Cas de Problème ?

### **Erreur de compilation** ❌
```bash
flutter clean
flutter pub get
flutter run --release
```

### **Permissions refusées** 🚫
Dans les paramètres Android :
- Autoriser le stockage
- Autoriser les fichiers et médias

### **Chants ne se lancent pas** 🎵
1. Vérifier la connexion internet
2. Vérifier les logs : `flutter logs`
3. Regarder les messages dans la console

### **App crash** 💥
1. Regarder les logs
2. Noter l'action qui cause le crash
3. Vérifier le fichier de logs

---

## 📊 Logs à Surveiller

Ouvrez un terminal et lancez :
```bash
flutter logs
```

### **Messages normaux** ✅
```
✅ Supabase initialisé avec succès
✅ Lifecycle observer ajouté
🔄 App lifecycle: resumed
📱 App au premier plan
```

### **Messages d'erreur** ⚠️
```
❌ Flutter Error: ...
❌ Erreur lors de la lecture: ...
📱 Pas de connexion internet
```

---

## 📝 Checklist Finale

Avant de valider :

- [ ] `flutter pub get` exécuté sans erreur
- [ ] App lancée en mode `--release`
- [ ] Chants jouent avec internet
- [ ] Message d'erreur approprié sans internet
- [ ] Musique continue en arrière-plan
- [ ] Pas de crash lors des rotations
- [ ] Mini-player fonctionne
- [ ] Full-player fonctionne
- [ ] Les boutons play/pause répondent

---

## 🎯 Résultat Attendu

### **Succès** ✅
- L'app se lance sans crash
- Les chants jouent correctement
- Les erreurs sont gérées gracieusement
- Bonne performance (fluide)
- Pas de lag notable

### **Performance** 📊
- Lancement : < 3 secondes
- Lecture audio : instantanée
- Navigation : fluide
- Batterie : consommation normale

---

## 🆘 En Cas de Besoin

### **Reconstruire complètement**
```bash
flutter clean
flutter pub get
flutter build apk --release
flutter install
```

### **Vérifier la version Android**
```bash
flutter doctor -v
```

**Version minimale requise** : Android 7.0 (API 24)

---

## 📱 Build APK pour Distribution

Une fois les tests validés :

```bash
flutter build apk --release --split-per-abi
```

Fichiers générés dans :
`build/app/outputs/flutter-apk/`

- `app-armeabi-v7a-release.apk` (32-bit)
- `app-arm64-v8a-release.apk` (64-bit)
- `app-x86_64-release.apk` (x86)

**Installer** : Transférez le fichier adapté à votre téléphone

---

## ⏱️ Temps Estimé

- Installation dépendances : **30 secondes**
- Premier build : **2-3 minutes**
- Builds suivants : **30 secondes**
- Tests complets : **10-15 minutes**

---

## 🎉 Bon Test !

Tout est prêt. Lancez maintenant :
```bash
flutter pub get && flutter run --release
```

**Bonne chance ! 🚀**
