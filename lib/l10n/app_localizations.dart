import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('fr'),
    Locale('it'),
    Locale('pt'),
  ];

  /// The application title
  ///
  /// In it, this message translates to:
  /// **'GIGI'**
  String get appTitle;

  /// Greeting shown on login screen
  ///
  /// In it, this message translates to:
  /// **'Bentornato!'**
  String get welcomeBack;

  /// Create account title
  ///
  /// In it, this message translates to:
  /// **'Crea Account'**
  String get createAccount;

  /// Subtitle on login screen
  ///
  /// In it, this message translates to:
  /// **'Accedi per continuare il tuo percorso fitness'**
  String get loginSubtitle;

  /// Subtitle on register screen
  ///
  /// In it, this message translates to:
  /// **'Inizia oggi il tuo percorso fitness'**
  String get registerSubtitle;

  /// No description provided for @fullName.
  ///
  /// In it, this message translates to:
  /// **'Nome Completo'**
  String get fullName;

  /// No description provided for @email.
  ///
  /// In it, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In it, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @enterYourName.
  ///
  /// In it, this message translates to:
  /// **'Inserisci il tuo nome'**
  String get enterYourName;

  /// No description provided for @enterYourEmail.
  ///
  /// In it, this message translates to:
  /// **'Inserisci la tua email'**
  String get enterYourEmail;

  /// No description provided for @enterValidEmail.
  ///
  /// In it, this message translates to:
  /// **'Inserisci un\'email valida'**
  String get enterValidEmail;

  /// No description provided for @enterPassword.
  ///
  /// In it, this message translates to:
  /// **'Inserisci la password'**
  String get enterPassword;

  /// No description provided for @passwordTooShort.
  ///
  /// In it, this message translates to:
  /// **'La password deve essere di almeno 6 caratteri'**
  String get passwordTooShort;

  /// No description provided for @login.
  ///
  /// In it, this message translates to:
  /// **'Accedi'**
  String get login;

  /// No description provided for @register.
  ///
  /// In it, this message translates to:
  /// **'Registrati'**
  String get register;

  /// No description provided for @or.
  ///
  /// In it, this message translates to:
  /// **'oppure'**
  String get or;

  /// No description provided for @continueWithGoogle.
  ///
  /// In it, this message translates to:
  /// **'Continua con Google'**
  String get continueWithGoogle;

  /// No description provided for @noAccount.
  ///
  /// In it, this message translates to:
  /// **'Non hai un account?'**
  String get noAccount;

  /// No description provided for @haveAccount.
  ///
  /// In it, this message translates to:
  /// **'Hai già un account?'**
  String get haveAccount;

  /// No description provided for @consentsRequired.
  ///
  /// In it, this message translates to:
  /// **'Consensi richiesti'**
  String get consentsRequired;

  /// No description provided for @acceptPrivacyPolicy.
  ///
  /// In it, this message translates to:
  /// **'Ho letto e accetto la'**
  String get acceptPrivacyPolicy;

  /// No description provided for @privacyPolicy.
  ///
  /// In it, this message translates to:
  /// **'Informativa sulla Privacy'**
  String get privacyPolicy;

  /// No description provided for @acceptTerms.
  ///
  /// In it, this message translates to:
  /// **'Accetto i'**
  String get acceptTerms;

  /// No description provided for @termsOfService.
  ///
  /// In it, this message translates to:
  /// **'Termini di Servizio'**
  String get termsOfService;

  /// No description provided for @acceptHealthData.
  ///
  /// In it, this message translates to:
  /// **'Acconsento al trattamento dei miei'**
  String get acceptHealthData;

  /// No description provided for @healthDataLink.
  ///
  /// In it, this message translates to:
  /// **'dati sanitari'**
  String get healthDataLink;

  /// No description provided for @healthDataDescription.
  ///
  /// In it, this message translates to:
  /// **'(peso, altezza, infortuni) per personalizzare i piani di allenamento'**
  String get healthDataDescription;

  /// No description provided for @acceptAllConsents.
  ///
  /// In it, this message translates to:
  /// **'Accetta tutti i consensi per procedere'**
  String get acceptAllConsents;

  /// No description provided for @home.
  ///
  /// In it, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @workout.
  ///
  /// In it, this message translates to:
  /// **'Workout'**
  String get workout;

  /// No description provided for @nutrition.
  ///
  /// In it, this message translates to:
  /// **'Nutrizione'**
  String get nutrition;

  /// No description provided for @social.
  ///
  /// In it, this message translates to:
  /// **'Social'**
  String get social;

  /// No description provided for @progress.
  ///
  /// In it, this message translates to:
  /// **'Progressi'**
  String get progress;

  /// No description provided for @profile.
  ///
  /// In it, this message translates to:
  /// **'Profilo'**
  String get profile;

  /// No description provided for @startNow.
  ///
  /// In it, this message translates to:
  /// **'Inizia Ora'**
  String get startNow;

  /// No description provided for @slogan.
  ///
  /// In it, this message translates to:
  /// **'La tua evoluzione fitness,\nguidata dall\'intelligenza.'**
  String get slogan;

  /// No description provided for @sloganSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Allenati con intelligenza. Ottieni risultati.'**
  String get sloganSubtitle;

  /// No description provided for @invalidCredentials.
  ///
  /// In it, this message translates to:
  /// **'Credenziali non valide. Controlla email e password.'**
  String get invalidCredentials;

  /// No description provided for @registrationFailed.
  ///
  /// In it, this message translates to:
  /// **'Registrazione fallita. Riprova più tardi.'**
  String get registrationFailed;

  /// No description provided for @emailAlreadyExists.
  ///
  /// In it, this message translates to:
  /// **'Questa email è già registrata. Prova ad accedere.'**
  String get emailAlreadyExists;

  /// No description provided for @connectionError.
  ///
  /// In it, this message translates to:
  /// **'Impossibile connettersi al server. Controlla la connessione internet.'**
  String get connectionError;

  /// No description provided for @unexpectedError.
  ///
  /// In it, this message translates to:
  /// **'Si è verificato un errore inatteso'**
  String get unexpectedError;

  /// No description provided for @googleSignInError.
  ///
  /// In it, this message translates to:
  /// **'Errore durante l\'accesso con Google'**
  String get googleSignInError;

  /// No description provided for @appleSignInError.
  ///
  /// In it, this message translates to:
  /// **'Errore durante l\'accesso con Apple'**
  String get appleSignInError;

  /// No description provided for @mustAcceptConsents.
  ///
  /// In it, this message translates to:
  /// **'Devi accettare tutti i consensi per registrarti.'**
  String get mustAcceptConsents;

  /// No description provided for @logout.
  ///
  /// In it, this message translates to:
  /// **'Esci'**
  String get logout;

  /// No description provided for @settings.
  ///
  /// In it, this message translates to:
  /// **'Impostazioni'**
  String get settings;

  /// No description provided for @editProfile.
  ///
  /// In it, this message translates to:
  /// **'Modifica Profilo'**
  String get editProfile;

  /// No description provided for @notifications.
  ///
  /// In it, this message translates to:
  /// **'Notifiche'**
  String get notifications;

  /// No description provided for @language.
  ///
  /// In it, this message translates to:
  /// **'Lingua'**
  String get language;

  /// No description provided for @darkMode.
  ///
  /// In it, this message translates to:
  /// **'Modalità Scura'**
  String get darkMode;

  /// No description provided for @about.
  ///
  /// In it, this message translates to:
  /// **'Info'**
  String get about;

  /// No description provided for @help.
  ///
  /// In it, this message translates to:
  /// **'Aiuto'**
  String get help;

  /// No description provided for @feedback.
  ///
  /// In it, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @rateApp.
  ///
  /// In it, this message translates to:
  /// **'Valuta l\'App'**
  String get rateApp;

  /// No description provided for @share.
  ///
  /// In it, this message translates to:
  /// **'Condividi'**
  String get share;

  /// No description provided for @version.
  ///
  /// In it, this message translates to:
  /// **'Versione'**
  String get version;

  /// No description provided for @cancel.
  ///
  /// In it, this message translates to:
  /// **'Annulla'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In it, this message translates to:
  /// **'Salva'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In it, this message translates to:
  /// **'Elimina'**
  String get delete;

  /// No description provided for @confirm.
  ///
  /// In it, this message translates to:
  /// **'Conferma'**
  String get confirm;

  /// No description provided for @yes.
  ///
  /// In it, this message translates to:
  /// **'Sì'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In it, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @ok.
  ///
  /// In it, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @error.
  ///
  /// In it, this message translates to:
  /// **'Errore'**
  String get error;

  /// No description provided for @success.
  ///
  /// In it, this message translates to:
  /// **'Successo'**
  String get success;

  /// No description provided for @loading.
  ///
  /// In it, this message translates to:
  /// **'Caricamento...'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In it, this message translates to:
  /// **'Riprova'**
  String get retry;

  /// No description provided for @next.
  ///
  /// In it, this message translates to:
  /// **'Prossimo'**
  String get next;

  /// No description provided for @back.
  ///
  /// In it, this message translates to:
  /// **'Indietro'**
  String get back;

  /// No description provided for @done.
  ///
  /// In it, this message translates to:
  /// **'Fatto'**
  String get done;

  /// No description provided for @skip.
  ///
  /// In it, this message translates to:
  /// **'Salta'**
  String get skip;

  /// No description provided for @search.
  ///
  /// In it, this message translates to:
  /// **'Cerca'**
  String get search;

  /// No description provided for @noResults.
  ///
  /// In it, this message translates to:
  /// **'Nessun risultato'**
  String get noResults;

  /// No description provided for @seeAll.
  ///
  /// In it, this message translates to:
  /// **'Vedi Tutto'**
  String get seeAll;

  /// No description provided for @today.
  ///
  /// In it, this message translates to:
  /// **'Oggi'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In it, this message translates to:
  /// **'Ieri'**
  String get yesterday;

  /// No description provided for @thisWeek.
  ///
  /// In it, this message translates to:
  /// **'Questa Settimana'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In it, this message translates to:
  /// **'Questo Mese'**
  String get thisMonth;

  /// No description provided for @noWorkoutPlan.
  ///
  /// In it, this message translates to:
  /// **'Nessun piano di allenamento trovato'**
  String get noWorkoutPlan;

  /// No description provided for @generatePlan.
  ///
  /// In it, this message translates to:
  /// **'Genera Piano'**
  String get generatePlan;

  /// No description provided for @startWorkout.
  ///
  /// In it, this message translates to:
  /// **'Inizia Workout'**
  String get startWorkout;

  /// No description provided for @completeWorkout.
  ///
  /// In it, this message translates to:
  /// **'COMPLETA ALLENAMENTO'**
  String get completeWorkout;

  /// No description provided for @restDay.
  ///
  /// In it, this message translates to:
  /// **'Giorno di Riposo'**
  String get restDay;

  /// No description provided for @exercises.
  ///
  /// In it, this message translates to:
  /// **'Esercizi'**
  String get exercises;

  /// No description provided for @sets.
  ///
  /// In it, this message translates to:
  /// **'Sets'**
  String get sets;

  /// No description provided for @reps.
  ///
  /// In it, this message translates to:
  /// **'Reps'**
  String get reps;

  /// No description provided for @weight.
  ///
  /// In it, this message translates to:
  /// **'Peso'**
  String get weight;

  /// No description provided for @duration.
  ///
  /// In it, this message translates to:
  /// **'Durata'**
  String get duration;

  /// No description provided for @rest.
  ///
  /// In it, this message translates to:
  /// **'Rest'**
  String get rest;

  /// No description provided for @calories.
  ///
  /// In it, this message translates to:
  /// **'Calorie'**
  String get calories;

  /// No description provided for @minutes.
  ///
  /// In it, this message translates to:
  /// **'minuti'**
  String get minutes;

  /// No description provided for @seconds.
  ///
  /// In it, this message translates to:
  /// **'secondi'**
  String get seconds;

  /// No description provided for @kg.
  ///
  /// In it, this message translates to:
  /// **'kg'**
  String get kg;

  /// No description provided for @lbs.
  ///
  /// In it, this message translates to:
  /// **'lbs'**
  String get lbs;

  /// No description provided for @userDefaultName.
  ///
  /// In it, this message translates to:
  /// **'Utente'**
  String get userDefaultName;

  /// No description provided for @heightLabel.
  ///
  /// In it, this message translates to:
  /// **'Altezza (cm)'**
  String get heightLabel;

  /// No description provided for @weightLabel.
  ///
  /// In it, this message translates to:
  /// **'Peso'**
  String get weightLabel;

  /// No description provided for @ageLabel.
  ///
  /// In it, this message translates to:
  /// **'Età'**
  String get ageLabel;

  /// No description provided for @currentPlan.
  ///
  /// In it, this message translates to:
  /// **'Piano Attuale'**
  String get currentPlan;

  /// No description provided for @premium.
  ///
  /// In it, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @freeTier.
  ///
  /// In it, this message translates to:
  /// **'Free Tier'**
  String get freeTier;

  /// No description provided for @premiumAccessText.
  ///
  /// In it, this message translates to:
  /// **'Hai accesso a tutte le funzionalità Premium.'**
  String get premiumAccessText;

  /// No description provided for @upgradeToPremiumText.
  ///
  /// In it, this message translates to:
  /// **'Passa a Premium per sbloccare il coaching AI, l\'analisi della forma e altro ancora.'**
  String get upgradeToPremiumText;

  /// No description provided for @upgradeToPremiumButton.
  ///
  /// In it, this message translates to:
  /// **'Passa a Premium'**
  String get upgradeToPremiumButton;

  /// No description provided for @levelAndRewards.
  ///
  /// In it, this message translates to:
  /// **'Livello & Premi'**
  String get levelAndRewards;

  /// No description provided for @xpForNextLevel.
  ///
  /// In it, this message translates to:
  /// **'XP per il prossimo livello'**
  String get xpForNextLevel;

  /// No description provided for @features.
  ///
  /// In it, this message translates to:
  /// **'Funzionalità'**
  String get features;

  /// No description provided for @challenges.
  ///
  /// In it, this message translates to:
  /// **'Sfide'**
  String get challenges;

  /// No description provided for @challengesSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Daily, Weekly, Community'**
  String get challengesSubtitle;

  /// No description provided for @leaderboard.
  ///
  /// In it, this message translates to:
  /// **'Classifica'**
  String get leaderboard;

  /// No description provided for @leaderboardSubtitle.
  ///
  /// In it, this message translates to:
  /// **'XP, Workout, Streak'**
  String get leaderboardSubtitle;

  /// No description provided for @inviteFriends.
  ///
  /// In it, this message translates to:
  /// **'Invita Amici'**
  String get inviteFriends;

  /// No description provided for @inviteFriendsSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Guadagna Premium gratis'**
  String get inviteFriendsSubtitle;

  /// No description provided for @transformation.
  ///
  /// In it, this message translates to:
  /// **'Trasformazione'**
  String get transformation;

  /// No description provided for @transformationSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Before/After tracking'**
  String get transformationSubtitle;

  /// No description provided for @personalInfo.
  ///
  /// In it, this message translates to:
  /// **'Informazioni Personali'**
  String get personalInfo;

  /// No description provided for @fitnessGoals.
  ///
  /// In it, this message translates to:
  /// **'Obiettivi Fitness'**
  String get fitnessGoals;

  /// No description provided for @privacySecurity.
  ///
  /// In it, this message translates to:
  /// **'Privacy & Sicurezza'**
  String get privacySecurity;

  /// No description provided for @healthFitness.
  ///
  /// In it, this message translates to:
  /// **'Salute & Fitness'**
  String get healthFitness;

  /// No description provided for @healthFitnessSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Apple Health / Health Connect'**
  String get healthFitnessSubtitle;

  /// No description provided for @helpSupport.
  ///
  /// In it, this message translates to:
  /// **'Aiuto & Supporto'**
  String get helpSupport;

  /// No description provided for @logoutConfirmationTitle.
  ///
  /// In it, this message translates to:
  /// **'Logout'**
  String get logoutConfirmationTitle;

  /// No description provided for @logoutConfirmationMessage.
  ///
  /// In it, this message translates to:
  /// **'Sei sicuro di voler uscire?'**
  String get logoutConfirmationMessage;

  /// No description provided for @communitySubtitle.
  ///
  /// In it, this message translates to:
  /// **'Obiettivi collettivi'**
  String get communitySubtitle;

  /// No description provided for @community.
  ///
  /// In it, this message translates to:
  /// **'Community'**
  String get community;

  /// No description provided for @info.
  ///
  /// In it, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @goalMuscleGainLabel.
  ///
  /// In it, this message translates to:
  /// **'Aumento Muscolare'**
  String get goalMuscleGainLabel;

  /// No description provided for @goalWeightLossLabel.
  ///
  /// In it, this message translates to:
  /// **'Perdita di Peso'**
  String get goalWeightLossLabel;

  /// No description provided for @goalToningLabel.
  ///
  /// In it, this message translates to:
  /// **'Definizione'**
  String get goalToningLabel;

  /// No description provided for @goalStrengthLabel.
  ///
  /// In it, this message translates to:
  /// **'Forza e Potenza'**
  String get goalStrengthLabel;

  /// No description provided for @goalWellnessLabel.
  ///
  /// In it, this message translates to:
  /// **'Salute e Benessere'**
  String get goalWellnessLabel;

  /// No description provided for @levelBeginnerLabel.
  ///
  /// In it, this message translates to:
  /// **'Principiante'**
  String get levelBeginnerLabel;

  /// No description provided for @levelIntermediateLabel.
  ///
  /// In it, this message translates to:
  /// **'Intermedio'**
  String get levelIntermediateLabel;

  /// No description provided for @levelAdvancedLabel.
  ///
  /// In it, this message translates to:
  /// **'Avanzato'**
  String get levelAdvancedLabel;

  /// No description provided for @locationGymLabel.
  ///
  /// In it, this message translates to:
  /// **'Palestra'**
  String get locationGymLabel;

  /// No description provided for @locationHomeLabel.
  ///
  /// In it, this message translates to:
  /// **'Casa'**
  String get locationHomeLabel;

  /// No description provided for @locationOutdoorLabel.
  ///
  /// In it, this message translates to:
  /// **'Outdoor'**
  String get locationOutdoorLabel;

  /// No description provided for @injuryMuscular.
  ///
  /// In it, this message translates to:
  /// **'Strappi, contratture'**
  String get injuryMuscular;

  /// No description provided for @injuryArticular.
  ///
  /// In it, this message translates to:
  /// **'Distorsioni, infiammazioni'**
  String get injuryArticular;

  /// No description provided for @injuryBone.
  ///
  /// In it, this message translates to:
  /// **'Osseo'**
  String get injuryBone;

  /// No description provided for @myWorkoutsTitle.
  ///
  /// In it, this message translates to:
  /// **'I Miei Workout'**
  String get myWorkoutsTitle;

  /// No description provided for @aiAnalyzingProfile.
  ///
  /// In it, this message translates to:
  /// **'🧠 Gigi sta analizzando il tuo profilo'**
  String get aiAnalyzingProfile;

  /// No description provided for @aiGeneratingPlanDescription.
  ///
  /// In it, this message translates to:
  /// **'Generazione piano in corso...\nAttendi mentre Gigi crea il tuo allenamento personalizzato.'**
  String get aiGeneratingPlanDescription;

  /// No description provided for @noWorkoutsTitle.
  ///
  /// In it, this message translates to:
  /// **'Nessun Workout'**
  String get noWorkoutsTitle;

  /// No description provided for @generateFirstPlanSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Genera il tuo primo piano di allenamento dalla Home'**
  String get generateFirstPlanSubtitle;

  /// No description provided for @minutesShort.
  ///
  /// In it, this message translates to:
  /// **'min'**
  String get minutesShort;

  /// No description provided for @durationMinutes.
  ///
  /// In it, this message translates to:
  /// **'{minutes} min'**
  String durationMinutes(int minutes);

  /// No description provided for @secondsShort.
  ///
  /// In it, this message translates to:
  /// **'{seconds}s'**
  String secondsShort(int seconds);

  /// No description provided for @exercisesCount.
  ///
  /// In it, this message translates to:
  /// **'{count} esercizi'**
  String exercisesCount(int count);

  /// No description provided for @difficultyBeginner.
  ///
  /// In it, this message translates to:
  /// **'Principiante'**
  String get difficultyBeginner;

  /// No description provided for @difficultyIntermediate.
  ///
  /// In it, this message translates to:
  /// **'Intermedio'**
  String get difficultyIntermediate;

  /// No description provided for @difficultyAdvanced.
  ///
  /// In it, this message translates to:
  /// **'Avanzato'**
  String get difficultyAdvanced;

  /// No description provided for @voiceCoachingEnable.
  ///
  /// In it, this message translates to:
  /// **'Attiva Voice Coaching'**
  String get voiceCoachingEnable;

  /// No description provided for @voiceCoachingDisable.
  ///
  /// In it, this message translates to:
  /// **'Disattiva Voice Coaching'**
  String get voiceCoachingDisable;

  /// No description provided for @exerciseProgress.
  ///
  /// In it, this message translates to:
  /// **'Esercizio {current}/{total}'**
  String exerciseProgress(int current, int total);

  /// No description provided for @aiWorkoutsSectionTitle.
  ///
  /// In it, this message translates to:
  /// **'🤖 Schede AI'**
  String get aiWorkoutsSectionTitle;

  /// No description provided for @aiWorkoutsSectionSubtitle.
  ///
  /// In it, this message translates to:
  /// **'I tuoi allenamenti generati'**
  String get aiWorkoutsSectionSubtitle;

  /// No description provided for @customWorkoutsSectionTitle.
  ///
  /// In it, this message translates to:
  /// **'✏️ Schede Personalizzate'**
  String get customWorkoutsSectionTitle;

  /// No description provided for @customWorkoutsSectionSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Create da te'**
  String get customWorkoutsSectionSubtitle;

  /// No description provided for @nextWorkoutTitle.
  ///
  /// In it, this message translates to:
  /// **'🔥 Prossimo Workout'**
  String get nextWorkoutTitle;

  /// No description provided for @noAiWorkoutsTitle.
  ///
  /// In it, this message translates to:
  /// **'Nessun workout AI'**
  String get noAiWorkoutsTitle;

  /// No description provided for @generateAiPlanSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Genera una scheda dalla Home'**
  String get generateAiPlanSubtitle;

  /// No description provided for @generatingInProgress.
  ///
  /// In it, this message translates to:
  /// **'🤖 Generazione in corso...'**
  String get generatingInProgress;

  /// No description provided for @completingCardioMobility.
  ///
  /// In it, this message translates to:
  /// **'Completando cardio e mobilità'**
  String get completingCardioMobility;

  /// No description provided for @aiCompletingPlan.
  ///
  /// In it, this message translates to:
  /// **'AI sta completando la scheda...'**
  String get aiCompletingPlan;

  /// No description provided for @noAiGeneratedPlan.
  ///
  /// In it, this message translates to:
  /// **'Nessuna scheda AI generata'**
  String get noAiGeneratedPlan;

  /// No description provided for @noCustomWorkouts.
  ///
  /// In it, this message translates to:
  /// **'Nessuna scheda personalizzata'**
  String get noCustomWorkouts;

  /// No description provided for @noCustomWorkoutsTitle.
  ///
  /// In it, this message translates to:
  /// **'Nessuna Scheda Custom'**
  String get noCustomWorkoutsTitle;

  /// No description provided for @createCustomWorkoutSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Crea la tua scheda personalizzata\nselezionando gli esercizi che preferisci'**
  String get createCustomWorkoutSubtitle;

  /// No description provided for @start.
  ///
  /// In it, this message translates to:
  /// **'Inizia'**
  String get start;

  /// No description provided for @noAiPlanGenerated.
  ///
  /// In it, this message translates to:
  /// **'Nessun Piano AI Generato'**
  String get noAiPlanGenerated;

  /// No description provided for @aiCreatingPlan.
  ///
  /// In it, this message translates to:
  /// **'🤖 AI sta creando il tuo piano'**
  String get aiCreatingPlan;

  /// No description provided for @waitFewMinutes.
  ///
  /// In it, this message translates to:
  /// **'Ci vorranno pochi minuti...'**
  String get waitFewMinutes;

  /// No description provided for @champion.
  ///
  /// In it, this message translates to:
  /// **'Campione'**
  String get champion;

  /// No description provided for @previous.
  ///
  /// In it, this message translates to:
  /// **'Precedente'**
  String get previous;

  /// No description provided for @finish.
  ///
  /// In it, this message translates to:
  /// **'Termina'**
  String get finish;

  /// No description provided for @sessionNotRecorded.
  ///
  /// In it, this message translates to:
  /// **'⚠️ Sessione non registrata - i progressi potrebbero non essere salvati'**
  String get sessionNotRecorded;

  /// No description provided for @sessionStartError.
  ///
  /// In it, this message translates to:
  /// **'Errore avvio sessione: {error}'**
  String sessionStartError(String error);

  /// No description provided for @noExercisesTitle.
  ///
  /// In it, this message translates to:
  /// **'Nessun Esercizio'**
  String get noExercisesTitle;

  /// No description provided for @noExercisesSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Questo allenamento non ha ancora esercizi.'**
  String get noExercisesSubtitle;

  /// No description provided for @goBack.
  ///
  /// In it, this message translates to:
  /// **'Torna Indietro'**
  String get goBack;

  /// No description provided for @mainWorkoutSection.
  ///
  /// In it, this message translates to:
  /// **'Allenamento Principale'**
  String get mainWorkoutSection;

  /// No description provided for @exercisesStats.
  ///
  /// In it, this message translates to:
  /// **'Esercizi'**
  String get exercisesStats;

  /// No description provided for @kcalStats.
  ///
  /// In it, this message translates to:
  /// **'Kcal'**
  String get kcalStats;

  /// No description provided for @preWorkoutSection.
  ///
  /// In it, this message translates to:
  /// **'Prima dell\'allenamento'**
  String get preWorkoutSection;

  /// No description provided for @startSession.
  ///
  /// In it, this message translates to:
  /// **'INIZIA SESSIONE'**
  String get startSession;

  /// No description provided for @finishSession.
  ///
  /// In it, this message translates to:
  /// **'TERMINA SESSIONE'**
  String get finishSession;

  /// No description provided for @statsCalories.
  ///
  /// In it, this message translates to:
  /// **'kcal'**
  String get statsCalories;

  /// No description provided for @statsSeries.
  ///
  /// In it, this message translates to:
  /// **'serie'**
  String get statsSeries;

  /// No description provided for @statsMinPerEx.
  ///
  /// In it, this message translates to:
  /// **'min/ex'**
  String get statsMinPerEx;

  /// No description provided for @exerciseDetailsTitle.
  ///
  /// In it, this message translates to:
  /// **'Dettagli Esercizio'**
  String get exerciseDetailsTitle;

  /// No description provided for @similarExercises.
  ///
  /// In it, this message translates to:
  /// **'Esercizi Simili'**
  String get similarExercises;

  /// No description provided for @withEquipment.
  ///
  /// In it, this message translates to:
  /// **'Con Attrezzatura'**
  String get withEquipment;

  /// No description provided for @bodyweight.
  ///
  /// In it, this message translates to:
  /// **'Corpo Libero'**
  String get bodyweight;

  /// No description provided for @musclesInvolved.
  ///
  /// In it, this message translates to:
  /// **'Muscoli Coinvolti'**
  String get musclesInvolved;

  /// No description provided for @equipmentRequired.
  ///
  /// In it, this message translates to:
  /// **'Attrezzatura Richiesta'**
  String get equipmentRequired;

  /// No description provided for @howToPerform.
  ///
  /// In it, this message translates to:
  /// **'Come Eseguire'**
  String get howToPerform;

  /// No description provided for @videoTutorial.
  ///
  /// In it, this message translates to:
  /// **'Video Tutorial'**
  String get videoTutorial;

  /// No description provided for @videoUrlInvalid.
  ///
  /// In it, this message translates to:
  /// **'URL video non valido'**
  String get videoUrlInvalid;

  /// No description provided for @postWorkoutSection.
  ///
  /// In it, this message translates to:
  /// **'Dopo l\'allenamento'**
  String get postWorkoutSection;

  /// No description provided for @sectionCompleted.
  ///
  /// In it, this message translates to:
  /// **'{title} completata!'**
  String sectionCompleted(String title);

  /// No description provided for @gigiGuidingYou.
  ///
  /// In it, this message translates to:
  /// **'🎤 Gigi ti guida per {exercise}...'**
  String gigiGuidingYou(String exercise);

  /// No description provided for @yourTurn.
  ///
  /// In it, this message translates to:
  /// **'✅ Ora tocca a te! Inizia le tue serie.'**
  String get yourTurn;

  /// No description provided for @aiCheck.
  ///
  /// In it, this message translates to:
  /// **'AI Check'**
  String get aiCheck;

  /// No description provided for @executeWithGigi.
  ///
  /// In it, this message translates to:
  /// **'Esegui con Gigi'**
  String get executeWithGigi;

  /// No description provided for @exitWorkoutTitle.
  ///
  /// In it, this message translates to:
  /// **'Uscire dall\'allenamento?'**
  String get exitWorkoutTitle;

  /// No description provided for @exitWorkoutMessage.
  ///
  /// In it, this message translates to:
  /// **'Il tuo progresso andrà perso. Sei sicuro di voler uscire?'**
  String get exitWorkoutMessage;

  /// No description provided for @confirmExit.
  ///
  /// In it, this message translates to:
  /// **'Esci'**
  String get confirmExit;

  /// No description provided for @finishWorkoutTitle.
  ///
  /// In it, this message translates to:
  /// **'Completa Allenamento'**
  String get finishWorkoutTitle;

  /// No description provided for @finishWorkoutMessage.
  ///
  /// In it, this message translates to:
  /// **'Sei sicuro di voler terminare l\'allenamento? Tutti i progressi verranno salvati.'**
  String get finishWorkoutMessage;

  /// No description provided for @nextBadge.
  ///
  /// In it, this message translates to:
  /// **'PROSSIMO'**
  String get nextBadge;

  /// No description provided for @workoutCompletedTitle.
  ///
  /// In it, this message translates to:
  /// **'Allenamento Completato!'**
  String get workoutCompletedTitle;

  /// No description provided for @workoutCompletedMessage.
  ///
  /// In it, this message translates to:
  /// **'Ottimo lavoro! Il tuo allenamento è stato registrato con successo.'**
  String get workoutCompletedMessage;

  /// No description provided for @awesome.
  ///
  /// In it, this message translates to:
  /// **'Fantastico!'**
  String get awesome;

  /// No description provided for @saveError.
  ///
  /// In it, this message translates to:
  /// **'Errore durante il salvataggio: {error}'**
  String saveError(Object error);

  /// No description provided for @workoutStrength.
  ///
  /// In it, this message translates to:
  /// **'Forza'**
  String get workoutStrength;

  /// No description provided for @workoutHypertrophy.
  ///
  /// In it, this message translates to:
  /// **'Ipertrofia'**
  String get workoutHypertrophy;

  /// No description provided for @workoutEndurance.
  ///
  /// In it, this message translates to:
  /// **'Resistenza'**
  String get workoutEndurance;

  /// No description provided for @workoutFunctional.
  ///
  /// In it, this message translates to:
  /// **'Funzionale'**
  String get workoutFunctional;

  /// No description provided for @workoutCalisthenics.
  ///
  /// In it, this message translates to:
  /// **'Calisthenics'**
  String get workoutCalisthenics;

  /// No description provided for @workoutStrengthDesc.
  ///
  /// In it, this message translates to:
  /// **'Massimizza la forza con carichi pesanti e basse ripetizioni.'**
  String get workoutStrengthDesc;

  /// No description provided for @workoutHypertrophyDesc.
  ///
  /// In it, this message translates to:
  /// **'Focus sulla crescita muscolare e volume.'**
  String get workoutHypertrophyDesc;

  /// No description provided for @workoutEnduranceDesc.
  ///
  /// In it, this message translates to:
  /// **'Migliora la resistenza muscolare e cardiovascolare.'**
  String get workoutEnduranceDesc;

  /// No description provided for @workoutFunctionalDesc.
  ///
  /// In it, this message translates to:
  /// **'Movimenti multi-articolari per la vita quotidiana.'**
  String get workoutFunctionalDesc;

  /// No description provided for @workoutCalisthenicsDesc.
  ///
  /// In it, this message translates to:
  /// **'Allenamento a corpo libero per forza e controllo.'**
  String get workoutCalisthenicsDesc;

  /// No description provided for @bodyFatVeryHigh.
  ///
  /// In it, this message translates to:
  /// **'Sovrappeso evidente'**
  String get bodyFatVeryHigh;

  /// No description provided for @bodyFatHigh.
  ///
  /// In it, this message translates to:
  /// **'Sovrappeso leggero'**
  String get bodyFatHigh;

  /// No description provided for @bodyFatAverage.
  ///
  /// In it, this message translates to:
  /// **'Normopeso'**
  String get bodyFatAverage;

  /// No description provided for @bodyFatAthletic.
  ///
  /// In it, this message translates to:
  /// **'Atletico'**
  String get bodyFatAthletic;

  /// No description provided for @bodyFatVeryLean.
  ///
  /// In it, this message translates to:
  /// **'Molto Definito'**
  String get bodyFatVeryLean;

  /// No description provided for @bodyFatVeryHighSub.
  ///
  /// In it, this message translates to:
  /// **'Addome predominante'**
  String get bodyFatVeryHighSub;

  /// No description provided for @bodyFatHighSub.
  ///
  /// In it, this message translates to:
  /// **'Poca definizione'**
  String get bodyFatHighSub;

  /// No description provided for @bodyFatAverageSub.
  ///
  /// In it, this message translates to:
  /// **'Addome piatto'**
  String get bodyFatAverageSub;

  /// No description provided for @bodyFatAthleticSub.
  ///
  /// In it, this message translates to:
  /// **'Muscoli visibili'**
  String get bodyFatAthleticSub;

  /// No description provided for @bodyFatVeryLeanSub.
  ///
  /// In it, this message translates to:
  /// **'Addominali scolpiti'**
  String get bodyFatVeryLeanSub;

  /// No description provided for @timeMorning.
  ///
  /// In it, this message translates to:
  /// **'Mattina (6:00 - 10:00)'**
  String get timeMorning;

  /// No description provided for @timeAfternoon.
  ///
  /// In it, this message translates to:
  /// **'Pomeriggio (14:00 - 18:00)'**
  String get timeAfternoon;

  /// No description provided for @timeEvening.
  ///
  /// In it, this message translates to:
  /// **'Sera (18:00 - 22:00)'**
  String get timeEvening;

  /// No description provided for @timeMorningDesc.
  ///
  /// In it, this message translates to:
  /// **'Energia per la giornata, focus mobilità'**
  String get timeMorningDesc;

  /// No description provided for @timeAfternoonDesc.
  ///
  /// In it, this message translates to:
  /// **'Picco di performance fisica'**
  String get timeAfternoonDesc;

  /// No description provided for @timeEveningDesc.
  ///
  /// In it, this message translates to:
  /// **'Scarico stress, attenzione al sonno'**
  String get timeEveningDesc;

  /// No description provided for @recoveryExcellent.
  ///
  /// In it, this message translates to:
  /// **'Eccellente'**
  String get recoveryExcellent;

  /// No description provided for @recoveryGood.
  ///
  /// In it, this message translates to:
  /// **'Buono'**
  String get recoveryGood;

  /// No description provided for @recoveryPoor.
  ///
  /// In it, this message translates to:
  /// **'Scarso'**
  String get recoveryPoor;

  /// No description provided for @recoveryExcellentDesc.
  ///
  /// In it, this message translates to:
  /// **'Mi sveglio riposato, recupero velocemente'**
  String get recoveryExcellentDesc;

  /// No description provided for @recoveryGoodDesc.
  ///
  /// In it, this message translates to:
  /// **'Recupero normale, stanchezza occasionale'**
  String get recoveryGoodDesc;

  /// No description provided for @recoveryPoorDesc.
  ///
  /// In it, this message translates to:
  /// **'Fatico a recuperare, spesso stanco'**
  String get recoveryPoorDesc;

  /// No description provided for @nutritionFullTracking.
  ///
  /// In it, this message translates to:
  /// **'Tracciamento Completo'**
  String get nutritionFullTracking;

  /// No description provided for @nutritionPartialTracking.
  ///
  /// In it, this message translates to:
  /// **'Tracciamento Parziale'**
  String get nutritionPartialTracking;

  /// No description provided for @nutritionIntuitive.
  ///
  /// In it, this message translates to:
  /// **'Mangio Sano'**
  String get nutritionIntuitive;

  /// No description provided for @nutritionNone.
  ///
  /// In it, this message translates to:
  /// **'Non ci faccio caso'**
  String get nutritionNone;

  /// No description provided for @nutritionFullTrackingDesc.
  ///
  /// In it, this message translates to:
  /// **'Conto calorie e macro (MyFitnessPal, ecc.)'**
  String get nutritionFullTrackingDesc;

  /// No description provided for @nutritionPartialTrackingDesc.
  ///
  /// In it, this message translates to:
  /// **'Controllo le porzioni e le proteine'**
  String get nutritionPartialTrackingDesc;

  /// No description provided for @nutritionIntuitiveDesc.
  ///
  /// In it, this message translates to:
  /// **'Scelte salutari ma senza tracciare'**
  String get nutritionIntuitiveDesc;

  /// No description provided for @nutritionNoneDesc.
  ///
  /// In it, this message translates to:
  /// **'Mangio quello che capita'**
  String get nutritionNoneDesc;

  /// No description provided for @questionFrequencyTitle.
  ///
  /// In it, this message translates to:
  /// **'Frequenza Settimanale'**
  String get questionFrequencyTitle;

  /// No description provided for @questionFrequencySubtitle.
  ///
  /// In it, this message translates to:
  /// **'Quante volte vuoi allenarti a settimana?'**
  String get questionFrequencySubtitle;

  /// No description provided for @days.
  ///
  /// In it, this message translates to:
  /// **'giorni'**
  String get days;

  /// No description provided for @continueButton.
  ///
  /// In it, this message translates to:
  /// **'Continua'**
  String get continueButton;

  /// No description provided for @questionWorkoutTypeTitle.
  ///
  /// In it, this message translates to:
  /// **'Tipo di Allenamento'**
  String get questionWorkoutTypeTitle;

  /// No description provided for @questionWorkoutTypeSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Come preferisci allenarti?'**
  String get questionWorkoutTypeSubtitle;

  /// No description provided for @questionGenderTitle.
  ///
  /// In it, this message translates to:
  /// **'Chi sei?'**
  String get questionGenderTitle;

  /// No description provided for @questionGenderSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Per personalizzare il tuo piano.'**
  String get questionGenderSubtitle;

  /// No description provided for @genderMale.
  ///
  /// In it, this message translates to:
  /// **'Uomo'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In it, this message translates to:
  /// **'Donna'**
  String get genderFemale;

  /// No description provided for @ageHint.
  ///
  /// In it, this message translates to:
  /// **'Es. 25'**
  String get ageHint;

  /// No description provided for @years.
  ///
  /// In it, this message translates to:
  /// **'anni'**
  String get years;

  /// No description provided for @questionBodyFatTitle.
  ///
  /// In it, this message translates to:
  /// **'Stima la tua % di grasso'**
  String get questionBodyFatTitle;

  /// No description provided for @questionBodyFatSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Scegli l\'immagine che più ti assomiglia.'**
  String get questionBodyFatSubtitle;

  /// No description provided for @questionTimeTitle.
  ///
  /// In it, this message translates to:
  /// **'Quando preferisci allenarti?'**
  String get questionTimeTitle;

  /// No description provided for @questionTimeSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Ottimizzeremo il riscaldamento in base all\'orario.'**
  String get questionTimeSubtitle;

  /// No description provided for @questionSleepTitle.
  ///
  /// In it, this message translates to:
  /// **'Sonno e Recupero'**
  String get questionSleepTitle;

  /// No description provided for @questionSleepSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Fondamentale per calcolare il volume di allenamento.'**
  String get questionSleepSubtitle;

  /// No description provided for @sleepHoursLabel.
  ///
  /// In it, this message translates to:
  /// **'Ore di sonno per notte:'**
  String get sleepHoursLabel;

  /// No description provided for @questionRecoveryTitle.
  ///
  /// In it, this message translates to:
  /// **'Come ti senti solitamente?'**
  String get questionRecoveryTitle;

  /// No description provided for @questionNutritionTitle.
  ///
  /// In it, this message translates to:
  /// **'Alimentazione'**
  String get questionNutritionTitle;

  /// No description provided for @questionNutritionSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Come gestisci la tua dieta?'**
  String get questionNutritionSubtitle;

  /// No description provided for @questionGoal.
  ///
  /// In it, this message translates to:
  /// **'Qual è il tuo obiettivo?'**
  String get questionGoal;

  /// No description provided for @questionGoalSubtitle.
  ///
  /// In it, this message translates to:
  /// **'✨ Puoi selezionarne più di uno per un piano personalizzato.'**
  String get questionGoalSubtitle;

  /// No description provided for @questionLevel.
  ///
  /// In it, this message translates to:
  /// **'Il tuo livello?'**
  String get questionLevel;

  /// No description provided for @questionLevelSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Sii onesto, adatteremo tutto a te.'**
  String get questionLevelSubtitle;

  /// No description provided for @questionLocation.
  ///
  /// In it, this message translates to:
  /// **'Dove ti allenerai?'**
  String get questionLocation;

  /// No description provided for @questionLocationSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Casa o Palestra?'**
  String get questionLocationSubtitle;

  /// No description provided for @questionEquipment.
  ///
  /// In it, this message translates to:
  /// **'Che attrezzatura hai?'**
  String get questionEquipment;

  /// No description provided for @equipmentBodyweight.
  ///
  /// In it, this message translates to:
  /// **'Corpo Libero'**
  String get equipmentBodyweight;

  /// No description provided for @equipmentMachines.
  ///
  /// In it, this message translates to:
  /// **'Macchinari'**
  String get equipmentMachines;

  /// No description provided for @equipmentFreeWeights.
  ///
  /// In it, this message translates to:
  /// **'Pesi Liberi'**
  String get equipmentFreeWeights;

  /// No description provided for @injuryAddedTitle.
  ///
  /// In it, this message translates to:
  /// **'Infortunio Aggiunto'**
  String get injuryAddedTitle;

  /// No description provided for @injuryAddedSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Hai altri infortuni da segnalare?'**
  String get injuryAddedSubtitle;

  /// No description provided for @addAnotherInjury.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi un altro infortunio'**
  String get addAnotherInjury;

  /// No description provided for @continueNoInjury.
  ///
  /// In it, this message translates to:
  /// **'No, Continua'**
  String get continueNoInjury;

  /// No description provided for @nutritionCoachTitle.
  ///
  /// In it, this message translates to:
  /// **'Nutrition Coach'**
  String get nutritionCoachTitle;

  /// No description provided for @logMeal.
  ///
  /// In it, this message translates to:
  /// **'Registra Pasto'**
  String get logMeal;

  /// No description provided for @setupGoalsTitle.
  ///
  /// In it, this message translates to:
  /// **'🎯 Imposta i tuoi obiettivi'**
  String get setupGoalsTitle;

  /// No description provided for @setupGoalsSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Calcola le calorie e i macro ideali in base ai tuoi obiettivi personali'**
  String get setupGoalsSubtitle;

  /// No description provided for @startSetup.
  ///
  /// In it, this message translates to:
  /// **'Inizia Setup'**
  String get startSetup;

  /// No description provided for @dailyGoal.
  ///
  /// In it, this message translates to:
  /// **'Obiettivo Giornaliero'**
  String get dailyGoal;

  /// No description provided for @kcalRemaining.
  ///
  /// In it, this message translates to:
  /// **'{kcal} kcal rimanenti'**
  String kcalRemaining(int kcal);

  /// No description provided for @kcalExcess.
  ///
  /// In it, this message translates to:
  /// **'{kcal} kcal in eccesso'**
  String kcalExcess(int kcal);

  /// No description provided for @protein.
  ///
  /// In it, this message translates to:
  /// **'Proteine'**
  String get protein;

  /// No description provided for @carbs.
  ///
  /// In it, this message translates to:
  /// **'Carboidrati'**
  String get carbs;

  /// No description provided for @fats.
  ///
  /// In it, this message translates to:
  /// **'Grassi'**
  String get fats;

  /// No description provided for @addMeal.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi pasto'**
  String get addMeal;

  /// No description provided for @whatToCook.
  ///
  /// In it, this message translates to:
  /// **'Cosa Cucino?'**
  String get whatToCook;

  /// No description provided for @water.
  ///
  /// In it, this message translates to:
  /// **'Acqua'**
  String get water;

  /// No description provided for @waterGlassesCount.
  ///
  /// In it, this message translates to:
  /// **'{ml} / {goal} ml ({glasses} bicchieri)'**
  String waterGlassesCount(int ml, int goal, int glasses);

  /// No description provided for @smartSuggestions.
  ///
  /// In it, this message translates to:
  /// **'💡 Suggerimenti Smart'**
  String get smartSuggestions;

  /// No description provided for @todayMeals.
  ///
  /// In it, this message translates to:
  /// **'🍽️ Pasti di Oggi'**
  String get todayMeals;

  /// No description provided for @noMealsLogged.
  ///
  /// In it, this message translates to:
  /// **'Nessun pasto registrato'**
  String get noMealsLogged;

  /// No description provided for @addWater.
  ///
  /// In it, this message translates to:
  /// **'💧 Aggiungi Acqua'**
  String get addWater;

  /// No description provided for @yourProgress.
  ///
  /// In it, this message translates to:
  /// **'I Tuoi Progressi'**
  String get yourProgress;

  /// No description provided for @overview.
  ///
  /// In it, this message translates to:
  /// **'Panoramica'**
  String get overview;

  /// No description provided for @recentActivity.
  ///
  /// In it, this message translates to:
  /// **'Attività Recente'**
  String get recentActivity;

  /// No description provided for @weeklySummary.
  ///
  /// In it, this message translates to:
  /// **'RIEPILOGO SETTIMANALE'**
  String get weeklySummary;

  /// No description provided for @timeLabel.
  ///
  /// In it, this message translates to:
  /// **'Tempo'**
  String get timeLabel;

  /// No description provided for @streakLabel.
  ///
  /// In it, this message translates to:
  /// **'Streak'**
  String get streakLabel;

  /// No description provided for @streakDays.
  ///
  /// In it, this message translates to:
  /// **'GIORNI DI FILA'**
  String streakDays(int days);

  /// No description provided for @volumeLabel.
  ///
  /// In it, this message translates to:
  /// **'Volume'**
  String get volumeLabel;

  /// No description provided for @comingSoon.
  ///
  /// In it, this message translates to:
  /// **'In arrivo'**
  String get comingSoon;

  /// No description provided for @workoutProgressComingSoon.
  ///
  /// In it, this message translates to:
  /// **'Progressi Workout - In Arrivo'**
  String get workoutProgressComingSoon;

  /// No description provided for @nutritionProgressComingSoon.
  ///
  /// In it, this message translates to:
  /// **'Progressi Nutrizione - In Arrivo'**
  String get nutritionProgressComingSoon;

  /// No description provided for @healthAndFitness.
  ///
  /// In it, this message translates to:
  /// **'Salute & Fitness'**
  String get healthAndFitness;

  /// No description provided for @yourData.
  ///
  /// In it, this message translates to:
  /// **'I tuoi dati'**
  String get yourData;

  /// No description provided for @connected.
  ///
  /// In it, this message translates to:
  /// **'Connesso'**
  String get connected;

  /// No description provided for @notConnected.
  ///
  /// In it, this message translates to:
  /// **'Non connesso'**
  String get notConnected;

  /// No description provided for @disconnect.
  ///
  /// In it, this message translates to:
  /// **'Disconnetti'**
  String get disconnect;

  /// No description provided for @connectTo.
  ///
  /// In it, this message translates to:
  /// **'Connetti {platform}'**
  String connectTo(String platform);

  /// No description provided for @platformConnected.
  ///
  /// In it, this message translates to:
  /// **'{platform} connesso! ✅'**
  String platformConnected(String platform);

  /// No description provided for @permissionDenied.
  ///
  /// In it, this message translates to:
  /// **'Permessi non concessi. Riprova dalle impostazioni del dispositivo.'**
  String get permissionDenied;

  /// No description provided for @disconnectPlatform.
  ///
  /// In it, this message translates to:
  /// **'Disconnettere {platform}?'**
  String disconnectPlatform(String platform);

  /// No description provided for @syncedDataRemains.
  ///
  /// In it, this message translates to:
  /// **'I dati sincronizzati rimarranno, ma non verranno più aggiornati automaticamente.'**
  String get syncedDataRemains;

  /// No description provided for @healthConnectNotInstalled.
  ///
  /// In it, this message translates to:
  /// **'Health Connect non installato'**
  String get healthConnectNotInstalled;

  /// No description provided for @installHealthConnectInfo.
  ///
  /// In it, this message translates to:
  /// **'Per sincronizzare i dati di salute, installa Health Connect dal Play Store.'**
  String get installHealthConnectInfo;

  /// No description provided for @installHealthConnect.
  ///
  /// In it, this message translates to:
  /// **'Installa Health Connect'**
  String get installHealthConnect;

  /// No description provided for @syncAppleHealth.
  ///
  /// In it, this message translates to:
  /// **'Sincronizza i tuoi dati con Apple Health per una visione completa della tua salute.'**
  String get syncAppleHealth;

  /// No description provided for @syncHealthConnect.
  ///
  /// In it, this message translates to:
  /// **'Sincronizza i tuoi dati con Health Connect per una visione completa della tua salute.'**
  String get syncHealthConnect;

  /// No description provided for @dataSyncedAutomatically.
  ///
  /// In it, this message translates to:
  /// **'I tuoi dati vengono sincronizzati automaticamente'**
  String get dataSyncedAutomatically;

  /// No description provided for @connectToSyncWorkouts.
  ///
  /// In it, this message translates to:
  /// **'Connetti per sincronizzare i tuoi allenamenti'**
  String get connectToSyncWorkouts;

  /// No description provided for @stepsToday.
  ///
  /// In it, this message translates to:
  /// **'Passi oggi'**
  String get stepsToday;

  /// No description provided for @restingHeartRate.
  ///
  /// In it, this message translates to:
  /// **'Battito a riposo'**
  String get restingHeartRate;

  /// No description provided for @sleepYesterday.
  ///
  /// In it, this message translates to:
  /// **'Sonno ieri'**
  String get sleepYesterday;

  /// No description provided for @hours.
  ///
  /// In it, this message translates to:
  /// **'ore'**
  String get hours;

  /// No description provided for @autoSyncActive.
  ///
  /// In it, this message translates to:
  /// **'Sincronizzazione automatica attiva'**
  String get autoSyncActive;

  /// No description provided for @workoutsSavedTo.
  ///
  /// In it, this message translates to:
  /// **'I tuoi allenamenti vengono salvati automaticamente in {platform}'**
  String workoutsSavedTo(String platform);

  /// No description provided for @syncedData.
  ///
  /// In it, this message translates to:
  /// **'Dati sincronizzati'**
  String get syncedData;

  /// No description provided for @steps.
  ///
  /// In it, this message translates to:
  /// **'Passi'**
  String get steps;

  /// No description provided for @trackDailyActivity.
  ///
  /// In it, this message translates to:
  /// **'Monitora la tua attività giornaliera'**
  String get trackDailyActivity;

  /// No description provided for @heartRateLabel.
  ///
  /// In it, this message translates to:
  /// **'Frequenza cardiaca'**
  String get heartRateLabel;

  /// No description provided for @heartRateDesc.
  ///
  /// In it, this message translates to:
  /// **'Battito a riposo e durante l\'esercizio'**
  String get heartRateDesc;

  /// No description provided for @sleepLabel.
  ///
  /// In it, this message translates to:
  /// **'Sonno'**
  String get sleepLabel;

  /// No description provided for @sleepDesc.
  ///
  /// In it, this message translates to:
  /// **'Analisi della qualità del sonno'**
  String get sleepDesc;

  /// No description provided for @trackYourProgress.
  ///
  /// In it, this message translates to:
  /// **'Traccia i tuoi progressi'**
  String get trackYourProgress;

  /// No description provided for @workoutsLabel.
  ///
  /// In it, this message translates to:
  /// **'Allenamenti'**
  String get workoutsLabel;

  /// No description provided for @syncSessionsAutomatically.
  ///
  /// In it, this message translates to:
  /// **'Sincronizza automaticamente le sessioni'**
  String get syncSessionsAutomatically;

  /// No description provided for @introTitle.
  ///
  /// In it, this message translates to:
  /// **'Ciao! Sono Gigi 👋'**
  String get introTitle;

  /// No description provided for @introDescription.
  ///
  /// In it, this message translates to:
  /// **'Sarò il tuo personal trainer AI.\nRispondi a 2 domande veloci così posso creare il piano perfetto per te.'**
  String get introDescription;

  /// No description provided for @introButton.
  ///
  /// In it, this message translates to:
  /// **'INIZIAMO!'**
  String get introButton;

  /// No description provided for @sectionAboutYou.
  ///
  /// In it, this message translates to:
  /// **'Parlaci di te'**
  String get sectionAboutYou;

  /// No description provided for @sectionAboutYouSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Queste informazioni ci aiutano a calcolare il tuo fabbisogno.'**
  String get sectionAboutYouSubtitle;

  /// No description provided for @equipmentTitle.
  ///
  /// In it, this message translates to:
  /// **'Attrezzatura'**
  String get equipmentTitle;

  /// No description provided for @equipmentSubtitleGym.
  ///
  /// In it, this message translates to:
  /// **'Seleziona gli stili di allenamento che preferisci.'**
  String get equipmentSubtitleGym;

  /// No description provided for @equipmentSubtitleHome.
  ///
  /// In it, this message translates to:
  /// **'Cosa hai a disposizione nel tuo spazio?'**
  String get equipmentSubtitleHome;

  /// No description provided for @machinesTitle.
  ///
  /// In it, this message translates to:
  /// **'Quali Macchine?'**
  String get machinesTitle;

  /// No description provided for @machinesSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Seleziona quelle disponibili.'**
  String get machinesSubtitle;

  /// No description provided for @bodyweightTypeTitle.
  ///
  /// In it, this message translates to:
  /// **'Tipo di Corpo Libero'**
  String get bodyweightTypeTitle;

  /// No description provided for @bodyweightTypeSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Scegli il tuo stile preferito.'**
  String get bodyweightTypeSubtitle;

  /// No description provided for @injuriesTitle.
  ///
  /// In it, this message translates to:
  /// **'Infortuni'**
  String get injuriesTitle;

  /// No description provided for @injuriesSubtitleEmpty.
  ///
  /// In it, this message translates to:
  /// **'Hai infortuni attuali o passati?\n\n💡 Inserisci anche infortuni PASSATI se potrebbero influenzare il tuo allenamento (es. vecchie fratture, interventi chirurgici, problemi cronici).'**
  String get injuriesSubtitleEmpty;

  /// No description provided for @injuriesSubtitleFilled.
  ///
  /// In it, this message translates to:
  /// **'Hai aggiunto {count} infortuni. Vuoi aggiungerne altri?'**
  String injuriesSubtitleFilled(Object count);

  /// No description provided for @yesInjury.
  ///
  /// In it, this message translates to:
  /// **'Sì, ho un infortunio da segnalare'**
  String get yesInjury;

  /// No description provided for @noInjury.
  ///
  /// In it, this message translates to:
  /// **'No, sono sano'**
  String get noInjury;

  /// No description provided for @noMoreInjuries.
  ///
  /// In it, this message translates to:
  /// **'No, ho finito'**
  String get noMoreInjuries;

  /// No description provided for @injuryCategoryTitle.
  ///
  /// In it, this message translates to:
  /// **'Tipo di infortunio'**
  String get injuryCategoryTitle;

  /// No description provided for @injuryCategorySubtitle.
  ///
  /// In it, this message translates to:
  /// **'Seleziona la categoria'**
  String get injuryCategorySubtitle;

  /// No description provided for @injuryAreaTitle.
  ///
  /// In it, this message translates to:
  /// **'Zona specifica'**
  String get injuryAreaTitle;

  /// No description provided for @injuryTimingTitle.
  ///
  /// In it, this message translates to:
  /// **'Quando?'**
  String get injuryTimingTitle;

  /// No description provided for @injurySideTitle.
  ///
  /// In it, this message translates to:
  /// **'Lato'**
  String get injurySideTitle;

  /// No description provided for @sideLeft.
  ///
  /// In it, this message translates to:
  /// **'Sinistro'**
  String get sideLeft;

  /// No description provided for @sideRight.
  ///
  /// In it, this message translates to:
  /// **'Destro'**
  String get sideRight;

  /// No description provided for @sideBilateral.
  ///
  /// In it, this message translates to:
  /// **'Bilaterale'**
  String get sideBilateral;

  /// No description provided for @injuryStatusTitle.
  ///
  /// In it, this message translates to:
  /// **'Stato attuale dell\'infortunio'**
  String get injuryStatusTitle;

  /// No description provided for @injuryStatusSubtitle.
  ///
  /// In it, this message translates to:
  /// **'L\'infortunio è stato completamente superato?'**
  String get injuryStatusSubtitle;

  /// No description provided for @injurySeverityTitle.
  ///
  /// In it, this message translates to:
  /// **'Gravità'**
  String get injurySeverityTitle;

  /// No description provided for @painfulExercisesTitle.
  ///
  /// In it, this message translates to:
  /// **'Esercizi che causano dolore'**
  String get painfulExercisesTitle;

  /// No description provided for @painfulExercisesHint.
  ///
  /// In it, this message translates to:
  /// **'Es: Squat, Panca piana, Stacchi...'**
  String get painfulExercisesHint;

  /// No description provided for @notesTitle.
  ///
  /// In it, this message translates to:
  /// **'Note Aggiuntive (Opzionale)'**
  String get notesTitle;

  /// No description provided for @notesHint.
  ///
  /// In it, this message translates to:
  /// **'Note sull\'esercizio...'**
  String get notesHint;

  /// No description provided for @saveInjuryButton.
  ///
  /// In it, this message translates to:
  /// **'Salva Infortunio'**
  String get saveInjuryButton;

  /// No description provided for @sessionDurationTitle.
  ///
  /// In it, this message translates to:
  /// **'Durata Sessione'**
  String get sessionDurationTitle;

  /// No description provided for @sessionDurationSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Quanto tempo hai per allenarti?'**
  String get sessionDurationSubtitle;

  /// No description provided for @cardioMobilityTitle.
  ///
  /// In it, this message translates to:
  /// **'Cardio & Mobilità'**
  String get cardioMobilityTitle;

  /// No description provided for @cardioSection.
  ///
  /// In it, this message translates to:
  /// **'Cardio'**
  String get cardioSection;

  /// No description provided for @mobilitySection.
  ///
  /// In it, this message translates to:
  /// **'Mobilità'**
  String get mobilitySection;

  /// No description provided for @trainingSplitTitle.
  ///
  /// In it, this message translates to:
  /// **'Split di Allenamento'**
  String get trainingSplitTitle;

  /// No description provided for @trainingSplitSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Come vuoi organizzare i tuoi allenamenti?'**
  String get trainingSplitSubtitle;

  /// No description provided for @finalDetailsTitle.
  ///
  /// In it, this message translates to:
  /// **'Ultimi dettagli'**
  String get finalDetailsTitle;

  /// No description provided for @finalDetailsSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Qualcos\'altro da sapere? (Facoltativo)'**
  String get finalDetailsSubtitle;

  /// No description provided for @finalDetailsHint.
  ///
  /// In it, this message translates to:
  /// **'Puoi anche procedere senza inserire nulla.'**
  String get finalDetailsHint;

  /// No description provided for @finalDetailsBulletTitle.
  ///
  /// In it, this message translates to:
  /// **'Cosa potresti scrivere qui:'**
  String get finalDetailsBulletTitle;

  /// No description provided for @bulletPreferences.
  ///
  /// In it, this message translates to:
  /// **'Preferenze su esercizi specifici'**
  String get bulletPreferences;

  /// No description provided for @bulletGoals.
  ///
  /// In it, this message translates to:
  /// **'Obiettivi particolari non menzionati'**
  String get bulletGoals;

  /// No description provided for @bulletMedical.
  ///
  /// In it, this message translates to:
  /// **'Note mediche aggiuntive'**
  String get bulletMedical;

  /// No description provided for @finalNotesHint.
  ///
  /// In it, this message translates to:
  /// **'Scrivi qui le tue note...'**
  String get finalNotesHint;

  /// No description provided for @savingButton.
  ///
  /// In it, this message translates to:
  /// **'Salvataggio...'**
  String get savingButton;

  /// No description provided for @proceedButton.
  ///
  /// In it, this message translates to:
  /// **'Procedi'**
  String get proceedButton;

  /// No description provided for @bodyweightFunctional.
  ///
  /// In it, this message translates to:
  /// **'Allenamento Funzionale'**
  String get bodyweightFunctional;

  /// No description provided for @bodyweightFunctionalDesc.
  ///
  /// In it, this message translates to:
  /// **'Focus su mobilità e controllo'**
  String get bodyweightFunctionalDesc;

  /// No description provided for @bodyweightCalisthenics.
  ///
  /// In it, this message translates to:
  /// **'Calisthenics'**
  String get bodyweightCalisthenics;

  /// No description provided for @bodyweightCalisthenicsDesc.
  ///
  /// In it, this message translates to:
  /// **'Forza bruta a corpo libero'**
  String get bodyweightCalisthenicsDesc;

  /// No description provided for @bodyweightPure.
  ///
  /// In it, this message translates to:
  /// **'Solo Corpo Libero'**
  String get bodyweightPure;

  /// No description provided for @bodyweightPureDesc.
  ///
  /// In it, this message translates to:
  /// **'Senza alcuna attrezzatura'**
  String get bodyweightPureDesc;

  /// No description provided for @splitMonofrequency.
  ///
  /// In it, this message translates to:
  /// **'Monofrequenza'**
  String get splitMonofrequency;

  /// No description provided for @splitMonofrequencyDesc.
  ///
  /// In it, this message translates to:
  /// **'Ogni gruppo muscolare allenato 1 volta a settimana'**
  String get splitMonofrequencyDesc;

  /// No description provided for @splitMultifrequency.
  ///
  /// In it, this message translates to:
  /// **'Multifrequenza'**
  String get splitMultifrequency;

  /// No description provided for @splitMultifrequencyDesc.
  ///
  /// In it, this message translates to:
  /// **'Ogni gruppo muscolare allenato 2-3 volte a settimana'**
  String get splitMultifrequencyDesc;

  /// No description provided for @splitUpperLower.
  ///
  /// In it, this message translates to:
  /// **'Upper/Lower'**
  String get splitUpperLower;

  /// No description provided for @splitUpperLowerDesc.
  ///
  /// In it, this message translates to:
  /// **'Alternanza tra parte superiore e inferiore del corpo'**
  String get splitUpperLowerDesc;

  /// No description provided for @splitPushPullLegs.
  ///
  /// In it, this message translates to:
  /// **'Push/Pull/Legs'**
  String get splitPushPullLegs;

  /// No description provided for @splitPushPullLegsDesc.
  ///
  /// In it, this message translates to:
  /// **'Spinta, Trazione, Gambe in rotazione'**
  String get splitPushPullLegsDesc;

  /// No description provided for @splitFullBody.
  ///
  /// In it, this message translates to:
  /// **'Full Body'**
  String get splitFullBody;

  /// No description provided for @splitFullBodyDesc.
  ///
  /// In it, this message translates to:
  /// **'Tutto il corpo in ogni sessione'**
  String get splitFullBodyDesc;

  /// No description provided for @splitBodyPart.
  ///
  /// In it, this message translates to:
  /// **'Split per Gruppo Muscolare'**
  String get splitBodyPart;

  /// No description provided for @splitBodyPartDesc.
  ///
  /// In it, this message translates to:
  /// **'Un gruppo muscolare principale per sessione'**
  String get splitBodyPartDesc;

  /// No description provided for @splitArnold.
  ///
  /// In it, this message translates to:
  /// **'Arnold Split'**
  String get splitArnold;

  /// No description provided for @splitArnoldDesc.
  ///
  /// In it, this message translates to:
  /// **'Petto/Schiena, Spalle/Braccia, Gambe'**
  String get splitArnoldDesc;

  /// No description provided for @cardioNone.
  ///
  /// In it, this message translates to:
  /// **'Nessuno'**
  String get cardioNone;

  /// No description provided for @cardioNoneDesc.
  ///
  /// In it, this message translates to:
  /// **'Solo pesi'**
  String get cardioNoneDesc;

  /// No description provided for @cardioWarmUp.
  ///
  /// In it, this message translates to:
  /// **'Riscaldamento (5-10 min)'**
  String get cardioWarmUp;

  /// No description provided for @cardioWarmUpDesc.
  ///
  /// In it, this message translates to:
  /// **'Per attivare il corpo'**
  String get cardioWarmUpDesc;

  /// No description provided for @cardioPostWorkout.
  ///
  /// In it, this message translates to:
  /// **'Post-Workout (15-20 min)'**
  String get cardioPostWorkout;

  /// No description provided for @cardioPostWorkoutDesc.
  ///
  /// In it, this message translates to:
  /// **'Per bruciare extra calorie'**
  String get cardioPostWorkoutDesc;

  /// No description provided for @cardioSeparate.
  ///
  /// In it, this message translates to:
  /// **'Sessione Dedicata'**
  String get cardioSeparate;

  /// No description provided for @cardioSeparateDesc.
  ///
  /// In it, this message translates to:
  /// **'Focus sulla resistenza'**
  String get cardioSeparateDesc;

  /// No description provided for @mobilityNone.
  ///
  /// In it, this message translates to:
  /// **'Nessuna'**
  String get mobilityNone;

  /// No description provided for @mobilityNoneDesc.
  ///
  /// In it, this message translates to:
  /// **'Nessuna sessione di mobilità'**
  String get mobilityNoneDesc;

  /// No description provided for @mobilityPostWorkout.
  ///
  /// In it, this message translates to:
  /// **'Stretching Post Workout'**
  String get mobilityPostWorkout;

  /// No description provided for @mobilityPostWorkoutDesc.
  ///
  /// In it, this message translates to:
  /// **'Allungamento a fine sessione'**
  String get mobilityPostWorkoutDesc;

  /// No description provided for @mobilityPreWorkout.
  ///
  /// In it, this message translates to:
  /// **'Mobilità Pre-Workout'**
  String get mobilityPreWorkout;

  /// No description provided for @mobilityPreWorkoutDesc.
  ///
  /// In it, this message translates to:
  /// **'Preparazione al movimento'**
  String get mobilityPreWorkoutDesc;

  /// No description provided for @mobilityDedicated.
  ///
  /// In it, this message translates to:
  /// **'Sessione Dedicata'**
  String get mobilityDedicated;

  /// No description provided for @mobilityDedicatedDesc.
  ///
  /// In it, this message translates to:
  /// **'Focus su flessibilità e mobilità'**
  String get mobilityDedicatedDesc;

  /// No description provided for @equipmentBench.
  ///
  /// In it, this message translates to:
  /// **'Panca'**
  String get equipmentBench;

  /// No description provided for @equipmentBenchDesc.
  ///
  /// In it, this message translates to:
  /// **'Piana o inclinata'**
  String get equipmentBenchDesc;

  /// No description provided for @equipmentDumbbells.
  ///
  /// In it, this message translates to:
  /// **'Manubri'**
  String get equipmentDumbbells;

  /// No description provided for @equipmentDumbbellsDesc.
  ///
  /// In it, this message translates to:
  /// **'Manubri fissi o componibili'**
  String get equipmentDumbbellsDesc;

  /// No description provided for @equipmentBarbell.
  ///
  /// In it, this message translates to:
  /// **'Bilanciere'**
  String get equipmentBarbell;

  /// No description provided for @equipmentBarbellDesc.
  ///
  /// In it, this message translates to:
  /// **'Bilanciere olimpico o standard'**
  String get equipmentBarbellDesc;

  /// No description provided for @equipmentBands.
  ///
  /// In it, this message translates to:
  /// **'Elastici'**
  String get equipmentBands;

  /// No description provided for @equipmentBandsDesc.
  ///
  /// In it, this message translates to:
  /// **'Bande elastiche di varie resistenze'**
  String get equipmentBandsDesc;

  /// No description provided for @equipmentMachinesDesc.
  ///
  /// In it, this message translates to:
  /// **'Macchinari isotonici, cavi e stazioni multifunzione'**
  String get equipmentMachinesDesc;

  /// No description provided for @equipmentBodyweightDesc.
  ///
  /// In it, this message translates to:
  /// **'Calisthenics, sbarre, anelli e corpo libero'**
  String get equipmentBodyweightDesc;

  /// No description provided for @equipmentMachinesHomeDesc.
  ///
  /// In it, this message translates to:
  /// **'Eventuali macchinari home gym'**
  String get equipmentMachinesHomeDesc;

  /// No description provided for @equipmentBodyweightHomeDesc.
  ///
  /// In it, this message translates to:
  /// **'Sbarra trazioni o corpo libero'**
  String get equipmentBodyweightHomeDesc;

  /// No description provided for @labelWeightParentheses.
  ///
  /// In it, this message translates to:
  /// **'Peso (kg)'**
  String get labelWeightParentheses;

  /// No description provided for @labelGenderTitle.
  ///
  /// In it, this message translates to:
  /// **'Genere'**
  String get labelGenderTitle;

  /// No description provided for @injuryAllAreas.
  ///
  /// In it, this message translates to:
  /// **'Tutte le aree'**
  String get injuryAllAreas;

  /// No description provided for @injuryAllMuscles.
  ///
  /// In it, this message translates to:
  /// **'Tutti i muscoli'**
  String get injuryAllMuscles;

  /// No description provided for @injuryAllBones.
  ///
  /// In it, this message translates to:
  /// **'Tutte le ossa'**
  String get injuryAllBones;

  /// No description provided for @injurySectionTitle.
  ///
  /// In it, this message translates to:
  /// **'Sezione relativa agli infortuni'**
  String get injurySectionTitle;

  /// No description provided for @hintHeight.
  ///
  /// In it, this message translates to:
  /// **'Es. 175'**
  String get hintHeight;

  /// No description provided for @hintWeight.
  ///
  /// In it, this message translates to:
  /// **'Es. 70'**
  String get hintWeight;

  /// No description provided for @injuryStatusOvercome.
  ///
  /// In it, this message translates to:
  /// **'Superato'**
  String get injuryStatusOvercome;

  /// No description provided for @injuryStatusOvercomeDesc.
  ///
  /// In it, this message translates to:
  /// **'Non ho più problemi, ma meglio saperlo'**
  String get injuryStatusOvercomeDesc;

  /// No description provided for @injuryStatusActive.
  ///
  /// In it, this message translates to:
  /// **'Ancora presente'**
  String get injuryStatusActive;

  /// No description provided for @injuryStatusActiveDesc.
  ///
  /// In it, this message translates to:
  /// **'Ho ancora fastidi o limitazioni'**
  String get injuryStatusActiveDesc;

  /// No description provided for @bwEquipmentFunctionalTitle.
  ///
  /// In it, this message translates to:
  /// **'Attrezzi Funzionali Disponibili'**
  String get bwEquipmentFunctionalTitle;

  /// No description provided for @bwEquipmentCalisthenicsTitle.
  ///
  /// In it, this message translates to:
  /// **'Attrezzi Calisthenics Disponibili'**
  String get bwEquipmentCalisthenicsTitle;

  /// No description provided for @bwEquipmentSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Seleziona quelli che hai a disposizione'**
  String get bwEquipmentSubtitle;

  /// No description provided for @equipmentTrx.
  ///
  /// In it, this message translates to:
  /// **'TRX / Suspension Trainer'**
  String get equipmentTrx;

  /// No description provided for @equipmentBandsAlt.
  ///
  /// In it, this message translates to:
  /// **'Elastici / Resistance Bands'**
  String get equipmentBandsAlt;

  /// No description provided for @equipmentFitball.
  ///
  /// In it, this message translates to:
  /// **'Fitball / Swiss Ball'**
  String get equipmentFitball;

  /// No description provided for @equipmentBosu.
  ///
  /// In it, this message translates to:
  /// **'Bosu / Balance Board'**
  String get equipmentBosu;

  /// No description provided for @equipmentPullUpBar.
  ///
  /// In it, this message translates to:
  /// **'Sbarra Trazioni'**
  String get equipmentPullUpBar;

  /// No description provided for @equipmentRings.
  ///
  /// In it, this message translates to:
  /// **'Anelli'**
  String get equipmentRings;

  /// No description provided for @equipmentParallels.
  ///
  /// In it, this message translates to:
  /// **'Parallele / Dip Bars'**
  String get equipmentParallels;

  /// No description provided for @equipmentWallBars.
  ///
  /// In it, this message translates to:
  /// **'Spalliera / Wall Bars'**
  String get equipmentWallBars;

  /// No description provided for @homeTitleGreetingEarly.
  ///
  /// In it, this message translates to:
  /// **'Sei mattiniero'**
  String get homeTitleGreetingEarly;

  /// No description provided for @homeTitleGreetingMorning.
  ///
  /// In it, this message translates to:
  /// **'Buongiorno'**
  String get homeTitleGreetingMorning;

  /// No description provided for @homeTitleGreetingAfternoon.
  ///
  /// In it, this message translates to:
  /// **'Buon pomeriggio'**
  String get homeTitleGreetingAfternoon;

  /// No description provided for @homeTitleGreetingEvening.
  ///
  /// In it, this message translates to:
  /// **'Buonasera'**
  String get homeTitleGreetingEvening;

  /// No description provided for @searchHint.
  ///
  /// In it, this message translates to:
  /// **'Cerca per nome, muscolo o attrezzatura...'**
  String get searchHint;

  /// No description provided for @searchComingSoon.
  ///
  /// In it, this message translates to:
  /// **'Ricerca globale in arrivo! 🔍'**
  String get searchComingSoon;

  /// No description provided for @filterAll.
  ///
  /// In it, this message translates to:
  /// **'Tutti'**
  String get filterAll;

  /// No description provided for @filterCardio.
  ///
  /// In it, this message translates to:
  /// **'Cardio'**
  String get filterCardio;

  /// No description provided for @filterStrength.
  ///
  /// In it, this message translates to:
  /// **'Forza'**
  String get filterStrength;

  /// No description provided for @filterFlex.
  ///
  /// In it, this message translates to:
  /// **'Flex'**
  String get filterFlex;

  /// No description provided for @filterHiit.
  ///
  /// In it, this message translates to:
  /// **'HIIT'**
  String get filterHiit;

  /// No description provided for @homeNextWorkoutTitle.
  ///
  /// In it, this message translates to:
  /// **'Il tuo prossimo workout'**
  String get homeNextWorkoutTitle;

  /// No description provided for @homeProgressTitle.
  ///
  /// In it, this message translates to:
  /// **'I tuoi progressi'**
  String get homeProgressTitle;

  /// No description provided for @viewAll.
  ///
  /// In it, this message translates to:
  /// **'Vedi tutti'**
  String get viewAll;

  /// No description provided for @streakStart.
  ///
  /// In it, this message translates to:
  /// **'INIZIA LA TUA SERIE'**
  String get streakStart;

  /// No description provided for @streakKeepGoing.
  ///
  /// In it, this message translates to:
  /// **'Non fermarti ora! Manca poco al prossimo livello.'**
  String get streakKeepGoing;

  /// No description provided for @streakStartToday.
  ///
  /// In it, this message translates to:
  /// **'Completa un workout oggi per accendere la fiamma.'**
  String get streakStartToday;

  /// No description provided for @actionGeneratePlan.
  ///
  /// In it, this message translates to:
  /// **'Genera Scheda AI'**
  String get actionGeneratePlan;

  /// No description provided for @actionGeneratePlanDesc.
  ///
  /// In it, this message translates to:
  /// **'Piano su misura'**
  String get actionGeneratePlanDesc;

  /// No description provided for @actionCommunity.
  ///
  /// In it, this message translates to:
  /// **'Community'**
  String get actionCommunity;

  /// No description provided for @actionCommunityDesc.
  ///
  /// In it, this message translates to:
  /// **'Entra nel gruppo'**
  String get actionCommunityDesc;

  /// No description provided for @actionMyPlans.
  ///
  /// In it, this message translates to:
  /// **'Le Mie Schede'**
  String get actionMyPlans;

  /// No description provided for @actionFormCheck.
  ///
  /// In it, this message translates to:
  /// **'Form Check'**
  String get actionFormCheck;

  /// No description provided for @snackPlanReady.
  ///
  /// In it, this message translates to:
  /// **'🎉 La tua scheda è pronta!'**
  String get snackPlanReady;

  /// No description provided for @loadingCategory.
  ///
  /// In it, this message translates to:
  /// **'Caricamento {category}...'**
  String loadingCategory(String category);

  /// No description provided for @pleaseWait.
  ///
  /// In it, this message translates to:
  /// **'Attendere prego'**
  String get pleaseWait;

  /// No description provided for @generatePlanCardTitle.
  ///
  /// In it, this message translates to:
  /// **'Genera la Tua Scheda'**
  String get generatePlanCardTitle;

  /// No description provided for @generatePlanCardSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Crea il tuo piano personalizzato AI'**
  String get generatePlanCardSubtitle;

  /// No description provided for @athleticAssessmentTitle.
  ///
  /// In it, this message translates to:
  /// **'Valutazione Atletica'**
  String get athleticAssessmentTitle;

  /// No description provided for @athleticAssessmentSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Scopri il tuo livello reale in 5 minuti.'**
  String get athleticAssessmentSubtitle;

  /// No description provided for @insightsTitle.
  ///
  /// In it, this message translates to:
  /// **'I tuoi Insights'**
  String get insightsTitle;

  /// No description provided for @viewReport.
  ///
  /// In it, this message translates to:
  /// **'Vedi report'**
  String get viewReport;

  /// No description provided for @connectHealth.
  ///
  /// In it, this message translates to:
  /// **'Connetti Apple Health'**
  String get connectHealth;

  /// No description provided for @connectHealthDesc.
  ///
  /// In it, this message translates to:
  /// **'Per vedere insights personalizzati sui tuoi dati di salute'**
  String get connectHealthDesc;

  /// No description provided for @discoveredPatterns.
  ///
  /// In it, this message translates to:
  /// **'Pattern scoperti'**
  String get discoveredPatterns;

  /// No description provided for @aiCreatingPlanDesc.
  ///
  /// In it, this message translates to:
  /// **'Ci vorranno pochi minuti...'**
  String get aiCreatingPlanDesc;

  /// No description provided for @aiPlanBadge.
  ///
  /// In it, this message translates to:
  /// **'PIANO AI'**
  String get aiPlanBadge;

  /// No description provided for @goal.
  ///
  /// In it, this message translates to:
  /// **'Obiettivo'**
  String get goal;

  /// No description provided for @level.
  ///
  /// In it, this message translates to:
  /// **'Livello'**
  String get level;

  /// No description provided for @xp.
  ///
  /// In it, this message translates to:
  /// **'XP'**
  String get xp;

  /// No description provided for @gigiAssessmentComplete.
  ///
  /// In it, this message translates to:
  /// **'Ottimo lavoro! Hai completato la valutazione atletica! 🎉\n\nOra posso creare la tua scheda personalizzata basata sui tuoi obiettivi e il tuo livello.'**
  String get gigiAssessmentComplete;

  /// No description provided for @gigiGeneratePlanButton.
  ///
  /// In it, this message translates to:
  /// **'Genera la Tua Scheda AI'**
  String get gigiGeneratePlanButton;

  /// No description provided for @gigiStartTransformation.
  ///
  /// In it, this message translates to:
  /// **'Inizia la tua trasformazione in 3 step:\n1️⃣ Fai la Valutazione Atletica\n2️⃣ Genera la tua Scheda AI\n3️⃣ Inizia il tuo primo allenamento!'**
  String get gigiStartTransformation;

  /// No description provided for @gigiStartAssessmentButton.
  ///
  /// In it, this message translates to:
  /// **'Inizia Valutazione'**
  String get gigiStartAssessmentButton;

  /// No description provided for @gigiReadyForWorkout.
  ///
  /// In it, this message translates to:
  /// **'Pronto per l\'allenamento? Segui la tua scheda personalizzata e ricordati di registrare ogni set per monitorare i tuoi progressi!'**
  String get gigiReadyForWorkout;

  /// No description provided for @newWorkout.
  ///
  /// In it, this message translates to:
  /// **'Nuova Scheda'**
  String get newWorkout;

  /// No description provided for @editWorkout.
  ///
  /// In it, this message translates to:
  /// **'Modifica Scheda'**
  String get editWorkout;

  /// No description provided for @addAtLeastOneExercise.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi almeno un esercizio alla scheda'**
  String get addAtLeastOneExercise;

  /// No description provided for @workoutUpdated.
  ///
  /// In it, this message translates to:
  /// **'Scheda aggiornata!'**
  String get workoutUpdated;

  /// No description provided for @workoutCreated.
  ///
  /// In it, this message translates to:
  /// **'Scheda creata con successo!'**
  String get workoutCreated;

  /// No description provided for @limitReached.
  ///
  /// In it, this message translates to:
  /// **'Limite Raggiunto'**
  String get limitReached;

  /// No description provided for @quotaCustomWorkoutDesc.
  ///
  /// In it, this message translates to:
  /// **'Passa a Pro per creare più workout custom!'**
  String get quotaCustomWorkoutDesc;

  /// No description provided for @close.
  ///
  /// In it, this message translates to:
  /// **'Chiudi'**
  String get close;

  /// No description provided for @upgradePro.
  ///
  /// In it, this message translates to:
  /// **'Passa a Pro'**
  String get upgradePro;

  /// No description provided for @workoutNameLabel.
  ///
  /// In it, this message translates to:
  /// **'Nome Scheda *'**
  String get workoutNameLabel;

  /// No description provided for @workoutNameRequired.
  ///
  /// In it, this message translates to:
  /// **'Inserisci un nome per la scheda'**
  String get workoutNameRequired;

  /// No description provided for @descriptionOptional.
  ///
  /// In it, this message translates to:
  /// **'Descrizione (opzionale)'**
  String get descriptionOptional;

  /// No description provided for @noExercisesAdded.
  ///
  /// In it, this message translates to:
  /// **'Nessun esercizio aggiunto'**
  String get noExercisesAdded;

  /// No description provided for @tapAddSearch.
  ///
  /// In it, this message translates to:
  /// **'Tocca \"Aggiungi\" per cercare esercizi'**
  String get tapAddSearch;

  /// No description provided for @restSecondsLabel.
  ///
  /// In it, this message translates to:
  /// **'Rest (s)'**
  String get restSecondsLabel;

  /// No description provided for @notesOptional.
  ///
  /// In it, this message translates to:
  /// **'Note (opzionale)'**
  String get notesOptional;

  /// No description provided for @saveChanges.
  ///
  /// In it, this message translates to:
  /// **'Salva Modifiche'**
  String get saveChanges;

  /// No description provided for @searchExercises.
  ///
  /// In it, this message translates to:
  /// **'Cerca Esercizi'**
  String get searchExercises;

  /// No description provided for @filters.
  ///
  /// In it, this message translates to:
  /// **'Filtri'**
  String get filters;

  /// No description provided for @clearFilters.
  ///
  /// In it, this message translates to:
  /// **'Azzera'**
  String get clearFilters;

  /// No description provided for @muscleGroup.
  ///
  /// In it, this message translates to:
  /// **'Gruppo Muscolare'**
  String get muscleGroup;

  /// No description provided for @equipment.
  ///
  /// In it, this message translates to:
  /// **'Attrezzatura'**
  String get equipment;

  /// No description provided for @difficulty.
  ///
  /// In it, this message translates to:
  /// **'Difficoltà'**
  String get difficulty;

  /// No description provided for @applyFilters.
  ///
  /// In it, this message translates to:
  /// **'Applica Filtri'**
  String get applyFilters;

  /// No description provided for @noExercisesFound.
  ///
  /// In it, this message translates to:
  /// **'Nessun esercizio trovato'**
  String get noExercisesFound;

  /// No description provided for @tryAdjustFilters.
  ///
  /// In it, this message translates to:
  /// **'Prova a modificare i filtri'**
  String get tryAdjustFilters;

  /// No description provided for @intensity.
  ///
  /// In it, this message translates to:
  /// **'Intensità'**
  String get intensity;

  /// No description provided for @moderate.
  ///
  /// In it, this message translates to:
  /// **'Moderata'**
  String get moderate;

  /// No description provided for @add.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi'**
  String get add;

  /// No description provided for @numberLabel.
  ///
  /// In it, this message translates to:
  /// **'numero'**
  String get numberLabel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'fr',
    'it',
    'pt',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
