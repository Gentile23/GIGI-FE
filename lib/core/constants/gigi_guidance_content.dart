class GigiGuidanceContent {
  static String homeQuestionnaireIncomplete() {
    return '🚀 Completa il profilo per sbloccare la generazione della tua scheda.\n\nDa questa home poi potrai usare:\n• 🏋️ il workout del giorno\n• 📈 i progressi rapidi\n• 💡 gli insight salute\n• 🧭 le scorciatoie verso le sezioni principali';
  }

  static String homeAssessmentComplete() {
    return '✅ Hai completato il profilo.\n\nProssimo passo:\n• ⚙️ genera la scheda personalizzata\n\nDopo, da questa home controllerai:\n• 📋 stato del piano\n• ▶️ prossimi workout\n• ⚡ accessi rapidi alle aree più importanti dell’app';
  }

  static String homePlanProcessing() {
    return '🧠 Sto preparando la tua scheda.\n\nQuando sara pronta, qui vedrai:\n• 📋 il piano attivo\n• 🏃 il prossimo allenamento\n• 📈 i progressi\n• 💡 gli insight da consultare al volo';
  }

  static String homePlanReady() {
    return '🏠 Questa home e il tuo pannello operativo.\n\nUsala per:\n• 📋 controllare il piano attivo\n• ▶️ aprire il prossimo allenamento\n• 💡 entrare negli insight\n• 🧭 muoverti rapidamente tra le sezioni senza passare dai menu';
  }

  static String progressDashboard() {
    return '📈 Questa pagina riassume i tuoi progressi.\n\nQui puoi:\n• 👆 toccare i widget per entrare nel dettaglio\n• 📏 registrare nuove misure quando aggiorni il fisico\n• 🧍 usare la sagoma per capire quali aree stanno cambiando davvero';
  }

  static String bodyMeasurements() {
    return '📏 Inserisci le misure sempre con lo stesso metodo e confrontale nel tempo.\n\nQui i centimetri sono fondamentali per capire se:\n• 🔥 stai perdendo grasso\n• 💪 stai costruendo massa\n• ⚖️ il peso e fermo ma il corpo sta comunque cambiando';
  }

  static String nutritionDashboardNoDiet() {
    return '📄 Se hai una dieta del nutrizionista, questo e il punto di partenza corretto: importa il PDF e lo trasformo in una struttura digitale consultabile.\n\nDopo l import potrai:\n• 📅 aprire il piano giorno per giorno\n• 🍽️ rileggere i pasti senza tornare al PDF\n• 🛒 generare la lista della spesa\n• 🤖 usare gli strumenti AI della sezione per confronti e aggiustamenti pratici\n\nL obiettivo e mantenere la logica della dieta di partenza, ma renderla molto piu facile da usare ogni giorno.';
  }

  static String nutritionDashboardStrategy() {
    return '🍎 Questa e la centrale operativa della nutrizione.\n\nNella parte strategica puoi usare:\n• 🎯 il wizard obiettivi per farmi calcolare calorie e macro dai tuoi dati\n• ✍️ l impostazione manuale se hai gia target definiti\n\nSubito sotto trovi gli strumenti pratici:\n• ⚔️ Food Duel: confronta due alimenti e ti aiuta a capire quale sostituzione e piu adatta\n• 🧮 Calcolatore rapido: stima calorie e macro di un alimento o pasto prima di inserirlo\n• 👨‍🍳 Chef AI: genera idee e alternative quando non sai cosa mangiare\n\nNella parte giornaliera controlli:\n• 🔥 il ring calorie per vedere quanto ti manca all obiettivo\n• 🥩 i progressi macro per proteine, carboidrati e grassi\n• 🍽️ la lista dei pasti registrati oggi\n\nInfine:\n• ➕ il pulsante finale serve per aggiungere subito un nuovo pasto e aggiornare i totali della giornata';
  }

  static String nutritionGoalWizard() {
    return '🎯 Questo wizard costruisce una strategia nutrizionale completa, non solo un numero di calorie.\n\nNei vari step considero:\n• 📏 i tuoi dati fisici\n• 🚶 il livello di attivita\n• 🥅 l obiettivo che vuoi raggiungere\n\nAlla fine ottieni:\n• 🔥 calorie target\n• 🥩 proteine\n• 🍞 carboidrati\n• 🥑 grassi\n\nDa quel momento ogni pasto registrato viene confrontato con questi valori per dirti subito se sei in linea o fuori target.';
  }

  static String mealLogging({required bool calculatorMode}) {
    if (calculatorMode) {
      return '🧮 Usa questo calcolatore per una verifica veloce prima di decidere cosa mangiare o registrare.\n\nPuoi:\n• 🔢 stimare calorie e macro di un alimento\n• ⚖️ cambiare i grammi e vedere subito come cambia il totale\n• 📊 capire l impatto sui target della giornata\n\nE utile soprattutto per confrontare porzioni diverse o controllare un alimento prima di inserirlo nel diario.';
    }

    return '🍽️ Qui registri davvero i pasti della tua giornata.\n\nPuoi partire da:\n• 📷 una foto per avere una stima rapida\n• ✍️ un inserimento manuale per controllare o correggere i valori\n\nPrima di salvare controlla sempre:\n• 🕒 tipo di pasto\n• ⚖️ grammi\n• 🔥 calorie\n• 🥩🍞🥑 macro finali\n\nAppena confermi, questa schermata aggiorna i totali della dashboard nutrizione e ti fa capire subito se stai rispettando la strategia impostata.';
  }

  static String foodDuelIntro() {
    return '⚔️ Food Duel serve per fare sostituzioni intelligenti, non confronti generici.\n\nInserisci due alimenti e scegli la modalita:\n• 🔥 Per calorie: se vuoi capire quale porzione mantiene lo stesso impatto energetico\n• 🥩 Per proteine: se vuoi trovare un alternativa che conservi soprattutto l apporto proteico\n\nUsalo quando devi sostituire un cibo della dieta, scegliere tra due opzioni al supermercato o costruire un pasto restando coerente con il tuo obiettivo.';
  }

  static String foodDuelResult() {
    return '📋 Leggi questo risultato in due passaggi:\n• 1️⃣ guarda il riepilogo per capire se i due alimenti sono sostituibili nel contesto scelto\n• 2️⃣ controlla i valori per 100 g per vedere dove differiscono davvero tra proteine, carboidrati e grassi\n\nIl punteggio di compatibilita non dice solo quale alimento e migliore in assoluto: ti dice quanto la sostituzione resta fedele all obiettivo scelto per quel confronto.';
  }

  static String foodDuelInvalid() {
    return 'Non riesco a confrontare bene questi alimenti. Inserisci nomi più chiari o comuni: l’obiettivo qui è aiutarti a fare sostituzioni pratiche, non interpretare input ambigui.';
  }

  static String formAnalysisIntro() {
    return '🎥 Carica un video breve e indica bene l esercizio.\n\nIn questa sezione valuti:\n• ✅ la tecnica generale\n• ⚠️ gli errori ricorrenti\n• 🎯 le priorita di correzione\n\nUsala prima di aumentare carichi o volume.';
  }

  static String formAnalysisResultHigh() {
    return '✅ Tecnica solida.\n\nUsa questo risultato per:\n• confermare che l esecuzione e stabile\n• concentrarti sulle progressioni\n• rifinire i dettagli fini nei punti qui sotto se vuoi migliorare ancora';
  }

  static String formAnalysisResultMedium() {
    return '🛠️ La base e buona, ma ci sono margini chiari di miglioramento.\n\nQuesta schermata ti serve per:\n• correggere gli errori che limitano stabilita ed efficienza\n• lavorare sui punti segnalati uno per volta\n• registrare poi un nuovo video di confronto';
  }

  static String formAnalysisResultLow() {
    return '⚠️ Qui la priorita non e caricare di piu, ma correggere il pattern.\n\nFai cosi:\n• 1️⃣ segui i feedback in ordine\n• 2️⃣ riprova il movimento\n• 3️⃣ usa questa analisi come controllo tecnico prima del prossimo workout';
  }

  static String socialFeed() {
    return '🌍 Questo feed serve per vedere attivita, challenge e segnali social della community.\n\nUsalo per:\n• 👀 scoprire cosa fanno gli altri utenti\n• 🏆 partecipare alle sfide\n• 🔥 restare coinvolto nel percorso con continuita';
  }
}
