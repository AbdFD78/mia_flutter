# Guide d'Authentification - Mia CRM Mobile

## ✅ Implémentation Complétée

Toutes les fonctionnalités d'authentification ont été implémentées avec succès !

### 🎯 Ce qui a été fait

#### Backend Laravel
1. ✅ Migration pour ajouter `api_token` à la table `users` (exécutée)
2. ✅ `AuthController` avec méthodes login, logout et user
3. ✅ Routes API ajoutées dans `routes/api.php`

#### Frontend Flutter
1. ✅ Modèle `User` avec sérialisation JSON
2. ✅ `AuthService` pour gérer les appels API
3. ✅ `AuthProvider` pour la gestion d'état
4. ✅ `LoginScreen` avec design identique à la version web
5. ✅ Navigation avec `go_router` (login/clients)
6. ✅ `ApiService` mis à jour avec authentification

### 🚀 Comment tester

#### 1. Démarrer le serveur Laravel
```bash
cd /var/www/html/mia
php artisan serve
```

#### 2. Lancer l'application Flutter
```bash
cd C:\Users\innov\Desktop\OCEER\Flutter\mia_flutter
flutter run
```

#### 3. Tester la connexion

**Utilisez un compte existant de votre base de données `mia_diffusion`.**

Exemple de test :
- Email : (votre email dans la table users)
- Password : (votre mot de passe)
- Cochez "Se souvenir de moi" pour tester la persistance

#### 4. Vérifications à effectuer

**✓ Connexion**
- [ ] La page de connexion s'affiche avec le fond rose
- [ ] Les champs email et password fonctionnent
- [ ] La validation locale fonctionne (format email)
- [ ] Le bouton affiche un loader pendant la connexion
- [ ] Les erreurs serveur s'affichent correctement
- [ ] La navigation vers `/clients` fonctionne après connexion

**✓ Persistance**
- [ ] Fermer et rouvrir l'app : l'utilisateur reste connecté
- [ ] Le token est stocké dans SharedPreferences
- [ ] Les données utilisateur sont récupérées au démarrage

**✓ API Clients**
- [ ] La liste des clients se charge avec le token
- [ ] Le header `Authorization: Bearer {token}` est présent

**✓ Déconnexion**
- [ ] La déconnexion supprime le token
- [ ] L'utilisateur est redirigé vers `/login`

### 📁 Structure des fichiers créés/modifiés

#### Backend
```
\\wsl$\Ubuntu-22.04\var\www\html\mia\
├── database\migrations\
│   └── 2026_01_20_120000_add_api_token_to_users_table.php
├── app\Http\Controllers\Api\
│   └── AuthController.php
└── routes\
    └── api.php (modifié)
```

#### Frontend
```
c:\Users\innov\Desktop\OCEER\Flutter\mia_flutter\
├── lib\
│   ├── main.dart (modifié)
│   ├── models\
│   │   └── user.dart
│   ├── providers\
│   │   └── auth_provider.dart
│   ├── screens\
│   │   └── auth\
│   │       └── login_screen.dart
│   └── services\
│       ├── api_service.dart (modifié)
│       └── auth_service.dart
└── pubspec.yaml (modifié)
```

### 🔑 Endpoints API

**POST** `/api/auth/login`
```json
{
  "email": "user@example.com",
  "password": "password",
  "remember": true
}
```

**Response** (200 OK)
```json
{
  "success": true,
  "message": "Connexion réussie",
  "data": {
    "token": "...",
    "user": {
      "id": 1,
      "name": "...",
      "email": "...",
      ...
    }
  }
}
```

**POST** `/api/auth/logout`
- Header: `Authorization: Bearer {token}`

**GET** `/api/auth/user`
- Header: `Authorization: Bearer {token}`

### 🎨 Design

La page de connexion mobile reproduit fidèlement la version web :
- Fond d'image rose
- Container blanc semi-transparent (opacity 0.9)
- Border radius 10px
- Champs avec icônes
- Checkbox "Se souvenir de moi"
- Bouton noir "Me connecter"

### 🔧 Configuration technique

**Base de données** : `mia_diffusion` (MySQL)
**URL API** : `http://10.0.2.2:8000/api` (depuis émulateur Android)
**Stockage local** : SharedPreferences
- Clé token : `auth_token`
- Clé user : `user_data`

### 📝 Notes importantes

1. **Migration exécutée** : La colonne `api_token` a été ajoutée à la table `users`
2. **Token sécurisé** : Le token est hashé en SHA256 avant stockage en base
3. **Validation du token** : Le token est vérifié au démarrage de l'app
4. **Gestion des erreurs 401** : Déconnexion automatique si le token expire
5. **Remember me** : Fonctionne via la persistance du token

### 🐛 Debugging

Si vous rencontrez des problèmes :

1. **Vérifier le serveur Laravel**
   ```bash
   php artisan serve
   # Doit être accessible sur http://localhost:8000
   ```

2. **Vérifier la base de données**
   ```sql
   DESCRIBE users;
   # Doit contenir la colonne api_token
   ```

3. **Logs Flutter**
   ```bash
   flutter run --verbose
   ```

4. **Tester l'API manuellement**
   ```bash
   curl -X POST http://localhost:8000/api/auth/login \
     -H "Content-Type: application/json" \
     -d '{"email":"test@test.com","password":"password"}'
   ```

### ✨ Prochaines étapes

Maintenant que l'authentification fonctionne, vous pouvez :

1. Ajouter d'autres pages à l'application mobile
2. Implémenter la déconnexion dans l'UI (bouton logout)
3. Ajouter un écran de profil utilisateur
4. Gérer le changement de mot de passe
5. Ajouter la gestion des permissions utilisateur

---

**Développé par Ab | 20/01/2026**
**Mia CRM - Application Mobile Flutter + API Laravel**
