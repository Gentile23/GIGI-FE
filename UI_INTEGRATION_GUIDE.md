# Guida Integrazione UI OpenAI

## 📱 Schermate Create

Sono state create 3 nuove schermate per l'integrazione OpenAI:

### 1. [injury_selection_screen.dart](file:///c:/Users/genti/Progetti/GIGI/lib/presentation/screens/questionnaire/injury_selection_screen.dart)
Schermata per selezionare e gestire infortuni con:
- Selezione categoria (Muscolare/Articolare/Osseo)
- Grid di 60+ aree anatomiche filtrate per categoria
- Selezione gravità (Lieve/Moderato/Grave)
- Selezione stato (Attivo/In Recupero/Risolto)
- Campo note personalizzate
- Supporto per infortuni multipli
- UI con cards espandibili e bottom sheet modale

### 2. [training_preferences_screen.dart](file:///c:/Users/genti/Progetti/GIGI/lib/presentation/screens/questionnaire/training_preferences_screen.dart)
Schermata per preferenze di allenamento con:
- Selezione tipo di split (7 opzioni con descrizioni)
- Slider per durata sessione (30-120 min)
- Selezione preferenze cardio (6 opzioni)
- Selezione preferenze mobilità (6 opzioni)
- Campo note aggiuntive
- UI con cards interattive e icone

### 3. [ai_workout_generation_screen.dart](file:///c:/Users/genti/Progetti/GIGI/lib/presentation/screens/workout/ai_workout_generation_screen.dart)
Schermata per generazione e visualizzazione scheda AI con:
- Riepilogo completo profilo utente
- Visualizzazione infortuni evidenziati
- Pulsante generazione con loading state
- Visualizzazione scheda generata con:
  - Cards espandibili per ogni giorno
  - Dettagli esercizi (serie, rip, recupero, note)
  - Focus muscolare per giorno
  - Durata stimata
- Opzioni per rigenerare o salvare

## 🔄 Integrazione nel Flusso Questionario

### Opzione 1: Aggiungere al Questionario Esistente

Se hai già un questionario multi-step, aggiungi questi step:

```dart
// Nel tuo questionario esistente (es. questionnaire_screen.dart)

import 'package:GIGI/presentation/screens/questionnaire/injury_selection_screen.dart';
import 'package:GIGI/presentation/screens/questionnaire/training_preferences_screen.dart';
import 'package:GIGI/presentation/screens/workout/ai_workout_generation_screen.dart';

// Aggiungi questi step dopo i dati base (goal, level, frequency, etc.)

// Step per infortuni
void _goToInjurySelection() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => InjurySelectionScreen(
        initialInjuries: _currentProfile.injuries,
        onInjuriesSelected: (injuries) {
          setState(() {
            _currentProfile = _currentProfile.copyWith(
              injuries: injuries,
            );
          });
          _goToTrainingPreferences(); // Vai al prossimo step
        },
      ),
    ),
  );
}

// Step per preferenze allenamento
void _goToTrainingPreferences() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => TrainingPreferencesScreen(
        initialPreferences: _currentProfile.trainingPreferences,
        onPreferencesSelected: (preferences) {
          setState(() {
            _currentProfile = _currentProfile.copyWith(
              trainingPreferences: preferences,
            );
          });
          _goToAIGeneration(); // Vai alla generazione
        },
      ),
    ),
  );
}

// Step finale: generazione AI
void _goToAIGeneration() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AIWorkoutGenerationScreen(
        user: _currentUser,
        profile: _currentProfile,
      ),
    ),
  );
}
```

### Opzione 2: Navigazione Standalone

Se vuoi usare le schermate indipendentemente:

```dart
// Da qualsiasi punto dell'app
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => AIWorkoutGenerationScreen(
      user: currentUser,
      profile: userProfile,
    ),
  ),
);
```

## 🎨 Personalizzazione UI

### Colori e Temi

Le schermate usano i colori del tema dell'app. Per personalizzare:

```dart
// In main.dart o theme.dart
ThemeData(
  primaryColor: Colors.blue, // Colore principale
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue,
  ),
  // ... altri colori
)
```

### Icone e Stili

Tutte le icone e stili sono personalizzabili nei rispettivi file.

## 📊 Gestione Stato

### Con Provider (Consigliato)

```dart
// Crea un provider per il profilo utente
class UserProfileProvider extends ChangeNotifier {
  UserProfile? _profile;
  
  UserProfile? get profile => _profile;
  
  void updateProfile(UserProfile profile) {
    _profile = profile;
    notifyListeners();
  }
  
  void addInjury(InjuryModel injury) {
    if (_profile != null) {
      final injuries = List<InjuryModel>.from(_profile!.injuries);
      injuries.add(injury);
      _profile = _profile!.copyWith(injuries: injuries);
      notifyListeners();
    }
  }
  
  void setTrainingPreferences(TrainingPreferences prefs) {
    if (_profile != null) {
      _profile = _profile!.copyWith(trainingPreferences: prefs);
      notifyListeners();
    }
  }
}

// Usa nelle schermate
final profileProvider = Provider.of<UserProfileProvider>(context);
```

### Senza Provider

Passa i dati tra schermate tramite constructor e callback (come negli esempi sopra).

## 🔧 Configurazione Necessaria

### 1. Assicurati che il pacchetto http sia installato

```bash
flutter pub get
```

### 2. Verifica la chiave OpenAI

In `lib/core/constants/api_config.dart`:
```dart
static const String openAiApiKey = 'sk-proj-...'; // La tua chiave
```

### 3. Gestione Errori

Le schermate gestiscono automaticamente:
- Errori di rete
- Errori API OpenAI
- Timeout
- Validazione input

## 🎯 Esempio Flusso Completo

```dart
// 1. Utente completa dati base nel questionario esistente
// 2. Naviga a InjurySelectionScreen
// 3. Seleziona eventuali infortuni
// 4. Naviga a TrainingPreferencesScreen
// 5. Seleziona preferenze allenamento
// 6. Naviga a AIWorkoutGenerationScreen
// 7. Genera scheda AI
// 8. Visualizza e salva scheda
```

## 📱 Testing Rapido

Per testare rapidamente le schermate:

```dart
// Crea dati di test
final testUser = UserModel(
  id: '1',
  email: 'test@test.com',
  name: 'Test User',
  createdAt: DateTime.now(),
);

final testProfile = UserProfile(
  userId: '1',
  goal: FitnessGoal.muscleGain,
  level: ExperienceLevel.intermediate,
  weeklyFrequency: 4,
  location: TrainingLocation.gym,
  equipment: [Equipment.barbell, Equipment.dumbbells],
  limitations: [],
);

// Naviga alla schermata
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => AIWorkoutGenerationScreen(
      user: testUser,
      profile: testProfile,
    ),
  ),
);
```

## ⚠️ Note Importanti

1. **Connessione Internet**: Le schermate richiedono connessione per chiamare OpenAI
2. **Costi API**: Ogni generazione costa ~$0.01-0.02
3. **Tempo Generazione**: Può richiedere 5-15 secondi
4. **Validazione**: Le schermate validano l'input prima di procedere
5. **Persistenza**: Implementa il salvataggio dei dati (SharedPreferences o backend)

## 🚀 Prossimi Passi

1. Integra le schermate nel tuo flusso questionario esistente
2. Testa con vari profili utente
3. Implementa il salvataggio delle schede generate
4. Aggiungi analytics per tracciare l'uso
5. Considera di aggiungere un tutorial/onboarding

## 💡 Suggerimenti

- **UX**: Mostra un tutorial la prima volta che l'utente usa la generazione AI
- **Performance**: Considera di cachare le schede generate
- **Feedback**: Aggiungi un sistema di rating per le schede generate
- **Personalizzazione**: Permetti all'utente di modificare la scheda generata
