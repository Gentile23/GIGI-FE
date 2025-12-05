---
description: Implementazione delle 3 feature per workout personalizzati - Scheda custom, Esercizi simili, Alternativa corpo libero/macchinario
---

# Custom Workout Features Implementation

## Overview
Questo documento descrive l'implementazione di 3 nuove feature per l'app FitGenius:

1. **Caricamento Scheda Personale** - L'utente crea la propria scheda selezionando esercizi dal database
2. **Esercizi Simili** - Per ogni esercizio, mostrare alternative che stimolano la stessa zona muscolare
3. **Alternativa Corpo Libero/Macchinario** - Per esercizi con attrezzatura, mostrare l'equivalente a corpo libero e viceversa

---

## Feature 1: Caricamento Scheda Personale

### Backend (Laravel)

#### 1.1 Nuova migrazione per schede custom
```bash
php artisan make:migration create_custom_workout_plans_table
```

Schema:
- `id`
- `user_id` (foreign key)
- `name` (nome della scheda)
- `description` (opzionale)
- `created_at`, `updated_at`

#### 1.2 Migrazione per esercizi della scheda custom
```bash
php artisan make:migration create_custom_workout_exercises_table
```

Schema:
- `id`
- `custom_workout_plan_id` (foreign key)
- `exercise_id` (foreign key a exercises)
- `sets` (int)
- `reps` (string)
- `rest_seconds` (int)
- `order_index` (int)
- `notes` (opzionale)

#### 1.3 Model CustomWorkoutPlan
File: `app/Models/CustomWorkoutPlan.php`

#### 1.4 Model CustomWorkoutExercise
File: `app/Models/CustomWorkoutExercise.php`

#### 1.5 Controller CustomWorkoutController
File: `app/Http/Controllers/Api/CustomWorkoutController.php`

Endpoints:
- `GET /api/custom-workouts` - Lista schede custom dell'utente
- `POST /api/custom-workouts` - Crea nuova scheda
- `GET /api/custom-workouts/{id}` - Dettaglio scheda
- `PUT /api/custom-workouts/{id}` - Modifica scheda
- `DELETE /api/custom-workouts/{id}` - Elimina scheda
- `POST /api/custom-workouts/{id}/exercises` - Aggiungi esercizio
- `PUT /api/custom-workouts/{id}/exercises/{exerciseId}` - Modifica esercizio nella scheda
- `DELETE /api/custom-workouts/{id}/exercises/{exerciseId}` - Rimuovi esercizio

### Frontend (Flutter)

#### 1.6 Model CustomWorkoutModel
File: `lib/data/models/custom_workout_model.dart`

#### 1.7 Service CustomWorkoutService
File: `lib/data/services/custom_workout_service.dart`

#### 1.8 Provider CustomWorkoutProvider
File: `lib/providers/custom_workout_provider.dart`

#### 1.9 Screens

##### CustomWorkoutListScreen
File: `lib/presentation/screens/custom_workout/custom_workout_list_screen.dart`
- Lista delle schede custom dell'utente
- FAB per creare nuova scheda

##### CreateCustomWorkoutScreen
File: `lib/presentation/screens/custom_workout/create_custom_workout_screen.dart`
- Form per nome e descrizione
- Ricerca esercizi dal database
- Aggiunta esercizi con sets/reps/rest
- Drag & drop per riordinare

##### ExerciseSearchScreen
File: `lib/presentation/screens/custom_workout/exercise_search_screen.dart`
- Ricerca con filtri (muscle group, equipment, difficulty)
- Selezione multipla esercizi

---

## Feature 2: Esercizi Simili

### Backend (Laravel)

#### 2.1 Endpoint in ExerciseController
Aggiungere metodo `similar(Exercise $exercise)`:

```php
public function similar(Exercise $exercise)
{
    // Trova esercizi con almeno un muscle_group in comune
    $muscleGroups = $exercise->muscle_groups;
    
    $similarExercises = Exercise::where('id', '!=', $exercise->id)
        ->where(function ($query) use ($muscleGroups) {
            foreach ($muscleGroups as $mg) {
                $query->orWhereJsonContains('muscle_groups', $mg);
            }
        })
        ->orderByRaw('(
            SELECT COUNT(*) FROM JSON_TABLE(muscle_groups, "$[*]" COLUMNS(mg VARCHAR(50) PATH "$")) AS jt
            WHERE jt.mg IN (' . implode(',', array_map(fn($m) => "'$m'", $muscleGroups)) . ')
        ) DESC')
        ->take(10)
        ->get();
    
    return response()->json($similarExercises);
}
```

Route: `GET /api/exercises/{exercise}/similar`

### Frontend (Flutter)

#### 2.2 Metodo in ExerciseService
```dart
Future<List<Exercise>> getSimilarExercises(String exerciseId)
```

#### 2.3 Widget SimilarExercisesSheet
File: `lib/presentation/widgets/workout/similar_exercises_sheet.dart`
- Bottom sheet con lista esercizi simili
- Card per ogni esercizio con info base
- Tap per vedere dettagli o sostituire

#### 2.4 Integrazione in ExerciseDetailScreen
Aggiungere bottone "Esercizi Simili" che apre il bottom sheet

---

## Feature 3: Alternativa Corpo Libero/Macchinario

### Backend (Laravel)

#### 3.1 Tabella exercise_alternatives (opzionale, per mapping manuale)
Se si vuole un mapping preciso, creare tabella:
- `exercise_id`
- `alternative_exercise_id`
- `type` ('bodyweight_equivalent', 'machine_equivalent')

#### 3.2 Endpoint in ExerciseController
Metodo `alternatives(Exercise $exercise)`:

```php
public function alternatives(Exercise $exercise)
{
    $hasBodyweight = in_array('Bodyweight', $exercise->equipment);
    $muscleGroups = $exercise->muscle_groups;
    
    $query = Exercise::where('id', '!=', $exercise->id)
        ->where(function ($q) use ($muscleGroups) {
            foreach ($muscleGroups as $mg) {
                $q->orWhereJsonContains('muscle_groups', $mg);
            }
        });
    
    if ($hasBodyweight) {
        // Esercizio a corpo libero -> trova equivalenti con macchinari
        $query->where(function ($q) {
            $q->whereJsonContains('equipment', 'Machine')
              ->orWhereJsonContains('equipment', 'Cable')
              ->orWhereJsonContains('equipment', 'Barbell')
              ->orWhereJsonContains('equipment', 'Dumbbell');
        })
        ->whereJsonDoesntContain('equipment', 'Bodyweight');
    } else {
        // Esercizio con macchinario -> trova equivalenti a corpo libero
        $query->whereJsonContains('equipment', 'Bodyweight');
    }
    
    return response()->json([
        'current_type' => $hasBodyweight ? 'bodyweight' : 'equipment',
        'alternatives' => $query->take(10)->get()
    ]);
}
```

Route: `GET /api/exercises/{exercise}/alternatives`

### Frontend (Flutter)

#### 3.3 Metodo in ExerciseService
```dart
Future<Map<String, dynamic>> getExerciseAlternatives(String exerciseId)
```

#### 3.4 Widget AlternativeExercisesSheet
File: `lib/presentation/widgets/workout/alternative_exercises_sheet.dart`
- Bottom sheet con alternative
- Indica se l'esercizio corrente è "Corpo Libero" o "Con Attrezzatura"
- Lista alternative con badge del tipo

#### 3.5 Integrazione in ExerciseDetailScreen
Aggiungere bottone "Vedi Alternativa" (corpo libero/macchinario)

---

## Ordine di Implementazione Consigliato

### Fase 1: Backend
1. Feature 2: Similar exercises endpoint
2. Feature 3: Alternative exercises endpoint
3. Feature 1: Custom workout migrations, models, controller

### Fase 2: Frontend - Base
1. Feature 2: Similar exercises service + widget
2. Feature 3: Alternative exercises service + widget
3. Integrazione in ExerciseDetailScreen

### Fase 3: Frontend - Custom Workout
1. Models
2. Service
3. Provider
4. ExerciseSearchScreen
5. CreateCustomWorkoutScreen
6. CustomWorkoutListScreen
7. Routing e integrazione nel MainScreen

---

## File da Creare/Modificare

### Backend (Gest_One)
- [x] `database/migrations/2025_12_05_130000_create_custom_workout_plans_table.php` ✅
- [x] `database/migrations/2025_12_05_130001_create_custom_workout_exercises_table.php` ✅
- [x] `app/Models/CustomWorkoutPlan.php` ✅
- [x] `app/Models/CustomWorkoutExercise.php` ✅
- [x] `app/Http/Controllers/Api/CustomWorkoutController.php` ✅
- [x] `app/Http/Controllers/Api/ExerciseController.php` (modificare - added similar() and alternatives()) ✅
- [x] `routes/api.php` (modificare - added custom workouts and exercise endpoints) ✅

### Frontend (fitgenius)
- [x] `lib/data/models/custom_workout_model.dart` ✅
- [x] `lib/data/services/custom_workout_service.dart` ✅
- [x] `lib/data/services/exercise_service.dart` (modificare - added getSimilarExercises and getAlternativeExercises) ✅
- [ ] `lib/providers/custom_workout_provider.dart` (opzionale, usando service direttamente)
- [x] `lib/presentation/screens/custom_workout/custom_workout_list_screen.dart` ✅
- [x] `lib/presentation/screens/custom_workout/create_custom_workout_screen.dart` ✅
- [x] `lib/presentation/screens/custom_workout/exercise_search_screen.dart` ✅
- [x] `lib/presentation/widgets/workout/similar_exercises_sheet.dart` ✅
- [x] `lib/presentation/widgets/workout/alternative_exercises_sheet.dart` ✅
- [x] `lib/presentation/screens/workout/exercise_detail_screen.dart` (modificare) ✅
- [x] `lib/presentation/screens/home/enhanced_home_screen.dart` (modificare per navigation) ✅

---

## Status: ✅ IMPLEMENTAZIONE COMPLETATA

Tutte e 3 le feature sono state implementate:

1. **Caricamento Scheda Personale** - Completa
   - Backend: Migrazioni, Models, Controller
   - Frontend: Screens per lista, creazione, ricerca esercizi

2. **Esercizi Simili** - Completa  
   - Backend: Endpoint `/api/exercises/{id}/similar`
   - Frontend: SimilarExercisesSheet integrato in ExerciseDetailScreen

3. **Alternativa Corpo Libero/Macchinario** - Completa
   - Backend: Endpoint `/api/exercises/{id}/alternatives`
   - Frontend: AlternativeExercisesSheet integrato in ExerciseDetailScreen

