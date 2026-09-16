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

const Color purple = Color(0xFF6C3FF5);
const Color gold = Color(0xFFB18A4A);

const List<String> roles = <String>[
  'Candid',
  'Cinematic',
  'T. Photo',
  'T. Video',
  'Drone',
  'Helper',
];

const List<String> eventOptions = <String>[
  'Ganesh Pooja',
  'Haldi',
  'Sangeet',
  'Wedding',
  'Reception',
  'Engagement',
  'Pre Wedding',
  'Mehndi',
  'Kankotri Lekhan',
  'Mayra',
  'Baby Shower',
  'House Warming',
  'Corporate Event',
  'Other',
];

String dateShort(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String dateLong(DateTime d) {
  const months = <String>[
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${d.day} ${months[d.month]} ${d.year}';
}

String money(int value) {
  final s = value.toString();
  final out = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
    out.write(s[i]);
  }
  return '₹$out /-';
}

String cleanFileName(String value) {
  final v = value.trim().isEmpty ? 'Quotation' : value.trim();
  return v.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
}

class TeamMember {
  final String id;
  String name;
  String role;
  String phone;

  TeamMember({
    required this.id,
    required this.name,
    required this.role,
    required this.phone,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'role': role,
        'phone': phone,
      };

  factory TeamMember.fromJson(Map<String, dynamic> j) => TeamMember(
        id: j['id']?.toString() ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        name: j['name']?.toString() ?? '',
        role: j['role']?.toString() ?? 'Team Member',
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
  List<String> types;
  DateTime date;
  Map<String, List<String>> assignments;
  String groupId;

  EventData({
    required this.id,
    required this.name,
    required this.client,
    required this.phone,
    required this.venue,
    required this.time,
    required this.notes,
    required this.types,
    required this.date,
    required this.assignments,
    String? groupId,
  }) : groupId = groupId ?? id;

  String get type => types.join(', ');

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'client': client,
        'phone': phone,
        'venue': venue,
        'time': time,
        'notes': notes,
        'types': types,
        'type': type,
        'date': date.toIso8601String(),
        'assignments': assignments,
        'groupId': groupId,
      };

  factory EventData.fromJson(Map<String, dynamic> j) {
    final raw = Map<String, dynamic>.from(j['assignments'] ?? <String, dynamic>{});
    final a = <String, List<String>>{};
    for (final r in roles) {
      final value = raw[r];
      a[r] = value is List ? value.map((x) => x.toString()).toList() : <String>[];
    }
    final savedTypes = j['types'];
    final typeList = savedTypes is List
        ? savedTypes
            .map((x) => x.toString().trim())
            .where((x) => x.isNotEmpty)
            .toList()
        : (j['type']?.toString().split(',') ?? <String>[])
            .map((x) => x.trim())
            .where((x) => x.isNotEmpty)
            .toList();
    if (typeList.isEmpty) typeList.add('Wedding');

    return EventData(
      id: j['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: j['name']?.toString() ?? '',
      client: j['client']?.toString() ?? '',
      phone: j['phone']?.toString() ?? '',
      venue: j['venue']?.toString() ?? '',
      time: j['time']?.toString() ?? '',
      notes: j['notes']?.toString() ?? '',
      types: typeList,
      date: DateTime.tryParse(j['date']?.toString() ?? '') ?? DateTime.now(),
      assignments: a,
      groupId: j['groupId']?.toString(),
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

class QuotationEvent {
  String date;
  String event;
  String side;
  Map<String, int> requirements;

  QuotationEvent({
    required this.date,
    required this.event,
    required this.side,
    required this.requirements,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'date': date,
        'event': event,
        'side': side,
        'requirements': requirements,
      };

  factory QuotationEvent.fromJson(Map<String, dynamic> j) {
    final raw = j['requirements'];
    final req = <String, int>{};
    if (raw is Map) {
      raw.forEach((key, value) {
        req[key.toString()] = value is num ? value.toInt() : 0;
      });
    }
    return QuotationEvent(
      date: j['date']?.toString() ?? '',
      event: j['event']?.toString() ?? '',
      side: j['side']?.toString() ?? 'Both Side',
      requirements: req,
    );
  }
}

class QuotationDeliverable {
  String name;
  int quantity;

  QuotationDeliverable(this.name, this.quantity);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'quantity': quantity,
      };

  factory QuotationDeliverable.fromJson(Map<String, dynamic> j) =>
      QuotationDeliverable(
        j['name']?.toString() ?? '',
        (j['quantity'] as num?)?.toInt() ?? 1,
      );
}

class QuotationAlbum {
  String name;
  int quantity;
  int price;
  int photos;

  QuotationAlbum({
    required this.name,
    required this.quantity,
    required this.price,
    required this.photos,
  });

  int get total => quantity * price;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'quantity': quantity,
        'price': price,
        'photos': photos,
      };

  factory QuotationAlbum.fromJson(Map<String, dynamic> j) => QuotationAlbum(
        name: j['name']?.toString() ?? 'Wedding Album',
        quantity: (j['quantity'] as num?)?.toInt() ?? 1,
        price: (j['price'] as num?)?.toInt() ?? 0,
        photos: (j['photos'] as num?)?.toInt() ?? 400,
      );
}

class Quotation {
  String id;
  String client;
  String phone;
  String email;
  String createdDate;
  String tnc;
  List<QuotationEvent> events;
  List<QuotationDeliverable> deliverables;
  List<QuotationAlbum> albums;
  int shootCharges;
  int editingCharges;

  Quotation({
    required this.id,
    required this.client,
    required this.phone,
    required this.email,
    required this.createdDate,
    required this.events,
    required this.deliverables,
    required this.shootCharges,
    required this.editingCharges,
    required this.albums,
    required this.tnc,
  });

  int get albumTotal => albums.fold(0, (sum, a) => sum + a.total);
  int get total => shootCharges + editingCharges;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'client': client,
        'phone': phone,
        'email': email,
        'createdDate': createdDate,
        'events': events.map((e) => e.toJson()).toList(),
        'deliverables': deliverables.map((d) => d.toJson()).toList(),
        'shootCharges': shootCharges,
        'editingCharges': editingCharges,
        'albums': albums.map((a) => a.toJson()).toList(),
        'tnc': tnc,
      };

  factory Quotation.fromJson(Map<String, dynamic> j) => Quotation(
        id: j['id']?.toString() ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        client: j['client']?.toString() ?? '',
        phone: j['phone']?.toString() ?? '',
        email: j['email']?.toString() ?? '',
        createdDate: j['createdDate']?.toString() ?? '',
        events: (j['events'] as List? ?? const <dynamic>[])
            .map((x) => QuotationEvent.fromJson(Map<String, dynamic>.from(x)))
            .toList(),
        deliverables: (j['deliverables'] as List? ?? const <dynamic>[])
            .map((x) =>
                QuotationDeliverable.fromJson(Map<String, dynamic>.from(x)))
            .toList(),
        shootCharges: (j['shootCharges'] as num?)?.toInt() ?? 0,
        editingCharges: (j['editingCharges'] as num?)?.toInt() ?? 0,
        albums: (j['albums'] as List? ?? const <dynamic>[])
            .map((x) => QuotationAlbum.fromJson(Map<String, dynamic>.from(x)))
            .toList(),
        tnc: j['tnc']?.toString() ?? '',
      );
}

void main() => runApp(const CrewFlowApp());

class CrewFlowApp extends StatefulWidget {
  const CrewFlowApp({super.key});

  @override
  State<CrewFlowApp> createState() => _CrewFlowAppState();
}

class _CrewFlowAppState extends State<CrewFlowApp> {
  bool dark = true;
  bool checking = true;
  bool loggedIn = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (!mounted) return;
      setState(() {
        dark = p.getBool('dark') ?? true;
        loggedIn = p.getBool('loggedIn') ?? false;
        checking = false;
      });
    });
  }

  Future<void> toggleDark() async {
    final p = await SharedPreferences.getInstance();
    setState(() => dark = !dark);
    await p.setBool('dark', dark);
  }

  Future<void> login() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('loggedIn', true);
    if (mounted) setState(() => loggedIn = true);
  }

  Future<void> logout() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('loggedIn', false);
    if (mounted) setState(() => loggedIn = false);
  }

  @override
  Widget build(BuildContext context) {
    final light = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: purple,
      brightness: Brightness.light,
    );
    final darkTheme = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color(0xFF8B63FF),
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0B0B0F),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CrewFlow',
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      theme: light,
      darkTheme: darkTheme,
      home: checking
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : loggedIn
              ? CrewFlowHome(
                  dark: dark,
                  onDark: toggleDark,
                  onLogout: logout,
                )
              : LoginPage(onLogin: login),
    );
  }
}

class LoginPage extends StatefulWidget {
  final VoidCallback onLogin;

  const LoginPage({super.key, required this.onLogin});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool obscure = true;
  bool create = false;

  void submit() {
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password.')),
      );
      return;
    }
    widget.onLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                children: [
                  Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      color: purple.withOpacity(.16),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: purple,
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'CrewFlow',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Organize. Assign. Capture.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 42),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      create ? 'Create your account' : 'Welcome back',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: password,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => obscure = !obscure),
                        icon: Icon(
                          obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: submit,
                      child: Text(create ? 'Create Account' : 'Login'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('or'),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: submit,
                      icon: const Icon(Icons.g_mobiledata, size: 30),
                      label: const Text('Continue with Google'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => setState(() => create = !create),
                    child: Text(
                      create
                          ? 'Already have an account? Login'
                          : 'Don’t have an account? Create one',
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Your CrewFlow data stays on this device in this version.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }
}

class CrewFlowHome extends StatefulWidget {
  final bool dark;
  final VoidCallback onDark;
  final VoidCallback? onLogout;

  const CrewFlowHome({
    super.key,
    required this.dark,
    required this.onDark,
    this.onLogout,
  });

  @override
  State<CrewFlowHome> createState() => _CrewFlowHomeState();
}

class _CrewFlowHomeState extends State<CrewFlowHome> {
  int tab = 0;
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime selected = DateTime.now();

  List<EventData> events = <EventData>[];
  List<TeamMember> team = <TeamMember>[];
  List<Quotation> quotations = <Quotation>[];
  List<String> tcTemplates = <String>[];

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

    final loadedEvents = (p.getStringList('events') ?? <String>[])
        .map((x) {
          try {
            return EventData.fromJson(jsonDecode(x));
          } catch (_) {
            return null;
          }
        })
        .whereType<EventData>()
        .toList();

    final loadedTeam = (p.getStringList('team') ?? <String>[])
        .map((x) {
          try {
            return TeamMember.fromJson(jsonDecode(x));
          } catch (_) {
            return null;
          }
        })
        .whereType<TeamMember>()
        .toList();

    final loadedQuotes = (p.getStringList('quotations') ?? <String>[])
        .map((x) {
          try {
            return Quotation.fromJson(jsonDecode(x));
          } catch (_) {
            return null;
          }
        })
        .whereType<Quotation>()
        .toList();

    if (!mounted) return;
    setState(() {
      events = loadedEvents;
      team = loadedTeam;
      quotations = loadedQuotes;
      tcTemplates = p.getStringList('tcTemplates') ?? <String>[];
      brandName = p.getString('brandName') ?? '';
      brandContact = p.getString('brandContact') ?? '';
      brandEmail = p.getString('brandEmail') ?? '';
      logoBase64 = p.getString('logoBase64');
    });
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(
      'events',
      events.map((e) => jsonEncode(e.toJson())).toList(),
    );
    await p.setStringList(
      'team',
      team.map((e) => jsonEncode(e.toJson())).toList(),
    );
    await p.setStringList(
      'quotations',
      quotations.map((q) => jsonEncode(q.toJson())).toList(),
    );
    await p.setStringList('tcTemplates', tcTemplates);
    await p.setString('brandName', brandName);
    await p.setString('brandContact', brandContact);
    await p.setString('brandEmail', brandEmail);
    if (logoBase64 == null) {
      await p.remove('logoBase64');
    } else {
      await p.setString('logoBase64', logoBase64!);
    }
  }

  bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool sameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  List<EventData> dayEvents(DateTime d) =>
      events.where((e) => sameDay(e.date, d)).toList();

  List<EventData> monthEvents(DateTime d) {
    final result = events.where((e) => sameMonth(e.date, d)).toList();
    result.sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  void changeMonth(int delta) {
    final next = DateTime(month.year, month.month + delta);
    setState(() {
      month = next;
      selected = DateTime(next.year, next.month, 1);
    });
  }

  BrandProfile profile() => BrandProfile(
        name: brandName,
        contact: brandContact,
        email: brandEmail,
        logoBase64: logoBase64,
      );

  void openQuotation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuotationListPage(
          quotations: quotations,
          profile: profile(),
          tcTemplates: tcTemplates,
          onChanged: (q, tcs) async {
            setState(() {
              quotations = q;
              tcTemplates = tcs;
            });
            await save();
          },
        ),
      ),
    );
  }

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
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventPdfPage(
          events: <EventData>[event],
          profile: profile(),
          team: team,
        ),
      ),
    );
  }

  Future<void> addFromContacts() async {
    try {
      final allowed = await FlutterContacts.requestPermission();
      if (!allowed) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contacts permission is required.')),
          );
        }
        return;
      }

      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
      );

      if (!mounted) return;
      if (contacts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No contacts found.')),
        );
        return;
      }

      final picked = await showModalBottomSheet<Contact>(
        context: context,
        isScrollControlled: true,
        builder: (_) => ContactPickerSheet(contacts: contacts),
      );

      if (picked == null) return;
      final phone = picked.phones.isEmpty ? '' : picked.phones.first.number;

      if (phone.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This contact has no phone number.')),
        );
        return;
      }

      final normalized = phone.replaceAll(RegExp(r'\D'), '');
      final exists = team.any(
        (m) => m.phone.replaceAll(RegExp(r'\D'), '') == normalized,
      );

      if (!exists) {
        setState(() {
          team.add(
            TeamMember(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              name: picked.displayName ?? 'Unnamed Contact',
              role: 'Team Member',
              phone: phone,
            ),
          );
        });
        await save();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not read contacts. Check Contacts permission.'),
          ),
        );
      }
    }
  }

  Future<void> addTeamManually() async {
    final name = TextEditingController();
    final phone = TextEditingController();

    final result = await showDialog<TeamMember>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Team Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Mobile Number'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (name.text.trim().isEmpty || phone.text.trim().isEmpty) return;
              Navigator.pop(
                context,
                TeamMember(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  name: name.text.trim(),
                  role: 'Team Member',
                  phone: phone.text.trim(),
                ),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    name.dispose();
    phone.dispose();

    if (result == null || !mounted) return;
    final normalized = result.phone.replaceAll(RegExp(r'\D'), '');
    if (team.any((m) => m.phone.replaceAll(RegExp(r'\D'), '') == normalized)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This mobile number is already in the team.')),
      );
      return;
    }

    setState(() => team.add(result));
    await save();
  }

  Future<void> whatsapp(TeamMember member) async {
    final assigned = events
        .where(
          (e) => e.assignments.values.any((names) => names.contains(member.name)),
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (assigned.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No event is assigned to this team member.')),
      );
      return;
    }

    final lines = <String>[
      'Hi ${member.name},',
      '',
      'Your upcoming event assignments:',
      '',
    ];

    for (final e in assigned) {
      final assignedRoles = <String>[];
      for (final entry in e.assignments.entries) {
        if (entry.value.contains(member.name)) {
          assignedRoles.add(entry.key);
        }
      }
      lines.add('Date: ${dateLong(e.date)}');
      lines.add('Client: ${e.client.isEmpty ? e.name : e.client}');
      lines.add('Event: ${e.type}');
      lines.add('Role: ${assignedRoles.join(', ')}');
      lines.add('Location: ${e.venue}');
      if (e.time.isNotEmpty) lines.add('Time: ${e.time}');
      lines.add('');
    }

    lines.add('Please be available on time. Thank you.');

    final number = member.phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse(
      'https://wa.me/$number?text=${Uri.encodeComponent(lines.join('\n'))}',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp.')),
        );
      }
    }
  }

  Future<void> callMember(TeamMember member) async {
    final uri = Uri.parse('tel:${member.phone}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> deleteTeamMember(TeamMember member) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Team Member?'),
        content: Text('Remove ${member.name} from the team?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (yes != true) return;
    setState(() => team.removeWhere((m) => m.id == member.id));
    await save();
  }

  Widget top(String title, {List<Widget> actions = const <Widget>[]}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          Builder(
            builder: (ctx) => IconButton(
              onPressed: () => Scaffold.of(ctx).openDrawer(),
              icon: const Icon(Icons.menu),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          ...actions,
        ],
      ),
    );
  }

  Widget calendarPage() {
    final first = DateTime(month.year, month.month, 1);
    final days = DateTime(month.year, month.month + 1, 0).day;
    final offset = first.weekday % 7;
    final cells = ((offset + days + 6) ~/ 7) * 7;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < -100) changeMonth(1);
        if (velocity > 100) changeMonth(-1);
      },
      child: Stack(
        children: [
          Column(
            children: [
              top('Dashboard'),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => changeMonth(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text(
                    '${_monthName(month.month)} ${month.year}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    onPressed: () => changeMonth(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: const [
                    'SUN',
                    'MON',
                    'TUE',
                    'WED',
                    'THU',
                    'FRI',
                    'SAT',
                  ]
                      .map(
                        (x) => Expanded(
                          child: Center(
                            child: Text(
                              x,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 300,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: cells,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                  ),
                  itemBuilder: (_, i) {
                    if (i < offset || i >= offset + days) {
                      return const SizedBox();
                    }
                    final d = DateTime(
                      month.year,
                      month.month,
                      i - offset + 1,
                    );
                    final day = dayEvents(d);
                    final selectedDay = sameDay(d, selected);

                    return GestureDetector(
                      onTap: () => setState(() => selected = d),
                      child: Container(
                        margin: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: selectedDay ? purple : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${d.day}',
                              style: TextStyle(
                                color: selectedDay ? Colors.white : null,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (day.isNotEmpty)
                              Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.only(top: 3),
                                decoration: BoxDecoration(
                                  color:
                                      selectedDay ? Colors.white : purple,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_monthName(month.month)} ${month.year} Events',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text('${monthEvents(month).length} Events'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...monthEvents(month).map(eventCard),
                    if (monthEvents(month).isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('No events booked this month')),
                      ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            right: 18,
            bottom: 18,
            child: FloatingActionButton(
              heroTag: 'calendarAdd',
              onPressed: () => openEvent(
                initialDate: DateTime(
                  selected.year,
                  selected.month,
                  selected.day,
                ),
              ),
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }

  Widget eventCard(EventData e, {bool pdfOnly = false}) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => pdfOnly ? openEventPdf(e) : openEvent(existing: e),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 5,
                height: 84,
                decoration: BoxDecoration(
                  color: purple,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.client.isEmpty ? e.name : e.client,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${dateShort(e.date)}  •  ${e.type}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      e.venue,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (e.time.isNotEmpty)
                      Text('Time: ${e.time}', style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Open PDF',
                onPressed: () => openEventPdf(e),
                icon: const Icon(Icons.picture_as_pdf_outlined),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget eventsPage() {
    final filtered = events.where((e) {
      final q = search.toLowerCase().trim();
      if (q.isEmpty) return true;
      return '${e.client} ${e.name} ${e.venue} ${e.type}'
          .toLowerCase()
          .contains(q);
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return Column(
      children: [
        top(
          'Events',
          actions: [
            IconButton(
              onPressed: () => openEvent(),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
          child: TextField(
            onChanged: (v) => setState(() => search = v),
            decoration: const InputDecoration(
              hintText: 'Search client, location or event',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No events found'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: filtered.map((e) => eventCard(e)).toList(),
                ),
        ),
      ],
    );
  }

  Widget teamPage() {
    return Column(
      children: [
        top(
          'Team',
          actions: [
            IconButton(
              tooltip: 'Add from contacts',
              onPressed: addFromContacts,
              icon: const Icon(Icons.contacts_outlined),
            ),
            IconButton(
              tooltip: 'Add manually',
              onPressed: addTeamManually,
              icon: const Icon(Icons.person_add_alt_1),
            ),
          ],
        ),
        Expanded(
          child: team.isEmpty
              ? const Center(
                  child: Text('No team members yet. Add from contacts.'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: team.length,
                  itemBuilder: (_, i) {
                    final member = team[i];
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        leading: CircleAvatar(
                          child: Text(
                            member.name.isEmpty
                                ? '?'
                                : member.name[0].toUpperCase(),
                          ),
                        ),
                        title: Text(
                          member.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(member.phone),
                        trailing: Wrap(
                          children: [
                            IconButton(
                              tooltip: 'WhatsApp',
                              onPressed: () => whatsapp(member),
                              icon: const Icon(Icons.chat_outlined),
                            ),
                            IconButton(
                              tooltip: 'Call',
                              onPressed: () => callMember(member),
                              icon: const Icon(Icons.call_outlined),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              onPressed: () => deleteTeamMember(member),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget morePage() {
    return ListView(
      children: [
        top('More'),
        ListTile(
          leading: const Icon(Icons.request_quote_outlined),
          title: const Text('Quotation'),
          subtitle: const Text('Create professional wedding quotations'),
          trailing: const Icon(Icons.chevron_right),
          onTap: openQuotation,
        ),
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: const Text('Profile'),
          subtitle: Text(
            brandName.isEmpty ? 'Add logo and business details' : brandName,
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: openProfile,
        ),
        SwitchListTile(
          value: widget.dark,
          onChanged: (_) => widget.onDark(),
          secondary: const Icon(Icons.dark_mode_outlined),
          title: const Text('Dark mode'),
        ),
        ListTile(
          leading: const Icon(Icons.event_note_outlined),
          title: const Text('Manage Events'),
          subtitle: const Text('Search, edit or delete booked events'),
          onTap: () => setState(() => tab = 1),
        ),
        if (widget.onLogout != null)
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: widget.onLogout,
          ),
      ],
    );
  }

  Future<void> openEvent({EventData? existing, DateTime? initialDate}) async {
    final result = await Navigator.push<List<EventData>>(
      context,
      MaterialPageRoute(
        builder: (_) => EventEditorPage(
          existing: existing,
          groupEvents: existing == null
              ? const <EventData>[]
              : events.where((x) => x.groupId == existing.groupId).toList()
                ..sort((a, b) => a.date.compareTo(b.date)),
          team: team,
          initialDate: initialDate,
        ),
      ),
    );

    if (result == null || !mounted) return;

    final groupId = result.first.groupId;
    setState(() {
      events.removeWhere((e) => e.groupId == groupId);
      events.addAll(result);
    });
    await save();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      calendarPage(),
      eventsPage(),
      teamPage(),
      morePage(),
    ];

    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const SizedBox(height: 20),
              const ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 20),
                leading: CircleAvatar(
                  backgroundColor: purple,
                  child: Icon(Icons.work_outline, color: Colors.white),
                ),
                title: Text(
                  'CrewFlow',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                subtitle: Text('Organize. Assign. Capture.'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.calendar_month_outlined),
                title: const Text('Calendar'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => tab = 0);
                },
              ),
              ListTile(
                leading: const Icon(Icons.event_outlined),
                title: const Text('Events'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => tab = 1);
                },
              ),
              ListTile(
                leading: const Icon(Icons.groups_outlined),
                title: const Text('Team'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => tab = 2);
                },
              ),
              ListTile(
                leading: const Icon(Icons.request_quote_outlined),
                title: const Text('Quotation'),
                onTap: () {
                  Navigator.pop(context);
                  openQuotation();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Profile'),
                onTap: () {
                  Navigator.pop(context);
                  openProfile();
                },
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(child: pages[tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event),
            label: 'Events',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Team',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }

  String _monthName(int m) {
    const names = <String>[
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[m];
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
    final list = widget.contacts.where((c) {
      final value = '${c.displayName} ${c.phones.map((p) => p.number).join(' ')}';
      return value.toLowerCase().contains(q.toLowerCase());
    }).toList();

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * .78,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Select Contact',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (v) => setState(() => q = v),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search contacts',
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final c = list[i];
                  return ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person_outline),
                    ),
                    title: Text(c.displayName ?? 'Unnamed Contact'),
                    subtitle: Text(
                      c.phones.isEmpty ? 'No phone number' : c.phones.first.number,
                    ),
                    onTap: () => Navigator.pop(context, c),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EventDraft {
  DateTime date;
  String venue;
  String time;
  String notes;
  List<String> types;
  Map<String, List<String>> assignments;

  EventDraft({
    required this.date,
    required this.venue,
    required this.time,
    required this.notes,
    required this.types,
    required this.assignments,
  });

  factory EventDraft.fromEvent(EventData e) => EventDraft(
        date: e.date,
        venue: e.venue,
        time: e.time,
        notes: e.notes,
        types: List<String>.from(e.types),
        assignments: e.assignments.map(
          (key, value) => MapEntry(key, List<String>.from(value)),
        ),
      );
}

class EventEditorPage extends StatefulWidget {
  final EventData? existing;
  final List<EventData> groupEvents;
  final List<TeamMember> team;
  final DateTime? initialDate;

  const EventEditorPage({
    super.key,
    this.existing,
    required this.groupEvents,
    required this.team,
    this.initialDate,
  });

  @override
  State<EventEditorPage> createState() => _EventEditorPageState();
}

class _EventEditorPageState extends State<EventEditorPage> {
  final client = TextEditingController();
  final phone = TextEditingController();

  late List<EventDraft> drafts;
  int current = 0;
  bool assigning = false;

  @override
  void initState() {
    super.initState();

    if (widget.groupEvents.isNotEmpty) {
      drafts = widget.groupEvents.map(EventDraft.fromEvent).toList();
    } else {
      drafts = <EventDraft>[
        EventDraft(
          date: widget.initialDate ?? DateTime.now(),
          venue: '',
          time: '',
          notes: '',
          types: <String>['Wedding'],
          assignments: <String, List<String>>{
            for (final r in roles) r: <String>[],
          },
        ),
      ];
    }

    client.text = widget.existing?.client ?? '';
    phone.text = widget.existing?.phone ?? '';
  }

  EventDraft get draft => drafts[current];

  Future<void> pickDate() async {
    final result = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: draft.date,
    );
    if (result != null) {
      setState(() => draft.date = result);
    }
  }

  Future<void> pickTime() async {
    final result = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (result != null) {
      setState(() => draft.time = result.format(context));
    }
  }

  Future<void> addType() async {
    final value = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: eventOptions
              .map(
                (x) => ListTile(
                  title: Text(x),
                  onTap: () => Navigator.pop(context, x),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (value == null || draft.types.contains(value)) return;
    setState(() => draft.types.add(value));
  }

  Future<void> assignRole(String role) async {
    if (assigning) return;
    setState(() => assigning = true);

    final selectedNames = await showDialog<List<String>>(
      context: context,
      builder: (_) => AssignMemberDialog(
        role: role,
        members: widget.team,
        already: draft.assignments[role] ?? <String>[],
      ),
    );

    if (mounted) {
      setState(() {
        assigning = false;
        if (selectedNames != null) {
          draft.assignments[role] = selectedNames;
        }
      });
    }
  }

  void addDate() {
    final last = drafts.last.date;
    setState(() {
      drafts.add(
        EventDraft(
          date: last.add(const Duration(days: 1)),
          venue: '',
          time: '',
          notes: '',
          types: <String>['Wedding'],
          assignments: <String, List<String>>{
            for (final r in roles) r: <String>[],
          },
        ),
      );
      current = drafts.length - 1;
    });
  }

  void removeDate(int index) {
    if (drafts.length == 1) return;
    setState(() {
      drafts.removeAt(index);
      if (current >= drafts.length) current = drafts.length - 1;
    });
  }

  void saveEvent() {
    final c = client.text.trim();
    if (c.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Client Name.')),
      );
      return;
    }

    for (final d in drafts) {
      if (d.venue.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter Venue for every date.')),
        );
        return;
      }
      if (d.types.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an Event Type.')),
        );
        return;
      }
    }

    final groupId = widget.existing?.groupId ??
        DateTime.now().microsecondsSinceEpoch.toString();

    final result = <EventData>[];
    for (var i = 0; i < drafts.length; i++) {
      final d = drafts[i];
      final old = i < widget.groupEvents.length ? widget.groupEvents[i] : null;
      result.add(
        EventData(
          id: old?.id ??
              DateTime.now().microsecondsSinceEpoch.toString() +
                  i.toString(),
          name: widget.existing?.name ?? '',
          client: c,
          phone: phone.text.trim(),
          venue: d.venue.trim(),
          time: d.time.trim(),
          notes: d.notes.trim(),
          types: List<String>.from(d.types),
          date: DateTime(d.date.year, d.date.month, d.date.day),
          assignments: d.assignments.map(
            (key, value) => MapEntry(key, List<String>.from(value)),
          ),
          groupId: groupId,
        ),
      );
    }

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final d = draft;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Add Event' : 'Edit Event'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: client,
            decoration: const InputDecoration(
              labelText: 'Client Name',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Mobile Number',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Text(
                'Event Dates',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: addDate,
                icon: const Icon(Icons.add),
                label: const Text('Add Date'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 54,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: drafts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                return ChoiceChip(
                  selected: i == current,
                  label: Text(
                    'Day ${i + 1}  •  ${dateShort(drafts[i].date)}',
                  ),
                  onSelected: (_) => setState(() => current = i),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Date & Location',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      if (drafts.length > 1)
                        IconButton(
                          onPressed: () => removeDate(current),
                          icon: const Icon(Icons.delete_outline),
                        ),
                    ],
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_month_outlined),
                    title: const Text('Date'),
                    subtitle: Text(dateLong(d.date)),
                    onTap: pickDate,
                  ),
                  TextField(
                    onChanged: (v) => d.venue = v,
                    controller: TextEditingController(text: d.venue),
                    decoration: const InputDecoration(
                      labelText: 'Location / Venue',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (v) => d.time = v,
                    controller: TextEditingController(text: d.time),
                    decoration: const InputDecoration(
                      labelText: 'Time',
                      prefixIcon: Icon(Icons.access_time_outlined),
                    ),
                    onTap: pickTime,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (v) => d.notes = v,
                    controller: TextEditingController(text: d.notes),
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Event Type',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...d.types.map(
                        (type) => InputChip(
                          label: Text(type),
                          onDeleted: d.types.length == 1
                              ? null
                              : () => setState(() => d.types.remove(type)),
                        ),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.add, size: 18),
                        label: const Text('Add Event Type'),
                        onPressed: addType,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Crew Assignment',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  ...roles.map(
                    (role) {
                      final names = d.assignments[role] ?? <String>[];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          child: Icon(_roleIcon(role)),
                        ),
                        title: Text(
                          role,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          names.isEmpty
                              ? 'Not assigned'
                              : names.join(', '),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => assignRole(role),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: saveEvent,
              icon: const Icon(Icons.save),
              label: const Text('Save Event'),
            ),
          ),
        ],
      ),
    );
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'Candid':
        return Icons.camera_alt_outlined;
      case 'Cinematic':
        return Icons.movie_creation_outlined;
      case 'T. Photo':
        return Icons.photo_camera_outlined;
      case 'T. Video':
        return Icons.videocam_outlined;
      case 'Drone':
        return Icons.flight_outlined;
      default:
        return Icons.person_outline;
    }
  }

  @override
  void dispose() {
    client.dispose();
    phone.dispose();
    super.dispose();
  }
}

class AssignMemberDialog extends StatefulWidget {
  final String role;
  final List<TeamMember> members;
  final List<String> already;

  const AssignMemberDialog({
    super.key,
    required this.role,
    required this.members,
    required this.already,
  });

  @override
  State<AssignMemberDialog> createState() => _AssignMemberDialogState();
}

class _AssignMemberDialogState extends State<AssignMemberDialog> {
  String query = '';
  late Set<String> selected;

  @override
  void initState() {
    super.initState();
    selected = widget.already.toSet();
  }

  @override
  Widget build(BuildContext context) {
    final list = widget.members.where((m) {
      return '${m.name} ${m.phone}'
          .toLowerCase()
          .contains(query.toLowerCase());
    }).toList();

    return AlertDialog(
      title: Text('Assign ${widget.role}'),
      content: SizedBox(
        width: 430,
        height: 430,
        child: Column(
          children: [
            TextField(
              onChanged: (v) => setState(() => query = v),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search member',
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: list.isEmpty
                  ? const Center(child: Text('No team members found.'))
                  : ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final m = list[i];
                        return CheckboxListTile(
                          value: selected.contains(m.name),
                          onChanged: (v) {
                            setState(() {
                              if (v == true) {
                                selected.add(m.name);
                              } else {
                                selected.remove(m.name);
                              }
                            });
                          },
                          title: Text(m.name),
                          subtitle: Text(m.phone),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, selected.toList()),
          child: const Text('Done'),
        ),
      ],
    );
  }
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
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (mounted) setState(() => logoBase64 = base64Encode(bytes));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Profile'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: logoBase64 == null
                  ? const Icon(Icons.add_photo_alternate_outlined, size: 40)
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.memory(
                        base64Decode(logoBase64!),
                        fit: BoxFit.contain,
                      ),
                    ),
            ),
            TextButton.icon(
              onPressed: pickLogo,
              icon: const Icon(Icons.upload_outlined),
              label: const Text('Upload Logo'),
            ),
            TextField(
              controller: name,
              decoration: const InputDecoration(
                labelText: 'Brand Name',
                prefixIcon: Icon(Icons.business_outlined),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: contact,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Contact',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            BrandProfile(
              name: name.text.trim(),
              contact: contact.text.trim(),
              email: email.text.trim(),
              logoBase64: logoBase64,
            ),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    name.dispose();
    contact.dispose();
    email.dispose();
    super.dispose();
  }
}

class QuotationListPage extends StatefulWidget {
  final List<Quotation> quotations;
  final BrandProfile profile;
  final List<String> tcTemplates;
  final Future<void> Function(List<Quotation>, List<String>) onChanged;

  const QuotationListPage({
    super.key,
    required this.quotations,
    required this.profile,
    required this.tcTemplates,
    required this.onChanged,
  });

  @override
  State<QuotationListPage> createState() => _QuotationListPageState();
}

class _QuotationListPageState extends State<QuotationListPage> {
  late List<Quotation> qs;
  late List<String> tcs;

  @override
  void initState() {
    super.initState();
    qs = List<Quotation>.from(widget.quotations);
    tcs = List<String>.from(widget.tcTemplates);
  }

  Future<void> persist() => widget.onChanged(qs, tcs);

  Future<void> edit([Quotation? quotation]) async {
    final result = await Navigator.push<Quotation>(
      context,
      MaterialPageRoute(
        builder: (_) => QuotationEditorPage(
          initial: quotation,
          profile: widget.profile,
          tcTemplates: tcs,
          onTemplatesChanged: (value) => tcs = value,
        ),
      ),
    );

    if (result == null) return;
    setState(() {
      qs.removeWhere((x) => x.id == result.id);
      qs.add(result);
      qs.sort((a, b) => b.createdDate.compareTo(a.createdDate));
    });
    await persist();
  }

  Future<void> delete(Quotation q) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Quotation?'),
        content: Text('Delete quotation for ${q.client}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    setState(() => qs.removeWhere((x) => x.id == q.id));
    await persist();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quotations'),
        actions: [
          IconButton(
            onPressed: () => edit(),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => edit(),
        child: const Icon(Icons.add),
      ),
      body: qs.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.request_quote_outlined, size: 54),
                  SizedBox(height: 12),
                  Text(
                    'No quotations yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text('Create your first professional quotation'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: qs.length,
              itemBuilder: (_, i) {
                final q = qs[i];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(14),
                    leading: CircleAvatar(
                      backgroundColor: purple.withOpacity(.16),
                      child: const Icon(
                        Icons.request_quote_outlined,
                        color: purple,
                      ),
                    ),
                    title: Text(
                      q.client.isEmpty ? 'Untitled Quotation' : q.client,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${q.events.length} event${q.events.length == 1 ? '' : 's'} • ${q.createdDate}\n${money(q.total)}',
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') await edit(q);
                        if (value == 'pdf') {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QuotationPdfPage(
                                quotation: q,
                                profile: widget.profile,
                              ),
                            ),
                          );
                        }
                        if (value == 'delete') await delete(q);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                        PopupMenuItem(
                          value: 'pdf',
                          child: Text('Open PDF'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class QuotationEditorPage extends StatefulWidget {
  final Quotation? initial;
  final BrandProfile profile;
  final List<String> tcTemplates;
  final ValueChanged<List<String>> onTemplatesChanged;

  const QuotationEditorPage({
    super.key,
    this.initial,
    required this.profile,
    required this.tcTemplates,
    required this.onTemplatesChanged,
  });

  @override
  State<QuotationEditorPage> createState() => _QuotationEditorPageState();
}

class _QuotationEditorPageState extends State<QuotationEditorPage> {
  late final TextEditingController client;
  late final TextEditingController phone;
  late final TextEditingController email;
  late final TextEditingController shoot;
  late final TextEditingController editing;
  late final TextEditingController tnc;

  late List<QuotationEvent> events;
  late List<QuotationDeliverable> deliverables;
  late List<QuotationAlbum> albums;
  late List<String> templates;

  final deliveryOptions = <String>[
    'Reels',
    'Teaser',
    'Cinematic Highlight',
    'Full Video',
    'Short Film',
  ];

  final requirementOptions = <String>[
    'Photographer',
    'Videographer',
    'Candid',
    'Cinematographer',
    'Drone',
    'Helper',
  ];

  @override
  void initState() {
    super.initState();
    final q = widget.initial;

    client = TextEditingController(text: q?.client ?? '');
    phone = TextEditingController(text: q?.phone ?? '');
    email = TextEditingController(text: q?.email ?? '');
    shoot = TextEditingController(
      text: q == null ? '' : q.shootCharges.toString(),
    );
    editing = TextEditingController(
      text: q == null ? '' : q.editingCharges.toString(),
    );
    tnc = TextEditingController(text: q?.tnc ?? '');

    events = q?.events
            .map(
              (e) => QuotationEvent(
                date: e.date,
                event: e.event,
                side: e.side,
                requirements: Map<String, int>.from(e.requirements),
              ),
            )
            .toList() ??
        <QuotationEvent>[];

    deliverables = q?.deliverables
            .map((d) => QuotationDeliverable(d.name, d.quantity))
            .toList() ??
        <QuotationDeliverable>[
          QuotationDeliverable('Reels', 4),
          QuotationDeliverable('Teaser', 1),
          QuotationDeliverable('Cinematic Highlight', 1),
          QuotationDeliverable('Full Video', 1),
        ];

    albums = q?.albums
            .map(
              (a) => QuotationAlbum(
                name: a.name,
                quantity: a.quantity,
                price: a.price,
                photos: a.photos,
              ),
            )
            .toList() ??
        <QuotationAlbum>[];

    templates = List<String>.from(widget.tcTemplates);
  }

  int parse(TextEditingController c) =>
      int.tryParse(c.text.replaceAll(',', '').trim()) ?? 0;

  int get total => parse(shoot) + parse(editing);

  Future<void> addEvent() async {
    DateTime selectedDate = DateTime.now();
    String event = eventOptions.first;
    String side = 'Both Side';
    final req = <String, int>{};

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Add Quotation Event'),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_month_outlined),
                      title: Text(dateLong(selectedDate)),
                      onTap: () async {
                        final d = await showDatePicker(
                          context: ctx,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          initialDate: selectedDate,
                        );
                        if (d != null) {
                          setDialogState(() => selectedDate = d);
                        }
                      },
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: event,
                      decoration: const InputDecoration(labelText: 'Event'),
                      items: eventOptions
                          .map(
                            (x) => DropdownMenuItem<String>(
                              value: x,
                              child: Text(x),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setDialogState(() => event = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: side,
                      decoration: const InputDecoration(labelText: 'Side'),
                      items: const [
                        DropdownMenuItem(
                          value: 'Bride Side',
                          child: Text('Bride Side'),
                        ),
                        DropdownMenuItem(
                          value: 'Groom Side',
                          child: Text('Groom Side'),
                        ),
                        DropdownMenuItem(
                          value: 'Both Side',
                          child: Text('Both Side'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setDialogState(() => side = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Coverage Requirements',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    ...requirementOptions.map(
                      (r) => Row(
                        children: [
                          Expanded(child: Text(r)),
                          IconButton(
                            onPressed: () => setDialogState(() {
                              req[r] = ((req[r] ?? 0) - 1).clamp(0, 99);
                            }),
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text(
                            '${req[r] ?? 0}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          IconButton(
                            onPressed: () => setDialogState(() {
                              req[r] = (req[r] ?? 0) + 1;
                            }),
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Add Event'),
              ),
            ],
          );
        },
      ),
    );

    if (ok != true) return;

    setState(() {
      events.add(
        QuotationEvent(
          date: dateShort(selectedDate),
          event: event,
          side: side,
          requirements: req,
        ),
      );
    });
  }

  Future<void> editEvent(int index) async {
    final old = events[index];
    DateTime selectedDate = _parseDate(old.date);
    String event = old.event;
    String side = old.side;
    final req = Map<String, int>.from(old.requirements);

    final result = await showDialog<QuotationEvent>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Event'),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(dateLong(selectedDate)),
                      onTap: () async {
                        final d = await showDatePicker(
                          context: ctx,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          initialDate: selectedDate,
                        );
                        if (d != null) {
                          setDialogState(() => selectedDate = d);
                        }
                      },
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: event,
                      items: eventOptions
                          .map(
                            (x) => DropdownMenuItem(
                              value: x,
                              child: Text(x),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setDialogState(() => event = v);
                      },
                      decoration: const InputDecoration(labelText: 'Event'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: side,
                      items: const [
                        DropdownMenuItem(
                          value: 'Bride Side',
                          child: Text('Bride Side'),
                        ),
                        DropdownMenuItem(
                          value: 'Groom Side',
                          child: Text('Groom Side'),
                        ),
                        DropdownMenuItem(
                          value: 'Both Side',
                          child: Text('Both Side'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setDialogState(() => side = v);
                      },
                      decoration: const InputDecoration(labelText: 'Side'),
                    ),
                    const SizedBox(height: 12),
                    ...requirementOptions.map(
                      (r) => Row(
                        children: [
                          Expanded(child: Text(r)),
                          IconButton(
                            onPressed: () => setDialogState(() {
                              req[r] = ((req[r] ?? 0) - 1).clamp(0, 99);
                            }),
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text('${req[r] ?? 0}'),
                          IconButton(
                            onPressed: () => setDialogState(() {
                              req[r] = (req[r] ?? 0) + 1;
                            }),
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(
                  ctx,
                  QuotationEvent(
                    date: dateShort(selectedDate),
                    event: event,
                    side: side,
                    requirements: req,
                  ),
                ),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    if (result != null) setState(() => events[index] = result);
  }

  DateTime _parseDate(String value) {
    final parts = value.split('/');
    if (parts.length == 3) {
      return DateTime(
        int.tryParse(parts[2]) ?? DateTime.now().year,
        int.tryParse(parts[1]) ?? DateTime.now().month,
        int.tryParse(parts[0]) ?? DateTime.now().day,
      );
    }
    return DateTime.now();
  }

  Future<void> manageTemplates() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Saved T&C Templates'),
        content: SizedBox(
          width: 500,
          child: templates.isEmpty
              ? const Text('No saved templates yet.')
              : ListView(
                  shrinkWrap: true,
                  children: templates
                      .asMap()
                      .entries
                      .map(
                        (entry) => ListTile(
                          title: Text(
                            'Template ${entry.key + 1}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            entry.value,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            tnc.text = entry.value;
                            Navigator.pop(ctx);
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () {
                              setState(() => templates.removeAt(entry.key));
                              widget.onTemplatesChanged(
                                List<String>.from(templates),
                              );
                              Navigator.pop(ctx);
                            },
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );

    controller.dispose();
  }

  void saveTemplate() {
    final value = tnc.text.trim();
    if (value.isEmpty) return;
    setState(() => templates.add(value));
    widget.onTemplatesChanged(List<String>.from(templates));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('T&C template saved.')),
    );
  }

  void saveQuotation() {
    if (client.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Client Name.')),
      );
      return;
    }

    if (events.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one event.')),
      );
      return;
    }

    final q = Quotation(
      id: widget.initial?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      client: client.text.trim(),
      phone: phone.text.trim(),
      email: email.text.trim(),
      createdDate: dateShort(DateTime.now()),
      events: events,
      deliverables: deliverables
          .where((d) => d.name.trim().isNotEmpty && d.quantity > 0)
          .toList(),
      shootCharges: parse(shoot),
      editingCharges: parse(editing),
      albums: albums,
      tnc: tnc.text.trim(),
    );

    Navigator.pop(context, q);
  }

  Widget section(String title, Widget child) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initial == null ? 'Create Quotation' : 'Edit Quotation',
        ),
        actions: [
          IconButton(
            tooltip: 'T&C templates',
            onPressed: manageTemplates,
            icon: const Icon(Icons.description_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          section(
            'Client Details',
            Column(
              children: [
                TextField(
                  controller: client,
                  decoration: const InputDecoration(
                    labelText: 'Client Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email (optional)',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
              ],
            ),
          ),
          section(
            'Event Coverage',
            Column(
              children: [
                if (events.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('No events added yet.'),
                  ),
                ...events.asMap().entries.map(
                  (entry) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.calendar_month_outlined),
                      title: Text(
                        '${entry.value.date}  •  ${entry.value.event}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${entry.value.side}\n${_requirementsText(entry.value.requirements)}',
                      ),
                      isThreeLine: true,
                      onTap: () => editEvent(entry.key),
                      trailing: IconButton(
                        onPressed: () =>
                            setState(() => events.removeAt(entry.key)),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: addEvent,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Event / Date'),
                  ),
                ),
              ],
            ),
          ),
          section(
            'Deliverables',
            Column(
              children: [
                ...deliverables.asMap().entries.map(
                  (entry) => Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: entry.value.name,
                          items: deliveryOptions
                              .map(
                                (x) => DropdownMenuItem(
                                  value: x,
                                  child: Text(x),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => entry.value.name = v);
                            }
                          },
                          decoration:
                              const InputDecoration(labelText: 'Deliverable'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 90,
                        child: TextFormField(
                          initialValue: '${entry.value.quantity}',
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Qty'),
                          onChanged: (v) {
                            entry.value.quantity = int.tryParse(v) ?? 0;
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            setState(() => deliverables.removeAt(entry.key)),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => setState(
                      () => deliverables.add(
                        QuotationDeliverable('Reels', 1),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Deliverable'),
                  ),
                ),
              ],
            ),
          ),
          section(
            'Investment',
            Column(
              children: [
                TextField(
                  controller: shoot,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Photography & Cinematography',
                    prefixText: '₹ ',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: editing,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Video Editing Charges',
                    prefixText: '₹ ',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: purple.withOpacity(.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Total Package',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const Spacer(),
                      Text(
                        money(total),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          section(
            'Albums — Optional / Extra',
            Column(
              children: [
                ...albums.asMap().entries.map(
                  (entry) {
                    final album = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: album.name,
                                    decoration: const InputDecoration(
                                      labelText: 'Album Name',
                                    ),
                                    onChanged: (v) => album.name = v,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => setState(
                                    () => albums.removeAt(entry.key),
                                  ),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: '${album.quantity}',
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Albums',
                                    ),
                                    onChanged: (v) {
                                      album.quantity = int.tryParse(v) ?? 1;
                                      setState(() {});
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: '${album.photos}',
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Photos / Album',
                                    ),
                                    onChanged: (v) {
                                      album.photos = int.tryParse(v) ?? 0;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: '${album.price}',
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Price / Album',
                                    ),
                                    onChanged: (v) {
                                      album.price = int.tryParse(v) ?? 0;
                                      setState(() {});
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Total: ${money(album.total)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => setState(
                      () => albums.add(
                        QuotationAlbum(
                          name: 'Wedding Album',
                          quantity: 1,
                          price: 0,
                          photos: 400,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Album'),
                  ),
                ),
                if (albums.isNotEmpty)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Album Charges: ${money(albums.fold(0, (s, a) => s + a.total))} extra',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          section(
            'Terms & Conditions',
            Column(
              children: [
                if (templates.isNotEmpty)
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Select Saved T&C',
                    ),
                    items: templates
                        .asMap()
                        .entries
                        .map(
                          (entry) => DropdownMenuItem<String>(
                            value: entry.value,
                            child: Text(
                              'Template ${entry.key + 1}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => tnc.text = v);
                    },
                  ),
                if (templates.isNotEmpty) const SizedBox(height: 10),
                TextField(
                  controller: tnc,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    hintText: 'Write T&C for this quotation...',
                    alignLabelWithHint: true,
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: saveTemplate,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save as new T&C template'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: saveQuotation,
              icon: const Icon(Icons.save),
              label: const Text('Save Quotation & Open PDF'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _requirementsText(Map<String, int> req) {
    final values = req.entries
        .where((x) => x.value > 0)
        .map((x) => '${x.key} x ${x.value}')
        .toList();
    return values.isEmpty ? 'No crew selected' : values.join('  +  ');
  }

  @override
  void dispose() {
    client.dispose();
    phone.dispose();
    email.dispose();
    shoot.dispose();
    editing.dispose();
    tnc.dispose();
    super.dispose();
  }
}

class QuotationPdfPage extends StatelessWidget {
  final Quotation quotation;
  final BrandProfile profile;

  const QuotationPdfPage({
    super.key,
    required this.quotation,
    required this.profile,
  });

  Future<Uint8List> buildPdf(PdfPageFormat format) async {
    final doc = pw.Document();

    pw.MemoryImage? logo;
    if (profile.logoBase64 != null && profile.logoBase64!.isNotEmpty) {
      try {
        logo = pw.MemoryImage(base64Decode(profile.logoBase64!));
      } catch (_) {}
    }

    final rows = quotation.events.map((e) {
      final coverage = e.requirements.entries
          .where((x) => x.value > 0)
          .map((x) => '${x.key} x ${x.value}')
          .join('  +  ');
      return <String>[
        e.date,
        '${e.event} - ${e.side}',
        coverage.isEmpty ? 'Not specified' : coverage,
      ];
    }).toList();

    final bodyText = <pw.Widget>[];

    bodyText.add(
      pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 10),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.black, width: 1.2),
          ),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (logo != null)
              pw.Container(
                width: 58,
                height: 58,
                margin: const pw.EdgeInsets.only(right: 12),
                child: pw.Image(logo, fit: pw.BoxFit.contain),
              ),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    profile.name.isEmpty ? 'CREWFLOW' : profile.name.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'WEDDING FILMS & PHOTOGRAPHY',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey700,
                    ),
                  ),
                  if (profile.contact.isNotEmpty || profile.email.isNotEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 5),
                      child: pw.Text(
                        [
                          if (profile.contact.isNotEmpty) profile.contact,
                          if (profile.email.isNotEmpty) profile.email,
                        ].join('  |  '),
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    ),
                ],
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'QUOTATION',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  'Wedding Film & Photography',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    bodyText.add(pw.SizedBox(height: 12));

    bodyText.add(
      pw.Table(
        border: pw.TableBorder.all(
          color: PdfColors.grey500,
          width: .5,
        ),
        columnWidths: <int, pw.TableColumnWidth>{
          0: const pw.FlexColumnWidth(1),
          1: const pw.FlexColumnWidth(1),
        },
        children: [
          pw.TableRow(
            children: [
              _infoCell('CLIENT NAME', quotation.client),
              _infoCell('DATE', quotation.createdDate),
            ],
          ),
          pw.TableRow(
            children: [
              _infoCell(
                'CONTACT',
                quotation.phone.isEmpty ? '-' : quotation.phone,
              ),
              _infoCell(
                'EMAIL',
                quotation.email.isEmpty ? '-' : quotation.email,
              ),
            ],
          ),
        ],
      ),
    );

    bodyText.add(pw.SizedBox(height: 16));
    bodyText.add(_sectionHeader('EVENT COVERAGE'));
    bodyText.add(pw.SizedBox(height: 6));

    bodyText.add(
      pw.Table.fromTextArray(
        headers: const ['Date', 'Event', 'Coverage Team'],
        data: rows,
        headerStyle: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.black),
        cellStyle: const pw.TextStyle(fontSize: 7.5),
        border: pw.TableBorder.all(color: PdfColors.grey500, width: .45),
        cellPadding: const pw.EdgeInsets.symmetric(
          horizontal: 6,
          vertical: 6,
        ),
        columnWidths: <int, pw.TableColumnWidth>{
          0: const pw.FlexColumnWidth(1.0),
          1: const pw.FlexColumnWidth(1.15),
          2: const pw.FlexColumnWidth(2.8),
        },
      ),
    );

    bodyText.add(pw.SizedBox(height: 16));
    bodyText.add(_sectionHeader('DELIVERABLES'));
    bodyText.add(pw.SizedBox(height: 6));

    bodyText.add(
      pw.Table.fromTextArray(
        headers: const ['Video Deliverables', 'Quantity'],
        data: quotation.deliverables
            .map((d) => <String>[d.name, '${d.quantity}'])
            .toList(),
        headerStyle: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.black),
        cellStyle: const pw.TextStyle(fontSize: 8),
        border: pw.TableBorder.all(color: PdfColors.grey500, width: .45),
        cellPadding: const pw.EdgeInsets.all(6),
        columnWidths: <int, pw.TableColumnWidth>{
          0: const pw.FlexColumnWidth(3),
          1: const pw.FlexColumnWidth(1),
        },
      ),
    );

    bodyText.add(pw.SizedBox(height: 16));
    bodyText.add(_sectionHeader('INVESTMENT'));
    bodyText.add(pw.SizedBox(height: 6));

    bodyText.add(
      pw.Table.fromTextArray(
        headers: const ['Description', 'Amount'],
        data: [
          <String>['Photography & Cinematography', money(quotation.shootCharges)],
          <String>['Video Editing Charges', money(quotation.editingCharges)],
          <String>['TOTAL PACKAGE', money(quotation.total)],
        ],
        headerStyle: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.black),
        cellStyle: const pw.TextStyle(fontSize: 8),
        border: pw.TableBorder.all(color: PdfColors.grey500, width: .45),
        cellPadding: const pw.EdgeInsets.all(6),
        columnWidths: <int, pw.TableColumnWidth>{
          0: const pw.FlexColumnWidth(3),
          1: const pw.FlexColumnWidth(1.2),
        },
      ),
    );

    if (quotation.albums.isNotEmpty) {
      bodyText.add(pw.SizedBox(height: 16));
      bodyText.add(_sectionHeader('ALBUMS - OPTIONAL / EXTRA'));
      bodyText.add(pw.SizedBox(height: 6));

      bodyText.add(
        pw.Table.fromTextArray(
          headers: const [
            'Album',
            'Quantity',
            'Photos / Album',
            'Price / Album',
            'Total',
          ],
          data: quotation.albums
              .map(
                (a) => <String>[
                  a.name,
                  '${a.quantity}',
                  '${a.photos}',
                  money(a.price),
                  money(a.total),
                ],
              )
              .toList(),
          headerStyle: pw.TextStyle(
            fontSize: 7,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.black),
          cellStyle: const pw.TextStyle(fontSize: 7),
          border: pw.TableBorder.all(color: PdfColors.grey500, width: .45),
          cellPadding: const pw.EdgeInsets.all(5),
        ),
      );

      bodyText.add(
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Padding(
            padding: const pw.EdgeInsets.only(top: 6),
            child: pw.Text(
              'Album Charges: ${money(quotation.albumTotal)} extra',
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    bodyText.add(pw.SizedBox(height: 16));
    bodyText.add(_sectionHeader('TERMS & CONDITIONS'));
    bodyText.add(pw.SizedBox(height: 6));

    bodyText.add(
      pw.Container(
        width: double.infinity,
        height: quotation.tnc.trim().isEmpty ? 85 : null,
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(
            color: PdfColors.grey500,
            width: .5,
          ),
        ),
        child: pw.Text(
          quotation.tnc.trim().isEmpty ? '' : quotation.tnc.trim(),
          style: const pw.TextStyle(
            fontSize: 8,
          ),
        ),
      ),
    );

    bodyText.add(pw.SizedBox(height: 18));
    bodyText.add(
      pw.Center(
        child: pw.Text(
          'Thank you for choosing ${profile.name.isEmpty ? 'CrewFlow' : profile.name}.',
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.fromLTRB(28, 26, 28, 26),
        build: (_) => bodyText,
      ),
    );

    return doc.save();
  }

  pw.Widget _infoCell(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 7,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );
  }

  pw.Widget _sectionHeader(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: const pw.BoxDecoration(color: PdfColors.black),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          letterSpacing: .5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quotation PDF')),
      body: PdfPreview(
        canChangePageFormat: false,
        canChangeOrientation: false,
        allowPrinting: false,
        allowSharing: true,
        pdfFileName: '${cleanFileName(quotation.client)}_Quotation.pdf',
        build: buildPdf,
      ),
    );
  }
}

class EventPdfPage extends StatelessWidget {
  final List<EventData> events;
  final BrandProfile profile;
  final List<TeamMember> team;

  const EventPdfPage({
    super.key,
    required this.events,
    required this.profile,
    required this.team,
  });

  TeamMember? findMember(String name) {
    for (final m in team) {
      if (m.name == name) return m;
    }
    return null;
  }

  Future<Uint8List> buildPdf(PdfPageFormat format) async {
    final doc = pw.Document();

    pw.MemoryImage? logo;
    if (profile.logoBase64 != null && profile.logoBase64!.isNotEmpty) {
      try {
        logo = pw.MemoryImage(base64Decode(profile.logoBase64!));
      } catch (_) {}
    }

    final sorted = List<EventData>.from(events)
      ..sort((a, b) => a.date.compareTo(b.date));

    final widgets = <pw.Widget>[];

    widgets.add(
      pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 10),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.black, width: 1.2),
          ),
        ),
        child: pw.Row(
          children: [
            if (logo != null)
              pw.Container(
                width: 55,
                height: 55,
                margin: const pw.EdgeInsets.only(right: 12),
                child: pw.Image(logo, fit: pw.BoxFit.contain),
              ),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    profile.name.isEmpty ? 'CREWFLOW' : profile.name.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 17,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'EVENT COVERAGE',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              ),
            ),
            if (profile.contact.isNotEmpty || profile.email.isNotEmpty)
              pw.Text(
                [
                  if (profile.contact.isNotEmpty) profile.contact,
                  if (profile.email.isNotEmpty) profile.email,
                ].join('\n'),
                textAlign: pw.TextAlign.right,
                style: const pw.TextStyle(fontSize: 8),
              ),
          ],
        ),
      ),
    );

    widgets.add(pw.SizedBox(height: 14));

    for (var index = 0; index < sorted.length; index++) {
      final e = sorted[index];
      final teamRows = <List<String>>[];

      for (final entry in e.assignments.entries) {
        for (final name in entry.value) {
          final member = findMember(name);
          teamRows.add([
            entry.key,
            name,
            member?.phone ?? '',
          ]);
        }
      }

      widgets.add(
        pw.Container(
          width: double.infinity,
          margin: const pw.EdgeInsets.only(bottom: 12),
          padding: const pw.EdgeInsets.all(11),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(
              color: PdfColors.grey500,
              width: .5,
            ),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '${index + 1}. ${dateLong(e.date)}${e.time.isEmpty ? '' : '  •  ${e.time}'}',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Client: ${e.client.isEmpty ? e.name : e.client}',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.Text(
                'Event: ${e.type}',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.Text(
                'Location: ${e.venue}',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.SizedBox(height: 8),
              teamRows.isEmpty
                  ? pw.Text(
                      'Team: Not assigned',
                      style: const pw.TextStyle(fontSize: 9),
                    )
                  : pw.Table.fromTextArray(
                      headers: const ['Role', 'Team Member', 'Phone'],
                      data: teamRows,
                      headerStyle: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                      headerDecoration:
                          const pw.BoxDecoration(color: PdfColors.black),
                      cellStyle: const pw.TextStyle(fontSize: 8),
                      border: pw.TableBorder.all(
                        color: PdfColors.grey500,
                        width: .4,
                      ),
                      cellPadding: const pw.EdgeInsets.all(5),
                    ),
              if (e.notes.trim().isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 7),
                  child: pw.Text(
                    'Notes: ${e.notes}',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(28),
        build: (_) => widgets,
      ),
    );

    return doc.save();
  }

  @override
  Widget build(BuildContext context) {
    final name = events.isEmpty ? 'Event' : events.first.client;
    return Scaffold(
      appBar: AppBar(title: const Text('Event PDF')),
      body: PdfPreview(
        canChangePageFormat: false,
        canChangeOrientation: false,
        allowPrinting: false,
        allowSharing: true,
        pdfFileName: '${cleanFileName(name)}_Events.pdf',
        build: buildPdf,
      ),
    );
  }
}
