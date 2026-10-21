import 'package:app_util/app_util.dart';

import '../api/endpoints.dart';
import 'attachment.dart';
import 'extra_field.dart';

/// A service / repair / upgrade / tax record from `GET /api/vehicle/X`. These
/// four share the `GenericRecordExportModel` shape (date, odometer, description,
/// cost, notes, tags); tax records carry no odometer, so [odometer] is null for
/// them. All fields arrive as strings on the wire (see the API contract).
class VehicleRecord {
  const VehicleRecord({
    required this.id,
    required this.date,
    required this.odometer,
    required this.description,
    required this.cost,
    required this.notes,
    required this.tags,
    this.files = const [],
    this.extraFields = const [],
  });

  factory VehicleRecord.fromJson(Map<String, dynamic> json) => VehicleRecord(
    id: toInt(json['id']),
    date: calendarDateFromJson(json['date']),
    // Tax records omit odometer; a "0" reading is treated as absent too.
    odometer: () {
      final o = toDouble(json['odometer']);
      return o > 0 ? o : null;
    }(),
    description: (json['description'] as String?) ?? '',
    cost: toDouble(json['cost']),
    notes: (json['notes'] as String?) ?? '',
    tags: (json['tags'] as String?) ?? '',
    files: Attachment.listFrom(json['files']),
    extraFields: ExtraField.listFrom(json['extraFields']),
  );

  final int id;
  final DateTime? date;
  final double? odometer;
  final String description;
  final double cost;
  final String notes;
  final String tags;
  final List<Attachment> files;
  final List<ExtraField> extraFields;
}

/// The four generic (date + cost) record types, each mapping to its list
/// endpoint. Fuel and odometer have their own richer models/endpoints.
enum RecordKind {
  service(Endpoints.serviceRecords, hasOdometer: true, editable: true),
  repair(Endpoints.repairRecords, hasOdometer: true, editable: true),
  upgrade(Endpoints.upgradeRecords, hasOdometer: true, editable: true),
  tax(Endpoints.taxRecords, hasOdometer: false, editable: true);

  const RecordKind(
    this.endpoint, {
    required this.hasOdometer,
    this.editable = false,
  });

  final String endpoint;

  /// Tax records have no odometer column; the others do.
  final bool hasOdometer;

  /// Whether add/edit/delete forms are wired for this kind. Flipped on per type
  /// as its form lands (service first); the FAB and record cards only offer
  /// editing when true.
  final bool editable;

  ExtraFieldRecordType get extraFieldType => switch (this) {
    RecordKind.service => ExtraFieldRecordType.service,
    RecordKind.repair => ExtraFieldRecordType.repair,
    RecordKind.upgrade => ExtraFieldRecordType.upgrade,
    RecordKind.tax => ExtraFieldRecordType.tax,
  };

  // Uniform CRUD paths under the list [endpoint] (see docs/api-records.md):
  // all four types share the same add/update/delete route shape.
  String get addEndpoint => '$endpoint/add';
  String get updateEndpoint => '$endpoint/update';
  String get deleteEndpoint => '$endpoint/delete';
}
