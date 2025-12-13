/// Comprehensive exercise coaching scripts for voice coaching
/// Each exercise has: position setup, movement, breathing, visualization, and during-set cues
library;

import 'dart:math';

/// Exercise coaching script with all voice coaching content
class ExerciseCoachingScript {
  final String exerciseName;
  final String muscleGroups;
  final String positionSetup;
  final String movementDescription;
  final String breathingCue;
  final String visualizationCue;
  final List<String> duringSetCues;

  const ExerciseCoachingScript({
    required this.exerciseName,
    required this.muscleGroups,
    required this.positionSetup,
    required this.movementDescription,
    required this.breathingCue,
    required this.visualizationCue,
    required this.duringSetCues,
  });

  /// Get full explanation for first set (beginners)
  String getFullExplanation(String userName) {
    return 'Ok $userName, ora eseguiamo $exerciseName. '
        '$positionSetup. '
        '$movementDescription. '
        '$breathingCue. '
        '$visualizationCue. '
        'Pronti? 3... 2... 1... Via!';
  }

  /// Get brief explanation (intermediate)
  String getBriefExplanation(String userName) {
    return '$userName, iniziamo $exerciseName. '
        'Ricorda: $breathingCue. '
        '3... 2... 1... Via!';
  }

  /// Get random during-set cue
  String getRandomCue() {
    if (duringSetCues.isEmpty) return '';
    return duringSetCues[Random().nextInt(duringSetCues.length)];
  }
}

// =====================================
// CHEST EXERCISES
// =====================================

const _benchPress = ExerciseCoachingScript(
  exerciseName: 'Panca Piana',
  muscleGroups: 'petto, tricipiti e spalle anteriori',
  positionSetup:
      'Sdraiati sulla panca, piedi ben piantati a terra, schiena con leggero arco naturale',
  movementDescription:
      'Afferra il bilanciere poco più largo delle spalle. Scendi lentamente sfiorando il petto, poi spingi verso l\'alto',
  breathingCue: 'Inspira scendendo, espira spingendo',
  visualizationCue: 'Immagina di spingere il soffitto lontano da te',
  duringSetCues: [
    'Senti il petto',
    'Gomiti a 45 gradi',
    'Schiena stabile',
    'Spingi forte',
    'Respira',
    'Ottimo ritmo',
    'Controllo',
  ],
);

const _inclineBenchPress = ExerciseCoachingScript(
  exerciseName: 'Panca Inclinata',
  muscleGroups: 'petto alto e spalle anteriori',
  positionSetup:
      'Regola la panca a 30-45 gradi, schiena aderente, piedi a terra',
  movementDescription:
      'Scendi con i manubri verso le clavicole, poi spingi verso l\'alto convergendo',
  breathingCue: 'Inspira nella discesa, espira nella spinta',
  visualizationCue: 'Immagina di unire i gomiti in cima',
  duringSetCues: [
    'Senti la parte alta',
    'Petto aperto',
    'Spalle basse',
    'Spingi in alto',
    'Ottimo!',
  ],
);

const _cableCrossover = ExerciseCoachingScript(
  exerciseName: 'Croci ai Cavi',
  muscleGroups: 'petto interno',
  positionSetup:
      'Posizionati al centro dei cavi, un piede avanti per stabilità, leggera flessione dei gomiti',
  movementDescription:
      'Porta le mani davanti al corpo disegnando un arco, spremi il petto in fondo',
  breathingCue: 'Espira chiudendo, inspira aprendo',
  visualizationCue: 'Immagina di abbracciare un albero grande',
  duringSetCues: [
    'Spremi il petto',
    'Gomiti fissi',
    'Controlla il ritorno',
    'Senti la contrazione',
  ],
);

// =====================================
// BACK EXERCISES
// =====================================

const _latPulldown = ExerciseCoachingScript(
  exerciseName: 'Lat Machine',
  muscleGroups: 'dorsali e bicipiti',
  positionSetup: 'Siediti, blocca le cosce, presa larga poco più delle spalle',
  movementDescription:
      'Tira la barra verso il petto alto portando i gomiti verso il basso e indietro',
  breathingCue: 'Espira tirando, inspira rilasciando',
  visualizationCue: 'Immagina di mettere i gomiti nelle tasche posteriori',
  duringSetCues: [
    'Dorsali attivi',
    'Petto in fuori',
    'Tira coi gomiti',
    'Schiena dritta',
    'Spremi in basso',
  ],
);

const _seatedRow = ExerciseCoachingScript(
  exerciseName: 'Pulley Basso',
  muscleGroups: 'dorsali e romboidi',
  positionSetup:
      'Siediti, gambe leggermente flesse, schiena dritta, presa neutra',
  movementDescription:
      'Tira il cavo verso l\'ombelico spremendo le scapole insieme',
  breathingCue: 'Espira tirando, inspira tornando',
  visualizationCue: 'Immagina di schiacciare una noce tra le scapole',
  duringSetCues: [
    'Scapole insieme',
    'Schiena ferma',
    'Gomiti indietro',
    'Spremi i dorsali',
    'Ottimo!',
  ],
);

const _deadlift = ExerciseCoachingScript(
  exerciseName: 'Stacco da Terra',
  muscleGroups: 'schiena, glutei e gambe',
  positionSetup:
      'Piedi sotto il bilanciere, presa appena fuori dalle gambe, schiena neutra',
  movementDescription:
      'Spingi con le gambe mantenendo il bilanciere vicino al corpo, estendi le anche in cima',
  breathingCue: 'Grande inspiro prima di sollevare, espira in cima',
  visualizationCue: 'Immagina di spingere il pavimento con i piedi',
  duringSetCues: [
    'Schiena neutra',
    'Bilanciere vicino',
    'Spingi col pavimento',
    'Glutei in cima',
    'Core stretto',
    'Ottimo!',
  ],
);

// =====================================
// LEG EXERCISES
// =====================================

const _squat = ExerciseCoachingScript(
  exerciseName: 'Squat',
  muscleGroups: 'quadricipiti, glutei e core',
  positionSetup:
      'Piedi larghi quanto le spalle, punte leggermente verso l\'esterno, bilanciere sui trapezi',
  movementDescription:
      'Scendi come se ti sedessi, ginocchia in linea con le punte, poi risali spingendo sui talloni',
  breathingCue: 'Inspira profondo scendendo, espira risalendo',
  visualizationCue: 'Immagina di spingere il pavimento via da te',
  duringSetCues: [
    'Petto alto',
    'Ginocchia fuori',
    'Core contratto',
    'Spingi sui talloni',
    'Schiena dritta',
    'Forza!',
  ],
);

const _legPress = ExerciseCoachingScript(
  exerciseName: 'Leg Press',
  muscleGroups: 'quadricipiti e glutei',
  positionSetup:
      'Schiena aderente allo schienale, piedi a larghezza spalle sulla pedana',
  movementDescription:
      'Abbassa il peso flettendo le ginocchia, poi spingi senza bloccare le ginocchia in cima',
  breathingCue: 'Inspira scendendo, espira spingendo',
  visualizationCue: 'Immagina di spingere via la pedana',
  duringSetCues: [
    'Schiena aderente',
    'Ginocchia fuori',
    'Spingi coi talloni',
    'Non bloccare le gambe',
    'Forza!',
  ],
);

const _legExtension = ExerciseCoachingScript(
  exerciseName: 'Leg Extension',
  muscleGroups: 'quadricipiti',
  positionSetup:
      'Siediti, schiena aderente, caviglie sotto il rullo, impugnature ai lati',
  movementDescription:
      'Estendi le gambe lentamente fino a quasi bloccare, spremi in cima, poi scendi controllato',
  breathingCue: 'Espira estendendo, inspira scendendo',
  visualizationCue: 'Immagina di far contrarre forte i quadricipiti',
  duringSetCues: [
    'Spremi in cima',
    'Controllo lento',
    'Senti i quadricipiti',
    'Ottimo!',
  ],
);

const _legCurl = ExerciseCoachingScript(
  exerciseName: 'Leg Curl',
  muscleGroups: 'femorali',
  positionSetup:
      'Sdraiati a pancia in giù, caviglie sotto il rullo, impugnature davanti',
  movementDescription:
      'Fletti le gambe portando i talloni verso i glutei, poi scendi lento',
  breathingCue: 'Espira flettendo, inspira estendendo',
  visualizationCue: 'Immagina di toccare i glutei coi talloni',
  duringSetCues: [
    'Spremi i femorali',
    'Bacino fermo',
    'Controllo nella discesa',
    'Forza!',
  ],
);

const _calfRaise = ExerciseCoachingScript(
  exerciseName: 'Calf Raise',
  muscleGroups: 'polpacci',
  positionSetup:
      'Su un gradino o macchina, avampiedi sul bordo, talloni nel vuoto',
  movementDescription:
      'Solleva i talloni il più in alto possibile, poi scendi sotto il parallelo per stirare',
  breathingCue: 'Espira salendo, inspira scendendo',
  visualizationCue: 'Immagina di arrivare in punta di piedi',
  duringSetCues: [
    'Spremi in cima',
    'Stretch in basso',
    'Stira bene',
    'Polpacci attivi',
  ],
);

// =====================================
// SHOULDER EXERCISES
// =====================================

const _shoulderPress = ExerciseCoachingScript(
  exerciseName: 'Shoulder Press',
  muscleGroups: 'spalle e tricipiti',
  positionSetup:
      'Seduto o in piedi, manubri all\'altezza delle orecchie, gomiti a 90 gradi',
  movementDescription:
      'Spingi i manubri verso l\'alto fino a quasi toccarsi, poi scendi controllato',
  breathingCue: 'Espira spingendo, inspira scendendo',
  visualizationCue: 'Immagina di spingere il soffitto in alto',
  duringSetCues: [
    'Core stretto',
    'Gomiti in linea',
    'Spingi forte',
    'Spalle attive',
    'Ottimo!',
  ],
);

const _lateralRaise = ExerciseCoachingScript(
  exerciseName: 'Alzate Laterali',
  muscleGroups: 'deltoidi laterali',
  positionSetup:
      'In piedi, manubri ai lati, leggera flessione dei gomiti, busto leggermente inclinato',
  movementDescription:
      'Solleva i manubri ai lati fino all\'altezza delle spalle, poi scendi lento',
  breathingCue: 'Espira salendo, inspira scendendo',
  visualizationCue: 'Immagina di versare dell\'acqua da due bottiglie',
  duringSetCues: [
    'Gomiti alti',
    'Mignoli su',
    'Spalle giù',
    'Controllo',
    'Senti il bruciore',
  ],
);

const _rearDeltFly = ExerciseCoachingScript(
  exerciseName: 'Rear Delt Fly',
  muscleGroups: 'deltoidi posteriori',
  positionSetup:
      'Inclinato in avanti a 45 gradi, manubri sotto, braccia quasi distese',
  movementDescription:
      'Apri le braccia ai lati portando i gomiti verso l\'alto e indietro',
  breathingCue: 'Espira aprendo, inspira chiudendo',
  visualizationCue: 'Immagina di aprire le ali',
  duringSetCues: [
    'Spremi le scapole',
    'Gomiti alti',
    'Senti i deltoidi posteriori',
    'Ottimo!',
  ],
);

// =====================================
// ARM EXERCISES
// =====================================

const _bicepCurl = ExerciseCoachingScript(
  exerciseName: 'Curl Bicipiti',
  muscleGroups: 'bicipiti',
  positionSetup:
      'In piedi, manubri ai lati, palmi in avanti, gomiti vicini al corpo',
  movementDescription:
      'Fletti i gomiti portando i manubri alle spalle, spremi in cima, poi scendi lento',
  breathingCue: 'Espira salendo, inspira scendendo',
  visualizationCue:
      'Immagina di portare i manubri alle spalle senza muovere i gomiti',
  duringSetCues: [
    'Gomiti fermi',
    'Spremi in cima',
    'Bicipiti contratti',
    'Controllo!',
    'Senti il pump',
  ],
);

const _tricepPushdown = ExerciseCoachingScript(
  exerciseName: 'Pushdown Tricipiti',
  muscleGroups: 'tricipiti',
  positionSetup:
      'In piedi davanti al cavo alto, gomiti vicini al corpo, presa sulla corda o barra',
  movementDescription:
      'Estendi i gomiti spingendo verso il basso, spremi i tricipiti, poi torna lento',
  breathingCue: 'Espira spingendo, inspira risalendo',
  visualizationCue: 'Immagina di schiacciare qualcosa verso il pavimento',
  duringSetCues: [
    'Gomiti fermi',
    'Spremi in basso',
    'Tricipiti contratti',
    'Controllo!',
  ],
);

const _hammerCurl = ExerciseCoachingScript(
  exerciseName: 'Curl a Martello',
  muscleGroups: 'bicipiti e avambracci',
  positionSetup: 'In piedi, manubri ai lati con presa neutra (pollici in alto)',
  movementDescription:
      'Fletti i gomiti mantenendo la presa neutra, poi scendi controllato',
  breathingCue: 'Espira salendo, inspira scendendo',
  visualizationCue: 'Immagina di usare un martello',
  duringSetCues: [
    'Presa neutra',
    'Gomiti fermi',
    'Avambracci attivi',
    'Ottimo!',
  ],
);

// =====================================
// CORE EXERCISES
// =====================================

const _crunch = ExerciseCoachingScript(
  exerciseName: 'Crunch',
  muscleGroups: 'addominali',
  positionSetup:
      'Sdraiato, ginocchia piegate, piedi a terra, mani dietro la testa',
  movementDescription:
      'Solleva le spalle dal suolo contraendo gli addominali, poi scendi lento',
  breathingCue: 'Espira salendo, inspira scendendo',
  visualizationCue: 'Immagina di avvicinare il petto alle ginocchia',
  duringSetCues: [
    'Addome contratto',
    'Non tirare il collo',
    'Senti gli addominali',
    'Controlla!',
  ],
);

const _plank = ExerciseCoachingScript(
  exerciseName: 'Plank',
  muscleGroups: 'core completo',
  positionSetup:
      'Appoggiati su avambracci e punte dei piedi, corpo in linea retta',
  movementDescription:
      'Mantieni la posizione senza far cadere o alzare i fianchi',
  breathingCue: 'Respira regolarmente, non trattenere il fiato',
  visualizationCue: 'Immagina una linea retta dalle spalle ai talloni',
  duringSetCues: [
    'Core stretto',
    'Fianchi in linea',
    'Respira',
    'Resisti!',
    'Ottimo!',
  ],
);

const _russianTwist = ExerciseCoachingScript(
  exerciseName: 'Russian Twist',
  muscleGroups: 'obliqui',
  positionSetup:
      'Seduto, busto inclinato indietro, gambe sollevate, peso in mano',
  movementDescription:
      'Ruota il busto da un lato all\'altro toccando il pavimento con il peso',
  breathingCue: 'Espira ad ogni rotazione',
  visualizationCue: 'Immagina di toccare il pavimento ai tuoi lati',
  duringSetCues: ['Core stretto', 'Gambe ferme', 'Ruota dal busto', 'Ottimo!'],
);

// =====================================
// SCRIPT LOOKUP MAP
// =====================================

/// All predefined exercise scripts
const Map<String, ExerciseCoachingScript> exerciseScriptsDatabase = {
  // Chest
  'bench_press': _benchPress,
  'panca_piana': _benchPress,
  'incline_bench': _inclineBenchPress,
  'panca_inclinata': _inclineBenchPress,
  'cable_crossover': _cableCrossover,
  'croci_cavi': _cableCrossover,

  // Back
  'lat_pulldown': _latPulldown,
  'lat_machine': _latPulldown,
  'seated_row': _seatedRow,
  'pulley': _seatedRow,
  'deadlift': _deadlift,
  'stacco': _deadlift,

  // Legs
  'squat': _squat,
  'leg_press': _legPress,
  'leg_extension': _legExtension,
  'leg_curl': _legCurl,
  'calf_raise': _calfRaise,
  'polpacci': _calfRaise,

  // Shoulders
  'shoulder_press': _shoulderPress,
  'military_press': _shoulderPress,
  'lento_avanti': _shoulderPress,
  'lateral_raise': _lateralRaise,
  'alzate_laterali': _lateralRaise,
  'rear_delt': _rearDeltFly,

  // Arms
  'bicep_curl': _bicepCurl,
  'curl': _bicepCurl,
  'tricep_pushdown': _tricepPushdown,
  'pushdown': _tricepPushdown,
  'hammer_curl': _hammerCurl,

  // Core
  'crunch': _crunch,
  'plank': _plank,
  'russian_twist': _russianTwist,
};

/// Get script for exercise by name (fuzzy match)
ExerciseCoachingScript? getScriptForExercise(String exerciseName) {
  final nameLower = exerciseName
      .toLowerCase()
      .replaceAll('-', '_')
      .replaceAll(' ', '_');

  // First try exact match
  if (exerciseScriptsDatabase.containsKey(nameLower)) {
    return exerciseScriptsDatabase[nameLower];
  }

  // Fuzzy match by keywords
  for (final entry in exerciseScriptsDatabase.entries) {
    final keywords = entry.key.split('_');
    for (final keyword in keywords) {
      if (keyword.length > 3 && nameLower.contains(keyword)) {
        return entry.value;
      }
    }
  }

  // Specific keyword checks
  if (nameLower.contains('panca') ||
      nameLower.contains('bench') ||
      nameLower.contains('press')) {
    if (nameLower.contains('inclin')) return _inclineBenchPress;
    if (nameLower.contains('spall') || nameLower.contains('shoulder'))
      return _shoulderPress;
    return _benchPress;
  }
  if (nameLower.contains('squat') || nameLower.contains('accosciata'))
    return _squat;
  if (nameLower.contains('stacco') || nameLower.contains('deadlift'))
    return _deadlift;
  if (nameLower.contains('lat') && nameLower.contains('machine'))
    return _latPulldown;
  if (nameLower.contains('pulley') ||
      nameLower.contains('row') ||
      nameLower.contains('rematore'))
    return _seatedRow;
  if (nameLower.contains('curl') && nameLower.contains('martello'))
    return _hammerCurl;
  if (nameLower.contains('curl') || nameLower.contains('bicip'))
    return _bicepCurl;
  if (nameLower.contains('tricip') || nameLower.contains('pushdown'))
    return _tricepPushdown;
  if (nameLower.contains('alzate') || nameLower.contains('lateral'))
    return _lateralRaise;
  if (nameLower.contains('leg') && nameLower.contains('press'))
    return _legPress;
  if (nameLower.contains('leg') && nameLower.contains('ext'))
    return _legExtension;
  if (nameLower.contains('leg') && nameLower.contains('curl')) return _legCurl;
  if (nameLower.contains('polpacc') || nameLower.contains('calf'))
    return _calfRaise;
  if (nameLower.contains('crunch') || nameLower.contains('addomin'))
    return _crunch;
  if (nameLower.contains('plank')) return _plank;
  if (nameLower.contains('twist') || nameLower.contains('obliqu'))
    return _russianTwist;

  return null;
}

/// Create a generic fallback script for unknown exercises
ExerciseCoachingScript createGenericScript({
  required String exerciseName,
  required List<String> muscleGroups,
}) {
  return ExerciseCoachingScript(
    exerciseName: exerciseName,
    muscleGroups: muscleGroups.join(', '),
    positionSetup: 'Posizionati correttamente mantenendo una postura stabile',
    movementDescription:
        'Esegui il movimento in modo controllato, senza slanci',
    breathingCue: 'Espira nella fase di sforzo, inspira nel ritorno',
    visualizationCue: 'Concentrati sul muscolo che stai allenando',
    duringSetCues: [
      'Controllo',
      'Ottimo!',
      'Forza!',
      'Continua così',
      'Respira',
    ],
  );
}
