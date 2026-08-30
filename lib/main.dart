import 'dart:convert';
import 'dart:typed_data';


import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const purple = Color(0xFF6C3FF5);
const roles = <String>[
  'Candid',
  'Cinematographer',
  'T. Photo',
  'T. Video',
  'Drone',
  'Helper',
];

class TeamMember {
  final String id;
  String name;
  String role;
  String phone;

  TeamMember({required this.id, required this.name, required this.role, required this.phone});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'role': role, 'phone': phone};

  factory TeamMember.fromJson(Map<String, dynamic> j) => TeamMember(
        id: j['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        name: j['name']?.toString() ?? '',
        role: 'Team Member',
        phone: j['phone']?.toString() ?? '',
      );
}

class EventData {
  final String id;
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
      a[r] = List<String>.from(raw[r] ?? const []);
    }
    return EventData(
      id: j['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
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

void main() => runApp(const PHFApp());

class PHFApp extends StatefulWidget {
  const PHFApp({super.key});
  @override
  State<PHFApp> createState() => _PHFAppState();
}

class _PHFAppState extends State<PHFApp> {
  bool dark = true;
  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) setState(() => dark = p.getBool('dark') ?? true);
    });
  }

  Future<void> toggle() async {
    final p = await SharedPreferences.getInstance();
    setState(() => dark = !dark);
    await p.setBool('dark', dark);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'CrewFlow',
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: purple),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF8B63FF),
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF121015),
        ),
        home: PHFHome(dark: dark, onDark: toggle),
      );
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
  String brandName = '';
  String brandContact = '';
  String brandEmail = '';
  String? logoBase64;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final es = (p.getStringList('events') ?? []).map((x) {
      try {
        return EventData.fromJson(jsonDecode(x));
      } catch (_) {
        return null;
      }
    }).whereType<EventData>().toList();
    final savedBrandName = p.getString('brandName') ?? '';
    final savedBrandContact = p.getString('brandContact') ?? '';
    final savedBrandEmail = p.getString('brandEmail') ?? '';
    final savedLogo = p.getString('logoBase64');
    final ts = (p.getStringList('team') ?? []).map((x) {
      try {
        return TeamMember.fromJson(jsonDecode(x));
      } catch (_) {
        return null;
      }
    }).whereType<TeamMember>().toList();
    if (!mounted) return;
    setState(() {
      events = es;
      team = ts;
      brandName = savedBrandName;
      brandContact = savedBrandContact;
      brandEmail = savedBrandEmail;
      logoBase64 = savedLogo;
    });
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList('events', events.map((e) => jsonEncode(e.toJson())).toList());
    await p.setStringList('team', team.map((e) => jsonEncode(e.toJson())).toList());
    await p.setString('brandName', brandName);
    await p.setString('brandContact', brandContact);
    await p.setString('brandEmail', brandEmail);
    if (logoBase64 == null) {
      await p.remove('logoBase64');
    } else {
      await p.setString('logoBase64', logoBase64!);
    }
  }

  bool same(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
  bool sameMonth(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;
  String mon(int m) => const [
        '', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August',
        'September', 'October', 'November', 'December'
      ][m];
  String dateFull(DateTime d) => '${d.day} ${mon(d.month)} ${d.year}';
  List<EventData> dayEvents(DateTime d) => events.where((e) => same(e.date, d)).toList();
  List<EventData> monthEvents(DateTime m) => events.where((e) => sameMonth(e.date, m)).toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  void changeMonth(int delta) {
    final next = DateTime(month.year, month.month + delta);
    setState(() {
      month = next;
      selected = DateTime(next.year, next.month, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [calendarPage(), eventsPage(), teamPage(), morePage()];
    return Scaffold(
      body: SafeArea(child: pages[tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Calendar'),
          NavigationDestination(icon: Icon(Icons.event_outlined), selectedIcon: Icon(Icons.event), label: 'Events'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Team'),
          NavigationDestination(icon: Icon(Icons.more_horiz), selectedIcon: Icon(Icons.more_horiz), label: 'More'),
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
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        if (v < -100) changeMonth(1);
        if (v > 100) changeMonth(-1);
      },
      child: Stack(children: [
        Column(children: [
        top('Dashboard'),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(onPressed: () => changeMonth(-1), icon: const Icon(Icons.chevron_left)),
          Text('${mon(month.month)} ${month.year}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
          IconButton(onPressed: () => changeMonth(1), icon: const Icon(Icons.chevron_right)),
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
                  decoration: BoxDecoration(color: sel ? purple : Colors.transparent, shape: BoxShape.circle),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('${d.day}', style: TextStyle(color: sel ? Colors.white : null, fontWeight: FontWeight.w600)),
                    if (ev.isNotEmpty)
                      Container(width: 5, height: 5, margin: const EdgeInsets.only(top: 3), decoration: BoxDecoration(color: sel ? Colors.white : purple, shape: BoxShape.circle)),
                  ]),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
            children: [
              Row(children: [
                Expanded(child: Text('${mon(month.month)} ${month.year} Events', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
                Text('${monthEvents(month).length} Events'),
              ]),
              const SizedBox(height: 8),
              ...monthEvents(month).map(eventCard),
              if (monthEvents(month).isEmpty) const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No events booked this month'))),
            ],
          ),
        ),
      ]),
        Positioned(
          right: 18,
          bottom: 18,
          child: FloatingActionButton(heroTag: 'calendarAdd', onPressed: () => openEvent(), child: const Icon(Icons.add)),
        ),
      ]),
    );
  }

  Widget eventCard(EventData e, {bool openPdf = false}) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openPdf ? openEventPdf(e) : openEvent(existing: e),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 5, height: 84, decoration: BoxDecoration(color: purple, borderRadius: BorderRadius.circular(10))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.client.isEmpty ? e.name : e.client, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 5),
                Text('📍 ${e.venue}'),
                Text('◉ ${e.type}'),
              ])),
              const SizedBox(width: 8),
              SizedBox(width: 118, child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(dateFull(e.date), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(e.time.isEmpty ? 'Time not set' : e.time),
                const SizedBox(height: 4),
                Text('${e.assignments.values.fold<int>(0, (s, x) => s + x.length)} crew', style: const TextStyle(fontSize: 11)),
              ])),
            ]),
          ),
        ),
      );

  Widget eventsPage() {
    final f = events.where((e) => '${e.name} ${e.client} ${e.phone} ${e.venue}'.toLowerCase().contains(search.toLowerCase())).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return Column(children: [
      top('Events'),
      Padding(padding: const EdgeInsets.all(12), child: TextField(onChanged: (v) => setState(() => search = v), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search client, phone or event', border: OutlineInputBorder()))),
      Expanded(child: ListView(padding: const EdgeInsets.symmetric(horizontal: 12), children: f.map((e) => Padding(padding: const EdgeInsets.only(bottom: 8), child: eventCard(e, openPdf: true))).toList())),
      Align(alignment: Alignment.bottomRight, child: Padding(padding: const EdgeInsets.all(16), child: FloatingActionButton(heroTag: 'eventsAdd', onPressed: () => openEvent(), child: const Icon(Icons.add)))),
    ]);
  }

  Widget teamPage() => Stack(children: [
        Column(children: [
          top('Team Members'),
          Expanded(child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 12), itemCount: team.length, itemBuilder: (_, i) => teamTile(team[i]))),
        ]),
        Positioned(right: 18, bottom: 18, child: FloatingActionButton(heroTag: 'teamAdd', onPressed: addFromContacts, child: const Icon(Icons.add))),
      ]);

  Widget teamTile(TeamMember m) => Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          leading: CircleAvatar(backgroundColor: purple.withOpacity(.55), child: Text(m.name.isEmpty ? '?' : m.name[0].toUpperCase())),
          title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('Team Member • ${m.phone}'),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(icon: const Icon(Icons.chat_outlined), tooltip: 'WhatsApp', onPressed: () => chooseWhatsappEvent(m)),
            IconButton(icon: const Icon(Icons.call_outlined), tooltip: 'Call', onPressed: () => call(m.phone)),
            PopupMenuButton<String>(
              onSelected: (v) { if (v == 'delete') deleteTeamMember(m); },
              itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Text('Delete member'))],
            ),
          ]),
        ),
      );

  Future<void> deleteTeamMember(TeamMember member) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Team Member?'),
        content: Text('Remove ${member.name} from the team?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => team.removeWhere((m) => m.id == member.id));
    await save();
  }

  Widget morePage() => ListView(children: [
        top('More'),
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: const Text('Profile'),
          subtitle: Text(brandName.isEmpty ? 'Add logo and business details' : brandName),
          trailing: const Icon(Icons.chevron_right),
          onTap: openProfile,
        ),
        SwitchListTile(value: widget.dark, onChanged: (_) => widget.onDark(), secondary: const Icon(Icons.dark_mode_outlined), title: const Text('Dark mode')),
        ListTile(leading: const Icon(Icons.delete_sweep_outlined), title: const Text('Manage Events'), subtitle: const Text('Search, edit or delete booked events'), onTap: () => setState(() => tab = 1)),
      ]);

  Future<void> openProfile() async {
    final result = await showDialog<BrandProfile>(
      context: context,
      builder: (_) => BrandProfileDialog(
        name: brandName,
        contact: brandContact,
        email: brandEmail,
        logoBase64: logoBase64,
      ),
    );
    if (result == null) return;
    setState(() {
      brandName = result.name;
      brandContact = result.contact;
      brandEmail = result.email;
      logoBase64 = result.logoBase64;
    });
    await save();
  }

  Future<void> openEventPdf(EventData event) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => EventPdfPage(event: event, profile: BrandProfile(name: brandName, contact: brandContact, email: brandEmail, logoBase64: logoBase64), team: team),
    ));
  }

  Future<void> addFromContacts() async {
    final ok = await FlutterContacts.requestPermission(readonly: true);
    if (!ok || !mounted) return;
    final contacts = await FlutterContacts.getContacts(withProperties: true);
    if (!mounted) return;
    final picked = await showModalBottomSheet<Contact>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ContactPickerSheet(contacts: contacts),
    );
    if (picked == null) return;
    final phone = picked.phones.isEmpty ? '' : picked.phones.first.number;
    if (phone.trim().isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This contact has no phone number.')));
      return;
    }
    final exists = team.any((m) => m.phone.replaceAll(RegExp(r'\D'), '') == phone.replaceAll(RegExp(r'\D'), ''));
    if (!exists) {
      team.add(TeamMember(id: DateTime.now().microsecondsSinceEpoch.toString(), name: picked.displayName, role: 'Team Member', phone: phone));
      await save();
      if (mounted) setState(() {});
    }
  }

  Future<void> chooseWhatsappEvent(TeamMember member) async {
    final assigned = events.where((e) => e.assignments.values.any((names) => names.contains(member.name))).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (assigned.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No event is assigned to this team member.')));
      }
      return;
    }
    EventData? event = assigned.length == 1 ? assigned.first : await showModalBottomSheet<EventData>(
      context: context,
      builder: (_) => SafeArea(child: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Select Event', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...assigned.map((e) => ListTile(
          leading: const Icon(Icons.event),
          title: Text(e.client.isEmpty ? e.name : e.client),
          subtitle: Text('${dateFull(e.date)} • ${e.time} • ${e.venue}'),
          onTap: () => Navigator.pop(context, e),
        )),
      ])),
    );
    if (event == null) return;
    final text = 'Hi ${member.name},\n\nYou are assigned for ${event.client.isEmpty ? event.name : event.client} ${event.type}.\n📍 ${event.venue}\n📅 ${dateFull(event.date)}\n⏰ ${event.time}\n\nPlease be available on time. Thank you.';
    await whatsapp(member.phone, message: text);
  }

  Future<void> whatsapp(String phone, {required String message}) async {
    var p = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (p.length == 10) p = '91$p';
    if (p.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid phone number.')));
      }
      return;
    }
    final encoded = Uri.encodeComponent(message);
    final appUri = Uri.parse('whatsapp://send?phone=$p&text=$encoded');
    final webUri = Uri.parse('https://wa.me/$p?text=$encoded');
    try {
      if (await launchUrl(appUri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {}
    try {
      if (await launchUrl(webUri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {}
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('WhatsApp is not available on this phone.')));
    }
  }

  Future<void> call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> deleteEvent(EventData event) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Event?'),
        content: Text('Delete ${event.client.isEmpty ? event.name : event.client} from ${dateFull(event.date)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() {
      events.removeWhere((e) => e.id == event.id);
      selected = DateTime(month.year, month.month, 1);
    });
    await save();
    if (mounted) Navigator.pop(context);
  }

  Future<void> openEvent({EventData? existing}) async {
    final result = await showDialog<EventData>(context: context, builder: (_) => EventDialog(existing: existing, team: team, onDelete: existing == null ? null : () => deleteEvent(existing)));
    if (result == null) return;
    final i = events.indexWhere((e) => e.id == result.id);
    setState(() {
      if (i >= 0) events[i] = result;
      else events.add(result);
      month = DateTime(result.date.year, result.date.month);
      selected = result.date;
    });
    await save();
  }
}

class ContactPickerSheet extends StatefulWidget {
  final List<Contact> contacts;
  const ContactPickerSheet({super.key, required this.contacts});
  @override
  State<ContactPickerSheet> createState() => _ContactPickerSheetState();
}
class _ContactPickerSheetState extends State<ContactPickerSheet> {
  String q = '';
  @override
  Widget build(BuildContext context) {
    final list = widget.contacts.where((c) => c.displayName.toLowerCase().contains(q.toLowerCase())).toList();
    return SizedBox(height: MediaQuery.sizeOf(context).height * .8, child: Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: TextField(onChanged: (v) => setState(() => q = v), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search contact', border: OutlineInputBorder()))),
      Expanded(child: ListView.builder(itemCount: list.length, itemBuilder: (_, i) { final c = list[i]; return ListTile(leading: const CircleAvatar(child: Icon(Icons.person)), title: Text(c.displayName), subtitle: Text(c.phones.isEmpty ? 'No phone number' : c.phones.first.number), onTap: () => Navigator.pop(context, c)); })),
    ]));
  }
}

class EventDialog extends StatefulWidget {
  final EventData? existing;
  final List<TeamMember> team;
  final VoidCallback? onDelete;
  const EventDialog({super.key, this.existing, required this.team, this.onDelete});
  @override
  State<EventDialog> createState() => _EventDialogState();
}

class _EventDialogState extends State<EventDialog> {
  late final TextEditingController client;
  late final TextEditingController phone;
  late final TextEditingController venue;
  late final TextEditingController notes;
  late String type;
  late DateTime date;
  late TimeOfDay time;
  late Map<String, List<String>> assignments;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    client = TextEditingController(text: e?.client ?? '');
    phone = TextEditingController(text: e?.phone ?? '');
    venue = TextEditingController(text: e?.venue ?? '');
    notes = TextEditingController(text: e?.notes ?? '');
    type = e?.type ?? 'Wedding';
    date = e?.date ?? DateTime.now();
    final parsed = _parseTime(e?.time ?? '');
    time = parsed ?? TimeOfDay.now();
    final existingAssignments = e?.assignments ?? const <String, List<String>>{};
    assignments = {};
    for (final r in roles) {
      if (existingAssignments.containsKey(r) || r == 'Candid' || r == 'Cinematographer') {
        assignments[r] = List<String>.from(existingAssignments[r] ?? const []);
      }
    }
  }

  TimeOfDay? _parseTime(String s) {
    final m = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)?$', caseSensitive: false).firstMatch(s.trim());
    if (m == null) return null;
    var h = int.parse(m.group(1)!);
    final min = int.parse(m.group(2)!);
    final ap = m.group(3)?.toUpperCase();
    if (ap == 'PM' && h != 12) h += 12;
    if (ap == 'AM' && h == 12) h = 0;
    return TimeOfDay(hour: h, minute: min);
  }

  String formatTime(TimeOfDay t) => t.format(context);
  String formatDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.78;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: maxHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.existing == null ? 'Add New Event' : 'Edit Event',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: client,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Client Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: phone,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Client Phone',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: type,
                      decoration: const InputDecoration(
                        labelText: 'Event Type',
                        prefixIcon: Icon(Icons.event_outlined),
                      ),
                      items: const [
                        'Wedding',
                        'Reception',
                        'Engagement',
                        'Pre Wedding',
                        'Haldi',
                        'Sangeet',
                        'Other',
                      ].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
                      onChanged: (v) => setState(() => type = v ?? type),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: venue,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Venue / Location',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 6),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.access_time),
                      title: const Text('Event Time'),
                      subtitle: Text(formatTime(time)),
                      onTap: () async {
                        final t = await showTimePicker(context: context, initialTime: time);
                        if (t != null && mounted) setState(() => time = t);
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_month),
                      title: const Text('Event Date'),
                      subtitle: Text(formatDate(date)),
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          initialDate: date,
                        );
                        if (d != null && mounted) setState(() => date = d);
                      },
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: notes,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        alignLabelWithHint: true,
                        hintText: 'Add event notes...',
                        border: OutlineInputBorder(),
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 52),
                          child: Icon(Icons.notes_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Assign Team',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    ...assignments.entries.map((entry) => _roleRow(entry.key, entry.value)),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _addRole,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Team'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  if (widget.existing != null && widget.onDelete != null)
                    TextButton(
                      onPressed: widget.onDelete,
                      child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _save,
                    child: Text(widget.existing == null ? 'Save Event' : 'Save Changes'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    client.dispose();
    phone.dispose();
    venue.dispose();
    notes.dispose();
    super.dispose();
  }

  String roleLabel(String role) => role == 'Cinematographer' ? 'Cinematic' : role;

  Widget _roleRow(String role, List<String> names) => Card(
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), child: Row(children: [
          Expanded(child: Text('${roleLabel(role)} - ${names.isEmpty ? 'Not assigned' : names.join(', ')}')),
          TextButton(onPressed: () => _assign(role), child: Text(names.isEmpty ? 'Assign' : 'Change')),
        ])),
      );

  Future<void> _assign(String role) async {
    final selected = await showDialog<TeamMember>(context: context, builder: (_) => AssignMemberDialog(role: role, members: widget.team, already: assignments[role] ?? const []));
    if (selected == null) return;
    setState(() => assignments[role] = [selected.name]);
  }

  Future<void> _addRole() async {
    final available = roles.where((r) => !assignments.containsKey(r)).toList();
    if (available.isEmpty) return;
    final r = await showModalBottomSheet<String>(context: context, builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: available.map((x) => ListTile(title: Text(roleLabel(x)), onTap: () => Navigator.pop(context, x))).toList())));
    if (r == null) return;
    final selected = await showDialog<TeamMember>(context: context, builder: (_) => AssignMemberDialog(role: r, members: widget.team, already: const []));
    setState(() => assignments[r] = selected == null ? <String>[] : [selected.name]);
  }

  void _save() {
    if (client.text.trim().isEmpty || venue.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter Client Name and Venue.')));
      return;
    }
    final t = formatTime(time);
    final e = EventData(id: widget.existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(), name: widget.existing?.name ?? '', client: client.text.trim(), phone: phone.text.trim(), venue: venue.text.trim(), time: t, notes: notes.text.trim(), type: type, date: DateTime(date.year, date.month, date.day), assignments: assignments);
    Navigator.pop(context, e);
  }
}

class AssignMemberDialog extends StatefulWidget {
  final String role;
  final List<TeamMember> members;
  final List<String> already;
  const AssignMemberDialog({super.key, required this.role, required this.members, required this.already});
  @override
  State<AssignMemberDialog> createState() => _AssignMemberDialogState();
}

class _AssignMemberDialogState extends State<AssignMemberDialog> {
  String q = '';
  @override
  Widget build(BuildContext context) {
    final list = widget.members.where((m) {
      final queryMatches = '${m.name} ${m.phone}'.toLowerCase().contains(q.toLowerCase());
      return queryMatches;
    }).toList();
    return AlertDialog(
      title: Text('Assign ${widget.role == 'Cinematographer' ? 'Cinematic' : widget.role}'),
      content: SizedBox(width: 420, height: 420, child: Column(children: [
        TextField(onChanged: (v) => setState(() => q = v), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search member', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        Expanded(child: list.isEmpty ? const Center(child: Text('No team members. Add members from Team first.')) : ListView.builder(itemCount: list.length, itemBuilder: (_, i) { final m = list[i]; return ListTile(leading: CircleAvatar(child: Text(m.name.isEmpty ? '?' : m.name[0].toUpperCase())), title: Text(m.name), subtitle: Text('Team Member • ${m.phone}'), onTap: () => Navigator.pop(context, m)); })),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))],
    );
  }
}


class BrandProfile {
  final String name;
  final String contact;
  final String email;
  final String? logoBase64;

  const BrandProfile({
    required this.name,
    required this.contact,
    required this.email,
    required this.logoBase64,
  });
}

class BrandProfileDialog extends StatefulWidget {
  final String name;
  final String contact;
  final String email;
  final String? logoBase64;

  const BrandProfileDialog({
    super.key,
    required this.name,
    required this.contact,
    required this.email,
    required this.logoBase64,
  });

  @override
  State<BrandProfileDialog> createState() => _BrandProfileDialogState();
}

class _BrandProfileDialogState extends State<BrandProfileDialog> {
  late final TextEditingController name;
  late final TextEditingController contact;
  late final TextEditingController email;
  String? logoBase64;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.name);
    contact = TextEditingController(text: widget.contact);
    email = TextEditingController(text: widget.email);
    logoBase64 = widget.logoBase64;
  }

  Future<void> pickLogo() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1200);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() => logoBase64 = base64Encode(bytes));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: pickLogo,
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                  ),
                  alignment: Alignment.center,
                  child: logoBase64 == null
                      ? const Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add_photo_alternate_outlined), SizedBox(height: 4), Text('Logo')])
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.memory(base64Decode(logoBase64!), fit: BoxFit.contain, width: 90, height: 90),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(onPressed: pickLogo, icon: const Icon(Icons.upload_outlined), label: const Text('Upload Logo')),
              const SizedBox(height: 8),
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Brand Name', prefixIcon: Icon(Icons.business_outlined))),
              const SizedBox(height: 10),
              TextField(controller: contact, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Contact', prefixIcon: Icon(Icons.phone_outlined))),
              const SizedBox(height: 10),
              TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              BrandProfile(name: name.text.trim(), contact: contact.text.trim(), email: email.text.trim(), logoBase64: logoBase64),
            ),
            child: const Text('Save'),
          ),
        ],
      );

  @override
  void dispose() {
    name.dispose();
    contact.dispose();
    email.dispose();
    super.dispose();
  }
}

class EventPdfPage extends StatelessWidget {
  final EventData event;
  final BrandProfile profile;
  final List<TeamMember> team;

  const EventPdfPage({super.key, required this.event, required this.profile, required this.team});

  TeamMember? memberByName(String name) {
    for (final m in team) {
      if (m.name == name) return m;
    }
    return null;
  }

  String roleLabel(String role) => role == 'Cinematographer' ? 'Cinematic' : role;

  Future<Uint8List> buildPdf(PdfPageFormat format) async {
    final doc = pw.Document();
    pw.MemoryImage? logo;
    if (profile.logoBase64 != null && profile.logoBase64!.isNotEmpty) {
      try {
        logo = pw.MemoryImage(base64Decode(profile.logoBase64!));
      } catch (_) {}
    }

    final assignedRows = <List<String>>[];
    for (final entry in event.assignments.entries) {
      for (final name in entry.value) {
        final m = memberByName(name);
        assignedRows.add([roleLabel(entry.key), name, m?.phone ?? '']);
      }
      if (entry.value.isEmpty) {
        assignedRows.add([roleLabel(entry.key), 'Not assigned', '']);
      }
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(28),
        build: (_) => [
          if (logo != null || profile.name.isNotEmpty || profile.contact.isNotEmpty || profile.email.isNotEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 14),
              decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 2))),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (logo != null) pw.Container(width: 58, height: 58, margin: const pw.EdgeInsets.only(right: 12), child: pw.Image(logo, fit: pw.BoxFit.contain)),
                  pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    if (profile.name.isNotEmpty) pw.Text(profile.name, style: pw.TextStyle(fontSize: 19, fontWeight: pw.FontWeight.bold)),
                    if (profile.contact.isNotEmpty || profile.email.isNotEmpty)
                      pw.Padding(padding: const pw.EdgeInsets.only(top: 4), child: pw.Text([if (profile.contact.isNotEmpty) profile.contact, if (profile.email.isNotEmpty) profile.email].join('  |  '), style: const pw.TextStyle(fontSize: 9))),
                  ])),
                ],
              ),
            ),
          pw.SizedBox(height: 18),
          pw.Center(child: pw.Text('EVENT SUMMARY', style: pw.TextStyle(fontSize: 21, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 14),
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.8), borderRadius: pw.BorderRadius.circular(8)),
            child: pw.Table(
              columnWidths: const {0: pw.FlexColumnWidth(1), 1: pw.FlexColumnWidth(1)},
              children: [
                pw.TableRow(children: [
                  _pdfInfo('CLIENT NAME', event.client.isEmpty ? '—' : event.client),
                  _pdfInfo('EVENT TYPE', event.type),
                ]),
                pw.TableRow(children: [
                  _pdfInfo('DATE', '${event.date.day} ${_month(event.date.month)} ${event.date.year}'),
                  _pdfInfo('LOCATION / VENUE', event.venue),
                ]),
                pw.TableRow(children: [
                  _pdfInfo('TIME', event.time.isEmpty ? '—' : event.time),
                  _pdfInfo('CLIENT CONTACT', event.phone.isEmpty ? '—' : event.phone),
                ]),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text('ASSIGNED TEAM', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          assignedRows.isEmpty
              ? pw.Container(padding: const pw.EdgeInsets.all(12), child: pw.Text('No team members assigned.'))
              : pw.Table.fromTextArray(
                  headers: const ['ROLE', 'TEAM MEMBER', 'PHONE'],
                  data: assignedRows,
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                  cellStyle: const pw.TextStyle(fontSize: 10),
                  headerDecoration: const pw.BoxDecoration(),
                  border: pw.TableBorder.all(width: 0.5),
                  cellPadding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 7),
                ),
          if (event.notes.trim().isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Text('NOTES', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Container(width: double.infinity, padding: const pw.EdgeInsets.all(12), decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5), borderRadius: pw.BorderRadius.circular(6)), child: pw.Text(event.notes, style: const pw.TextStyle(fontSize: 10))),
          ],
        ],
      ),
    );
    return doc.save();
  }

  pw.Widget _pdfInfo(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.all(7),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 3),
          pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
        ]),
      );

  String _month(int m) => const ['', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][m];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Event PDF')),
        body: PdfPreview(
          canChangePageFormat: false,
          canChangeOrientation: false,
          allowPrinting: false,
          allowSharing: true,
          pdfFileName: '${event.client.isEmpty ? 'Event' : event.client}_${event.date.day}-${event.date.month}-${event.date.year}.pdf',
          build: buildPdf,
        ),
      );
}
