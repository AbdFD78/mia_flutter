# MIA Flutter

Application mobile Flutter pour la plateforme MIA (gestion de clients et événements).

## 📱 Fonctionnalités

### ✅ Authentification
- Connexion avec email et mot de passe
- Gestion de session avec tokens API
- Persistance de la connexion
- Déconnexion sécurisée

### 📊 Dashboard
- Vue d'ensemble des statistiques
- Filtres par période (aujourd'hui, cette semaine, ce mois, cette année)
- Filtres par utilisateur
- Widgets dynamiques
- Graphiques interactifs

### 👥 Gestion des Clients
- Liste complète des clients
- Recherche par nom
- Filtres par type et statut
- Détails complets du client :
  - Informations de contact
  - Statistiques (campagnes, contacts, suivis)
  - Onglet Suivis du client
  - Onglet Événements

### 🧭 Navigation
- Sidebar (menu latéral) persistant
- Routes configurées avec GoRouter
- Menu sections :
  - Mon Profil
  - Clients → Liste clients
  - Utilisateurs → Liste utilisateurs
  - Campagnes → Mes campagnes
  - Événements → Liste, Calendrier, Suivis clients

## 🛠️ Technologies

- **Flutter** : Framework UI
- **Provider** : Gestion d'état
- **GoRouter** : Navigation
- **HTTP** : Requêtes API
- **SharedPreferences** : Stockage local

## 🔗 Backend

L'application communique avec une API Laravel :
- Base URL : `http://10.0.2.2:8000/api` (émulateur)
- Authentification par token API
- Endpoints :
  - `POST /auth/login`
  - `POST /auth/logout`
  - `GET /dashboard`
  - `GET /clients`
  - `GET /clients/{id}`

## 📦 Installation

```bash
# Cloner le dépôt
git clone https://github.com/AbdFD78/mia_flutter.git

# Installer les dépendances
flutter pub get

# Lancer l'application
flutter run
```

## 🏗️ Structure du projet

```
lib/
├── main.dart                    # Point d'entrée + configuration routes
├── models/                      # Modèles de données
│   ├── user.dart
│   └── client.dart
├── providers/                   # Gestion d'état
│   └── auth_provider.dart
├── screens/                     # Écrans de l'application
│   ├── auth/
│   │   └── login_screen.dart
│   ├── dashboard_screen.dart
│   ├── clients_screen.dart
│   ├── client_detail_screen.dart
│   └── coming_soon_screen.dart
├── services/                    # Services API
│   ├── auth_service.dart
│   ├── api_service.dart
│   └── dashboard_service.dart
└── widgets/                     # Composants réutilisables
    └── app_drawer.dart
```

## 🎨 Design

L'application respecte le design de la version web Laravel avec :
- Palette de couleurs identique
- Composants Material Design
- Interface responsive
- Animations fluides

## 📝 Configuration

### Environnement de développement
- Pour émulateur Android : `http://10.0.2.2:8000`
- Pour appareil physique : remplacer par l'IP de votre machine

### Modifier l'URL de l'API
Fichiers à mettre à jour :
- `lib/services/auth_service.dart`
- `lib/services/api_service.dart`
- `lib/services/dashboard_service.dart`

## 🔐 Sécurité

- Tokens stockés de manière sécurisée avec SharedPreferences
- Validation des entrées utilisateur
- Gestion des erreurs d'authentification
- Session expirée détectée automatiquement

## 👨‍💻 Auteur

**AbdFD78**

## 📄 Licence

Ce projet est privé et propriétaire.
