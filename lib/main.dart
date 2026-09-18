import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'app_store.dart';
import 'models.dart';
import 'report_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EcoAuditApp());
}

class EcoAuditApp extends StatefulWidget {
  const EcoAuditApp({super.key});
  @override
  State<EcoAuditApp> createState() => _EcoAuditAppState();
}

class _EcoAuditAppState extends State<EcoAuditApp> {
  final store = AppStore();
  @override
  void initState() {
    super.initState();
    store.load();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'EcoAudit',
        theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xff087f5b),
                brightness: Brightness.light),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xfff5f7f6),
            cardTheme:
                const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
            inputDecorationTheme: const InputDecorationTheme(
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white)),
        home: AnimatedBuilder(
            animation: store,
            builder: (_, __) => store.ready
                ? HomeShell(store: store)
                : const Scaffold(
                    body: Center(child: CircularProgressIndicator()))),
      );
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.store});
  final AppStore store;
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    final pages = [
      Dashboard(
          store: widget.store,
          openInspections: () => setState(() => index = 1)),
      InspectionsPage(store: widget.store),
      ActionsPage(store: widget.store),
      FacilitiesPage(store: widget.store)
    ];
    return Scaffold(
      body: SafeArea(child: pages[index]),
      bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (v) => setState(() => index = v),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.grid_view_rounded), label: 'Overview'),
            NavigationDestination(
                icon: Icon(Icons.fact_check_outlined), label: 'Inspections'),
            NavigationDestination(icon: Icon(Icons.task_alt), label: 'Actions'),
            NavigationDestination(
                icon: Icon(Icons.factory_outlined), label: 'Facilities'),
          ]),
    );
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader(this.title, {super.key, this.subtitle, this.trailing});
  final String title;
  final String? subtitle;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
      child: Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          if (subtitle != null)
            Text(subtitle!, style: TextStyle(color: Colors.grey.shade600))
        ])),
        if (trailing != null) trailing!
      ]));
}

class Dashboard extends StatelessWidget {
  const Dashboard(
      {super.key, required this.store, required this.openInspections});
  final AppStore store;
  final VoidCallback openInspections;
  @override
  Widget build(BuildContext context) {
    final average = store.inspections.isEmpty
        ? 0
        : store.inspections.fold<int>(0, (p, i) => p + i.score) ~/
            store.inspections.length;
    final findings = store.inspections
        .expand((i) => i.findings)
        .where((f) => !f.resolved)
        .length;
    final overdue = store.inspections
        .expand((i) => i.actions)
        .where((a) => a.overdue)
        .length;
    return RefreshIndicator(
        onRefresh: store.load,
        child: ListView(padding: const EdgeInsets.only(bottom: 24), children: [
          const PageHeader('EcoAudit',
              subtitle: 'Environmental compliance, clearly managed',
              trailing: CircleAvatar(child: Icon(Icons.eco))),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xff087f5b), Color(0xff0ca678)]),
                      borderRadius: BorderRadius.circular(24)),
                  child: Row(children: [
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          const Text('PORTFOLIO COMPLIANCE',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  letterSpacing: 1.2)),
                          const SizedBox(height: 8),
                          Text('$average%',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 42,
                                  fontWeight: FontWeight.w800)),
                          const Text('Average compliance score',
                              style: TextStyle(color: Colors.white70))
                        ])),
                    SizedBox(
                        width: 90,
                        height: 90,
                        child: CircularProgressIndicator(
                            value: average / 100,
                            strokeWidth: 10,
                            backgroundColor: Colors.white24,
                            color: Colors.white))
                  ]))),
          const SizedBox(height: 18),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Expanded(
                    child: MetricCard(
                        label: 'Facilities',
                        value: '${store.facilities.length}',
                        icon: Icons.factory_outlined)),
                const SizedBox(width: 10),
                Expanded(
                    child: MetricCard(
                        label: 'Open findings',
                        value: '$findings',
                        icon: Icons.warning_amber_rounded)),
                const SizedBox(width: 10),
                Expanded(
                    child: MetricCard(
                        label: 'Overdue',
                        value: '$overdue',
                        icon: Icons.schedule))
              ])),
          Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent inspections',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    TextButton(
                        onPressed: openInspections,
                        child: const Text('View all'))
                  ])),
          ...store.inspections.take(3).map((i) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: InspectionTile(store: store, inspection: i))),
          Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Text('Compliance by facility',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold))),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                  child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                          children: store.facilities.map((f) {
                        final audits = store.inspections
                            .where((i) => i.facilityId == f.id)
                            .toList();
                        final score = audits.isEmpty
                            ? 0
                            : audits.fold<int>(0, (p, i) => p + i.score) ~/
                                audits.length;
                        return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Expanded(
                                        child: Text(f.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis)),
                                    Text('$score%',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold))
                                  ]),
                                  const SizedBox(height: 6),
                                  LinearProgressIndicator(
                                      value: score / 100,
                                      minHeight: 8,
                                      borderRadius: BorderRadius.circular(8))
                                ]));
                      }).toList())))),
        ]));
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard(
      {super.key,
      required this.label,
      required this.value,
      required this.icon});
  final String label, value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(value,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(label,
                maxLines: 1,
                style: const TextStyle(fontSize: 11, color: Colors.black54))
          ])));
}

class InspectionsPage extends StatelessWidget {
  const InspectionsPage({super.key, required this.store});
  final AppStore store;
  @override
  Widget build(BuildContext context) => Column(children: [
        PageHeader('Inspections',
            subtitle: '${store.inspections.length} recorded',
            trailing: FilledButton.icon(
                onPressed: () => showInspectionForm(context, store),
                icon: const Icon(Icons.add),
                label: const Text('New'))),
        Expanded(
            child: store.inspections.isEmpty
                ? const Center(child: Text('No inspections yet'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: store.inspections.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, n) => InspectionTile(
                        store: store, inspection: store.inspections[n])))
      ]);
}

class InspectionTile extends StatelessWidget {
  const InspectionTile(
      {super.key, required this.store, required this.inspection});
  final AppStore store;
  final Inspection inspection;
  @override
  Widget build(BuildContext context) {
    final f = store.facilityFor(inspection.facilityId);
    final color = inspection.score >= 80
        ? Colors.green
        : inspection.score >= 60
            ? Colors.orange
            : Colors.red;
    return Card(
        child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => InspectionDetail(
                        store: store, inspection: inspection))),
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  CircleAvatar(
                      backgroundColor: color.withValues(alpha: .12),
                      child: Text('${inspection.score}',
                          style: TextStyle(
                              color: color, fontWeight: FontWeight.bold))),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(inspection.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        Text(f.name,
                            style: const TextStyle(color: Colors.black54)),
                        Text(DateFormat.yMMMd().format(inspection.date),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black45))
                      ])),
                  const Icon(Icons.chevron_right)
                ]))));
  }
}

class InspectionDetail extends StatelessWidget {
  const InspectionDetail(
      {super.key, required this.store, required this.inspection});
  final AppStore store;
  final Inspection inspection;
  @override
  Widget build(BuildContext context) {
    final facility = store.facilityFor(inspection.facilityId);
    return AnimatedBuilder(
        animation: store,
        builder: (_, __) => Scaffold(
            appBar: AppBar(title: const Text('Inspection'), actions: [
              IconButton(
                  tooltip: 'Export PDF',
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  onPressed: () async => Printing.sharePdf(
                      bytes: await ReportService.build(inspection, facility),
                      filename: 'ecoaudit-${inspection.id}.pdf'))
            ]),
            body: ListView(padding: const EdgeInsets.all(20), children: [
              Text(inspection.title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text(
                  '${facility.name} · ${DateFormat.yMMMd().format(inspection.date)}',
                  style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 18),
              Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(18)),
                  child: Row(children: [
                    Text('${inspection.score}%',
                        style: const TextStyle(
                            fontSize: 34, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 14),
                    const Expanded(
                        child: Text(
                            'Current compliance score\nUpdates automatically as findings are resolved.'))
                  ])),
              SectionTitle('Findings',
                  onAdd: () => showFindingForm(context, store, inspection)),
              if (inspection.findings.isEmpty)
                const EmptyCard('No findings recorded.'),
              ...inspection.findings.map((f) => FindingCard(f)),
              SectionTitle('Corrective actions',
                  onAdd: () => showActionForm(context, store, inspection)),
              if (inspection.actions.isEmpty)
                const EmptyCard('No actions assigned.'),
              ...inspection.actions.map((a) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                      onTap: () => store.cycleAction(a),
                      leading: Icon(
                          a.status == ActionStatus.closed
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: a.overdue ? Colors.red : Colors.green),
                      title: Text(a.title),
                      subtitle: Text(
                          '${a.owner} · Due ${DateFormat.MMMd().format(a.dueDate)}'),
                      trailing: Text(a.status.name,
                          style: const TextStyle(fontSize: 11))))),
            ])));
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, required this.onAdd});
  final String text;
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Row(children: [
        Expanded(
            child: Text(text,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold))),
        IconButton.filledTonal(onPressed: onAdd, icon: const Icon(Icons.add))
      ]));
}

class EmptyCard extends StatelessWidget {
  const EmptyCard(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
              child:
                  Text(text, style: const TextStyle(color: Colors.black54)))));
}

class FindingCard extends StatelessWidget {
  const FindingCard(this.finding, {super.key});
  final Finding finding;
  @override
  Widget build(BuildContext context) {
    final c = switch (finding.severity) {
      Severity.low => Colors.blue,
      Severity.medium => Colors.orange,
      Severity.high => Colors.deepOrange,
      Severity.critical => Colors.red
    };
    return Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (finding.photoPath != null)
                ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(File(finding.photoPath!),
                        width: 62, height: 62, fit: BoxFit.cover))
              else
                Container(
                    width: 8,
                    height: 62,
                    decoration: BoxDecoration(
                        color: c, borderRadius: BorderRadius.circular(8))),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(
                        '${finding.severity.name.toUpperCase()} · ${finding.category}',
                        style: TextStyle(
                            fontSize: 11,
                            color: c,
                            fontWeight: FontWeight.bold)),
                    Text(finding.title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(finding.description,
                        maxLines: 2, overflow: TextOverflow.ellipsis)
                  ]))
            ])));
  }
}

class ActionsPage extends StatelessWidget {
  const ActionsPage({super.key, required this.store});
  final AppStore store;
  @override
  Widget build(BuildContext context) {
    final actions = store.inspections.expand((i) => i.actions).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return Column(children: [
      PageHeader('Corrective actions',
          subtitle: 'Tap an action to update its status'),
      Expanded(
          child: actions.isEmpty
              ? const Center(child: Text('No actions assigned'))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: actions.length,
                  itemBuilder: (_, n) {
                    final a = actions[n];
                    return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                            onTap: () => store.cycleAction(a),
                            leading: CircleAvatar(
                                backgroundColor: a.overdue
                                    ? Colors.red.shade50
                                    : Colors.green.shade50,
                                child: Icon(
                                    a.status == ActionStatus.closed
                                        ? Icons.done
                                        : Icons.schedule,
                                    color:
                                        a.overdue ? Colors.red : Colors.green)),
                            title: Text(a.title),
                            subtitle: Text(
                                '${a.owner}\nDue ${DateFormat.yMMMd().format(a.dueDate)}'),
                            isThreeLine: true,
                            trailing: Chip(
                                label: Text(a.status.name,
                                    style: const TextStyle(fontSize: 10)))));
                  }))
    ]);
  }
}

class FacilitiesPage extends StatelessWidget {
  const FacilitiesPage({super.key, required this.store});
  final AppStore store;
  @override
  Widget build(BuildContext context) => Column(children: [
        PageHeader('Facilities',
            subtitle: '${store.facilities.length} managed sites',
            trailing: FilledButton.icon(
                onPressed: () => showFacilityForm(context, store),
                icon: const Icon(Icons.add),
                label: const Text('Add'))),
        Expanded(
            child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: store.facilities.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, n) {
                  final f = store.facilities[n];
                  final count = store.inspections
                      .where((i) => i.facilityId == f.id)
                      .length;
                  return Card(
                      child: ListTile(
                          contentPadding: const EdgeInsets.all(14),
                          leading: const CircleAvatar(
                              child: Icon(Icons.factory_outlined)),
                          title: Text(f.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${f.sector} · ${f.location}'),
                          trailing: Text('$count audits')));
                }))
      ]);
}

String id() => DateTime.now().microsecondsSinceEpoch.toString();
Future<void> showFacilityForm(BuildContext context, AppStore store) async {
  final name = TextEditingController(),
      sector = TextEditingController(),
      location = TextEditingController();
  await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
              title: const Text('Add facility'),
              content: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                    controller: name,
                    decoration:
                        const InputDecoration(labelText: 'Facility name')),
                const SizedBox(height: 10),
                TextField(
                    controller: sector,
                    decoration: const InputDecoration(labelText: 'Sector')),
                const SizedBox(height: 10),
                TextField(
                    controller: location,
                    decoration: const InputDecoration(labelText: 'Location'))
              ])),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () {
                      if (name.text.trim().isEmpty) return;
                      store.addFacility(Facility(
                          id: id(),
                          name: name.text.trim(),
                          sector: sector.text.trim(),
                          location: location.text.trim()));
                      Navigator.pop(ctx);
                    },
                    child: const Text('Save'))
              ]));
}

Future<void> showInspectionForm(BuildContext context, AppStore store) async {
  if (store.facilities.isEmpty) return;
  String facility = store.facilities.first.id;
  final title =
          TextEditingController(text: 'Environmental Compliance Inspection'),
      inspector = TextEditingController();
  await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
                  title: const Text('New inspection'),
                  content: SingleChildScrollView(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                    DropdownButtonFormField(
                        value: facility,
                        decoration:
                            const InputDecoration(labelText: 'Facility'),
                        items: store.facilities
                            .map((f) => DropdownMenuItem(
                                value: f.id, child: Text(f.name)))
                            .toList(),
                        onChanged: (v) => setLocal(() => facility = v!)),
                    const SizedBox(height: 10),
                    TextField(
                        controller: title,
                        decoration: const InputDecoration(
                            labelText: 'Inspection title')),
                    const SizedBox(height: 10),
                    TextField(
                        controller: inspector,
                        decoration:
                            const InputDecoration(labelText: 'Inspector'))
                  ])),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel')),
                    FilledButton(
                        onPressed: () {
                          if (inspector.text.trim().isEmpty) return;
                          store.addInspection(Inspection(
                              id: id(),
                              facilityId: facility,
                              date: DateTime.now(),
                              inspector: inspector.text.trim(),
                              title: title.text.trim()));
                          Navigator.pop(ctx);
                        },
                        child: const Text('Create'))
                  ])));
}

Future<void> showFindingForm(
    BuildContext context, AppStore store, Inspection inspection) async {
  final title = TextEditingController(), description = TextEditingController();
  String category = 'Waste';
  Severity severity = Severity.medium;
  String? photo;
  Position? position;
  await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
                  title: const Text('Record finding'),
                  content: SingleChildScrollView(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                    DropdownButtonFormField(
                        value: category,
                        decoration:
                            const InputDecoration(labelText: 'Category'),
                        items: [
                          'Air',
                          'Water',
                          'Wastewater',
                          'Waste',
                          'Energy',
                          'Safety',
                          'Permits'
                        ]
                            .map((e) =>
                                DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (v) => setLocal(() => category = v!)),
                    const SizedBox(height: 10),
                    DropdownButtonFormField(
                        value: severity,
                        decoration:
                            const InputDecoration(labelText: 'Severity'),
                        items: Severity.values
                            .map((e) =>
                                DropdownMenuItem(value: e, child: Text(e.name)))
                            .toList(),
                        onChanged: (v) => setLocal(() => severity = v!)),
                    const SizedBox(height: 10),
                    TextField(
                        controller: title,
                        decoration:
                            const InputDecoration(labelText: 'Finding title')),
                    const SizedBox(height: 10),
                    TextField(
                        controller: description,
                        maxLines: 3,
                        decoration:
                            const InputDecoration(labelText: 'Description')),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                          child: OutlinedButton.icon(
                              onPressed: () async {
                                final x = await ImagePicker().pickImage(
                                    source: ImageSource.camera,
                                    imageQuality: 70);
                                if (x != null) setLocal(() => photo = x.path);
                              },
                              icon: Icon(photo == null
                                  ? Icons.camera_alt_outlined
                                  : Icons.check),
                              label:
                                  Text(photo == null ? 'Photo' : 'Attached'))),
                      const SizedBox(width: 8),
                      Expanded(
                          child: OutlinedButton.icon(
                              onPressed: () async {
                                var permission =
                                    await Geolocator.checkPermission();
                                if (permission == LocationPermission.denied)
                                  permission =
                                      await Geolocator.requestPermission();
                                if (permission ==
                                        LocationPermission.whileInUse ||
                                    permission == LocationPermission.always) {
                                  final p =
                                      await Geolocator.getCurrentPosition();
                                  setLocal(() => position = p);
                                }
                              },
                              icon: Icon(position == null
                                  ? Icons.location_on_outlined
                                  : Icons.check),
                              label:
                                  Text(position == null ? 'GPS' : 'Captured')))
                    ])
                  ])),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel')),
                    FilledButton(
                        onPressed: () {
                          if (title.text.trim().isEmpty) return;
                          store.addFinding(
                              inspection,
                              Finding(
                                  id: id(),
                                  category: category,
                                  title: title.text.trim(),
                                  description: description.text.trim(),
                                  severity: severity,
                                  photoPath: photo,
                                  latitude: position?.latitude,
                                  longitude: position?.longitude));
                          Navigator.pop(ctx);
                        },
                        child: const Text('Save'))
                  ])));
}

Future<void> showActionForm(
    BuildContext context, AppStore store, Inspection inspection) async {
  final title = TextEditingController(), owner = TextEditingController();
  DateTime due = DateTime.now().add(const Duration(days: 14));
  await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
                  title: const Text('Assign action'),
                  content: Column(mainAxisSize: MainAxisSize.min, children: [
                    TextField(
                        controller: title,
                        decoration: const InputDecoration(
                            labelText: 'Corrective action')),
                    const SizedBox(height: 10),
                    TextField(
                        controller: owner,
                        decoration: const InputDecoration(
                            labelText: 'Responsible person')),
                    const SizedBox(height: 10),
                    ListTile(
                        tileColor: Colors.white,
                        title: const Text('Due date'),
                        subtitle: Text(DateFormat.yMMMd().format(due)),
                        trailing: const Icon(Icons.calendar_month),
                        onTap: () async {
                          final picked = await showDatePicker(
                              context: ctx,
                              initialDate: due,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now()
                                  .add(const Duration(days: 730)));
                          if (picked != null) setLocal(() => due = picked);
                        })
                  ]),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel')),
                    FilledButton(
                        onPressed: () {
                          if (title.text.trim().isEmpty) return;
                          store.addAction(
                              inspection,
                              CorrectiveAction(
                                  id: id(),
                                  title: title.text.trim(),
                                  owner: owner.text.trim(),
                                  dueDate: due));
                          Navigator.pop(ctx);
                        },
                        child: const Text('Assign'))
                  ])));
}
