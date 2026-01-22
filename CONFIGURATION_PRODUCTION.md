# 🔧 Configuration pour tester en Production

## 📋 Étapes pour basculer en mode Production

### 1. Modifier le fichier `lib/config/app_config.dart`

Ouvrez le fichier et changez la ligne suivante :

```dart
static const bool isProduction = false; // ← Changez à true
```

En :

```dart
static const bool isProduction = true; // ← Mode production activé
```

### 2. Redémarrer l'application

**IMPORTANT** : Après avoir changé `isProduction`, vous DEVEZ faire un **Hot Restart** (pas juste Hot Reload) :

- Dans VS Code / Android Studio : Appuyez sur `R` (majuscule) ou cliquez sur l'icône "Hot Restart"
- Ou arrêtez complètement l'app et relancez-la

### 3. Vérifier la connexion

L'application utilisera maintenant :
- **API** : `https://crm.model-intelligence-agency.com/api`
- **Serveur** : `https://crm.model-intelligence-agency.com`

## 🔍 Vérifications

### Vérifier que l'API répond

Vous pouvez tester l'API depuis un navigateur ou avec curl :

```bash
curl https://crm.model-intelligence-agency.com/api/auth/login \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"email":"test","password":"test"}'
```

Vous devriez recevoir une réponse JSON (même si c'est une erreur d'authentification, c'est bon signe que l'API répond).

### Vérifier dans les logs Flutter

Quand vous lancez l'application, regardez les logs dans la console. Vous devriez voir les URLs utilisées :

```
📡 URL: https://crm.model-intelligence-agency.com/api/...
```

## ⚠️ Problèmes courants

### Erreur "Connection refused" ou "Failed to connect"

1. **Vérifiez que l'API est accessible** : Ouvrez `https://crm.model-intelligence-agency.com/api/auth/login` dans un navigateur
2. **Vérifiez votre connexion Internet** : L'émulateur doit avoir accès à Internet
3. **Vérifiez les logs Laravel** : Regardez si les requêtes arrivent sur le serveur

### Erreur "Certificate error" ou "SSL error"

Le fichier `network_security_config.xml` a été créé pour gérer cela. Si le problème persiste, vérifiez que le certificat SSL du serveur est valide.

### Erreur 401 "Unauthenticated"

C'est normal si vous n'êtes pas connecté. Essayez de vous connecter avec vos identifiants de production.

### Erreur 404 "Not Found"

Vérifiez que les routes API existent bien en production et sont identiques à celles en local.

## 🔄 Revenir en mode Développement

Pour revenir en mode local, changez simplement :

```dart
static const bool isProduction = false; // ← Mode développement
```

Et faites un **Hot Restart**.

## 📝 Notes

- Les données de production sont différentes des données locales
- Assurez-vous d'avoir des identifiants valides pour la production
- Les images et fichiers seront chargés depuis le serveur de production
