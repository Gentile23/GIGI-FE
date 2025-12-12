# Integrazione OpenAI per Generazione Schede Allenamento

## 📋 Panoramica

Questa implementazione integra OpenAI GPT-5-nano nell'app GIGI per generare schede di allenamento personalizzate basate su:
- Obiettivi fitness dell'utente
- Livello di esperienza
- Infortuni dettagliati (muscoli, articolazioni, ossa)
- Preferenze di allenamento (monofrequenza, multifrequenza, PPL, ecc.)
- Attrezzatura disponibile

## 🎯 Componenti Implementati

### 1. Modelli Dati

#### `injury_model.dart`
Modello completo per tracciare infortuni con:
- **Categorie**: Muscolare, Articolare, Osseo
- **Aree specifiche**: 60+ aree anatomiche dettagliate
  - Muscoli: trapezio, deltoidi, pettorali, bicipiti, tricipiti, dorsali, glutei, quadricipiti, femorali, ecc.
  - Articolazioni: spalla, gomito, polso, ginocchio, caviglia, colonna vertebrale, ecc.
  - Ossa: clavicola, scapola, femore, tibia, vertebre, ecc.
- **Gravità**: Lieve, Moderato, Grave
- **Stato**: Attivo, In Recupero, Risolto
- **Note personalizzate**

#### `training_preferences_model.dart`
Preferenze di allenamento con:
- **Split di allenamento**:
  - Monofrequenza (ogni muscolo 1x/settimana)
  - Multifrequenza (ogni muscolo 2-3x/settimana)
  - Upper/Lower
  - Push/Pull/Legs
  - Full Body
  - Body Part Split
  - Arnold Split
- **Preferenze Cardio**: Nessuno, Minimo, Moderato, Alto, HIIT, LISS
- **Preferenze Mobilità**: Nessuna, Minima, Moderata, Alta, Yoga, Dinamica
- **Durata sessione preferita**

#### `user_model.dart` (Esteso)
`UserProfile` ora include:
- Lista di infortuni (`List<InjuryModel>`)
- Preferenze di allenamento (`TrainingPreferences`)

### 2. Servizi

#### `openai_service.dart`
Servizio dedicato per comunicazione con OpenAI:
- **Prompt Engineering Ottimizzato**:
  - System prompt con ruolo di personal trainer esperto
  - Context dettagliato su utente, obiettivi, limitazioni
  - Istruzioni specifiche per evitare esercizi che coinvolgono aree infortunate
  - Output in formato JSON strutturato
  - Temperature: 0.7 (bilanciamento tra creatività e consistenza)
  - Max tokens: 3000

- **Best Practices GPT-5-nano**:
  - Prompt chiaro e strutturato
  - Esempi di output desiderato
  - Gestione errori robusta
  - Retry logic (può essere implementato)

#### `workout_service.dart` (Aggiornato)
Metodo `generateAIPlan()` che:
1. Chiama OpenAI service con dati utente e profilo
2. Riceve risposta JSON strutturata
3. Converte in modello `WorkoutPlan` esistente
4. Opzionalmente salva nel backend Laravel

### 3. Configurazione

#### `api_config.dart`
Aggiunta configurazione OpenAI:
```dart
static const String openAiApiKey = 'sk-proj-...';
static const String openAiBaseUrl = 'https://api.openai.com/v1';
static const String openAiModel = 'gpt-5-nano';
```

## 🚀 Come Utilizzare

### Esempio Base

```dart
// 1. Crea dati utente
final user = UserModel(
  id: '1',
  email: 'user@example.com',
  name: 'Mario Rossi',
  gender: 'Maschio',
  dateOfBirth: DateTime(1990, 1, 1),
  height: 175,
  weight: 75,
  createdAt: DateTime.now(),
);

// 2. Definisci infortuni
final injuries = [
  InjuryModel(
    id: '1',
    category: InjuryCategory.articular,
    area: InjuryArea.knee,
    severity: InjurySeverity.moderate,
    status: InjuryStatus.recovering,
    notes: 'Dolore al ginocchio destro durante squat profondi',
    reportedAt: DateTime.now(),
  ),
];

// 3. Imposta preferenze allenamento
final trainingPreferences = TrainingPreferences(
  id: '1',
  trainingSplit: TrainingSplit.pushPullLegs,
  sessionDurationMinutes: 60,
  cardioPreference: CardioPreference.minimal,
  mobilityPreference: MobilityPreference.moderate,
);

// 4. Crea profilo utente
final profile = UserProfile(
  userId: user.id,
  goal: FitnessGoal.muscleGain,
  level: ExperienceLevel.intermediate,
  weeklyFrequency: 4,
  location: TrainingLocation.gym,
  equipment: [Equipment.barbell, Equipment.dumbbells],
  limitations: [],
  injuries: injuries,
  trainingPreferences: trainingPreferences,
);

// 5. Genera scheda AI
final workoutService = WorkoutService(apiClient);
final result = await workoutService.generateAIPlan(
  user: user,
  profile: profile,
);

if (result['success']) {
  final WorkoutPlan plan = result['plan'];
  // Usa la scheda generata
}
```

### Esempio Completo UI

Vedi `ai_workout_generation_example.dart` per un esempio completo con UI.

## 📊 Formato Risposta OpenAI

L'AI restituisce un JSON strutturato:

```json
{
  "workoutPlan": {
    "name": "Programma Push/Pull/Legs Intermedio",
    "description": "Programma di 4 giorni...",
    "durationWeeks": 8,
    "weeklySchedule": [
      {
        "dayNumber": 1,
        "dayName": "Giorno 1 - Push (Petto/Spalle/Tricipiti)",
        "focusAreas": ["Petto", "Spalle", "Tricipiti"],
        "exercises": [
          {
            "name": "Panca Piana con Bilanciere",
            "sets": 4,
            "reps": "8-10",
            "rest": "90s",
            "notes": "Mantieni scapole retratte..."
          }
        ],
        "warmup": "5 minuti di cardio leggero + mobilità spalle",
        "cooldown": "Stretching pettorali e spalle"
      }
    ],
    "progressionNotes": "Aumenta il peso del 2.5-5% quando...",
    "safetyNotes": "IMPORTANTE: Evita squat profondi per il ginocchio..."
  }
}
```

## ⚙️ Installazione Dipendenze

Aggiungi al `pubspec.yaml` (già fatto):
```yaml
dependencies:
  http: ^1.2.0
```

Esegui:
```bash
flutter pub get
```

## 🔒 Sicurezza

> **IMPORTANTE**: La chiave API OpenAI è attualmente hardcoded nel file `api_config.dart`. 
> Per produzione, considera di:
> 1. Usare variabili d'ambiente
> 2. Salvare la chiave in modo sicuro (es. Flutter Secure Storage)
> 3. Implementare un proxy backend che gestisce le chiamate OpenAI

## 💰 Costi

- **Modello**: GPT-5-nano 
- **Costo stimato per generazione**: ~$0.01-0.02 per scheda
- **Max tokens**: 3000 (input + output)

Monitora l'uso su: https://platform.openai.com/usage

## 🎨 Prossimi Passi UI

Per completare l'integrazione, implementa:

1. **Schermata Infortuni** nel questionario:
   - Selezione categoria (Muscolare/Articolare/Osseo)
   - Selezione area specifica con UI intuitiva
   - Indicazione gravità e stato
   - Possibilità di aggiungere multipli infortuni

2. **Schermata Preferenze Allenamento**:
   - Selezione tipo di split
   - Slider per durata sessioni
   - Preferenze cardio e mobilità

3. **Schermata Generazione Scheda**:
   - Riepilogo profilo utente
   - Pulsante "Genera Scheda AI"
   - Loading indicator
   - Visualizzazione scheda generata
   - Opzioni per rigenerare o salvare

## 🧪 Testing

```dart
// Test con profilo completo
final result = await workoutService.generateAIPlan(
  user: testUser,
  profile: testProfile,
);

expect(result['success'], true);
expect(result['plan'].workouts.length, greaterThan(0));
```

## 📝 Note Tecniche

- Il servizio converte automaticamente la risposta OpenAI nel modello `WorkoutPlan` esistente
- Gli esercizi sono creati come oggetti `Exercise` con `WorkoutExercise`
- La durata stimata è calcolata automaticamente basandosi su serie e recuperi
- Il sistema è progettato per essere estensibile (facile aggiungere nuovi parametri)

## 🐛 Troubleshooting

### Errore "Failed to generate workout plan"
- Verifica che la chiave API OpenAI sia valida
- Controlla la connessione internet
- Verifica i limiti di rate della tua chiave API

### Scheda generata non rispetta gli infortuni
- Controlla che gli infortuni siano correttamente passati nel profilo
- Verifica il prompt in `openai_service.dart`
- Considera di aumentare l'enfasi sugli infortuni nel prompt

### Timeout durante la generazione
- Aumenta il timeout della richiesta HTTP
- Riduci `max_tokens` se necessario
- Implementa retry logic

## 📚 Risorse

- [OpenAI API Documentation](https://platform.openai.com/docs)
- [GPT-5-nano Pricing](https://openai.com/pricing)
- [Prompt Engineering Guide](https://platform.openai.com/docs/guides/prompt-engineering)
