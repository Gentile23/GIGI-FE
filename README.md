# GIGI 🏋️‍♂️

> **Your AI-Powered Fitness Coach** – A premium Flutter application that delivers personalized workout plans, real-time AI voice coaching, form analysis, gamification, and a vibrant social experience.

[![Flutter](https://img.shields.io/badge/Flutter-3.38+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## 📚 Table of Contents

1. [Project Overview](#-project-overview)
2. [Key Features](#-key-features)
3. [Screen-by-Screen Walkthrough](#-screen-by-screen-walkthrough)
4. [Architecture & Tech Stack](#-architecture--tech-stack)
5. [Project Structure](#-project-structure)
6. [Getting Started](#-getting-started)
7. [Running & Building](#-running--building)
8. [Subscription Tiers](#-subscription-tiers)
9. [AI Features](#-ai-features)
10. [Testing](#-testing)
11. [Contributing](#-contributing)
12. [License & Contact](#-license--contact)

---

## 🎯 Project Overview

GIGI is a comprehensive **Flutter** mobile/web/desktop fitness application that combines cutting-edge AI technology with gamification to create an engaging, personalized workout experience.

### Core Pillars

- **🤖 AI-Powered Personalization** – Workout generation with OpenAI GPT-4, voice coaching with TTS, form analysis with Gemini 2.0 Flash
- **🎮 Gamification** – XP system, achievements, streaks, leaderboards, and community challenges
- **👥 Social Features** – Activity feed, community goals, referral program
- **📊 Progress Tracking** – Detailed statistics, transformation tracker, workout history
- **🎨 Premium UI/UX** – Clean design with glassmorphism, smooth animations, and responsive layouts

---

## ✨ Key Features

### 🏠 Enhanced Home Screen
- **Dynamic Hero Card** – Personalized greeting with time-based messages
- **Quick Actions** – One-tap access to trial workout, AI plan generation, custom workouts, history, and community
- **Weekly Progress Tracker** – Visual representation of workout consistency
- **Skeleton Loading** – Premium loading animations for better perceived performance

### 🏋️ Workout System
- **Trial Workout** – Free assessment workout for new users with voice coaching
- **AI-Generated Plans** – Personalized workout plans based on user profile, goals, and equipment
- **Custom Workout Builder** – Create and save your own workout routines
- **Exercise Library** – Complete database with video demonstrations and muscle group visualization
- **Set Logging** – Track reps, weight, and rest times for each exercise
- **Voice Coaching** – Audio guidance during exercises (pre, during, post phases)

### 🎯 Gamification System
- **XP & Leveling** – Earn experience points for completing workouts
- **Achievements** – Unlock badges for milestones (streaks, PRs, challenges)
- **Daily/Weekly Challenges** – Compete with the community for rewards
- **Leaderboards** – Rankings by XP, workouts completed, and streak length
- **Celebration Overlays** – Confetti animations for achievements

### 👥 Social Features
- **Activity Feed** – See what the community is achieving
- **Community Goals** – Collective milestones (e.g., "10,000 workouts together")
- **Referral Program** – Invite friends and earn rewards
- **Kudos System** – Support fellow users with likes and comments

### 📊 Progress & Analytics
- **Transformation Tracker** – Photo comparisons over time
- **Workout History** – Complete log of all completed sessions
- **Statistics Dashboard** – Volume, frequency, and performance metrics
- **Biometric Integration** – Track weight, body measurements, and more

### 🥗 Nutrition Coach
- **Daily Calorie Tracking** – Monitor intake vs. goals
- **Macro Breakdown** – Protein, carbs, and fat tracking
- **Meal Logging** – Quick and easy food entry
- **Water Tracking** – Stay hydrated

### 👤 Profile & Settings
- **User Profile** – Personal info, stats, and achievements
- **Training Preferences** – Equipment, goals, limitations
- **Subscription Management** – Upgrade/downgrade plans
- **Edit Preferences** – Update fitness goals and training style

---

## 📱 Screen-by-Screen Walkthrough

### Onboarding Flow
1. **Onboarding Slides** – 4-slide introduction to app features
2. **Authentication** – Email/Google/Apple Sign-In via Firebase
3. **Unified Questionnaire** – Goals, experience level, equipment, schedule
4. **Trial Workout** – Assessment workout with voice coaching

### Main Application

| Screen | Description |
|--------|-------------|
| `EnhancedHomeScreen` | Dashboard with hero card, quick actions, weekly progress |
| `ProfileScreen` | User info, subscription status, quick navigation to features |
| `EditProfileScreen` | Edit personal information and preferences |
| `WorkoutSessionScreen` | Active workout execution with set logging |
| `TrialWorkoutScreen` | Free trial workout with full voice coaching |
| `CustomWorkoutListScreen` | Manage custom workout plans |
| `CreateCustomWorkoutScreen` | Build new workout routines |
| `ExerciseSearchScreen` | Browse and filter exercise library |
| `GamificationScreen` | Stats, achievements, and leaderboard tabs |
| `ChallengesScreen` | Daily, weekly, and community challenges |
| `LeaderboardScreen` | Rankings by XP, workouts, and streaks |
| `CommunityGoalsScreen` | Collective milestones and progress |
| `ActivityFeedScreen` | Social feed with activities, challenges, leaderboard |
| `NutritionDashboardScreen` | Calorie and macro tracking |
| `MealLoggingScreen` | Add meals and food items |
| `TransformationTrackerScreen` | Progress photos comparison |
| `WorkoutHistoryScreen` | Complete workout log |
| `PaywallScreen` | Subscription tier selection |
| `ReferralScreen` | Share and earn rewards |

---

## 🏗️ Architecture & Tech Stack

### Frontend Stack

| Technology | Purpose |
|------------|---------|
| **Flutter 3.38+** | Cross-platform UI framework |
| **Dart 3.0+** | Programming language |
| **Provider** | State management |
| **GoRouter** | Declarative routing |
| **Material 3** | Design system |
| **Google Fonts** | Typography (Inter, Outfit, Roboto) |

### Backend Integration

| Service | Purpose |
|---------|---------|
| **Laravel API** | REST API backend |
| **MySQL 8.0+** | Database |
| **Firebase Auth** | Authentication |
| **Firebase Cloud Messaging** | Push notifications |
| **RevenueCat** | In-app purchases & subscriptions |

### AI Services

| Service | Purpose |
|---------|---------|
| **OpenAI GPT-4** | Workout plan generation |
| **Gemini 2.0 Flash** | Real-time pose detection & form analysis |
| **OpenAI TTS** | Voice coaching audio generation |

### Key Dependencies

```yaml
dependencies:
  # Core
  flutter: sdk
  provider: ^6.1.1
  go_router: ^14.0.0
  
  # HTTP & Storage
  dio: ^5.4.0
  shared_preferences: ^2.2.2
  
  # UI
  google_fonts: ^6.1.0
  flutter_svg: ^2.0.9
  confetti: ^0.7.0
  fl_chart: ^0.66.0
  
  # Media
  audioplayers: ^5.0.0
  video_player: ^2.10.1
  youtube_player_flutter: ^9.0.3
  camera: ^0.11.3
  image_picker: ^1.2.1
  
  # Payments
  purchases_flutter: ^8.0.0
  
  # Social
  share_plus: ^7.2.1
```

---

## 📂 Project Structure

```
lib/
├── core/
│   ├── constants/           # App colors, text styles, API config
│   │   ├── app_colors.dart
│   │   ├── api_config.dart
│   │   └── subscription_tiers.dart
│   ├── theme/               # Material theme configuration
│   │   └── clean_theme.dart
│   ├── services/            # Core services (haptic, sound, etc.)
│   │   ├── haptic_service.dart
│   │   └── sound_service.dart
│   └── utils/               # Helper functions
│
├── data/
│   ├── models/              # Data models
│   │   ├── user_model.dart
│   │   ├── workout_model.dart
│   │   ├── gamification_model.dart
│   │   ├── nutrition_model.dart
│   │   ├── voice_coaching_model.dart
│   │   ├── biometric_model.dart
│   │   └── ...
│   ├── repositories/        # Data repositories (optional)
│   └── services/            # API & external services
│       ├── api_client.dart
│       ├── auth_service.dart
│       ├── workout_service.dart
│       ├── voice_coaching_service.dart
│       ├── gamification_service.dart
│       ├── nutrition_service.dart
│       └── ...
│
├── presentation/
│   ├── screens/             # All UI screens
│   │   ├── home/
│   │   │   ├── enhanced_home_screen.dart
│   │   │   └── home_screen.dart
│   │   ├── workout/
│   │   │   ├── workout_session_screen.dart
│   │   │   ├── trial_workout_screen.dart
│   │   │   ├── exercise_detail_screen.dart
│   │   │   └── ...
│   │   ├── profile/
│   │   ├── gamification/
│   │   ├── challenges/
│   │   ├── leaderboard/
│   │   ├── social/
│   │   ├── nutrition/
│   │   ├── custom_workout/
│   │   ├── onboarding/
│   │   ├── auth/
│   │   ├── paywall/
│   │   └── ...
│   ├── widgets/             # Reusable UI components
│   │   ├── clean_widgets.dart
│   │   ├── gamification_widgets.dart
│   │   ├── voice_coaching_player.dart
│   │   ├── celebration_widgets.dart
│   │   └── ...
│   └── navigation/          # GoRouter configuration
│
├── providers/               # State management
│   ├── auth_provider.dart
│   ├── workout_provider.dart
│   ├── workout_log_provider.dart
│   ├── gamification_provider.dart
│   ├── social_provider.dart
│   └── engagement_provider.dart
│
└── main.dart                # App entry point
```

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK ≥ 3.38** (`flutter doctor` should pass)
- **Dart SDK ≥ 3.0**
- **Android Studio / Xcode** (for mobile development)
- **Node.js ≥ 18** (for backend, if running locally)
- **MySQL ≥ 8.0**

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/GIGI.git
cd GIGI

# Install Flutter dependencies
flutter pub get

# Run the app
flutter run
```

### Firebase Setup

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable Authentication (Email, Google, Apple)
3. Download configuration files:
   - `google-services.json` → `android/app/`
   - `GoogleService-Info.plist` → `ios/Runner/`
4. Run `flutterfire configure` if using FlutterFire CLI

### Environment Configuration

Create a `.env` file at the project root:

```env
# API Configuration
API_BASE_URL=https://your-api.example.com/api

# AI Services
OPENAI_API_KEY=sk-your-openai-key
GEMINI_API_KEY=your-gemini-key

# RevenueCat
REVENUECAT_API_KEY=your-revenuecat-key
```

---

## 📱 Running & Building

### Development

```bash
# Run on connected device
flutter run

# Run on specific platform
flutter run -d chrome      # Web
flutter run -d windows     # Windows desktop
flutter run -d macos       # macOS desktop
flutter run -d android     # Android device/emulator
flutter run -d ios         # iOS device/simulator
```

### Production Builds

```bash
# Android
flutter build apk --release
flutter build appbundle --release  # For Play Store

# iOS
flutter build ios --release
flutter build ipa --release        # For App Store

# Web
flutter build web --release

# Windows
flutter build windows --release

# macOS
flutter build macos --release
```

---

## 💳 Subscription Tiers

| Feature | Free | Premium (€9.99/mo) | Gold (€19.99/mo) | Platinum (€29.99/mo) |
|---------|:----:|:------------------:|:----------------:|:--------------------:|
| **Assessment Workouts** | ✅ 3 | ✅ Unlimited | ✅ Unlimited | ✅ Unlimited |
| **AI Workout Plans** | 1/2mo | ♾️ Unlimited | ♾️ Auto-updating | ♾️ Auto-updating |
| **Exercise Library** | ✅ | ✅ | ✅ | ✅ |
| **Workout History** | ✅ Basic | ✅ Detailed | ✅ Detailed | ✅ Detailed |
| **Detailed Statistics** | ❌ | ✅ | ✅ | ✅ |
| **Custom Workouts** | ❌ | ✅ | ✅ | ✅ |
| **AI Voice Coach** | Trial only | ❌ | ✅ | ✅ |
| **Pose Detection** | ❌ | ❌ | ✅ Basic | ✅ Advanced |
| **Form Feedback** | ❌ | ❌ | ✅ Basic | ✅ Detailed corrections |
| **Weekly Reports** | ❌ | ❌ | ❌ | ✅ |
| **Live Q&A Sessions** | ❌ | ❌ | ❌ | ✅ |
| **Priority Support** | ❌ | ❌ | ❌ | ✅ |

---

## 🤖 AI Features

### Workout Generation (OpenAI GPT-4)
- Analyzes user profile: goals, experience, equipment, limitations
- Generates periodized training plans
- Adapts difficulty based on performance feedback
- Considers recovery and injury prevention

### Voice Coaching (OpenAI TTS)
- **Pre-exercise**: Preparation cues and technique reminders
- **During execution**: Rep counting, form reminders, motivation
- **Post-exercise**: Recovery guidance and next exercise preview
- Available free during trial, premium feature for regular workouts

### Pose Detection (Gemini 2.0 Flash)
- Real-time video analysis via device camera
- Identifies form errors and suggests corrections
- **Gold tier**: Basic feedback
- **Platinum tier**: Advanced, detailed corrections

---

## 🧪 Testing

```bash
# Run all unit tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run integration tests
flutter test integration_test/

# Analyze code
flutter analyze

# Format code
dart format lib/
```

### Current Status
✅ **No lint errors** – All analyzer warnings resolved  
✅ **Compiles successfully** – Web, Android, iOS builds pass  
✅ **Flutter 3.38+ compatible** – Uses latest APIs

---

## 🎨 Design System

### Color Palette

| Color | Hex | Usage |
|-------|-----|-------|
| **Primary (Sage Green)** | `#7C9885` | Primary actions, highlights |
| **Secondary (Warm Beige)** | `#D4C5B9` | Secondary elements |
| **Tertiary (Soft Coral)** | `#E8A598` | Accent, notifications |
| **Background** | `#1A1A1A` | Dark mode background |
| **Surface** | `#FFFFFF` | Cards, dialogs |
| **Success** | `#6B9080` | Positive actions |
| **Warning** | `#D4A574` | Caution states |
| **Error** | `#C97C7C` | Error states |

### Typography

- **Headlines**: Outfit (600-700 weight)
- **Body**: Inter (400-600 weight)
- **Monospace**: Roboto Mono

### Design Principles

1. **Clean & Minimal** – Focus on content, reduce visual noise
2. **Glassmorphism** – Subtle transparency and blur effects
3. **Micro-animations** – Smooth transitions for better UX
4. **Responsive** – Adapts to mobile, tablet, and desktop

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Follow the existing coding style (Clean Architecture, Provider pattern)
4. Run `flutter analyze` and fix any warnings
5. Write tests for new functionality
6. Submit a Pull Request with clear description

### Code Style Guidelines

- Use `CleanTheme` for all colors and styles
- Prefer `CleanWidgets` for common UI components
- Follow Provider pattern for state management
- Use `GoogleFonts.outfit()` for headlines, `GoogleFonts.inter()` for body text

---

## 📄 License

This project is licensed under the **MIT License** – see the [LICENSE](LICENSE) file for details.

---

## 📧 Contact

For questions, feature requests, or support:

- **Email**: support@GIGI.app
- **Twitter**: [@GIGIApp](https://twitter.com/GIGIApp)
- **Discord**: [discord.gg/GIGI](https://discord.gg/GIGI)

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- OpenAI for GPT-4 and TTS APIs
- Google for Gemini 2.0 Flash
- RevenueCat for simplified subscription management
- All contributors and beta testers

---

**Made with ❤️ and Flutter**

*GIGI – Transform your fitness journey with AI-powered coaching*
