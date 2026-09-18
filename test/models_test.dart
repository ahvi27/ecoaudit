import 'package:flutter_test/flutter_test.dart';
import 'package:ecoaudit/models.dart';

void main() {
  test('compliance score applies severity penalties', () {
    final inspection = Inspection(id: '1', facilityId: 'f', date: DateTime(2026), inspector: 'A', title: 'Test', findings: [
      Finding(id: '1', category: 'Waste', title: 'A', description: '', severity: Severity.high),
      Finding(id: '2', category: 'Air', title: 'B', description: '', severity: Severity.medium),
    ]);
    expect(inspection.score, 77);
    inspection.findings.first.resolved = true;
    expect(inspection.score, 92);
  });

  test('score cannot fall below zero', () {
    final findings = List.generate(10, (i) => Finding(id: '$i', category: 'Water', title: 'Issue', description: '', severity: Severity.critical));
    final inspection = Inspection(id: '1', facilityId: 'f', date: DateTime(2026), inspector: 'A', title: 'Test', findings: findings);
    expect(inspection.score, 0);
  });
}
