import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const roles = <String>[
  'Candid',
  'Cinematographer',
  'T. Photo',
  'T. Video',
  'Drone',
  'Helper',
];

const roleIcons = <String, IconData>{
  'Candid': Icons.camera_alt,
  'Cinematographer': Icons.videocam,
  'T. Photo': Icons.photo_camera,
  'T. Video': Icons.video_camera_back,
  'Drone': Icons.flight,
  'Helper': Icons.person,
};

class TeamMember {
  String id;
  String name;
  String phone;
  String role;

  TeamMember({required this.id, required this.name, required this.phone, required this.role});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'phone': phone, 'role': role};

  factory TeamMember.fromJson(Map<String, dynamic> j) => TeamMember(
        id: j['id']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        phone: j['phone']?.toString() ?? '',
        role: j['role']?.toString() ?? 'Helper',
      );
}

class EventData {
  String id;
  String name;
  String client;
  String phone;
  String venue;
  String time;
  String notes;
  String type;
  DateTime date;
  Map<String, List<String>> assignments;

  EventData({
    required this.id,
    required this.name,
    required this.client,
    required this.phone,
    required this.venue,
    required this.time,
    required this.notes,
    required this.type,
    required this.date,
    required this.assignments,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'client': client,
        'phone': phone,
        'venue': venue,
        'time': time,
        'notes': notes,
        'type': type,
        'date': date.toIso8601String(),
        'assignments': assignments,
      };

  factory EventData.fromJson(Map<String, dynamic> j) {
    final raw = Map<String, dynamic>.from(j['assignments'] ?? {});
    final a = <String, List<String>>{};
    for (final r in roles) {
      a[r] = List<String>.from(raw[r] ?? const <String>[]);
    }
    return EventData(
      id: j['id']?.toString() ?? '',
      name: j['name']?.toString() ?? '',
      client: j['client']?.toString() ?? '',
      phone: j['phone']?.toString() ?? '',
      venue: j['venue']?.toString() ?? '',
      time: j['time']?.toString() ?? '',
      notes: j['notes']?.toString() ?? '',
      type: j['type']?.toString() ?? 'Wedding',
      date: DateTime.tryParse(j['date']?.toString() ?? '') ?? DateTime.now(),
      assignments: a,
    );
  }
}

Future<void> openPhone(String phone) async {
  final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
  if (clean.isEmpty) return;
  await launchUrl(Uri.parse('tel:$clean'));
}

Future<void> openWhatsApp(String phone) async {
  var clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (clean.length == 10) clean = '91$clean';
  if (clean.isEmpty) return;
  final uri = Uri.parse('https://wa.me/$clean');
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

class PHFApp extends StatefulWidget {
  const PHFApp({super.key});

  @override
  State<PHFApp> createState() => _PHFAppState();
}

class _PHFAppState extends State<PHFApp> {
  bool dark = false;
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() { dark = p.getBool('dark') ?? false; loaded = true; });
  }

  Future<void> toggleDark() async {
    final p = await SharedPreferences.getInstance();
    setState(() => dark = !dark);
    await p.setBool('dark', dark);
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PHF',
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF6C3FF5), brightness: Brightness.light),
      darkTheme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF8B63FF), brightness: Brightness.dark),
      home: PHFHome(dark: dark, onDark: toggleDark),
    );
  }
}

class PHFHome extends StatefulWidget {
  final bool dark;
  final VoidCallback onDark;
  const PHFHome({super.key, required this.dark, required this.onDark});

  @override
  State<PHFHome> createState() => _PHFHomeState();
}

class _PHFHomeState extends State<PHFHome> {
  int tab = 0;
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime selected = DateTime.now();
  List<EventData> events = [];
  List<TeamMember> team = [];
  String search = '';
  String teamSearch = '';
  String teamRole = 'All';

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final es = (p.getStringList('events') ?? []).map((x) {
      try { return EventData.fromJson(jsonDecode(x)); } catch (_) { return null; }
    }).whereType<EventData>().toList();
    final ts = (p.getStringList('team') ?? []).map((x) {
      try { return TeamMember.fromJson(jsonDecode(x)); } catch (_) { return null; }
    }).whereType<TeamMember>().toList();
    if (mounted) setState(() { events = es; team = ts; });
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList('events', events.map((e) => jsonEncode(e.toJson())).toList());
    await p.setStringList('team', team.map((e) => jsonEncode(e.toJson())).toList());
  }

  bool same(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
  List<EventData> dayEvents(DateTime d) => events.where((e) => same(e.date, d)).toList();
  String mon(int m) => const ['', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][m];

  String initials(String name) => name.trim().isEmpty ? '?' : name.trim().split(RegExp(r'\s+')).take(2).map((x) => x[0]).join().toUpperCase();

  @override
  Widget build(BuildContext context) {
    final pages = [calendarPage(), eventsPage(), teamPage(), contactsPage(), morePage()];
    return Scaffold(
      body: SafeArea(child: pages[tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Calendar'),
          NavigationDestination(icon: Icon(Icons.event_outlined), selectedIcon: Icon(Icons.event), label: 'Events'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Team'),
          NavigationDestination(icon: Icon(Icons.contacts_outlined), selectedIcon: Icon(Icons.contacts), label: 'Contacts'),
          NavigationDestination(icon: Icon(Icons.more_horiz), selectedIcon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }

  Widget top(String title, {List<Widget> actions = const []}) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
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
      top('Dashboard', actions: [IconButton(onPressed: () => openEvent(), icon: const CircleAvatar(child: Icon(Icons.add))) ]),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        IconButton(onPressed: () => setState(() => month = DateTime(month.year, month.month - 1)), icon: const Icon(Icons.chevron_left)),
        Text('${mon(month.month)} ${month.year}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        IconButton(onPressed: () => setState(() => month = DateTime(month.year, month.month + 1)), icon: const Icon(Icons.chevron_right)),
      ]),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(children: ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'].map((x) => Expanded(child: Center(child: Text(x, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))))).toList()),
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
                  if (ev.isNotEmpty) Container(width: 5, height: 5, margin: const EdgeInsets.only(top: 3), decoration: BoxDecoration(color: sel ? Colors.white : const Color(0xFF6C3FF5), shape: BoxShape.circle)),
                ]),
              ),
            );
          },
        ),
      ),
      Expanded(
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 12), children: [
          Text('Events on ${selected.day} ${mon(selected.month)} ${selected.year}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...dayEvents(selected).map(eventCard),
          if (dayEvents(selected).isEmpty) const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No events booked on this date'))),
        ]),
      ),
    ]);
  }

  Widget eventCard(EventData e) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openEvent(existing: e),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(width: 5, height: 76, decoration: BoxDecoration(color: const Color(0xFF6C3FF5), borderRadius: BorderRadius.circular(10))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Expanded(child: Text(e.name.isEmpty ? e.client : e.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))), Text(e.time)]),
                const SizedBox(height: 5),
                Text('📍 ${e.venue}'),
                Text('◉ ${e.type}'),
              ])),
              Text('${e.assignments.values.fold<int>(0, (s, x) => s + x.length)} crew', style: const TextStyle(fontSize: 11)),
            ]),
          ),
        ),
      );

  Widget eventsPage() {
    final f = events.where((e) => '${e.name} ${e.client} ${e.venue} ${e.phone}'.toLowerCase().contains(search.toLowerCase())).toList()..sort((a, b) => a.date.compareTo(b.date));
    return Column(children: [
      top('Events'),
      Padding(padding: const EdgeInsets.all(12), child: TextField(onChanged: (v) => setState(() => search = v), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search client, phone or event', border: OutlineInputBorder()))),
      Expanded(child: f.isEmpty ? const Center(child: Text('No events found')) : ListView(padding: const EdgeInsets.symmetric(horizontal: 12), children: f.map((e) => Padding(padding: const EdgeInsets.only(bottom: 8), child: eventCard(e))).toList())),
    ]);
  }

  Widget teamPage() {
    final filtered = team.where((m) {
      final q = '${m.name} ${m.phone} ${m.role}'.toLowerCase();
      return q.contains(teamSearch.toLowerCase()) && (teamRole == 'All' || m.role == teamRole);
    }).toList();
    return Column(children: [
      top('Team Members', actions: [IconButton(onPressed: importContact, tooltip: 'Import contact', icon: const Icon(Icons.person_add_alt_1))]),
      Padding(padding: const EdgeInsets.fromLTRB(12, 4, 12, 8), child: TextField(onChanged: (v) => setState(() => teamSearch = v), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search by name, phone or role', border: OutlineInputBorder()))),
      SizedBox(height: 46, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: ['All', ...roles].map((r) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(r), selected: teamRole == r, onSelected: (_) => setState(() => teamRole = r))).toList())),
      Expanded(child: filtered.isEmpty ? const Center(child: Text('No team members')) : ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 12), itemCount: filtered.length, itemBuilder: (_, i) => teamTile(filtered[i]))),
      Padding(padding: const EdgeInsets.all(12), child: FilledButton.icon(onPressed: addTeamManually, icon: const Icon(Icons.add), label: const Text('Add Team Member'))),
    ]);
  }

  Widget teamTile(TeamMember m) => Card(
        child: ListTile(
          leading: CircleAvatar(child: Text(initials(m.name))),
          title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('${m.role} • ${m.phone}'),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(icon: const Icon(Icons.chat_outlined), tooltip: 'WhatsApp', onPressed: () => openWhatsApp(m.phone)),
            IconButton(icon: const Icon(Icons.call_outlined), tooltip: 'Call', onPressed: () => openPhone(m.phone)),
          ]),
          onTap: () => editTeam(m),
        ),
      );

  Widget contactsPage() => Column(children: [
        top('Phone Contacts'),
        const Padding(padding: EdgeInsets.fromLTRB(16, 10, 16, 8), child: Text('Import saved phone contacts directly into your PHF team. Name and number will be filled automatically.')),
        FilledButton.icon(onPressed: importContact, icon: const Icon(Icons.contacts), label: const Text('Import from Phone Contacts')),
        const SizedBox(height: 8),
        Expanded(child: ListView(padding: const EdgeInsets.all(12), children: team.map(teamTile).toList())),
      ]);

  Widget morePage() => ListView(children: [
        top('More'),
        SwitchListTile(value: widget.dark, onChanged: (_) => widget.onDark(), secondary: const Icon(Icons.dark_mode_outlined), title: const Text('Dark mode')),
        ListTile(leading: const Icon(Icons.delete_sweep_outlined), title: const Text('Manage Events'), subtitle: const Text('Search, edit or delete booked events'), onTap: () => setState(() => tab = 1)),
        const Divider(),
        const ListTile(leading: Icon(Icons.info_outline), title: Text('PHF'), subtitle: Text('Wedding & Event Crew Booking Manager • V2')),
      ]);

  Future<void> openEvent({EventData? existing}) async {
    final result = await Navigator.push<EventEditorResult>(context, MaterialPageRoute(builder: (_) => EventEditor(event: existing, team: team)));
    if (result == null) return;
    if (result.deleted) {
      if (existing != null) setState(() => events.removeWhere((e) => e.id == existing.id));
      await save();
      return;
    }
    final event = result.event;
    if (event == null) return;
    final index = events.indexWhere((e) => e.id == event.id);
    setState(() {
      if (index >= 0) events[index] = event; else events.add(event);
      selected = event.date;
      month = DateTime(event.date.year, event.date.month);
    });
    await save();
  }

  Future<void> deleteEvent(EventData e) async {
    final yes = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Delete event?'), content: Text('Delete “${e.name.isEmpty ? e.client : e.name}”?'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete'))])) ?? false;
    if (!yes) return;
    setState(() => events.removeWhere((x) => x.id == e.id));
    await save();
  }

  Future<void> addTeamManually() async {
    final result = await Navigator.push<TeamMember>(context, MaterialPageRoute(builder: (_) => TeamEditor(team: team)));
    if (result == null) return;
    setState(() => team.add(result));
    await save();
  }

  Future<void> editTeam(TeamMember m) async {
    final result = await Navigator.push<TeamMember>(context, MaterialPageRoute(builder: (_) => TeamEditor(member: m, team: team)));
    if (result == null) return;
    final i = team.indexWhere((x) => x.id == result.id);
    if (i >= 0) setState(() => team[i] = result);
    await save();
  }

  Future<void> importContact() async {
    try {
      final granted = await FlutterContacts.requestPermission();
      if (!granted) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contacts permission is required to import team members.')));
        return;
      }
      final contact = await FlutterContacts.openExternalPick();
      if (contact == null) return;
      final phones = contact.phones;
      final phone = phones.isEmpty ? '' : phones.first.number;
      if (!mounted) return;
      final result = await Navigator.push<TeamMember>(context, MaterialPageRoute(builder: (_) => TeamEditor(prefillName: contact.displayName, prefillPhone: phone, team: team)));
      if (result == null) return;
      setState(() => team.add(result));
      await save();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open contacts: $e')));
    }
  }
}

class EventEditorResult {
  final EventData? event;
  final bool deleted;
  const EventEditorResult({this.event, this.deleted = false});
}

class EventEditor extends StatefulWidget {
  final EventData? event;
  final List<TeamMember> team;
  const EventEditor({super.key, this.event, required this.team});
  @override State<EventEditor> createState() => _EventEditorState();
}

class _EventEditorState extends State<EventEditor> {
  late final TextEditingController name, client, phone, venue, time, notes;
  late DateTime date;
  String type = 'Wedding';
  late Map<String, List<String>> assignments;

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    name = TextEditingController(text: e?.name ?? '');
    client = TextEditingController(text: e?.client ?? '');
    phone = TextEditingController(text: e?.phone ?? '');
    venue = TextEditingController(text: e?.venue ?? '');
    time = TextEditingController(text: e?.time ?? '');
    notes = TextEditingController(text: e?.notes ?? '');
    date = e?.date ?? DateTime.now();
    type = e?.type ?? 'Wedding';
    assignments = {for (final r in roles) r: List<String>.from(e?.assignments[r] ?? const <String>[])};
  }

  @override
  void dispose() { name.dispose(); client.dispose(); phone.dispose(); venue.dispose(); time.dispose(); notes.dispose(); super.dispose(); }

  String fmt(DateTime d) => '${d.day.toString().padLeft(2, '0')} ${const ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.month]} ${d.year}';

  Future<void> pickDate() async {
    final d = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (d != null) setState(() => date = DateTime(d.year, d.month, d.day));
  }

  Future<void> pickTime() async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (t != null) setState(() => time.text = t.format(context));
  }

  Future<void> assignRole(String role) async {
    final chosen = Set<String>.from(assignments[role] ?? []);
    final available = widget.team.where((m) => m.role == role || role == 'Helper' || role == 'Candid' || role == 'Cinematographer' || role == 'T. Photo' || role == 'T. Video' || role == 'Drone').toList();
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No team members available. Add members first.')));
      return;
    }
    final result = await showDialog<Set<String>>(context: context, builder: (_) => _AssignDialog(role: role, team: available, selected: chosen));
    if (result != null) setState(() => assignments[role] = result.toList());
  }

  void saveEvent() {
    if (name.text.trim().isEmpty && client.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter event name or client name.')));
      return;
    }
    final id = widget.event?.id ?? DateTime.now().microsecondsSinceEpoch.toString();
    Navigator.pop(context, EventEditorResult(event: EventData(id: id, name: name.text.trim(), client: client.text.trim(), phone: phone.text.trim(), venue: venue.text.trim(), time: time.text.trim(), notes: notes.text.trim(), type: type, date: date, assignments: assignments)));
  }

  @override
  Widget build(BuildContext context) {
    final edit = widget.event != null;
    return Scaffold(
      appBar: AppBar(title: Text(edit ? 'Edit Event' : 'Add New Event')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Event Name', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: client, decoration: const InputDecoration(labelText: 'Client Name', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Client Phone', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone))),
        const SizedBox(height: 12),
        Row(children: [Expanded(child: DropdownButtonFormField<String>(value: type, decoration: const InputDecoration(labelText: 'Event Type', border: OutlineInputBorder()), items: const ['Wedding', 'Reception', 'Engagement', 'Pre Wedding', 'Haldi', 'Sangeet', 'Other'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: (v) => setState(() => type = v ?? type))), const SizedBox(width: 12), Expanded(child: InkWell(onTap: pickDate, child: InputDecorator(decoration: const InputDecoration(labelText: 'Event Date', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_month)), child: Text(fmt(date))))) ]),
        const SizedBox(height: 12),
        TextField(controller: time, readOnly: true, onTap: pickTime, decoration: const InputDecoration(labelText: 'Event Time', border: OutlineInputBorder(), suffixIcon: Icon(Icons.access_time))),
        const SizedBox(height: 12),
        TextField(controller: venue, decoration: const InputDecoration(labelText: 'Venue', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on_outlined))),
        const SizedBox(height: 12),
        TextField(controller: notes, maxLines: 3, decoration: const InputDecoration(labelText: 'Note (Optional)', border: OutlineInputBorder())),
        const SizedBox(height: 18),
        const Text('ASSIGN TEAM', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: .5)),
        const SizedBox(height: 8),
        ...roles.map((r) => _assignmentTile(r)),
        const SizedBox(height: 18),
        Row(children: [Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))), const SizedBox(width: 12), Expanded(child: FilledButton(onPressed: saveEvent, child: Text(edit ? 'Update Event' : 'Save Event')))]),
        if (edit) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(onPressed: () async {
            final yes = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Delete event?'), content: const Text('This event will be removed from PHF.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete'))])) ?? false;
            if (yes && mounted) Navigator.pop(context, const EventEditorResult(deleted: true));
          }, icon: const Icon(Icons.delete_outline), label: const Text('Delete event'), style: OutlinedButton.styleFrom(foregroundColor: Colors.red)),
        ],
      ]),
    );
  }

  Widget _assignmentTile(String role) {
    final ids = assignments[role] ?? [];
    final names = widget.team.where((m) => ids.contains(m.id)).map((m) => m.name).toList();
    return Card(child: ListTile(leading: CircleAvatar(child: Icon(roleIcons[role])), title: Text(role), subtitle: Text(names.isEmpty ? 'Not assigned' : names.join(', ')), trailing: FilledButton.tonalIcon(onPressed: () => assignRole(role), icon: const Icon(Icons.add), label: Text(ids.isEmpty ? 'Assign' : 'Add'))));
  }
}

class _AssignDialog extends StatefulWidget {
  final String role;
  final List<TeamMember> team;
  final Set<String> selected;
  const _AssignDialog({required this.role, required this.team, required this.selected});
  @override State<_AssignDialog> createState() => _AssignDialogState();
}
class _AssignDialogState extends State<_AssignDialog> {
  late Set<String> selected;
  String search = '';
  @override void initState() { super.initState(); selected = Set.from(widget.selected); }
  @override Widget build(BuildContext context) {
    final list = widget.team.where((m) => '${m.name} ${m.phone} ${m.role}'.toLowerCase().contains(search.toLowerCase())).toList();
    return AlertDialog(
      title: Text('Assign ${widget.role}'),
      content: SizedBox(width: 430, height: 430, child: Column(children: [
        TextField(onChanged: (v) => setState(() => search = v), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search member', border: OutlineInputBorder())),
        const SizedBox(height: 8),
        Expanded(child: ListView(children: list.map((m) => CheckboxListTile(value: selected.contains(m.id), onChanged: (v) => setState(() { if (v == true) selected.add(m.id); else selected.remove(m.id); }), title: Text(m.name), subtitle: Text('${m.role} • ${m.phone}'))).toList())),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, selected), child: Text('Done (${selected.length})'))],
    );
  }
}

class TeamEditor extends StatefulWidget {
  final TeamMember? member;
  final List<TeamMember> team;
  final String? prefillName;
  final String? prefillPhone;
  const TeamEditor({super.key, this.member, required this.team, this.prefillName, this.prefillPhone});
  @override State<TeamEditor> createState() => _TeamEditorState();
}
class _TeamEditorState extends State<TeamEditor> {
  late final TextEditingController name, phone;
  late String role;
  @override void initState() { super.initState(); name = TextEditingController(text: widget.member?.name ?? widget.prefillName ?? ''); phone = TextEditingController(text: widget.member?.phone ?? widget.prefillPhone ?? ''); role = widget.member?.role ?? 'Candid'; }
  @override void dispose() { name.dispose(); phone.dispose(); super.dispose(); }
  void saveMember() { if (name.text.trim().isEmpty) return; final id = widget.member?.id ?? DateTime.now().microsecondsSinceEpoch.toString(); Navigator.pop(context, TeamMember(id: id, name: name.text.trim(), phone: phone.text.trim(), role: role)); }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(widget.member == null ? 'Add Team Member' : 'Edit Team Member')), body: ListView(padding: const EdgeInsets.all(16), children: [
    TextField(controller: name, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())), const SizedBox(height: 12),
    TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone))), const SizedBox(height: 12),
    DropdownButtonFormField<String>(value: role, decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()), items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(), onChanged: (v) => setState(() => role = v ?? role)), const SizedBox(height: 20),
    FilledButton(onPressed: saveMember, child: const Text('Save Member')),
  ]);
}

void main() => runApp(const PHFApp());
