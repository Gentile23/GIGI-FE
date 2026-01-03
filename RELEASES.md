# Registro delle Release - GiGi App

Questo documento tiene traccia di tutte le release dell'applicazione GiGi, fornendo dettagli su nuove funzionalità, miglioramenti e correzioni di bug.

---

## [1.0.0+1] - 2024-12-30

### 🚀 Nuove Funzionalità
- **Personalizzazione Workout:**
  - Introdotta la possibilità di generare schede workout custom.
  - Aggiunta la funzionalità "Esercizi Simili" per variare l'allenamento.
  - Implementata l'alternativa corpo libero/macchinario per adattarsi all'attrezzatura disponibile.
- **Gigi Voice Coaching 2.0:**
  - Voce più naturale e lenta con pause strategiche.
  - Sistema di pre-caching audio per eliminare i tempi di attesa della generazione TTS.
  - Messaggi di benvenuto personalizzati con il nome dell'utente.
- **GDPR & Privacy:** Integrazione dei consensi obbligatori durante la registrazione (Privacy Policy, Termini di Servizio e Trattamento dati sanitari).
- **Visualizzazione Progressi:** Nuova dashboard per visualizzare i progressi per gruppo muscolare basati su carichi e ripetizioni.

### 🛠️ Miglioramenti & Fix
- **Google Sign-In (Web):** Corretto il bug di navigazione su Chrome dove l'utente rimaneva bloccato sulla schermata di login dopo l'autenticazione. Introdotta una logica di navigazione fallback robusta.
- **Ottimizzazione API:** Migliorata la gestione dei token e delle sessioni durante il social login.
- **Correzione Errori 404:** Risolto il problema del caricamento del piano corrente quando non ancora esistente, migliorando la user experience iniziale.

### 📋 Note per il Testing
- Verificare il flusso di login Google su diverse porte (5000/5001).
- Testare la generazione del piano in lingua inglese cambiando le impostazioni del profilo.

---

## 📝 Modello Release (Copia per la prossima release)

<!-- 
## [X.Y.Z+B] - AAAA-MM-GG

### 🚀 Nuove Funzionalità
- [Dettaglio feature 1]
- [Dettaglio feature 2]

### 🛠️ Miglioramenti & Fix
- [Dettaglio miglioramento/fix 1]
- [Dettaglio miglioramento/fix 2]

### 📋 Note per il Testing
- [Cosa testare specificamente]
-->
