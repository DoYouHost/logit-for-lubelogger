// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Logit';

  @override
  String get connectToServer => 'Connect to server';

  @override
  String get setupIntro =>
      'Enter your LubeLogger server address and API key to get started.';

  @override
  String get serverAddressLabel => 'Server address';

  @override
  String get serverAddressHint => 'https://lubelogger.example.com';

  @override
  String get serverAddressHelper => 'Full URL of your LubeLogger instance.';

  @override
  String get apiKeyExplain =>
      'Generate an API key in LubeLogger under Settings. Recommended: no expiry and scoped access.';

  @override
  String get apiKeyLabel => 'API key';

  @override
  String get apiKeyShow => 'Show the key';

  @override
  String get apiKeyHide => 'Hide the key';

  @override
  String get connect => 'Connect';

  @override
  String get connecting => 'Connecting…';

  @override
  String get tryDemo => 'Try the demo';

  @override
  String get logout => 'Log out';

  @override
  String get retry => 'Retry';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get garageEmpty =>
      'No vehicles yet. Add your first one to get started.';

  @override
  String get garageLoadError => 'Couldn\'t load your garage. Pull to retry.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsUnits => 'Units';

  @override
  String get settingsCurrency => 'Currency';

  @override
  String get settingsDistance => 'Distance';

  @override
  String get settingsFuelEconomy => 'Fuel economy';

  @override
  String get settingsDateFormat => 'Date format';

  @override
  String get settingsDateSeparator => 'Date separator';

  @override
  String get settingsServer => 'Server';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsStorageBase => 'Server data';

  @override
  String get baseMetric => 'Metric';

  @override
  String get baseImperial => 'Imperial';

  @override
  String get baseImperialUk => 'Miles & liters (UK MPG)';

  @override
  String currencyAuto(String symbol) {
    return 'Automatic ($symbol)';
  }

  @override
  String get settingsUnitsMetricNote =>
      'Set the units your LubeLogger server stores values in (metric = km & liters). If the server has “Use UK MPG Calculation” turned on, pick Miles & liters (UK MPG). The app converts the values to your chosen display units.';

  @override
  String get settingsVisibleTabs => 'Visible tabs';

  @override
  String get settingsVisibleTabsNote =>
      'Choose which record tabs appear on the vehicle screen and in the add menu, and drag to reorder them. The Dashboard is always shown first.';

  @override
  String get dashLoadError => 'Couldn\'t load this vehicle. Pull to retry.';

  @override
  String get statDistanceTraveled => 'Distance Traveled';

  @override
  String get statTotalCost => 'Total Cost';

  @override
  String get statAvgEconomy => 'Average Fuel Economy';

  @override
  String get chartExpensesByType => 'Expenses by Type';

  @override
  String get chartExpensesDistance => 'Expenses and Distance';

  @override
  String get chartRemindersByUrgency => 'Reminders by Urgency';

  @override
  String get chartFuelMileage => 'Fuel Mileage';

  @override
  String get chartNoDataInRange => 'No data in this period';

  @override
  String get chartNoReminders => 'No reminders';

  @override
  String chartRemindersTotal(int count) {
    return '$count total';
  }

  @override
  String get chartTotal => 'Total';

  @override
  String chartAverage(String value) {
    return 'avg $value';
  }

  @override
  String chartQuarter(int quarter) {
    return 'Q$quarter';
  }

  @override
  String get chartRangeTitle => 'Data range';

  @override
  String get chartRangeOneMonth => '1 month';

  @override
  String get chartRangeThreeMonths => '3 months';

  @override
  String get chartRangeSixMonths => '6 months';

  @override
  String get chartRangeYear => '1 year';

  @override
  String get chartRangeCustom => 'Custom range';

  @override
  String get chartRangeOneMonthShort => '1 mo';

  @override
  String get chartRangeThreeMonthsShort => '3 mo';

  @override
  String get chartRangeSixMonthsShort => '6 mo';

  @override
  String get chartRangeYearShort => '1 yr';

  @override
  String get chartRangeDefault => 'default';

  @override
  String get chartRangeSettingsHint =>
      'Change the default range for all charts in Settings.';

  @override
  String chartRangeButton(String range) {
    return 'Data range: $range';
  }

  @override
  String get settingsCharts => 'Charts';

  @override
  String get settingsChartDefaultRange => 'Default chart range';

  @override
  String get settingsChartsNote =>
      'You can switch each chart on the vehicle dashboard separately.';

  @override
  String get settingsFuelForm => 'Fuel-ups';

  @override
  String get settingsFuelCalculated => 'Calculated field';

  @override
  String get settingsFuelFormNote =>
      'A new fuel-up asks for the other two values first and calculates this one. To enter a different pair once, empty one of the fields.';

  @override
  String get fuelCalculatedPrice => 'Price';

  @override
  String get fuelCalculatedAmount => 'Amount';

  @override
  String get fuelCalculatedCost => 'Total cost';

  @override
  String get legendExpenses => 'Expenses';

  @override
  String get legendDistance => 'Distance';

  @override
  String get catService => 'Service';

  @override
  String get catRepairs => 'Repairs';

  @override
  String get catUpgrades => 'Upgrades';

  @override
  String get catFuel => 'Fuel';

  @override
  String get catTax => 'Tax';

  @override
  String get catSupply => 'Supplies';

  @override
  String get catPlan => 'Planner';

  @override
  String get catReminder => 'Reminders';

  @override
  String get catNote => 'Notes';

  @override
  String get catEquipment => 'Equipment';

  @override
  String get planPriorityCritical => 'Critical';

  @override
  String get planPriorityNormal => 'Normal';

  @override
  String get planPriorityLow => 'Low';

  @override
  String get planProgressBacklog => 'Backlog';

  @override
  String get planProgressInProgress => 'In progress';

  @override
  String get planProgressTesting => 'Testing';

  @override
  String get planProgressDone => 'Done';

  @override
  String get equipmentEquipped => 'Equipped';

  @override
  String get equipmentRemoved => 'Removed';

  @override
  String get notePinned => 'Pinned';

  @override
  String cardAttachments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attachments',
      one: '1 attachment',
    );
    return '$_temp0';
  }

  @override
  String get cardHasNote => 'Has a note';

  @override
  String get tabDashboard => 'Dashboard';

  @override
  String get tabOdometer => 'Odometer';

  @override
  String get colDate => 'Date';

  @override
  String get colOdometer => 'Odometer';

  @override
  String get colDescription => 'Description';

  @override
  String get colCost => 'Cost';

  @override
  String get recordsEmpty => 'No records yet.';

  @override
  String get recordsNoMatches => 'No records match.';

  @override
  String get recordsSearchHint => 'Search';

  @override
  String get recordsSearchClear => 'Clear search';

  @override
  String get recordsSortBy => 'Sort by';

  @override
  String get recordsSortAscending => 'Ascending';

  @override
  String get recordsSortDescending => 'Descending';

  @override
  String get recordsClearFilters => 'Clear filters';

  @override
  String get colUrgency => 'Urgency';

  @override
  String get colDistance => 'Distance';

  @override
  String fuelPillRecords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count records',
      one: '1 record',
    );
    return '$_temp0';
  }

  @override
  String fuelPillAvg(String value) {
    return 'Avg $value';
  }

  @override
  String fuelPillMin(String value) {
    return 'Min $value';
  }

  @override
  String fuelPillMax(String value) {
    return 'Max $value';
  }

  @override
  String fuelPillDistance(String value) {
    return 'Distance $value';
  }

  @override
  String fuelPillFuel(String value) {
    return 'Fuel $value';
  }

  @override
  String fuelPillCost(String value) {
    return 'Cost $value';
  }

  @override
  String get addRecordTitle => 'Add record';

  @override
  String addRecordHidden(int count) {
    return 'Hidden records ($count)';
  }

  @override
  String get formFuelTitle => 'Add Fuel Record';

  @override
  String get formFuelEditTitle => 'Edit Fuel Record';

  @override
  String get formOdometerTitle => 'Add Odometer Reading';

  @override
  String get formOdometerEditTitle => 'Edit Odometer Reading';

  @override
  String get formServiceTitle => 'Add Service Record';

  @override
  String get formServiceEditTitle => 'Edit Service Record';

  @override
  String get formRepairTitle => 'Add Repair Record';

  @override
  String get formRepairEditTitle => 'Edit Repair Record';

  @override
  String get formUpgradeTitle => 'Add Upgrade Record';

  @override
  String get formUpgradeEditTitle => 'Edit Upgrade Record';

  @override
  String get formTaxTitle => 'Add Tax Record';

  @override
  String get formTaxEditTitle => 'Edit Tax Record';

  @override
  String get formSupplyTitle => 'Add Supply Record';

  @override
  String get formSupplyEditTitle => 'Edit Supply Record';

  @override
  String get formSupplyPartNumber => 'Part number (optional)';

  @override
  String get formSupplyPartSupplier => 'Supplier (optional)';

  @override
  String get formSupplyQuantity => 'Quantity';

  @override
  String get formPlanTitle => 'Add Planner Item';

  @override
  String get formPlanEditTitle => 'Edit Planner Item';

  @override
  String get formPlanType => 'Type';

  @override
  String get formPlanPriority => 'Priority';

  @override
  String get formPlanProgress => 'Progress';

  @override
  String get formReminderTitle => 'Add Reminder';

  @override
  String get formReminderEditTitle => 'Edit Reminder';

  @override
  String get formReminderMetric => 'Remind by';

  @override
  String get formReminderMetricDate => 'Date';

  @override
  String get formReminderMetricOdometer => 'Odometer';

  @override
  String get formReminderMetricBoth => 'Date & odometer';

  @override
  String get formReminderDueDate => 'Due date';

  @override
  String formReminderDueOdometer(String unit) {
    return 'Due odometer ($unit)';
  }

  @override
  String get formNoteTitle => 'Add Note';

  @override
  String get formNoteEditTitle => 'Edit Note';

  @override
  String get formNoteTitleLabel => 'Title';

  @override
  String get formNoteBodyLabel => 'Note';

  @override
  String get formNotePinned => 'Pinned';

  @override
  String get formEquipmentTitle => 'Add Equipment';

  @override
  String get formEquipmentEditTitle => 'Edit Equipment';

  @override
  String get formEquipmentNameLabel => 'Name';

  @override
  String get formEquipmentEquipped => 'Equipped';

  @override
  String get formVehicleTitle => 'Add Vehicle';

  @override
  String get formVehicleEditTitle => 'Edit Vehicle';

  @override
  String get formVehicleYear => 'Year';

  @override
  String get formVehicleMake => 'Make';

  @override
  String get formVehicleModel => 'Model';

  @override
  String get formVehicleLicensePlate => 'License plate';

  @override
  String get formVehicleFuelType => 'Fuel type';

  @override
  String get formVehicleUseHours => 'Track engine hours instead of odometer';

  @override
  String get formVehicleOdometerOptional => 'Odometer optional';

  @override
  String get fuelTypeGasoline => 'Gasoline';

  @override
  String get fuelTypeDiesel => 'Diesel';

  @override
  String get fuelTypeElectric => 'Electric';

  @override
  String get vehicleAdded => 'Vehicle added';

  @override
  String get vehicleAddError => 'Couldn\'t add the vehicle. Try again.';

  @override
  String get vehicleUpdated => 'Vehicle updated';

  @override
  String get vehicleUpdateError => 'Couldn\'t save the vehicle. Try again.';

  @override
  String get vehicleDeleted => 'Vehicle deleted';

  @override
  String get vehicleDeleteError => 'Couldn\'t delete the vehicle. Try again.';

  @override
  String get confirmDeleteVehicleTitle => 'Delete this vehicle?';

  @override
  String get confirmDeleteVehicleMessage =>
      'This permanently deletes the vehicle and all of its records. This can\'t be undone.';

  @override
  String confirmDeleteVehicleFinalTitle(String vehicle) {
    return 'Permanently delete $vehicle?';
  }

  @override
  String get confirmDeleteVehicleFinalMessage =>
      'This is your last chance to cancel. The vehicle and every record for it will be gone for good.';

  @override
  String get actionDeletePermanently => 'Delete permanently';

  @override
  String get vehicleDeleteUnsupportedTitle => 'Server update required';

  @override
  String vehicleDeleteUnsupportedMessage(String required, String current) {
    return 'Deleting a vehicle requires LubeLogger $required or newer, but your server is running $current. Update the server to use this.';
  }

  @override
  String get actionOk => 'OK';

  @override
  String get actionEdit => 'Edit';

  @override
  String formOdometerLabel(String unit) {
    return 'Odometer reading ($unit)';
  }

  @override
  String formOdometerLast(String value) {
    return 'Last reading: $value';
  }

  @override
  String formOdometerBackwards(String value) {
    return 'Below the last reading ($value).';
  }

  @override
  String get formOdometerBackwardsTitle => 'Reading goes backwards';

  @override
  String formOdometerBackwardsMessage(String value) {
    return 'This reading is lower than the last one ($value). Odometers normally only go up. Save it anyway?';
  }

  @override
  String get actionSaveAnyway => 'Save anyway';

  @override
  String formFuelLabel(String unit) {
    return 'Fuel consumed ($unit)';
  }

  @override
  String formFuelPriceLabel(String unit) {
    return 'Fuel price (per $unit)';
  }

  @override
  String formEnergyPriceLabel(String unit) {
    return 'Energy price (per $unit)';
  }

  @override
  String get formFillToFull => 'Filled to full';

  @override
  String get formMissedFuelUp => 'Missed fuel-up (skip economy)';

  @override
  String get formTagsOptional => 'Tags (optional)';

  @override
  String get formNotesOptional => 'Notes (optional)';

  @override
  String get attachmentsLabel => 'Attachments (optional)';

  @override
  String get attachmentAddButton => 'Add file';

  @override
  String get attachmentUploadError => 'Couldn\'t upload the file. Try again.';

  @override
  String attachmentUploadRejected(String size, int status) {
    return 'The server rejected this upload ($size MB, HTTP $status). The file is probably too large for the server or for a proxy in front of it.';
  }

  @override
  String attachmentUploadInterrupted(String size) {
    return 'The upload was interrupted ($size MB). On a slow connection a large file may not get through.';
  }

  @override
  String get attachmentOpenError => 'Couldn\'t open the file.';

  @override
  String get extraFieldsLabel => 'Custom fields';

  @override
  String get formStateOfCharge => 'State of charge';

  @override
  String formStateOfChargeRange(int start, int end) {
    return '$start% → $end%';
  }

  @override
  String get quickActionAddFuel => 'Add fuel';

  @override
  String get quickActionAddOdometer => 'Add odometer';

  @override
  String get quickActionSelectVehicle => 'Select vehicle';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionAdd => 'Add';

  @override
  String get actionSave => 'Save';

  @override
  String get actionDelete => 'Delete';

  @override
  String get validationRequired => 'Required';

  @override
  String get validationNumber => 'Enter a valid number';

  @override
  String get recordAdded => 'Record added';

  @override
  String get recordAddError => 'Couldn\'t add the record. Try again.';

  @override
  String get recordUpdated => 'Record updated';

  @override
  String get recordUpdateError => 'Couldn\'t save the record. Try again.';

  @override
  String get recordDeleted => 'Record deleted';

  @override
  String get recordDeleteError => 'Couldn\'t delete the record. Try again.';

  @override
  String get confirmDeleteTitle => 'Delete this record?';

  @override
  String get confirmDeleteMessage => 'This can\'t be undone.';

  @override
  String get urgencyNotUrgent => 'Not Urgent';

  @override
  String get urgencyUrgent => 'Urgent';

  @override
  String get urgencyVeryUrgent => 'Very Urgent';

  @override
  String get urgencyPastDue => 'Past Due';

  @override
  String signedInAs(String name) {
    return 'Signed in as $name';
  }

  @override
  String get errMissingUrl => 'Enter the server address.';

  @override
  String get errMissingApiKey => 'Enter your API key.';

  @override
  String get errServerUnreachable =>
      'Cannot reach the server. Check the address and your network.';

  @override
  String get errUnauthorized =>
      'Authentication failed, or the key lacks the required permission.';

  @override
  String get errForbidden => 'You do not have permission for this action.';

  @override
  String errBadResponse(int status) {
    return 'Unexpected server response (HTTP $status).';
  }

  @override
  String get errUnsupportedByServer =>
      'Your LubeLogger server is too old for this action. Update the server to use it.';

  @override
  String get errBadCertificate =>
      'The server\'s security certificate could not be verified.';

  @override
  String get errConnection => 'Connection error. Please try again.';

  @override
  String get errMalformedResponse =>
      'The server response could not be understood.';

  @override
  String get errInvalidCredentials => 'Invalid username or password.';

  @override
  String get errApiKeyRejected => 'The server rejected the API key.';

  @override
  String appVersion(String version, String build) {
    return 'Version $version ($build)';
  }

  @override
  String get openSourceLicenses => 'Open source licenses';

  @override
  String serverVersionLabel(String version) {
    return 'Server version $version';
  }

  @override
  String updateAvailable(String version) {
    return 'Update available: $version';
  }

  @override
  String get settingsBackup => 'Create backup';

  @override
  String get backupCreated => 'Backup created on the server.';

  @override
  String get backupError => 'Couldn\'t create the backup. Try again.';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleRoot => 'Root';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotificationsNote =>
      'Check for past-due reminders in the background (about every 3 hours) and post a notification. Each reminder notifies once until it\'s resolved.';

  @override
  String get notifRemindersToggle => 'Past-due reminders';

  @override
  String get notifPermissionDenied =>
      'Notification permission is required. Enable it in system settings.';

  @override
  String get notifReminderChannelName => 'Reminders';

  @override
  String get notifReminderChannelDescription =>
      'Past-due vehicle maintenance reminders';

  @override
  String get notifReminderTitle => 'Reminder past due';

  @override
  String notifReminderBody(String vehicle, String description) {
    return '$vehicle: $description';
  }

  @override
  String get settingsDiagnostics => 'Bugs and ideas';

  @override
  String get settingsDiagnosticsNote =>
      'Report a bug with a recording of what the app was doing, or ask for a change or a new feature.';

  @override
  String get bugReportTitle => 'Report a bug or an idea';

  @override
  String get bugReportLogScreens => 'Screens you open and buttons you press';

  @override
  String get bugReportLogRequests => 'Requests to the server and its answers';

  @override
  String get bugReportLogErrors => 'Errors, including the ones you never see';

  @override
  String get bugReportLogSetup =>
      'App and server version, your phone, your units and date format';

  @override
  String get bugReportLogNoKey => 'Your API key or password';

  @override
  String get bugReportLogNoTyping => 'The text you type';

  @override
  String get bugReportLogNoAddress =>
      'Your server address — only http or https, name or IP, and the port';

  @override
  String get bugReportLogNoData =>
      'Plates, notes, your records — only how long they were';

  @override
  String get bugReportRequestNoData =>
      'Nothing about your vehicles or your phone';

  @override
  String fuelPillEnergy(String value) {
    return 'Energy $value';
  }

  @override
  String formEnergyLabel(String unit) {
    return 'Energy charged ($unit)';
  }

  @override
  String get statAvgConsumption => 'Average Consumption';

  @override
  String get chartConsumption => 'Consumption';

  @override
  String get planDoneReadOnly =>
      'This plan is done. LubeLogger\'s API refuses to store a finished plan, and every state it would accept sends it backwards — so it can be read and deleted here, but not edited. Change it on the planner board.';

  @override
  String get syncTitle => 'Sync';

  @override
  String get syncOffline => 'The server isn\'t answering.';

  @override
  String syncLastContact(String time) {
    return 'Server last answered $time.';
  }

  @override
  String syncPendingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes waiting to be sent',
      one: '1 change waiting to be sent',
    );
    return '$_temp0';
  }

  @override
  String get syncNothingPending =>
      'Everything you have saved is on the server.';

  @override
  String get syncSendNow => 'Send now';

  @override
  String get syncSending => 'Sending…';

  @override
  String syncSentResult(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes sent',
      one: '1 change sent',
    );
    return '$_temp0';
  }

  @override
  String get syncStillOffline =>
      'Still no answer from the server — they stay queued.';

  @override
  String syncAttempts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attempts',
      one: '1 attempt',
    );
    return '$_temp0';
  }

  @override
  String get syncRejectedTitle => 'Refused by the server';

  @override
  String get syncRejectedExplain =>
      'The server answered and turned these down, so sending them again would only repeat it. Read why, then dismiss.';

  @override
  String get syncDiscard => 'Discard';

  @override
  String get syncDiscardAll => 'Discard all';

  @override
  String syncOpAdd(String type) {
    return 'Add $type';
  }

  @override
  String syncOpUpdate(String type) {
    return 'Edit $type';
  }

  @override
  String syncOpDelete(String type) {
    return 'Delete $type';
  }

  @override
  String get syncTypeVehicle => 'Vehicle';

  @override
  String get syncPendingTooltip => 'Changes waiting to be sent';

  @override
  String get syncOfflineTooltip => 'No connection to the server';

  @override
  String get settingsOfflineSection => 'Offline';

  @override
  String get settingsBackgroundRefresh => 'Refresh in the background';

  @override
  String get settingsBackgroundRefreshSub =>
      'Keeps the stored copy current, so the app opens on your records instead of a spinner.';

  @override
  String get settingsStoredData => 'Stored data';

  @override
  String settingsStoredDataSize(String size) {
    return '$size on this phone';
  }

  @override
  String get settingsClearStoredData => 'Clear';

  @override
  String get settingsStoredDataCleared => 'Stored data cleared.';
}
