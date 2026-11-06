// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'LubeLogger';

  @override
  String get connectToServer => 'Połącz z serwerem';

  @override
  String get setupIntro =>
      'Podaj adres serwera LubeLogger i klucz API, aby rozpocząć.';

  @override
  String get serverAddressLabel => 'Adres serwera';

  @override
  String get serverAddressHint => 'https://lubelogger.example.com';

  @override
  String get serverAddressHelper =>
      'Pełny adres URL Twojej instancji LubeLogger.';

  @override
  String get apiKeyExplain =>
      'Wygeneruj klucz API w LubeLogger w Ustawieniach. Zalecane: bez wygasania, z ograniczonym zakresem.';

  @override
  String get apiKeyLabel => 'Klucz API';

  @override
  String get connect => 'Połącz';

  @override
  String get connecting => 'Łączenie…';

  @override
  String get tryDemo => 'Wypróbuj wersję demo';

  @override
  String get logout => 'Wyloguj';

  @override
  String get retry => 'Ponów';

  @override
  String get comingSoon => 'Wkrótce';

  @override
  String get garageEmpty => 'Brak pojazdów. Dodaj pierwszy, aby rozpocząć.';

  @override
  String get garageLoadError =>
      'Nie udało się wczytać garażu. Pociągnij, aby ponowić.';

  @override
  String get settingsTitle => 'Ustawienia';

  @override
  String get settingsUnits => 'Jednostki';

  @override
  String get settingsCurrency => 'Waluta';

  @override
  String get settingsDistance => 'Dystans';

  @override
  String get settingsFuelEconomy => 'Zużycie paliwa';

  @override
  String get settingsDateFormat => 'Format daty';

  @override
  String get settingsDateSeparator => 'Separator daty';

  @override
  String get settingsServer => 'Serwer';

  @override
  String get settingsAbout => 'O aplikacji';

  @override
  String get settingsStorageBase => 'Dane serwera';

  @override
  String get baseMetric => 'Metryczne';

  @override
  String get baseImperial => 'Imperialne';

  @override
  String get baseImperialUk => 'Mile i litry (UK MPG)';

  @override
  String currencyAuto(String symbol) {
    return 'Automatyczna ($symbol)';
  }

  @override
  String get settingsUnitsMetricNote =>
      'Ustaw jednostki, w jakich Twój serwer LubeLogger zapisuje dane (metryczne = km i litry). Jeśli na serwerze włączono „Use UK MPG Calculation”, wybierz Mile i litry (UK MPG). Aplikacja przeliczy dane do wybranych jednostek wyświetlania.';

  @override
  String get settingsVisibleTabs => 'Widoczne zakładki';

  @override
  String get settingsVisibleTabsNote =>
      'Wybierz, które zakładki mają się pojawiać na ekranie pojazdu i w menu dodawania, oraz przeciągnij, aby zmienić ich kolejność. Pulpit jest zawsze pokazywany jako pierwszy.';

  @override
  String get dashLoadError =>
      'Nie udało się wczytać pojazdu. Pociągnij, aby ponowić.';

  @override
  String get statDistanceTraveled => 'Przejechany dystans';

  @override
  String get statTotalCost => 'Koszt całkowity';

  @override
  String get statAvgEconomy => 'Średnie spalanie';

  @override
  String get chartExpensesByType => 'Wydatki wg typu';

  @override
  String get chartExpensesDistance => 'Wydatki i dystans';

  @override
  String get chartRemindersByUrgency => 'Przypomnienia wg pilności';

  @override
  String get chartFuelMileage => 'Spalanie';

  @override
  String get chartNoDataInRange => 'Brak danych w tym okresie';

  @override
  String get chartNoReminders => 'Brak przypomnień';

  @override
  String chartRemindersTotal(int count) {
    return '$count łącznie';
  }

  @override
  String get chartTotal => 'Razem';

  @override
  String chartAverage(String value) {
    return 'śr. $value';
  }

  @override
  String chartQuarter(int quarter) {
    return '$quarter kw.';
  }

  @override
  String get chartRangeTitle => 'Zakres danych';

  @override
  String get chartRangeOneMonth => '1 miesiąc';

  @override
  String get chartRangeThreeMonths => '3 miesiące';

  @override
  String get chartRangeSixMonths => '6 miesięcy';

  @override
  String get chartRangeYear => 'Rok';

  @override
  String get chartRangeCustom => 'Własny zakres';

  @override
  String get chartRangeOneMonthShort => '1 mies.';

  @override
  String get chartRangeThreeMonthsShort => '3 mies.';

  @override
  String get chartRangeSixMonthsShort => '6 mies.';

  @override
  String get chartRangeYearShort => 'Rok';

  @override
  String get chartRangeDefault => 'domyślny';

  @override
  String get chartRangeSettingsHint =>
      'Domyślny zakres wszystkich wykresów zmienisz w Ustawieniach.';

  @override
  String chartRangeButton(String range) {
    return 'Zakres danych: $range';
  }

  @override
  String get settingsCharts => 'Wykresy';

  @override
  String get settingsChartDefaultRange => 'Domyślny zakres wykresów';

  @override
  String get settingsChartsNote =>
      'Każdy wykres na pulpicie pojazdu możesz przełączyć osobno.';

  @override
  String get legendExpenses => 'Wydatki';

  @override
  String get legendDistance => 'Dystans';

  @override
  String get catService => 'Serwis';

  @override
  String get catRepairs => 'Naprawy';

  @override
  String get catUpgrades => 'Ulepszenia';

  @override
  String get catFuel => 'Paliwo';

  @override
  String get catTax => 'Podatki';

  @override
  String get catSupply => 'Zaopatrzenie';

  @override
  String get catPlan => 'Planer';

  @override
  String get catReminder => 'Przypomnienia';

  @override
  String get catNote => 'Notatki';

  @override
  String get catEquipment => 'Wyposażenie';

  @override
  String get planPriorityCritical => 'Krytyczny';

  @override
  String get planPriorityNormal => 'Normalny';

  @override
  String get planPriorityLow => 'Niski';

  @override
  String get planProgressBacklog => 'Zaległe';

  @override
  String get planProgressInProgress => 'W toku';

  @override
  String get planProgressTesting => 'Testowanie';

  @override
  String get planProgressDone => 'Gotowe';

  @override
  String get equipmentEquipped => 'Zamontowane';

  @override
  String get equipmentRemoved => 'Zdjęte';

  @override
  String get notePinned => 'Przypięta';

  @override
  String cardAttachments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count załącznika',
      many: '$count załączników',
      few: '$count załączniki',
      one: '1 załącznik',
    );
    return '$_temp0';
  }

  @override
  String get cardHasNote => 'Zawiera notatkę';

  @override
  String get tabDashboard => 'Pulpit';

  @override
  String get tabOdometer => 'Licznik kilometrów';

  @override
  String get colDate => 'Data';

  @override
  String get colOdometer => 'Licznik';

  @override
  String get colDescription => 'Opis';

  @override
  String get colCost => 'Koszt';

  @override
  String get recordsEmpty => 'Brak wpisów.';

  @override
  String get recordsNoMatches => 'Brak pasujących wpisów.';

  @override
  String get recordsSearchHint => 'Szukaj';

  @override
  String get recordsSearchClear => 'Wyczyść wyszukiwanie';

  @override
  String get recordsSortBy => 'Sortuj według';

  @override
  String get recordsSortAscending => 'Rosnąco';

  @override
  String get recordsSortDescending => 'Malejąco';

  @override
  String get recordsClearFilters => 'Wyczyść filtry';

  @override
  String get colUrgency => 'Pilność';

  @override
  String get colDistance => 'Dystans';

  @override
  String fuelPillRecords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wpisu',
      many: '$count wpisów',
      few: '$count wpisy',
      one: '1 wpis',
    );
    return '$_temp0';
  }

  @override
  String fuelPillAvg(String value) {
    return 'Śr. $value';
  }

  @override
  String fuelPillMin(String value) {
    return 'Min $value';
  }

  @override
  String fuelPillMax(String value) {
    return 'Maks. $value';
  }

  @override
  String fuelPillDistance(String value) {
    return 'Dystans $value';
  }

  @override
  String fuelPillFuel(String value) {
    return 'Paliwo $value';
  }

  @override
  String fuelPillCost(String value) {
    return 'Koszt $value';
  }

  @override
  String get addRecordTitle => 'Dodaj wpis';

  @override
  String addRecordHidden(int count) {
    return 'Ukryte pozycje ($count)';
  }

  @override
  String get formFuelTitle => 'Dodaj tankowanie';

  @override
  String get formFuelEditTitle => 'Edytuj tankowanie';

  @override
  String get formOdometerTitle => 'Dodaj odczyt licznika';

  @override
  String get formOdometerEditTitle => 'Edytuj odczyt licznika';

  @override
  String get formServiceTitle => 'Dodaj wpis serwisowy';

  @override
  String get formServiceEditTitle => 'Edytuj wpis serwisowy';

  @override
  String get formRepairTitle => 'Dodaj naprawę';

  @override
  String get formRepairEditTitle => 'Edytuj naprawę';

  @override
  String get formUpgradeTitle => 'Dodaj ulepszenie';

  @override
  String get formUpgradeEditTitle => 'Edytuj ulepszenie';

  @override
  String get formTaxTitle => 'Dodaj podatek';

  @override
  String get formTaxEditTitle => 'Edytuj podatek';

  @override
  String get formSupplyTitle => 'Dodaj zaopatrzenie';

  @override
  String get formSupplyEditTitle => 'Edytuj zaopatrzenie';

  @override
  String get formSupplyPartNumber => 'Numer części (opcjonalnie)';

  @override
  String get formSupplyPartSupplier => 'Dostawca (opcjonalnie)';

  @override
  String get formSupplyQuantity => 'Ilość';

  @override
  String get formPlanTitle => 'Dodaj pozycję planera';

  @override
  String get formPlanEditTitle => 'Edytuj pozycję planera';

  @override
  String get formPlanType => 'Typ';

  @override
  String get formPlanPriority => 'Priorytet';

  @override
  String get formPlanProgress => 'Postęp';

  @override
  String get formReminderTitle => 'Dodaj przypomnienie';

  @override
  String get formReminderEditTitle => 'Edytuj przypomnienie';

  @override
  String get formReminderMetric => 'Przypomnij wg';

  @override
  String get formReminderMetricDate => 'Data';

  @override
  String get formReminderMetricOdometer => 'Licznik';

  @override
  String get formReminderMetricBoth => 'Data i licznik';

  @override
  String get formReminderDueDate => 'Termin';

  @override
  String formReminderDueOdometer(String unit) {
    return 'Licznik docelowy ($unit)';
  }

  @override
  String get formNoteTitle => 'Dodaj notatkę';

  @override
  String get formNoteEditTitle => 'Edytuj notatkę';

  @override
  String get formNoteTitleLabel => 'Tytuł';

  @override
  String get formNoteBodyLabel => 'Notatka';

  @override
  String get formNotePinned => 'Przypięta';

  @override
  String get formEquipmentTitle => 'Dodaj wyposażenie';

  @override
  String get formEquipmentEditTitle => 'Edytuj wyposażenie';

  @override
  String get formEquipmentNameLabel => 'Nazwa';

  @override
  String get formEquipmentEquipped => 'Zamontowane';

  @override
  String get formVehicleTitle => 'Dodaj pojazd';

  @override
  String get formVehicleEditTitle => 'Edytuj pojazd';

  @override
  String get formVehicleYear => 'Rok';

  @override
  String get formVehicleMake => 'Marka';

  @override
  String get formVehicleModel => 'Model';

  @override
  String get formVehicleLicensePlate => 'Numer rejestracyjny';

  @override
  String get formVehicleFuelType => 'Rodzaj paliwa';

  @override
  String get formVehicleUseHours => 'Śledź motogodziny zamiast licznika';

  @override
  String get formVehicleOdometerOptional => 'Licznik opcjonalny';

  @override
  String get fuelTypeGasoline => 'Benzyna';

  @override
  String get fuelTypeDiesel => 'Diesel';

  @override
  String get fuelTypeElectric => 'Elektryczny';

  @override
  String get vehicleAdded => 'Dodano pojazd';

  @override
  String get vehicleAddError =>
      'Nie udało się dodać pojazdu. Spróbuj ponownie.';

  @override
  String get vehicleUpdated => 'Zapisano zmiany pojazdu';

  @override
  String get vehicleUpdateError =>
      'Nie udało się zapisać pojazdu. Spróbuj ponownie.';

  @override
  String get vehicleDeleted => 'Usunięto pojazd';

  @override
  String get vehicleDeleteError =>
      'Nie udało się usunąć pojazdu. Spróbuj ponownie.';

  @override
  String get confirmDeleteVehicleTitle => 'Usunąć ten pojazd?';

  @override
  String get confirmDeleteVehicleMessage =>
      'Spowoduje to trwałe usunięcie pojazdu i wszystkich jego wpisów. Tej operacji nie można cofnąć.';

  @override
  String confirmDeleteVehicleFinalTitle(String vehicle) {
    return 'Trwale usunąć $vehicle?';
  }

  @override
  String get confirmDeleteVehicleFinalMessage =>
      'To ostatnia szansa, aby anulować. Pojazd i wszystkie jego wpisy zostaną bezpowrotnie usunięte.';

  @override
  String get actionDeletePermanently => 'Usuń trwale';

  @override
  String get vehicleDeleteUnsupportedTitle => 'Wymagana aktualizacja serwera';

  @override
  String vehicleDeleteUnsupportedMessage(String required, String current) {
    return 'Usuwanie pojazdu wymaga LubeLogger $required lub nowszego, a Twój serwer działa w wersji $current. Zaktualizuj serwer, aby z tego korzystać.';
  }

  @override
  String get actionOk => 'OK';

  @override
  String get actionEdit => 'Edytuj';

  @override
  String formOdometerLabel(String unit) {
    return 'Stan licznika ($unit)';
  }

  @override
  String formOdometerLast(String value) {
    return 'Ostatni odczyt: $value';
  }

  @override
  String formOdometerBackwards(String value) {
    return 'Poniżej ostatniego odczytu ($value).';
  }

  @override
  String get formOdometerBackwardsTitle => 'Licznik się cofa';

  @override
  String formOdometerBackwardsMessage(String value) {
    return 'Ten odczyt jest niższy niż ostatni ($value). Licznik zwykle tylko rośnie. Zapisać mimo to?';
  }

  @override
  String get actionSaveAnyway => 'Zapisz mimo to';

  @override
  String formFuelLabel(String unit) {
    return 'Zatankowane paliwo ($unit)';
  }

  @override
  String formFuelPriceLabel(String unit) {
    return 'Cena paliwa (za $unit)';
  }

  @override
  String formEnergyPriceLabel(String unit) {
    return 'Cena energii (za $unit)';
  }

  @override
  String get formFillToFull => 'Do pełna';

  @override
  String get formMissedFuelUp => 'Pominięte tankowanie (bez spalania)';

  @override
  String get formTagsOptional => 'Tagi (opcjonalnie)';

  @override
  String get formNotesOptional => 'Notatki (opcjonalnie)';

  @override
  String get attachmentsLabel => 'Załączniki (opcjonalnie)';

  @override
  String get attachmentAddButton => 'Dodaj plik';

  @override
  String get attachmentUploadError =>
      'Nie udało się przesłać pliku. Spróbuj ponownie.';

  @override
  String attachmentUploadRejected(String size, int status) {
    return 'Serwer odrzucił tę wysyłkę ($size MB, HTTP $status). Plik jest prawdopodobnie za duży dla serwera lub dla proxy przed nim.';
  }

  @override
  String attachmentUploadInterrupted(String size) {
    return 'Wysyłka została przerwana ($size MB). Na wolnym łączu duży plik może nie przejść.';
  }

  @override
  String get attachmentOpenError => 'Nie udało się otworzyć pliku.';

  @override
  String get extraFieldsLabel => 'Pola własne';

  @override
  String get formStateOfCharge => 'Stan naładowania';

  @override
  String formStateOfChargeRange(int start, int end) {
    return '$start% → $end%';
  }

  @override
  String get quickActionAddFuel => 'Dodaj tankowanie';

  @override
  String get quickActionAddOdometer => 'Dodaj licznik';

  @override
  String get quickActionSelectVehicle => 'Wybierz pojazd';

  @override
  String get actionCancel => 'Anuluj';

  @override
  String get actionAdd => 'Dodaj';

  @override
  String get actionSave => 'Zapisz';

  @override
  String get actionDelete => 'Usuń';

  @override
  String get validationRequired => 'Wymagane';

  @override
  String get validationNumber => 'Podaj poprawną liczbę';

  @override
  String get recordAdded => 'Dodano wpis';

  @override
  String get recordAddError => 'Nie udało się dodać wpisu. Spróbuj ponownie.';

  @override
  String get recordUpdated => 'Zapisano zmiany';

  @override
  String get recordUpdateError =>
      'Nie udało się zapisać wpisu. Spróbuj ponownie.';

  @override
  String get recordDeleted => 'Usunięto wpis';

  @override
  String get recordDeleteError =>
      'Nie udało się usunąć wpisu. Spróbuj ponownie.';

  @override
  String get confirmDeleteTitle => 'Usunąć ten wpis?';

  @override
  String get confirmDeleteMessage => 'Tej operacji nie można cofnąć.';

  @override
  String get urgencyNotUrgent => 'Niepilne';

  @override
  String get urgencyUrgent => 'Pilne';

  @override
  String get urgencyVeryUrgent => 'Bardzo pilne';

  @override
  String get urgencyPastDue => 'Po terminie';

  @override
  String signedInAs(String name) {
    return 'Zalogowano jako $name';
  }

  @override
  String get errMissingUrl => 'Podaj adres serwera.';

  @override
  String get errMissingApiKey => 'Podaj klucz API.';

  @override
  String get errServerUnreachable =>
      'Nie można połączyć się z serwerem. Sprawdź adres i sieć.';

  @override
  String get errUnauthorized =>
      'Uwierzytelnianie nie powiodło się lub klucz nie ma wymaganych uprawnień.';

  @override
  String get errForbidden => 'Brak uprawnień do tej operacji.';

  @override
  String errBadResponse(int status) {
    return 'Nieoczekiwana odpowiedź serwera (HTTP $status).';
  }

  @override
  String get errUnsupportedByServer =>
      'Twój serwer LubeLogger jest za stary na tę operację. Zaktualizuj go, aby z niej korzystać.';

  @override
  String get errBadCertificate =>
      'Nie udało się zweryfikować certyfikatu serwera.';

  @override
  String get errConnection => 'Błąd połączenia. Spróbuj ponownie.';

  @override
  String get errMalformedResponse =>
      'Nie udało się odczytać odpowiedzi serwera.';

  @override
  String get errInvalidCredentials =>
      'Nieprawidłowa nazwa użytkownika lub hasło.';

  @override
  String get errApiKeyRejected => 'Klucz API został odrzucony przez serwer.';

  @override
  String appVersion(String version, String build) {
    return 'Wersja $version ($build)';
  }

  @override
  String get openSourceLicenses => 'Licencje open source';

  @override
  String serverVersionLabel(String version) {
    return 'Wersja serwera $version';
  }

  @override
  String updateAvailable(String version) {
    return 'Dostępna aktualizacja: $version';
  }

  @override
  String get settingsBackup => 'Utwórz kopię zapasową';

  @override
  String get backupCreated => 'Kopia zapasowa utworzona na serwerze.';

  @override
  String get backupError =>
      'Nie udało się utworzyć kopii zapasowej. Spróbuj ponownie.';

  @override
  String get roleAdmin => 'Administrator';

  @override
  String get roleRoot => 'Root';

  @override
  String get settingsNotifications => 'Powiadomienia';

  @override
  String get settingsNotificationsNote =>
      'Sprawdzaj w tle przypomnienia po terminie (mniej więcej co 3 godziny) i wysyłaj powiadomienie. Każde przypomnienie powiadamia raz, dopóki nie zostanie rozwiązane.';

  @override
  String get notifRemindersToggle => 'Przypomnienia po terminie';

  @override
  String get notifPermissionDenied =>
      'Wymagane jest pozwolenie na powiadomienia. Włącz je w ustawieniach systemu.';

  @override
  String get notifReminderChannelName => 'Przypomnienia';

  @override
  String get notifReminderChannelDescription =>
      'Przypomnienia serwisowe po terminie';

  @override
  String get notifReminderTitle => 'Przypomnienie po terminie';

  @override
  String notifReminderBody(String vehicle, String description) {
    return '$vehicle: $description';
  }

  @override
  String get settingsDiagnostics => 'Błędy i pomysły';

  @override
  String get settingsDiagnosticsNote =>
      'Zgłoś błąd wraz z nagraniem tego, co robiła aplikacja, albo poproś o zmianę lub nową funkcję.';

  @override
  String get bugReportTitle => 'Zgłoś błąd lub pomysł';

  @override
  String get bugReportLogScreens => 'Otwierane ekrany i naciskane przyciski';

  @override
  String get bugReportLogRequests => 'Zapytania do serwera i jego odpowiedzi';

  @override
  String get bugReportLogErrors => 'Błędy, także te, których nie widzisz';

  @override
  String get bugReportLogSetup =>
      'Wersja aplikacji i serwera, Twój telefon, jednostki i format daty';

  @override
  String get bugReportLogNoKey => 'Klucz API ani hasło';

  @override
  String get bugReportLogNoTyping => 'Tekst, który wpisujesz';

  @override
  String get bugReportLogNoAddress =>
      'Adres serwera — tylko http albo https, nazwa albo IP, i port';

  @override
  String get bugReportLogNoData =>
      'Tablice, notatki, Twoje wpisy — tylko ich długość';

  @override
  String get bugReportRequestNoData => 'Nic o Twoich pojazdach ani telefonie';

  @override
  String fuelPillEnergy(String value) {
    return 'Energia $value';
  }

  @override
  String formEnergyLabel(String unit) {
    return 'Pobrana energia ($unit)';
  }

  @override
  String get statAvgConsumption => 'Średnie zużycie energii';

  @override
  String get chartConsumption => 'Zużycie energii';

  @override
  String get planDoneReadOnly =>
      'Ten plan jest ukończony. API LubeLoggera nie przyjmuje ukończonego planu, a każdy stan, który przyjmie, cofnąłby go — więc tutaj można go odczytać i usunąć, ale nie edytować. Zmień go na tablicy planera.';

  @override
  String get syncTitle => 'Synchronizacja';

  @override
  String get syncOffline => 'Serwer nie odpowiada.';

  @override
  String syncLastContact(String time) {
    return 'Ostatnia odpowiedź serwera: $time.';
  }

  @override
  String syncPendingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zmiany czekają na wysłanie',
      many: '$count zmian czeka na wysłanie',
      few: '$count zmiany czekają na wysłanie',
      one: '1 zmiana czeka na wysłanie',
    );
    return '$_temp0';
  }

  @override
  String get syncNothingPending => 'Wszystko, co zapisałeś, jest na serwerze.';

  @override
  String get syncSendNow => 'Wyślij teraz';

  @override
  String get syncSending => 'Wysyłanie…';

  @override
  String syncSentResult(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wysłano $count zmiany',
      many: 'Wysłano $count zmian',
      few: 'Wysłano $count zmiany',
      one: 'Wysłano 1 zmianę',
    );
    return '$_temp0';
  }

  @override
  String get syncStillOffline =>
      'Serwer nadal nie odpowiada — zostają w kolejce.';

  @override
  String syncAttempts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count próby',
      many: '$count prób',
      few: '$count próby',
      one: '1 próba',
    );
    return '$_temp0';
  }

  @override
  String get syncRejectedTitle => 'Odrzucone przez serwer';

  @override
  String get syncRejectedExplain =>
      'Serwer odpowiedział i ich nie przyjął, więc ponowne wysłanie tylko to powtórzy. Przeczytaj powód i odrzuć.';

  @override
  String get syncDiscard => 'Odrzuć';

  @override
  String get syncDiscardAll => 'Odrzuć wszystkie';

  @override
  String syncOpAdd(String type) {
    return 'Dodanie: $type';
  }

  @override
  String syncOpUpdate(String type) {
    return 'Edycja: $type';
  }

  @override
  String syncOpDelete(String type) {
    return 'Usunięcie: $type';
  }

  @override
  String get syncTypeVehicle => 'Pojazd';

  @override
  String get syncPendingTooltip => 'Zmiany czekające na wysłanie';

  @override
  String get syncOfflineTooltip => 'Brak połączenia z serwerem';

  @override
  String get settingsOfflineSection => 'Offline';

  @override
  String get settingsBackgroundRefresh => 'Odświeżaj w tle';

  @override
  String get settingsBackgroundRefreshSub =>
      'Utrzymuje zapisaną kopię aktualną, żeby aplikacja otwierała się na Twoich rekordach, a nie na kółku ładowania.';

  @override
  String get settingsStoredData => 'Zapisane dane';

  @override
  String settingsStoredDataSize(String size) {
    return '$size na tym telefonie';
  }

  @override
  String get settingsClearStoredData => 'Wyczyść';

  @override
  String get settingsStoredDataCleared => 'Zapisane dane wyczyszczone.';
}
