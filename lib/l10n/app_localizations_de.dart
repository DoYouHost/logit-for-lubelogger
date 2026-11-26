// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Logit';

  @override
  String get connectToServer => 'Mit Server verbinden';

  @override
  String get setupIntro =>
      'Gib die Adresse deines LubeLogger-Servers und deinen API-Schlüssel ein, um loszulegen.';

  @override
  String get serverAddressLabel => 'Serveradresse';

  @override
  String get serverAddressHint => 'https://lubelogger.example.com';

  @override
  String get serverAddressHelper =>
      'Vollständige URL deiner LubeLogger-Instanz.';

  @override
  String get apiKeyExplain =>
      'Erzeuge in LubeLogger unter „Einstellungen“ einen API-Schlüssel. Empfohlen: ohne Ablaufdatum und mit eingeschränktem Zugriff.';

  @override
  String get apiKeyLabel => 'API-Schlüssel';

  @override
  String get apiKeyShow => 'Schlüssel anzeigen';

  @override
  String get apiKeyHide => 'Schlüssel verbergen';

  @override
  String get connect => 'Verbinden';

  @override
  String get connecting => 'Verbinde…';

  @override
  String get tryDemo => 'Demo ausprobieren';

  @override
  String get logout => 'Abmelden';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get comingSoon => 'Demnächst';

  @override
  String get garageEmpty =>
      'Noch keine Fahrzeuge. Füge dein erstes hinzu, um loszulegen.';

  @override
  String get garageLoadError =>
      'Die Garage konnte nicht geladen werden. Zum Wiederholen nach unten ziehen.';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsUnits => 'Einheiten';

  @override
  String get settingsCurrency => 'Währung';

  @override
  String get settingsDistance => 'Entfernung';

  @override
  String get settingsFuelEconomy => 'Kraftstoffverbrauch';

  @override
  String get settingsDateFormat => 'Datumsformat';

  @override
  String get settingsDateSeparator => 'Datumstrennzeichen';

  @override
  String get settingsServer => 'Server';

  @override
  String get settingsAbout => 'Über die App';

  @override
  String get settingsStorageBase => 'Serverdaten';

  @override
  String get baseMetric => 'Metrisch';

  @override
  String get baseImperial => 'Imperial';

  @override
  String get baseImperialUk => 'Meilen und Liter (UK MPG)';

  @override
  String currencyAuto(String symbol) {
    return 'Automatisch ($symbol)';
  }

  @override
  String get settingsUnitsMetricNote =>
      'Lege die Einheiten fest, in denen dein LubeLogger-Server Werte speichert (metrisch = km und Liter). Ist auf dem Server „Use UK MPG Calculation“ aktiviert, wähle Meilen und Liter (UK MPG). Die App rechnet die Werte in die gewählten Anzeigeeinheiten um.';

  @override
  String get settingsVisibleTabs => 'Sichtbare Tabs';

  @override
  String get settingsVisibleTabsNote =>
      'Wähle, welche Tabs auf dem Fahrzeugbildschirm und im Hinzufügen-Menü erscheinen, und ändere ihre Reihenfolge per Ziehen. Die Übersicht steht immer an erster Stelle.';

  @override
  String get dashLoadError =>
      'Das Fahrzeug konnte nicht geladen werden. Zum Wiederholen nach unten ziehen.';

  @override
  String get statDistanceTraveled => 'Zurückgelegte Strecke';

  @override
  String get statTotalCost => 'Gesamtkosten';

  @override
  String get statAvgEconomy => 'Durchschnittsverbrauch';

  @override
  String get chartExpensesByType => 'Ausgaben nach Art';

  @override
  String get chartExpensesDistance => 'Ausgaben und Strecke';

  @override
  String get chartRemindersByUrgency => 'Erinnerungen nach Dringlichkeit';

  @override
  String get chartFuelMileage => 'Kraftstoffverbrauch';

  @override
  String get chartNoDataInRange => 'Keine Daten in diesem Zeitraum';

  @override
  String get chartNoReminders => 'Keine Erinnerungen';

  @override
  String chartRemindersTotal(int count) {
    return '$count insgesamt';
  }

  @override
  String get chartTotal => 'Gesamt';

  @override
  String chartAverage(String value) {
    return 'Ø $value';
  }

  @override
  String chartQuarter(int quarter) {
    return 'Q$quarter';
  }

  @override
  String get chartRangeTitle => 'Datenzeitraum';

  @override
  String get chartRangeOneMonth => '1 Monat';

  @override
  String get chartRangeThreeMonths => '3 Monate';

  @override
  String get chartRangeSixMonths => '6 Monate';

  @override
  String get chartRangeYear => '1 Jahr';

  @override
  String get chartRangeCustom => 'Eigener Zeitraum';

  @override
  String get chartRangeOneMonthShort => '1 Mon.';

  @override
  String get chartRangeThreeMonthsShort => '3 Mon.';

  @override
  String get chartRangeSixMonthsShort => '6 Mon.';

  @override
  String get chartRangeYearShort => '1 J.';

  @override
  String get chartRangeDefault => 'Standard';

  @override
  String get chartRangeSettingsHint =>
      'Den Standardzeitraum aller Diagramme änderst du in den Einstellungen.';

  @override
  String chartRangeButton(String range) {
    return 'Datenzeitraum: $range';
  }

  @override
  String get settingsCharts => 'Diagramme';

  @override
  String get settingsChartDefaultRange => 'Standardzeitraum der Diagramme';

  @override
  String get settingsChartsNote =>
      'Jedes Diagramm in der Fahrzeugübersicht kannst du einzeln umschalten.';

  @override
  String get settingsFuelForm => 'Tankvorgänge';

  @override
  String get settingsFuelCalculated => 'Berechnetes Feld';

  @override
  String get settingsFuelFormNote =>
      'Ein neuer Tankvorgang fragt zuerst die beiden anderen Werte ab und berechnet diesen. Um einmalig ein anderes Paar einzugeben, leere eines der Felder.';

  @override
  String get fuelCalculatedPrice => 'Preis';

  @override
  String get fuelCalculatedAmount => 'Menge';

  @override
  String get fuelCalculatedCost => 'Gesamtkosten';

  @override
  String get legendExpenses => 'Ausgaben';

  @override
  String get legendDistance => 'Strecke';

  @override
  String get catService => 'Wartung';

  @override
  String get catRepairs => 'Reparaturen';

  @override
  String get catUpgrades => 'Umbauten';

  @override
  String get catFuel => 'Kraftstoff';

  @override
  String get catTax => 'Steuern';

  @override
  String get catSupply => 'Verbrauchsmaterial';

  @override
  String get catPlan => 'Planer';

  @override
  String get catReminder => 'Erinnerungen';

  @override
  String get catNote => 'Notizen';

  @override
  String get catEquipment => 'Ausstattung';

  @override
  String get planPriorityCritical => 'Kritisch';

  @override
  String get planPriorityNormal => 'Normal';

  @override
  String get planPriorityLow => 'Niedrig';

  @override
  String get planProgressBacklog => 'Offen';

  @override
  String get planProgressInProgress => 'In Arbeit';

  @override
  String get planProgressTesting => 'In Prüfung';

  @override
  String get planProgressDone => 'Erledigt';

  @override
  String get equipmentEquipped => 'Montiert';

  @override
  String get equipmentRemoved => 'Demontiert';

  @override
  String get notePinned => 'Angeheftet';

  @override
  String cardAttachments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Anhänge',
      one: '$count Anhang',
    );
    return '$_temp0';
  }

  @override
  String get cardHasNote => 'Enthält eine Notiz';

  @override
  String get tabDashboard => 'Übersicht';

  @override
  String get tabOdometer => 'Kilometerstand';

  @override
  String get colDate => 'Datum';

  @override
  String get colOdometer => 'Kilometerstand';

  @override
  String get colDescription => 'Beschreibung';

  @override
  String get colCost => 'Kosten';

  @override
  String get recordsEmpty => 'Noch keine Einträge.';

  @override
  String get recordsNoMatches => 'Keine passenden Einträge.';

  @override
  String get recordsSearchHint => 'Suchen';

  @override
  String get recordsSearchClear => 'Suche löschen';

  @override
  String get recordsSortBy => 'Sortieren nach';

  @override
  String get recordsSortAscending => 'Aufsteigend';

  @override
  String get recordsSortDescending => 'Absteigend';

  @override
  String get recordsClearFilters => 'Filter zurücksetzen';

  @override
  String get colUrgency => 'Dringlichkeit';

  @override
  String get colDistance => 'Strecke';

  @override
  String fuelPillRecords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einträge',
      one: '$count Eintrag',
    );
    return '$_temp0';
  }

  @override
  String fuelPillAvg(String value) {
    return 'Ø $value';
  }

  @override
  String fuelPillMin(String value) {
    return 'Min. $value';
  }

  @override
  String fuelPillMax(String value) {
    return 'Max. $value';
  }

  @override
  String fuelPillDistance(String value) {
    return 'Strecke $value';
  }

  @override
  String fuelPillFuel(String value) {
    return 'Kraftstoff $value';
  }

  @override
  String fuelPillCost(String value) {
    return 'Kosten $value';
  }

  @override
  String get addRecordTitle => 'Eintrag hinzufügen';

  @override
  String addRecordHidden(int count) {
    return 'Ausgeblendete Einträge ($count)';
  }

  @override
  String get formFuelTitle => 'Tankvorgang hinzufügen';

  @override
  String get formFuelEditTitle => 'Tankvorgang bearbeiten';

  @override
  String get formOdometerTitle => 'Kilometerstand hinzufügen';

  @override
  String get formOdometerEditTitle => 'Kilometerstand bearbeiten';

  @override
  String get formServiceTitle => 'Wartungseintrag hinzufügen';

  @override
  String get formServiceEditTitle => 'Wartungseintrag bearbeiten';

  @override
  String get formRepairTitle => 'Reparatur hinzufügen';

  @override
  String get formRepairEditTitle => 'Reparatur bearbeiten';

  @override
  String get formUpgradeTitle => 'Umbau hinzufügen';

  @override
  String get formUpgradeEditTitle => 'Umbau bearbeiten';

  @override
  String get formTaxTitle => 'Steuer hinzufügen';

  @override
  String get formTaxEditTitle => 'Steuer bearbeiten';

  @override
  String get formSupplyTitle => 'Verbrauchsmaterial hinzufügen';

  @override
  String get formSupplyEditTitle => 'Verbrauchsmaterial bearbeiten';

  @override
  String get formSupplyPartNumber => 'Teilenummer (optional)';

  @override
  String get formSupplyPartSupplier => 'Lieferant (optional)';

  @override
  String get formSupplyQuantity => 'Menge';

  @override
  String get formPlanTitle => 'Planerpunkt hinzufügen';

  @override
  String get formPlanEditTitle => 'Planerpunkt bearbeiten';

  @override
  String get formPlanType => 'Art';

  @override
  String get formPlanPriority => 'Priorität';

  @override
  String get formPlanProgress => 'Fortschritt';

  @override
  String get formReminderTitle => 'Erinnerung hinzufügen';

  @override
  String get formReminderEditTitle => 'Erinnerung bearbeiten';

  @override
  String get formReminderMetric => 'Erinnern nach';

  @override
  String get formReminderMetricDate => 'Datum';

  @override
  String get formReminderMetricOdometer => 'Kilometerstand';

  @override
  String get formReminderMetricBoth => 'Datum und Kilometerstand';

  @override
  String get formReminderDueDate => 'Fälligkeitsdatum';

  @override
  String formReminderDueOdometer(String unit) {
    return 'Fälliger Kilometerstand ($unit)';
  }

  @override
  String get formNoteTitle => 'Notiz hinzufügen';

  @override
  String get formNoteEditTitle => 'Notiz bearbeiten';

  @override
  String get formNoteTitleLabel => 'Titel';

  @override
  String get formNoteBodyLabel => 'Notiz';

  @override
  String get formNotePinned => 'Angeheftet';

  @override
  String get formEquipmentTitle => 'Ausstattung hinzufügen';

  @override
  String get formEquipmentEditTitle => 'Ausstattung bearbeiten';

  @override
  String get formEquipmentNameLabel => 'Name';

  @override
  String get formEquipmentEquipped => 'Montiert';

  @override
  String get formVehicleTitle => 'Fahrzeug hinzufügen';

  @override
  String get formVehicleEditTitle => 'Fahrzeug bearbeiten';

  @override
  String get formVehicleYear => 'Baujahr';

  @override
  String get formVehicleMake => 'Marke';

  @override
  String get formVehicleModel => 'Modell';

  @override
  String get formVehicleLicensePlate => 'Kennzeichen';

  @override
  String get formVehicleFuelType => 'Kraftstoffart';

  @override
  String get formVehicleUseHours =>
      'Betriebsstunden statt Kilometerstand erfassen';

  @override
  String get formVehicleOdometerOptional => 'Kilometerstand optional';

  @override
  String get fuelTypeGasoline => 'Benzin';

  @override
  String get fuelTypeDiesel => 'Diesel';

  @override
  String get fuelTypeElectric => 'Elektro';

  @override
  String get vehicleAdded => 'Fahrzeug hinzugefügt';

  @override
  String get vehicleAddError =>
      'Das Fahrzeug konnte nicht hinzugefügt werden. Versuche es erneut.';

  @override
  String get vehicleUpdated => 'Fahrzeug aktualisiert';

  @override
  String get vehicleUpdateError =>
      'Das Fahrzeug konnte nicht gespeichert werden. Versuche es erneut.';

  @override
  String get vehicleDeleted => 'Fahrzeug gelöscht';

  @override
  String get vehicleDeleteError =>
      'Das Fahrzeug konnte nicht gelöscht werden. Versuche es erneut.';

  @override
  String get confirmDeleteVehicleTitle => 'Dieses Fahrzeug löschen?';

  @override
  String get confirmDeleteVehicleMessage =>
      'Das Fahrzeug und alle zugehörigen Einträge werden endgültig gelöscht. Das lässt sich nicht rückgängig machen.';

  @override
  String confirmDeleteVehicleFinalTitle(String vehicle) {
    return '$vehicle endgültig löschen?';
  }

  @override
  String get confirmDeleteVehicleFinalMessage =>
      'Das ist deine letzte Chance zum Abbrechen. Das Fahrzeug und alle seine Einträge sind danach unwiderruflich weg.';

  @override
  String get actionDeletePermanently => 'Endgültig löschen';

  @override
  String get vehicleDeleteUnsupportedTitle => 'Server-Update erforderlich';

  @override
  String vehicleDeleteUnsupportedMessage(String required, String current) {
    return 'Zum Löschen eines Fahrzeugs ist LubeLogger $required oder neuer nötig, dein Server läuft jedoch mit $current. Aktualisiere den Server, um diese Funktion zu nutzen.';
  }

  @override
  String get actionOk => 'OK';

  @override
  String get actionEdit => 'Bearbeiten';

  @override
  String formOdometerLabel(String unit) {
    return 'Kilometerstand ($unit)';
  }

  @override
  String formOdometerLast(String value) {
    return 'Letzter Stand: $value';
  }

  @override
  String formOdometerBackwards(String value) {
    return 'Unter dem letzten Stand ($value).';
  }

  @override
  String get formOdometerBackwardsTitle => 'Stand liegt unter dem letzten';

  @override
  String formOdometerBackwardsMessage(String value) {
    return 'Dieser Stand ist niedriger als der letzte ($value). Ein Kilometerstand steigt normalerweise nur. Trotzdem speichern?';
  }

  @override
  String get actionSaveAnyway => 'Trotzdem speichern';

  @override
  String formFuelLabel(String unit) {
    return 'Getankte Menge ($unit)';
  }

  @override
  String formFuelPriceLabel(String unit) {
    return 'Kraftstoffpreis (pro $unit)';
  }

  @override
  String formEnergyPriceLabel(String unit) {
    return 'Strompreis (pro $unit)';
  }

  @override
  String get formFillToFull => 'Vollgetankt';

  @override
  String get formMissedFuelUp =>
      'Ausgelassener Tankvorgang (Verbrauch überspringen)';

  @override
  String get formTagsOptional => 'Tags (optional)';

  @override
  String get formNotesOptional => 'Notizen (optional)';

  @override
  String get attachmentsLabel => 'Anhänge (optional)';

  @override
  String get attachmentAddButton => 'Datei hinzufügen';

  @override
  String get attachmentUploadError =>
      'Die Datei konnte nicht hochgeladen werden. Versuche es erneut.';

  @override
  String attachmentUploadRejected(String size, int status) {
    return 'Der Server hat diesen Upload abgelehnt ($size MB, HTTP $status). Die Datei ist wahrscheinlich zu groß für den Server oder einen vorgeschalteten Proxy.';
  }

  @override
  String attachmentUploadInterrupted(String size) {
    return 'Der Upload wurde unterbrochen ($size MB). Bei einer langsamen Verbindung kommt eine große Datei eventuell nicht durch.';
  }

  @override
  String get attachmentOpenError => 'Die Datei konnte nicht geöffnet werden.';

  @override
  String get extraFieldsLabel => 'Benutzerdefinierte Felder';

  @override
  String get formStateOfCharge => 'Ladestand';

  @override
  String formStateOfChargeRange(int start, int end) {
    return '$start % → $end %';
  }

  @override
  String get quickActionAddFuel => 'Tanken erfassen';

  @override
  String get quickActionAddOdometer => 'Kilometer erfassen';

  @override
  String get quickActionSelectVehicle => 'Fahrzeug auswählen';

  @override
  String get actionCancel => 'Abbrechen';

  @override
  String get actionAdd => 'Hinzufügen';

  @override
  String get actionSave => 'Speichern';

  @override
  String get actionDelete => 'Löschen';

  @override
  String get validationRequired => 'Erforderlich';

  @override
  String get validationNumber => 'Gib eine gültige Zahl ein';

  @override
  String get recordAdded => 'Eintrag hinzugefügt';

  @override
  String get recordAddError =>
      'Der Eintrag konnte nicht hinzugefügt werden. Versuche es erneut.';

  @override
  String get recordUpdated => 'Eintrag aktualisiert';

  @override
  String get recordUpdateError =>
      'Der Eintrag konnte nicht gespeichert werden. Versuche es erneut.';

  @override
  String get recordDeleted => 'Eintrag gelöscht';

  @override
  String get recordDeleteError =>
      'Der Eintrag konnte nicht gelöscht werden. Versuche es erneut.';

  @override
  String get confirmDeleteTitle => 'Diesen Eintrag löschen?';

  @override
  String get confirmDeleteMessage => 'Das lässt sich nicht rückgängig machen.';

  @override
  String get urgencyNotUrgent => 'Nicht dringend';

  @override
  String get urgencyUrgent => 'Dringend';

  @override
  String get urgencyVeryUrgent => 'Sehr dringend';

  @override
  String get urgencyPastDue => 'Überfällig';

  @override
  String signedInAs(String name) {
    return 'Angemeldet als $name';
  }

  @override
  String get errMissingUrl => 'Gib die Serveradresse ein.';

  @override
  String get errMissingApiKey => 'Gib deinen API-Schlüssel ein.';

  @override
  String get errServerUnreachable =>
      'Der Server ist nicht erreichbar. Prüfe die Adresse und dein Netzwerk.';

  @override
  String get errUnauthorized =>
      'Die Authentifizierung ist fehlgeschlagen oder dem Schlüssel fehlt die erforderliche Berechtigung.';

  @override
  String get errForbidden => 'Du hast keine Berechtigung für diese Aktion.';

  @override
  String errBadResponse(int status) {
    return 'Unerwartete Serverantwort (HTTP $status).';
  }

  @override
  String get errUnsupportedByServer =>
      'Dein LubeLogger-Server ist für diese Aktion zu alt. Aktualisiere den Server, um sie zu nutzen.';

  @override
  String get errBadCertificate =>
      'Das Sicherheitszertifikat des Servers konnte nicht überprüft werden.';

  @override
  String get errConnection => 'Verbindungsfehler. Bitte versuche es erneut.';

  @override
  String get errMalformedResponse =>
      'Die Serverantwort konnte nicht verstanden werden.';

  @override
  String get errInvalidCredentials =>
      'Ungültiger Benutzername oder ungültiges Passwort.';

  @override
  String get errApiKeyRejected => 'Der Server hat den API-Schlüssel abgelehnt.';

  @override
  String appVersion(String version, String build) {
    return 'Version $version ($build)';
  }

  @override
  String get openSourceLicenses => 'Open-Source-Lizenzen';

  @override
  String serverVersionLabel(String version) {
    return 'Serverversion $version';
  }

  @override
  String updateAvailable(String version) {
    return 'Update verfügbar: $version';
  }

  @override
  String get settingsBackup => 'Backup erstellen';

  @override
  String get backupCreated => 'Backup auf dem Server erstellt.';

  @override
  String get backupError =>
      'Das Backup konnte nicht erstellt werden. Versuche es erneut.';

  @override
  String get roleAdmin => 'Administrator';

  @override
  String get roleRoot => 'Root';

  @override
  String get settingsNotifications => 'Benachrichtigungen';

  @override
  String get settingsNotificationsNote =>
      'Prüft im Hintergrund (etwa alle 3 Stunden) auf überfällige Erinnerungen und zeigt eine Benachrichtigung an. Jede Erinnerung meldet sich einmal, bis sie erledigt ist.';

  @override
  String get notifRemindersToggle => 'Überfällige Erinnerungen';

  @override
  String get notifPermissionDenied =>
      'Die Berechtigung für Benachrichtigungen ist erforderlich. Aktiviere sie in den Systemeinstellungen.';

  @override
  String get notifReminderChannelName => 'Erinnerungen';

  @override
  String get notifReminderChannelDescription =>
      'Überfällige Wartungserinnerungen für Fahrzeuge';

  @override
  String get notifReminderTitle => 'Erinnerung überfällig';

  @override
  String notifReminderBody(String vehicle, String description) {
    return '$vehicle: $description';
  }

  @override
  String get settingsDiagnostics => 'Fehler und Ideen';

  @override
  String get settingsDiagnosticsNote =>
      'Melde einen Fehler samt Aufzeichnung dessen, was die App getan hat, oder wünsche dir eine Änderung oder neue Funktion.';

  @override
  String get bugReportTitle => 'Fehler oder Idee melden';

  @override
  String get bugReportLogScreens =>
      'Geöffnete Bildschirme und gedrückte Schaltflächen';

  @override
  String get bugReportLogRequests =>
      'Anfragen an den Server und seine Antworten';

  @override
  String get bugReportLogErrors => 'Fehler, auch solche, die du nie siehst';

  @override
  String get bugReportLogSetup =>
      'App- und Serverversion, dein Telefon, deine Einheiten und dein Datumsformat';

  @override
  String get bugReportLogNoKey => 'Dein API-Schlüssel oder Passwort';

  @override
  String get bugReportLogNoTyping => 'Der Text, den du eingibst';

  @override
  String get bugReportLogNoAddress =>
      'Deine Serveradresse — nur http oder https, Name oder IP und der Port';

  @override
  String get bugReportLogNoData =>
      'Kennzeichen, Notizen, deine Einträge — nur ihre Länge';

  @override
  String get bugReportRequestNoData =>
      'Nichts über deine Fahrzeuge oder dein Telefon';

  @override
  String fuelPillEnergy(String value) {
    return 'Energie $value';
  }

  @override
  String formEnergyLabel(String unit) {
    return 'Geladene Energie ($unit)';
  }

  @override
  String get statAvgConsumption => 'Durchschnittsverbrauch';

  @override
  String get chartConsumption => 'Verbrauch';

  @override
  String get planDoneReadOnly =>
      'Dieser Plan ist erledigt. Die API von LubeLogger speichert keinen erledigten Plan, und jeder Status, den sie annimmt, würde ihn zurücksetzen — daher kann er hier nur gelesen und gelöscht, aber nicht bearbeitet werden. Ändere ihn im Planer-Board.';

  @override
  String get syncTitle => 'Synchronisierung';

  @override
  String get syncOffline => 'Der Server antwortet nicht.';

  @override
  String syncLastContact(String time) {
    return 'Letzte Antwort des Servers: $time.';
  }

  @override
  String syncPendingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Änderungen warten auf das Senden',
      one: '$count Änderung wartet auf das Senden',
    );
    return '$_temp0';
  }

  @override
  String get syncNothingPending =>
      'Alles, was du gespeichert hast, liegt auf dem Server.';

  @override
  String get syncSendNow => 'Jetzt senden';

  @override
  String get syncSending => 'Wird gesendet…';

  @override
  String syncSentResult(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Änderungen gesendet',
      one: '$count Änderung gesendet',
    );
    return '$_temp0';
  }

  @override
  String get syncStillOffline =>
      'Noch immer keine Antwort vom Server — sie bleiben in der Warteschlange.';

  @override
  String syncAttempts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Versuche',
      one: '$count Versuch',
    );
    return '$_temp0';
  }

  @override
  String get syncRejectedTitle => 'Vom Server abgelehnt';

  @override
  String get syncRejectedExplain =>
      'Der Server hat geantwortet und diese Änderungen abgewiesen, ein erneutes Senden würde also nur dasselbe wiederholen. Lies den Grund und verwirf sie dann.';

  @override
  String get syncDiscard => 'Verwerfen';

  @override
  String get syncDiscardAll => 'Alle verwerfen';

  @override
  String syncOpAdd(String type) {
    return 'Hinzufügen: $type';
  }

  @override
  String syncOpUpdate(String type) {
    return 'Bearbeiten: $type';
  }

  @override
  String syncOpDelete(String type) {
    return 'Löschen: $type';
  }

  @override
  String get syncTypeVehicle => 'Fahrzeug';

  @override
  String get syncPendingTooltip => 'Änderungen, die auf das Senden warten';

  @override
  String get syncOfflineTooltip => 'Keine Verbindung zum Server';

  @override
  String get settingsOfflineSection => 'Offline';

  @override
  String get settingsBackgroundRefresh => 'Im Hintergrund aktualisieren';

  @override
  String get settingsBackgroundRefreshSub =>
      'Hält die gespeicherte Kopie aktuell, damit die App sofort deine Einträge zeigt statt eines Ladekreises.';

  @override
  String get settingsStoredData => 'Gespeicherte Daten';

  @override
  String settingsStoredDataSize(String size) {
    return '$size auf diesem Telefon';
  }

  @override
  String get settingsClearStoredData => 'Löschen';

  @override
  String get settingsStoredDataCleared => 'Gespeicherte Daten gelöscht.';
}
