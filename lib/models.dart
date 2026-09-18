import 'dart:convert';

enum Severity { low, medium, high, critical }

enum ActionStatus { open, inProgress, closed }

class Facility {
  const Facility(
      {required this.id,
      required this.name,
      required this.sector,
      required this.location});
  final String id;
  final String name;
  final String sector;
  final String location;
  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'sector': sector, 'location': location};
  factory Facility.fromJson(Map<String, dynamic> j) => Facility(
      id: j['id'],
      name: j['name'],
      sector: j['sector'],
      location: j['location']);
}

class Finding {
  Finding({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.severity,
    this.photoPath,
    this.latitude,
    this.longitude,
    this.resolved = false,
  });
  final String id;
  final String category;
  final String title;
  final String description;
  final Severity severity;
  final String? photoPath;
  final double? latitude;
  final double? longitude;
  bool resolved;
  int get penalty => switch (severity) {
        Severity.low => 4,
        Severity.medium => 8,
        Severity.high => 15,
        Severity.critical => 25
      };
  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'title': title,
        'description': description,
        'severity': severity.name,
        'photoPath': photoPath,
        'latitude': latitude,
        'longitude': longitude,
        'resolved': resolved,
      };
  factory Finding.fromJson(Map<String, dynamic> j) => Finding(
        id: j['id'],
        category: j['category'],
        title: j['title'],
        description: j['description'],
        severity: Severity.values.byName(j['severity']),
        photoPath: j['photoPath'],
        latitude: (j['latitude'] as num?)?.toDouble(),
        longitude: (j['longitude'] as num?)?.toDouble(),
        resolved: j['resolved'] ?? false,
      );
}

class CorrectiveAction {
  CorrectiveAction(
      {required this.id,
      required this.title,
      required this.owner,
      required this.dueDate,
      this.status = ActionStatus.open});
  final String id;
  final String title;
  final String owner;
  final DateTime dueDate;
  ActionStatus status;
  bool get overdue =>
      status != ActionStatus.closed && dueDate.isBefore(DateTime.now());
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'owner': owner,
        'dueDate': dueDate.toIso8601String(),
        'status': status.name
      };
  factory CorrectiveAction.fromJson(Map<String, dynamic> j) => CorrectiveAction(
      id: j['id'],
      title: j['title'],
      owner: j['owner'],
      dueDate: DateTime.parse(j['dueDate']),
      status: ActionStatus.values.byName(j['status']));
}

class Inspection {
  Inspection(
      {required this.id,
      required this.facilityId,
      required this.date,
      required this.inspector,
      required this.title,
      List<Finding>? findings,
      List<CorrectiveAction>? actions})
      : findings = findings ?? [],
        actions = actions ?? [];
  final String id;
  final String facilityId;
  final DateTime date;
  final String inspector;
  final String title;
  final List<Finding> findings;
  final List<CorrectiveAction> actions;
  int get score => (100 -
          findings
              .where((f) => !f.resolved)
              .fold<int>(0, (p, f) => p + f.penalty))
      .clamp(0, 100);
  Map<String, dynamic> toJson() => {
        'id': id,
        'facilityId': facilityId,
        'date': date.toIso8601String(),
        'inspector': inspector,
        'title': title,
        'findings': findings.map((e) => e.toJson()).toList(),
        'actions': actions.map((e) => e.toJson()).toList()
      };
  factory Inspection.fromJson(Map<String, dynamic> j) => Inspection(
      id: j['id'],
      facilityId: j['facilityId'],
      date: DateTime.parse(j['date']),
      inspector: j['inspector'],
      title: j['title'],
      findings:
          (j['findings'] as List).map((e) => Finding.fromJson(e)).toList(),
      actions: (j['actions'] as List)
          .map((e) => CorrectiveAction.fromJson(e))
          .toList());
}

String encodeData(List<Facility> facilities, List<Inspection> inspections) =>
    jsonEncode({
      'facilities': facilities.map((e) => e.toJson()).toList(),
      'inspections': inspections.map((e) => e.toJson()).toList()
    });
