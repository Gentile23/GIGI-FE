# FitGenius 🏋️‍♂️

> Your AI-Powered Fitness Coach

FitGenius is a mobile fitness application built with Flutter that provides personalized workout plans, AI voice coaching, and real-time exercise form analysis using Gemini 2.0 Flash.

## ✨ Features

### For All Users (Free Tier)
- 🎯 3 Assessment workouts to determine your fitness level
- 📋 1 Personalized workout plan every 2 months
- 📚 Complete exercise library with video demonstrations
- 📊 Basic workout history tracking

### Premium Features (€9.99/month)
- ♾️ Unlimited workout plan generation
- 🔄 Auto-updating plans based on your progress
- 📈 Detailed statistics and progress tracking
- 💪 Personalized recommendations

### Gold Features (€19.99/month)
- 🎤 AI Voice Coach for live workout guidance
- 📹 Basic pose detection with Gemini 2.0 Flash
- ✅ Real-time exercise form feedback
- 🗣️ Voice-guided rep counting

### Platinum Features (€29.99/month)
- 🎯 Advanced pose analysis with detailed corrections
- 📊 Weekly performance reports
- 👨‍🏫 Access to live Q&A sessions with trainers
- ⭐ Priority support

## 🎨 Design

- **Color Scheme**: Light background with electric orange accent (#FF6B35)
- **Typography**: Roboto font family
- **UI Philosophy**: Clean, minimal, sweat-proof design for workout execution

## 🛠️ Tech Stack

### Frontend
- **Framework**: Flutter 3.10+
- **Language**: Dart
- **State Management**: Provider/Riverpod
- **Navigation**: go_router
- **Theme**: Material 3

### Backend
- **Runtime**: Node.js 18+
- **Framework**: NestJS
- **Database**: MySQL 8.0+
- **ORM**: TypeORM/Prisma

### AI Services
- **Workout Generation**: OpenAI API (GPT-4)
- **Video Analysis**: Gemini 2.0 Flash
- **Voice Coach**: Text-to-Speech

### Authentication & Cloud
- **Auth**: Firebase Authentication
- **Push Notifications**: Firebase Cloud Messaging
- **Payments**: In-app purchases (iOS/Android)

## 📁 Project Structure

```
lib/
├── core/
│   ├── constants/        # App colors, text styles, subscription tiers
│   ├── theme/           # Material theme configuration
│   └── utils/           # Helper functions
├── data/
│   ├── models/          # Data models
│   ├── repositories/    # Data repositories
│   └── services/        # API and external services
├── presentation/
│   ├── screens/         # All app screens
│   ├── widgets/         # Reusable widgets
│   └── navigation/      # Navigation configuration
└── providers/           # State management providers
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.10 or higher
- Dart 3.0 or higher
- Android Studio / Xcode (for mobile development)
- Node.js 18+ (for backend)
- MySQL 8.0+

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/fitgenius.git
   cd fitgenius
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a Firebase project
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place them in the respective directories

4. **Set up environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your API keys
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

## 📱 App Flow

1. **Onboarding** → 4-slide introduction
2. **Registration** → Email/Google/Apple Sign-In
3. **Questionnaire** → Goals, experience, equipment, limitations
4. **Assessment** → 3 evaluation workouts
5. **Main App** → Home, Workout, History, Profile tabs

## 🎯 Assessment System

Every user completes 3 assessment workouts to determine:
- Technical skill level (low/medium/high)
- Relative strength level
- Mobility scores (hips, shoulders, ankles)
- Injury risk assessment

This data is used to generate personalized workout plans.

## 🤖 AI Features

### Workout Generation (OpenAI)
- Personalized plans based on user data
- Considers goals, equipment, limitations
- Adapts to user feedback

### Video Analysis (Gemini 2.0 Flash)
- Real-time pose detection
- Form error identification
- Natural language feedback
- **Gold**: Basic feedback
- **Platinum**: Advanced, detailed corrections

### Voice Coach
- Exercise announcements
- Rep counting
- Technique cues
- Motivational prompts

## 💳 Subscription Tiers

| Feature | Free | Premium | Gold | Platinum |
|---------|------|---------|------|----------|
| Assessment Workouts | ✅ | ✅ | ✅ | ✅ |
| Workout Plans | 1/2mo | ♾️ | ♾️ | ♾️ |
| Auto-updating Plans | ❌ | ✅ | ✅ | ✅ |
| Detailed Stats | ❌ | ✅ | ✅ | ✅ |
| AI Voice Coach | ❌ | ❌ | ✅ | ✅ |
| Pose Detection | ❌ | ❌ | ✅ | ✅ |
| Advanced Analysis | ❌ | ❌ | ❌ | ✅ |
| Weekly Reports | ❌ | ❌ | ❌ | ✅ |
| Live Q&A | ❌ | ❌ | ❌ | ✅ |
| **Price** | €0 | €9.99 | €19.99 | €29.99 |

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test

# Run with coverage
flutter test --coverage
```

## 📦 Building

### Android
```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📧 Contact

For questions or support, contact: support@fitgenius.app

---

**Made with ❤️ and Flutter**
