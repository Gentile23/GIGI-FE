import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/user_profile_model.dart';
import '../models/training_preferences_model.dart';
import '../models/injury_model.dart';
import '../../core/constants/api_config.dart';

/// Service for generating workout plans using OpenAI GPT-5-nano
class OpenAIService {
  /// Generate a personalized workout plan using OpenAI
  Future<Map<String, dynamic>> generateWorkoutPlan({
    required UserModel user,
    required UserProfile profile,
  }) async {
    try {
      final prompt = _buildPrompt(user, profile);

      final response = await http.post(
        Uri.parse(
          '${ApiConfig.openAiBaseUrl}${ApiConfig.openAiChatCompletionsEndpoint}',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.openAiApiKey}',
        },
        body: jsonEncode({
          'model': ApiConfig.openAiModel,
          'messages': [
            {'role': 'system', 'content': _getSystemPrompt()},
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.7,
          'max_tokens': 3000,
          'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        return jsonDecode(content) as Map<String, dynamic>;
      } else {
        throw Exception(
          'Failed to generate workout plan: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error generating workout plan: $e');
    }
  }

  /// System prompt with role definition and output format
  String _getSystemPrompt() {
    return '''Sei un personal trainer esperto certificato con oltre 15 anni di esperienza nella creazione di programmi di allenamento personalizzati. 

La tua specializzazione include:
- Programmazione scientifica dell'allenamento
- Prevenzione e gestione infortuni
- Periodizzazione e progressione
- Biomeccanica e tecnica degli esercizi
- Adattamento dei programmi a limitazioni fisiche

IMPORTANTE: Devi rispondere SEMPRE in formato JSON valido seguendo ESATTAMENTE questa struttura:

{
  "workoutPlan": {
    "name": "Nome del programma",
    "description": "Descrizione dettagliata del programma",
    "durationWeeks": numero_settimane,
    "weeklySchedule": [
      {
        "dayNumber": 1,
        "dayName": "Nome giorno (es. Giorno 1 - Push)",
        "focusAreas": ["area1", "area2"],
        "exercises": [
          {
            "name": "Nome esercizio",
            "sets": numero_serie,
            "reps": "range ripetizioni (es. 8-12)",
            "rest": "tempo recupero (es. 90s)",
            "notes": "Note tecniche e precauzioni"
          }
        ],
        "warmup": "Descrizione riscaldamento",
        "cooldown": "Descrizione defaticamento"
      }
    ],
    "progressionNotes": "Note sulla progressione",
    "safetyNotes": "Note di sicurezza specifiche per gli infortuni dell'utente"
  }
}

Regole fondamentali:
1. EVITA COMPLETAMENTE esercizi che coinvolgono aree infortunate
2. Suggerisci alternative sicure quando necessario
3. Rispetta il livello di esperienza dell'utente
4. Adatta il volume alle capacità di recupero
5. Includi sempre riscaldamento e defaticamento appropriati
6. Fornisci progressioni chiare e sicure
''';
  }

  /// Build detailed prompt with user information
  String _buildPrompt(UserModel user, UserProfile profile) {
    final buffer = StringBuffer();

    buffer.writeln('Crea una scheda di allenamento personalizzata per:');
    buffer.writeln('');

    // User basic info
    buffer.writeln('INFORMAZIONI UTENTE:');
    buffer.writeln('- Nome: ${user.name}');
    if (user.gender != null) {
      buffer.writeln('- Genere: ${user.gender}');
    }
    if (user.dateOfBirth != null) {
      final age = DateTime.now().year - user.dateOfBirth!.year;
      buffer.writeln('- Età: $age anni');
    }
    if (user.height != null) {
      buffer.writeln('- Altezza: ${user.height} cm');
    }
    if (user.weight != null) {
      buffer.writeln('- Peso: ${user.weight} kg');
    }
    buffer.writeln('');

    // Fitness goals and experience
    buffer.writeln('OBIETTIVI E ESPERIENZA:');
    buffer.writeln(
      '- Obiettivo: ${profile.goal != null ? _getFitnessGoalDescription(profile.goal!) : "Non specificato"}',
    );
    buffer.writeln(
      '- Livello: ${profile.level != null ? _getExperienceLevelDescription(profile.level!) : "Non specificato"}',
    );
    buffer.writeln(
      '- Frequenza settimanale: ${profile.weeklyFrequency} giorni',
    );
    buffer.writeln(
      '- Luogo allenamento: ${profile.location == TrainingLocation.gym ? "Palestra" : "Casa"}',
    );
    buffer.writeln('');

    // Equipment available
    buffer.writeln('ATTREZZATURA DISPONIBILE:');
    if (profile.equipment != null) {
      for (final eq in profile.equipment!) {
        buffer.writeln('- ${_getEquipmentDescription(eq)}');
      }
    }
    buffer.writeln('');

    // Training preferences
    if (profile.trainingPreferences != null) {
      final prefs = profile.trainingPreferences!;
      buffer.writeln('PREFERENZE DI ALLENAMENTO:');
      buffer.writeln('- Split: ${prefs.trainingSplit.displayName}');
      buffer.writeln('  ${prefs.trainingSplit.description}');
      buffer.writeln(
        '- Durata sessione: ${prefs.sessionDurationMinutes} minuti',
      );
      buffer.writeln('- Cardio: ${prefs.cardioPreference.displayName}');
      buffer.writeln('  ${prefs.cardioPreference.description}');
      buffer.writeln('- Mobilità: ${prefs.mobilityPreference.displayName}');
      buffer.writeln('  ${prefs.mobilityPreference.description}');
      buffer.writeln('');
    }

    // Injuries - CRITICAL SECTION
    if (profile.injuries.isNotEmpty) {
      buffer.writeln('⚠️ INFORTUNI E LIMITAZIONI (PRIORITÀ MASSIMA):');
      for (final injury in profile.injuries) {
        buffer.writeln(
          '- ${injury.area.displayName} (${injury.category.displayName})',
        );
        buffer.writeln(
          '  Gravità: ${injury.severity.displayName} | Stato: ${injury.status.displayName}',
        );
        if (injury.notes != null && injury.notes!.isNotEmpty) {
          buffer.writeln('  Note: ${injury.notes}');
        }
      }
      buffer.writeln('');
      buffer.writeln(
        'IMPORTANTE: Evita COMPLETAMENTE esercizi che sollecitano queste aree.',
      );
      buffer.writeln(
        'Suggerisci alternative sicure e modifiche agli esercizi quando necessario.',
      );
      buffer.writeln('');
    }

    // Other limitations
    if (profile.limitations.isNotEmpty) {
      buffer.writeln('ALTRE LIMITAZIONI:');
      for (final limitation in profile.limitations) {
        buffer.writeln('- $limitation');
      }
      buffer.writeln('');
    }

    // Final instructions
    buffer.writeln('ISTRUZIONI FINALI:');
    buffer.writeln(
      '1. Crea un programma di ${profile.weeklyFrequency} giorni a settimana',
    );
    if (profile.trainingPreferences != null) {
      buffer.writeln(
        '2. Usa lo split: ${profile.trainingPreferences!.trainingSplit.displayName}',
      );
      buffer.writeln(
        '3. Ogni sessione deve durare circa ${profile.trainingPreferences!.sessionDurationMinutes} minuti',
      );
    }
    buffer.writeln('4. Rispetta RIGOROSAMENTE gli infortuni indicati');
    buffer.writeln('5. Adatta il volume al livello di esperienza');
    buffer.writeln('6. Includi progressioni chiare per le prossime settimane');
    buffer.writeln('7. Fornisci note tecniche dettagliate per ogni esercizio');

    return buffer.toString();
  }

  String _getFitnessGoalDescription(FitnessGoal goal) {
    switch (goal) {
      case FitnessGoal.weightLoss:
        return 'Perdita di peso';
      case FitnessGoal.muscleGain:
        return 'Aumento massa muscolare';
      case FitnessGoal.toning:
        return 'Tonificazione';
      case FitnessGoal.strength:
        return 'Aumento forza';
      case FitnessGoal.wellness:
        return 'Benessere generale';
    }
  }

  String _getExperienceLevelDescription(ExperienceLevel level) {
    switch (level) {
      case ExperienceLevel.beginner:
        return 'Principiante';
      case ExperienceLevel.intermediate:
        return 'Intermedio';
      case ExperienceLevel.advanced:
        return 'Avanzato';
    }
  }

  String _getEquipmentDescription(Equipment eq) {
    switch (eq) {
      case Equipment.bench:
        return 'Panca';
      case Equipment.dumbbells:
        return 'Manubri';
      case Equipment.barbell:
        return 'Bilanciere';
      case Equipment.resistanceBands:
        return 'Bande elastiche';
      case Equipment.machines:
        return 'Macchine';
      case Equipment.bodyweight:
        return 'Corpo libero';
    }
  }
}
