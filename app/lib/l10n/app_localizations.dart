import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('en'), Locale('it')];

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    _AppLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale(_fallbackLanguageCode));
  }

  static const _fallbackLanguageCode = 'en';

  static const Map<String, Map<String, String>> _strings = {
    'it': {
      'Training Log': 'Diario Allenamenti',
      'Home': 'Home',
      'Splits': 'Schede',
      'Exercises': 'Esercizi',
      'Other': 'Altro',
      'Language': 'Lingua',
      'Choose app language': 'Scegli la lingua dell app',
      'Follow system language': 'Segui la lingua del sistema',
      'English': 'Inglese',
      'Italian': 'Italiano',
      'Choose exercise': 'Scegli esercizio',
      'No exercises match the current filter.':
          'Nessun esercizio corrisponde al filtro corrente.',
      'Search exercises': 'Cerca esercizi',
      'Division': 'Divisione',
      'Muscles': 'Muscoli',
      'Push-pull-legs': 'Spinta-tirata-gambe',
      'Upper-lower': 'Parte alta-parte bassa',
      'Compound-isolation': 'Multiart.-isolamento',
      'All exercises': 'Tutti gli esercizi',
      'ADD EXERCISE': 'AGGIUNGI ESERCIZIO',
      'Ordering': 'Ordinamento',
      'Alphabetic order': 'Ordine alfabetico',
      'Date of creation': 'Data di creazione',
      'Most used': 'Più usati',
      'Ascending': 'Crescente',
      'Descending': 'Decrescente',
      'Visible': 'Visibili',
      'Hidden': 'Nascosti',
      'Hidden exercises': 'Esercizi nascosti',
      'ADD SPLIT': 'AGGIUNGI SCHEDA',
      'Add exercise': 'Aggiungi esercizio',
      'Add set': 'Aggiungi serie',
      'Delete set': 'Elimina serie',
      'Start rest timer': 'Avvia timer recupero',
      'Workout': 'Allenamento',
      'Unsupported workout mode: {mode}':
          'Modalita allenamento non supportata: {mode}',
      'Missing split workout parameters.':
          'Parametri allenamento scheda mancanti.',
      'Split not found.': 'Scheda non trovata.',
      'Workout day not found.': 'Giorno allenamento non trovato.',
      'Failed to load split workout: {error}':
          'Impossibile caricare l allenamento scheda: {error}',
      'Build as you go': 'Costruiscilo mentre ti alleni',
      'Rest {value}': 'Recupero {value}',
      'Delete current log': 'Elimina log corrente',
      'Finish': 'Termina',
      'No exercises yet. Add one to start logging sets.':
          'Nessun esercizio ancora. Aggiungine uno per iniziare a registrare le serie.',
      'No planned exercises for this day.':
          'Nessun esercizio pianificato per questo giorno.',
      'Edit {name}': 'Modifica {name}',
      'Target sets': 'Serie obiettivo',
      'Rep min': 'Rip min',
      'Rep max': 'Rip max',
      'Target RPE': 'RPE obiettivo',
      'Target sets must be greater than zero.':
          'Le serie obiettivo devono essere maggiori di zero.',
      'Rep min must be greater than zero.':
          'Le ripetizioni minime devono essere maggiori di zero.',
      'Rep max cannot be lower than rep min.':
          'Le ripetizioni massime non possono essere inferiori alle minime.',
      'Rest cannot be negative.': 'Il recupero non puo essere negativo.',
      'Target RPE must be between 0 and 10.':
          'L RPE obiettivo deve essere compreso tra 0 e 10.',
      'Delete last set?': 'Eliminare l ultima serie?',
      'The last set is already logged. Do you really want to delete it?':
          'L ultima serie e gia registrata. Vuoi davvero eliminarla?',
      'Workout saved.': 'Allenamento salvato.',
      'Log at least one complete set before finishing.':
          'Registra almeno una serie completa prima di terminare.',
      'Finish workout': 'Termina allenamento',
      '{count} total sets': '{count} serie totali',
      '{count} unfilled sets will not be counted. Save anyway?':
          '{count} serie non compilate non verranno conteggiate. Salvare comunque?',
      'Delete current log?': 'Eliminare il log corrente?',
      'This will clear your in-progress workout. You can start again from Home.':
          'Questo cancellera l allenamento in corso. Potrai ricominciare dalla Home.',
      'In-progress log deleted.': 'Log in corso eliminato.',
      'Swap exercise': 'Sostituisci esercizio',
      'Edit prescription': 'Modifica prescrizione',
      'Remove exercise': 'Rimuovi esercizio',
      '{sets} sets | {repMin}-{repMax} reps':
          '{sets} serie | {repMin}-{repMax} rip',
      '{sets} sets | {repMin}-{repMax} reps | {rest}s rest':
          '{sets} serie | {repMin}-{repMax} rip | {rest}s recupero',
      '{sets} sets | {repMin}-{repMax} reps | RPE {rpe}':
          '{sets} serie | {repMin}-{repMax} rip | RPE {rpe}',
      '{sets} sets | {repMin}-{repMax} reps | {rest}s rest | RPE {rpe}':
          '{sets} serie | {repMin}-{repMax} rip | {rest}s recupero | RPE {rpe}',
      'Loading last workout...': 'Caricamento ultimo allenamento...',
      'Next time +2.5 kg': 'La prossima volta +2.5 kg',
      'Reference: {date}': 'Riferimento: {date}',
      'Reference: {label} | {date}': 'Riferimento: {label} | {date}',
      'Weight': 'Peso',
      'Reps': 'Rip',
      'Copy previous set': 'Copia serie precedente',
      'Below target range - consider -2.5 kg or more rest.':
          'Sotto il range obiettivo - valuta -2.5 kg o piu recupero.',
      'Last: -': 'Ultima: -',
      'Last: {weight} x {reps}': 'Ultima: {weight} x {reps}',
      'Last: {weight} x {reps} | RPE {rpe}':
          'Ultima: {weight} x {reps} | RPE {rpe}',
      'Vs last: matched': 'Vs ultima: uguale',
      'Vs last: {delta} volume': 'Vs ultima: {delta} volume',
      'Failed to load exercises: {error}':
          'Impossibile caricare gli esercizi: {error}',
      'Saved split draft found': 'Trovata bozza scheda salvata',
      'There is already a saved split draft. If you continue, you will overwrite it and the draft will be lost. Do you want to continue?':
          'Esiste gia una bozza scheda salvata. Se continui, la sovrascriverai e verra persa. Vuoi continuare?',
      'Continue': 'Continua',
      'Continue building split': 'Continua a creare la scheda',
      'Current split': 'Scheda corrente',
      'All splits': 'Tutte le schede',
      'No splits created yet. Tap ADD SPLIT to create your first split.':
          'Nessuna scheda creata. Tocca AGGIUNGI SCHEDA per creare la prima scheda.',
      'No active split selected.': 'Nessuna scheda attiva selezionata.',
      'Active': 'Attivo',
      'Hide split summary': 'Nascondi riepilogo scheda',
      'Show split summary': 'Mostra riepilogo scheda',
      'Split details unavailable.\nLast logged: {value}':
          'Dettagli scheda non disponibili.\nUltimo log: {value}',
      'No day plans configured.': 'Nessun giorno pianificato configurato.',
      'Last logged: {value}': 'Ultimo log: {value}',
      'Could not load split summary.\nLast logged: {value}':
          'Impossibile caricare il riepilogo scheda.\nUltimo log: {value}',
      'Never': 'Mai',
      'Split': 'Scheda',
      'Edit split': 'Modifica scheda',
      'Delete split': 'Elimina scheda',
      'Do you want to delete this split?': 'Vuoi eliminare questa scheda?',
      'Split deleted.': 'Scheda eliminata.',
      'Could not delete split: {error}':
          'Impossibile eliminare la scheda: {error}',
      'Updated {value}': 'Aggiornato {value}',
      'Days: {count}': 'Giorni: {count}',
      'Loading volume by muscle...': 'Caricamento volume per muscolo...',
      'Could not load volume by muscle: {error}':
          'Impossibile caricare il volume per muscolo: {error}',
      'Days': 'Giorni',
      'This split has no days configured.':
          'Questa scheda non ha giorni configurati.',
      'No planned exercises.': 'Nessun esercizio pianificato.',
      '{order}. {name} - {sets} sets x {repMin}-{repMax} reps':
          '{order}. {name} - {sets} serie x {repMin}-{repMax} rip',
      'Volume by muscle (sets)': 'Volume per muscolo (serie)',
      'Collapse volume by muscle': 'Comprimi volume per muscolo',
      'Expand volume by muscle': 'Espandi volume per muscolo',
      'Based on exercise labels. Each exercise contributes all sets to each selected control label it has.':
          'Basato sulle etichette degli esercizi. Ogni esercizio contribuisce con tutte le serie a ogni etichetta di controllo selezionata che possiede.',
      'Whole split ({count} planned sets)':
          'Scheda intera ({count} serie pianificate)',
      'Control labels': 'Etichette',
      'Select at least one control label to track muscle volume.':
          'Seleziona almeno un etichetta di controllo per tracciare il volume muscolare.',
      'No tracked control labels in this split yet.':
          'Nessuna etichetta di controllo tracciata in questa scheda.',
      'By day': 'Per giorno',
      'Control Labels': 'Etichette',
      'Search control labels': 'Cerca etichette',
      'No labels available.': 'Nessuna etichetta disponibile.',
      'Apply': 'Applica',
      '{label} ({count} sets)': '{label} ({count} serie)',
      'No selected control labels present in this day.':
          'Nessuna etichetta di controllo selezionata presente in questo giorno.',
      'No control labels selected.':
          'Nessuna etichetta di controllo selezionata.',
      'Whole split: {value}': 'Scheda intera: {value}',
      'No tracked labels': 'Nessuna etichetta tracciata',
      '+{count} more': '+{count} altre',
      'Edit Split': 'Modifica scheda',
      'Split Builder': 'Builder scheda',
      'Erase draft': 'Cancella bozza',
      'Build a split with ordered training days and planned exercises.':
          'Crea una scheda con giorni di allenamento ordinati ed esercizi pianificati.',
      'Split name *': 'Nome scheda *',
      'Set as active split': 'Imposta come scheda attiva',
      'Add Day': 'Aggiungi giorno',
      'No exercises available. Seed exercises before creating a split.':
          'Nessun esercizio disponibile. Inizializza gli esercizi prima di creare una scheda.',
      'Erase split draft?': 'Cancellare la bozza della scheda?',
      'You are erasing the current split draft. Do you want to continue?':
          'Stai cancellando la bozza della scheda corrente. Vuoi continuare?',
      'Erase': 'Cancella',
      'Split draft erased.': 'Bozza scheda cancellata.',
      'Saved split changes and set it active.':
          'Modifiche alla scheda salvate e scheda impostata come attiva.',
      'Saved split and set it active.':
          'Scheda salvata e impostata come attiva.',
      'Saved split changes.': 'Modifiche alla scheda salvate.',
      'Saved split successfully.': 'Scheda salvata correttamente.',
      'Could not save split: {error}': 'Impossibile salvare la scheda: {error}',
      'Split name is required.': 'Il nome scheda e obbligatorio.',
      'At least one day is required.': 'E richiesto almeno un giorno.',
      'Day {day} title is required.':
          'Il titolo del giorno {day} e obbligatorio.',
      'Day {day} must include at least one exercise.':
          'Il giorno {day} deve includere almeno un esercizio.',
      'Day {day}, exercise {exercise}: choose an exercise.':
          'Giorno {day}, esercizio {exercise}: scegli un esercizio.',
      'Day {day}, exercise {exercise}: sets must be a positive integer.':
          'Giorno {day}, esercizio {exercise}: le serie devono essere un intero positivo.',
      'Day {day}, exercise {exercise}: minimum reps must be positive.':
          'Giorno {day}, esercizio {exercise}: le ripetizioni minime devono essere positive.',
      'Day {day}, exercise {exercise}: maximum reps must be >= minimum reps.':
          'Giorno {day}, esercizio {exercise}: le ripetizioni massime devono essere >= delle minime.',
      'Day {day}, exercise {exercise}: rest must be a non-negative integer.':
          'Giorno {day}, esercizio {exercise}: il recupero deve essere un intero non negativo.',
      'Day {day}, exercise {exercise}: target RPE must be between 0 and 10.':
          'Giorno {day}, esercizio {exercise}: l RPE obiettivo deve essere compreso tra 0 e 10.',
      'Remove day': 'Rimuovi giorno',
      'Day title *': 'Titolo giorno *',
      'Add Exercise': 'Aggiungi esercizio',
      'Exercise {number}': 'Esercizio {number}',
      'Exercise *': 'Esercizio *',
      'No exercises available': 'Nessun esercizio disponibile',
      'Show labels': 'Mostra etichette',
      'Hide labels': 'Nascondi etichette',
      'Sets *': 'Serie *',
      'Rep min *': 'Rip min *',
      'Rep max *': 'Rip max *',
      'Session': 'Sessione',
      'Session not found.': 'Sessione non trovata.',
      'Session Overview': 'Panoramica sessione',
      'Session name': 'Nome sessione',
      'Failed to load session: {error}':
          'Impossibile caricare la sessione: {error}',
      'Discard edits': 'Annulla modifiche',
      'Edit session': 'Modifica sessione',
      'Delete session': 'Elimina sessione',
      'Delete set?': 'Eliminare la serie?',
      'Remove set {index} from {name}?':
          'Rimuovere la serie {index} da {name}?',
      'Confirm': 'Conferma',
      '{name} set {index}: reps and weight must be valid.':
          '{name} serie {index}: ripetizioni e peso devono essere validi.',
      '{name} set {index}: rest must be non-negative.':
          '{name} serie {index}: il recupero deve essere non negativo.',
      '{name} set {index}: RPE must be 0-10.':
          '{name} serie {index}: l RPE deve essere 0-10.',
      'Session updated.': 'Sessione aggiornata.',
      'Could not update session: {error}':
          'Impossibile aggiornare la sessione: {error}',
      'Delete session?': 'Eliminare la sessione?',
      'This will permanently delete the workout record.':
          'Questo eliminera definitivamente il record allenamento.',
      'Session deleted.': 'Sessione eliminata.',
      'Could not delete session: {error}':
          'Impossibile eliminare la sessione: {error}',
      'Type: {type}': 'Tipo: {type}',
      'Duration: {minutes} min': 'Durata: {minutes} min',
      'Total sets: {count}': 'Serie totali: {count}',
      'Rest': 'Recupero',
      'split_day': 'scheda',
      'free': 'libero',
      'Exit delete mode': 'Esci dalla modalità elimina',
      'Delete/hide mode': 'Modalità elimina/nascondi',
      'RESTORE': 'RIPRISTINA',
      'HIDE': 'NASCONDI',
      'Cancel': 'Annulla',
      'Delete': 'Elimina',
      'Restore': 'Ripristina',
      'Hide': 'Nascondi',
      'Retry': 'Riprova',
      'Labels': 'Etichette',
      'Browse and create labels': 'Sfoglia e crea etichette',
      'Debug tools': 'Strumenti debug',
      'Protected developer utilities': 'Utility sviluppatore protette',
      'Unlock debug tools': 'Sblocca strumenti debug',
      'Password': 'Password',
      'Unlock': 'Sblocca',
      'Incorrect password': 'Password non corretta',
      'Reset + seed demo data': 'Reset + dati demo',
      'Reset all data': 'Resetta tutti i dati',
      'Demo fixture restored.': 'Dati demo ripristinati.',
      'All local data has been reset.':
          'Tutti i dati locali sono stati resettati.',
      'Debug action failed: {error}': 'Azione debug non riuscita: {error}',
      'Recent sessions': 'Sessioni recenti',
      'Active split: none': 'Scheda attiva: nessuna',
      'Active split: {name}': 'Scheda attiva: {name}',
      'Active split: loading...': 'Scheda attiva: caricamento...',
      'Active split: unavailable': 'Scheda attiva: non disponibile',
      'Last session: No sessions yet': 'Ultima sessione: nessuna sessione',
      'Last session: {label} | {date}': 'Ultima sessione: {label} | {date}',
      'Last session: loading...': 'Ultima sessione: caricamento...',
      'Last session: unavailable': 'Ultima sessione: non disponibile',
      'DEBUG draft: none': 'BOZZA DEBUG: nessuna',
      'DEBUG draft: mode={mode}, split={split}, day={day}, updated={updated}':
          'BOZZA DEBUG: modalita={mode}, split={split}, giorno={day}, aggiornata={updated}',
      'Next workout': 'Prossimo allenamento',
      'Log current split': 'Registra scheda corrente',
      'Set current split': 'Imposta scheda corrente',
      'Current split has no available workout suggestion.':
          'La scheda corrente non ha un suggerimento di allenamento disponibile.',
      'Set an active split to get a workout suggestion.':
          'Imposta una scheda attiva per ricevere un suggerimento di allenamento.',
      'Day {day}: {title}': 'Giorno {day}: {title}',
      'Day {day}': 'Giorno {day}',
      '{count} exercises | ~{minutes} min': '{count} esercizi | ~{minutes} min',
      'Loading next workout...': 'Caricamento prossimo allenamento...',
      'Could not load next workout: {error}':
          'Impossibile caricare il prossimo allenamento: {error}',
      'Log new current split': 'Registra nuova scheda corrente',
      'Your last used split was deleted.':
          'L ultima scheda usata e stata eliminata.',
      'Your last used split is not the current split.':
          'L ultima scheda usata non e la scheda corrente.',
      'Last used: {name}': 'Ultimo usato: {name}',
      'Set last used split as current':
          'Imposta l ultima scheda usata come corrente',
      'Set last used split as current.':
          'Ultima scheda usata impostata come corrente.',
      'Could not set active split: {error}':
          'Impossibile impostare la scheda attiva: {error}',
      'Current': 'Corrente',
      'Current split updated.': 'Scheda corrente aggiornata.',
      'You have an in-progress workout from today.':
          'Hai un allenamento in corso iniziato oggi.',
      "Keep logging today's workout":
          'Continua a registrare l allenamento di oggi',
      'Log different split': 'Registra scheda diversa',
      'Log different day': 'Registra giorno diverso',
      'Free workout': 'Allenamento libero',
      'Create new split': 'Crea nuova scheda',
      'Selected split has no workout days.':
          'La scheda selezionata non ha giorni di allenamento.',
      '{count} exercises': '{count} esercizi',
      'No sessions logged yet.': 'Nessuna sessione registrata.',
      'Loading recent sessions...': 'Caricamento sessioni recenti...',
      'Failed to load recent sessions: {error}':
          'Impossibile caricare le sessioni recenti: {error}',
      '{count} sets': '{count} serie',
      '1 day': '1 giorno',
      '{count} days': '{count} giorni',
      '1 set': '1 serie',
      '1 exercise': '1 esercizio',
      '1 min': '1 min',
      'Split workout': 'Allenamento scheda',
      'Quick workout': 'Allenamento rapido',
      'Create Label': 'Crea etichetta',
      'Label name': 'Nome etichetta',
      'Add': 'Aggiungi',
      'Search labels': 'Cerca etichette',
      'No labels available yet.': 'Nessuna etichetta disponibile.',
      'ADD LABEL': 'AGGIUNGI ETICHETTA',
      'Create labels with ': 'Crea etichette con ',
      'Only added labels can be deleted.':
          'Solo le etichette aggiunte possono essere eliminate.',
      'Undo': 'Annulla',
      'Redo': 'Ripeti',
      'No labels match the current filter.':
          'Nessuna etichetta corrisponde al filtro corrente.',
      'Failed to load labels: {error}':
          'Impossibile caricare le etichette: {error}',
      'Failed to initialize labels: {error}':
          'Impossibile inizializzare le etichette: {error}',
      'Label already exists or is standard.':
          'L etichetta esiste gia o e standard.',
      'Are you sure to delete this label? When you exit the Labels screen, it will not be possible to restore it.':
          'Vuoi davvero eliminare questa etichetta? Quando uscirai dalla schermata Etichette non sara piu possibile ripristinarla.',
      'Create Exercise': 'Crea esercizio',
      'Save': 'Salva',
      'Exercise name *': 'Nome esercizio *',
      'No labels selected yet. Select at least one label.':
          'Nessuna etichetta selezionata. Selezionane almeno una.',
      'Exercise name is required.': 'Il nome esercizio e obbligatorio.',
      'Add at least one label.': 'Aggiungi almeno un etichetta.',
      'Exercise created.': 'Esercizio creato.',
      'Could not create exercise: {error}':
          'Impossibile creare l esercizio: {error}',
      'Edit Labels': 'Modifica etichette',
      'Exercise not found.': 'Esercizio non trovato.',
      'Failed to load exercise: {error}':
          'Impossibile caricare l esercizio: {error}',
      'Labels: {name}': 'Etichette: {name}',
      'This is a standard app exercise with custom labels applied.':
          'Questo e un esercizio standard dell app con etichette personalizzate.',
      'This is one of the standard app exercises. Saving creates a temporary custom label override.':
          'Questo e uno degli esercizi standard dell app. Salvando verra creato un override temporaneo delle etichette.',
      'Back to standard labels': 'Torna alle etichette standard',
      'No labels selected. Add at least one label.':
          'Nessuna etichetta selezionata. Aggiungine almeno una.',
      'Labels updated.': 'Etichette aggiornate.',
      'Could not save labels: {error}':
          'Impossibile salvare le etichette: {error}',
      'Restored standard labels.': 'Etichette standard ripristinate.',
      'Could not restore labels: {error}':
          'Impossibile ripristinare le etichette: {error}',
      'Quick Log': 'Registrazione rapida',
      'Quick Log: {name}': 'Registrazione rapida: {name}',
      'Enter reps and weight (kg) for each set. Rest and RPE are optional.':
          'Inserisci ripetizioni e peso (kg) per ogni serie. Recupero e RPE sono opzionali.',
      'Saved quick workout for {name}.':
          'Allenamento rapido salvato per {name}.',
      'Could not save workout: {error}':
          'Impossibile salvare l allenamento: {error}',
      'Set {index}: reps must be a positive integer.':
          'Serie {index}: le ripetizioni devono essere un intero positivo.',
      'Set {index}: weight must be a positive number.':
          'Serie {index}: il peso deve essere un numero positivo.',
      'Set {index}: rest must be a non-negative integer.':
          'Serie {index}: il recupero deve essere un intero non negativo.',
      'Set {index}: RPE must be between 0 and 10.':
          'Serie {index}: l RPE deve essere compreso tra 0 e 10.',
      'Set {index}': 'Serie {index}',
      'Remove set': 'Rimuovi serie',
      'Reps *': 'Ripetizioni *',
      'Weight kg *': 'Peso kg *',
      'Rest sec': 'Recupero sec',
      'RPE': 'RPE',
      'Add Set': 'Aggiungi serie',
      'Chest': 'Petto',
      'Back': 'Schiena',
      'Shoulders': 'Spalle',
      'Quads': 'Quadricipiti',
      'Glutes': 'Glutei',
      'Biceps': 'Bicipiti',
      'Triceps': 'Tricipiti',
      'Hamstrings': 'Femorali',
      'Calves': 'Polpacci',
      'Forearms': 'Avambracci',
      'Push': 'Spinta',
      'Pull': 'Tirata',
      'Legs': 'Gambe',
      'Upper': 'Parte alta',
      'Lower': 'Parte bassa',
      'Compound': 'Multiart.',
      'Isolation': 'Isolamento',
      'Are you sure to delete this exercise? When you exit the Exercises screen, it will not be possible to restore it.':
          'Vuoi davvero eliminare questo esercizio? Quando uscirai dalla schermata Esercizi non sara piu possibile ripristinarlo.',
      'Do you want to restore this exercise?':
          'Vuoi ripristinare questo esercizio?',
      'This exercise is a standard app exercise. It will not be deleted, but you can hide it. Hidden exercises can always be restored':
          'Questo esercizio e standard dell app. Non verra eliminato, ma puoi nasconderlo. Gli esercizi nascosti possono sempre essere ripristinati.',
      'History': 'Storico',
      '{name} History': 'Storico {name}',
      'Performance': 'Prestazioni',
      'Best set': 'Serie migliore',
      'Last set': 'Ultima serie',
      'No labels.': 'Nessuna etichetta.',
      '{title}: no logged data yet.': '{title}: nessun dato registrato.',
      '{reps} reps x {weight} kg': '{reps} rip x {weight} kg',
      'Rest: {seconds}s': 'Recupero: {seconds}s',
      'Logged: {value}': 'Registrato: {value}',
      'Failed to load {title}: {error}':
          'Impossibile caricare {title}: {error}',
      'Best current split set: no active split selected.':
          'Migliore serie della scheda corrente: nessuna scheda attiva selezionata.',
      'Best current split set: active split not found.':
          'Migliore serie della scheda corrente: scheda attiva non trovata.',
      'Best current split set: exercise not in active split.':
          'Migliore serie della scheda corrente: esercizio non presente nella scheda attiva.',
      'Best current split set: no logged data yet.':
          'Migliore serie della scheda corrente: nessun dato registrato.',
      'Best current split set': 'Migliore serie della scheda corrente',
      'Failed to load current split best set: {error}':
          'Impossibile caricare la migliore serie della scheda corrente: {error}',
      'Failed to load active split details: {error}':
          'Impossibile caricare i dettagli della scheda attiva: {error}',
      'Failed to load active split: {error}':
          'Impossibile caricare la scheda attiva: {error}',
      'Set {index}: {reps} reps x {weight} kg':
          'Serie {index}: {reps} rip x {weight} kg',
      'Session {date}': 'Sessione {date}',
      '{minutes} min | {sets} sets': '{minutes} min | {sets} serie',
      'Back Squat': 'Squat con bilanciere',
      'Front Squat': 'Front Squat',
      'Leg Press': 'Leg Press',
      'Romanian Deadlift': 'Stacco rumeno',
      'Conventional Deadlift': 'Stacco da terra',
      'Barbell Bench Press': 'Panca piana con bilanciere',
      'Incline Dumbbell Press': 'Panca inclinata con manubri',
      'Overhead Press': 'Military Press',
      'Dips': 'Dip alle parallele',
      'Dumbbell Lateral Raise': 'Alzate laterali con manubri',
      'Pull-Up': 'Trazioni',
      'Lat Pulldown': 'Lat Machine',
      'Barbell Row': 'Rematore con bilanciere',
      'Seated Cable Row': 'Rematore al cavo da seduto',
      'Face Pull': 'Face Pull',
      'Barbell Curl': 'Curl con bilanciere',
      'Incline Dumbbell Curl': 'Curl inclinato con manubri',
      'Triceps Pushdown': 'Pushdown tricipiti',
      'Skull Crusher': 'French Press',
      'Standing Calf Raise': 'Calf Raise in piedi',
      'legs': 'gambe',
      'quads': 'quadricipiti',
      'glutes': 'glutei',
      'abs': 'addome',
      'compound': 'multiart.',
      'hamstrings': 'femorali',
      'back': 'schiena',
      'forearms': 'avambracci',
      'posterior chain': 'catena posteriore',
      'pull': 'tirata',
      'push': 'spinta',
      'chest': 'petto',
      'triceps': 'tricipiti',
      'upper pecs': 'petto alto',
      'shoulders': 'spalle',
      'isolation': 'isolamento',
      'lats': 'dorsali',
      'biceps': 'bicipiti',
      'upper back': 'parte alta della schiena',
      'rear delts': 'deltoidi posteriori',
      'arms': 'braccia',
      'calves': 'polpacci',
    },
  };

  String get languageCode => locale.languageCode;

  String get localeName => locale.toString();

  String tr(String key, {String? fallback}) {
    final localeStrings = _strings[languageCode];
    if (localeStrings != null && localeStrings.containsKey(key)) {
      return localeStrings[key]!;
    }
    final fallbackStrings = _strings[_fallbackLanguageCode];
    if (fallbackStrings != null && fallbackStrings.containsKey(key)) {
      return fallbackStrings[key]!;
    }
    return fallback ?? key;
  }

  String format(String key, Map<String, Object?> params, {String? fallback}) {
    var output = tr(key, fallback: fallback);
    for (final entry in params.entries) {
      output = output.replaceAll('{${entry.key}}', '${entry.value}');
    }
    return output;
  }

  String localizeExerciseName(String name) => tr(name, fallback: name);

  String localizeLabelName(String name) => tr(name, fallback: name);

  String localizeLabelsJoined(Iterable<String> labels) {
    return labels.map(localizeLabelName).join(', ');
  }

  String languageDisplayName(String? languageCode) {
    switch (languageCode) {
      case null:
      case '':
        return tr('Follow system language');
      case 'en':
        return tr('English');
      case 'it':
        return tr('Italian');
      default:
        return languageCode;
    }
  }

  String formatMonthDay(DateTime value) {
    return DateFormat.MMMd(localeName).format(value);
  }

  String formatMonthDayTimeSeconds(DateTime value) {
    return DateFormat.MMMd(localeName).add_Hms().format(value);
  }

  String formatDateTimeCompact(DateTime value) {
    return DateFormat.yMd(localeName).add_Hm().format(value);
  }

  String formatDateTimeLong(DateTime value) {
    return DateFormat.yMMMd(localeName).add_Hm().format(value);
  }

  String formatDateLong(DateTime value) {
    return DateFormat.yMMMd(localeName).format(value);
  }

  String dayCountLabel(int count) {
    if (count == 1) {
      return tr('1 day');
    }
    return format('{count} days', {'count': count}, fallback: '$count days');
  }

  String setCountLabel(int count) {
    if (count == 1) {
      return tr('1 set');
    }
    return format('{count} sets', {'count': count}, fallback: '$count sets');
  }

  String exerciseCountLabel(int count) {
    if (count == 1) {
      return tr('1 exercise');
    }
    return format('{count} exercises', {
      'count': count,
    }, fallback: '$count exercises');
  }

  String minuteCountLabel(int count) {
    if (count == 1) {
      return tr('1 min');
    }
    return format('{count} min', {'count': count}, fallback: '$count min');
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsBuildContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
