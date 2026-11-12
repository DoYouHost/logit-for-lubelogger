import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pl.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('en'),
    Locale('pl'),
  ];

  /// Application name, shown in the launcher and title bar.
  ///
  /// In en, this message translates to:
  /// **'Logit'**
  String get appTitle;

  /// Title of the login / server setup screen.
  ///
  /// In en, this message translates to:
  /// **'Connect to server'**
  String get connectToServer;

  /// No description provided for @setupIntro.
  ///
  /// In en, this message translates to:
  /// **'Enter your LubeLogger server address and API key to get started.'**
  String get setupIntro;

  /// No description provided for @serverAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Server address'**
  String get serverAddressLabel;

  /// No description provided for @serverAddressHint.
  ///
  /// In en, this message translates to:
  /// **'https://lubelogger.example.com'**
  String get serverAddressHint;

  /// No description provided for @serverAddressHelper.
  ///
  /// In en, this message translates to:
  /// **'Full URL of your LubeLogger instance.'**
  String get serverAddressHelper;

  /// No description provided for @apiKeyExplain.
  ///
  /// In en, this message translates to:
  /// **'Generate an API key in LubeLogger under Settings. Recommended: no expiry and scoped access.'**
  String get apiKeyExplain;

  /// No description provided for @apiKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get apiKeyLabel;

  /// No description provided for @apiKeyShow.
  ///
  /// In en, this message translates to:
  /// **'Show the key'**
  String get apiKeyShow;

  /// No description provided for @apiKeyHide.
  ///
  /// In en, this message translates to:
  /// **'Hide the key'**
  String get apiKeyHide;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get connecting;

  /// Button on the login screen that fills in the demo credentials.
  ///
  /// In en, this message translates to:
  /// **'Try the demo'**
  String get tryDemo;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @garageEmpty.
  ///
  /// In en, this message translates to:
  /// **'No vehicles yet. Add your first one to get started.'**
  String get garageEmpty;

  /// No description provided for @garageLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your garage. Pull to retry.'**
  String get garageLoadError;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsUnits.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get settingsUnits;

  /// No description provided for @settingsCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get settingsCurrency;

  /// No description provided for @settingsDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get settingsDistance;

  /// No description provided for @settingsFuelEconomy.
  ///
  /// In en, this message translates to:
  /// **'Fuel economy'**
  String get settingsFuelEconomy;

  /// No description provided for @settingsDateFormat.
  ///
  /// In en, this message translates to:
  /// **'Date format'**
  String get settingsDateFormat;

  /// No description provided for @settingsDateSeparator.
  ///
  /// In en, this message translates to:
  /// **'Date separator'**
  String get settingsDateSeparator;

  /// No description provided for @settingsServer.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get settingsServer;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsStorageBase.
  ///
  /// In en, this message translates to:
  /// **'Server data'**
  String get settingsStorageBase;

  /// No description provided for @baseMetric.
  ///
  /// In en, this message translates to:
  /// **'Metric'**
  String get baseMetric;

  /// No description provided for @baseImperial.
  ///
  /// In en, this message translates to:
  /// **'Imperial'**
  String get baseImperial;

  /// No description provided for @baseImperialUk.
  ///
  /// In en, this message translates to:
  /// **'Miles & liters (UK MPG)'**
  String get baseImperialUk;

  /// No description provided for @currencyAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic ({symbol})'**
  String currencyAuto(String symbol);

  /// No description provided for @settingsUnitsMetricNote.
  ///
  /// In en, this message translates to:
  /// **'Set the units your LubeLogger server stores values in (metric = km & liters). If the server has “Use UK MPG Calculation” turned on, pick Miles & liters (UK MPG). The app converts the values to your chosen display units.'**
  String get settingsUnitsMetricNote;

  /// No description provided for @settingsVisibleTabs.
  ///
  /// In en, this message translates to:
  /// **'Visible tabs'**
  String get settingsVisibleTabs;

  /// No description provided for @settingsVisibleTabsNote.
  ///
  /// In en, this message translates to:
  /// **'Choose which record tabs appear on the vehicle screen and in the add menu, and drag to reorder them. The Dashboard is always shown first.'**
  String get settingsVisibleTabsNote;

  /// No description provided for @dashLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this vehicle. Pull to retry.'**
  String get dashLoadError;

  /// No description provided for @statDistanceTraveled.
  ///
  /// In en, this message translates to:
  /// **'Distance Traveled'**
  String get statDistanceTraveled;

  /// No description provided for @statTotalCost.
  ///
  /// In en, this message translates to:
  /// **'Total Cost'**
  String get statTotalCost;

  /// No description provided for @statAvgEconomy.
  ///
  /// In en, this message translates to:
  /// **'Average Fuel Economy'**
  String get statAvgEconomy;

  /// No description provided for @chartExpensesByType.
  ///
  /// In en, this message translates to:
  /// **'Expenses by Type'**
  String get chartExpensesByType;

  /// No description provided for @chartExpensesDistance.
  ///
  /// In en, this message translates to:
  /// **'Expenses and Distance'**
  String get chartExpensesDistance;

  /// No description provided for @chartRemindersByUrgency.
  ///
  /// In en, this message translates to:
  /// **'Reminders by Urgency'**
  String get chartRemindersByUrgency;

  /// No description provided for @chartFuelMileage.
  ///
  /// In en, this message translates to:
  /// **'Fuel Mileage'**
  String get chartFuelMileage;

  /// No description provided for @chartNoDataInRange.
  ///
  /// In en, this message translates to:
  /// **'No data in this period'**
  String get chartNoDataInRange;

  /// No description provided for @chartNoReminders.
  ///
  /// In en, this message translates to:
  /// **'No reminders'**
  String get chartNoReminders;

  /// No description provided for @chartRemindersTotal.
  ///
  /// In en, this message translates to:
  /// **'{count} total'**
  String chartRemindersTotal(int count);

  /// No description provided for @chartTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get chartTotal;

  /// Label on a chart's average line; value is a formatted number
  ///
  /// In en, this message translates to:
  /// **'avg {value}'**
  String chartAverage(String value);

  /// Time-axis label for a calendar quarter
  ///
  /// In en, this message translates to:
  /// **'Q{quarter}'**
  String chartQuarter(int quarter);

  /// No description provided for @chartRangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Data range'**
  String get chartRangeTitle;

  /// No description provided for @chartRangeOneMonth.
  ///
  /// In en, this message translates to:
  /// **'1 month'**
  String get chartRangeOneMonth;

  /// No description provided for @chartRangeThreeMonths.
  ///
  /// In en, this message translates to:
  /// **'3 months'**
  String get chartRangeThreeMonths;

  /// No description provided for @chartRangeSixMonths.
  ///
  /// In en, this message translates to:
  /// **'6 months'**
  String get chartRangeSixMonths;

  /// No description provided for @chartRangeYear.
  ///
  /// In en, this message translates to:
  /// **'1 year'**
  String get chartRangeYear;

  /// No description provided for @chartRangeCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom range'**
  String get chartRangeCustom;

  /// Chart range button label; keep it very short
  ///
  /// In en, this message translates to:
  /// **'1 mo'**
  String get chartRangeOneMonthShort;

  /// No description provided for @chartRangeThreeMonthsShort.
  ///
  /// In en, this message translates to:
  /// **'3 mo'**
  String get chartRangeThreeMonthsShort;

  /// No description provided for @chartRangeSixMonthsShort.
  ///
  /// In en, this message translates to:
  /// **'6 mo'**
  String get chartRangeSixMonthsShort;

  /// No description provided for @chartRangeYearShort.
  ///
  /// In en, this message translates to:
  /// **'1 yr'**
  String get chartRangeYearShort;

  /// Badge next to the range option that Settings sets as default
  ///
  /// In en, this message translates to:
  /// **'default'**
  String get chartRangeDefault;

  /// No description provided for @chartRangeSettingsHint.
  ///
  /// In en, this message translates to:
  /// **'Change the default range for all charts in Settings.'**
  String get chartRangeSettingsHint;

  /// Screen-reader label of a chart's range button
  ///
  /// In en, this message translates to:
  /// **'Data range: {range}'**
  String chartRangeButton(String range);

  /// No description provided for @settingsCharts.
  ///
  /// In en, this message translates to:
  /// **'Charts'**
  String get settingsCharts;

  /// No description provided for @settingsChartDefaultRange.
  ///
  /// In en, this message translates to:
  /// **'Default chart range'**
  String get settingsChartDefaultRange;

  /// No description provided for @settingsChartsNote.
  ///
  /// In en, this message translates to:
  /// **'You can switch each chart on the vehicle dashboard separately.'**
  String get settingsChartsNote;

  /// No description provided for @settingsFuelForm.
  ///
  /// In en, this message translates to:
  /// **'Fuel-ups'**
  String get settingsFuelForm;

  /// No description provided for @settingsFuelCalculated.
  ///
  /// In en, this message translates to:
  /// **'Calculated field'**
  String get settingsFuelCalculated;

  /// No description provided for @settingsFuelFormNote.
  ///
  /// In en, this message translates to:
  /// **'A new fuel-up asks for the other two values first and calculates this one. To enter a different pair once, empty one of the fields.'**
  String get settingsFuelFormNote;

  /// No description provided for @fuelCalculatedPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get fuelCalculatedPrice;

  /// No description provided for @fuelCalculatedAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get fuelCalculatedAmount;

  /// No description provided for @fuelCalculatedCost.
  ///
  /// In en, this message translates to:
  /// **'Total cost'**
  String get fuelCalculatedCost;

  /// No description provided for @legendExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get legendExpenses;

  /// No description provided for @legendDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get legendDistance;

  /// No description provided for @catService.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get catService;

  /// No description provided for @catRepairs.
  ///
  /// In en, this message translates to:
  /// **'Repairs'**
  String get catRepairs;

  /// No description provided for @catUpgrades.
  ///
  /// In en, this message translates to:
  /// **'Upgrades'**
  String get catUpgrades;

  /// No description provided for @catFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get catFuel;

  /// No description provided for @catTax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get catTax;

  /// No description provided for @catSupply.
  ///
  /// In en, this message translates to:
  /// **'Supplies'**
  String get catSupply;

  /// No description provided for @catPlan.
  ///
  /// In en, this message translates to:
  /// **'Planner'**
  String get catPlan;

  /// No description provided for @catReminder.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get catReminder;

  /// No description provided for @catNote.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get catNote;

  /// No description provided for @catEquipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get catEquipment;

  /// No description provided for @planPriorityCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get planPriorityCritical;

  /// No description provided for @planPriorityNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get planPriorityNormal;

  /// No description provided for @planPriorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get planPriorityLow;

  /// No description provided for @planProgressBacklog.
  ///
  /// In en, this message translates to:
  /// **'Backlog'**
  String get planProgressBacklog;

  /// No description provided for @planProgressInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get planProgressInProgress;

  /// No description provided for @planProgressTesting.
  ///
  /// In en, this message translates to:
  /// **'Testing'**
  String get planProgressTesting;

  /// No description provided for @planProgressDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get planProgressDone;

  /// No description provided for @equipmentEquipped.
  ///
  /// In en, this message translates to:
  /// **'Equipped'**
  String get equipmentEquipped;

  /// No description provided for @equipmentRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed'**
  String get equipmentRemoved;

  /// No description provided for @notePinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get notePinned;

  /// Long-press text on a record card's paperclip, which shows the file count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 attachment} other{{count} attachments}}'**
  String cardAttachments(int count);

  /// Long-press text on a record card's note icon.
  ///
  /// In en, this message translates to:
  /// **'Has a note'**
  String get cardHasNote;

  /// No description provided for @tabDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get tabDashboard;

  /// No description provided for @tabOdometer.
  ///
  /// In en, this message translates to:
  /// **'Odometer'**
  String get tabOdometer;

  /// No description provided for @colDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get colDate;

  /// No description provided for @colOdometer.
  ///
  /// In en, this message translates to:
  /// **'Odometer'**
  String get colOdometer;

  /// No description provided for @colDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get colDescription;

  /// No description provided for @colCost.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get colCost;

  /// No description provided for @recordsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No records yet.'**
  String get recordsEmpty;

  /// No description provided for @recordsNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No records match.'**
  String get recordsNoMatches;

  /// No description provided for @recordsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get recordsSearchHint;

  /// No description provided for @recordsSearchClear.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get recordsSearchClear;

  /// No description provided for @recordsSortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get recordsSortBy;

  /// No description provided for @recordsSortAscending.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get recordsSortAscending;

  /// No description provided for @recordsSortDescending.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get recordsSortDescending;

  /// No description provided for @recordsClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get recordsClearFilters;

  /// No description provided for @colUrgency.
  ///
  /// In en, this message translates to:
  /// **'Urgency'**
  String get colUrgency;

  /// No description provided for @colDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get colDistance;

  /// No description provided for @fuelPillRecords.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 record} other{{count} records}}'**
  String fuelPillRecords(int count);

  /// No description provided for @fuelPillAvg.
  ///
  /// In en, this message translates to:
  /// **'Avg {value}'**
  String fuelPillAvg(String value);

  /// No description provided for @fuelPillMin.
  ///
  /// In en, this message translates to:
  /// **'Min {value}'**
  String fuelPillMin(String value);

  /// No description provided for @fuelPillMax.
  ///
  /// In en, this message translates to:
  /// **'Max {value}'**
  String fuelPillMax(String value);

  /// No description provided for @fuelPillDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance {value}'**
  String fuelPillDistance(String value);

  /// No description provided for @fuelPillFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel {value}'**
  String fuelPillFuel(String value);

  /// No description provided for @fuelPillCost.
  ///
  /// In en, this message translates to:
  /// **'Cost {value}'**
  String fuelPillCost(String value);

  /// No description provided for @addRecordTitle.
  ///
  /// In en, this message translates to:
  /// **'Add record'**
  String get addRecordTitle;

  /// No description provided for @addRecordHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden records ({count})'**
  String addRecordHidden(int count);

  /// No description provided for @formFuelTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Fuel Record'**
  String get formFuelTitle;

  /// No description provided for @formFuelEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Fuel Record'**
  String get formFuelEditTitle;

  /// No description provided for @formOdometerTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Odometer Reading'**
  String get formOdometerTitle;

  /// No description provided for @formOdometerEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Odometer Reading'**
  String get formOdometerEditTitle;

  /// No description provided for @formServiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Service Record'**
  String get formServiceTitle;

  /// No description provided for @formServiceEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Service Record'**
  String get formServiceEditTitle;

  /// No description provided for @formRepairTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Repair Record'**
  String get formRepairTitle;

  /// No description provided for @formRepairEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Repair Record'**
  String get formRepairEditTitle;

  /// No description provided for @formUpgradeTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Upgrade Record'**
  String get formUpgradeTitle;

  /// No description provided for @formUpgradeEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Upgrade Record'**
  String get formUpgradeEditTitle;

  /// No description provided for @formTaxTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Tax Record'**
  String get formTaxTitle;

  /// No description provided for @formTaxEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Tax Record'**
  String get formTaxEditTitle;

  /// No description provided for @formSupplyTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Supply Record'**
  String get formSupplyTitle;

  /// No description provided for @formSupplyEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Supply Record'**
  String get formSupplyEditTitle;

  /// No description provided for @formSupplyPartNumber.
  ///
  /// In en, this message translates to:
  /// **'Part number (optional)'**
  String get formSupplyPartNumber;

  /// No description provided for @formSupplyPartSupplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier (optional)'**
  String get formSupplyPartSupplier;

  /// No description provided for @formSupplyQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get formSupplyQuantity;

  /// No description provided for @formPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Planner Item'**
  String get formPlanTitle;

  /// No description provided for @formPlanEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Planner Item'**
  String get formPlanEditTitle;

  /// No description provided for @formPlanType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get formPlanType;

  /// No description provided for @formPlanPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get formPlanPriority;

  /// No description provided for @formPlanProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get formPlanProgress;

  /// No description provided for @formReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Reminder'**
  String get formReminderTitle;

  /// No description provided for @formReminderEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Reminder'**
  String get formReminderEditTitle;

  /// No description provided for @formReminderMetric.
  ///
  /// In en, this message translates to:
  /// **'Remind by'**
  String get formReminderMetric;

  /// No description provided for @formReminderMetricDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get formReminderMetricDate;

  /// No description provided for @formReminderMetricOdometer.
  ///
  /// In en, this message translates to:
  /// **'Odometer'**
  String get formReminderMetricOdometer;

  /// No description provided for @formReminderMetricBoth.
  ///
  /// In en, this message translates to:
  /// **'Date & odometer'**
  String get formReminderMetricBoth;

  /// No description provided for @formReminderDueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get formReminderDueDate;

  /// No description provided for @formReminderDueOdometer.
  ///
  /// In en, this message translates to:
  /// **'Due odometer ({unit})'**
  String formReminderDueOdometer(String unit);

  /// No description provided for @formNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Note'**
  String get formNoteTitle;

  /// No description provided for @formNoteEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Note'**
  String get formNoteEditTitle;

  /// No description provided for @formNoteTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get formNoteTitleLabel;

  /// No description provided for @formNoteBodyLabel.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get formNoteBodyLabel;

  /// No description provided for @formNotePinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get formNotePinned;

  /// No description provided for @formEquipmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Equipment'**
  String get formEquipmentTitle;

  /// No description provided for @formEquipmentEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Equipment'**
  String get formEquipmentEditTitle;

  /// No description provided for @formEquipmentNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get formEquipmentNameLabel;

  /// No description provided for @formEquipmentEquipped.
  ///
  /// In en, this message translates to:
  /// **'Equipped'**
  String get formEquipmentEquipped;

  /// No description provided for @formVehicleTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Vehicle'**
  String get formVehicleTitle;

  /// No description provided for @formVehicleEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Vehicle'**
  String get formVehicleEditTitle;

  /// No description provided for @formVehicleYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get formVehicleYear;

  /// No description provided for @formVehicleMake.
  ///
  /// In en, this message translates to:
  /// **'Make'**
  String get formVehicleMake;

  /// No description provided for @formVehicleModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get formVehicleModel;

  /// No description provided for @formVehicleLicensePlate.
  ///
  /// In en, this message translates to:
  /// **'License plate'**
  String get formVehicleLicensePlate;

  /// No description provided for @formVehicleFuelType.
  ///
  /// In en, this message translates to:
  /// **'Fuel type'**
  String get formVehicleFuelType;

  /// No description provided for @formVehicleUseHours.
  ///
  /// In en, this message translates to:
  /// **'Track engine hours instead of odometer'**
  String get formVehicleUseHours;

  /// No description provided for @formVehicleOdometerOptional.
  ///
  /// In en, this message translates to:
  /// **'Odometer optional'**
  String get formVehicleOdometerOptional;

  /// No description provided for @fuelTypeGasoline.
  ///
  /// In en, this message translates to:
  /// **'Gasoline'**
  String get fuelTypeGasoline;

  /// No description provided for @fuelTypeDiesel.
  ///
  /// In en, this message translates to:
  /// **'Diesel'**
  String get fuelTypeDiesel;

  /// No description provided for @fuelTypeElectric.
  ///
  /// In en, this message translates to:
  /// **'Electric'**
  String get fuelTypeElectric;

  /// No description provided for @vehicleAdded.
  ///
  /// In en, this message translates to:
  /// **'Vehicle added'**
  String get vehicleAdded;

  /// No description provided for @vehicleAddError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t add the vehicle. Try again.'**
  String get vehicleAddError;

  /// No description provided for @vehicleUpdated.
  ///
  /// In en, this message translates to:
  /// **'Vehicle updated'**
  String get vehicleUpdated;

  /// No description provided for @vehicleUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the vehicle. Try again.'**
  String get vehicleUpdateError;

  /// No description provided for @vehicleDeleted.
  ///
  /// In en, this message translates to:
  /// **'Vehicle deleted'**
  String get vehicleDeleted;

  /// No description provided for @vehicleDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete the vehicle. Try again.'**
  String get vehicleDeleteError;

  /// No description provided for @confirmDeleteVehicleTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this vehicle?'**
  String get confirmDeleteVehicleTitle;

  /// No description provided for @confirmDeleteVehicleMessage.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes the vehicle and all of its records. This can\'t be undone.'**
  String get confirmDeleteVehicleMessage;

  /// No description provided for @confirmDeleteVehicleFinalTitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete {vehicle}?'**
  String confirmDeleteVehicleFinalTitle(String vehicle);

  /// No description provided for @confirmDeleteVehicleFinalMessage.
  ///
  /// In en, this message translates to:
  /// **'This is your last chance to cancel. The vehicle and every record for it will be gone for good.'**
  String get confirmDeleteVehicleFinalMessage;

  /// No description provided for @actionDeletePermanently.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get actionDeletePermanently;

  /// No description provided for @vehicleDeleteUnsupportedTitle.
  ///
  /// In en, this message translates to:
  /// **'Server update required'**
  String get vehicleDeleteUnsupportedTitle;

  /// No description provided for @vehicleDeleteUnsupportedMessage.
  ///
  /// In en, this message translates to:
  /// **'Deleting a vehicle requires LubeLogger {required} or newer, but your server is running {current}. Update the server to use this.'**
  String vehicleDeleteUnsupportedMessage(String required, String current);

  /// No description provided for @actionOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get actionOk;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @formOdometerLabel.
  ///
  /// In en, this message translates to:
  /// **'Odometer reading ({unit})'**
  String formOdometerLabel(String unit);

  /// Helper line under the odometer field, showing the reading this one follows.
  ///
  /// In en, this message translates to:
  /// **'Last reading: {value}'**
  String formOdometerLast(String value);

  /// Inline warning when the entered reading is lower than the previous one.
  ///
  /// In en, this message translates to:
  /// **'Below the last reading ({value}).'**
  String formOdometerBackwards(String value);

  /// No description provided for @formOdometerBackwardsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reading goes backwards'**
  String get formOdometerBackwardsTitle;

  /// No description provided for @formOdometerBackwardsMessage.
  ///
  /// In en, this message translates to:
  /// **'This reading is lower than the last one ({value}). Odometers normally only go up. Save it anyway?'**
  String formOdometerBackwardsMessage(String value);

  /// No description provided for @actionSaveAnyway.
  ///
  /// In en, this message translates to:
  /// **'Save anyway'**
  String get actionSaveAnyway;

  /// No description provided for @formFuelLabel.
  ///
  /// In en, this message translates to:
  /// **'Fuel consumed ({unit})'**
  String formFuelLabel(String unit);

  /// No description provided for @formFuelPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Fuel price (per {unit})'**
  String formFuelPriceLabel(String unit);

  /// Charging-session price field; unit is kWh
  ///
  /// In en, this message translates to:
  /// **'Energy price (per {unit})'**
  String formEnergyPriceLabel(String unit);

  /// No description provided for @formFillToFull.
  ///
  /// In en, this message translates to:
  /// **'Filled to full'**
  String get formFillToFull;

  /// No description provided for @formMissedFuelUp.
  ///
  /// In en, this message translates to:
  /// **'Missed fuel-up (skip economy)'**
  String get formMissedFuelUp;

  /// No description provided for @formTagsOptional.
  ///
  /// In en, this message translates to:
  /// **'Tags (optional)'**
  String get formTagsOptional;

  /// No description provided for @formNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get formNotesOptional;

  /// No description provided for @attachmentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Attachments (optional)'**
  String get attachmentsLabel;

  /// No description provided for @attachmentAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add file'**
  String get attachmentAddButton;

  /// No description provided for @attachmentUploadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t upload the file. Try again.'**
  String get attachmentUploadError;

  /// Shown for 413/502/504, where retrying the same file cannot help — so the message must not say 'try again'.
  ///
  /// In en, this message translates to:
  /// **'The server rejected this upload ({size} MB, HTTP {status}). The file is probably too large for the server or for a proxy in front of it.'**
  String attachmentUploadRejected(String size, int status);

  /// No description provided for @attachmentUploadInterrupted.
  ///
  /// In en, this message translates to:
  /// **'The upload was interrupted ({size} MB). On a slow connection a large file may not get through.'**
  String attachmentUploadInterrupted(String size);

  /// No description provided for @attachmentOpenError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the file.'**
  String get attachmentOpenError;

  /// No description provided for @extraFieldsLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom fields'**
  String get extraFieldsLabel;

  /// No description provided for @formStateOfCharge.
  ///
  /// In en, this message translates to:
  /// **'State of charge'**
  String get formStateOfCharge;

  /// No description provided for @formStateOfChargeRange.
  ///
  /// In en, this message translates to:
  /// **'{start}% → {end}%'**
  String formStateOfChargeRange(int start, int end);

  /// No description provided for @quickActionAddFuel.
  ///
  /// In en, this message translates to:
  /// **'Add fuel'**
  String get quickActionAddFuel;

  /// No description provided for @quickActionAddOdometer.
  ///
  /// In en, this message translates to:
  /// **'Add odometer'**
  String get quickActionAddOdometer;

  /// No description provided for @quickActionSelectVehicle.
  ///
  /// In en, this message translates to:
  /// **'Select vehicle'**
  String get quickActionSelectVehicle;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAdd;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @validationRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get validationRequired;

  /// No description provided for @validationNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get validationNumber;

  /// No description provided for @recordAdded.
  ///
  /// In en, this message translates to:
  /// **'Record added'**
  String get recordAdded;

  /// No description provided for @recordAddError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t add the record. Try again.'**
  String get recordAddError;

  /// No description provided for @recordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Record updated'**
  String get recordUpdated;

  /// No description provided for @recordUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the record. Try again.'**
  String get recordUpdateError;

  /// No description provided for @recordDeleted.
  ///
  /// In en, this message translates to:
  /// **'Record deleted'**
  String get recordDeleted;

  /// No description provided for @recordDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete the record. Try again.'**
  String get recordDeleteError;

  /// No description provided for @confirmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this record?'**
  String get confirmDeleteTitle;

  /// No description provided for @confirmDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'This can\'t be undone.'**
  String get confirmDeleteMessage;

  /// No description provided for @urgencyNotUrgent.
  ///
  /// In en, this message translates to:
  /// **'Not Urgent'**
  String get urgencyNotUrgent;

  /// No description provided for @urgencyUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgencyUrgent;

  /// No description provided for @urgencyVeryUrgent.
  ///
  /// In en, this message translates to:
  /// **'Very Urgent'**
  String get urgencyVeryUrgent;

  /// No description provided for @urgencyPastDue.
  ///
  /// In en, this message translates to:
  /// **'Past Due'**
  String get urgencyPastDue;

  /// Confirmation after a successful connection.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {name}'**
  String signedInAs(String name);

  /// No description provided for @errMissingUrl.
  ///
  /// In en, this message translates to:
  /// **'Enter the server address.'**
  String get errMissingUrl;

  /// No description provided for @errMissingApiKey.
  ///
  /// In en, this message translates to:
  /// **'Enter your API key.'**
  String get errMissingApiKey;

  /// No description provided for @errServerUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach the server. Check the address and your network.'**
  String get errServerUnreachable;

  /// No description provided for @errUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed, or the key lacks the required permission.'**
  String get errUnauthorized;

  /// No description provided for @errForbidden.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission for this action.'**
  String get errForbidden;

  /// No description provided for @errBadResponse.
  ///
  /// In en, this message translates to:
  /// **'Unexpected server response (HTTP {status}).'**
  String errBadResponse(int status);

  /// Shown when the server answers 404 because the endpoint only exists in a newer LubeLogger.
  ///
  /// In en, this message translates to:
  /// **'Your LubeLogger server is too old for this action. Update the server to use it.'**
  String get errUnsupportedByServer;

  /// No description provided for @errBadCertificate.
  ///
  /// In en, this message translates to:
  /// **'The server\'s security certificate could not be verified.'**
  String get errBadCertificate;

  /// No description provided for @errConnection.
  ///
  /// In en, this message translates to:
  /// **'Connection error. Please try again.'**
  String get errConnection;

  /// No description provided for @errMalformedResponse.
  ///
  /// In en, this message translates to:
  /// **'The server response could not be understood.'**
  String get errMalformedResponse;

  /// No description provided for @errInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid username or password.'**
  String get errInvalidCredentials;

  /// No description provided for @errApiKeyRejected.
  ///
  /// In en, this message translates to:
  /// **'The server rejected the API key.'**
  String get errApiKeyRejected;

  /// App version + build number, shown in Settings > About.
  ///
  /// In en, this message translates to:
  /// **'Version {version} ({build})'**
  String appVersion(String version, String build);

  /// No description provided for @openSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open source licenses'**
  String get openSourceLicenses;

  /// No description provided for @serverVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Server version {version}'**
  String serverVersionLabel(String version);

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update available: {version}'**
  String updateAvailable(String version);

  /// No description provided for @settingsBackup.
  ///
  /// In en, this message translates to:
  /// **'Create backup'**
  String get settingsBackup;

  /// No description provided for @backupCreated.
  ///
  /// In en, this message translates to:
  /// **'Backup created on the server.'**
  String get backupCreated;

  /// No description provided for @backupError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create the backup. Try again.'**
  String get backupError;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @roleRoot.
  ///
  /// In en, this message translates to:
  /// **'Root'**
  String get roleRoot;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsNotificationsNote.
  ///
  /// In en, this message translates to:
  /// **'Check for past-due reminders in the background (about every 3 hours) and post a notification. Each reminder notifies once until it\'s resolved.'**
  String get settingsNotificationsNote;

  /// No description provided for @notifRemindersToggle.
  ///
  /// In en, this message translates to:
  /// **'Past-due reminders'**
  String get notifRemindersToggle;

  /// No description provided for @notifPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Notification permission is required. Enable it in system settings.'**
  String get notifPermissionDenied;

  /// No description provided for @notifReminderChannelName.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get notifReminderChannelName;

  /// No description provided for @notifReminderChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Past-due vehicle maintenance reminders'**
  String get notifReminderChannelDescription;

  /// No description provided for @notifReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminder past due'**
  String get notifReminderTitle;

  /// No description provided for @notifReminderBody.
  ///
  /// In en, this message translates to:
  /// **'{vehicle}: {description}'**
  String notifReminderBody(String vehicle, String description);

  /// No description provided for @settingsDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Bugs and ideas'**
  String get settingsDiagnostics;

  /// No description provided for @settingsDiagnosticsNote.
  ///
  /// In en, this message translates to:
  /// **'Report a bug with a recording of what the app was doing, or ask for a change or a new feature.'**
  String get settingsDiagnosticsNote;

  /// No description provided for @bugReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report a bug or an idea'**
  String get bugReportTitle;

  /// No description provided for @bugReportLogScreens.
  ///
  /// In en, this message translates to:
  /// **'Screens you open and buttons you press'**
  String get bugReportLogScreens;

  /// No description provided for @bugReportLogRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests to the server and its answers'**
  String get bugReportLogRequests;

  /// No description provided for @bugReportLogErrors.
  ///
  /// In en, this message translates to:
  /// **'Errors, including the ones you never see'**
  String get bugReportLogErrors;

  /// No description provided for @bugReportLogSetup.
  ///
  /// In en, this message translates to:
  /// **'App and server version, your phone, your units and date format'**
  String get bugReportLogSetup;

  /// No description provided for @bugReportLogNoKey.
  ///
  /// In en, this message translates to:
  /// **'Your API key or password'**
  String get bugReportLogNoKey;

  /// No description provided for @bugReportLogNoTyping.
  ///
  /// In en, this message translates to:
  /// **'The text you type'**
  String get bugReportLogNoTyping;

  /// No description provided for @bugReportLogNoAddress.
  ///
  /// In en, this message translates to:
  /// **'Your server address — only http or https, name or IP, and the port'**
  String get bugReportLogNoAddress;

  /// No description provided for @bugReportLogNoData.
  ///
  /// In en, this message translates to:
  /// **'Plates, notes, your records — only how long they were'**
  String get bugReportLogNoData;

  /// No description provided for @bugReportRequestNoData.
  ///
  /// In en, this message translates to:
  /// **'Nothing about your vehicles or your phone'**
  String get bugReportRequestNoData;

  /// Fuel tab summary pill: total energy drawn from the battery
  ///
  /// In en, this message translates to:
  /// **'Energy {value}'**
  String fuelPillEnergy(String value);

  /// Charging-session amount field; unit is kWh
  ///
  /// In en, this message translates to:
  /// **'Energy charged ({unit})'**
  String formEnergyLabel(String unit);

  /// No description provided for @statAvgConsumption.
  ///
  /// In en, this message translates to:
  /// **'Average Consumption'**
  String get statAvgConsumption;

  /// No description provided for @chartConsumption.
  ///
  /// In en, this message translates to:
  /// **'Consumption'**
  String get chartConsumption;

  /// Warning shown on the plan form when the item's progress is Done
  ///
  /// In en, this message translates to:
  /// **'This plan is done. LubeLogger\'s API refuses to store a finished plan, and every state it would accept sends it backwards — so it can be read and deleted here, but not edited. Change it on the planner board.'**
  String get planDoneReadOnly;

  /// No description provided for @syncTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get syncTitle;

  /// No description provided for @syncOffline.
  ///
  /// In en, this message translates to:
  /// **'The server isn\'t answering.'**
  String get syncOffline;

  /// Sync sheet: when the server was last reachable
  ///
  /// In en, this message translates to:
  /// **'Server last answered {time}.'**
  String syncLastContact(String time);

  /// No description provided for @syncPendingCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change waiting to be sent} other{{count} changes waiting to be sent}}'**
  String syncPendingCount(int count);

  /// No description provided for @syncNothingPending.
  ///
  /// In en, this message translates to:
  /// **'Everything you have saved is on the server.'**
  String get syncNothingPending;

  /// No description provided for @syncSendNow.
  ///
  /// In en, this message translates to:
  /// **'Send now'**
  String get syncSendNow;

  /// No description provided for @syncSending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get syncSending;

  /// No description provided for @syncSentResult.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change sent} other{{count} changes sent}}'**
  String syncSentResult(int count);

  /// No description provided for @syncStillOffline.
  ///
  /// In en, this message translates to:
  /// **'Still no answer from the server — they stay queued.'**
  String get syncStillOffline;

  /// No description provided for @syncAttempts.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 attempt} other{{count} attempts}}'**
  String syncAttempts(int count);

  /// No description provided for @syncRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Refused by the server'**
  String get syncRejectedTitle;

  /// No description provided for @syncRejectedExplain.
  ///
  /// In en, this message translates to:
  /// **'The server answered and turned these down, so sending them again would only repeat it. Read why, then dismiss.'**
  String get syncRejectedExplain;

  /// No description provided for @syncDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get syncDiscard;

  /// No description provided for @syncDiscardAll.
  ///
  /// In en, this message translates to:
  /// **'Discard all'**
  String get syncDiscardAll;

  /// A queued write, named by what it does; type is a record type
  ///
  /// In en, this message translates to:
  /// **'Add {type}'**
  String syncOpAdd(String type);

  /// No description provided for @syncOpUpdate.
  ///
  /// In en, this message translates to:
  /// **'Edit {type}'**
  String syncOpUpdate(String type);

  /// No description provided for @syncOpDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete {type}'**
  String syncOpDelete(String type);

  /// No description provided for @syncTypeVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get syncTypeVehicle;

  /// No description provided for @syncPendingTooltip.
  ///
  /// In en, this message translates to:
  /// **'Changes waiting to be sent'**
  String get syncPendingTooltip;

  /// No description provided for @syncOfflineTooltip.
  ///
  /// In en, this message translates to:
  /// **'No connection to the server'**
  String get syncOfflineTooltip;

  /// No description provided for @settingsOfflineSection.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get settingsOfflineSection;

  /// No description provided for @settingsBackgroundRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh in the background'**
  String get settingsBackgroundRefresh;

  /// No description provided for @settingsBackgroundRefreshSub.
  ///
  /// In en, this message translates to:
  /// **'Keeps the stored copy current, so the app opens on your records instead of a spinner.'**
  String get settingsBackgroundRefreshSub;

  /// No description provided for @settingsStoredData.
  ///
  /// In en, this message translates to:
  /// **'Stored data'**
  String get settingsStoredData;

  /// No description provided for @settingsStoredDataSize.
  ///
  /// In en, this message translates to:
  /// **'{size} on this phone'**
  String settingsStoredDataSize(String size);

  /// No description provided for @settingsClearStoredData.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get settingsClearStoredData;

  /// No description provided for @settingsStoredDataCleared.
  ///
  /// In en, this message translates to:
  /// **'Stored data cleared.'**
  String get settingsStoredDataCleared;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pl':
      return AppLocalizationsPl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
