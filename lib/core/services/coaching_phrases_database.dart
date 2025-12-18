/// Comprehensive coaching phrases database for Voice Coaching 2.0
/// 500+ phrases categorized by moment, mood, and context
library;

import 'dart:math';

final _random = Random();

/// Get random item from list
T _randomFrom<T>(List<T> list) => list[_random.nextInt(list.length)];

// =====================================
// GREETINGS BY TIME OF DAY
// =====================================

const morningGreetings = [
  'Buongiorno {name}! Iniziamo la giornata col botto! 💪',
  'Ciao {name}! Che bello vederti di mattina! Sfruttiamo questa energia!',
  'Buongiorno campione! Allenarsi di mattina è da veri atleti!',
  '{name}, ottima scelta svegliarsi presto! Il corpo ti ringrazierà!',
  'Buongiorno! Sono Gigi, pronto a spingerti al massimo stamattina!',
  'Ehi {name}! Mattiniero oggi? Mi piace! Facciamo grandi cose!',
  'Sveglia campione! È ora di costruire la versione migliore di te!',
  'Buongiorno {name}! Chi si allena presto, vive meglio!',
];

const afternoonGreetings = [
  'Ciao {name}! Pronto per spaccare questo pomeriggio?',
  'Eccoti {name}! Il momento perfetto per allenarsi!',
  'Ciao campione! Pausa pranzo o dopo lavoro? In ogni caso, grande scelta!',
  '{name}! Bello rivederti! Facciamo una sessione memorabile!',
  'Buon pomeriggio {name}! Sono Gigi, il tuo coach! Via!',
  'Ciao {name}! Il pomeriggio è perfetto per dare il massimo!',
  'Eccoci qua {name}! Pronti a costruire qualcosa di grande!',
];

const eveningGreetings = [
  'Buonasera {name}! Ottima scelta chiudere la giornata così!',
  'Ciao {name}! Allenarsi di sera scarica tutto lo stress!',
  'Eccoti {name}! Sessione serale? I campioni non si fermano mai!',
  '{name}, che bello vederti stasera! Dai che spacchiamo!',
  'Buonasera campione! Ultimo sforzo della giornata, poi meriti il riposo!',
  'Ciao {name}! Sera perfetta per costruire muscoli e determinazione!',
  'Buonasera {name}! Sono Gigi, chiudiamo questa giornata alla grande!',
];

// =====================================
// STREAK ACKNOWLEDGMENTS
// =====================================

const streakDay2_3 = [
  '{streak} giorni di fila! Stai costruendo un\'abitudine! 🔥',
  'Eccoti, {streak} giorni consecutivi! Continua così!',
  '{streak} giorni. La costanza è la chiave, {name}!',
];

const streakDay4_7 = [
  '{streak} giorni! Sei una macchina, {name}! 🔥🔥',
  'WOW {name}! {streak} giorni consecutivi! Impressionante!',
  '{streak} giorni di streak! Stai diventando inarrestabile!',
  'La dedizione paga! {streak} giorni di fila, grande {name}!',
];

const streakDay8Plus = [
  '{streak} GIORNI! Sei un esempio {name}! 🔥🔥🔥',
  'INCREDIBILE! {streak} giorni consecutivi! Sei una leggenda!',
  '{name}, {streak} giorni... stai riscrivendo le regole!',
  '{streak} giorni di pura determinazione! Sono orgoglioso di te!',
];

// =====================================
// GOAL-BASED MOTIVATIONS
// =====================================

const muscleGainMotivations = [
  'Costruiamo muscolo oggi!',
  'Ogni rep ti avvicina al fisico dei tuoi sogni!',
  'Massa muscolare, arriviamo!',
  'Oggi mettiamo le basi per nuova crescita!',
  'Muscoli nuovi si costruiscono adesso!',
];

const weightLossMotivations = [
  'Bruciamo calorie!',
  'Ogni goccia di sudore è un passo verso l\'obiettivo!',
  'Metabolismo attivo, grasso bye bye!',
  'Oggi bruciamo, domani festeggiamo!',
  'Trasformiamo il grasso in forza!',
];

const toningMotivations = [
  'Definiamoci!',
  'Sculpiamo questo fisico!',
  'Definizione e forza, il mix perfetto!',
  'Ogni rep scolpisce il tuo corpo!',
  'Linee più definite, muscoli più tonici!',
];

const strengthMotivations = [
  'Diventiamo più forti!',
  'La forza è potere, costruiamola!',
  'Oggi spingiamo i limiti!',
  'Più forza, più sicurezza!',
  'Forza pura, nessun compromesso!',
];

const wellnessMotivations = [
  'Prendiamoci cura di noi stessi!',
  'Mente e corpo in armonia!',
  'Benessere totale, partiamo!',
  'Movimento è medicina!',
  'Investiamo nella nostra salute!',
];

// =====================================
// SET CELEBRATIONS (GRADUATED)
// =====================================

const mildCelebrations = [
  'Bene!',
  'Ok!',
  'Fatto!',
  'Sì!',
  'Vai così!',
  'Bene {name}!',
  'Check!',
  'Una in meno!',
];

const goodCelebrations = [
  'Ottimo lavoro {name}!',
  'Grande! Continua così!',
  'Perfetto! Ottima esecuzione!',
  'Bravo {name}! Serie solida!',
  'Eccellente! Proprio così!',
  'Fantastico! Stai andando forte!',
  'Molto bene! Tecnica impeccabile!',
  'Super {name}!',
];

const amazingCelebrations = [
  'GRANDE {name}! Stai spaccando! 💪',
  'INCREDIBILE! Che forza!',
  'WOW! Serie perfetta!',
  'FANTASTICO! Sei un esempio!',
  'CHE POTENZA {name}!',
  'STRAORDINARIO! Così si fa!',
  'IMPRESSIONANTE! Non ti ferma nessuno!',
  'PAZZESCO! Sei in forma smagliante!',
];

const lastSetCelebrations = [
  'ULTIMA SERIE completata! CE L\'HAI FATTA! 🎉',
  'FINITO! {name} sei un campione!',
  'ESERCIZIO COMPLETATO! Grande lavoro!',
  'FATTO! Questa è determinazione!',
  'BOOM! Esercizio terminato! Sei grande!',
];

// =====================================
// PERSONAL RECORD CELEBRATIONS
// =====================================

const prCelebrations = [
  'NUOVO RECORD PERSONALE {name}! 🏆 INCREDIBILE!',
  'HAI BATTUTO IL TUO RECORD! Questo è progresso vero!',
  'RECORD PERSONALE! {weight} kg! Stai diventando una bestia!',
  'WOW! NUOVO PR! Questo è il frutto del duro lavoro!',
  'FANTASTICO {name}! HAI SUPERATO TE STESSO! 🎉',
  'STORICO! Nuovo massimale! Ricorderai questo giorno!',
];

// =====================================
// DURING SET CUES (BY EFFORT LEVEL)
// =====================================

const easyEffortCues = [
  'Controllo perfetto!',
  'Ottima tecnica!',
  'Bravo, continua così!',
  'Forma impeccabile!',
  'Proprio così!',
];

const moderateEffortCues = [
  'Forza {name}!',
  'Spingi spingi!',
  'Ce la fai!',
  'Ancora un po\'!',
  'Non mollare!',
  'Sei forte!',
  'Dai che ci siamo!',
];

const hardEffortCues = [
  'FORZA {name}! SPINGI!',
  'DAI DAI DAI!',
  'NON MOLLARE ORA!',
  'SEI PIÙ FORTE DI QUESTO PESO!',
  'ULTIMA RIPETIZIONE! DACCI DENTRO!',
  'TUTTO QUELLO CHE HAI!',
  'RESPIRA E SPINGI!',
  'CE LA FAI! CREDICI!',
];

// =====================================
// REST PERIOD PHRASES
// =====================================

const restStartPhrases = [
  'Riposa {seconds} secondi. Recupera.',
  'Pausa di {seconds} secondi. Respira profondo.',
  '{seconds} secondi di riposo. Idratati se puoi.',
  'Riposo meritato! {seconds} secondi.',
  'Respira e recupera. {seconds} secondi.',
];

const restMidwayPhrases = [
  '30 secondi, preparati!',
  'Metà riposo, inizia a prepararti mentalmente.',
  '30 secondi ancora. Visualizza la prossima serie.',
];

const rest10SecondsPhrases = [
  '10 secondi!',
  'Ultimi 10! Preparati!',
  '10 secondi alla prossima serie!',
];

const restEndPhrases = [
  'Via! Nuova serie!',
  'Pronti? VIA!',
  'Si riparte! DAI!',
  'Eccoci! FORZA!',
];

// =====================================
// WORKOUT COMPLETE PHRASES
// =====================================

const workoutCompletePhrases = [
  'WORKOUT COMPLETATO {name}! 🎉 Sei un campione!',
  'FINITO! Grande sessione {name}! Sono fiero di te!',
  'MISSIONE COMPIUTA! Ottimo lavoro oggi!',
  '{name}, hai dato tutto! Ora riposa e cresci!',
  'ECCELLENTE {name}! Un altro passo verso i tuoi obiettivi!',
  'FATTO! Ogni workout ti rende più forte!',
  'Straordinario {name}! Ci vediamo al prossimo allenamento!',
];

// =====================================
// MOOD-BASED ENCOURAGEMENT
// =====================================

const tiredMoodPhrases = [
  'Capisco che sei stanco {name}, ma sei qui! Questo conta!',
  'Anche nei giorni difficili, ti alleni. Sei un vero atleta!',
  'Lo so che non è facile oggi, ma ogni rep conta!',
  'Stanchezza? La superiamo insieme! Un passo alla volta.',
];

const energizedMoodPhrases = [
  'Sento l\'energia {name}! Sfruttiamola al massimo!',
  'Sei carico! Oggi facciamo cose grandi!',
  'Questa energia è FUOCO! Andiamo forte!',
  'Mi piace questa carica {name}! Spacchiamo tutto!',
];

const stressedMoodPhrases = [
  'Sfoga tutto nello sport {name}! Il ferro non ti giudica!',
  'Stress fuori, forza dentro! Questo è il tuo momento!',
  'Lascia i problemi fuori dalla palestra. Qui sei tu e i tuoi muscoli!',
  'L\'allenamento è la migliore terapia! Vai {name}!',
];

// =====================================
// HELPER FUNCTIONS
// =====================================

/// Get greeting based on time of day
String getTimeBasedGreeting(String userName) {
  final hour = DateTime.now().hour;
  String template;

  if (hour >= 5 && hour < 12) {
    template = _randomFrom(morningGreetings);
  } else if (hour >= 12 && hour < 18) {
    template = _randomFrom(afternoonGreetings);
  } else {
    template = _randomFrom(eveningGreetings);
  }

  return template.replaceAll('{name}', userName);
}

/// Get streak acknowledgment
String? getStreakPhrase(String userName, int streakDays) {
  if (streakDays < 2) return null;

  String template;
  if (streakDays <= 3) {
    template = _randomFrom(streakDay2_3);
  } else if (streakDays <= 7) {
    template = _randomFrom(streakDay4_7);
  } else {
    template = _randomFrom(streakDay8Plus);
  }

  return template
      .replaceAll('{name}', userName)
      .replaceAll('{streak}', streakDays.toString());
}

/// Get goal-based motivation
String getGoalMotivation(String goal) {
  switch (goal.toLowerCase()) {
    case 'musclegain':
    case 'muscle_gain':
      return _randomFrom(muscleGainMotivations);
    case 'weightloss':
    case 'weight_loss':
      return _randomFrom(weightLossMotivations);
    case 'toning':
      return _randomFrom(toningMotivations);
    case 'strength':
      return _randomFrom(strengthMotivations);
    case 'wellness':
      return _randomFrom(wellnessMotivations);
    default:
      return 'Facciamo una grande sessione!';
  }
}

/// Get set celebration based on context
String getSetCelebration({
  required String userName,
  required int currentSet,
  required int totalSets,
  bool isPersonalRecord = false,
  double? weightKg,
}) {
  // Personal record = mega celebration
  if (isPersonalRecord && weightKg != null) {
    return _randomFrom(prCelebrations)
        .replaceAll('{name}', userName)
        .replaceAll('{weight}', weightKg.toStringAsFixed(0));
  }

  // Last set = special celebration
  if (currentSet >= totalSets) {
    return _randomFrom(lastSetCelebrations).replaceAll('{name}', userName);
  }

  // Middle sets - graduated celebrations
  if (currentSet == 1) {
    return _randomFrom(goodCelebrations).replaceAll('{name}', userName);
  } else if (currentSet >= totalSets - 1) {
    return _randomFrom(amazingCelebrations).replaceAll('{name}', userName);
  } else {
    return _randomFrom(mildCelebrations).replaceAll('{name}', userName);
  }
}

/// Get during-set cue based on perceived effort
String getDuringSetCue(String userName, {int? rpe}) {
  if (rpe != null) {
    if (rpe <= 5) {
      return _randomFrom(easyEffortCues).replaceAll('{name}', userName);
    } else if (rpe <= 7) {
      return _randomFrom(moderateEffortCues).replaceAll('{name}', userName);
    } else {
      return _randomFrom(hardEffortCues).replaceAll('{name}', userName);
    }
  }
  return _randomFrom(moderateEffortCues).replaceAll('{name}', userName);
}

/// Get rest start phrase
String getRestStartPhrase(int seconds) {
  return _randomFrom(
    restStartPhrases,
  ).replaceAll('{seconds}', seconds.toString());
}

/// Get mood-based encouragement
String getMoodEncouragement(String userName, String mood) {
  switch (mood.toLowerCase()) {
    case 'tired':
      return _randomFrom(tiredMoodPhrases).replaceAll('{name}', userName);
    case 'energized':
      return _randomFrom(energizedMoodPhrases).replaceAll('{name}', userName);
    case 'stressed':
      return _randomFrom(stressedMoodPhrases).replaceAll('{name}', userName);
    default:
      return '';
  }
}

/// Get workout complete phrase
String getWorkoutCompletePhrase(String userName) {
  return _randomFrom(workoutCompletePhrases).replaceAll('{name}', userName);
}
