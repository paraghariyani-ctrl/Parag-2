import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:url_launcher/url_launcher.dart';

const roles = ['Candid', 'Cinematographer', 'T. Photo', 'T. Video', 'Drone', 'Helper'];

class TeamMember {
  String id, name, phone, role;
  TeamMember({required this.id, required this.name, required this.phone, required this.role});
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'phone': phone, 'role': role};
  factory TeamMember.fromJson(Map<String, dynamic> j) => TeamMember(
    id: '${j['id'] ?? ''}', name: '${j['name'] ?? ''}', phone: '${j['phone'] ?? ''}', role: '${j['role'] ?? 'Helper'}');
}

class EventData {
  String id, name, client, phone, venue, time, notes, type;
  DateTime date;
  Map<String, List<String>> assignments;
  EventData({
    required this.id, required this.name, required this.client, required this.phone,
    required this.venue, required this.time, required this.notes, required this.type,
    required this.date, required this.assignments,
  });
  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'client': client, 'phone': phone, 'venue': venue,
    'time': time, 'notes': notes, 'type': type, 'date': date.toIso8601String(),
    'assignments': assignments,
  };
  factory EventData.fromJson(Map<String, dynamic> j) {
    final raw = Map<String, dynamic>.from(j['assignments'] ?? {});
    final a = <String, List<String>>{};
    for (final r in roles) {
      a[r] = List<String>.from(raw[r] ?? const []);
    }
    return EventData(
      id: '${j['id'] ?? ''}', name: '${j['name'] ?? ''}', client: '${j['client'] ?? ''}',
      phone: '${j['phone'] ?? ''}', venue: '${j['venue'] ?? ''}', time: '${j['time'] ?? ''}',
      notes: '${j['notes'] ?? ''}', type: '${j['type'] ?? 'Wedding'}',
      date: DateTime.tryParse('${j['date'] ?? ''}') ?? DateTime.now(), assignments: a,
    );
  }
}

class PHFApp extends StatefulWidget {
  const PHFApp({super.key});
  @override State<PHFApp> createState() => _PHFAppState();
}
class _PHFAppState extends State<PHFApp> {
  bool dark = false;
  @override void initState() { super.initState(); _loadDark(); }
  Future<void> _loadDark() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() => dark = p.getBool('dark') ?? false);
  }
  Future<void> toggle() async {
    final p = await SharedPreferences.getInstance();
    setState(() => dark = !dark);
    await p.setBool('dark', dark);
  }
  @override Widget build(BuildContext c) => MaterialApp(
    debugShowCheckedModeBanner: false, title: 'PHF', themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF6C3FF5)),
    darkTheme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF8B63FF), brightness: Brightness.dark),
    home: PHFHome(dark: dark, onDark: toggle),
  );
}

class PHFHome extends StatefulWidget {
  final bool dark;
  final VoidCallback onDark;
  const PHFHome({super.key, required this.dark, required this.onDark});
  @override State<PHFHome> createState() => _PHFHomeState();
}

class _PHFHomeState extends State<PHFHome> {
  int tab = 0;
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime selected = DateTime.now();
  List<EventData> events = [];
  List<TeamMember> team = [];
  String search = '';

  @override void initState() { super.initState(); load(); }

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final es = (p.getStringList('events') ?? []).map((x) {
      try { return EventData.fromJson(jsonDecode(x)); } catch (_) { return null; }
    }).whereType<EventData>().toList();
    final ts = (p.getStringList('team') ?? []).map((x) {
      try { return TeamMember.fromJson(jsonDecode(x)); } catch (_) { return null; }
    }).whereType<TeamMember>().toList();
    if (mounted) {
      setState(() {
        events = es;
        team = ts;
      });
    }
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList('events', events.map((e) => jsonEncode(e.toJson())).toList());
    await p.setStringList('team', team.map((e) => jsonEncode(e.toJson())).toList());
  }

  bool same(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
  List<EventData> dayEvents(DateTime d) => events.where((e) => same(e.date, d)).toList();
  String mon(int m) => const ['', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'][m];

  @override Widget build(BuildContext c) {
    final pages = [calendarPage(), eventsPage(), teamPage(), contactsPage(), morePage()];
    return Scaffold(
      body: SafeArea(child: pages[tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab, onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Calendar'),
          NavigationDestination(icon: Icon(Icons.event_outlined), selectedIcon: Icon(Icons.event), label: 'Events'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Team'),
          NavigationDestination(icon: Icon(Icons.contacts_outlined), selectedIcon: Icon(Icons.contacts), label: 'Contacts'),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }

  Widget top(String title, {List<Widget> actions = const []}) => Padding(
    padding: const EdgeInsets.fromLTRB(10, 8, 8, 4),
    child: Row(children: [
      IconButton(onPressed: () {}, icon: const Icon(Icons.menu)),
      Expanded(child: Center(child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)))),
      ...actions,
    ]),
  );

  Widget calendarPage() {
    final first = DateTime(month.year, month.month, 1);
    final count = DateTime(month.year, month.month + 1, 0).day;
    final offset = first.weekday % 7;
    final cells = ((offset + count + 6) ~/ 7) * 7;
    return Column(children: [
      top('Dashboard', actions: [IconButton(onPressed: () => openEvent(), icon: const CircleAvatar(child: Icon(Icons.add)))]),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        IconButton(onPressed: () => setState(() => month = DateTime(month.year, month.month - 1)), icon: const Icon(Icons.chevron_left)),
        Text('${mon(month.month)} ${month.year}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        IconButton(onPressed: () => setState(() => month = DateTime(month.year, month.month + 1)), icon: const Icon(Icons.chevron_right)),
      ]),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(children: ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT']
          .map((x) => Expanded(child: Center(child: Text(x, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))))).toList()),
      ),
      const SizedBox(height: 4),
      SizedBox(
        height: 300,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          itemCount: cells,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
          itemBuilder: (_, i) {
            if (i < offset || i >= offset + count) return const SizedBox();
            final d = DateTime(month.year, month.month, i - offset + 1);
            final ev = dayEvents(d);
            final sel = same(d, selected);
            return GestureDetector(
              onTap: () => setState(() => selected = d),
              child: Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(color: sel ? const Color(0xFF6C3FF5) : Colors.transparent, shape: BoxShape.circle),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('${d.day}', style: TextStyle(color: sel ? Colors.white : null, fontWeight: FontWeight.w600)),
                  if (ev.isNotEmpty) Container(width: 5, height: 5, margin: const EdgeInsets.only(top: 3),
                    decoration: BoxDecoration(color: sel ? Colors.white : const Color(0xFF6C3FF5), shape: BoxShape.circle)),
                ]),
              ),
            );
          },
        ),
      ),
      Expanded(child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          Text('Events on ${selected.day} ${mon(selected.month)} ${selected.year}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...dayEvents(selected).map(eventCard),
          if (dayEvents(selected).isEmpty)
            const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No events booked on this date'))),
        ],
      )),
    ]);
  }

  Widget eventCard(EventData e) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => openEvent(existing: e),
      child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
        Container(width: 5, height: 72, decoration: BoxDecoration(color: const Color(0xFF6C3FF5), borderRadius: BorderRadius.circular(10))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(e.name.isEmpty ? e.client : e.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
            Text(e.time),
          ]),
          const SizedBox(height: 5),
          Text('📍 ${e.venue}'),
          Text('◉ ${e.type}'),
        ])),
        Text('${e.assignments.values.fold<int>(0, (s, x) => s + x.length)} crew', style: const TextStyle(fontSize: 11)),
      ])),
    ),
  );

  Widget eventsPage() {
    final f = events.where((e) => '${e.name} ${e.client} ${e.venue} ${e.phone}'.toLowerCase().contains(search.toLowerCase())).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return Column(children: [
      top('Events'),
      Padding(padding: const EdgeInsets.all(12), child: TextField(
        onChanged: (v) => setState(() => search = v),
        decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search client, phone or event', border: OutlineInputBorder()),
      )),
      Expanded(child: ListView(padding: const EdgeInsets.symmetric(horizontal: 12),
        children: f.map((e) => Padding(padding: const EdgeInsets.only(bottom: 8), child: eventCard(e))).toList())),
    ]);
  }

  Widget teamPage() => Column(children: [
    top('Team Members', actions: [IconButton(onPressed: addTeamManually, icon: const Icon(Icons.add))]),
    Expanded(child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 12), itemCount: team.length,
      itemBuilder: (_, i) => teamTile(team[i]))),
  ]);

  Widget teamTile(TeamMember m) => Card(child: ListTile(
    leading: CircleAvatar(child: Text(m.name.isEmpty ? '?' : m.name[0].toUpperCase())),
    title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
    subtitle: Text('${m.role} • ${m.phone}'),
    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton(icon: const Icon(Icons.chat_outlined), onPressed: () => whatsapp(m.phone)),
      IconButton(icon: const Icon(Icons.call_outlined), onPressed: () => call(m.phone)),
    ]),
  ));

  Widget contactsPage() => Column(children: [
    top('Phone Contacts'),
    const Padding(padding: EdgeInsets.all(16), child: Text('Import a saved phone contact directly into your PHF team.')),
    FilledButton.icon(onPressed: importContact, icon: const Icon(Icons.contacts), label: const Text('Import from Phone Contacts')),
    const SizedBox(height: 12),
    Expanded(child: ListView(padding: const EdgeInsets.all(12), children: team.map(teamTile).toList())),
  ]);

  Widget morePage() => ListView(children: [
    top('More'),
    SwitchListTile(value: widget.dark, onChanged: (_) => widget.onDark(), secondary: const Icon(Icons.dark_mode_outlined), title: const Text('Dark mode')),
    ListTile(leading: const Icon(Icons.delete_sweep_outlined), title: const Text('Manage Events'),
      subtitle: const Text('Search, edit or delete booked events'), onTap: () => setState(() => tab = 1)),
  ]);

  Future<void> openEvent({EventData? existing}) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final client = TextEditingController(text: existing?.client ?? '');
    final phone = TextEditingController(text: existing?.phone ?? '');
    final venue = TextEditingController(text: existing?.venue ?? '');
    final time = TextEditingController(text: existing?.time ?? '7:00 PM');
    final notes = TextEditingController(text: existing?.notes ?? '');
    DateTime date = existing?.date ?? selected;
    String type = existing?.type ?? 'Wedding';
    final a = <String, List<String>>{};
    for (final r in roles) a[r] = List<String>.from(existing?.assignments[r] ?? const []);

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setD) => AlertDialog(
        title: Text(existing == null ? 'Add New Event' : 'Edit Event'),
        content: SizedBox(width: 520, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Event Name')),
          TextField(controller: client, decoration: const InputDecoration(labelText: 'Client Name')),
          TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Client Phone')),
          DropdownButtonFormField<String>(value: type, decoration: const InputDecoration(labelText: 'Event Type'),
            items: ['Wedding', 'Reception', 'Engagement', 'Pre Wedding', 'Other'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
            onChanged: (v) => setD(() => type = v ?? type)),
          TextField(controller: venue, decoration: const InputDecoration(labelText: 'Venue')),
          TextField(controller: time, decoration: const InputDecoration(labelText: 'Event Time')),
          ListTile(contentPadding: EdgeInsets.zero, title: Text('Event Date: ${date.day}/${date.month}/${date.year}'),
            trailing: const Icon(Icons.calendar_month), onTap: () async {
              final d = await showDatePicker(context: ctx, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime(2100));
              if (d != null) setD(() => date = d);
            }),
          TextField(controller: notes, maxLines: 3, decoration: const InputDecoration(labelText: 'Notes')),
          const SizedBox(height: 8),
          const Align(alignment: Alignment.centerLeft, child: Text('Assign Team', style: TextStyle(fontWeight: FontWeight.bold))),
          ...roles.map((r) => roleAssignment(ctx, setD, r, a[r]!)),
        ]))),
        actions: [
          if (existing != null) TextButton(onPressed: () => Navigator.pop(ctx, 'delete'),
            child: const Text('Delete', style: TextStyle(color: Colors.red))),
          TextButton(onPressed: () => Navigator.pop(ctx, 'cancel'), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, 'save'), child: const Text('Save Event')),
        ],
      )),
    );

    if (result == null || result == 'cancel') return;
    if (result == 'delete' && existing != null) {
      final confirm = await showDialog<bool>(context: context, builder: (d) => AlertDialog(
        title: const Text('Delete Event?'), content: Text('Delete "${existing.name.isEmpty ? existing.client : existing.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Delete')),
        ],
      ));
      if (confirm == true) {
        setState(() => events.removeWhere((e) => e.id == existing.id));
        await save();
      }
      return;
    }
    if (result == 'save') {
      final e = EventData(
        id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        name: name.text.trim(), client: client.text.trim(), phone: phone.text.trim(),
        venue: venue.text.trim(), time: time.text.trim(), notes: notes.text.trim(),
        type: type, date: date, assignments: a,
      );
      setState(() {
        if (existing == null) {
          events.add(e);
        } else {
          final i = events.indexWhere((x) => x.id == existing.id);
          if (i >= 0) events[i] = e;
        }
      });
      await save();
    }
  }

  Widget roleAssignment(BuildContext ctx, StateSetter setD, String role, List<String> ids) => Card(
    child: ListTile(
      title: Text('$role  •  ${ids.length} assigned'),
      trailing: IconButton(
        icon: const Icon(Icons.add_circle_outline),
        onPressed: () => showDialog(context: ctx, builder: (d) => StatefulBuilder(builder: (d, setInner) => AlertDialog(
          title: Text('Assign $role'),
          content: SizedBox(width: 420, child: ListView(shrinkWrap: true, children: team.map((m) => CheckboxListTile(
            value: ids.contains(m.id),
            title: Text(m.name),
            subtitle: Text(m.phone),
            onChanged: (v) {
              setInner(() {
                if (v == true && !ids.contains(m.id)) ids.add(m.id);
                if (v != true) ids.remove(m.id);
              });
              setD(() {});
            },
          )).toList())),
          actions: [TextButton(onPressed: () => Navigator.pop(d), child: const Text('Done'))],
        ))),
      ),
    ),
  );

  Future<void> addTeamManually() async {
    final n = TextEditingController(), p = TextEditingController();
    String role = 'Candid';
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setD) => AlertDialog(
      title: const Text('Add Team Member'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: n, decoration: const InputDecoration(labelText: 'Name')),
        TextField(controller: p, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone')),
        DropdownButtonFormField<String>(value: role, items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
          onChanged: (v) => setD(() => role = v ?? role), decoration: const InputDecoration(labelText: 'Role')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
      ],
    )));
    if (ok == true && n.text.trim().isNotEmpty) {
      setState(() => team.add(TeamMember(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: n.text.trim(), phone: p.text.trim(), role: role,
      )));
      await save();
    }
  }

  Future<void> importContact() async {
    if (!await FlutterContacts.requestPermission(readonly: false)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contacts permission denied')));
      return;
    }
    final c = await FlutterContacts.openExternalPick();
    if (c == null) return;
    final full = await FlutterContacts.getContact(c.id, withProperties: true);
    final name = full?.displayName ?? c.displayName;
    final phone = (full != null && full.phones.isNotEmpty) ? full.phones.first.number : '';
    if (!mounted) return;
    String role = 'Candid';
    final r = await showDialog<String>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setD) => AlertDialog(
      title: Text('Add $name'),
      content: DropdownButtonFormField<String>(value: role, items: roles.map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
        onChanged: (v) => setD(() => role = v ?? role)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, role), child: const Text('Add')),
      ],
    )));
    if (r != null) {
      setState(() => team.add(TeamMember(
        id: DateTime.now().microsecondsSinceEpoch.toString(), name: name, phone: phone, role: r,
      )));
      await save();
    }
  }

  Future<void> whatsapp(String phone) async {
    final p = phone.replaceAll(RegExp(r'[^0-9+]'), '').replaceFirst('+', '');
    if (p.isEmpty) return;
    final uri = Uri.parse('https://wa.me/$p');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> call(String phone) async {
    if (phone.trim().isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}

void main() => runApp(const PHFApp());
