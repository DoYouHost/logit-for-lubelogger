// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Logit';

  @override
  String get connectToServer => 'Conectar con el servidor';

  @override
  String get setupIntro =>
      'Introduce la dirección de tu servidor LubeLogger y tu clave de API para empezar.';

  @override
  String get serverAddressLabel => 'Dirección del servidor';

  @override
  String get serverAddressHint => 'https://lubelogger.example.com';

  @override
  String get serverAddressHelper =>
      'URL completa de tu instancia de LubeLogger.';

  @override
  String get apiKeyExplain =>
      'Genera una clave de API en LubeLogger, en Ajustes. Recomendado: sin caducidad y con acceso limitado.';

  @override
  String get apiKeyLabel => 'Clave de API';

  @override
  String get apiKeyShow => 'Mostrar la clave';

  @override
  String get apiKeyHide => 'Ocultar la clave';

  @override
  String get connect => 'Conectar';

  @override
  String get connecting => 'Conectando…';

  @override
  String get tryDemo => 'Probar la demo';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get retry => 'Reintentar';

  @override
  String get comingSoon => 'Próximamente';

  @override
  String get garageEmpty =>
      'Aún no hay vehículos. Añade el primero para empezar.';

  @override
  String get garageLoadError =>
      'No se pudo cargar tu garaje. Desliza hacia abajo para reintentar.';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsUnits => 'Unidades';

  @override
  String get settingsCurrency => 'Moneda';

  @override
  String get settingsDistance => 'Distancia';

  @override
  String get settingsFuelEconomy => 'Consumo de combustible';

  @override
  String get settingsDateFormat => 'Formato de fecha';

  @override
  String get settingsDateSeparator => 'Separador de fecha';

  @override
  String get settingsServer => 'Servidor';

  @override
  String get settingsAbout => 'Acerca de';

  @override
  String get settingsStorageBase => 'Datos del servidor';

  @override
  String get baseMetric => 'Métrico';

  @override
  String get baseImperial => 'Imperial';

  @override
  String get baseImperialUk => 'Millas y litros (UK MPG)';

  @override
  String currencyAuto(String symbol) {
    return 'Automática ($symbol)';
  }

  @override
  String get settingsUnitsMetricNote =>
      'Indica las unidades en las que tu servidor LubeLogger guarda los valores (métrico = km y litros). Si en el servidor está activada la opción «Use UK MPG Calculation», elige Millas y litros (UK MPG). La aplicación convierte los valores a las unidades de visualización que elijas.';

  @override
  String get settingsVisibleTabs => 'Pestañas visibles';

  @override
  String get settingsVisibleTabsNote =>
      'Elige qué pestañas aparecen en la pantalla del vehículo y en el menú de añadir, y arrástralas para reordenarlas. El panel siempre se muestra primero.';

  @override
  String get dashLoadError =>
      'No se pudo cargar este vehículo. Desliza hacia abajo para reintentar.';

  @override
  String get statDistanceTraveled => 'Distancia recorrida';

  @override
  String get statTotalCost => 'Coste total';

  @override
  String get statAvgEconomy => 'Consumo medio';

  @override
  String get chartExpensesByType => 'Gastos por tipo';

  @override
  String get chartExpensesDistance => 'Gastos y distancia';

  @override
  String get chartRemindersByUrgency => 'Recordatorios por urgencia';

  @override
  String get chartFuelMileage => 'Consumo de combustible';

  @override
  String get chartNoDataInRange => 'Sin datos en este periodo';

  @override
  String get chartNoReminders => 'Sin recordatorios';

  @override
  String chartRemindersTotal(int count) {
    return '$count en total';
  }

  @override
  String get chartTotal => 'Total';

  @override
  String chartAverage(String value) {
    return 'media $value';
  }

  @override
  String chartQuarter(int quarter) {
    return 'T$quarter';
  }

  @override
  String get chartRangeTitle => 'Periodo de datos';

  @override
  String get chartRangeOneMonth => '1 mes';

  @override
  String get chartRangeThreeMonths => '3 meses';

  @override
  String get chartRangeSixMonths => '6 meses';

  @override
  String get chartRangeYear => '1 año';

  @override
  String get chartRangeCustom => 'Periodo personalizado';

  @override
  String get chartRangeOneMonthShort => '1 m';

  @override
  String get chartRangeThreeMonthsShort => '3 m';

  @override
  String get chartRangeSixMonthsShort => '6 m';

  @override
  String get chartRangeYearShort => '1 a';

  @override
  String get chartRangeDefault => 'predeterminado';

  @override
  String get chartRangeSettingsHint =>
      'Cambia el periodo predeterminado de todos los gráficos en Ajustes.';

  @override
  String chartRangeButton(String range) {
    return 'Periodo de datos: $range';
  }

  @override
  String get settingsCharts => 'Gráficos';

  @override
  String get settingsChartDefaultRange =>
      'Periodo predeterminado de los gráficos';

  @override
  String get settingsChartsNote =>
      'Puedes cambiar cada gráfico del panel del vehículo por separado.';

  @override
  String get settingsFuelForm => 'Repostajes';

  @override
  String get settingsFuelCalculated => 'Campo calculado';

  @override
  String get settingsFuelFormNote =>
      'Un repostaje nuevo pide primero los otros dos valores y calcula este. Para introducir otro par una sola vez, vacía uno de los campos.';

  @override
  String get fuelCalculatedPrice => 'Precio';

  @override
  String get fuelCalculatedAmount => 'Cantidad';

  @override
  String get fuelCalculatedCost => 'Coste total';

  @override
  String get legendExpenses => 'Gastos';

  @override
  String get legendDistance => 'Distancia';

  @override
  String get catService => 'Mantenimiento';

  @override
  String get catRepairs => 'Reparaciones';

  @override
  String get catUpgrades => 'Mejoras';

  @override
  String get catFuel => 'Combustible';

  @override
  String get catTax => 'Impuestos';

  @override
  String get catSupply => 'Suministros';

  @override
  String get catPlan => 'Planificador';

  @override
  String get catReminder => 'Recordatorios';

  @override
  String get catNote => 'Notas';

  @override
  String get catEquipment => 'Equipamiento';

  @override
  String get planPriorityCritical => 'Crítica';

  @override
  String get planPriorityNormal => 'Normal';

  @override
  String get planPriorityLow => 'Baja';

  @override
  String get planProgressBacklog => 'Pendiente';

  @override
  String get planProgressInProgress => 'En curso';

  @override
  String get planProgressTesting => 'En pruebas';

  @override
  String get planProgressDone => 'Hecho';

  @override
  String get equipmentEquipped => 'Montado';

  @override
  String get equipmentRemoved => 'Desmontado';

  @override
  String get notePinned => 'Fijada';

  @override
  String cardAttachments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archivos adjuntos',
      one: '$count archivo adjunto',
    );
    return '$_temp0';
  }

  @override
  String get cardHasNote => 'Contiene una nota';

  @override
  String get tabDashboard => 'Panel';

  @override
  String get tabOdometer => 'Cuentakilómetros';

  @override
  String get colDate => 'Fecha';

  @override
  String get colOdometer => 'Cuentakilómetros';

  @override
  String get colDescription => 'Descripción';

  @override
  String get colCost => 'Coste';

  @override
  String get recordsEmpty => 'Aún no hay registros.';

  @override
  String get recordsNoMatches => 'Ningún registro coincide.';

  @override
  String get recordsSearchHint => 'Buscar';

  @override
  String get recordsSearchClear => 'Borrar búsqueda';

  @override
  String get recordsSortBy => 'Ordenar por';

  @override
  String get recordsSortAscending => 'Ascendente';

  @override
  String get recordsSortDescending => 'Descendente';

  @override
  String get recordsClearFilters => 'Borrar filtros';

  @override
  String get colUrgency => 'Urgencia';

  @override
  String get colDistance => 'Distancia';

  @override
  String fuelPillRecords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count registros',
      one: '$count registro',
    );
    return '$_temp0';
  }

  @override
  String fuelPillAvg(String value) {
    return 'Media $value';
  }

  @override
  String fuelPillMin(String value) {
    return 'Mín. $value';
  }

  @override
  String fuelPillMax(String value) {
    return 'Máx. $value';
  }

  @override
  String fuelPillDistance(String value) {
    return 'Distancia $value';
  }

  @override
  String fuelPillFuel(String value) {
    return 'Combustible $value';
  }

  @override
  String fuelPillCost(String value) {
    return 'Coste $value';
  }

  @override
  String get addRecordTitle => 'Añadir registro';

  @override
  String addRecordHidden(int count) {
    return 'Elementos ocultos ($count)';
  }

  @override
  String get formFuelTitle => 'Añadir repostaje';

  @override
  String get formFuelEditTitle => 'Editar repostaje';

  @override
  String get formOdometerTitle => 'Añadir lectura del cuentakilómetros';

  @override
  String get formOdometerEditTitle => 'Editar lectura del cuentakilómetros';

  @override
  String get formServiceTitle => 'Añadir registro de mantenimiento';

  @override
  String get formServiceEditTitle => 'Editar registro de mantenimiento';

  @override
  String get formRepairTitle => 'Añadir reparación';

  @override
  String get formRepairEditTitle => 'Editar reparación';

  @override
  String get formUpgradeTitle => 'Añadir mejora';

  @override
  String get formUpgradeEditTitle => 'Editar mejora';

  @override
  String get formTaxTitle => 'Añadir impuesto';

  @override
  String get formTaxEditTitle => 'Editar impuesto';

  @override
  String get formSupplyTitle => 'Añadir suministro';

  @override
  String get formSupplyEditTitle => 'Editar suministro';

  @override
  String get formSupplyPartNumber => 'Número de pieza (opcional)';

  @override
  String get formSupplyPartSupplier => 'Proveedor (opcional)';

  @override
  String get formSupplyQuantity => 'Cantidad';

  @override
  String get formPlanTitle => 'Añadir elemento al planificador';

  @override
  String get formPlanEditTitle => 'Editar elemento del planificador';

  @override
  String get formPlanType => 'Tipo';

  @override
  String get formPlanPriority => 'Prioridad';

  @override
  String get formPlanProgress => 'Progreso';

  @override
  String get formReminderTitle => 'Añadir recordatorio';

  @override
  String get formReminderEditTitle => 'Editar recordatorio';

  @override
  String get formReminderMetric => 'Recordar por';

  @override
  String get formReminderMetricDate => 'Fecha';

  @override
  String get formReminderMetricOdometer => 'Cuentakilómetros';

  @override
  String get formReminderMetricBoth => 'Fecha y cuentakilómetros';

  @override
  String get formReminderDueDate => 'Fecha de vencimiento';

  @override
  String formReminderDueOdometer(String unit) {
    return 'Cuentakilómetros al vencimiento ($unit)';
  }

  @override
  String get formNoteTitle => 'Añadir nota';

  @override
  String get formNoteEditTitle => 'Editar nota';

  @override
  String get formNoteTitleLabel => 'Título';

  @override
  String get formNoteBodyLabel => 'Nota';

  @override
  String get formNotePinned => 'Fijada';

  @override
  String get formEquipmentTitle => 'Añadir equipamiento';

  @override
  String get formEquipmentEditTitle => 'Editar equipamiento';

  @override
  String get formEquipmentNameLabel => 'Nombre';

  @override
  String get formEquipmentEquipped => 'Montado';

  @override
  String get formVehicleTitle => 'Añadir vehículo';

  @override
  String get formVehicleEditTitle => 'Editar vehículo';

  @override
  String get formVehicleYear => 'Año';

  @override
  String get formVehicleMake => 'Marca';

  @override
  String get formVehicleModel => 'Modelo';

  @override
  String get formVehicleLicensePlate => 'Matrícula';

  @override
  String get formVehicleFuelType => 'Tipo de combustible';

  @override
  String get formVehicleUseHours =>
      'Registrar horas de motor en lugar del cuentakilómetros';

  @override
  String get formVehicleOdometerOptional => 'Cuentakilómetros opcional';

  @override
  String get fuelTypeGasoline => 'Gasolina';

  @override
  String get fuelTypeDiesel => 'Diésel';

  @override
  String get fuelTypeElectric => 'Eléctrico';

  @override
  String get vehicleAdded => 'Vehículo añadido';

  @override
  String get vehicleAddError =>
      'No se pudo añadir el vehículo. Inténtalo de nuevo.';

  @override
  String get vehicleUpdated => 'Vehículo actualizado';

  @override
  String get vehicleUpdateError =>
      'No se pudo guardar el vehículo. Inténtalo de nuevo.';

  @override
  String get vehicleDeleted => 'Vehículo eliminado';

  @override
  String get vehicleDeleteError =>
      'No se pudo eliminar el vehículo. Inténtalo de nuevo.';

  @override
  String get confirmDeleteVehicleTitle => '¿Eliminar este vehículo?';

  @override
  String get confirmDeleteVehicleMessage =>
      'Se eliminarán de forma permanente el vehículo y todos sus registros. Esta acción no se puede deshacer.';

  @override
  String confirmDeleteVehicleFinalTitle(String vehicle) {
    return '¿Eliminar $vehicle de forma permanente?';
  }

  @override
  String get confirmDeleteVehicleFinalMessage =>
      'Esta es tu última oportunidad para cancelar. El vehículo y todos sus registros desaparecerán para siempre.';

  @override
  String get actionDeletePermanently => 'Eliminar de forma permanente';

  @override
  String get vehicleDeleteUnsupportedTitle =>
      'Se requiere actualizar el servidor';

  @override
  String vehicleDeleteUnsupportedMessage(String required, String current) {
    return 'Eliminar un vehículo requiere LubeLogger $required o posterior, pero tu servidor ejecuta la versión $current. Actualiza el servidor para usar esta función.';
  }

  @override
  String get actionOk => 'Aceptar';

  @override
  String get actionEdit => 'Editar';

  @override
  String formOdometerLabel(String unit) {
    return 'Lectura del cuentakilómetros ($unit)';
  }

  @override
  String formOdometerLast(String value) {
    return 'Última lectura: $value';
  }

  @override
  String formOdometerBackwards(String value) {
    return 'Por debajo de la última lectura ($value).';
  }

  @override
  String get formOdometerBackwardsTitle => 'La lectura retrocede';

  @override
  String formOdometerBackwardsMessage(String value) {
    return 'Esta lectura es inferior a la última ($value). Un cuentakilómetros normalmente solo aumenta. ¿Guardarla de todos modos?';
  }

  @override
  String get actionSaveAnyway => 'Guardar de todos modos';

  @override
  String formFuelLabel(String unit) {
    return 'Combustible repostado ($unit)';
  }

  @override
  String formFuelPriceLabel(String unit) {
    return 'Precio del combustible (por $unit)';
  }

  @override
  String formEnergyPriceLabel(String unit) {
    return 'Precio de la energía (por $unit)';
  }

  @override
  String get formFillToFull => 'Depósito lleno';

  @override
  String get formMissedFuelUp => 'Repostaje omitido (ignorar el consumo)';

  @override
  String get formTagsOptional => 'Etiquetas (opcional)';

  @override
  String get formNotesOptional => 'Notas (opcional)';

  @override
  String get attachmentsLabel => 'Archivos adjuntos (opcional)';

  @override
  String get attachmentAddButton => 'Añadir archivo';

  @override
  String get attachmentUploadError =>
      'No se pudo subir el archivo. Inténtalo de nuevo.';

  @override
  String attachmentUploadRejected(String size, int status) {
    return 'El servidor rechazó esta subida ($size MB, HTTP $status). Es probable que el archivo sea demasiado grande para el servidor o para un proxy situado delante.';
  }

  @override
  String attachmentUploadInterrupted(String size) {
    return 'La subida se interrumpió ($size MB). Con una conexión lenta, puede que un archivo grande no llegue.';
  }

  @override
  String get attachmentOpenError => 'No se pudo abrir el archivo.';

  @override
  String get extraFieldsLabel => 'Campos personalizados';

  @override
  String get formStateOfCharge => 'Nivel de carga';

  @override
  String formStateOfChargeRange(int start, int end) {
    return '$start % → $end %';
  }

  @override
  String get quickActionAddFuel => 'Añadir repostaje';

  @override
  String get quickActionAddOdometer => 'Añadir lectura';

  @override
  String get quickActionSelectVehicle => 'Seleccionar vehículo';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionAdd => 'Añadir';

  @override
  String get actionSave => 'Guardar';

  @override
  String get actionDelete => 'Eliminar';

  @override
  String get validationRequired => 'Obligatorio';

  @override
  String get validationNumber => 'Introduce un número válido';

  @override
  String get recordAdded => 'Registro añadido';

  @override
  String get recordAddError =>
      'No se pudo añadir el registro. Inténtalo de nuevo.';

  @override
  String get recordUpdated => 'Registro actualizado';

  @override
  String get recordUpdateError =>
      'No se pudo guardar el registro. Inténtalo de nuevo.';

  @override
  String get recordDeleted => 'Registro eliminado';

  @override
  String get recordDeleteError =>
      'No se pudo eliminar el registro. Inténtalo de nuevo.';

  @override
  String get confirmDeleteTitle => '¿Eliminar este registro?';

  @override
  String get confirmDeleteMessage => 'Esta acción no se puede deshacer.';

  @override
  String get urgencyNotUrgent => 'No urgente';

  @override
  String get urgencyUrgent => 'Urgente';

  @override
  String get urgencyVeryUrgent => 'Muy urgente';

  @override
  String get urgencyPastDue => 'Vencido';

  @override
  String signedInAs(String name) {
    return 'Sesión iniciada como $name';
  }

  @override
  String get errMissingUrl => 'Introduce la dirección del servidor.';

  @override
  String get errMissingApiKey => 'Introduce tu clave de API.';

  @override
  String get errServerUnreachable =>
      'No se puede conectar con el servidor. Comprueba la dirección y tu red.';

  @override
  String get errUnauthorized =>
      'Falló la autenticación o la clave no tiene el permiso necesario.';

  @override
  String get errForbidden => 'No tienes permiso para realizar esta acción.';

  @override
  String errBadResponse(int status) {
    return 'Respuesta inesperada del servidor (HTTP $status).';
  }

  @override
  String get errUnsupportedByServer =>
      'Tu servidor LubeLogger es demasiado antiguo para esta acción. Actualízalo para usarla.';

  @override
  String get errBadCertificate =>
      'No se pudo verificar el certificado de seguridad del servidor.';

  @override
  String get errConnection => 'Error de conexión. Inténtalo de nuevo.';

  @override
  String get errMalformedResponse =>
      'No se pudo interpretar la respuesta del servidor.';

  @override
  String get errInvalidCredentials =>
      'Nombre de usuario o contraseña no válidos.';

  @override
  String get errApiKeyRejected => 'El servidor rechazó la clave de API.';

  @override
  String appVersion(String version, String build) {
    return 'Versión $version ($build)';
  }

  @override
  String get openSourceLicenses => 'Licencias de código abierto';

  @override
  String serverVersionLabel(String version) {
    return 'Versión del servidor $version';
  }

  @override
  String updateAvailable(String version) {
    return 'Actualización disponible: $version';
  }

  @override
  String get settingsBackup => 'Crear copia de seguridad';

  @override
  String get backupCreated => 'Copia de seguridad creada en el servidor.';

  @override
  String get backupError =>
      'No se pudo crear la copia de seguridad. Inténtalo de nuevo.';

  @override
  String get roleAdmin => 'Administrador';

  @override
  String get roleRoot => 'Root';

  @override
  String get settingsNotifications => 'Notificaciones';

  @override
  String get settingsNotificationsNote =>
      'Comprueba en segundo plano (aproximadamente cada 3 horas) si hay recordatorios vencidos y envía una notificación. Cada recordatorio avisa una sola vez, hasta que se resuelve.';

  @override
  String get notifRemindersToggle => 'Recordatorios vencidos';

  @override
  String get notifPermissionDenied =>
      'Se necesita el permiso de notificaciones. Actívalo en los ajustes del sistema.';

  @override
  String get notifReminderChannelName => 'Recordatorios';

  @override
  String get notifReminderChannelDescription =>
      'Recordatorios de mantenimiento de vehículos vencidos';

  @override
  String get notifReminderTitle => 'Recordatorio vencido';

  @override
  String notifReminderBody(String vehicle, String description) {
    return '$vehicle: $description';
  }

  @override
  String get settingsDiagnostics => 'Errores e ideas';

  @override
  String get settingsDiagnosticsNote =>
      'Informa de un error con una grabación de lo que hacía la aplicación, o pide un cambio o una función nueva.';

  @override
  String get bugReportTitle => 'Informar de un error o una idea';

  @override
  String get bugReportLogScreens =>
      'Las pantallas que abres y los botones que pulsas';

  @override
  String get bugReportLogRequests =>
      'Las peticiones al servidor y sus respuestas';

  @override
  String get bugReportLogErrors => 'Los errores, incluidos los que nunca ves';

  @override
  String get bugReportLogSetup =>
      'La versión de la aplicación y del servidor, tu teléfono, tus unidades y tu formato de fecha';

  @override
  String get bugReportLogNoKey => 'Tu clave de API o contraseña';

  @override
  String get bugReportLogNoTyping => 'El texto que escribes';

  @override
  String get bugReportLogNoAddress =>
      'La dirección de tu servidor — solo http o https, nombre o IP, y el puerto';

  @override
  String get bugReportLogNoData =>
      'Matrículas, notas, tus registros — solo su longitud';

  @override
  String get bugReportRequestNoData =>
      'Nada sobre tus vehículos ni sobre tu teléfono';

  @override
  String fuelPillEnergy(String value) {
    return 'Energía $value';
  }

  @override
  String formEnergyLabel(String unit) {
    return 'Energía cargada ($unit)';
  }

  @override
  String get statAvgConsumption => 'Consumo medio';

  @override
  String get chartConsumption => 'Consumo';

  @override
  String get planDoneReadOnly =>
      'Este plan está terminado. La API de LubeLogger no admite guardar un plan terminado, y cualquier estado que acepte lo haría retroceder, así que aquí solo se puede leer y eliminar, pero no editar. Cámbialo en el tablero del planificador.';

  @override
  String get syncTitle => 'Sincronización';

  @override
  String get syncOffline => 'El servidor no responde.';

  @override
  String syncLastContact(String time) {
    return 'Última respuesta del servidor: $time.';
  }

  @override
  String syncPendingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cambios pendientes de enviar',
      one: '$count cambio pendiente de enviar',
    );
    return '$_temp0';
  }

  @override
  String get syncNothingPending =>
      'Todo lo que has guardado está en el servidor.';

  @override
  String get syncSendNow => 'Enviar ahora';

  @override
  String get syncSending => 'Enviando…';

  @override
  String syncSentResult(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cambios enviados',
      one: '$count cambio enviado',
    );
    return '$_temp0';
  }

  @override
  String get syncStillOffline =>
      'El servidor sigue sin responder — se quedan en la cola.';

  @override
  String syncAttempts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count intentos',
      one: '$count intento',
    );
    return '$_temp0';
  }

  @override
  String get syncRejectedTitle => 'Rechazado por el servidor';

  @override
  String get syncRejectedExplain =>
      'El servidor respondió y rechazó estos cambios, así que volver a enviarlos solo repetiría el error. Lee el motivo y descártalos.';

  @override
  String get syncDiscard => 'Descartar';

  @override
  String get syncDiscardAll => 'Descartar todo';

  @override
  String syncOpAdd(String type) {
    return 'Añadir: $type';
  }

  @override
  String syncOpUpdate(String type) {
    return 'Editar: $type';
  }

  @override
  String syncOpDelete(String type) {
    return 'Eliminar: $type';
  }

  @override
  String get syncTypeVehicle => 'Vehículo';

  @override
  String get syncPendingTooltip => 'Cambios pendientes de enviar';

  @override
  String get syncOfflineTooltip => 'Sin conexión con el servidor';

  @override
  String get settingsOfflineSection => 'Sin conexión';

  @override
  String get settingsBackgroundRefresh => 'Actualizar en segundo plano';

  @override
  String get settingsBackgroundRefreshSub =>
      'Mantiene al día la copia guardada, para que la aplicación se abra directamente con tus registros en lugar de con un indicador de carga.';

  @override
  String get settingsStoredData => 'Datos guardados';

  @override
  String settingsStoredDataSize(String size) {
    return '$size en este teléfono';
  }

  @override
  String get settingsClearStoredData => 'Borrar';

  @override
  String get settingsStoredDataCleared => 'Datos guardados borrados.';
}
