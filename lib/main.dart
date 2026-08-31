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
  'Cinematic',
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

  Map<String, dynamic> toJson() => {
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
    final raw = Map<String, dynamic>.from(j['assignments'] ?? {});
    final a = <String, List<String>>{};
    for (final r in roles) {
      a[r] = List<String>.from(raw[r] ?? const []);
    }
    final savedTypes = j['types'];
    final types = savedTypes is List
        ? savedTypes.map((x) => x.toString()).where((x) => x.isNotEmpty).toList()
        : ((j['type']?.toString().split(',') ?? ['Wedding']).map((x) => x.trim()).where((x) => x.isNotEmpty).toList());
    if (types.isEmpty) types.add('Wedding');
    return EventData(
      id: j['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: j['name']?.toString() ?? '',
      client: j['client']?.toString() ?? '',
      phone: j['phone']?.toString() ?? '',
      venue: j['venue']?.toString() ?? '',
      time: j['time']?.toString() ?? '',
      notes: j['notes']?.toString() ?? '',
      types: types,
      date: DateTime.tryParse(j['date']?.toString() ?? '') ?? DateTime.now(),
      assignments: a,
      groupId: j['groupId']?.toString(),
    );
  }
}


class QuotationEvent {
  String date;
  String event;
  String side;
  Map<String, int> requirements;
  QuotationEvent({required this.date, required this.event, required this.side, required this.requirements});
  Map<String,dynamic> toJson()=>{'date':date,'event':event,'side':side,'requirements':requirements};
  factory QuotationEvent.fromJson(Map<String,dynamic> j)=>QuotationEvent(date:j['date']?.toString()??'',event:j['event']?.toString()??'',side:j['side']?.toString()??'Both Side',requirements:Map<String,int>.from((j['requirements']??{}).map((k,v)=>MapEntry(k,(v as num).toInt()))));
}
class QuotationDeliverable { String name; int quantity; QuotationDeliverable(this.name,this.quantity); Map<String,dynamic> toJson()=>{'name':name,'quantity':quantity}; factory QuotationDeliverable.fromJson(Map<String,dynamic> j)=>QuotationDeliverable(j['name']?.toString()??'',(j['quantity'] as num?)?.toInt()??1); }
class QuotationAlbum { String name; int quantity; int price; int photos; QuotationAlbum({required this.name,required this.quantity,required this.price,required this.photos}); int get total=>quantity*price; Map<String,dynamic> toJson()=>{'name':name,'quantity':quantity,'price':price,'photos':photos}; factory QuotationAlbum.fromJson(Map<String,dynamic> j)=>QuotationAlbum(name:j['name']?.toString()??'Album',quantity:(j['quantity'] as num?)?.toInt()??1,price:(j['price'] as num?)?.toInt()??0,photos:(j['photos'] as num?)?.toInt()??0); }
class Quotation {
  String id, client, phone, email, createdDate, tnc;
  List<QuotationEvent> events; List<QuotationDeliverable> deliverables; List<QuotationAlbum> albums;
  int shootCharges, editingCharges;
  Quotation({required this.id,required this.client,required this.phone,required this.email,required this.createdDate,required this.events,required this.deliverables,required this.shootCharges,required this.editingCharges,required this.albums,required this.tnc});
  int get albumTotal=>albums.fold(0,(s,a)=>s+a.total); int get total=>shootCharges+editingCharges;
  Map<String,dynamic> toJson()=>{'id':id,'client':client,'phone':phone,'email':email,'createdDate':createdDate,'events':events.map((e)=>e.toJson()).toList(),'deliverables':deliverables.map((d)=>d.toJson()).toList(),'shootCharges':shootCharges,'editingCharges':editingCharges,'albums':albums.map((a)=>a.toJson()).toList(),'tnc':tnc};
  factory Quotation.fromJson(Map<String,dynamic> j)=>Quotation(id:j['id']?.toString()??DateTime.now().microsecondsSinceEpoch.toString(),client:j['client']?.toString()??'',phone:j['phone']?.toString()??'',email:j['email']?.toString()??'',createdDate:j['createdDate']?.toString()??'',events:(j['events'] as List? ?? const []).map((x)=>QuotationEvent.fromJson(Map<String,dynamic>.from(x))).toList(),deliverables:(j['deliverables'] as List? ?? const []).map((x)=>QuotationDeliverable.fromJson(Map<String,dynamic>.from(x))).toList(),shootCharges:(j['shootCharges'] as num?)?.toInt()??0,editingCharges:(j['editingCharges'] as num?)?.toInt()??0,albums:(j['albums'] as List? ?? const []).map((x)=>QuotationAlbum.fromJson(Map<String,dynamic>.from(x))).toList(),tnc:j['tnc']?.toString()??'');
}

void main() => runApp(const CrewFlowApp());

class CrewFlowApp extends StatefulWidget {
  const CrewFlowApp({super.key});
  @override State<CrewFlowApp> createState() => _CrewFlowAppState();
}
class _CrewFlowAppState extends State<CrewFlowApp> {
  bool dark = true; bool checking = true; bool loggedIn = false;
  @override void initState(){super.initState(); SharedPreferences.getInstance().then((p){if(mounted)setState((){dark=p.getBool('dark')??true;loggedIn=p.getBool('loggedIn')??false;checking=false;});});}
  Future<void> toggle() async {final p=await SharedPreferences.getInstance();setState(()=>dark=!dark);await p.setBool('dark',dark);}
  Future<void> login() async {final p=await SharedPreferences.getInstance();await p.setBool('loggedIn',true);if(mounted)setState(()=>loggedIn=true);}
  Future<void> logout() async {final p=await SharedPreferences.getInstance();await p.setBool('loggedIn',false);if(mounted)setState(()=>loggedIn=false);}
  @override Widget build(BuildContext context)=>MaterialApp(debugShowCheckedModeBanner:false,title:'CrewFlow',themeMode:dark?ThemeMode.dark:ThemeMode.light,theme:ThemeData(useMaterial3:true,colorSchemeSeed:purple,cardTheme:const CardThemeData(margin:EdgeInsets.symmetric(vertical:6),elevation:0)),darkTheme:ThemeData(useMaterial3:true,colorSchemeSeed:const Color(0xFF8B63FF),brightness:Brightness.dark,scaffoldBackgroundColor:const Color(0xFF0B0B0F),cardTheme:const CardThemeData(color:Color(0xFF15151B),margin:EdgeInsets.symmetric(vertical:6),elevation:0),inputDecorationTheme:InputDecorationTheme(filled:true,fillColor:Color(0xFF15151B),border:OutlineInputBorder(borderRadius:BorderRadius.all(Radius.circular(14)),borderSide:BorderSide.none),enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.all(Radius.circular(14)),borderSide:BorderSide.none),focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.all(Radius.circular(14)),borderSide:BorderSide(color:purple,width:1.4)))),home:checking?const Scaffold(body:Center(child:CircularProgressIndicator())):(loggedIn?CrewFlowHome(dark:dark,onDark:toggle,onLogout:logout):LoginPage(onLogin:login)));}

class LoginPage extends StatefulWidget { final VoidCallback onLogin; const LoginPage({super.key,required this.onLogin}); @override State<LoginPage> createState()=>_LoginPageState(); }
class _LoginPageState extends State<LoginPage>{final email=TextEditingController();final password=TextEditingController();bool obscure=true;bool create=false;@override Widget build(BuildContext context)=>Scaffold(body:SafeArea(child:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:430),child:Column(children:[Container(width:82,height:82,decoration:BoxDecoration(color:purple.withOpacity(.16),borderRadius:BorderRadius.circular(24)),child:const Icon(Icons.auto_awesome_rounded,color:purple,size:42)),const SizedBox(height:18),const Text('CrewFlow',style:TextStyle(fontSize:32,fontWeight:FontWeight.w900)),const SizedBox(height:6),const Text('Organize. Assign. Capture.',style:TextStyle(color:Colors.grey)),const SizedBox(height:42),Align(alignment:Alignment.centerLeft,child:Text(create?'Create your account':'Welcome back',style:const TextStyle(fontSize:24,fontWeight:FontWeight.w800))),const SizedBox(height:18),TextField(controller:email,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'Email',prefixIcon:Icon(Icons.email_outlined))),const SizedBox(height:12),TextField(controller:password,obscureText:obscure,decoration:InputDecoration(labelText:'Password',prefixIcon:const Icon(Icons.lock_outline),suffixIcon:IconButton(onPressed:()=>setState(()=>obscure=!obscure),icon:Icon(obscure?Icons.visibility_outlined:Icons.visibility_off_outlined)))),const SizedBox(height:20),SizedBox(width:double.infinity,height:52,child:FilledButton(onPressed:()=>_submit(),child:Text(create?'Create Account':'Login'))),const SizedBox(height:14),Row(children:[const Expanded(child:Divider()),Padding(padding:const EdgeInsets.symmetric(horizontal:12),child:Text('or')),const Expanded(child:Divider())]),const SizedBox(height:14),SizedBox(width:double.infinity,height:50,child:OutlinedButton.icon(onPressed:()=>_submit(),icon:const Icon(Icons.g_mobiledata,size:30),label:const Text('Continue with Google'))),const SizedBox(height:16),TextButton(onPressed:()=>setState(()=>create=!create),child:Text(create?'Already have an account? Login':'Don’t have an account? Create one')),const SizedBox(height:18),const Text('Your CrewFlow data stays on this device in this version. Cloud restore can be connected later.',textAlign:TextAlign.center,style:TextStyle(fontSize:11,color:Colors.grey))]))))));
void _submit(){if(email.text.trim().isEmpty||password.text.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Please enter email and password.')));return;}widget.onLogin();}
@override void dispose(){email.dispose();password.dispose();super.dispose();}}

class CrewFlowHome extends StatefulWidget {
  final bool dark;
  final VoidCallback onDark;
  final VoidCallback? onLogout;
  const CrewFlowHome({super.key, required this.dark, required this.onDark, this.onLogout});
  @override
  State<CrewFlowHome> createState() => _CrewFlowHomeState();
}

class _CrewFlowHomeState extends State<CrewFlowHome> {
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
  List<Quotation> quotations = [];
  List<String> tcTemplates = [];

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
    final qs = (p.getStringList('quotations') ?? []).map((x) { try { return Quotation.fromJson(jsonDecode(x)); } catch (_) { return null; } }).whereType<Quotation>().toList();
    final savedTcs = p.getStringList('tcTemplates') ?? [];
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
      quotations = qs;
      tcTemplates = savedTcs;
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
    await p.setStringList('quotations', quotations.map((q) => jsonEncode(q.toJson())).toList());
    await p.setStringList('tcTemplates', tcTemplates);
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
      drawer: Drawer(child: SafeArea(child: ListView(padding: EdgeInsets.zero, children: [
        const SizedBox(height: 18),
        ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 20), leading: const CircleAvatar(backgroundColor: purple, child: Icon(Icons.work_outline, color: Colors.white)), title: const Text('CrewFlow', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), subtitle: const Text('Organize. Assign. Capture.')),
        const Divider(),
        ListTile(leading: const Icon(Icons.groups_2_outlined), title: const Text('Team Assign'), subtitle: const Text('Events, calendar & team management'), onTap: () { Navigator.pop(context); setState(() => tab = 0); }),
        ListTile(leading: const Icon(Icons.request_quote_outlined), title: const Text('Quotation'), subtitle: const Text('Create and manage quotations'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => QuotationListPage(quotations: quotations, profile: BrandProfile(name: brandName, contact: brandContact, email: brandEmail, logoBase64: logoBase64), tcTemplates: tcTemplates, onChanged: (q, tcs) async { setState(() { quotations = q; tcTemplates = tcs; }); await save(); }))); }),
        const Divider(),
        ListTile(leading: const Icon(Icons.person_outline), title: const Text('Profile'), onTap: () { Navigator.pop(context); openProfile(); }),
        if (widget.onLogout != null) ListTile(leading: const Icon(Icons.logout, color: Colors.redAccent), title: const Text('Logout'), onTap: () { Navigator.pop(context); widget.onLogout!(); }),
        SwitchListTile(value: widget.dark, onChanged: (_) { Navigator.pop(context); widget.onDark(); }, secondary: const Icon(Icons.dark_mode_outlined), title: const Text('Dark mode')),
      ]))),
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
          Builder(builder: (ctx) => IconButton(onPressed: () => Scaffold.of(ctx).openDrawer(), icon: const Icon(Icons.menu))),
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
          child: FloatingActionButton(heroTag: 'calendarAdd', onPressed: () => openEvent(initialDate: DateTime(selected.year, selected.month, selected.day)), child: const Icon(Icons.add)),
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
    final filtered = events.where((e) => '${e.name} ${e.client} ${e.phone} ${e.venue} ${e.type}'.toLowerCase().contains(search.toLowerCase())).toList();
    final groups = <String, List<EventData>>{};
    for (final e in filtered) {
      groups.putIfAbsent(e.groupId, () => []).add(e);
    }
    final grouped = groups.values.toList()..sort((a, b) => a.first.date.compareTo(b.first.date));
    return Column(children: [
      top('Events'),
      Padding(padding: const EdgeInsets.all(12), child: TextField(onChanged: (v) => setState(() => search = v), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search client, phone or event', border: OutlineInputBorder()))),
      Expanded(child: ListView(padding: const EdgeInsets.symmetric(horizontal: 12), children: grouped.map((group) => Padding(padding: const EdgeInsets.only(bottom: 8), child: eventGroupCard(group))).toList())),
      Align(alignment: Alignment.bottomRight, child: Padding(padding: const EdgeInsets.all(16), child: FloatingActionButton(heroTag: 'eventsAdd', onPressed: () => openEvent(initialDate: DateTime.now()), child: const Icon(Icons.add)))),
    ]);
  }

  Widget eventGroupCard(List<EventData> group) {
    group.sort((a, b) => a.date.compareTo(b.date));
    final first = group.first;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openEventPdfGroup(group),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 5, height: 90, decoration: BoxDecoration(color: purple, borderRadius: BorderRadius.circular(10))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(first.client.isEmpty ? first.name : first.client, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 5),
              Text('📍 ${first.venue}'),
              const SizedBox(height: 5),
              Text('${group.length} date${group.length == 1 ? '' : 's'} • ${group.map((e) => e.date.day).join(', ')} ${mon(first.date.month)} ${first.date.year}', style: const TextStyle(fontWeight: FontWeight.w600)),
            ])),
            const Icon(Icons.picture_as_pdf_outlined),
          ]),
        ),
      ),
    );
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
        ListTile(leading: const Icon(Icons.request_quote_outlined), title: const Text('Quotation'), subtitle: const Text('Create professional branded PDF quotations'), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuotationListPage(quotations: quotations, profile: BrandProfile(name: brandName, contact: brandContact, email: brandEmail, logoBase64: logoBase64), tcTemplates: tcTemplates, onChanged: (q, tcs) async { setState(() { quotations = q; tcTemplates = tcs; }); await save(); })))),
        ListTile(leading: const Icon(Icons.person_outline), title: const Text('Profile'), subtitle: Text(brandName.isEmpty ? 'Add logo and business details' : brandName), trailing: const Icon(Icons.chevron_right), onTap: openProfile),
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
      builder: (_) => EventPdfPage(
        events: [event],
        profile: BrandProfile(
          name: brandName,
          contact: brandContact,
          email: brandEmail,
          logoBase64: logoBase64,
        ),
        team: team,
      ),
    ));
  }

  Future<void> openEventPdfGroup(List<EventData> group) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => EventPdfPage(events: group, profile: BrandProfile(name: brandName, contact: brandContact, email: brandEmail, logoBase64: logoBase64), team: team),
    ));
  }

  Future<void> addFromContacts() async {
    try {
      final ok = await FlutterContacts.requestPermission(readonly: true);
      if (!ok) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contacts permission is required to add a team member.')));
        }
        return;
      }
      final contacts = await FlutterContacts.getContacts(withProperties: true);
      if (!mounted) return;
      if (contacts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No contacts found.')));
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This contact has no phone number.')));
      return;
    }
    final exists = team.any((m) => m.phone.replaceAll(RegExp(r'\D'), '') == phone.replaceAll(RegExp(r'\D'), ''));
      if (!exists) {
        team.add(TeamMember(id: DateTime.now().microsecondsSinceEpoch.toString(), name: picked.displayName, role: 'Team Member', phone: phone));
        await save();
        if (mounted) setState(() {});
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not read contacts. Please check Contacts permission.')));
      }
    }
  }

  Future<void> chooseWhatsappEvent(TeamMember member) async {
    // Send one consolidated WhatsApp message containing every event/date
    // currently assigned to this team member. No event selection is needed.
    final assigned = events.where((e) => e.assignments.values.any((names) => names.contains(member.name))).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (assigned.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No event is assigned to this team member.')));
      }
      return;
    }

    final lines = <String>[
      'Hi ${member.name},',
      '',
      'Your upcoming event assignments:',
      '',
    ];

    for (final event in assigned) {
      final clientName = event.client.isEmpty ? event.name : event.client;
      final assignedRoles = <String>[];
      for (final entry in event.assignments.entries) {
        if (entry.value.contains(member.name)) assignedRoles.add(entry.key == 'Cinematographer' ? 'Cinematic' : entry.key);
      }
      lines.add('📅 ${dateFull(event.date)}');
      lines.add('👤 $clientName');
      lines.add('🎯 ${event.type}');
      lines.add('🎥 ${assignedRoles.join(', ')}');
      lines.add('📍 ${event.venue}');
      if (event.time.isNotEmpty) lines.add('⏰ ${event.time}');
      lines.add('');
    }

    lines.add('Please be available on time. Thank you.');
    await whatsapp(member.phone, message: lines.join('\n'));
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

  Future<void> openEvent({EventData? existing, DateTime? initialDate}) async {
    final group = existing == null ? <EventData>[] : events.where((e) => e.groupId == existing.groupId).toList()..sort((a, b) => a.date.compareTo(b.date));
    final result = await showDialog<List<EventData>>(
      context: context,
      builder: (_) => EventDialog(
        existing: existing,
        initialDate: initialDate,
        groupEvents: group,
        team: team,
        onDelete: existing == null ? null : () => deleteEvent(existing),
      ),
    );
    if (result == null) return;
    final groupId = existing?.groupId ?? result.first.groupId;
    setState(() {
      events.removeWhere((e) => e.groupId == groupId);
      events.addAll(result);
      final last = result.last;
      month = DateTime(last.date.year, last.date.month);
      selected = last.date;
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
  final DateTime? initialDate;
  final List<EventData> groupEvents;
  final List<TeamMember> team;
  final VoidCallback? onDelete;
  const EventDialog({super.key, this.existing, this.initialDate, required this.groupEvents, required this.team, this.onDelete});
  @override
  State<EventDialog> createState() => _EventDialogState();
}

class _EventDraft {
  DateTime date;
  String venue;
  String time;
  String notes;
  List<String> types;
  Map<String, List<String>> assignments;
  _EventDraft({required this.date, required this.venue, required this.time, required this.notes, required this.types, required this.assignments});
}

class _EventDialogState extends State<EventDialog> {
  late final TextEditingController client;
  late final TextEditingController phone;
  late final TextEditingController venue;
  late final TextEditingController notes;
  late DateTime date;
  late TimeOfDay time;
  late List<String> types;
  late Map<String, List<String>> assignments;
  late List<_EventDraft> drafts;
  int currentIndex = 0;

  static const eventTypes = <String>['Wedding', 'Reception', 'Engagement', 'Pre Wedding', 'Haldi', 'Sangeet', 'Mehndi', 'Kankotri Lekhan', 'Ganesh Pooja', 'Mayra', 'Baby Shower', 'House Warming', 'Corporate Event', 'Other'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    client = TextEditingController(text: e?.client ?? '');
    phone = TextEditingController(text: e?.phone ?? '');
    venue = TextEditingController();
    notes = TextEditingController();
    drafts = (widget.groupEvents.isNotEmpty ? widget.groupEvents : e != null ? [e] : []).map((x) => _draftFromEvent(x)).toList();
    if (drafts.isEmpty) {
      drafts = [_EventDraft(date: widget.initialDate ?? DateTime.now(), venue: '', time: _formatTimeOfDay(TimeOfDay.now()), notes: '', types: ['Wedding'], assignments: {})];
    }
    _loadDraft(0);
  }

  _EventDraft _draftFromEvent(EventData e) => _EventDraft(
        date: DateTime(e.date.year, e.date.month, e.date.day),
        venue: e.venue,
        time: e.time,
        notes: e.notes,
        types: List<String>.from(e.types),
        assignments: e.assignments.map((k, v) => MapEntry(k, List<String>.from(v))),
      );

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

  static String _formatTimeOfDay(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.period == DayPeriod.am ? 'AM' : 'PM'}';
  }

  void _loadDraft(int index) {
    final d = drafts[index];
    currentIndex = index;
    date = d.date;
    venue.text = d.venue;
    notes.text = d.notes;
    time = _parseTime(d.time) ?? TimeOfDay.now();
    types = List<String>.from(d.types);
    assignments = d.assignments.map((k, v) => MapEntry(k, List<String>.from(v)));
  }

  void _saveCurrentDraft() {
    drafts[currentIndex] = _EventDraft(date: DateTime(date.year, date.month, date.day), venue: venue.text.trim(), time: formatTime(time), notes: notes.text.trim(), types: List<String>.from(types), assignments: assignments.map((k, v) => MapEntry(k, List<String>.from(v))));
  }

  String formatTime(TimeOfDay t) => t.format(context);
  String formatDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  String roleLabel(String role) => role == 'Cinematographer' ? 'Cinematic' : role;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.82;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: SizedBox(
        width: 560,
        height: maxHeight,
        child: Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(20, 18, 12, 8), child: Row(children: [
            Expanded(child: Text(widget.existing == null ? 'Add New Event' : 'Edit Event', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600))),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
          ])),
          if (drafts.length > 1) SizedBox(height: 42, child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: drafts.length, itemBuilder: (_, i) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(formatDate(drafts[i].date)), selected: i == currentIndex, onSelected: (_) { _saveCurrentDraft(); setState(() => _loadDraft(i)); })) )),
          Expanded(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextField(controller: client, textInputAction: TextInputAction.next, decoration: InputDecoration(labelText: 'Client Name', prefixIcon: const Icon(Icons.person_outline), suffixIcon: IconButton(tooltip: 'Select contact', icon: const Icon(Icons.contacts_outlined), onPressed: _pickClientContact))),
            const SizedBox(height: 10),
            TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Client Phone', prefixIcon: Icon(Icons.phone_outlined))),
            const SizedBox(height: 10),
            Text('Event Type (select one or more)', style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 8, children: eventTypes.map((x) => FilterChip(label: Text(x), selected: types.contains(x), onSelected: (v) => setState(() { if (v) { types.add(x); } else { types.remove(x); } }))).toList()),
            const SizedBox(height: 12),
            TextField(controller: venue, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Venue / Location', prefixIcon: Icon(Icons.location_on_outlined))),
            const SizedBox(height: 6),
            ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.access_time), title: const Text('Event Time'), subtitle: Text(formatTime(time)), onTap: () async { final t = await showTimePicker(context: context, initialTime: time); if (t != null && mounted) setState(() => time = t); }),
            ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.calendar_month), title: const Text('Event Date'), subtitle: Text(formatDate(date)), onTap: () async { final d = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2100), initialDate: date); if (d != null && mounted) setState(() => date = d); }),
            const SizedBox(height: 6),
            TextField(controller: notes, maxLines: 4, decoration: const InputDecoration(labelText: 'Notes', alignLabelWithHint: true, hintText: 'Add event notes...', border: OutlineInputBorder(), prefixIcon: Padding(padding: EdgeInsets.only(bottom: 52), child: Icon(Icons.notes_outlined)))),
            const SizedBox(height: 18),
            const Text('Assign Team', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ...assignments.entries.map((entry) => _roleRow(entry.key, entry.value)),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _addRole, icon: const Icon(Icons.add), label: const Text('Add Team'))),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _addDate, icon: const Icon(Icons.event_available_outlined), label: const Text('Add Date'))),
          ])),),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.fromLTRB(12, 8, 12, 12), child: Row(children: [
            if (widget.existing != null && widget.onDelete != null) TextButton(onPressed: widget.onDelete, child: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
            const Spacer(), TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), const SizedBox(width: 8), FilledButton(onPressed: _save, child: Text(widget.existing == null ? 'Save Event' : 'Save Changes')),
          ])),
        ]),
      ),
    );
  }

  Future<void> _pickClientContact() async {
    final ok = await FlutterContacts.requestPermission(readonly: true);
    if (!ok || !mounted) return;
    final contacts = await FlutterContacts.getContacts(withProperties: true);
    if (!mounted) return;
    final picked = await showModalBottomSheet<Contact>(context: context, isScrollControlled: true, builder: (_) => ContactPickerSheet(contacts: contacts));
    if (picked == null || !mounted) return;
    setState(() { client.text = picked.displayName; phone.text = picked.phones.isEmpty ? '' : picked.phones.first.number; });
  }

  Future<void> _addDate() async {
    _saveCurrentDraft();
    final d = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2100), initialDate: date.add(const Duration(days: 1)));
    if (d == null) return;
    final exists = drafts.any((x) => x.date.year == d.year && x.date.month == d.month && x.date.day == d.day);
    if (exists) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This date is already added.'))); return; }
    final base = drafts[currentIndex];
    drafts.add(_EventDraft(date: d, venue: base.venue, time: base.time, notes: '', types: [], assignments: {}));
    setState(() => _loadDraft(drafts.length - 1));
  }

  Widget _roleRow(String role, List<String> names) => Card(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), child: Row(children: [Expanded(child: Text('${roleLabel(role)} - ${names.isEmpty ? 'Not assigned' : names.join(', ')}')), TextButton(onPressed: () => _assign(role), child: Text(names.isEmpty ? 'Assign' : 'Change'))])));

  Future<void> _assign(String role) async {
    final selected = await showDialog<List<TeamMember>>(
      context: context,
      builder: (_) => AssignMemberDialog(
        role: role,
        members: widget.team,
        already: assignments[role] ?? const [],
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      assignments[role] = selected.map((m) => m.name).toSet().toList();
    });
  }

  Future<void> _addRole() async {
    // Roles are unlimited: the same role can be added/assigned repeatedly.
    final r = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: roles.map((x) => ListTile(
            title: Text(roleLabel(x)),
            onTap: () => Navigator.pop(context, x),
          )).toList(),
        ),
      ),
    );
    if (r == null || !mounted) return;

    final selected = await showDialog<List<TeamMember>>(
      context: context,
      builder: (_) => AssignMemberDialog(
        role: r,
        members: widget.team,
        already: assignments[r] ?? const [],
      ),
    );
    if (selected == null || !mounted) return;

    setState(() {
      final current = List<String>.from(assignments[r] ?? const []);
      for (final m in selected) {
        if (!current.contains(m.name)) current.add(m.name);
      }
      assignments[r] = current;
    });
  }

  void _save() {
    _saveCurrentDraft();
    if (client.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter Client Name.'))); return; }
    for (final d in drafts) { if (d.venue.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter Venue for every date.'))); return; } if (d.types.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one Event Type for every date.'))); return; } }
    final groupId = widget.existing?.groupId ?? DateTime.now().microsecondsSinceEpoch.toString();
    final result = <EventData>[];
    for (var i = 0; i < drafts.length; i++) {
      final d = drafts[i];
      result.add(EventData(id: i < widget.groupEvents.length ? widget.groupEvents[i].id : DateTime.now().microsecondsSinceEpoch.toString(), name: widget.existing?.name ?? '', client: client.text.trim(), phone: phone.text.trim(), venue: d.venue, time: d.time, notes: d.notes, types: d.types, date: DateTime(d.date.year, d.date.month, d.date.day), assignments: d.assignments, groupId: groupId));
    }
    Navigator.pop(context, result);
  }

  @override
  void dispose() { client.dispose(); phone.dispose(); venue.dispose(); notes.dispose(); super.dispose(); }
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
  late Set<String> selectedNames;

  @override
  void initState() {
    super.initState();
    selectedNames = widget.already.toSet();
  }

  @override
  Widget build(BuildContext context) {
    final list = widget.members.where((m) {
      final queryMatches = '${m.name} ${m.phone}'.toLowerCase().contains(q.toLowerCase());
      return queryMatches;
    }).toList();

    return AlertDialog(
      title: Text('Assign ${widget.role == 'Cinematographer' ? 'Cinematic' : widget.role}'),
      content: SizedBox(
        width: 420,
        height: 420,
        child: Column(children: [
          TextField(
            onChanged: (v) => setState(() => q = v),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search member',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text('No team members. Add members from Team first.'))
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final m = list[i];
                      final checked = selectedNames.contains(m.name);
                      return CheckboxListTile(
                        value: checked,
                        onChanged: (v) => setState(() {
                          if (v == true) {
                            selectedNames.add(m.name);
                          } else {
                            selectedNames.remove(m.name);
                          }
                        }),
                        secondary: CircleAvatar(child: Text(m.name.isEmpty ? '?' : m.name[0].toUpperCase())),
                        title: Text(m.name),
                        subtitle: Text('Team Member • ${m.phone}'),
                        controlAffinity: ListTileControlAffinity.trailing,
                      );
                    },
                  ),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final selected = widget.members.where((m) => selectedNames.contains(m.name)).toList();
            Navigator.pop(context, selected);
          },
          child: const Text('Done'),
        ),
      ],
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


class QuotationListPage extends StatefulWidget {
  final List<Quotation> quotations; final BrandProfile profile; final List<String> tcTemplates; final Future<void> Function(List<Quotation>, List<String>) onChanged;
  const QuotationListPage({super.key,required this.quotations,required this.profile,required this.tcTemplates,required this.onChanged});
  @override State<QuotationListPage> createState()=>_QuotationListPageState();
}
class _QuotationListPageState extends State<QuotationListPage>{
  late List<Quotation> qs; late List<String> tcs;
  @override void initState(){super.initState();qs=List.from(widget.quotations);tcs=List.from(widget.tcTemplates);}
  Future<void> persist(){return widget.onChanged(qs,tcs);}
  Future<void> edit([Quotation? q]) async { final r=await Navigator.push<Quotation>(context,MaterialPageRoute(builder:(_)=>QuotationEditorPage(initial:q,profile:widget.profile,tcTemplates:tcs,onTemplatesChanged:(x){tcs=x;}))); if(r!=null){setState((){qs.removeWhere((x)=>x.id==r.id);qs.add(r);qs.sort((a,b)=>b.createdDate.compareTo(a.createdDate));});await persist();}}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quotations'),
        actions: [
          IconButton(onPressed: () => edit(), icon: const Icon(Icons.add)),
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      backgroundColor: purple.withOpacity(.18),
                      child: const Icon(Icons.request_quote_outlined, color: purple),
                    ),
                    title: Text(
                      q.client.isEmpty ? 'Untitled Quotation' : q.client,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${q.events.length} event${q.events.length == 1 ? '' : 's'} • ${q.createdDate}\n₹${q.total}',
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'edit') {
                          await edit(q);
                        } else if (v == 'pdf') {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QuotationPdfPage(
                                quotation: q,
                                profile: widget.profile,
                              ),
                            ),
                          );
                        } else if (v == 'delete') {
                          setState(() => qs.removeWhere((x) => x.id == q.id));
                          await persist();
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'pdf', child: Text('Open PDF')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
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
  final Quotation? initial; final BrandProfile profile; final List<String> tcTemplates; final ValueChanged<List<String>> onTemplatesChanged;
  const QuotationEditorPage({super.key,this.initial,required this.profile,required this.tcTemplates,required this.onTemplatesChanged});
  @override State<QuotationEditorPage> createState()=>_QuotationEditorPageState();
}
class _QuotationEditorPageState extends State<QuotationEditorPage>{
  late TextEditingController client,phone,email,shoot,editing,tnc; late List<QuotationEvent> events; late List<QuotationDeliverable> dels; late List<QuotationAlbum> albums; late List<String> tcs;
  final eventOptions=['Ganesh Pooja','Haldi','Sangeet','Wedding','Reception','Engagement','Pre Wedding','Mehndi','Kankotri Lekhan','Mayra','Baby Shower','House Warming','Corporate Event','Other'];
  final reqOptions=['Photographer','Videographer','Candid','Cinematographer','Drone','Helper'];
  final delOptions=['Reels','Teaser','Cinematic Highlight','Full Video','Short Film'];
  @override void initState(){super.initState();final q=widget.initial;client=TextEditingController(text:q?.client??'');phone=TextEditingController(text:q?.phone??'');email=TextEditingController(text:q?.email??'');shoot=TextEditingController(text:q?.shootCharges.toString()??'');editing=TextEditingController(text:q?.editingCharges.toString()??'');tnc=TextEditingController(text:q?.tnc??'');events=q?.events.map((e)=>QuotationEvent(date:e.date,event:e.event,side:e.side,requirements:Map.from(e.requirements))).toList()??[];dels=q?.deliverables.map((d)=>QuotationDeliverable(d.name,d.quantity)).toList()??[QuotationDeliverable('Reels',4),QuotationDeliverable('Teaser',1),QuotationDeliverable('Cinematic Highlight',1),QuotationDeliverable('Full Video',1)];albums=q?.albums.map((a)=>QuotationAlbum(name:a.name,quantity:a.quantity,price:a.price,photos:a.photos)).toList()??[];tcs=List.from(widget.tcTemplates);}
  int num(TextEditingController c)=>int.tryParse(c.text.replaceAll(',',''))??0; int get total=>num(shoot)+num(editing);
  String fmt(DateTime d)=>'${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
  Future<void> addEvent() async {
    DateTime d = DateTime.now();
    String ev = eventOptions.first;
    String side = 'Both Side';
    final req = <String, int>{};

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setD) {
            return AlertDialog(
              title: const Text('Add Event'),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.calendar_month),
                        title: Text(fmt(d)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                            initialDate: d,
                          );
                          if (picked != null) {
                            setD(() => d = picked);
                          }
                        },
                      ),
                      DropdownButtonFormField<String>(
                        value: ev,
                        decoration: const InputDecoration(labelText: 'Event'),
                        items: eventOptions
                            .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                            .toList(),
                        onChanged: (x) {
                          if (x != null) setD(() => ev = x);
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: side,
                        decoration: const InputDecoration(labelText: 'Side'),
                        items: const ['Bride Side', 'Groom Side', 'Both Side']
                            .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                            .toList(),
                        onChanged: (x) {
                          if (x != null) setD(() => side = x);
                        },
                      ),
                      const SizedBox(height: 14),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Requirements',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ...reqOptions.map(
                        (x) => Row(
                          children: [
                            Expanded(child: Text(x)),
                            IconButton(
                              onPressed: () {
                                setD(() {
                                  req[x] = ((req[x] ?? 0) - 1).clamp(0, 99);
                                });
                              },
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text(
                              '${req[x] ?? 0}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              onPressed: () {
                                setD(() => req[x] = (req[x] ?? 0) + 1);
                              },
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
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      setState(
        () => events.add(
          QuotationEvent(
            date: fmt(d),
            event: ev,
            side: side,
            requirements: Map.from(req),
          ),
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? 'Create Quotation' : 'Edit Quotation'),
        actions: [
          IconButton(onPressed: saveQ, icon: const Icon(Icons.check)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
        children: [
          _section(
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
          _section(
            'Event Coverage',
            Column(
              children: [
                ...events.asMap().entries.map(
                  (entry) => Card(
                    child: ListTile(
                      title: Text(
                        '${entry.value.date} • ${entry.value.event}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${entry.value.side} • ${entry.value.requirements.entries.where((e) => e.value > 0).map((e) => '${e.key} × ${e.value}').join(' + ')}',
                      ),
                      trailing: IconButton(
                        onPressed: () => setState(() => events.removeAt(entry.key)),
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
          _section(
            'Deliverables',
            Column(
              children: [
                ...dels.asMap().entries.map(
                  (entry) => Row(
                    children: [
                      Expanded(child: Text(entry.value.name)),
                      IconButton(
                        onPressed: () => setState(
                          () => entry.value.quantity =
                              (entry.value.quantity - 1).clamp(0, 999),
                        ),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text(
                        '${entry.value.quantity}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => setState(() => entry.value.quantity++),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                      IconButton(
                        onPressed: () => setState(() => dels.removeAt(entry.key)),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Add Deliverable'),
                  items: delOptions
                      .where((x) => !dels.any((d) => d.name == x))
                      .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                      .toList(),
                  onChanged: (x) {
                    if (x != null) {
                      setState(() => dels.add(QuotationDeliverable(x, 1)));
                    }
                  },
                ),
              ],
            ),
          ),
          _section(
            'Investment',
            Column(
              children: [
                TextField(
                  controller: shoot,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Shoot Charges',
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
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: purple.withOpacity(.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Package',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '₹$total',
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
          _section(
            'Albums — Optional / Extra',
            Column(
              children: [
                ...albums.asMap().entries.map(
                  (entry) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: TextEditingController(
                                    text: entry.value.name,
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: 'Album Name',
                                  ),
                                  onChanged: (v) => entry.value.name = v,
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
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: TextEditingController(
                                    text: '${entry.value.quantity}',
                                  ),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Albums',
                                  ),
                                  onChanged: (v) {
                                    entry.value.quantity = int.tryParse(v) ?? 1;
                                    setState(() {});
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: TextEditingController(
                                    text: '${entry.value.photos}',
                                  ),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Photos / Album',
                                  ),
                                  onChanged: (v) {
                                    entry.value.photos = int.tryParse(v) ?? 0;
                                    setState(() {});
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: TextEditingController(
                                    text: '${entry.value.price}',
                                  ),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Price / Album',
                                  ),
                                  onChanged: (v) {
                                    entry.value.price = int.tryParse(v) ?? 0;
                                    setState(() {});
                                  },
                                ),
                              ),
                            ],
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '₹${entry.value.total}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
                    child: Text(
                      'Album Total: ₹${albums.fold(0, (s, a) => s + a.total)}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
              ],
            ),
          ),
          _section(
            'Terms & Conditions',
            Column(
              children: [
                if (tcs.isNotEmpty)
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Select Saved T&C'),
                    items: tcs.asMap().entries
                        .map(
                          (entry) => DropdownMenuItem(
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
                if (tcs.isNotEmpty) const SizedBox(height: 8),
                TextField(
                  controller: tnc,
                  maxLines: 7,
                  decoration: const InputDecoration(
                    hintText: 'Write T&C for this quotation...',
                    border: OutlineInputBorder(),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: manageTcs,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save as new T&C template'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: saveQ,
            icon: const Icon(Icons.save),
            label: const Text('Save Quotation & Open PDF'),
          ),
        ],
      ),
    );
  }
  Widget _section(String title,Widget child)=>Card(margin:const EdgeInsets.only(bottom:14),child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:17,fontWeight:FontWeight.w800)),const SizedBox(height:12),child])));
  @override void dispose(){client.dispose();phone.dispose();email.dispose();shoot.dispose();editing.dispose();tnc.dispose();super.dispose();}
}

class QuotationPdfPage extends StatelessWidget {
  final Quotation quotation; final BrandProfile profile;
  const QuotationPdfPage({super.key,required this.quotation,required this.profile});
  String money(int n)=>'Rs. ${n.toString()} /-';
  Future<Uint8List> buildPdf(PdfPageFormat format)async{final doc=pw.Document();pw.MemoryImage? logo;if(profile.logoBase64!=null){try{logo=pw.MemoryImage(base64Decode(profile.logoBase64!));}catch(_){}}
    final rows=quotation.events.map((e){final req=e.requirements.entries.where((x)=>x.value>0).map((x)=>'${x.key} × ${x.value}').join(' + ');return [e.date,e.event+' – '+e.side,req.isEmpty?'—':req];}).toList();
    doc.addPage(pw.MultiPage(pageFormat:format,margin:const pw.EdgeInsets.all(30),build:(_)=>[
      if(logo!=null||profile.name.isNotEmpty||profile.contact.isNotEmpty||profile.email.isNotEmpty)pw.Row(children:[if(logo!=null)pw.Container(width:62,height:62,margin:const pw.EdgeInsets.only(right:12),child:pw.Image(logo!,fit:pw.BoxFit.contain)),pw.Expanded(child:pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.start,children:[pw.Text(profile.name.isEmpty?'CREWFLOW':profile.name,style:pw.TextStyle(fontSize:20,fontWeight:pw.FontWeight.bold)),if(profile.contact.isNotEmpty||profile.email.isNotEmpty)pw.Text([if(profile.contact.isNotEmpty)profile.contact,if(profile.email.isNotEmpty)profile.email].join('  |  '),style:const pw.TextStyle(fontSize:9))]))]),
      pw.SizedBox(height:18),pw.Center(child:pw.Text('WEDDING PHOTOGRAPHY & CINEMATOGRAPHY',style:pw.TextStyle(fontSize:18,fontWeight:pw.FontWeight.bold))),pw.Center(child:pw.Text('Quotation',style:const pw.TextStyle(fontSize:11))),pw.SizedBox(height:14),pw.Table(border:pw.TableBorder.all(width:.5),columnWidths:{0:const pw.FlexColumnWidth(1),1:const pw.FlexColumnWidth(1)},children:[pw.TableRow(children:[_cell('CLIENT NAME',quotation.client),_cell('DATE',quotation.createdDate)]),pw.TableRow(children:[_cell('CONTACT',quotation.phone.isEmpty?'—':quotation.phone),_cell('EMAIL',quotation.email.isEmpty?'—':quotation.email)])]),
      pw.SizedBox(height:18),pw.Text('EVENT COVERAGE',style:pw.TextStyle(fontSize:14,fontWeight:pw.FontWeight.bold)),pw.SizedBox(height:7),pw.Table.fromTextArray(headers:const['Date','Event','Coverage Team'],data:rows,headerStyle:pw.TextStyle(fontWeight:pw.FontWeight.bold,fontSize:8),cellStyle:const pw.TextStyle(fontSize:8),border:pw.TableBorder.all(width:.4),cellPadding:const pw.EdgeInsets.all(5)),
      pw.SizedBox(height:18),pw.Text('DELIVERABLES',style:pw.TextStyle(fontSize:14,fontWeight:pw.FontWeight.bold)),pw.SizedBox(height:7),pw.Table.fromTextArray(headers:const['Video Deliverables','Quantity'],data:quotation.deliverables.map((d)=>[d.name,'${d.quantity}']).toList(),headerStyle:pw.TextStyle(fontWeight:pw.FontWeight.bold,fontSize:8),cellStyle:const pw.TextStyle(fontSize:8),border:pw.TableBorder.all(width:.4)),
      pw.SizedBox(height:18),pw.Text('INVESTMENT',style:pw.TextStyle(fontSize:14,fontWeight:pw.FontWeight.bold)),pw.SizedBox(height:7),pw.Table.fromTextArray(headers:const['Description','Amount'],data:[[ 'Photography & Cinematography',money(quotation.shootCharges) ],['Video Editing Charges',money(quotation.editingCharges)],['Total Package',money(quotation.total)]],headerStyle:pw.TextStyle(fontWeight:pw.FontWeight.bold,fontSize:8),cellStyle:const pw.TextStyle(fontSize:9),border:pw.TableBorder.all(width:.4)),
      if(quotation.albums.isNotEmpty)pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.start,children:[pw.SizedBox(height:18),pw.Text('ALBUMS – OPTIONAL / EXTRA',style:pw.TextStyle(fontSize:14,fontWeight:pw.FontWeight.bold)),pw.SizedBox(height:7),pw.Table.fromTextArray(headers:const['Album','Quantity','Photos / Album','Price / Album','Total'],data:quotation.albums.map((a)=>[a.name,'${a.quantity}','${a.photos}',money(a.price),money(a.total)]).toList(),headerStyle:pw.TextStyle(fontWeight:pw.FontWeight.bold,fontSize:7),cellStyle:const pw.TextStyle(fontSize:7),border:pw.TableBorder.all(width:.4)),pw.Align(alignment:pw.Alignment.centerRight,child:pw.Padding(padding:const pw.EdgeInsets.only(top:5),child:pw.Text('Album Charges: ${money(quotation.albumTotal)} extra',style:pw.TextStyle(fontWeight:pw.FontWeight.bold,fontSize:9))))]),
      pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.start,children:[pw.SizedBox(height:18),pw.Text('TERMS & CONDITIONS',style:pw.TextStyle(fontSize:14,fontWeight:pw.FontWeight.bold)),pw.SizedBox(height:6),pw.Container(width:double.infinity,constraints:const pw.BoxConstraints(minHeight:88),padding:const pw.EdgeInsets.all(10),decoration:pw.BoxDecoration(border:pw.Border.all(width:.4)),child:pw.Text(quotation.tnc.trim().isEmpty?'':quotation.tnc.trim(),style:const pw.TextStyle(fontSize:8)))]),
      pw.SizedBox(height:18),pw.Center(child:pw.Text('Thank you for choosing ${profile.name.isEmpty?'CrewFlow':profile.name}.',style:const pw.TextStyle(fontSize:9))),
    ]));return doc.save();}
  pw.Widget _cell(String l,String v)=>pw.Padding(padding:const pw.EdgeInsets.all(7),child:pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.start,children:[pw.Text(l,style:pw.TextStyle(fontSize:7,fontWeight:pw.FontWeight.bold)),pw.SizedBox(height:3),pw.Text(v,style:const pw.TextStyle(fontSize:9))]));
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Quotation PDF')),body:PdfPreview(canChangePageFormat:false,canChangeOrientation:false,allowPrinting:false,allowSharing:true,pdfFileName:'${quotation.client.isEmpty?'Quotation':quotation.client.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'),'_')}_Quotation.pdf',build:buildPdf));
}

class EventPdfPage extends StatelessWidget {
  final List<EventData> events;
  final BrandProfile profile;
  final List<TeamMember> team;
  const EventPdfPage({super.key, required this.events, required this.profile, required this.team});

  TeamMember? memberByName(String name) { for (final m in team) { if (m.name == name) return m; } return null; }
  String roleLabel(String role) => role == 'Cinematographer' ? 'Cinematic' : role;
  String month(int m) => const ['', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][m];
  String dateFull(DateTime d) => '${d.day} ${month(d.month)} ${d.year}';

  Future<Uint8List> buildPdf(PdfPageFormat format) async {
    final doc = pw.Document();
    pw.MemoryImage? logo;
    if (profile.logoBase64 != null && profile.logoBase64!.isNotEmpty) { try { logo = pw.MemoryImage(base64Decode(profile.logoBase64!)); } catch (_) {} }
    final sorted = [...events]..sort((a, b) => a.date.compareTo(b.date));
    doc.addPage(pw.MultiPage(pageFormat: format, margin: const pw.EdgeInsets.all(28), build: (_) => [
      if (logo != null || profile.name.isNotEmpty || profile.contact.isNotEmpty || profile.email.isNotEmpty)
        pw.Container(padding: const pw.EdgeInsets.only(bottom: 14), decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 2))), child: pw.Row(children: [
          if (logo != null) pw.Container(width: 58, height: 58, margin: const pw.EdgeInsets.only(right: 12), child: pw.Image(logo, fit: pw.BoxFit.contain)),
          pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [if (profile.name.isNotEmpty) pw.Text(profile.name, style: pw.TextStyle(fontSize: 19, fontWeight: pw.FontWeight.bold)), if (profile.contact.isNotEmpty || profile.email.isNotEmpty) pw.Padding(padding: const pw.EdgeInsets.only(top: 4), child: pw.Text([if (profile.contact.isNotEmpty) profile.contact, if (profile.email.isNotEmpty) profile.email].join('  |  '), style: const pw.TextStyle(fontSize: 9)))])),
        ])),
      pw.SizedBox(height: 18),
      pw.Center(child: pw.Text('EVENT SUMMARY', style: pw.TextStyle(fontSize: 21, fontWeight: pw.FontWeight.bold))),
      pw.SizedBox(height: 12),
      _infoBox(sorted.first),
      pw.SizedBox(height: 20),
      pw.Text('EVENT SCHEDULE & ASSIGNED TEAM', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 8),
      ...sorted.asMap().entries.map((entry) => _dateSection(entry.key + 1, entry.value)),
    ]));
    return doc.save();
  }

  pw.Widget _infoBox(EventData e) => pw.Container(padding: const pw.EdgeInsets.all(14), decoration: pw.BoxDecoration(border: pw.Border.all(width: .8), borderRadius: pw.BorderRadius.circular(8)), child: pw.Table(columnWidths: const {0: pw.FlexColumnWidth(1), 1: pw.FlexColumnWidth(1)}, children: [
    pw.TableRow(children: [_pdfInfo('CLIENT NAME', e.client.isEmpty ? '—' : e.client), _pdfInfo('CLIENT CONTACT', e.phone.isEmpty ? '—' : e.phone)]),
    pw.TableRow(children: [_pdfInfo('DATES', events.map((x) => dateFull(x.date)).join(', ')), _pdfInfo('LOCATION / VENUE', e.venue)]),
  ]));

  pw.Widget _dateSection(int n, EventData e) {
    final rows = <List<String>>[];
    for (final entry in e.assignments.entries) { for (final name in entry.value) { final m = memberByName(name); rows.add([roleLabel(entry.key), name, m?.phone ?? '']); } }
    return pw.Container(margin: const pw.EdgeInsets.only(bottom: 16), padding: const pw.EdgeInsets.all(12), decoration: pw.BoxDecoration(border: pw.Border.all(width: .6), borderRadius: pw.BorderRadius.circular(7)), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text('$n. ${dateFull(e.date)}  •  ${e.time.isEmpty ? 'Time not set' : e.time}', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 5),
      pw.Text('Event Type: ${e.type}', style: const pw.TextStyle(fontSize: 10)),
      pw.Text('Location: ${e.venue}', style: const pw.TextStyle(fontSize: 10)),
      pw.SizedBox(height: 8),
      rows.isEmpty ? pw.Text('Team: Not assigned', style: const pw.TextStyle(fontSize: 10)) : pw.Table.fromTextArray(headers: const ['ROLE', 'TEAM MEMBER', 'PHONE'], data: rows, headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), cellStyle: const pw.TextStyle(fontSize: 9), border: pw.TableBorder.all(width: .4), cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5)),
      if (e.notes.trim().isNotEmpty) pw.Padding(padding: const pw.EdgeInsets.only(top: 8), child: pw.Text('Notes: ${e.notes}', style: const pw.TextStyle(fontSize: 9))),
    ]));
  }

  pw.Widget _pdfInfo(String label, String value) => pw.Padding(padding: const pw.EdgeInsets.all(7), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Text(label, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)), pw.SizedBox(height: 3), pw.Text(value, style: const pw.TextStyle(fontSize: 10))]));

  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Event PDF')), body: PdfPreview(canChangePageFormat: false, canChangeOrientation: false, allowPrinting: false, allowSharing: true, pdfFileName: '${(events.first.client.isEmpty ? 'Event' : events.first.client).replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_')}_Events.pdf', build: buildPdf));
}

