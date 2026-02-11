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

  /// No description provided for @confirmPassword.
  ///
  /// In it, this message translates to:
  /// **'Conferma Password'**
  String get confirmPassword;

  /// No description provided for @enterConfirmPassword.
  ///
  /// In it, this message translates to:
  /// **'Conferma la tua password'**
  String get enterConfirmPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In it, this message translates to:
  /// **'Le password non corrispondono'**
  String get passwordsDoNotMatch;

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
  /// **'Casa'**
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
  /// **'Errore imprevisto'**
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
  /// **'Serie'**
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
  /// **'PESO (KG)'**
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
  /// **'Muscolare'**
  String get injuryMuscular;

  /// No description provided for @injuryArticular.
  ///
  /// In it, this message translates to:
  /// **'Articolare'**
  String get injuryArticular;

  /// No description provided for @injuryBone.
  ///
  /// In it, this message translates to:
  /// **'Osseo'**
  String get injuryBone;

  /// No description provided for @myWorkoutsTitle.
  ///
  /// In it, this message translates to:
  /// **'Le Mie Schede'**
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

  /// No description provided for @appBarTitleGoals.
  ///
  /// In it, this message translates to:
  /// **'Imposta Obiettivi'**
  String get appBarTitleGoals;

  /// No description provided for @profileDataSummary.
  ///
  /// In it, this message translates to:
  /// **'Dati dal profilo: {height} cm • {weight} kg • {age} anni'**
  String profileDataSummary(int height, int weight, int age);

  /// No description provided for @goalStepTitle.
  ///
  /// In it, this message translates to:
  /// **'🎯 Qual è il tuo obiettivo?'**
  String get goalStepTitle;

  /// No description provided for @goalStepSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Scegli cosa vuoi raggiungere'**
  String get goalStepSubtitle;

  /// No description provided for @goalLoseWeight.
  ///
  /// In it, this message translates to:
  /// **'Perdere Peso'**
  String get goalLoseWeight;

  /// No description provided for @goalsSavedSuccess.
  ///
  /// In it, this message translates to:
  /// **'Obiettivi salvati con successo!'**
  String get goalsSavedSuccess;

  /// No description provided for @goalMaintain.
  ///
  /// In it, this message translates to:
  /// **'Mantenere Peso'**
  String get goalMaintain;

  /// No description provided for @goalGainMuscle.
  ///
  /// In it, this message translates to:
  /// **'Aumentare Massa Muscolare'**
  String get goalGainMuscle;

  /// No description provided for @goalGainWeight.
  ///
  /// In it, this message translates to:
  /// **'Aumentare Peso Corporeo'**
  String get goalGainWeight;

  /// No description provided for @dietStepTitle.
  ///
  /// In it, this message translates to:
  /// **'🥗 Tipo di dieta'**
  String get dietStepTitle;

  /// No description provided for @dietStepSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Hai preferenze alimentari?'**
  String get dietStepSubtitle;

  /// No description provided for @dietStandard.
  ///
  /// In it, this message translates to:
  /// **'Standard'**
  String get dietStandard;

  /// No description provided for @dietStandardDesc.
  ///
  /// In it, this message translates to:
  /// **'Nessuna restrizione'**
  String get dietStandardDesc;

  /// No description provided for @dietLowCarb.
  ///
  /// In it, this message translates to:
  /// **'Low Carb'**
  String get dietLowCarb;

  /// No description provided for @dietLowCarbDesc.
  ///
  /// In it, this message translates to:
  /// **'Pochi carboidrati'**
  String get dietLowCarbDesc;

  /// No description provided for @dietVegetarian.
  ///
  /// In it, this message translates to:
  /// **'Vegetariana'**
  String get dietVegetarian;

  /// No description provided for @dietVegetarianDesc.
  ///
  /// In it, this message translates to:
  /// **'No carne'**
  String get dietVegetarianDesc;

  /// No description provided for @dietVegan.
  ///
  /// In it, this message translates to:
  /// **'Vegana'**
  String get dietVegan;

  /// No description provided for @dietVeganDesc.
  ///
  /// In it, this message translates to:
  /// **'Solo vegetali'**
  String get dietVeganDesc;

  /// No description provided for @dietKeto.
  ///
  /// In it, this message translates to:
  /// **'Keto'**
  String get dietKeto;

  /// No description provided for @dietKetoDesc.
  ///
  /// In it, this message translates to:
  /// **'Chetogenica'**
  String get dietKetoDesc;

  /// No description provided for @dietMediterranean.
  ///
  /// In it, this message translates to:
  /// **'Mediterranea'**
  String get dietMediterranean;

  /// No description provided for @dietMediterraneanDesc.
  ///
  /// In it, this message translates to:
  /// **'Stile italiano'**
  String get dietMediterraneanDesc;

  /// No description provided for @resultsStepTitle.
  ///
  /// In it, this message translates to:
  /// **'🎉 Il tuo piano!'**
  String get resultsStepTitle;

  /// No description provided for @resultsStepSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Ecco i tuoi obiettivi giornalieri personalizzati'**
  String get resultsStepSubtitle;

  /// No description provided for @caloriesPerDay.
  ///
  /// In it, this message translates to:
  /// **'calorie/giorno'**
  String get caloriesPerDay;

  /// No description provided for @saveGoalsButton.
  ///
  /// In it, this message translates to:
  /// **'Salva Obiettivi'**
  String get saveGoalsButton;

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

  /// No description provided for @errorSavingProfile.
  ///
  /// In it, this message translates to:
  /// **'Errore durante il salvataggio del profilo'**
  String get errorSavingProfile;

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
  /// **'Attivo'**
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
  /// **'I Miei Workout'**
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
  /// **'Connetti Apple Health per generare il tuo report settimanale personalizzato.'**
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
  /// **'Profilo completato! 🎉\n\nOra posso creare la tua scheda personalizzata. Durante il primo allenamento calibrerò automaticamente i pesi perfetti per te.'**
  String get gigiAssessmentComplete;

  /// No description provided for @gigiGeneratePlanButton.
  ///
  /// In it, this message translates to:
  /// **'Genera la Tua Scheda AI'**
  String get gigiGeneratePlanButton;

  /// No description provided for @gigiStartTransformation.
  ///
  /// In it, this message translates to:
  /// **'Inizia la tua trasformazione in 2 step:\n1️⃣ Completa il tuo profilo\n2️⃣ Genera la tua Scheda AI\n\nLa calibrazione dei pesi avviene automaticamente durante il primo allenamento!'**
  String get gigiStartTransformation;

  /// No description provided for @gigiStartAssessmentButton.
  ///
  /// In it, this message translates to:
  /// **'Completa Profilo'**
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

  /// No description provided for @communityTitle.
  ///
  /// In it, this message translates to:
  /// **'Community'**
  String get communityTitle;

  /// No description provided for @activitiesToday.
  ///
  /// In it, this message translates to:
  /// **'{count} attività oggi'**
  String activitiesToday(Object count);

  /// No description provided for @feedTab.
  ///
  /// In it, this message translates to:
  /// **'Feed'**
  String get feedTab;

  /// No description provided for @challengesTab.
  ///
  /// In it, this message translates to:
  /// **'Sfide'**
  String get challengesTab;

  /// No description provided for @leaderboardTab.
  ///
  /// In it, this message translates to:
  /// **'Classifica'**
  String get leaderboardTab;

  /// No description provided for @noRecentActivity.
  ///
  /// In it, this message translates to:
  /// **'Nessuna attività recente'**
  String get noRecentActivity;

  /// No description provided for @communityGigiMessage.
  ///
  /// In it, this message translates to:
  /// **'Entrare a far parte della community aumenta la tua costanza del 35%. Interagisci con gli altri per restare motivato! 🚀'**
  String get communityGigiMessage;

  /// No description provided for @kudos.
  ///
  /// In it, this message translates to:
  /// **'Kudos'**
  String get kudos;

  /// No description provided for @before.
  ///
  /// In it, this message translates to:
  /// **'Prima'**
  String get before;

  /// No description provided for @newRecord.
  ///
  /// In it, this message translates to:
  /// **'Nuovo Record!'**
  String get newRecord;

  /// No description provided for @activeChallengesTitle.
  ///
  /// In it, this message translates to:
  /// **'Sfide Attive'**
  String get activeChallengesTitle;

  /// No description provided for @availableChallengesTitle.
  ///
  /// In it, this message translates to:
  /// **'Sfide Disponibili'**
  String get availableChallengesTitle;

  /// No description provided for @noActiveChallenges.
  ///
  /// In it, this message translates to:
  /// **'Nessuna sfida attiva al momento'**
  String get noActiveChallenges;

  /// No description provided for @percentCompleted.
  ///
  /// In it, this message translates to:
  /// **'{percent}% completato'**
  String percentCompleted(Object percent);

  /// No description provided for @daysRemaining.
  ///
  /// In it, this message translates to:
  /// **'{days} giorni rimasti'**
  String daysRemaining(Object days);

  /// No description provided for @participantsCount.
  ///
  /// In it, this message translates to:
  /// **'{count} partecipanti'**
  String participantsCount(Object count);

  /// No description provided for @joinButton.
  ///
  /// In it, this message translates to:
  /// **'Unisciti'**
  String get joinButton;

  /// No description provided for @leaderboardComingSoon.
  ///
  /// In it, this message translates to:
  /// **'Classifica in arrivo...'**
  String get leaderboardComingSoon;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In it, this message translates to:
  /// **'{minutes}m fa'**
  String timeMinutesAgo(Object minutes);

  /// No description provided for @timeHoursAgo.
  ///
  /// In it, this message translates to:
  /// **'{hours}h fa'**
  String timeHoursAgo(Object hours);

  /// No description provided for @timeDaysAgo.
  ///
  /// In it, this message translates to:
  /// **'{days}g fa'**
  String timeDaysAgo(Object days);

  /// No description provided for @feedUpdated.
  ///
  /// In it, this message translates to:
  /// **'Feed aggiornato!'**
  String get feedUpdated;

  /// No description provided for @commentsCount.
  ///
  /// In it, this message translates to:
  /// **'Commenti ({count})'**
  String commentsCount(Object count);

  /// No description provided for @writeCommentHint.
  ///
  /// In it, this message translates to:
  /// **'Scrivi un commento...'**
  String get writeCommentHint;

  /// No description provided for @commentSent.
  ///
  /// In it, this message translates to:
  /// **'Commento inviato!'**
  String get commentSent;

  /// No description provided for @kudosSentTo.
  ///
  /// In it, this message translates to:
  /// **'Kudos inviato a {name}! 🎉'**
  String kudosSentTo(Object name);

  /// No description provided for @joinChallengeTitle.
  ///
  /// In it, this message translates to:
  /// **'Unisciti alla sfida'**
  String get joinChallengeTitle;

  /// No description provided for @joinChallengeConfirm.
  ///
  /// In it, this message translates to:
  /// **'Vuoi unirti a \"{title}\"?\n\nPremio: {reward} XP'**
  String joinChallengeConfirm(Object reward, Object title);

  /// No description provided for @joinedChallengeSuccess.
  ///
  /// In it, this message translates to:
  /// **'Ti sei unito a \"{title}\"! 🎯'**
  String joinedChallengeSuccess(Object title);

  /// No description provided for @joinChallengeError.
  ///
  /// In it, this message translates to:
  /// **'Errore: impossibile unirsi alla sfida.'**
  String get joinChallengeError;

  /// No description provided for @bodyMeasurementsTitle.
  ///
  /// In it, this message translates to:
  /// **'Misure Corporee'**
  String get bodyMeasurementsTitle;

  /// No description provided for @howToMeasure.
  ///
  /// In it, this message translates to:
  /// **'Come misurare'**
  String get howToMeasure;

  /// No description provided for @howToMeasureSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Segui questi consigli per misure accurate'**
  String get howToMeasureSubtitle;

  /// No description provided for @measureSameTime.
  ///
  /// In it, this message translates to:
  /// **'Misura sempre alla stessa ora'**
  String get measureSameTime;

  /// No description provided for @morningFasting.
  ///
  /// In it, this message translates to:
  /// **'Preferibilmente al mattino, a digiuno'**
  String get morningFasting;

  /// No description provided for @useFlexibleTape.
  ///
  /// In it, this message translates to:
  /// **'Usa un metro da sarto flessibile'**
  String get useFlexibleTape;

  /// No description provided for @noRigidRulers.
  ///
  /// In it, this message translates to:
  /// **'Non usare righelli rigidi'**
  String get noRigidRulers;

  /// No description provided for @repeatEveryMeasure.
  ///
  /// In it, this message translates to:
  /// **'Ripeti ogni misura 2 volte'**
  String get repeatEveryMeasure;

  /// No description provided for @ensureCorrect.
  ///
  /// In it, this message translates to:
  /// **'Per assicurarti che sia corretta'**
  String get ensureCorrect;

  /// No description provided for @relaxDoNotContract.
  ///
  /// In it, this message translates to:
  /// **'Rilassati, non contrarre'**
  String get relaxDoNotContract;

  /// No description provided for @naturalPosition.
  ///
  /// In it, this message translates to:
  /// **'Posizione naturale, respiro normale'**
  String get naturalPosition;

  /// No description provided for @arms.
  ///
  /// In it, this message translates to:
  /// **'Braccia'**
  String get arms;

  /// No description provided for @measureBiceps.
  ///
  /// In it, this message translates to:
  /// **'Misura i tuoi bicipiti'**
  String get measureBiceps;

  /// No description provided for @positionLabel.
  ///
  /// In it, this message translates to:
  /// **'Posizione'**
  String get positionLabel;

  /// No description provided for @armFlexed90.
  ///
  /// In it, this message translates to:
  /// **'Braccio flesso a 90°, pugno chiuso'**
  String get armFlexed90;

  /// No description provided for @whereToMeasure.
  ///
  /// In it, this message translates to:
  /// **'Dove misurare'**
  String get whereToMeasure;

  /// No description provided for @thickestPoint.
  ///
  /// In it, this message translates to:
  /// **'Nel punto più spesso del muscolo'**
  String get thickestPoint;

  /// No description provided for @repeatBoth.
  ///
  /// In it, this message translates to:
  /// **'Ripeti per entrambi'**
  String get repeatBoth;

  /// No description provided for @mightBeDifferent.
  ///
  /// In it, this message translates to:
  /// **'Potrebbero essere leggermente diversi'**
  String get mightBeDifferent;

  /// No description provided for @torso.
  ///
  /// In it, this message translates to:
  /// **'Torso'**
  String get torso;

  /// No description provided for @chestWaistHips.
  ///
  /// In it, this message translates to:
  /// **'Petto, vita e fianchi'**
  String get chestWaistHips;

  /// No description provided for @underArmpits.
  ///
  /// In it, this message translates to:
  /// **'Metro sotto le ascelle, sul punto più sporgente'**
  String get underArmpits;

  /// No description provided for @bellyButtonHeight.
  ///
  /// In it, this message translates to:
  /// **'All\'altezza dell\'ombelico, posizione naturale'**
  String get bellyButtonHeight;

  /// No description provided for @widestHips.
  ///
  /// In it, this message translates to:
  /// **'Nel punto più largo dei glutei'**
  String get widestHips;

  /// No description provided for @legs.
  ///
  /// In it, this message translates to:
  /// **'Gambe'**
  String get legs;

  /// No description provided for @thighsCalves.
  ///
  /// In it, this message translates to:
  /// **'Cosce e polpacci'**
  String get thighsCalves;

  /// No description provided for @thigh.
  ///
  /// In it, this message translates to:
  /// **'Coscia'**
  String get thigh;

  /// No description provided for @midThigh.
  ///
  /// In it, this message translates to:
  /// **'A metà tra inguine e ginocchio, gamba rilassata'**
  String get midThigh;

  /// No description provided for @calf.
  ///
  /// In it, this message translates to:
  /// **'Polpaccio'**
  String get calf;

  /// No description provided for @widestCalf.
  ///
  /// In it, this message translates to:
  /// **'Nel punto più largo, in piedi'**
  String get widestCalf;

  /// No description provided for @startingPoint.
  ///
  /// In it, this message translates to:
  /// **'Il Tuo Punto di Partenza'**
  String get startingPoint;

  /// No description provided for @startingPointDesc.
  ///
  /// In it, this message translates to:
  /// **'Queste misure ci aiutano a creare la scheda perfetta per te e a tracciare i tuoi progressi nel tempo.'**
  String get startingPointDesc;

  /// No description provided for @startMeasurements.
  ///
  /// In it, this message translates to:
  /// **'Inizia le Misure'**
  String get startMeasurements;

  /// No description provided for @bicepRight.
  ///
  /// In it, this message translates to:
  /// **'Bicipite DX'**
  String get bicepRight;

  /// No description provided for @bicepLeft.
  ///
  /// In it, this message translates to:
  /// **'Bicipite SX'**
  String get bicepLeft;

  /// No description provided for @thighRight.
  ///
  /// In it, this message translates to:
  /// **'Coscia DX'**
  String get thighRight;

  /// No description provided for @thighLeft.
  ///
  /// In it, this message translates to:
  /// **'Coscia SX'**
  String get thighLeft;

  /// No description provided for @measurementsSummary.
  ///
  /// In it, this message translates to:
  /// **'Riepilogo Misure'**
  String get measurementsSummary;

  /// No description provided for @startingMeasurementsNote.
  ///
  /// In it, this message translates to:
  /// **'Ecco le tue misure di partenza'**
  String get startingMeasurementsNote;

  /// No description provided for @bicepDX.
  ///
  /// In it, this message translates to:
  /// **'Bicipite DX'**
  String get bicepDX;

  /// No description provided for @bicepSX.
  ///
  /// In it, this message translates to:
  /// **'Bicipite SX'**
  String get bicepSX;

  /// No description provided for @thighDX.
  ///
  /// In it, this message translates to:
  /// **'Coscia DX'**
  String get thighDX;

  /// No description provided for @thighSX.
  ///
  /// In it, this message translates to:
  /// **'Coscia SX'**
  String get thighSX;

  /// No description provided for @updateWeeklyNote.
  ///
  /// In it, this message translates to:
  /// **'Potrai aggiornare le misure ogni settimana per vedere i progressi!'**
  String get updateWeeklyNote;

  /// No description provided for @workoutStats.
  ///
  /// In it, this message translates to:
  /// **'Statistiche Allenamenti'**
  String get workoutStats;

  /// No description provided for @totalSeriesLabel.
  ///
  /// In it, this message translates to:
  /// **'Serie totali'**
  String get totalSeriesLabel;

  /// No description provided for @totalTimeLabel.
  ///
  /// In it, this message translates to:
  /// **'Tempo totale'**
  String get totalTimeLabel;

  /// No description provided for @myProgressTitle.
  ///
  /// In it, this message translates to:
  /// **'I Miei Progressi'**
  String get myProgressTitle;

  /// No description provided for @weeksCount.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =1{1 settimana} other{{count} settimane}}'**
  String weeksCount(num count);

  /// No description provided for @consecutiveMeasurements.
  ///
  /// In it, this message translates to:
  /// **'di misurazioni consecutive'**
  String get consecutiveMeasurements;

  /// No description provided for @measurementsCount.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =1{1 misurazione} other{{count} misurazioni}}'**
  String measurementsCount(num count);

  /// No description provided for @lastLabel.
  ///
  /// In it, this message translates to:
  /// **'ultima'**
  String get lastLabel;

  /// No description provided for @measurementsTrend.
  ///
  /// In it, this message translates to:
  /// **'Trend Misure'**
  String get measurementsTrend;

  /// No description provided for @waistCircumference.
  ///
  /// In it, this message translates to:
  /// **'Circonferenza Vita'**
  String get waistCircumference;

  /// No description provided for @addMoreMeasurementsTrend.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi più misure per vedere il trend'**
  String get addMoreMeasurementsTrend;

  /// No description provided for @bodyMap.
  ///
  /// In it, this message translates to:
  /// **'Mappa Corporea'**
  String get bodyMap;

  /// No description provided for @tapZoneDetails.
  ///
  /// In it, this message translates to:
  /// **'Tocca una zona per vedere i dettagli'**
  String get tapZoneDetails;

  /// No description provided for @setGoal.
  ///
  /// In it, this message translates to:
  /// **'Imposta un obiettivo'**
  String get setGoal;

  /// No description provided for @goalExample.
  ///
  /// In it, this message translates to:
  /// **'Es. \"Vita a 80cm\" o \"Bicipite a 40cm\"'**
  String get goalExample;

  /// No description provided for @quickActions.
  ///
  /// In it, this message translates to:
  /// **'Azioni rapide'**
  String get quickActions;

  /// No description provided for @newMeasurement.
  ///
  /// In it, this message translates to:
  /// **'Nuova Misura'**
  String get newMeasurement;

  /// No description provided for @progressPhoto.
  ///
  /// In it, this message translates to:
  /// **'Foto Progresso'**
  String get progressPhoto;

  /// No description provided for @yourJourneyPhotos.
  ///
  /// In it, this message translates to:
  /// **'Foto del Tuo Percorso'**
  String get yourJourneyPhotos;

  /// No description provided for @journeyPhotosDesc.
  ///
  /// In it, this message translates to:
  /// **'Tra qualche settimana potrai confrontare i tuoi progressi visivamente. È il modo più motivante per vedere i risultati!'**
  String get journeyPhotosDesc;

  /// No description provided for @privacyPrivate.
  ///
  /// In it, this message translates to:
  /// **'100% Private'**
  String get privacyPrivate;

  /// No description provided for @privacyDesc.
  ///
  /// In it, this message translates to:
  /// **'Le tue foto saranno visibili SOLO a te. Non vengono mai condivise o usate per altri scopi.'**
  String get privacyDesc;

  /// No description provided for @howToGetPerfectPhotos.
  ///
  /// In it, this message translates to:
  /// **'Come scattare foto perfette'**
  String get howToGetPerfectPhotos;

  /// No description provided for @sameLightTime.
  ///
  /// In it, this message translates to:
  /// **'Stessa luce e ora'**
  String get sameLightTime;

  /// No description provided for @comparableResults.
  ///
  /// In it, this message translates to:
  /// **'Per risultati comparabili'**
  String get comparableResults;

  /// No description provided for @minimalClothing.
  ///
  /// In it, this message translates to:
  /// **'Abbigliamento minimale'**
  String get minimalClothing;

  /// No description provided for @seeChanges.
  ///
  /// In it, this message translates to:
  /// **'Così vedi i cambiamenti'**
  String get seeChanges;

  /// No description provided for @neutralPosition.
  ///
  /// In it, this message translates to:
  /// **'Posizione neutra'**
  String get neutralPosition;

  /// No description provided for @relaxedArms.
  ///
  /// In it, this message translates to:
  /// **'Rilassato, braccia lungo i fianchi'**
  String get relaxedArms;

  /// No description provided for @useTimerMirror.
  ///
  /// In it, this message translates to:
  /// **'Usa timer o specchio'**
  String get useTimerMirror;

  /// No description provided for @easierAlone.
  ///
  /// In it, this message translates to:
  /// **'Più facile da solo'**
  String get easierAlone;

  /// No description provided for @sameSpot.
  ///
  /// In it, this message translates to:
  /// **'Stesso punto'**
  String get sameSpot;

  /// No description provided for @neutralBackground.
  ///
  /// In it, this message translates to:
  /// **'Sfondo neutro, stessa distanza'**
  String get neutralBackground;

  /// No description provided for @front.
  ///
  /// In it, this message translates to:
  /// **'Fronte'**
  String get front;

  /// No description provided for @side.
  ///
  /// In it, this message translates to:
  /// **'Lato'**
  String get side;

  /// No description provided for @backLabel.
  ///
  /// In it, this message translates to:
  /// **'Dietro'**
  String get backLabel;

  /// No description provided for @savePhotos.
  ///
  /// In it, this message translates to:
  /// **'Salva Foto'**
  String get savePhotos;

  /// No description provided for @seeProgressNote.
  ///
  /// In it, this message translates to:
  /// **'Tra 4-8 settimane potrai vedere i cambiamenti confrontando le foto!'**
  String get seeProgressNote;

  /// No description provided for @chooseSource.
  ///
  /// In it, this message translates to:
  /// **'Scegli sorgente'**
  String get chooseSource;

  /// No description provided for @camera.
  ///
  /// In it, this message translates to:
  /// **'Fotocamera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In it, this message translates to:
  /// **'Galleria'**
  String get gallery;

  /// No description provided for @photosSavedSuccess.
  ///
  /// In it, this message translates to:
  /// **'Foto salvate con successo!'**
  String get photosSavedSuccess;

  /// No description provided for @yourProgressTab.
  ///
  /// In it, this message translates to:
  /// **'I Tuoi Progressi'**
  String get yourProgressTab;

  /// No description provided for @noPhotosYet.
  ///
  /// In it, this message translates to:
  /// **'Nessuna foto ancora'**
  String get noPhotosYet;

  /// No description provided for @noPhotosDesc.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi foto per vedere la tua trasformazione nel tempo'**
  String get noPhotosDesc;

  /// No description provided for @addPhotosButton.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi Foto'**
  String get addPhotosButton;

  /// No description provided for @yourTransformation.
  ///
  /// In it, this message translates to:
  /// **'La Tua Trasformazione'**
  String get yourTransformation;

  /// No description provided for @swipeToCompare.
  ///
  /// In it, this message translates to:
  /// **'Scorri per confrontare prima e dopo'**
  String get swipeToCompare;

  /// No description provided for @addNewPhotos.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi Nuove Foto'**
  String get addNewPhotos;

  /// No description provided for @daysCount.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =1{1 giorno} other{{count} giorni}}'**
  String daysCount(num count);

  /// No description provided for @beforeLabel.
  ///
  /// In it, this message translates to:
  /// **'PRIMA'**
  String get beforeLabel;

  /// No description provided for @afterLabel.
  ///
  /// In it, this message translates to:
  /// **'DOPO'**
  String get afterLabel;

  /// No description provided for @noMeasurementsYet.
  ///
  /// In it, this message translates to:
  /// **'Nessuna misura ancora'**
  String get noMeasurementsYet;

  /// No description provided for @noMeasurementsDesc.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi le tue misure per tracciare i progressi'**
  String get noMeasurementsDesc;

  /// No description provided for @addMeasurementsButton.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi Misure'**
  String get addMeasurementsButton;

  /// No description provided for @measurementsComparison.
  ///
  /// In it, this message translates to:
  /// **'Confronto Misure'**
  String get measurementsComparison;

  /// No description provided for @history.
  ///
  /// In it, this message translates to:
  /// **'Storico'**
  String get history;

  /// No description provided for @updateMeasurements.
  ///
  /// In it, this message translates to:
  /// **'Aggiorna Misure'**
  String get updateMeasurements;

  /// No description provided for @startLabel.
  ///
  /// In it, this message translates to:
  /// **'Inizio'**
  String get startLabel;

  /// No description provided for @lastMeasurementsHistory.
  ///
  /// In it, this message translates to:
  /// **'Ultimi {count} rilevamenti'**
  String lastMeasurementsHistory(Object count);

  /// No description provided for @waistTrendOverTime.
  ///
  /// In it, this message translates to:
  /// **'Circonferenza vita nel tempo'**
  String get waistTrendOverTime;

  /// No description provided for @heightCm.
  ///
  /// In it, this message translates to:
  /// **'Altezza (cm)'**
  String get heightCm;

  /// No description provided for @weightKg.
  ///
  /// In it, this message translates to:
  /// **'Peso (kg)'**
  String get weightKg;

  /// No description provided for @profileUpdatedSuccess.
  ///
  /// In it, this message translates to:
  /// **'Profilo aggiornato con successo'**
  String get profileUpdatedSuccess;

  /// No description provided for @saveErrorGeneric.
  ///
  /// In it, this message translates to:
  /// **'Errore durante il salvataggio'**
  String get saveErrorGeneric;

  /// No description provided for @voiceModeTitle.
  ///
  /// In it, this message translates to:
  /// **'VOICE MODE'**
  String get voiceModeTitle;

  /// No description provided for @voiceModeSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Gigi ti guida\nogni ripetizione'**
  String get voiceModeSubtitle;

  /// No description provided for @musicModeTitle.
  ///
  /// In it, this message translates to:
  /// **'MUSIC MODE'**
  String get musicModeTitle;

  /// No description provided for @musicModeSubtitle.
  ///
  /// In it, this message translates to:
  /// **'La tua musica\n+ cue minimi'**
  String get musicModeSubtitle;

  /// No description provided for @discreteMode.
  ///
  /// In it, this message translates to:
  /// **'Modalità Discreta'**
  String get discreteMode;

  /// No description provided for @unlockedCount.
  ///
  /// In it, this message translates to:
  /// **'Sbloccati ({count})'**
  String unlockedCount(Object count);

  /// No description provided for @toUnlockCount.
  ///
  /// In it, this message translates to:
  /// **'Da Sbloccare ({count})'**
  String toUnlockCount(Object count);

  /// No description provided for @howToMeasureTitle.
  ///
  /// In it, this message translates to:
  /// **'📏 Come prendere le misure'**
  String get howToMeasureTitle;

  /// No description provided for @howToMeasureDesc.
  ///
  /// In it, this message translates to:
  /// **'Segui questi consigli per misure accurate'**
  String get howToMeasureDesc;

  /// No description provided for @armsSection.
  ///
  /// In it, this message translates to:
  /// **'💪 Braccia'**
  String get armsSection;

  /// No description provided for @armsSectionDesc.
  ///
  /// In it, this message translates to:
  /// **'Misura i tuoi bicipiti'**
  String get armsSectionDesc;

  /// No description provided for @torsoSection.
  ///
  /// In it, this message translates to:
  /// **'🫁 Torso'**
  String get torsoSection;

  /// No description provided for @torsoSectionDesc.
  ///
  /// In it, this message translates to:
  /// **'Petto, vita e fianchi'**
  String get torsoSectionDesc;

  /// No description provided for @legsSection.
  ///
  /// In it, this message translates to:
  /// **'🦵 Gambe'**
  String get legsSection;

  /// No description provided for @legsSectionDesc.
  ///
  /// In it, this message translates to:
  /// **'Cosce e polpacci'**
  String get legsSectionDesc;

  /// No description provided for @frontPhoto.
  ///
  /// In it, this message translates to:
  /// **'Fronte'**
  String get frontPhoto;

  /// No description provided for @sidePhoto.
  ///
  /// In it, this message translates to:
  /// **'Lato'**
  String get sidePhoto;

  /// No description provided for @backPhoto.
  ///
  /// In it, this message translates to:
  /// **'Retro'**
  String get backPhoto;

  /// No description provided for @cameraOption.
  ///
  /// In it, this message translates to:
  /// **'Fotocamera'**
  String get cameraOption;

  /// No description provided for @galleryOption.
  ///
  /// In it, this message translates to:
  /// **'Galleria'**
  String get galleryOption;

  /// No description provided for @noPhotosYetTitle.
  ///
  /// In it, this message translates to:
  /// **'Nessuna foto ancora'**
  String get noPhotosYetTitle;

  /// No description provided for @noPhotosYetDesc.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi foto per vedere la tua trasformazione nel tempo'**
  String get noPhotosYetDesc;

  /// No description provided for @noMeasurementsYetTitle.
  ///
  /// In it, this message translates to:
  /// **'Nessuna misura ancora'**
  String get noMeasurementsYetTitle;

  /// No description provided for @noMeasurementsYetDesc.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi le tue misure per tracciare i progressi'**
  String get noMeasurementsYetDesc;

  /// No description provided for @newMeasurementAction.
  ///
  /// In it, this message translates to:
  /// **'Nuova Misura'**
  String get newMeasurementAction;

  /// No description provided for @progressPhotoAction.
  ///
  /// In it, this message translates to:
  /// **'Foto Progresso'**
  String get progressPhotoAction;

  /// No description provided for @compareAction.
  ///
  /// In it, this message translates to:
  /// **'Confronta'**
  String get compareAction;

  /// No description provided for @weightStat.
  ///
  /// In it, this message translates to:
  /// **'Peso'**
  String get weightStat;

  /// No description provided for @bodyFatStat.
  ///
  /// In it, this message translates to:
  /// **'Body Fat'**
  String get bodyFatStat;

  /// No description provided for @daysStat.
  ///
  /// In it, this message translates to:
  /// **'Giorni'**
  String get daysStat;

  /// No description provided for @streakStat.
  ///
  /// In it, this message translates to:
  /// **'Streak'**
  String get streakStat;

  /// No description provided for @measurementsStat.
  ///
  /// In it, this message translates to:
  /// **'Misure'**
  String get measurementsStat;

  /// No description provided for @waistStat.
  ///
  /// In it, this message translates to:
  /// **'Vita'**
  String get waistStat;

  /// No description provided for @bicepStat.
  ///
  /// In it, this message translates to:
  /// **'Bicipite'**
  String get bicepStat;

  /// No description provided for @exercisesLabel.
  ///
  /// In it, this message translates to:
  /// **'Esercizi'**
  String get exercisesLabel;

  /// No description provided for @durationLabel.
  ///
  /// In it, this message translates to:
  /// **'Durata'**
  String get durationLabel;

  /// No description provided for @caloriesLabel.
  ///
  /// In it, this message translates to:
  /// **'Calorie'**
  String get caloriesLabel;

  /// No description provided for @totalSetsLabel.
  ///
  /// In it, this message translates to:
  /// **'Serie Totali'**
  String get totalSetsLabel;

  /// No description provided for @minutesLabel.
  ///
  /// In it, this message translates to:
  /// **'Minuti'**
  String get minutesLabel;

  /// No description provided for @seriesLabel.
  ///
  /// In it, this message translates to:
  /// **'Serie'**
  String get seriesLabel;

  /// No description provided for @startButton.
  ///
  /// In it, this message translates to:
  /// **'Inizia'**
  String get startButton;

  /// No description provided for @completeButton.
  ///
  /// In it, this message translates to:
  /// **'Completa'**
  String get completeButton;

  /// No description provided for @completedButton.
  ///
  /// In it, this message translates to:
  /// **'Completa 🎉'**
  String get completedButton;

  /// No description provided for @trialWorkoutTitle.
  ///
  /// In it, this message translates to:
  /// **'Trial Workout'**
  String get trialWorkoutTitle;

  /// No description provided for @recommendedLabel.
  ///
  /// In it, this message translates to:
  /// **'Consigliato'**
  String get recommendedLabel;

  /// No description provided for @skipTrialTitle.
  ///
  /// In it, this message translates to:
  /// **'Salta il Trial'**
  String get skipTrialTitle;

  /// No description provided for @generateNowLabel.
  ///
  /// In it, this message translates to:
  /// **'Genera subito'**
  String get generateNowLabel;

  /// No description provided for @exampleTen.
  ///
  /// In it, this message translates to:
  /// **'Es: 10'**
  String get exampleTen;

  /// No description provided for @exampleWeight.
  ///
  /// In it, this message translates to:
  /// **'Es: 20.5'**
  String get exampleWeight;

  /// No description provided for @confirmButton.
  ///
  /// In it, this message translates to:
  /// **'CONFERMA'**
  String get confirmButton;

  /// No description provided for @errorTitle.
  ///
  /// In it, this message translates to:
  /// **'Errore'**
  String get errorTitle;

  /// No description provided for @setTimeLabel.
  ///
  /// In it, this message translates to:
  /// **'Tempo serie'**
  String get setTimeLabel;

  /// No description provided for @minutesLabelWithValue.
  ///
  /// In it, this message translates to:
  /// **'{value} minuti'**
  String minutesLabelWithValue(Object value);

  /// No description provided for @exampleDifficultyHint.
  ///
  /// In it, this message translates to:
  /// **'Es: Ho trovato difficile l\'esercizio X...'**
  String get exampleDifficultyHint;

  /// No description provided for @instructionsSection.
  ///
  /// In it, this message translates to:
  /// **'Istruzioni'**
  String get instructionsSection;

  /// No description provided for @videoDemoSection.
  ///
  /// In it, this message translates to:
  /// **'Video Dimostrazione'**
  String get videoDemoSection;

  /// No description provided for @intensityLabel.
  ///
  /// In it, this message translates to:
  /// **'Intensità'**
  String get intensityLabel;

  /// No description provided for @heartRateZone.
  ///
  /// In it, this message translates to:
  /// **'Zona FC'**
  String get heartRateZone;

  /// No description provided for @basicInfoSection.
  ///
  /// In it, this message translates to:
  /// **'Informazioni Base'**
  String get basicInfoSection;

  /// No description provided for @goalsSection.
  ///
  /// In it, this message translates to:
  /// **'Obiettivi'**
  String get goalsSection;

  /// No description provided for @workoutPreferencesSection.
  ///
  /// In it, this message translates to:
  /// **'Preferenze Allenamento'**
  String get workoutPreferencesSection;

  /// No description provided for @editButton.
  ///
  /// In it, this message translates to:
  /// **'Modifica'**
  String get editButton;

  /// No description provided for @introPhase.
  ///
  /// In it, this message translates to:
  /// **'Intro'**
  String get introPhase;

  /// No description provided for @duringPhase.
  ///
  /// In it, this message translates to:
  /// **'Durante'**
  String get duringPhase;

  /// No description provided for @finalPhase.
  ///
  /// In it, this message translates to:
  /// **'Finale'**
  String get finalPhase;

  /// No description provided for @stopButton.
  ///
  /// In it, this message translates to:
  /// **'Stop'**
  String get stopButton;

  /// No description provided for @repsLabel.
  ///
  /// In it, this message translates to:
  /// **'RIPETIZIONI'**
  String get repsLabel;

  /// No description provided for @weightKgLabel.
  ///
  /// In it, this message translates to:
  /// **'PESO (KG)'**
  String get weightKgLabel;

  /// No description provided for @consentManagementSection.
  ///
  /// In it, this message translates to:
  /// **'Gestione Consensi'**
  String get consentManagementSection;

  /// No description provided for @pushNotificationsTitle.
  ///
  /// In it, this message translates to:
  /// **'Notifiche Push'**
  String get pushNotificationsTitle;

  /// No description provided for @pushNotificationsDesc.
  ///
  /// In it, this message translates to:
  /// **'Promemoria allenamenti e progressi'**
  String get pushNotificationsDesc;

  /// No description provided for @emailMarketingTitle.
  ///
  /// In it, this message translates to:
  /// **'Email Marketing'**
  String get emailMarketingTitle;

  /// No description provided for @emailMarketingDesc.
  ///
  /// In it, this message translates to:
  /// **'Promozioni e novità'**
  String get emailMarketingDesc;

  /// No description provided for @analyticsTitle.
  ///
  /// In it, this message translates to:
  /// **'Analytics'**
  String get analyticsTitle;

  /// No description provided for @analyticsDesc.
  ///
  /// In it, this message translates to:
  /// **'Aiutaci a migliorare l\'app'**
  String get analyticsDesc;

  /// No description provided for @legalDocumentsSection.
  ///
  /// In it, this message translates to:
  /// **'Documenti Legali'**
  String get legalDocumentsSection;

  /// No description provided for @gdprRightsSection.
  ///
  /// In it, this message translates to:
  /// **'I Tuoi Diritti GDPR'**
  String get gdprRightsSection;

  /// No description provided for @exportDataTitle.
  ///
  /// In it, this message translates to:
  /// **'Esporta i Miei Dati'**
  String get exportDataTitle;

  /// No description provided for @exportDataDesc.
  ///
  /// In it, this message translates to:
  /// **'Scarica tutti i tuoi dati in formato JSON'**
  String get exportDataDesc;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In it, this message translates to:
  /// **'Elimina Account'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountDesc.
  ///
  /// In it, this message translates to:
  /// **'Cancella permanentemente i tuoi dati'**
  String get deleteAccountDesc;

  /// No description provided for @goalLabel.
  ///
  /// In it, this message translates to:
  /// **'Obiettivo'**
  String get goalLabel;

  /// No description provided for @experienceLevelLabel.
  ///
  /// In it, this message translates to:
  /// **'Livello di Esperienza'**
  String get experienceLevelLabel;

  /// No description provided for @weeklyFrequencyLabel.
  ///
  /// In it, this message translates to:
  /// **'Frequenza Settimanale'**
  String get weeklyFrequencyLabel;

  /// No description provided for @trainingLocationLabel.
  ///
  /// In it, this message translates to:
  /// **'Dove ti alleni?'**
  String get trainingLocationLabel;

  /// No description provided for @workoutTypeLabel.
  ///
  /// In it, this message translates to:
  /// **'Tipo di Allenamento'**
  String get workoutTypeLabel;

  /// No description provided for @trainingSplitLabel.
  ///
  /// In it, this message translates to:
  /// **'Split di Allenamento'**
  String get trainingSplitLabel;

  /// No description provided for @sessionDurationLabel.
  ///
  /// In it, this message translates to:
  /// **'Durata Sessione'**
  String get sessionDurationLabel;

  /// No description provided for @cardioPreferenceLabel.
  ///
  /// In it, this message translates to:
  /// **'Preferenza Cardio'**
  String get cardioPreferenceLabel;

  /// No description provided for @mobilityPreferenceLabel.
  ///
  /// In it, this message translates to:
  /// **'Preferenza Mobilità'**
  String get mobilityPreferenceLabel;

  /// No description provided for @trialWorkoutLabel.
  ///
  /// In it, this message translates to:
  /// **'Trial Workout'**
  String get trialWorkoutLabel;

  /// No description provided for @heightWeightLabel.
  ///
  /// In it, this message translates to:
  /// **'Altezza e Peso'**
  String get heightWeightLabel;

  /// No description provided for @defaultWorkoutName.
  ///
  /// In it, this message translates to:
  /// **'Allenamento'**
  String get defaultWorkoutName;

  /// No description provided for @goToWorkoutButton.
  ///
  /// In it, this message translates to:
  /// **'Vai all\'Allenamento'**
  String get goToWorkoutButton;

  /// No description provided for @startText.
  ///
  /// In it, this message translates to:
  /// **'Inizia'**
  String get startText;

  /// No description provided for @nextText.
  ///
  /// In it, this message translates to:
  /// **'Avanti'**
  String get nextText;

  /// No description provided for @yourNameHint.
  ///
  /// In it, this message translates to:
  /// **'Il tuo nome'**
  String get yourNameHint;

  /// No description provided for @detailsLabel.
  ///
  /// In it, this message translates to:
  /// **'Dettagli'**
  String get detailsLabel;

  /// No description provided for @whatsappShare.
  ///
  /// In it, this message translates to:
  /// **'WhatsApp'**
  String get whatsappShare;

  /// No description provided for @instagramShare.
  ///
  /// In it, this message translates to:
  /// **'Instagram'**
  String get instagramShare;

  /// No description provided for @otherShare.
  ///
  /// In it, this message translates to:
  /// **'Altro'**
  String get otherShare;

  /// No description provided for @totalReferrals.
  ///
  /// In it, this message translates to:
  /// **'Totali'**
  String get totalReferrals;

  /// No description provided for @pendingReferrals.
  ///
  /// In it, this message translates to:
  /// **'In attesa'**
  String get pendingReferrals;

  /// No description provided for @convertedReferrals.
  ///
  /// In it, this message translates to:
  /// **'Convertiti'**
  String get convertedReferrals;

  /// No description provided for @yourReferralCode.
  ///
  /// In it, this message translates to:
  /// **'Il tuo codice referral'**
  String get yourReferralCode;

  /// No description provided for @skipButton.
  ///
  /// In it, this message translates to:
  /// **'Salta'**
  String get skipButton;

  /// No description provided for @instructionsLabel.
  ///
  /// In it, this message translates to:
  /// **'Istruzioni'**
  String get instructionsLabel;

  /// No description provided for @videoDemoLabel.
  ///
  /// In it, this message translates to:
  /// **'Video Dimostrazione'**
  String get videoDemoLabel;

  /// No description provided for @pause.
  ///
  /// In it, this message translates to:
  /// **'Pausa'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In it, this message translates to:
  /// **'Riprendi'**
  String get resume;

  /// No description provided for @savedLabel.
  ///
  /// In it, this message translates to:
  /// **'SALVATO!'**
  String get savedLabel;

  /// No description provided for @deleteWorkoutTitle.
  ///
  /// In it, this message translates to:
  /// **'Elimina Scheda'**
  String get deleteWorkoutTitle;

  /// No description provided for @reviewPreferences.
  ///
  /// In it, this message translates to:
  /// **'Rivedi Preferenze'**
  String get reviewPreferences;

  /// No description provided for @edit.
  ///
  /// In it, this message translates to:
  /// **'Modifica'**
  String get edit;

  /// No description provided for @workoutCompleted.
  ///
  /// In it, this message translates to:
  /// **'Workout Completato! 🎉'**
  String get workoutCompleted;

  /// No description provided for @greatJobKeepItUp.
  ///
  /// In it, this message translates to:
  /// **'Ottimo lavoro! Continua così.'**
  String get greatJobKeepItUp;

  /// No description provided for @greatJob.
  ///
  /// In it, this message translates to:
  /// **'Ottimo Lavoro!'**
  String get greatJob;

  /// No description provided for @completedFirstWorkout.
  ///
  /// In it, this message translates to:
  /// **'Hai completato il tuo primo allenamento'**
  String get completedFirstWorkout;

  /// No description provided for @didYouLikeGigi.
  ///
  /// In it, this message translates to:
  /// **'Ti è piaciuto Gigi?'**
  String get didYouLikeGigi;

  /// No description provided for @workoutSession.
  ///
  /// In it, this message translates to:
  /// **'Sessione Allenamento'**
  String get workoutSession;

  /// No description provided for @volume.
  ///
  /// In it, this message translates to:
  /// **'Volume'**
  String get volume;

  /// No description provided for @cancelButton.
  ///
  /// In it, this message translates to:
  /// **'Annulla'**
  String get cancelButton;

  /// No description provided for @deleteButton.
  ///
  /// In it, this message translates to:
  /// **'Elimina'**
  String get deleteButton;

  /// No description provided for @searchExercisesHint.
  ///
  /// In it, this message translates to:
  /// **'Cerca esercizi...'**
  String get searchExercisesHint;

  /// No description provided for @searchWorkoutsHint.
  ///
  /// In it, this message translates to:
  /// **'Cerca scheda, esercizi...'**
  String get searchWorkoutsHint;

  /// No description provided for @ingredientsHint.
  ///
  /// In it, this message translates to:
  /// **'Es. pollo, riso, broccoli...'**
  String get ingredientsHint;

  /// No description provided for @exerciseHint.
  ///
  /// In it, this message translates to:
  /// **'es. Squat, Panca piana, Stacco...'**
  String get exerciseHint;

  /// No description provided for @paywallTitle.
  ///
  /// In it, this message translates to:
  /// **'Scegli il Piano'**
  String get paywallTitle;

  /// No description provided for @paywallSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Allenati Sempre Con Un Coach'**
  String get paywallSubtitle;

  /// No description provided for @paywallDescription.
  ///
  /// In it, this message translates to:
  /// **'GIGI ti parla mentre ti alleni e ti corregge come un PT vero.'**
  String get paywallDescription;

  /// No description provided for @paywallPsychologicalFull.
  ///
  /// In it, this message translates to:
  /// **'Hai provato il coaching reale. Immagina ogni allenamento così.'**
  String get paywallPsychologicalFull;

  /// No description provided for @paywallUrgencyText.
  ///
  /// In it, this message translates to:
  /// **'Offerta valida ancora per'**
  String get paywallUrgencyText;

  /// No description provided for @paywallSocialProofUsers.
  ///
  /// In it, this message translates to:
  /// **'12,847 utenti'**
  String get paywallSocialProofUsers;

  /// No description provided for @paywallSocialProofAction.
  ///
  /// In it, this message translates to:
  /// **'sono passati a Pro questo mese'**
  String get paywallSocialProofAction;

  /// No description provided for @paywallBillingMonthly.
  ///
  /// In it, this message translates to:
  /// **'Mensile'**
  String get paywallBillingMonthly;

  /// No description provided for @paywallBillingYearly.
  ///
  /// In it, this message translates to:
  /// **'Annuale'**
  String get paywallBillingYearly;

  /// No description provided for @paywallDiscount.
  ///
  /// In it, this message translates to:
  /// **'-37%'**
  String get paywallDiscount;

  /// No description provided for @paywallSubscribeButtonYearly.
  ///
  /// In it, this message translates to:
  /// **'Abbonati - {price}€/anno'**
  String paywallSubscribeButtonYearly(Object price);

  /// No description provided for @paywallSubscribeButtonMonthly.
  ///
  /// In it, this message translates to:
  /// **'Abbonati - {price}€/mese'**
  String paywallSubscribeButtonMonthly(Object price);

  /// No description provided for @paywallCurrentPlan.
  ///
  /// In it, this message translates to:
  /// **'Piano Attuale'**
  String get paywallCurrentPlan;

  /// No description provided for @paywallGuarantee.
  ///
  /// In it, this message translates to:
  /// **'7 giorni di prova gratuita'**
  String get paywallGuarantee;

  /// No description provided for @paywallTerms.
  ///
  /// In it, this message translates to:
  /// **'Abbonandoti accetti i nostri Termini di Servizio e Privacy Policy. L\'abbonamento si rinnova automaticamente. Puoi cancellare in qualsiasi momento.'**
  String get paywallTerms;

  /// No description provided for @paywallActivateTitle.
  ///
  /// In it, this message translates to:
  /// **'Attiva {planName}'**
  String paywallActivateTitle(Object planName);

  /// No description provided for @paywallActivateDesc.
  ///
  /// In it, this message translates to:
  /// **'Stai per attivare il piano {planName} a €{price}/{period}.'**
  String paywallActivateDesc(Object period, Object planName, Object price);

  /// No description provided for @paywallRevenueCatWarning.
  ///
  /// In it, this message translates to:
  /// **'RevenueCat non configurato'**
  String get paywallRevenueCatWarning;

  /// No description provided for @paywallRevenueCatDesc.
  ///
  /// In it, this message translates to:
  /// **'Configura RevenueCat per abilitare i pagamenti reali.'**
  String get paywallRevenueCatDesc;

  /// No description provided for @privacyPolicyTitle.
  ///
  /// In it, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyTitle;

  /// No description provided for @privacyPolicySubtitle.
  ///
  /// In it, this message translates to:
  /// **'La tua privacy è importante per noi'**
  String get privacyPolicySubtitle;

  /// No description provided for @termsOfServiceTitle.
  ///
  /// In it, this message translates to:
  /// **'Termini di Servizio'**
  String get termsOfServiceTitle;

  /// No description provided for @termsOfServiceSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Condizioni d\'uso del servizio GIGI'**
  String get termsOfServiceSubtitle;

  /// No description provided for @mealBreakfast.
  ///
  /// In it, this message translates to:
  /// **'Colazione'**
  String get mealBreakfast;

  /// No description provided for @mealLunch.
  ///
  /// In it, this message translates to:
  /// **'Pranzo'**
  String get mealLunch;

  /// No description provided for @mealDinner.
  ///
  /// In it, this message translates to:
  /// **'Cena'**
  String get mealDinner;

  /// No description provided for @mealSnack.
  ///
  /// In it, this message translates to:
  /// **'Snack'**
  String get mealSnack;

  /// No description provided for @mealPreWorkout.
  ///
  /// In it, this message translates to:
  /// **'Pre-Workout'**
  String get mealPreWorkout;

  /// No description provided for @mealPostWorkout.
  ///
  /// In it, this message translates to:
  /// **'Post-Workout'**
  String get mealPostWorkout;

  /// No description provided for @categoryAll.
  ///
  /// In it, this message translates to:
  /// **'Tutti'**
  String get categoryAll;

  /// No description provided for @categoryStrength.
  ///
  /// In it, this message translates to:
  /// **'Forza'**
  String get categoryStrength;

  /// No description provided for @categoryCardio.
  ///
  /// In it, this message translates to:
  /// **'Cardio'**
  String get categoryCardio;

  /// No description provided for @categoryMobility.
  ///
  /// In it, this message translates to:
  /// **'Mobilità'**
  String get categoryMobility;

  /// No description provided for @challengesTitle.
  ///
  /// In it, this message translates to:
  /// **'Sfide'**
  String get challengesTitle;

  /// No description provided for @challengesTabActive.
  ///
  /// In it, this message translates to:
  /// **'Attive'**
  String get challengesTabActive;

  /// No description provided for @challengesTabDaily.
  ///
  /// In it, this message translates to:
  /// **'Giornaliere'**
  String get challengesTabDaily;

  /// No description provided for @challengesTabWeekly.
  ///
  /// In it, this message translates to:
  /// **'Settimanali'**
  String get challengesTabWeekly;

  /// No description provided for @challengesTabCommunity.
  ///
  /// In it, this message translates to:
  /// **'Community'**
  String get challengesTabCommunity;

  /// No description provided for @challengesActiveTitle.
  ///
  /// In it, this message translates to:
  /// **'Le tue sfide attive'**
  String get challengesActiveTitle;

  /// No description provided for @progressTitle.
  ///
  /// In it, this message translates to:
  /// **'I Miei Progressi'**
  String get progressTitle;

  /// No description provided for @progressStatsTitle.
  ///
  /// In it, this message translates to:
  /// **'Statistiche Allenamenti'**
  String get progressStatsTitle;

  /// No description provided for @progressWorkouts.
  ///
  /// In it, this message translates to:
  /// **'Allenamenti'**
  String get progressWorkouts;

  /// No description provided for @progressTotalSets.
  ///
  /// In it, this message translates to:
  /// **'Serie totali'**
  String get progressTotalSets;

  /// No description provided for @progressCalories.
  ///
  /// In it, this message translates to:
  /// **'Calorie bruciate'**
  String get progressCalories;

  /// No description provided for @progressTotalTime.
  ///
  /// In it, this message translates to:
  /// **'Tempo totale'**
  String get progressTotalTime;

  /// No description provided for @progressBodyMapTitle.
  ///
  /// In it, this message translates to:
  /// **'Mappa Corporea'**
  String get progressBodyMapTitle;

  /// No description provided for @progressBodyMapHint.
  ///
  /// In it, this message translates to:
  /// **'Tocca una zona per vedere i dettagli'**
  String get progressBodyMapHint;

  /// No description provided for @progressChangesTitle.
  ///
  /// In it, this message translates to:
  /// **'Cambiamenti'**
  String get progressChangesTitle;

  /// No description provided for @progressTrendTitle.
  ///
  /// In it, this message translates to:
  /// **'Trend Misure'**
  String get progressTrendTitle;

  /// No description provided for @progressAddMoreData.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi più misure per vedere il trend'**
  String get progressAddMoreData;

  /// No description provided for @progressGoalsTitle.
  ///
  /// In it, this message translates to:
  /// **'Obiettivi'**
  String get progressGoalsTitle;

  /// No description provided for @progressSetGoal.
  ///
  /// In it, this message translates to:
  /// **'Imposta un obiettivo'**
  String get progressSetGoal;

  /// No description provided for @progressGoalHint.
  ///
  /// In it, this message translates to:
  /// **'Es. Vita a 80cm o Bicipite a 40cm'**
  String get progressGoalHint;

  /// No description provided for @weeks.
  ///
  /// In it, this message translates to:
  /// **'settimane'**
  String get weeks;

  /// No description provided for @measurements.
  ///
  /// In it, this message translates to:
  /// **'misurazioni'**
  String get measurements;

  /// No description provided for @lastMeasurement.
  ///
  /// In it, this message translates to:
  /// **'ultima'**
  String get lastMeasurement;

  /// No description provided for @xpBonus.
  ///
  /// In it, this message translates to:
  /// **'XP BONUS'**
  String get xpBonus;

  /// No description provided for @nextBonus.
  ///
  /// In it, this message translates to:
  /// **'Prossimo bonus: {multiplier} XP'**
  String nextBonus(Object multiplier);

  /// No description provided for @freezeTokens.
  ///
  /// In it, this message translates to:
  /// **'Freeze Token'**
  String get freezeTokens;

  /// No description provided for @use.
  ///
  /// In it, this message translates to:
  /// **'Usa'**
  String get use;

  /// No description provided for @streakRisk.
  ///
  /// In it, this message translates to:
  /// **'La tua streak è a rischio! Allenati oggi per mantenerla.'**
  String get streakRisk;

  /// No description provided for @peopleWorkingOut.
  ///
  /// In it, this message translates to:
  /// **'persone si stanno allenando ora'**
  String get peopleWorkingOut;

  /// No description provided for @workoutsCompleted.
  ///
  /// In it, this message translates to:
  /// **'workout completati oggi'**
  String get workoutsCompleted;

  /// No description provided for @chestLabel.
  ///
  /// In it, this message translates to:
  /// **'CHEST'**
  String get chestLabel;

  /// No description provided for @openChest.
  ///
  /// In it, this message translates to:
  /// **'Apri Chest'**
  String get openChest;

  /// No description provided for @challengeDaily.
  ///
  /// In it, this message translates to:
  /// **'DAILY'**
  String get challengeDaily;

  /// No description provided for @challengeWeekly.
  ///
  /// In it, this message translates to:
  /// **'WEEKLY'**
  String get challengeWeekly;

  /// No description provided for @challengeMonthly.
  ///
  /// In it, this message translates to:
  /// **'MONTHLY'**
  String get challengeMonthly;

  /// No description provided for @challengeCommunity.
  ///
  /// In it, this message translates to:
  /// **'COMMUNITY'**
  String get challengeCommunity;

  /// No description provided for @challengeOneVsOne.
  ///
  /// In it, this message translates to:
  /// **'1v1'**
  String get challengeOneVsOne;

  /// No description provided for @injuryAreaNeck.
  ///
  /// In it, this message translates to:
  /// **'Collo'**
  String get injuryAreaNeck;

  /// No description provided for @injuryAreaTrapezius.
  ///
  /// In it, this message translates to:
  /// **'Trapezio'**
  String get injuryAreaTrapezius;

  /// No description provided for @injuryAreaDeltoids.
  ///
  /// In it, this message translates to:
  /// **'Deltoidi'**
  String get injuryAreaDeltoids;

  /// No description provided for @injuryAreaPectorals.
  ///
  /// In it, this message translates to:
  /// **'Pettorali'**
  String get injuryAreaPectorals;

  /// No description provided for @injuryAreaBiceps.
  ///
  /// In it, this message translates to:
  /// **'Bicipiti'**
  String get injuryAreaBiceps;

  /// No description provided for @injuryAreaTriceps.
  ///
  /// In it, this message translates to:
  /// **'Tricipiti'**
  String get injuryAreaTriceps;

  /// No description provided for @injuryAreaForearms.
  ///
  /// In it, this message translates to:
  /// **'Avambracci'**
  String get injuryAreaForearms;

  /// No description provided for @injuryAreaAbs.
  ///
  /// In it, this message translates to:
  /// **'Addominali'**
  String get injuryAreaAbs;

  /// No description provided for @injuryAreaObliques.
  ///
  /// In it, this message translates to:
  /// **'Obliqui'**
  String get injuryAreaObliques;

  /// No description provided for @injuryAreaLowerBack.
  ///
  /// In it, this message translates to:
  /// **'Zona Lombare'**
  String get injuryAreaLowerBack;

  /// No description provided for @injuryAreaUpperBack.
  ///
  /// In it, this message translates to:
  /// **'Parte Alta Schiena'**
  String get injuryAreaUpperBack;

  /// No description provided for @injuryAreaLats.
  ///
  /// In it, this message translates to:
  /// **'Dorsali'**
  String get injuryAreaLats;

  /// No description provided for @injuryAreaGlutes.
  ///
  /// In it, this message translates to:
  /// **'Glutei'**
  String get injuryAreaGlutes;

  /// No description provided for @injuryAreaHipFlexors.
  ///
  /// In it, this message translates to:
  /// **'Flessori Anca'**
  String get injuryAreaHipFlexors;

  /// No description provided for @injuryAreaQuadriceps.
  ///
  /// In it, this message translates to:
  /// **'Quadricipiti'**
  String get injuryAreaQuadriceps;

  /// No description provided for @injuryAreaHamstrings.
  ///
  /// In it, this message translates to:
  /// **'Femorali'**
  String get injuryAreaHamstrings;

  /// No description provided for @injuryAreaCalves.
  ///
  /// In it, this message translates to:
  /// **'Polpacci'**
  String get injuryAreaCalves;

  /// No description provided for @injuryAreaAdductors.
  ///
  /// In it, this message translates to:
  /// **'Adduttori'**
  String get injuryAreaAdductors;

  /// No description provided for @injuryAreaAbductors.
  ///
  /// In it, this message translates to:
  /// **'Abduttori'**
  String get injuryAreaAbductors;

  /// No description provided for @injuryAreaRotatorCuff.
  ///
  /// In it, this message translates to:
  /// **'Cuffia Rotatori'**
  String get injuryAreaRotatorCuff;

  /// No description provided for @injuryAreaCervicalSpine.
  ///
  /// In it, this message translates to:
  /// **'Colonna Cervicale'**
  String get injuryAreaCervicalSpine;

  /// No description provided for @injuryAreaShoulder.
  ///
  /// In it, this message translates to:
  /// **'Spalla'**
  String get injuryAreaShoulder;

  /// No description provided for @injuryAreaElbow.
  ///
  /// In it, this message translates to:
  /// **'Gomito'**
  String get injuryAreaElbow;

  /// No description provided for @injuryAreaWrist.
  ///
  /// In it, this message translates to:
  /// **'Polso'**
  String get injuryAreaWrist;

  /// No description provided for @injuryAreaFingers.
  ///
  /// In it, this message translates to:
  /// **'Dita Mano'**
  String get injuryAreaFingers;

  /// No description provided for @injuryAreaThoracicSpine.
  ///
  /// In it, this message translates to:
  /// **'Colonna Toracica'**
  String get injuryAreaThoracicSpine;

  /// No description provided for @injuryAreaLumbarSpine.
  ///
  /// In it, this message translates to:
  /// **'Colonna Lombare'**
  String get injuryAreaLumbarSpine;

  /// No description provided for @injuryAreaHip.
  ///
  /// In it, this message translates to:
  /// **'Anca'**
  String get injuryAreaHip;

  /// No description provided for @injuryAreaKnee.
  ///
  /// In it, this message translates to:
  /// **'Ginocchio'**
  String get injuryAreaKnee;

  /// No description provided for @injuryAreaAnkle.
  ///
  /// In it, this message translates to:
  /// **'Caviglia'**
  String get injuryAreaAnkle;

  /// No description provided for @injuryAreaToes.
  ///
  /// In it, this message translates to:
  /// **'Dita Piede'**
  String get injuryAreaToes;

  /// No description provided for @injuryAreaSacroiliac.
  ///
  /// In it, this message translates to:
  /// **'Sacroiliac'**
  String get injuryAreaSacroiliac;

  /// No description provided for @injuryAreaTemporomandibular.
  ///
  /// In it, this message translates to:
  /// **'Temporo-Mandibolare'**
  String get injuryAreaTemporomandibular;

  /// No description provided for @injuryAreaSkull.
  ///
  /// In it, this message translates to:
  /// **'Cranio'**
  String get injuryAreaSkull;

  /// No description provided for @injuryAreaClavicle.
  ///
  /// In it, this message translates to:
  /// **'Clavicola'**
  String get injuryAreaClavicle;

  /// No description provided for @injuryAreaScapula.
  ///
  /// In it, this message translates to:
  /// **'Scapola'**
  String get injuryAreaScapula;

  /// No description provided for @injuryAreaRibs.
  ///
  /// In it, this message translates to:
  /// **'Costole'**
  String get injuryAreaRibs;

  /// No description provided for @injuryAreaSternum.
  ///
  /// In it, this message translates to:
  /// **'Sterno'**
  String get injuryAreaSternum;

  /// No description provided for @injuryAreaHumerus.
  ///
  /// In it, this message translates to:
  /// **'Omero'**
  String get injuryAreaHumerus;

  /// No description provided for @injuryAreaRadius.
  ///
  /// In it, this message translates to:
  /// **'Radio'**
  String get injuryAreaRadius;

  /// No description provided for @injuryAreaUlna.
  ///
  /// In it, this message translates to:
  /// **'Ulna'**
  String get injuryAreaUlna;

  /// No description provided for @injuryAreaCarpals.
  ///
  /// In it, this message translates to:
  /// **'Carpo'**
  String get injuryAreaCarpals;

  /// No description provided for @injuryAreaMetacarpals.
  ///
  /// In it, this message translates to:
  /// **'Metacarpo'**
  String get injuryAreaMetacarpals;

  /// No description provided for @injuryAreaPhalangesHand.
  ///
  /// In it, this message translates to:
  /// **'Falangi Mano'**
  String get injuryAreaPhalangesHand;

  /// No description provided for @injuryAreaVertebrae.
  ///
  /// In it, this message translates to:
  /// **'Vertebre'**
  String get injuryAreaVertebrae;

  /// No description provided for @injuryAreaPelvis.
  ///
  /// In it, this message translates to:
  /// **'Bacino'**
  String get injuryAreaPelvis;

  /// No description provided for @injuryAreaFemur.
  ///
  /// In it, this message translates to:
  /// **'Femore'**
  String get injuryAreaFemur;

  /// No description provided for @injuryAreaPatella.
  ///
  /// In it, this message translates to:
  /// **'Rotula'**
  String get injuryAreaPatella;

  /// No description provided for @injuryAreaTibia.
  ///
  /// In it, this message translates to:
  /// **'Tibia'**
  String get injuryAreaTibia;

  /// No description provided for @injuryAreaFibula.
  ///
  /// In it, this message translates to:
  /// **'Perone'**
  String get injuryAreaFibula;

  /// No description provided for @injuryAreaTarsals.
  ///
  /// In it, this message translates to:
  /// **'Tarso'**
  String get injuryAreaTarsals;

  /// No description provided for @injuryAreaMetatarsals.
  ///
  /// In it, this message translates to:
  /// **'Metatarso'**
  String get injuryAreaMetatarsals;

  /// No description provided for @injuryAreaPhalangesFoot.
  ///
  /// In it, this message translates to:
  /// **'Falangi Piede'**
  String get injuryAreaPhalangesFoot;

  /// No description provided for @injurySeverityMild.
  ///
  /// In it, this message translates to:
  /// **'Lieve'**
  String get injurySeverityMild;

  /// No description provided for @injurySeverityModerate.
  ///
  /// In it, this message translates to:
  /// **'Moderato'**
  String get injurySeverityModerate;

  /// No description provided for @injurySeveritySevere.
  ///
  /// In it, this message translates to:
  /// **'Grave'**
  String get injurySeveritySevere;

  /// No description provided for @injuryTimingCurrent.
  ///
  /// In it, this message translates to:
  /// **'Attuale'**
  String get injuryTimingCurrent;

  /// No description provided for @injuryTimingPast.
  ///
  /// In it, this message translates to:
  /// **'Passato'**
  String get injuryTimingPast;

  /// No description provided for @injuryStatusRecovering.
  ///
  /// In it, this message translates to:
  /// **'In Recupero'**
  String get injuryStatusRecovering;

  /// No description provided for @injuryStatusResolved.
  ///
  /// In it, this message translates to:
  /// **'Risolto'**
  String get injuryStatusResolved;

  /// No description provided for @scanMealWithAi.
  ///
  /// In it, this message translates to:
  /// **'Scansiona Pasto con AI'**
  String get scanMealWithAi;

  /// No description provided for @takePhotoForAnalysis.
  ///
  /// In it, this message translates to:
  /// **'Scatta una foto per analisi automatica'**
  String get takePhotoForAnalysis;

  /// No description provided for @nextReward.
  ///
  /// In it, this message translates to:
  /// **'Prossimo premio'**
  String get nextReward;

  /// No description provided for @minimalClothingDesc.
  ///
  /// In it, this message translates to:
  /// **'Così vedi i cambiamenti'**
  String get minimalClothingDesc;

  /// No description provided for @neutralPositionDesc.
  ///
  /// In it, this message translates to:
  /// **'Rilassato, braccia lungo i fianchi'**
  String get neutralPositionDesc;

  /// No description provided for @sameSpotDesc.
  ///
  /// In it, this message translates to:
  /// **'Sfondo neutro, stessa distanza'**
  String get sameSpotDesc;

  /// No description provided for @notSpecified.
  ///
  /// In it, this message translates to:
  /// **'Non specificato'**
  String get notSpecified;

  /// No description provided for @whereToMeasureDesc.
  ///
  /// In it, this message translates to:
  /// **'Nel punto più spesso del muscolo'**
  String get whereToMeasureDesc;

  /// No description provided for @homeWorkout.
  ///
  /// In it, this message translates to:
  /// **'Allenamento domestico'**
  String get homeWorkout;

  /// No description provided for @maybeLater.
  ///
  /// In it, this message translates to:
  /// **'Magari dopo'**
  String get maybeLater;

  /// No description provided for @averageSleep.
  ///
  /// In it, this message translates to:
  /// **'Sonno medio'**
  String get averageSleep;

  /// No description provided for @totalSteps.
  ///
  /// In it, this message translates to:
  /// **'Passi totali'**
  String get totalSteps;

  /// No description provided for @startHere.
  ///
  /// In it, this message translates to:
  /// **'Inizia qui'**
  String get startHere;

  /// No description provided for @yourWorkout.
  ///
  /// In it, this message translates to:
  /// **'Il tuo allenamento'**
  String get yourWorkout;

  /// No description provided for @recommendedPrograms.
  ///
  /// In it, this message translates to:
  /// **'Programmi consigliati'**
  String get recommendedPrograms;

  /// No description provided for @completeNow.
  ///
  /// In it, this message translates to:
  /// **'Completa ora'**
  String get completeNow;

  /// No description provided for @seeMore.
  ///
  /// In it, this message translates to:
  /// **'Vedi altro'**
  String get seeMore;

  /// No description provided for @burnedCalories.
  ///
  /// In it, this message translates to:
  /// **'Calorie bruciate'**
  String get burnedCalories;

  /// No description provided for @totalTime.
  ///
  /// In it, this message translates to:
  /// **'Tempo totale'**
  String get totalTime;

  /// No description provided for @completedWorkouts.
  ///
  /// In it, this message translates to:
  /// **'Workout completati'**
  String get completedWorkouts;

  /// No description provided for @earnedBadges.
  ///
  /// In it, this message translates to:
  /// **'Badge guadagnati'**
  String get earnedBadges;

  /// No description provided for @analysisFailed.
  ///
  /// In it, this message translates to:
  /// **'Analisi fallita'**
  String get analysisFailed;

  /// No description provided for @unlimitedAnalyses.
  ///
  /// In it, this message translates to:
  /// **'Analisi illimitate'**
  String get unlimitedAnalyses;

  /// No description provided for @selectedVideo.
  ///
  /// In it, this message translates to:
  /// **'Video selezionato'**
  String get selectedVideo;

  /// No description provided for @howItWorks.
  ///
  /// In it, this message translates to:
  /// **'Come funziona'**
  String get howItWorks;

  /// No description provided for @progressPhotos.
  ///
  /// In it, this message translates to:
  /// **'Foto Progresso'**
  String get progressPhotos;

  /// No description provided for @yourPhotos.
  ///
  /// In it, this message translates to:
  /// **'Le tue foto'**
  String get yourPhotos;

  /// No description provided for @journeyPhotos.
  ///
  /// In it, this message translates to:
  /// **'Foto del Tuo Percorso'**
  String get journeyPhotos;

  /// No description provided for @visiblyCompare.
  ///
  /// In it, this message translates to:
  /// **'Tra qualche settimana potrai confrontare i tuoi progressi visivamente. È il modo più motivante per vedere i risultati!'**
  String get visiblyCompare;

  /// No description provided for @privateAssurance.
  ///
  /// In it, this message translates to:
  /// **'100% Private'**
  String get privateAssurance;

  /// No description provided for @privateDesc.
  ///
  /// In it, this message translates to:
  /// **'Le tue foto saranno visibili SOLO a te. Non vengono mai condivise o usate per altri scopi.'**
  String get privateDesc;

  /// No description provided for @perfectPhotoTitle.
  ///
  /// In it, this message translates to:
  /// **'Come scattare foto perfette'**
  String get perfectPhotoTitle;

  /// No description provided for @saving.
  ///
  /// In it, this message translates to:
  /// **'Salvataggio...'**
  String get saving;

  /// No description provided for @savePhoto.
  ///
  /// In it, this message translates to:
  /// **'Salva Foto'**
  String get savePhoto;

  /// No description provided for @skipForNow.
  ///
  /// In it, this message translates to:
  /// **'Salta per ora'**
  String get skipForNow;

  /// No description provided for @motivationDesc.
  ///
  /// In it, this message translates to:
  /// **'Tra 4-8 settimane potrai vedere i cambiamenti confrontando le foto!'**
  String get motivationDesc;

  /// No description provided for @howToTakeMeasurements.
  ///
  /// In it, this message translates to:
  /// **'Come prendere le misure'**
  String get howToTakeMeasurements;

  /// No description provided for @followTips.
  ///
  /// In it, this message translates to:
  /// **'Segui questi consigli per misure accurate'**
  String get followTips;

  /// No description provided for @morningsFasting.
  ///
  /// In it, this message translates to:
  /// **'Preferibilmente al mattino, a digiuno'**
  String get morningsFasting;

  /// No description provided for @flexibleTape.
  ///
  /// In it, this message translates to:
  /// **'Usa un metro da sarto flessibile'**
  String get flexibleTape;

  /// No description provided for @repeatTwice.
  ///
  /// In it, this message translates to:
  /// **'Ripeti ogni misura 2 volte'**
  String get repeatTwice;

  /// No description provided for @relaxNoContracting.
  ///
  /// In it, this message translates to:
  /// **'Rilassati, non contrarre'**
  String get relaxNoContracting;

  /// No description provided for @position.
  ///
  /// In it, this message translates to:
  /// **'Posizione'**
  String get position;

  /// No description provided for @bicepPositionDesc.
  ///
  /// In it, this message translates to:
  /// **'Braccio flesso a 90°, pugno chiuso'**
  String get bicepPositionDesc;

  /// No description provided for @slightlyDifferent.
  ///
  /// In it, this message translates to:
  /// **'Potrebbero essere leggermente diversi'**
  String get slightlyDifferent;

  /// No description provided for @torsoParts.
  ///
  /// In it, this message translates to:
  /// **'Petto, vita e fianchi'**
  String get torsoParts;

  /// No description provided for @chest.
  ///
  /// In it, this message translates to:
  /// **'Petto'**
  String get chest;

  /// No description provided for @chestDesc.
  ///
  /// In it, this message translates to:
  /// **'Metro sotto le ascelle, sul punto più sporgente'**
  String get chestDesc;

  /// No description provided for @waist.
  ///
  /// In it, this message translates to:
  /// **'Vita'**
  String get waist;

  /// No description provided for @waistDesc.
  ///
  /// In it, this message translates to:
  /// **'All\'altezza dell\'ombelico, posizione naturale'**
  String get waistDesc;

  /// No description provided for @hips.
  ///
  /// In it, this message translates to:
  /// **'Fianchi'**
  String get hips;

  /// No description provided for @hipsDesc.
  ///
  /// In it, this message translates to:
  /// **'Nel punto più largo dei glutei'**
  String get hipsDesc;

  /// No description provided for @legsParts.
  ///
  /// In it, this message translates to:
  /// **'Cosce e polpacci'**
  String get legsParts;

  /// No description provided for @thighDesc.
  ///
  /// In it, this message translates to:
  /// **'A metà tra inguine e ginocchio, gamba rilassata'**
  String get thighDesc;

  /// No description provided for @calfDesc.
  ///
  /// In it, this message translates to:
  /// **'Nel punto più largo, in piedi'**
  String get calfDesc;

  /// No description provided for @bodyMeasurements.
  ///
  /// In it, this message translates to:
  /// **'Misure Corporee'**
  String get bodyMeasurements;

  /// No description provided for @yourStartingPoint.
  ///
  /// In it, this message translates to:
  /// **'Il Tuo Punto di Partenza'**
  String get yourStartingPoint;

  /// No description provided for @measurementsHelpDesc.
  ///
  /// In it, this message translates to:
  /// **'Queste misure ci aiutano a creare la scheda perfetta per te e a tracciare i tuoi progressi nel tempo.'**
  String get measurementsHelpDesc;

  /// No description provided for @startingMeasurementsDesc.
  ///
  /// In it, this message translates to:
  /// **'Ecco le tue misure di partenza'**
  String get startingMeasurementsDesc;

  /// No description provided for @updateWeeklyDesc.
  ///
  /// In it, this message translates to:
  /// **'Potrai aggiornare le misure ogni settimana per vedere i progressi!'**
  String get updateWeeklyDesc;

  /// No description provided for @saveAndContinue.
  ///
  /// In it, this message translates to:
  /// **'Salva e Continua'**
  String get saveAndContinue;

  /// No description provided for @editPreferences.
  ///
  /// In it, this message translates to:
  /// **'Modifica Preferenze'**
  String get editPreferences;

  /// No description provided for @reviewPreferencesDesc.
  ///
  /// In it, this message translates to:
  /// **'Rivedi le tue preferenze prima di generare il piano. Puoi modificarle se necessario.'**
  String get reviewPreferencesDesc;

  /// No description provided for @height.
  ///
  /// In it, this message translates to:
  /// **'Altezza'**
  String get height;

  /// No description provided for @age.
  ///
  /// In it, this message translates to:
  /// **'Età'**
  String get age;

  /// No description provided for @gender.
  ///
  /// In it, this message translates to:
  /// **'Genere'**
  String get gender;

  /// No description provided for @bodyShape.
  ///
  /// In it, this message translates to:
  /// **'Forma Fisica'**
  String get bodyShape;

  /// No description provided for @trainingGoals.
  ///
  /// In it, this message translates to:
  /// **'Obiettivi di Allenamento'**
  String get trainingGoals;

  /// No description provided for @experienceLevel.
  ///
  /// In it, this message translates to:
  /// **'Livello di Esperienza'**
  String get experienceLevel;

  /// No description provided for @weeklyFrequency.
  ///
  /// In it, this message translates to:
  /// **'Frequenza Settimanale'**
  String get weeklyFrequency;

  /// No description provided for @daysPerWeek.
  ///
  /// In it, this message translates to:
  /// **'giorni/settimana'**
  String get daysPerWeek;

  /// No description provided for @trainingLocation.
  ///
  /// In it, this message translates to:
  /// **'Luogo di Allenamento'**
  String get trainingLocation;

  /// No description provided for @whereDoYouTrain.
  ///
  /// In it, this message translates to:
  /// **'Dove ti alleni?'**
  String get whereDoYouTrain;

  /// No description provided for @availableEquipment.
  ///
  /// In it, this message translates to:
  /// **'Attrezzatura Disponibile'**
  String get availableEquipment;

  /// No description provided for @trainingPreferences.
  ///
  /// In it, this message translates to:
  /// **'Preferenze di Allenamento'**
  String get trainingPreferences;

  /// No description provided for @workoutType.
  ///
  /// In it, this message translates to:
  /// **'Tipo di Allenamento'**
  String get workoutType;

  /// No description provided for @trainingSplit.
  ///
  /// In it, this message translates to:
  /// **'Split di Allenamento'**
  String get trainingSplit;

  /// No description provided for @sessionDuration.
  ///
  /// In it, this message translates to:
  /// **'Durata Sessione'**
  String get sessionDuration;

  /// No description provided for @cardioPreference.
  ///
  /// In it, this message translates to:
  /// **'Preferenza Cardio'**
  String get cardioPreference;

  /// No description provided for @mobilityPreference.
  ///
  /// In it, this message translates to:
  /// **'Preferenza Mobilità'**
  String get mobilityPreference;

  /// No description provided for @generatePlanWithPrefs.
  ///
  /// In it, this message translates to:
  /// **'Genera Piano con Queste Preferenze'**
  String get generatePlanWithPrefs;

  /// No description provided for @savePreferences.
  ///
  /// In it, this message translates to:
  /// **'Salva Preferenze'**
  String get savePreferences;

  /// No description provided for @preferencesSavedSuccess.
  ///
  /// In it, this message translates to:
  /// **'Preferenze salvate con successo'**
  String get preferencesSavedSuccess;

  /// No description provided for @errorSavingPreferences.
  ///
  /// In it, this message translates to:
  /// **'Errore durante il salvataggio'**
  String get errorSavingPreferences;

  /// No description provided for @unspecified.
  ///
  /// In it, this message translates to:
  /// **'Non specificato'**
  String get unspecified;

  /// No description provided for @male.
  ///
  /// In it, this message translates to:
  /// **'Maschio'**
  String get male;

  /// No description provided for @female.
  ///
  /// In it, this message translates to:
  /// **'Femmina'**
  String get female;

  /// No description provided for @verySkinny.
  ///
  /// In it, this message translates to:
  /// **'Molto Magro'**
  String get verySkinny;

  /// No description provided for @skinny.
  ///
  /// In it, this message translates to:
  /// **'Magro'**
  String get skinny;

  /// No description provided for @lean.
  ///
  /// In it, this message translates to:
  /// **'Snello'**
  String get lean;

  /// No description provided for @athletic.
  ///
  /// In it, this message translates to:
  /// **'Atletico'**
  String get athletic;

  /// No description provided for @muscular.
  ///
  /// In it, this message translates to:
  /// **'Muscoloso'**
  String get muscular;

  /// No description provided for @overweight.
  ///
  /// In it, this message translates to:
  /// **'Sovrappeso'**
  String get overweight;

  /// No description provided for @average.
  ///
  /// In it, this message translates to:
  /// **'Medio'**
  String get average;

  /// No description provided for @muscleGain.
  ///
  /// In it, this message translates to:
  /// **'Aumento Massa Muscolare'**
  String get muscleGain;

  /// No description provided for @weightLoss.
  ///
  /// In it, this message translates to:
  /// **'Perdita di Peso'**
  String get weightLoss;

  /// No description provided for @toning.
  ///
  /// In it, this message translates to:
  /// **'Tonificazione'**
  String get toning;

  /// No description provided for @strength.
  ///
  /// In it, this message translates to:
  /// **'Forza'**
  String get strength;

  /// No description provided for @wellness.
  ///
  /// In it, this message translates to:
  /// **'Benessere'**
  String get wellness;

  /// No description provided for @beginner.
  ///
  /// In it, this message translates to:
  /// **'Principiante'**
  String get beginner;

  /// No description provided for @intermediate.
  ///
  /// In it, this message translates to:
  /// **'Intermedio'**
  String get intermediate;

  /// No description provided for @advanced.
  ///
  /// In it, this message translates to:
  /// **'Avanzato'**
  String get advanced;

  /// No description provided for @gym.
  ///
  /// In it, this message translates to:
  /// **'Palestra'**
  String get gym;

  /// No description provided for @outdoor.
  ///
  /// In it, this message translates to:
  /// **'All\'aperto'**
  String get outdoor;

  /// No description provided for @bench.
  ///
  /// In it, this message translates to:
  /// **'Panca'**
  String get bench;

  /// No description provided for @dumbbells.
  ///
  /// In it, this message translates to:
  /// **'Manubri'**
  String get dumbbells;

  /// No description provided for @barbell.
  ///
  /// In it, this message translates to:
  /// **'Bilanciere'**
  String get barbell;

  /// No description provided for @resistanceBands.
  ///
  /// In it, this message translates to:
  /// **'Bande Elastiche'**
  String get resistanceBands;

  /// No description provided for @machines.
  ///
  /// In it, this message translates to:
  /// **'Macchine'**
  String get machines;

  /// No description provided for @ipertrofia.
  ///
  /// In it, this message translates to:
  /// **'Ipertrofia'**
  String get ipertrofia;

  /// No description provided for @ipertrophy.
  ///
  /// In it, this message translates to:
  /// **'Ipertrofia'**
  String get ipertrophy;

  /// No description provided for @endurance.
  ///
  /// In it, this message translates to:
  /// **'Resistenza'**
  String get endurance;

  /// No description provided for @functional.
  ///
  /// In it, this message translates to:
  /// **'Funzionale'**
  String get functional;

  /// No description provided for @calisthenics.
  ///
  /// In it, this message translates to:
  /// **'Calisthenics'**
  String get calisthenics;

  /// No description provided for @weeklyReport.
  ///
  /// In it, this message translates to:
  /// **'Report Settimanale'**
  String get weeklyReport;

  /// No description provided for @myWeeklyReport.
  ///
  /// In it, this message translates to:
  /// **'Il mio Report Settimanale GIGI'**
  String get myWeeklyReport;

  /// No description provided for @sleep.
  ///
  /// In it, this message translates to:
  /// **'Sonno'**
  String get sleep;

  /// No description provided for @workouts.
  ///
  /// In it, this message translates to:
  /// **'Workout'**
  String get workouts;

  /// No description provided for @heartRate.
  ///
  /// In it, this message translates to:
  /// **'HR'**
  String get heartRate;

  /// No description provided for @perNight.
  ///
  /// In it, this message translates to:
  /// **'/notte'**
  String get perNight;

  /// No description provided for @perDay.
  ///
  /// In it, this message translates to:
  /// **'/giorno'**
  String get perDay;

  /// No description provided for @completed.
  ///
  /// In it, this message translates to:
  /// **'completati'**
  String get completed;

  /// No description provided for @sleepTrend.
  ///
  /// In it, this message translates to:
  /// **'Andamento Sonno'**
  String get sleepTrend;

  /// No description provided for @activity.
  ///
  /// In it, this message translates to:
  /// **'Attività'**
  String get activity;

  /// No description provided for @aiInsights.
  ///
  /// In it, this message translates to:
  /// **'Insights AI'**
  String get aiInsights;

  /// No description provided for @patternDiscovery.
  ///
  /// In it, this message translates to:
  /// **'Pattern Discovery'**
  String get patternDiscovery;

  /// No description provided for @gigiTip.
  ///
  /// In it, this message translates to:
  /// **'Consiglio di Gigi'**
  String get gigiTip;

  /// No description provided for @avgSleep.
  ///
  /// In it, this message translates to:
  /// **'Sonno medio'**
  String get avgSleep;

  /// No description provided for @stepsPerDay.
  ///
  /// In it, this message translates to:
  /// **'Passi/giorno'**
  String get stepsPerDay;

  /// No description provided for @hrBpm.
  ///
  /// In it, this message translates to:
  /// **'HR bpm'**
  String get hrBpm;

  /// No description provided for @weeklyStepGoal.
  ///
  /// In it, this message translates to:
  /// **'Obiettivo: 70.000 passi/settimana'**
  String get weeklyStepGoal;

  /// No description provided for @basedOnDataPoints.
  ///
  /// In it, this message translates to:
  /// **'Basato su {count} giorni di dati'**
  String basedOnDataPoints(int count);

  /// No description provided for @noDataAvailable.
  ///
  /// In it, this message translates to:
  /// **'Nessun dato disponibile'**
  String get noDataAvailable;

  /// No description provided for @aiFormCheck.
  ///
  /// In it, this message translates to:
  /// **'AI Form Check'**
  String get aiFormCheck;

  /// No description provided for @exerciseName.
  ///
  /// In it, this message translates to:
  /// **'Nome Esercizio'**
  String get exerciseName;

  /// No description provided for @recordVideo.
  ///
  /// In it, this message translates to:
  /// **'Registra Video'**
  String get recordVideo;

  /// No description provided for @max15Seconds.
  ///
  /// In it, this message translates to:
  /// **'Max 15 secondi'**
  String get max15Seconds;

  /// No description provided for @uploadFromGallery.
  ///
  /// In it, this message translates to:
  /// **'Carica dalla Galleria'**
  String get uploadFromGallery;

  /// No description provided for @videoSelected.
  ///
  /// In it, this message translates to:
  /// **'Video selezionato'**
  String get videoSelected;

  /// No description provided for @remove.
  ///
  /// In it, this message translates to:
  /// **'Rimuovi'**
  String get remove;

  /// No description provided for @analyzeForm.
  ///
  /// In it, this message translates to:
  /// **'Analizza Esecuzione'**
  String get analyzeForm;

  /// No description provided for @analyzingForm.
  ///
  /// In it, this message translates to:
  /// **'Gigi sta analizzando la tua tecnica...'**
  String get analyzingForm;

  /// No description provided for @loadingProgress.
  ///
  /// In it, this message translates to:
  /// **'Caricamento... {progress}%'**
  String loadingProgress(int progress);

  /// No description provided for @takeTimeDesc.
  ///
  /// In it, this message translates to:
  /// **'Questo può richiedere 30-60 secondi'**
  String get takeTimeDesc;

  /// No description provided for @gigiFormMessage.
  ///
  /// In it, this message translates to:
  /// **'Ciao! Per un risultato perfetto, chiedi a qualcuno di riprenderti di profilo o appoggia il telefono. Assicurati che tutto il corpo sia visibile!'**
  String get gigiFormMessage;

  /// No description provided for @howItWorksStep1.
  ///
  /// In it, this message translates to:
  /// **'Registra o carica un video (max 15 sec)'**
  String get howItWorksStep1;

  /// No description provided for @howItWorksStep2.
  ///
  /// In it, this message translates to:
  /// **'Gigi analizza la tua esecuzione'**
  String get howItWorksStep2;

  /// No description provided for @howItWorksStep3.
  ///
  /// In it, this message translates to:
  /// **'Ricevi feedback su postura ed errori'**
  String get howItWorksStep3;

  /// No description provided for @howItWorksStep4.
  ///
  /// In it, this message translates to:
  /// **'Migliora con suggerimenti personalizzati'**
  String get howItWorksStep4;

  /// No description provided for @dailyAnalyses.
  ///
  /// In it, this message translates to:
  /// **'Analisi Giornaliere'**
  String get dailyAnalyses;

  /// No description provided for @remainingToday.
  ///
  /// In it, this message translates to:
  /// **'{count}/{total} rimaste oggi'**
  String remainingToday(int count, int total);

  /// No description provided for @limitReachedDesc.
  ///
  /// In it, this message translates to:
  /// **'Hai raggiunto il limite giornaliero di {limit} analisi.\n\nUpgrade a Premium per analisi illimitate!'**
  String limitReachedDesc(int limit);

  /// No description provided for @upgrade.
  ///
  /// In it, this message translates to:
  /// **'Upgrade'**
  String get upgrade;

  /// No description provided for @videoTooLarge.
  ///
  /// In it, this message translates to:
  /// **'Video troppo grande! Max 50MB'**
  String get videoTooLarge;

  /// No description provided for @selectVideoAndExercise.
  ///
  /// In it, this message translates to:
  /// **'Seleziona video e inserisci nome esercizio'**
  String get selectVideoAndExercise;

  /// No description provided for @ml.
  ///
  /// In it, this message translates to:
  /// **'ml'**
  String get ml;

  /// No description provided for @glasses.
  ///
  /// In it, this message translates to:
  /// **'bicchieri'**
  String get glasses;

  /// No description provided for @exercise.
  ///
  /// In it, this message translates to:
  /// **'Esercizio'**
  String get exercise;

  /// No description provided for @kcal.
  ///
  /// In it, this message translates to:
  /// **'kcal'**
  String get kcal;

  /// No description provided for @platform.
  ///
  /// In it, this message translates to:
  /// **'Piattaforma'**
  String get platform;

  /// No description provided for @description.
  ///
  /// In it, this message translates to:
  /// **'Descrizione'**
  String get description;

  /// No description provided for @title.
  ///
  /// In it, this message translates to:
  /// **'Titolo'**
  String get title;

  /// No description provided for @current.
  ///
  /// In it, this message translates to:
  /// **'Attuale'**
  String get current;
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
