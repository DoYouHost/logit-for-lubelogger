// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Logit';

  @override
  String get connectToServer => 'Se connecter au serveur';

  @override
  String get setupIntro =>
      'Saisissez l’adresse de votre serveur LubeLogger et votre clé API pour commencer.';

  @override
  String get serverAddressLabel => 'Adresse du serveur';

  @override
  String get serverAddressHint => 'https://lubelogger.example.com';

  @override
  String get serverAddressHelper =>
      'URL complète de votre instance LubeLogger.';

  @override
  String get apiKeyExplain =>
      'Générez une clé API dans LubeLogger, sous Paramètres. Recommandé : sans expiration et avec un accès limité.';

  @override
  String get apiKeyLabel => 'Clé API';

  @override
  String get apiKeyShow => 'Afficher la clé';

  @override
  String get apiKeyHide => 'Masquer la clé';

  @override
  String get connect => 'Se connecter';

  @override
  String get connecting => 'Connexion…';

  @override
  String get tryDemo => 'Essayer la démo';

  @override
  String get logout => 'Se déconnecter';

  @override
  String get retry => 'Réessayer';

  @override
  String get comingSoon => 'Bientôt disponible';

  @override
  String get garageEmpty =>
      'Aucun véhicule pour l’instant. Ajoutez le premier pour commencer.';

  @override
  String get garageLoadError =>
      'Impossible de charger votre garage. Tirez vers le bas pour réessayer.';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsUnits => 'Unités';

  @override
  String get settingsCurrency => 'Devise';

  @override
  String get settingsDistance => 'Distance';

  @override
  String get settingsFuelEconomy => 'Consommation de carburant';

  @override
  String get settingsDateFormat => 'Format de date';

  @override
  String get settingsDateSeparator => 'Séparateur de date';

  @override
  String get settingsServer => 'Serveur';

  @override
  String get settingsAbout => 'À propos';

  @override
  String get settingsStorageBase => 'Données du serveur';

  @override
  String get baseMetric => 'Métrique';

  @override
  String get baseImperial => 'Impérial';

  @override
  String get baseImperialUk => 'Miles et litres (UK MPG)';

  @override
  String currencyAuto(String symbol) {
    return 'Automatique ($symbol)';
  }

  @override
  String get settingsUnitsMetricNote =>
      'Indiquez les unités dans lesquelles votre serveur LubeLogger enregistre les valeurs (métrique = km et litres). Si l’option « Use UK MPG Calculation » est activée sur le serveur, choisissez Miles et litres (UK MPG). L’application convertit les valeurs dans les unités d’affichage choisies.';

  @override
  String get settingsVisibleTabs => 'Onglets visibles';

  @override
  String get settingsVisibleTabsNote =>
      'Choisissez les onglets affichés sur l’écran du véhicule et dans le menu d’ajout, et faites-les glisser pour les réordonner. Le tableau de bord est toujours affiché en premier.';

  @override
  String get dashLoadError =>
      'Impossible de charger ce véhicule. Tirez vers le bas pour réessayer.';

  @override
  String get statDistanceTraveled => 'Distance parcourue';

  @override
  String get statTotalCost => 'Coût total';

  @override
  String get statAvgEconomy => 'Consommation moyenne';

  @override
  String get chartExpensesByType => 'Dépenses par type';

  @override
  String get chartExpensesDistance => 'Dépenses et distance';

  @override
  String get chartRemindersByUrgency => 'Rappels par urgence';

  @override
  String get chartFuelMileage => 'Consommation de carburant';

  @override
  String get chartNoDataInRange => 'Aucune donnée sur cette période';

  @override
  String get chartNoReminders => 'Aucun rappel';

  @override
  String chartRemindersTotal(int count) {
    return '$count au total';
  }

  @override
  String get chartTotal => 'Total';

  @override
  String chartAverage(String value) {
    return 'moy. $value';
  }

  @override
  String chartQuarter(int quarter) {
    return 'T$quarter';
  }

  @override
  String get chartRangeTitle => 'Période des données';

  @override
  String get chartRangeOneMonth => '1 mois';

  @override
  String get chartRangeThreeMonths => '3 mois';

  @override
  String get chartRangeSixMonths => '6 mois';

  @override
  String get chartRangeYear => '1 an';

  @override
  String get chartRangeCustom => 'Période personnalisée';

  @override
  String get chartRangeOneMonthShort => '1 m';

  @override
  String get chartRangeThreeMonthsShort => '3 m';

  @override
  String get chartRangeSixMonthsShort => '6 m';

  @override
  String get chartRangeYearShort => '1 an';

  @override
  String get chartRangeDefault => 'par défaut';

  @override
  String get chartRangeSettingsHint =>
      'Modifiez la période par défaut de tous les graphiques dans les Paramètres.';

  @override
  String chartRangeButton(String range) {
    return 'Période des données : $range';
  }

  @override
  String get settingsCharts => 'Graphiques';

  @override
  String get settingsChartDefaultRange => 'Période par défaut des graphiques';

  @override
  String get settingsChartsNote =>
      'Vous pouvez régler chaque graphique du tableau de bord du véhicule séparément.';

  @override
  String get settingsFuelForm => 'Pleins';

  @override
  String get settingsFuelCalculated => 'Champ calculé';

  @override
  String get settingsFuelFormNote =>
      'Un nouveau plein demande d’abord les deux autres valeurs et calcule celle-ci. Pour saisir une autre paire une seule fois, videz l’un des champs.';

  @override
  String get fuelCalculatedPrice => 'Prix';

  @override
  String get fuelCalculatedAmount => 'Quantité';

  @override
  String get fuelCalculatedCost => 'Coût total';

  @override
  String get legendExpenses => 'Dépenses';

  @override
  String get legendDistance => 'Distance';

  @override
  String get catService => 'Entretien';

  @override
  String get catRepairs => 'Réparations';

  @override
  String get catUpgrades => 'Améliorations';

  @override
  String get catFuel => 'Carburant';

  @override
  String get catTax => 'Taxes';

  @override
  String get catSupply => 'Fournitures';

  @override
  String get catPlan => 'Planificateur';

  @override
  String get catReminder => 'Rappels';

  @override
  String get catNote => 'Notes';

  @override
  String get catEquipment => 'Équipements';

  @override
  String get planPriorityCritical => 'Critique';

  @override
  String get planPriorityNormal => 'Normale';

  @override
  String get planPriorityLow => 'Faible';

  @override
  String get planProgressBacklog => 'À faire';

  @override
  String get planProgressInProgress => 'En cours';

  @override
  String get planProgressTesting => 'En test';

  @override
  String get planProgressDone => 'Terminé';

  @override
  String get equipmentEquipped => 'Monté';

  @override
  String get equipmentRemoved => 'Retiré';

  @override
  String get notePinned => 'Épinglée';

  @override
  String cardAttachments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pièces jointes',
      one: '$count pièce jointe',
    );
    return '$_temp0';
  }

  @override
  String get cardHasNote => 'Contient une note';

  @override
  String get tabDashboard => 'Tableau de bord';

  @override
  String get tabOdometer => 'Compteur kilométrique';

  @override
  String get colDate => 'Date';

  @override
  String get colOdometer => 'Compteur';

  @override
  String get colDescription => 'Description';

  @override
  String get colCost => 'Coût';

  @override
  String get recordsEmpty => 'Aucun enregistrement pour l’instant.';

  @override
  String get recordsNoMatches => 'Aucun enregistrement correspondant.';

  @override
  String get recordsSearchHint => 'Rechercher';

  @override
  String get recordsSearchClear => 'Effacer la recherche';

  @override
  String get recordsSortBy => 'Trier par';

  @override
  String get recordsSortAscending => 'Croissant';

  @override
  String get recordsSortDescending => 'Décroissant';

  @override
  String get recordsClearFilters => 'Effacer les filtres';

  @override
  String get colUrgency => 'Urgence';

  @override
  String get colDistance => 'Distance';

  @override
  String fuelPillRecords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count enregistrements',
      one: '$count enregistrement',
    );
    return '$_temp0';
  }

  @override
  String fuelPillAvg(String value) {
    return 'Moy. $value';
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
    return 'Distance $value';
  }

  @override
  String fuelPillFuel(String value) {
    return 'Carburant $value';
  }

  @override
  String fuelPillCost(String value) {
    return 'Coût $value';
  }

  @override
  String get addRecordTitle => 'Ajouter un enregistrement';

  @override
  String addRecordHidden(int count) {
    return 'Éléments masqués ($count)';
  }

  @override
  String get formFuelTitle => 'Ajouter un plein';

  @override
  String get formFuelEditTitle => 'Modifier le plein';

  @override
  String get formOdometerTitle => 'Ajouter un relevé kilométrique';

  @override
  String get formOdometerEditTitle => 'Modifier le relevé kilométrique';

  @override
  String get formServiceTitle => 'Ajouter un entretien';

  @override
  String get formServiceEditTitle => 'Modifier l’entretien';

  @override
  String get formRepairTitle => 'Ajouter une réparation';

  @override
  String get formRepairEditTitle => 'Modifier la réparation';

  @override
  String get formUpgradeTitle => 'Ajouter une amélioration';

  @override
  String get formUpgradeEditTitle => 'Modifier l’amélioration';

  @override
  String get formTaxTitle => 'Ajouter une taxe';

  @override
  String get formTaxEditTitle => 'Modifier la taxe';

  @override
  String get formSupplyTitle => 'Ajouter une fourniture';

  @override
  String get formSupplyEditTitle => 'Modifier la fourniture';

  @override
  String get formSupplyPartNumber => 'Référence de la pièce (facultatif)';

  @override
  String get formSupplyPartSupplier => 'Fournisseur (facultatif)';

  @override
  String get formSupplyQuantity => 'Quantité';

  @override
  String get formPlanTitle => 'Ajouter un élément au planificateur';

  @override
  String get formPlanEditTitle => 'Modifier l’élément du planificateur';

  @override
  String get formPlanType => 'Type';

  @override
  String get formPlanPriority => 'Priorité';

  @override
  String get formPlanProgress => 'Avancement';

  @override
  String get formReminderTitle => 'Ajouter un rappel';

  @override
  String get formReminderEditTitle => 'Modifier le rappel';

  @override
  String get formReminderMetric => 'Rappeler selon';

  @override
  String get formReminderMetricDate => 'Date';

  @override
  String get formReminderMetricOdometer => 'Compteur';

  @override
  String get formReminderMetricBoth => 'Date et compteur';

  @override
  String get formReminderDueDate => 'Date d’échéance';

  @override
  String formReminderDueOdometer(String unit) {
    return 'Compteur à l’échéance ($unit)';
  }

  @override
  String get formNoteTitle => 'Ajouter une note';

  @override
  String get formNoteEditTitle => 'Modifier la note';

  @override
  String get formNoteTitleLabel => 'Titre';

  @override
  String get formNoteBodyLabel => 'Note';

  @override
  String get formNotePinned => 'Épinglée';

  @override
  String get formEquipmentTitle => 'Ajouter un équipement';

  @override
  String get formEquipmentEditTitle => 'Modifier l’équipement';

  @override
  String get formEquipmentNameLabel => 'Nom';

  @override
  String get formEquipmentEquipped => 'Monté';

  @override
  String get formVehicleTitle => 'Ajouter un véhicule';

  @override
  String get formVehicleEditTitle => 'Modifier le véhicule';

  @override
  String get formVehicleYear => 'Année';

  @override
  String get formVehicleMake => 'Marque';

  @override
  String get formVehicleModel => 'Modèle';

  @override
  String get formVehicleLicensePlate => 'Plaque d’immatriculation';

  @override
  String get formVehicleFuelType => 'Type de carburant';

  @override
  String get formVehicleUseHours =>
      'Suivre les heures moteur au lieu du compteur kilométrique';

  @override
  String get formVehicleOdometerOptional => 'Compteur facultatif';

  @override
  String get fuelTypeGasoline => 'Essence';

  @override
  String get fuelTypeDiesel => 'Diesel';

  @override
  String get fuelTypeElectric => 'Électrique';

  @override
  String get vehicleAdded => 'Véhicule ajouté';

  @override
  String get vehicleAddError => 'Impossible d’ajouter le véhicule. Réessayez.';

  @override
  String get vehicleUpdated => 'Véhicule mis à jour';

  @override
  String get vehicleUpdateError =>
      'Impossible d’enregistrer le véhicule. Réessayez.';

  @override
  String get vehicleDeleted => 'Véhicule supprimé';

  @override
  String get vehicleDeleteError =>
      'Impossible de supprimer le véhicule. Réessayez.';

  @override
  String get confirmDeleteVehicleTitle => 'Supprimer ce véhicule ?';

  @override
  String get confirmDeleteVehicleMessage =>
      'Le véhicule et tous ses enregistrements seront définitivement supprimés. Cette action est irréversible.';

  @override
  String confirmDeleteVehicleFinalTitle(String vehicle) {
    return 'Supprimer définitivement $vehicle ?';
  }

  @override
  String get confirmDeleteVehicleFinalMessage =>
      'C’est votre dernière chance d’annuler. Le véhicule et tous ses enregistrements disparaîtront pour de bon.';

  @override
  String get actionDeletePermanently => 'Supprimer définitivement';

  @override
  String get vehicleDeleteUnsupportedTitle => 'Mise à jour du serveur requise';

  @override
  String vehicleDeleteUnsupportedMessage(String required, String current) {
    return 'La suppression d’un véhicule nécessite LubeLogger $required ou une version plus récente, mais votre serveur exécute la version $current. Mettez le serveur à jour pour utiliser cette fonction.';
  }

  @override
  String get actionOk => 'OK';

  @override
  String get actionEdit => 'Modifier';

  @override
  String formOdometerLabel(String unit) {
    return 'Relevé du compteur ($unit)';
  }

  @override
  String formOdometerLast(String value) {
    return 'Dernier relevé : $value';
  }

  @override
  String formOdometerBackwards(String value) {
    return 'Inférieur au dernier relevé ($value).';
  }

  @override
  String get formOdometerBackwardsTitle => 'Le relevé recule';

  @override
  String formOdometerBackwardsMessage(String value) {
    return 'Ce relevé est inférieur au dernier ($value). Un compteur ne fait normalement qu’augmenter. L’enregistrer quand même ?';
  }

  @override
  String get actionSaveAnyway => 'Enregistrer quand même';

  @override
  String formFuelLabel(String unit) {
    return 'Carburant consommé ($unit)';
  }

  @override
  String formFuelPriceLabel(String unit) {
    return 'Prix du carburant (par $unit)';
  }

  @override
  String formEnergyPriceLabel(String unit) {
    return 'Prix de l’énergie (par $unit)';
  }

  @override
  String get formFillToFull => 'Plein complet';

  @override
  String get formMissedFuelUp => 'Plein manqué (ignorer la consommation)';

  @override
  String get formTagsOptional => 'Étiquettes (facultatif)';

  @override
  String get formNotesOptional => 'Notes (facultatif)';

  @override
  String get attachmentsLabel => 'Pièces jointes (facultatif)';

  @override
  String get attachmentAddButton => 'Ajouter un fichier';

  @override
  String get attachmentUploadError =>
      'Impossible d’envoyer le fichier. Réessayez.';

  @override
  String attachmentUploadRejected(String size, int status) {
    return 'Le serveur a refusé cet envoi ($size Mo, HTTP $status). Le fichier est probablement trop volumineux pour le serveur ou pour un proxy placé devant.';
  }

  @override
  String attachmentUploadInterrupted(String size) {
    return 'L’envoi a été interrompu ($size Mo). Sur une connexion lente, un gros fichier peut ne pas passer.';
  }

  @override
  String get attachmentOpenError => 'Impossible d’ouvrir le fichier.';

  @override
  String get extraFieldsLabel => 'Champs personnalisés';

  @override
  String get formStateOfCharge => 'Niveau de charge';

  @override
  String formStateOfChargeRange(int start, int end) {
    return '$start % → $end %';
  }

  @override
  String get quickActionAddFuel => 'Ajouter un plein';

  @override
  String get quickActionAddOdometer => 'Ajouter un relevé';

  @override
  String get quickActionSelectVehicle => 'Choisir un véhicule';

  @override
  String get actionCancel => 'Annuler';

  @override
  String get actionAdd => 'Ajouter';

  @override
  String get actionSave => 'Enregistrer';

  @override
  String get actionDelete => 'Supprimer';

  @override
  String get validationRequired => 'Obligatoire';

  @override
  String get validationNumber => 'Saisissez un nombre valide';

  @override
  String get recordAdded => 'Enregistrement ajouté';

  @override
  String get recordAddError =>
      'Impossible d’ajouter l’enregistrement. Réessayez.';

  @override
  String get recordUpdated => 'Enregistrement mis à jour';

  @override
  String get recordUpdateError =>
      'Impossible de sauvegarder l’enregistrement. Réessayez.';

  @override
  String get recordDeleted => 'Enregistrement supprimé';

  @override
  String get recordDeleteError =>
      'Impossible de supprimer l’enregistrement. Réessayez.';

  @override
  String get confirmDeleteTitle => 'Supprimer cet enregistrement ?';

  @override
  String get confirmDeleteMessage => 'Cette action est irréversible.';

  @override
  String get urgencyNotUrgent => 'Pas urgent';

  @override
  String get urgencyUrgent => 'Urgent';

  @override
  String get urgencyVeryUrgent => 'Très urgent';

  @override
  String get urgencyPastDue => 'En retard';

  @override
  String signedInAs(String name) {
    return 'Connecté en tant que $name';
  }

  @override
  String get errMissingUrl => 'Saisissez l’adresse du serveur.';

  @override
  String get errMissingApiKey => 'Saisissez votre clé API.';

  @override
  String get errServerUnreachable =>
      'Impossible de joindre le serveur. Vérifiez l’adresse et votre réseau.';

  @override
  String get errUnauthorized =>
      'L’authentification a échoué, ou la clé n’a pas l’autorisation requise.';

  @override
  String get errForbidden =>
      'Vous n’avez pas l’autorisation d’effectuer cette action.';

  @override
  String errBadResponse(int status) {
    return 'Réponse inattendue du serveur (HTTP $status).';
  }

  @override
  String get errUnsupportedByServer =>
      'Votre serveur LubeLogger est trop ancien pour cette action. Mettez-le à jour pour l’utiliser.';

  @override
  String get errBadCertificate =>
      'Le certificat de sécurité du serveur n’a pas pu être vérifié.';

  @override
  String get errConnection => 'Erreur de connexion. Veuillez réessayer.';

  @override
  String get errMalformedResponse =>
      'La réponse du serveur n’a pas pu être interprétée.';

  @override
  String get errInvalidCredentials =>
      'Nom d’utilisateur ou mot de passe incorrect.';

  @override
  String get errApiKeyRejected => 'Le serveur a rejeté la clé API.';

  @override
  String appVersion(String version, String build) {
    return 'Version $version ($build)';
  }

  @override
  String get openSourceLicenses => 'Licences open source';

  @override
  String serverVersionLabel(String version) {
    return 'Version du serveur $version';
  }

  @override
  String updateAvailable(String version) {
    return 'Mise à jour disponible : $version';
  }

  @override
  String get settingsBackup => 'Créer une sauvegarde';

  @override
  String get backupCreated => 'Sauvegarde créée sur le serveur.';

  @override
  String get backupError => 'Impossible de créer la sauvegarde. Réessayez.';

  @override
  String get roleAdmin => 'Administrateur';

  @override
  String get roleRoot => 'Root';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotificationsNote =>
      'Vérifie en arrière-plan (environ toutes les 3 heures) les rappels en retard et envoie une notification. Chaque rappel ne notifie qu’une fois, jusqu’à ce qu’il soit résolu.';

  @override
  String get notifRemindersToggle => 'Rappels en retard';

  @override
  String get notifPermissionDenied =>
      'L’autorisation d’envoyer des notifications est requise. Activez-la dans les paramètres du système.';

  @override
  String get notifReminderChannelName => 'Rappels';

  @override
  String get notifReminderChannelDescription =>
      'Rappels d’entretien de véhicule en retard';

  @override
  String get notifReminderTitle => 'Rappel en retard';

  @override
  String notifReminderBody(String vehicle, String description) {
    return '$vehicle : $description';
  }

  @override
  String get settingsDiagnostics => 'Bugs et idées';

  @override
  String get settingsDiagnosticsNote =>
      'Signalez un bug avec un enregistrement de ce que faisait l’application, ou demandez une modification ou une nouvelle fonction.';

  @override
  String get bugReportTitle => 'Signaler un bug ou une idée';

  @override
  String get bugReportLogScreens =>
      'Les écrans que vous ouvrez et les boutons sur lesquels vous appuyez';

  @override
  String get bugReportLogRequests =>
      'Les requêtes envoyées au serveur et ses réponses';

  @override
  String get bugReportLogErrors =>
      'Les erreurs, y compris celles que vous ne voyez jamais';

  @override
  String get bugReportLogSetup =>
      'La version de l’application et du serveur, votre téléphone, vos unités et votre format de date';

  @override
  String get bugReportLogNoKey => 'Votre clé API ou votre mot de passe';

  @override
  String get bugReportLogNoTyping => 'Le texte que vous saisissez';

  @override
  String get bugReportLogNoAddress =>
      'L’adresse de votre serveur — seulement http ou https, nom ou IP, et le port';

  @override
  String get bugReportLogNoData =>
      'Plaques, notes, vos enregistrements — seulement leur longueur';

  @override
  String get bugReportRequestNoData =>
      'Rien sur vos véhicules ni sur votre téléphone';

  @override
  String fuelPillEnergy(String value) {
    return 'Énergie $value';
  }

  @override
  String formEnergyLabel(String unit) {
    return 'Énergie chargée ($unit)';
  }

  @override
  String get statAvgConsumption => 'Consommation moyenne';

  @override
  String get chartConsumption => 'Consommation';

  @override
  String get planDoneReadOnly =>
      'Ce plan est terminé. L’API de LubeLogger refuse d’enregistrer un plan terminé, et chaque état qu’elle accepterait le ferait revenir en arrière — il peut donc être consulté et supprimé ici, mais pas modifié. Modifiez-le sur le tableau du planificateur.';

  @override
  String get syncTitle => 'Synchronisation';

  @override
  String get syncOffline => 'Le serveur ne répond pas.';

  @override
  String syncLastContact(String time) {
    return 'Dernière réponse du serveur : $time.';
  }

  @override
  String syncPendingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count modifications en attente d’envoi',
      one: '$count modification en attente d’envoi',
    );
    return '$_temp0';
  }

  @override
  String get syncNothingPending =>
      'Tout ce que vous avez enregistré se trouve sur le serveur.';

  @override
  String get syncSendNow => 'Envoyer maintenant';

  @override
  String get syncSending => 'Envoi…';

  @override
  String syncSentResult(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count modifications envoyées',
      one: '$count modification envoyée',
    );
    return '$_temp0';
  }

  @override
  String get syncStillOffline =>
      'Toujours aucune réponse du serveur — elles restent en file d’attente.';

  @override
  String syncAttempts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tentatives',
      one: '$count tentative',
    );
    return '$_temp0';
  }

  @override
  String get syncRejectedTitle => 'Refusé par le serveur';

  @override
  String get syncRejectedExplain =>
      'Le serveur a répondu et a refusé ces modifications ; les renvoyer ne ferait que répéter l’échec. Lisez la raison, puis ignorez-les.';

  @override
  String get syncDiscard => 'Ignorer';

  @override
  String get syncDiscardAll => 'Tout ignorer';

  @override
  String syncOpAdd(String type) {
    return 'Ajout : $type';
  }

  @override
  String syncOpUpdate(String type) {
    return 'Modification : $type';
  }

  @override
  String syncOpDelete(String type) {
    return 'Suppression : $type';
  }

  @override
  String get syncTypeVehicle => 'Véhicule';

  @override
  String get syncPendingTooltip => 'Modifications en attente d’envoi';

  @override
  String get syncOfflineTooltip => 'Pas de connexion au serveur';

  @override
  String get settingsOfflineSection => 'Hors ligne';

  @override
  String get settingsBackgroundRefresh => 'Actualiser en arrière-plan';

  @override
  String get settingsBackgroundRefreshSub =>
      'Garde la copie enregistrée à jour, pour que l’application s’ouvre directement sur vos enregistrements plutôt que sur un indicateur de chargement.';

  @override
  String get settingsStoredData => 'Données enregistrées';

  @override
  String settingsStoredDataSize(String size) {
    return '$size sur ce téléphone';
  }

  @override
  String get settingsClearStoredData => 'Effacer';

  @override
  String get settingsStoredDataCleared => 'Données enregistrées effacées.';
}
