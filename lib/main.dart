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
const roles = ['Candid', 'Cinematic', 'T. Photo', 'T. Video', 'Drone', 'Helper'];
const eventTypes = [
  'Wedding', 'Reception', 'Engagement', 'Pre Wedding', 'Haldi', 'Sangeet',
  'Mehndi', 'Kankotri Lekhan', 'Ganesh Pooja', 'Mayra', 'Baby Shower',
  'House Warming', 'Corporate Event', 'Other'
];

String idNow() => DateTime.now().microsecondsSinceEpoch.toString();
String money(int n) => '₹${n.toString()} /-';
String monthName(int m) => const ['', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][m];
String fullDate(DateTime d) => '${d.day} ${monthName(d.month)} ${d.year}';
String shortDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

class TeamMember {
  String id, name, phone;
  TeamMember({required this.id, required this.name, required this.phone});
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'phone': phone};
  factory TeamMember.fromJson(Map<String, dynamic> j) => TeamMember(
        id: j['id']?.toString() ?? idNow(),
        name: j['name']?.toString() ?? '',
        phone: j['phone']?.toString() ?? '',
      );
}

class EventData {
  String id, client, phone, venue, time, notes, groupId;
  DateTime date;
  List<String> types;
  Map<String, List<String>> assignments;
  EventData({
    required this.id, required this.client, required this.phone,
    required this.venue, required this.time, required this.notes,
    required this.date, required this.types, required this.assignments,
    String? groupId,
  }) : groupId = groupId ?? id;
  String get type => types.join(', ');
  Map<String, dynamic> toJson() => {
        'id': id, 'client': client, 'phone': phone, 'venue': venue,
        'time': time, 'notes': notes, 'date': date.toIso8601String(),
        'types': types, 'assignments': assignments, 'groupId': groupId,
      };
  factory EventData.fromJson(Map<String, dynamic> j) {
    final raw = Map<String, dynamic>.from(j['assignments'] ?? {});
    final a = <String, List<String>>{};
    for (final r in roles) a[r] = List<String>.from(raw[r] ?? const []);
    final rawTypes = j['types'];
    final t = rawTypes is List
        ? rawTypes.map((x) => x.toString()).where((x) => x.isNotEmpty).toList()
        : [j['type']?.toString() ?? 'Wedding'];
    return EventData(
      id: j['id']?.toString() ?? idNow(), client: j['client']?.toString() ?? '',
      phone: j['phone']?.toString() ?? '', venue: j['venue']?.toString() ?? '',
      time: j['time']?.toString() ?? '', notes: j['notes']?.toString() ?? '',
      date: DateTime.tryParse(j['date']?.toString() ?? '') ?? DateTime.now(),
      types: t.isEmpty ? ['Wedding'] : t, assignments: a,
      groupId: j['groupId']?.toString(),
    );
  }
}

class QuotationEvent {
  String date, event, side;
  Map<String, int> requirements;
  QuotationEvent({required this.date, required this.event, required this.side, required this.requirements});
  Map<String, dynamic> toJson() => {'date': date, 'event': event, 'side': side, 'requirements': requirements};
  factory QuotationEvent.fromJson(Map<String, dynamic> j) => QuotationEvent(
        date: j['date']?.toString() ?? '', event: j['event']?.toString() ?? '',
        side: j['side']?.toString() ?? 'Both Side',
        requirements: Map<String, int>.from((j['requirements'] ?? {}).map((k, v) => MapEntry(k.toString(), (v as num).toInt()))),
      );
}

class Deliverable {
  String name; int quantity;
  Deliverable(this.name, this.quantity);
  Map<String, dynamic> toJson() => {'name': name, 'quantity': quantity};
  factory Deliverable.fromJson(Map<String, dynamic> j) => Deliverable(j['name']?.toString() ?? '', (j['quantity'] as num?)?.toInt() ?? 1);
}

class Album {
  String name; int quantity, photos, price;
  Album({required this.name, required this.quantity, required this.photos, required this.price});
  int get total => quantity * price;
  Map<String, dynamic> toJson() => {'name': name, 'quantity': quantity, 'photos': photos, 'price': price};
  factory Album.fromJson(Map<String, dynamic> j) => Album(
        name: j['name']?.toString() ?? 'Wedding Album',
        quantity: (j['quantity'] as num?)?.toInt() ?? 1,
        photos: (j['photos'] as num?)?.toInt() ?? 400,
        price: (j['price'] as num?)?.toInt() ?? 0,
      );
}

class Quotation {
  String id, client, phone, email, createdDate, tnc;
  List<QuotationEvent> events;
  List<Deliverable> deliverables;
  List<Album> albums;
  int shootCharges, editingCharges;
  Quotation({required this.id, required this.client, required this.phone, required this.email, required this.createdDate, required this.events, required this.deliverables, required this.albums, required this.shootCharges, required this.editingCharges, required this.tnc});
  int get total => shootCharges + editingCharges;
  int get albumTotal => albums.fold(0, (s, a) => s + a.total);
  Map<String, dynamic> toJson() => {
        'id': id, 'client': client, 'phone': phone, 'email': email,
        'createdDate': createdDate, 'events': events.map((e) => e.toJson()).toList(),
        'deliverables': deliverables.map((d) => d.toJson()).toList(),
        'albums': albums.map((a) => a.toJson()).toList(), 'shootCharges': shootCharges,
        'editingCharges': editingCharges, 'tnc': tnc,
      };
  factory Quotation.fromJson(Map<String, dynamic> j) => Quotation(
        id: j['id']?.toString() ?? idNow(), client: j['client']?.toString() ?? '',
        phone: j['phone']?.toString() ?? '', email: j['email']?.toString() ?? '',
        createdDate: j['createdDate']?.toString() ?? '',
        events: (j['events'] as List? ?? []).map((x) => QuotationEvent.fromJson(Map<String, dynamic>.from(x))).toList(),
        deliverables: (j['deliverables'] as List? ?? []).map((x) => Deliverable.fromJson(Map<String, dynamic>.from(x))).toList(),
        albums: (j['albums'] as List? ?? []).map((x) => Album.fromJson(Map<String, dynamic>.from(x))).toList(),
        shootCharges: (j['shootCharges'] as num?)?.toInt() ?? 0,
        editingCharges: (j['editingCharges'] as num?)?.toInt() ?? 0,
        tnc: j['tnc']?.toString() ?? '',
      );
}

class BrandProfile {
  final String name, phone, email;
  final String? logo;
  const BrandProfile({required this.name, required this.phone, required this.email, required this.logo});
}

void main() => runApp(const CrewFlowApp());

class CrewFlowApp extends StatefulWidget {
  const CrewFlowApp({super.key});
  @override State<CrewFlowApp> createState() => _CrewFlowAppState();
}
class _CrewFlowAppState extends State<CrewFlowApp> {
  bool dark = true;
  @override Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false, title: 'CrewFlow', themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: purple),
        darkTheme: ThemeData(useMaterial3: true, colorSchemeSeed: purple, brightness: Brightness.dark, scaffoldBackgroundColor: const Color(0xFF0B0B0F)),
        home: HomePage(dark: dark, onDark: () => setState(() => dark = !dark)),
      );
}

class HomePage extends StatefulWidget {
  final bool dark; final VoidCallback onDark;
  const HomePage({super.key, required this.dark, required this.onDark});
  @override State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  int tab = 0;
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month), selected = DateTime.now();
  List<EventData> events = [];
  List<TeamMember> team = [];
  List<Quotation> quotations = [];
  String brandName = '', brandPhone = '', brandEmail = '', search = '';
  String? logo;
  List<String> tcs = [];

  @override void initState() { super.initState(); load(); }
  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    EventData? event(String x) { try { return EventData.fromJson(jsonDecode(x)); } catch (_) { return null; } }
    TeamMember? member(String x) { try { return TeamMember.fromJson(jsonDecode(x)); } catch (_) { return null; } }
    Quotation? quote(String x) { try { return Quotation.fromJson(jsonDecode(x)); } catch (_) { return null; } }
    setState(() {
      events = (p.getStringList('events') ?? []).map(event).whereType<EventData>().toList();
      team = (p.getStringList('team') ?? []).map(member).whereType<TeamMember>().toList();
      quotations = (p.getStringList('quotes') ?? []).map(quote).whereType<Quotation>().toList();
      brandName = p.getString('brandName') ?? ''; brandPhone = p.getString('brandPhone') ?? ''; brandEmail = p.getString('brandEmail') ?? '';
      logo = p.getString('logo'); tcs = p.getStringList('tcs') ?? [];
    });
  }
  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList('events', events.map((e) => jsonEncode(e.toJson())).toList());
    await p.setStringList('team', team.map((e) => jsonEncode(e.toJson())).toList());
    await p.setStringList('quotes', quotations.map((e) => jsonEncode(e.toJson())).toList());
    await p.setString('brandName', brandName); await p.setString('brandPhone', brandPhone); await p.setString('brandEmail', brandEmail);
    if (logo == null) { await p.remove('logo'); } else { await p.setString('logo', logo!); }
    await p.setStringList('tcs', tcs);
  }
  bool same(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
  void moveMonth(int n) => setState(() { month = DateTime(month.year, month.month + n); selected = DateTime(month.year, month.month, 1); });
  List<EventData> monthEvents() => events.where((e) => e.date.year == month.year && e.date.month == month.month).toList()..sort((a,b)=>a.date.compareTo(b.date));
  List<EventData> dayEvents(DateTime d) => events.where((e)=>same(e.date,d)).toList();
  BrandProfile get profile => BrandProfile(name: brandName, phone: brandPhone, email: brandEmail, logo: logo);

  @override Widget build(BuildContext context) => Scaffold(
    drawer: Drawer(child: SafeArea(child: ListView(children: [
      const SizedBox(height: 16), ListTile(leading: const CircleAvatar(backgroundColor: purple, child: Icon(Icons.movie_creation_outlined, color: Colors.white)), title: const Text('CrewFlow', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), subtitle: const Text('Organize. Assign. Capture.')),
      const Divider(), ListTile(leading: const Icon(Icons.calendar_month), title: const Text('Calendar'), onTap: () { Navigator.pop(context); setState(()=>tab=0); }),
      ListTile(leading: const Icon(Icons.groups), title: const Text('Team'), onTap: () { Navigator.pop(context); setState(()=>tab=2); }),
      ListTile(leading: const Icon(Icons.request_quote), title: const Text('Quotation'), onTap: () { Navigator.pop(context); openQuotes(); }),
      ListTile(leading: const Icon(Icons.person_outline), title: const Text('Business Profile'), onTap: () { Navigator.pop(context); profileDialog(); }),
      SwitchListTile(value: widget.dark, onChanged: (_) { Navigator.pop(context); widget.onDark(); }, title: const Text('Dark mode'), secondary: const Icon(Icons.dark_mode_outlined)),
    ]))),
    body: SafeArea(child: [calendarPage(), eventsPage(), teamPage(), morePage()][tab]),
    bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (i)=>setState(()=>tab=i), destinations: const [
      NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Calendar'),
      NavigationDestination(icon: Icon(Icons.event_outlined), selectedIcon: Icon(Icons.event), label: 'Events'),
      NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Team'),
      NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
    ]),
  );

  Widget header(String title, {List<Widget> actions = const []}) => Row(children: [Builder(builder: (c)=>IconButton(onPressed: ()=>Scaffold.of(c).openDrawer(), icon: const Icon(Icons.menu))), Expanded(child: Center(child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)))), ...actions]);

  Widget calendarPage() {
    final first = DateTime(month.year, month.month, 1), days = DateTime(month.year, month.month+1, 0);
    final offset = first.weekday % 7, cells = ((offset + days.day + 6) ~/ 7) * 7;
    return Column(children: [header('Dashboard'), Row(mainAxisAlignment: MainAxisAlignment.center, children: [IconButton(onPressed: ()=>moveMonth(-1), icon: const Icon(Icons.chevron_left)), Text('${monthName(month.month)} ${month.year}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)), IconButton(onPressed: ()=>moveMonth(1), icon: const Icon(Icons.chevron_right))]),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Row(children: ['SUN','MON','TUE','WED','THU','FRI','SAT'].map((x)=>Expanded(child: Center(child: Text(x, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)))).toList())),
      SizedBox(height: 300, child: GridView.builder(physics: const NeverScrollableScrollPhysics(), padding: const EdgeInsets.all(10), itemCount: cells, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7), itemBuilder: (_,i) {
        if (i < offset || i >= offset+days.day) return const SizedBox(); final d=DateTime(month.year,month.month,i-offset+1); final has=dayEvents(d).isNotEmpty; final sel=same(d,selected);
        return GestureDetector(onTap: ()=>setState(()=>selected=d), child: Container(margin: const EdgeInsets.all(3), decoration: BoxDecoration(color: sel?purple:Colors.transparent, shape: BoxShape.circle), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('${d.day}', style: TextStyle(fontWeight: FontWeight.bold, color: sel?Colors.white:null)), if(has) Container(width:5,height:5,margin:const EdgeInsets.only(top:3),decoration:BoxDecoration(color:sel?Colors.white:purple,shape:BoxShape.circle))])));
      })),
      Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(14,0,14,90), children: [Row(children: [Expanded(child: Text('${monthName(month.month)} Events', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17))), Text('${monthEvents().length} Events')]), ...monthEvents().map(eventCard), if(monthEvents().isEmpty) const Padding(padding: EdgeInsets.all(28), child: Center(child: Text('No events booked this month')))])),
      Align(alignment: Alignment.bottomRight, child: Padding(padding: const EdgeInsets.all(16), child: FloatingActionButton(onPressed: ()=>eventDialog(initialDate:selected), child: const Icon(Icons.add)))),
    ]);
  }

  Widget eventCard(EventData e) => Card(child: ListTile(contentPadding: const EdgeInsets.all(14), onTap: ()=>eventDialog(existing:e), leading: Container(width:5,height:65,decoration:BoxDecoration(color:purple,borderRadius:BorderRadius.circular(8))), title: Text(e.client.isEmpty?'Event':e.client, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('${fullDate(e.date)} • ${e.type}\n📍 ${e.venue}\n🎥 ${e.assignments.values.fold<int>(0,(s,v)=>s+v.length)} crew'), isThreeLine: true, trailing: PopupMenuButton<String>(onSelected:(v)async{if(v=='pdf')await Navigator.push(context,MaterialPageRoute(builder:(_)=>EventPdf(events:[e],profile:profile,team:team)));if(v=='delete'){final ok=await confirm('Delete this event?');if(ok){setState(()=>events.removeWhere((x)=>x.id==e.id));await save();}}},itemBuilder:(_)=>const[PopupMenuItem(value:'pdf',child:Text('Open PDF')),PopupMenuItem(value:'delete',child:Text('Delete'))])));

  Widget eventsPage() {
    final list = events.where((e)=>'${e.client} ${e.phone} ${e.venue} ${e.type}'.toLowerCase().contains(search.toLowerCase())).toList()..sort((a,b)=>a.date.compareTo(b.date));
    return Column(children: [header('Events'), Padding(padding: const EdgeInsets.all(12), child: TextField(onChanged:(v)=>setState(()=>search=v), decoration: const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Search client, phone or event'))), Expanded(child: list.isEmpty?const Center(child:Text('No events')):ListView(padding:const EdgeInsets.symmetric(horizontal:12),children:list.map(eventCard).toList())), Align(alignment:Alignment.bottomRight,child:Padding(padding:const EdgeInsets.all(16),child:FloatingActionButton(onPressed:()=>eventDialog(initialDate:DateTime.now()),child:const Icon(Icons.add))))]);
  }

  Widget teamPage() => Stack(children: [Column(children:[header('Team Members'),Expanded(child: team.isEmpty?const Center(child:Text('No team members yet\nTap + to add')):ListView.builder(padding:const EdgeInsets.all(12),itemCount:team.length,itemBuilder:(_,i)=>teamTile(team[i]))) ]),Positioned(right:18,bottom:18,child:FloatingActionButton(onPressed:addTeam,child:const Icon(Icons.add))) ]);
  Widget teamTile(TeamMember m) => Card(child: ListTile(leading:CircleAvatar(backgroundColor:purple,child:Text(m.name.isEmpty?'?':m.name[0].toUpperCase())),title:Text(m.name,style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text(m.phone),trailing:Row(mainAxisSize:MainAxisSize.min,children:[IconButton(onPressed:()=>whatsapp(m.phone,'Hi ${m.name}, please check your CrewFlow event assignments.'),icon:const Icon(Icons.chat_outlined)),IconButton(onPressed:()=>call(m.phone),icon:const Icon(Icons.call_outlined)),PopupMenuButton<String>(onSelected:(v)async{if(v=='delete'){setState(()=>team.removeWhere((x)=>x.id==m.id));await save();}},itemBuilder:(_)=>const[PopupMenuItem(value:'delete',child:Text('Delete'))])])));

  Widget morePage()=>ListView(children:[header('More'),ListTile(leading:const Icon(Icons.request_quote_outlined),title:const Text('Quotation'),subtitle:const Text('Create branded quotation PDF'),onTap:openQuotes),ListTile(leading:const Icon(Icons.business_outlined),title:const Text('Business Profile'),subtitle:Text(brandName.isEmpty?'Add logo and business details':brandName),onTap:profileDialog),ListTile(leading:const Icon(Icons.dark_mode_outlined),title:const Text('Dark Mode'),trailing:Switch(value:widget.dark,onChanged:(_)=>widget.onDark())),ListTile(leading:const Icon(Icons.delete_sweep_outlined),title:const Text('Delete All Events'),onTap:deleteAllEvents)]);

  Future<void> deleteAllEvents() async { final ok=await confirm('Delete all events?'); if(ok){setState(()=>events.clear());await save();} }
  Future<bool> confirm(String text) async => await showDialog<bool>(context:context,builder:(_)=>AlertDialog(title:const Text('Confirm'),content:Text(text),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Delete'))]))??false;

  Future<void> addTeam() async {
    final name=TextEditingController(), phone=TextEditingController();
    final useContacts=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(title:const Text('Add Team Member'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:name,decoration:const InputDecoration(labelText:'Name')),const SizedBox(height:10),TextField(controller:phone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'Phone')),const SizedBox(height:8),TextButton.icon(onPressed:()async{final c=await pickContact();if(c!=null){name.text=c.displayName;phone.text=c.phones.isEmpty?'':c.phones.first.number;}},icon:const Icon(Icons.contacts_outlined),label:const Text('Pick from Contacts'))]),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Add'))]));
    if(useContacts==true && name.text.trim().isNotEmpty){setState(()=>team.add(TeamMember(id:idNow(),name:name.text.trim(),phone:phone.text.trim())));await save();}
  }
  Future<Contact?> pickContact() async {
    try { final granted=await FlutterContacts.permissions.request(PermissionType.read); if(granted != PermissionStatus.granted)return null; final cs=await FlutterContacts.getAll(withProperties:true); if(!mounted)return null; return await showModalBottomSheet<Contact>(context:context,isScrollControlled:true,builder:(_)=>ContactSheet(contacts:cs)); } catch(_){ if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Contacts permission or access failed.'))); return null; }
  }

  Future<void> eventDialog({EventData? existing, DateTime? initialDate}) async {
    final client=TextEditingController(text:existing?.client??''), phone=TextEditingController(text:existing?.phone??''), venue=TextEditingController(text:existing?.venue??''), notes=TextEditingController(text:existing?.notes??'');
    DateTime date=existing?.date??initialDate??DateTime.now(); TimeOfDay time=parseTime(existing?.time??'')??TimeOfDay.now(); List<String> types=List.from(existing?.types??['Wedding']); Map<String,List<String>> assign={for(final r in roles) r:List<String>.from(existing?.assignments[r]??const[])};
    final ok=await showDialog<bool>(context:context,builder:(_)=>StatefulBuilder(builder:(ctx,setD)=>AlertDialog(title:Text(existing==null?'Add Event':'Edit Event'),content:SizedBox(width:560,child:SingleChildScrollView(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      TextField(controller:client,decoration:const InputDecoration(labelText:'Client Name',prefixIcon:Icon(Icons.person_outline))),const SizedBox(height:10),TextField(controller:phone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'Client Phone',prefixIcon:Icon(Icons.phone_outlined))),const SizedBox(height:12),const Text('Event Type',style:TextStyle(fontWeight:FontWeight.bold)),Wrap(spacing:6,children:eventTypes.map((x)=>FilterChip(label:Text(x),selected:types.contains(x),onSelected:(v)=>setD(()=>v?types.add(x):types.remove(x)))).toList()),TextField(controller:venue,decoration:const InputDecoration(labelText:'Venue / Location',prefixIcon:Icon(Icons.location_on_outlined))),ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.calendar_month),title:const Text('Date'),subtitle:Text(shortDate(date)),onTap:()async{final d=await showDatePicker(context:ctx,firstDate:DateTime(2020),lastDate:DateTime(2100),initialDate:date);if(d!=null)setD(()=>date=d);}),ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.access_time),title:const Text('Time'),subtitle:Text(formatTime(time)),onTap:()async{final t=await showTimePicker(context:ctx,initialTime:time);if(t!=null)setD(()=>time=t);}),TextField(controller:notes,maxLines:3,decoration:const InputDecoration(labelText:'Notes',alignLabelWithHint:true)),const SizedBox(height:12),const Text('Assign Team',style:TextStyle(fontWeight:FontWeight.bold)),...assign.entries.where((e)=>e.value.isNotEmpty).map((e)=>ListTile(contentPadding:EdgeInsets.zero,title:Text('${e.key}: ${e.value.join(', ')}'),trailing:TextButton(onPressed:()async{final s=await assignDialog(e.key,e.value);if(s!=null)setD(()=>assign[e.key]=s);},child:const Text('Change')))),OutlinedButton.icon(onPressed:()async{final r=await showModalBottomSheet<String>(context:ctx,builder:(_)=>SafeArea(child:ListView(shrinkWrap:true,children:roles.map((r)=>ListTile(title:Text(r),onTap:()=>Navigator.pop(ctx,r))).toList())));if(r!=null){final s=await assignDialog(r,assign[r]??[]);if(s!=null)setD(()=>assign[r]=s);}},icon:const Icon(Icons.add),label:const Text('Add Team'))
    ]))),actions:[if(existing!=null)TextButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Delete',style:TextStyle(color:Colors.redAccent))),TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Save'))])));
    if(ok!=true)return;
    final valid=client.text.trim().isNotEmpty&&venue.text.trim().isNotEmpty&&types.isNotEmpty;
    if(!valid){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Client, Venue and Event Type are required.')));return;}
    final e=EventData(id:existing?.id??idNow(),client:client.text.trim(),phone:phone.text.trim(),venue:venue.text.trim(),time:formatTime(time),notes:notes.text.trim(),date:date,types:types,assignments:assign,groupId:existing?.groupId);
    setState(()=>existing==null?events.add(e):events[events.indexWhere((x)=>x.id==existing.id)]=e); await save();
  }
  TimeOfDay? parseTime(String s){final m=RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)?$',caseSensitive:false).firstMatch(s.trim());if(m==null)return null;var h=int.parse(m.group(1)!);final min=int.parse(m.group(2)!);final ap=m.group(3)?.toUpperCase();if(ap=='PM'&&h!=12)h+=12;if(ap=='AM'&&h==12)h=0;return TimeOfDay(hour:h,minute:min);}
  String formatTime(TimeOfDay t)=>t.format(context);
  Future<List<String>?> assignDialog(String role,List<String> already) async {final chosen=already.toSet();return showDialog<List<String>>(context:context,builder:(_)=>StatefulBuilder(builder:(ctx,setD)=>AlertDialog(title:Text('Assign $role'),content:SizedBox(width:420,height:380,child:team.isEmpty?const Center(child:Text('Add team members first.')):ListView(children:team.map((m)=>CheckboxListTile(value:chosen.contains(m.name),onChanged:(v)=>setD(()=>v==true?chosen.add(m.name):chosen.remove(m.name)),title:Text(m.name),subtitle:Text(m.phone))).toList())),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(ctx,chosen.toList()),child:const Text('Done'))]))));}

  Future<void> profileDialog() async {
    final n = TextEditingController(text: brandName);
    final p = TextEditingController(text: brandPhone);
    final e = TextEditingController(text: brandEmail);
    String? newLogo = logo;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Business Profile'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                GestureDetector(
                  onTap: () async {
                    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
                    if (x == null) return;
                    final bytes = await x.readAsBytes();
                    setD(() => newLogo = base64Encode(bytes));
                  },
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(border: Border.all(color: Theme.of(ctx).colorScheme.outline), borderRadius: BorderRadius.circular(14)),
                    child: newLogo == null ? const Icon(Icons.add_photo_alternate_outlined) : Image.memory(base64Decode(newLogo!), fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(onPressed: () async {
                  final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
                  if (x == null) return;
                  final bytes = await x.readAsBytes();
                  setD(() => newLogo = base64Encode(bytes));
                }, icon: const Icon(Icons.upload), label: const Text('Upload Logo')),
                TextField(controller: n, decoration: const InputDecoration(labelText: 'Business / Brand Name')),
                TextField(controller: p, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Contact')),
                TextField(controller: e, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(onPressed: () async {
              setState(() { brandName = n.text.trim(); brandPhone = p.text.trim(); brandEmail = e.text.trim(); logo = newLogo; });
              await save();
              if (ctx.mounted) Navigator.pop(ctx);
            }, child: const Text('Save')),
          ],
        ),
      ),
    );
    n.dispose(); p.dispose(); e.dispose();
  }

  void openQuotes() { Navigator.push(context,MaterialPageRoute(builder:(_)=>QuotationList(initial:quotations,profile:profile,templates:tcs,onChanged:(q,t){setState((){quotations=q;tcs=t;});save();}))); }
  Future<void> whatsapp(String phone,String message) async {var p=phone.replaceAll(RegExp(r'\D'),'');if(p.length==10)p='91$p';final u=Uri.parse('https://wa.me/$p?text=${Uri.encodeComponent(message)}');if(await canLaunchUrl(u))await launchUrl(u,mode:LaunchMode.externalApplication);}
  Future<void> call(String phone) async {final u=Uri(scheme:'tel',path:phone);if(await canLaunchUrl(u))await launchUrl(u);}
}

class ContactSheet extends StatefulWidget {final List<Contact> contacts;const ContactSheet({super.key,required this.contacts});@override State<ContactSheet> createState()=>_ContactSheetState();}
class _ContactSheetState extends State<ContactSheet>{String q='';@override Widget build(BuildContext context){final list=widget.contacts.where((c)=>c.displayName.toLowerCase().contains(q.toLowerCase())).toList();return SizedBox(height:MediaQuery.sizeOf(context).height*.8,child:Column(children:[Padding(padding:const EdgeInsets.all(14),child:TextField(onChanged:(v)=>setState(()=>q=v),decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Search contact'))),Expanded(child:ListView(children:list.map((c)=>ListTile(leading:const CircleAvatar(child:Icon(Icons.person)),title:Text(c.displayName),subtitle:Text(c.phones.isEmpty?'No phone':c.phones.first.number),onTap:()=>Navigator.pop(context,c))).toList()))]));}}

class QuotationList extends StatefulWidget {final List<Quotation> initial;final BrandProfile profile;final List<String> templates;final void Function(List<Quotation>,List<String>) onChanged;const QuotationList({super.key,required this.initial,required this.profile,required this.templates,required this.onChanged});@override State<QuotationList> createState()=>_QuotationListState();}
class _QuotationListState extends State<QuotationList>{late List<Quotation> qs;late List<String> ts;@override void initState(){super.initState();qs=List.from(widget.initial);ts=List.from(widget.templates);}void changed(){widget.onChanged(qs,ts);}
@override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Quotations'),actions:[IconButton(onPressed:()=>edit(),icon:const Icon(Icons.add))]),floatingActionButton:FloatingActionButton(onPressed:()=>edit(),child:const Icon(Icons.add)),body:qs.isEmpty?const Center(child:Text('No quotations yet')):ListView.builder(padding:const EdgeInsets.all(12),itemCount:qs.length,itemBuilder:(_,i){final q=qs[i];return Card(child:ListTile(title:Text(q.client.isEmpty?'Untitled':q.client,style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text('${q.events.length} event(s) • ${q.createdDate}\n${money(q.total)}'),trailing:PopupMenuButton<String>(onSelected:(v)async{if(v=='edit')await edit(q);if(v=='pdf')await Navigator.push(context,MaterialPageRoute(builder:(_)=>QuotationPdf(q:q,profile:widget.profile)));if(v=='delete'){setState(()=>qs.removeWhere((x)=>x.id==q.id));changed();}},itemBuilder:(_)=>const[PopupMenuItem(value:'edit',child:Text('Edit')),PopupMenuItem(value:'pdf',child:Text('Open PDF')),PopupMenuItem(value:'delete',child:Text('Delete'))])));});}
Future<void> edit([Quotation? q])async{final r=await Navigator.push<Quotation>(context,MaterialPageRoute(builder:(_)=>QuotationEditor(initial:q,profile:widget.profile,templates:ts,onTemplates:(x)=>ts=x)));if(r!=null){setState((){qs.removeWhere((x)=>x.id==r.id);qs.add(r);});changed();}}
}

class QuotationEditor extends StatefulWidget {final Quotation? initial;final BrandProfile profile;final List<String> templates;final void Function(List<String>) onTemplates;const QuotationEditor({super.key,this.initial,required this.profile,required this.templates,required this.onTemplates});@override State<QuotationEditor> createState()=>_QuotationEditorState();}
class _QuotationEditorState extends State<QuotationEditor>{late TextEditingController client,phone,email,shoot,editing,tnc;late List<QuotationEvent> events;late List<Deliverable> dels;late List<Album> albums;late List<String> ts;
final req=['Photographer','Videographer','Candid','Cinematographer','Drone','Helper'];final delNames=['Reels','Teaser','Cinematic Highlight','Full Video','Short Film'];
@override void initState(){super.initState();final q=widget.initial;client=TextEditingController(text:q?.client??'');phone=TextEditingController(text:q?.phone??'');email=TextEditingController(text:q?.email??'');shoot=TextEditingController(text:'${q?.shootCharges??0}');editing=TextEditingController(text:'${q?.editingCharges??0}');tnc=TextEditingController(text:q?.tnc??'');events=List.from(q?.events??[]);dels=List.from(q?.deliverables??[Deliverable('Reels',4),Deliverable('Teaser',1),Deliverable('Cinematic Highlight',1),Deliverable('Full Video',1)]);albums=List.from(q?.albums??[]);ts=List.from(widget.templates);}
int num(TextEditingController c)=>int.tryParse(c.text.replaceAll(',',''))??0;
Future<void> addEvent()async{DateTime d=DateTime.now();String ev=eventTypes.first,side='Both Side';final r=<String,int>{};final ok=await showDialog<bool>(context:context,builder:(_)=>StatefulBuilder(builder:(ctx,setD)=>AlertDialog(title:const Text('Add Event'),content:SingleChildScrollView(child:Column(children:[ListTile(title:Text(shortDate(d)),leading:const Icon(Icons.calendar_month),onTap:()async{final x=await showDatePicker(context:ctx,firstDate:DateTime(2020),lastDate:DateTime(2100),initialDate:d);if(x!=null)setD(()=>d=x);}),DropdownButtonFormField<String>(value:ev,items:eventTypes.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(x)=>setD(()=>ev=x!),decoration:const InputDecoration(labelText:'Event')),DropdownButtonFormField<String>(value:side,items:const['Bride Side','Groom Side','Both Side'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(x)=>setD(()=>side=x!),decoration:const InputDecoration(labelText:'Side')),const SizedBox(height:8),...req.map((x)=>Row(children:[Expanded(child:Text(x)),IconButton(onPressed:()=>setD(()=>r[x]=((r[x]??0)-1).clamp(0,99)),icon:const Icon(Icons.remove_circle_outline)),Text('${r[x]??0}'),IconButton(onPressed:()=>setD(()=>r[x]=(r[x]??0)+1),icon:const Icon(Icons.add_circle_outline))]))])),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Add'))])));if(ok==true)setState(()=>events.add(QuotationEvent(date:shortDate(d),event:ev,side:side,requirements:r)));}
Future<void> saveQ()async{if(client.text.trim().isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Client name is required.')));return;}final q=Quotation(id:widget.initial?.id??idNow(),client:client.text.trim(),phone:phone.text.trim(),email:email.text.trim(),createdDate:widget.initial?.createdDate??shortDate(DateTime.now()),events:events,deliverables:dels,albums:albums,shootCharges:num(shoot),editingCharges:num(editing),tnc:tnc.text.trim());await Navigator.push(context,MaterialPageRoute(builder:(_)=>QuotationPdf(q:q,profile:widget.profile)));if(mounted)Navigator.pop(context,q);}
@override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(widget.initial==null?'Create Quotation':'Edit Quotation'),actions:[IconButton(onPressed:saveQ,icon:const Icon(Icons.check))]),body:ListView(padding:const EdgeInsets.all(14),children:[section('Client Details',Column(children:[TextField(controller:client,decoration:const InputDecoration(labelText:'Client Name')),TextField(controller:phone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'Mobile Number')),TextField(controller:email,decoration:const InputDecoration(labelText:'Email (optional)'))])),section('Event Coverage',Column(children:[...events.asMap().entries.map((x)=>Card(child:ListTile(title:Text('${x.value.date} • ${x.value.event}'),subtitle:Text('${x.value.side} • ${x.value.requirements.entries.where((e)=>e.value>0).map((e)=>'${e.key} × ${e.value}').join(' + ')}'),trailing:IconButton(onPressed:()=>setState(()=>events.removeAt(x.key)),icon:const Icon(Icons.delete_outline)))),OutlinedButton.icon(onPressed:addEvent,icon:const Icon(Icons.add),label:const Text('Add Event / Date'))])),section('Deliverables',Column(children:[...dels.asMap().entries.map((x)=>Row(children:[Expanded(child:Text(x.value.name)),IconButton(onPressed:()=>setState(()=>x.value.quantity=(x.value.quantity-1).clamp(0,999)),icon:const Icon(Icons.remove_circle_outline)),Text('${x.value.quantity}'),IconButton(onPressed:()=>setState(()=>x.value.quantity++),icon:const Icon(Icons.add_circle_outline)),IconButton(onPressed:()=>setState(()=>dels.removeAt(x.key)),icon:const Icon(Icons.close))])),DropdownButtonFormField<String>(decoration:const InputDecoration(labelText:'Add Deliverable'),items:delNames.where((x)=>!dels.any((d)=>d.name==x)).map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(x){if(x!=null)setState(()=>dels.add(Deliverable(x,1)));})])),section('Investment',Column(children:[TextField(controller:shoot,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Shoot Charges',prefixText:'₹ ')),TextField(controller:editing,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Video Editing Charges',prefixText:'₹ ')),const SizedBox(height:10),Align(alignment:Alignment.centerRight,child:Text('Total Package: ₹${num(shoot)+num(editing)}',style:const TextStyle(fontWeight:FontWeight.bold,fontSize:18)))])),section('Albums — Optional / Extra',Column(children:[...albums.asMap().entries.map((x)=>Card(child:Padding(padding:const EdgeInsets.all(10),child:Column(children:[TextField(initialValue:x.value.name,decoration:const InputDecoration(labelText:'Album Name'),onChanged:(v)=>x.value.name=v),Row(children:[Expanded(child:TextFormField(initialValue:'${x.value.quantity}',keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Albums'),onChanged:(v)=>x.value.quantity=int.tryParse(v)??1)),const SizedBox(width:8),Expanded(child:TextFormField(initialValue:'${x.value.photos}',keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Photos / Album'),onChanged:(v)=>x.value.photos=int.tryParse(v)??0)),const SizedBox(width:8),Expanded(child:TextFormField(initialValue:'${x.value.price}',keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Price / Album'),onChanged:(v)=>x.value.price=int.tryParse(v)??0))]),Align(alignment:Alignment.centerRight,child:Text('Total: ₹${x.value.total}')),TextButton(onPressed:()=>setState(()=>albums.removeAt(x.key)),child:const Text('Remove'))]))),OutlinedButton.icon(onPressed:()=>setState(()=>albums.add(Album(name:'Wedding Album',quantity:1,photos:400,price:0))),icon:const Icon(Icons.add),label:const Text('Add Album'))])),section('Terms & Conditions',Column(children:[if(ts.isNotEmpty)DropdownButtonFormField<String>(decoration:const InputDecoration(labelText:'Saved T&C'),items:ts.map((x)=>DropdownMenuItem(value:x,child:Text(x,overflow:TextOverflow.ellipsis))).toList(),onChanged:(v){if(v!=null)tnc.text=v;}),TextField(controller:tnc,maxLines:6,decoration:const InputDecoration(hintText:'Write terms & conditions')),TextButton.icon(onPressed:()async{final c=TextEditingController(text:tnc.text);final ok=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(title:const Text('Save T&C Template'),content:TextField(controller:c,maxLines:6),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Save'))]));if(ok==true&&c.text.trim().isNotEmpty){setState(()=>ts.add(c.text.trim()));widget.onTemplates(ts);}},icon:const Icon(Icons.save_outlined),label:const Text('Save as template'))])),const SizedBox(height:12),FilledButton.icon(onPressed:saveQ,icon:const Icon(Icons.picture_as_pdf),label:const Text('Save Quotation & Open PDF'))]));
Widget section(String title,Widget child)=>Card(margin:const EdgeInsets.only(bottom:12),child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:17)),const SizedBox(height:10),child])));
@override void dispose(){client.dispose();phone.dispose();email.dispose();shoot.dispose();editing.dispose();tnc.dispose();super.dispose();}}

class QuotationPdf extends StatelessWidget {final Quotation q;final BrandProfile profile;const QuotationPdf({super.key,required this.q,required this.profile});Future<Uint8List> make(PdfPageFormat _)async{final doc=pw.Document();pw.MemoryImage? img;if(profile.logo!=null){try{img=pw.MemoryImage(base64Decode(profile.logo!));}catch(_){}}
doc.addPage(pw.MultiPage(pageFormat:PdfPageFormat.a4,margin:const pw.EdgeInsets.all(30),build:(_)=>[
if(img!=null||profile.name.isNotEmpty)pw.Row(children:[if(img!=null)pw.Container(width:55,height:55,margin:const pw.EdgeInsets.only(right:10),child:pw.Image(img!,fit:pw.BoxFit.contain)),pw.Expanded(child:pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.start,children:[pw.Text(profile.name.isEmpty?'CREWFLOW':profile.name,style:pw.TextStyle(fontSize:19,fontWeight:pw.FontWeight.bold)),pw.Text([if(profile.phone.isNotEmpty)profile.phone,if(profile.email.isNotEmpty)profile.email].join(' | '),style:const pw.TextStyle(fontSize:8))]))]),pw.SizedBox(height:18),pw.Center(child:pw.Text('WEDDING PHOTOGRAPHY & CINEMATOGRAPHY',style:pw.TextStyle(fontSize:15,fontWeight:pw.FontWeight.bold))),pw.Center(child:pw.Text('QUOTATION',style:const pw.TextStyle(fontSize:11))),pw.SizedBox(height:15),pw.Table(border:pw.TableBorder.all(width:.5),children:[pw.TableRow(children:[cell('CLIENT',q.client),cell('DATE',q.createdDate)]),pw.TableRow(children:[cell('CONTACT',q.phone.isEmpty?'—':q.phone),cell('EMAIL',q.email.isEmpty?'—':q.email)])]),
pw.SizedBox(height:18),pw.Text('EVENT COVERAGE',style:pw.TextStyle(fontSize:13,fontWeight:pw.FontWeight.bold)),pw.SizedBox(height:6),pw.Table.fromTextArray(headers:const['DATE','EVENT','SIDE','COVERAGE'],data:q.events.map((e)=>[e.date,e.event,e.side,e.requirements.entries.where((x)=>x.value>0).map((x)=>'${x.key} × ${x.value}').join(' + ')]).toList(),headerStyle:pw.TextStyle(fontWeight:pw.FontWeight.bold,fontSize:7),cellStyle:const pw.TextStyle(fontSize:7),border:pw.TableBorder.all(width:.4)),
pw.SizedBox(height:18),pw.Text('DELIVERABLES',style:pw.TextStyle(fontSize:13,fontWeight:pw.FontWeight.bold)),pw.Table.fromTextArray(headers:const['DELIVERABLE','QTY'],data:q.deliverables.map((d)=>[d.name,'${d.quantity}']).toList(),headerStyle:pw.TextStyle(fontWeight:pw.FontWeight.bold,fontSize:8),cellStyle:const pw.TextStyle(fontSize:8),border:pw.TableBorder.all(width:.4)),
pw.SizedBox(height:18),pw.Text('INVESTMENT',style:pw.TextStyle(fontSize:13,fontWeight:pw.FontWeight.bold)),pw.Table.fromTextArray(headers:const['DESCRIPTION','AMOUNT'],data:[[ 'Shoot Charges',money(q.shootCharges)],['Video Editing Charges',money(q.editingCharges)],['TOTAL PACKAGE',money(q.total)]],headerStyle:pw.TextStyle(fontWeight:pw.FontWeight.bold,fontSize:8),cellStyle:const pw.TextStyle(fontSize:8),border:pw.TableBorder.all(width:.4)),
if(q.albums.isNotEmpty)pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.start,children:[pw.SizedBox(height:18),pw.Text('ALBUMS — OPTIONAL / EXTRA',style:pw.TextStyle(fontSize:13,fontWeight:pw.FontWeight.bold)),pw.Table.fromTextArray(headers:const['ALBUM','QTY','PHOTOS','PRICE','TOTAL'],data:q.albums.map((a)=>[a.name,'${a.quantity}','${a.photos}',money(a.price),money(a.total)]).toList(),headerStyle:pw.TextStyle(fontWeight:pw.FontWeight.bold,fontSize:7),cellStyle:const pw.TextStyle(fontSize:7),border:pw.TableBorder.all(width:.4))]),
if(q.tnc.trim().isNotEmpty)pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.start,children:[pw.SizedBox(height:18),pw.Text('TERMS & CONDITIONS',style:pw.TextStyle(fontSize:13,fontWeight:pw.FontWeight.bold)),pw.SizedBox(height:5),pw.Container(width:double.infinity,padding:const pw.EdgeInsets.all(9),decoration:pw.BoxDecoration(border:pw.Border.all(width:.4)),child:pw.Text(q.tnc,style:const pw.TextStyle(fontSize:8,leading:11)))]),pw.SizedBox(height:18),pw.Center(child:pw.Text('Thank you for choosing ${profile.name.isEmpty?'CrewFlow':profile.name}.',style:const pw.TextStyle(fontSize:8))) ]));return doc.save();}
pw.Widget cell(String a,String b)=>pw.Padding(padding:const pw.EdgeInsets.all(6),child:pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.start,children:[pw.Text(a,style:pw.TextStyle(fontSize:7,fontWeight:pw.FontWeight.bold)),pw.SizedBox(height:3),pw.Text(b,style:const pw.TextStyle(fontSize:9))]));
@override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Quotation PDF')),body:PdfPreview(canChangePageFormat:false,canChangeOrientation:false,allowPrinting:true,allowSharing:true,pdfFileName:'${q.client.isEmpty?'Quotation':q.client.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'),'_')}_Quotation.pdf',build:make));}
