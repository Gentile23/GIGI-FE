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
    Map<String, dynamic>? bodyMeasurements,
  }) async {
    try {
      final prompt = _buildPrompt(user, profile, bodyMeasurements);

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
- Analisi delle proporzioni corporee per un allenamento bilanciato

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
    "safetyNotes": "Note di sicurezza specifiche per gli infortuni dell'utente",
    "bodyFocusAreas": "Aree del corpo su cui concentrarsi in base alle proporzioni"
  }
}

Regole fondamentali:
1. EVITA COMPLETAMENTE esercizi che coinvolgono aree infortunate
2. Suggerisci alternative sicure quando necessario
3. Rispetta il livello di esperienza dell'utente
4. Adatta il volume alle capacità di recupero
5. Includi sempre riscaldamento e defaticamento appropriati
6. Fornisci progressioni chiare e sicure
7. I nomi degli esercizi devono essere SEMPRE in INGLESE (es. "Bench Press" non "Panca Piana")
8. Rispetta RIGOROSAMENTE l'ordine di Cardio e Mobilità indicato nelle preferenze
9. Se fornite le misure corporee, analizza le proporzioni e suggerisci focus specifici
''';
  }

  /// Build detailed prompt with user information
  String _buildPrompt(
    UserModel user,
    UserProfile profile,
    Map<String, dynamic>? measurements,
  ) {
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

    // Body measurements section - COMPLETE
    if (measurements != null && measurements.isNotEmpty) {
      buffer.writeln(
        '📏 MISURE CORPOREE DETTAGLIATE (usa per personalizzare la scheda):',
      );
      buffer.writeln('');

      // Arms
      buffer.writeln('💪 BRACCIA:');
      if (measurements['bicep_right_cm'] != null) {
        buffer.writeln('  - Bicipite DX: ${measurements['bicep_right_cm']} cm');
      }
      if (measurements['bicep_left_cm'] != null) {
        buffer.writeln('  - Bicipite SX: ${measurements['bicep_left_cm']} cm');
      }
      if (measurements['forearm_cm'] != null) {
        buffer.writeln('  - Avambraccio: ${measurements['forearm_cm']} cm');
      }

      // Torso
      buffer.writeln('🫁 TORSO:');
      if (measurements['shoulders_cm'] != null) {
        buffer.writeln('  - Spalle: ${measurements['shoulders_cm']} cm');
      }
      if (measurements['chest_cm'] != null) {
        buffer.writeln('  - Petto: ${measurements['chest_cm']} cm');
      }
      if (measurements['waist_cm'] != null) {
        buffer.writeln('  - Vita: ${measurements['waist_cm']} cm');
      }
      if (measurements['hips_cm'] != null) {
        buffer.writeln('  - Fianchi: ${measurements['hips_cm']} cm');
      }
      if (measurements['neck_cm'] != null) {
        buffer.writeln('  - Collo: ${measurements['neck_cm']} cm');
      }

      // Legs
      buffer.writeln('🦵 GAMBE:');
      if (measurements['thigh_right_cm'] != null) {
        buffer.writeln('  - Coscia DX: ${measurements['thigh_right_cm']} cm');
      }
      if (measurements['thigh_left_cm'] != null) {
        buffer.writeln('  - Coscia SX: ${measurements['thigh_left_cm']} cm');
      }
      if (measurements['calf_cm'] != null) {
        buffer.writeln('  - Polpaccio: ${measurements['calf_cm']} cm');
      }

      // Body composition
      buffer.writeln('⚖️ COMPOSIZIONE CORPOREA:');
      if (measurements['weight_kg'] != null) {
        buffer.writeln(
          '  - Peso (dalla misura): ${measurements['weight_kg']} kg',
        );
      }
      if (measurements['body_fat_percentage'] != null) {
        buffer.writeln(
          '  - Massa grassa: ${measurements['body_fat_percentage']}%',
        );
      }

      // Calculate and suggest focus areas
      buffer.writeln('');
      buffer.writeln('🎯 ANALISI PROPORZIONI E SUGGERIMENTI:');

      // Waist-to-hip ratio
      if (measurements['waist_cm'] != null && measurements['hips_cm'] != null) {
        final ratio =
            (measurements['waist_cm'] as num) /
            (measurements['hips_cm'] as num);
        buffer.writeln('- Rapporto vita/fianchi: ${ratio.toStringAsFixed(2)}');
        if (ratio > 0.95) {
          buffer.writeln(
            '  → PRIORITÀ: Esercizi core intensi e HIIT cardio per riduzione addominale',
          );
        } else if (ratio > 0.85) {
          buffer.writeln('  → Focus: Mantenimento core, buona proporzione');
        } else {
          buffer.writeln(
            '  → Ottimo rapporto, focus su tonificazione generale',
          );
        }
      }

      // Bicep asymmetry
      if (measurements['bicep_right_cm'] != null &&
          measurements['bicep_left_cm'] != null) {
        final diff =
            ((measurements['bicep_right_cm'] as num) -
                    (measurements['bicep_left_cm'] as num))
                .abs();
        if (diff > 1.5) {
          buffer.writeln(
            '- ⚠️ Asimmetria braccia significativa: ${diff.toStringAsFixed(1)} cm',
          );
          buffer.writeln(
            '  → IMPORTANTE: Usa SOLO esercizi unilaterali per braccia (dumbbell curls, single arm exercises)',
          );
        } else if (diff > 0.5) {
          buffer.writeln(
            '- Leggera asimmetria braccia: ${diff.toStringAsFixed(1)} cm',
          );
          buffer.writeln('  → Considera qualche esercizio unilaterale');
        }
      }

      // Thigh asymmetry
      if (measurements['thigh_right_cm'] != null &&
          measurements['thigh_left_cm'] != null) {
        final diff =
            ((measurements['thigh_right_cm'] as num) -
                    (measurements['thigh_left_cm'] as num))
                .abs();
        if (diff > 2) {
          buffer.writeln(
            '- ⚠️ Asimmetria gambe: ${diff.toStringAsFixed(1)} cm',
          );
          buffer.writeln(
            '  → Includi esercizi unilaterali per gambe (single leg press, lunges)',
          );
        }
      }

      // Shoulder-to-waist ratio (V-taper indicator)
      if (measurements['shoulders_cm'] != null &&
          measurements['waist_cm'] != null) {
        final vTaper =
            (measurements['shoulders_cm'] as num) /
            (measurements['waist_cm'] as num);
        buffer.writeln(
          '- Rapporto spalle/vita (V-taper): ${vTaper.toStringAsFixed(2)}',
        );
        if (vTaper < 1.3) {
          buffer.writeln(
            '  → PRIORITÀ: Esercizi spalle larghe (lateral raises, wide grip pull-ups, overhead press)',
          );
        } else if (vTaper < 1.45) {
          buffer.writeln(
            '  → Focus: Sviluppo spalle per migliorare proporzioni',
          );
        } else {
          buffer.writeln('  → Ottimo V-taper, mantieni proporzioni');
        }
      }

      // Chest-to-waist ratio
      if (measurements['chest_cm'] != null &&
          measurements['waist_cm'] != null) {
        final chestRatio =
            (measurements['chest_cm'] as num) /
            (measurements['waist_cm'] as num);
        buffer.writeln(
          '- Rapporto petto/vita: ${chestRatio.toStringAsFixed(2)}',
        );
        if (chestRatio < 1.15) {
          buffer.writeln(
            '  → Focus: Esercizi petto per sviluppo torace (bench press, flyes, dips)',
          );
        }
      }

      // Body fat suggestions
      if (measurements['body_fat_percentage'] != null) {
        final bf = measurements['body_fat_percentage'] as num;
        if (bf > 25) {
          buffer.writeln('- Massa grassa elevata: $bf%');
          buffer.writeln(
            '  → PRIORITÀ: Più cardio/HIIT, circuit training per bruciare calorie',
          );
        } else if (bf > 18) {
          buffer.writeln('- Massa grassa moderata: $bf%');
          buffer.writeln('  → Bilanciare forza e cardio');
        } else if (bf > 12) {
          buffer.writeln('- Buona massa grassa: $bf%');
          buffer.writeln('  → Focus su ipertrofia e definizione');
        }
      }

      buffer.writeln('');
      buffer.writeln('ISTRUZIONI BASATE SULLE MISURE:');
      buffer.writeln('1. Usa le misure per identificare punti deboli e forte');
      buffer.writeln('2. Bilancia il programma per correggere asimmetrie');
      buffer.writeln('3. Prioritizza le aree che necessitano più sviluppo');
      buffer.writeln('4. Adatta volume ed esercizi alle proporzioni corporee');
      buffer.writeln('');
    }

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

      // ORDERING INSTRUCTIONS
      buffer.writeln('');
      buffer.writeln('ISTRUZIONI ORDINE ESERCIZI:');

      // Cardio Ordering
      if (prefs.cardioPreference.toString().contains('warmUp')) {
        buffer.writeln(
          '- INCLUDI il Cardio nel campo "warmup" (Riscaldamento)',
        );
      } else if (prefs.cardioPreference.toString().contains('postWorkout')) {
        buffer.writeln(
          '- INCLUDI il Cardio nel campo "cooldown" o come ultimo esercizio',
        );
      }

      // Mobility Ordering
      if (prefs.mobilityPreference.toString().contains('preWorkout')) {
        buffer.writeln(
          '- INCLUDI la Mobilità nel campo "warmup" PRIMA del workouot principale',
        );
      } else if (prefs.mobilityPreference.toString().contains('postWorkout')) {
        buffer.writeln('- INCLUDI lo Stretching/Mobilità nel campo "cooldown"');
      }
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
