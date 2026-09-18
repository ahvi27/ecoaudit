import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'models.dart';

class AppStore extends ChangeNotifier {
  final List<Facility> facilities = [];
  final List<Inspection> inspections = [];
  bool ready = false;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('ecoaudit_data');
    facilities.clear();
    inspections.clear();
    if (raw == null) {
      _seed();
      await save();
    } else {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      facilities.addAll(
          (data['facilities'] as List).map((e) => Facility.fromJson(e)));
      inspections.addAll(
          (data['inspections'] as List).map((e) => Inspection.fromJson(e)));
    }
    ready = true;
    notifyListeners();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ecoaudit_data', encodeData(facilities, inspections));
    notifyListeners();
  }

  void _seed() {
    facilities.addAll(const [
      Facility(
          id: 'f1',
          name: 'Green Valley Textiles',
          sector: 'Textile',
          location: 'Industrial Zone A'),
      Facility(
          id: 'f2',
          name: 'Nova Foods Processing',
          sector: 'Food & Beverage',
          location: 'Industrial Zone B'),
      Facility(
          id: 'f3',
          name: 'Apex Metal Works',
          sector: 'Manufacturing',
          location: 'Industrial Zone C'),
    ]);
    inspections.addAll([
      Inspection(
          id: 'i1',
          facilityId: 'f1',
          date: DateTime.now().subtract(const Duration(days: 7)),
          inspector: 'Demo Inspector',
          title: 'Quarterly Environmental Audit',
          findings: [
            Finding(
                id: 'x1',
                category: 'Wastewater',
                title: 'Missing flow log',
                description: 'Daily discharge log was not updated.',
                severity: Severity.medium),
            Finding(
                id: 'x2',
                category: 'Waste',
                title: 'Unlabelled container',
                description: 'Hazardous waste container requires a label.',
                severity: Severity.high),
          ],
          actions: [
            CorrectiveAction(
                id: 'a1',
                title: 'Label hazardous waste containers',
                owner: 'EHS Manager',
                dueDate: DateTime.now().add(const Duration(days: 5)))
          ]),
      Inspection(
          id: 'i2',
          facilityId: 'f2',
          date: DateTime.now().subtract(const Duration(days: 18)),
          inspector: 'Demo Inspector',
          title: 'Routine Compliance Check',
          findings: [
            Finding(
                id: 'x3',
                category: 'Air',
                title: 'Stack test record',
                description: 'Latest test certificate was unavailable.',
                severity: Severity.low),
          ]),
    ]);
  }

  Facility facilityFor(String id) => facilities.firstWhere((f) => f.id == id);
  Future<void> addFacility(Facility f) async {
    facilities.add(f);
    await save();
  }

  Future<void> addInspection(Inspection i) async {
    inspections.insert(0, i);
    await save();
  }

  Future<void> addFinding(Inspection i, Finding f) async {
    i.findings.add(f);
    await save();
  }

  Future<void> addAction(Inspection i, CorrectiveAction a) async {
    i.actions.add(a);
    await save();
  }

  Future<void> cycleAction(CorrectiveAction a) async {
    a.status = switch (a.status) {
      ActionStatus.open => ActionStatus.inProgress,
      ActionStatus.inProgress => ActionStatus.closed,
      ActionStatus.closed => ActionStatus.open
    };
    await save();
  }
}
