import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const PHFApp());
const roles = ['Candid','Cinematographer','T. Photo','T. Video','Drone','Helper'];

class TeamMember {
  String id,name,phone,role;
  TeamMember({required this.id,required this.name,required this.phone,this.role='All'});
  Map<String,dynamic> toJson()=>{'id':id,'name':name,'phone':phone,'role':role};
  factory TeamMember.fromJson(Map<String,dynamic> j)=>TeamMember(id:j['id']?.toString()??'',name:j['name']?.toString()??'',phone:j['phone']?.toString()??'',role:j['role']?.toString()??'All');
}
class EventData {
  String id,name,client,phone,venue,time,notes,type; DateTime date; Map<String,List<String>> assignments;
  EventData({required this.id,required this.name,required this.client,required this.phone,required this.venue,required this.time,required this.notes,required this.type,required this.date,required this.assignments});
  Map<String,dynamic> toJson()=>{'id':id,'name':name,'client':client,'phone':phone,'venue':venue,'time':time,'notes':notes,'type':type,'date':date.toIso8601String(),'assignments':assignments};
  factory EventData.fromJson(Map<String,dynamic> j){final raw=Map<String,dynamic>.from(j['assignments']??{});final a=<String,List<String>>{};for(final r in roles){a[r]=List<String>.from(raw[r]??const []);}return EventData(id:j['id']?.toString()??'',name:j['name']?.toString()??'',client:j['client']?.toString()??'',phone:j['phone']?.toString()??'',venue:j['venue']?.toString()??'',time:j['time']?.toString()??'',notes:j['notes']?.toString()??'',type:j['type']?.toString()??'Wedding',date:DateTime.tryParse(j['date']?.toString()??'')??DateTime.now(),assignments:a);}
}
class PHFApp extends StatefulWidget{const PHFApp({super.key});@override State<PHFApp> createState()=>_PHFAppState();}
class _PHFAppState extends State<PHFApp>{bool dark=false;@override void initState(){super.initState();SharedPreferences.getInstance().then((p)=>setState(()=>dark=p.getBool('dark')??false));}Future<void> toggle()async{final p=await SharedPreferences.getInstance();setState(()=>dark=!dark);await p.setBool('dark',dark);}@override Widget build(BuildContext c)=>MaterialApp(debugShowCheckedModeBanner:false,title:'PHF',themeMode:dark?ThemeMode.dark:ThemeMode.light,theme:ThemeData(useMaterial3:true,colorSchemeSeed:const Color(0xFF6C3FF5)),darkTheme:ThemeData(useMaterial3:true,colorSchemeSeed:const Color(0xFF8B63FF),brightness:Brightness.dark),home:PHFHome(dark:dark,onDark:toggle));}
class PHFHome extends StatefulWidget{final bool dark;final VoidCallback onDark;const PHFHome({super.key,required this.dark,required this.onDark});@override State<PHFHome> createState()=>_PHFHomeState();}
class _PHFHomeState extends State<PHFHome>{int tab=0;DateTime month=DateTime(DateTime.now().year,DateTime.now().month),selected=DateTime.now();List<EventData> events=[];List<TeamMember> team=[];String search='';
@override void initState(){super.initState();load();}Future<void> load()async{final p=await SharedPreferences.getInstance();final es=(p.getStringList('events')??[]).map((x){try{return EventData.fromJson(jsonDecode(x));}catch(_){return null;}}).whereType<EventData>().toList();final ts=(p.getStringList('team')??[]).map((x){try{return TeamMember.fromJson(jsonDecode(x));}catch(_){return null;}}).whereType<TeamMember>().toList();setState((){events=es;team=ts;});}Future<void> save()async{final p=await SharedPreferences.getInstance();await p.setStringList('events',events.map((e)=>jsonEncode(e.toJson())).toList());await p.setStringList('team',team.map((e)=>jsonEncode(e.toJson())).toList());}bool same(DateTime a,DateTime b)=>a.year==b.year&&a.month==b.month&&a.day==b.day;List<EventData> dayEvents(DateTime d)=>events.where((e)=>same(e.date,d)).toList();String mon(int m)=>const ['','January','February','March','April','May','June','July','August','September','October','November','December'][m];
@override Widget build(BuildContext c){final pages=[calendarPage(),eventsPage(),teamPage(),contactsPage(),morePage()];return Scaffold(body:SafeArea(child:pages[tab]),bottomNavigationBar:NavigationBar(selectedIndex:tab,onDestinationSelected:(i)=>setState(()=>tab=i),destinations:const[NavigationDestination(icon:Icon(Icons.calendar_month_outlined),selectedIcon:Icon(Icons.calendar_month),label:'Calendar'),NavigationDestination(icon:Icon(Icons.event_outlined),selectedIcon:Icon(Icons.event),label:'Events'),NavigationDestination(icon:Icon(Icons.groups_outlined),selectedIcon:Icon(Icons.groups),label:'Team'),NavigationDestination(icon:Icon(Icons.contacts_outlined),selectedIcon:Icon(Icons.contacts),label:'Contacts'),NavigationDestination(icon:Icon(Icons.more_horiz),label:'More')]));}
Widget top(String title,{List<Widget> actions=const[]})=>Padding(padding:const EdgeInsets.fromLTRB(10,8,8,4),child:Row(children:[IconButton(onPressed:(){},icon:const Icon(Icons.menu)),Expanded(child:Center(child:Text(title,style:const TextStyle(fontSize:20,fontWeight:FontWeight.w700)))),...actions]));
Widget calendarPage() {
  final first = DateTime(month.year, month.month, 1);
  final count = DateTime(month.year, month.month + 1, 0).day;
  final offset = first.weekday % 7;
  final cells = ((offset + count + 6) ~/ 7) * 7;

  return Column(
    children: [
      top(
        'Dashboard',
        actions: [
          IconButton(
            onPressed: () => openEvent(),
            icon: const CircleAvatar(
              child: Icon(Icons.add),
            ),
          ),
        ],
      ),

      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                month = DateTime(month.year, month.month - 1);
              });
            },
            icon: const Icon(Icons.chevron_left),
          ),

          Text(
            '${mon(month.month)} ${month.year}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),

          IconButton(
            onPressed: () {
              setState(() {
                month = DateTime(month.year, month.month + 1);
              });
            },
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),

      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            'SUN',
            'MON',
            'TUE',
            'WED',
            'THU',
            'FRI',
            'SAT',
          ].map(
            (x) => Expanded(
              child: Center(
                child: Text(
                  x,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ).toList(),
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
            if (i < offset || i >= offset + count) {
              return const SizedBox();
            }

            final d = DateTime(
              month.year,
              month.month,
              i - offset + 1,
            );

            final ev = dayEvents(d);
            final sel = same(d, selected);

            return GestureDetector(
              onTap: () {
                setState(() {
                  selected = d;
                });
              },
              child: Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: sel
                      ? const Color(0xFF6C3FF5)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${d.day}',
                      style: TextStyle(
                        color: sel ? Colors.white : null,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    if (ev.isNotEmpty)
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.only(top: 3),
                        decoration: BoxDecoration(
                          color: sel
                              ? Colors.white
                              : const Color(0xFF6C3FF5),
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
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          children: [
            Text(
              'Events on ${selected.day} ${mon(selected.month)} ${selected.year}',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            ...dayEvents(selected).map(eventCard),

            if (dayEvents(selected).isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No events booked on this date',
                  ),
                ),
              ),
          ],
        ),
      ),
    ],
  );
}
Widget eventCard(EventData e)=>Card(clipBehavior:Clip.antiAlias,child:InkWell(onTap:()=>openEvent(existing:e),child:Padding(padding:const EdgeInsets.all(14),child:Row(children:[Container(width:5,height:72,decoration:BoxDecoration(color:const Color(0xFF6C3FF5),borderRadius:BorderRadius.circular(10))),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:Text(e.name.isEmpty?e.client:e.name,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:15))),Text(e.time)]),const SizedBox(height:5),Text('📍 ${e.venue}'),Text('◉ ${e.type}')])),Text('${e.assignments.values.fold<int>(0,(s,x)=>s+x.length)} crew',style:const TextStyle(fontSize:11))]))));
Widget eventsPage(){final f=events.where((e)=>'${e.name} ${e.client} ${e.venue}'.toLowerCase().contains(search.toLowerCase())).toList()..sort((a,b)=>a.date.compareTo(b.date));return Column(children:[top('Events'),Padding(padding:const EdgeInsets.all(12),child:TextField(onChanged:(v)=>setState(()=>search=v),decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Search client or event',border:OutlineInputBorder()))),Expanded(child:ListView(padding:const EdgeInsets.symmetric(horizontal:12),children:f.map((e)=>Padding(padding:const EdgeInsets.only(bottom:8),child:eventCard(e))).toList()))]);}
Widget teamPage()=>Column(children:[top('Team Members',actions:[IconButton(onPressed:addTeamManually,icon:const Icon(Icons.add))]),Expanded(child:ListView.builder(padding:const EdgeInsets.symmetric(horizontal:12),itemCount:team.length,itemBuilder:(_,i)=>teamTile(team[i]))) ]);
Widget teamTile(TeamMember m)=>Card(child:ListTile(leading:CircleAvatar(child:Text(m.name.isEmpty?'?':m.name[0].toUpperCase())),title:Text(m.name,style:const TextStyle(fontWeight:FontWeight.w600)),subtitle:Text('${m.role} • ${m.phone}'),trailing:Row(mainAxisSize:MainAxisSize.min,children:[IconButton(icon:const Icon(Icons.chat_outlined),onPressed:()=>whatsapp(m.phone)),IconButton(icon:const Icon(Icons.call_outlined),onPressed:()=>call(m.phone))])));
Widget contactsPage()=>Column(children:[top('Phone Contacts'),const Padding(padding:EdgeInsets.all(16),child:Text('Import a saved phone contact directly into your PHF team.')),FilledButton.icon(onPressed:importContact,icon:const Icon(Icons.contacts),label:const Text('Import from Phone Contacts')),const SizedBox(height:12),Expanded(child:ListView(padding:const EdgeInsets.all(12),children:team.map(teamTile).toList()))]);
Widget morePage()=>ListView(children:[top('More'),SwitchListTile(value:widget.dark,onChanged:(_)=>widget.onDark(),secondary:const Icon(Icons.dark_mode_outlined),title:const Text('Dark mode')),ListTile(leading:const Icon(Icons.delete_sweep_outlined),title:const Text('Manage Events'),subtitle:const Text('Search, edit or delete booked events'),onTap:()=>setState(()=>tab=1))]);
Future<void> openEvent({EventData? existing})async{final r=await Navigator.push<EventData>(context,MaterialPageRoute(builder:(_)=>EventForm(event:existing,date:existing?.date??selected,team:team)));if(r==null)return;if(r.id.startsWith('__DELETE__')){events.removeWhere((e)=>e.id==r.id.substring(10));}else{final i=events.indexWhere((x)=>x.id==r.id);if(i<0)events.add(r);else events[i]=r;selected=r.date;month=DateTime(r.date.year,r.date.month);}setState((){});await save();}
Future<void> importContact()async{try{final ok=await FlutterContacts.requestPermission(readonly:true);if(!ok){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Contacts permission was not granted')));return;}final cs=await FlutterContacts.getContacts(withProperties:true);if(!mounted)return;final chosen=await showModalBottomSheet<Contact>(context:context,isScrollControlled:true,builder:(_)=>ContactPicker(contacts:cs));if(chosen==null)return;final ph=chosen.phones.isNotEmpty?chosen.phones.first.number:'';if(ph.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('This contact has no phone number')));return;}setState(()=>team.add(TeamMember(id:DateTime.now().microsecondsSinceEpoch.toString(),name:chosen.displayName,phone:ph)));await save();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not open contacts: $e')));}}
Future<void> addTeamManually()async{final n=TextEditingController(),p=TextEditingController();final ok=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(title:const Text('Add team member'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:n,decoration:const InputDecoration(labelText:'Name')),TextField(controller:p,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'Phone'))]),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Add'))]));if(ok==true&&n.text.trim().isNotEmpty){setState(()=>team.add(TeamMember(id:DateTime.now().microsecondsSinceEpoch.toString(),name:n.text.trim(),phone:p.text.trim())));await save();}n.dispose();p.dispose();}
Future<void> call(String phone)async{final d=phone.replaceAll(RegExp(r'[^0-9+]'),'');await launchUrl(Uri.parse('tel:$d'));}Future<void> whatsapp(String phone)async{var d=phone.replaceAll(RegExp(r'[^0-9]'),'');if(d.length==10)d='91$d';await launchUrl(Uri.parse('https://wa.me/$d'),mode:LaunchMode.externalApplication);}
}
class ContactPicker extends StatelessWidget{final List<Contact> contacts;const ContactPicker({super.key,required this.contacts});@override Widget build(BuildContext c)=>SizedBox(height:MediaQuery.sizeOf(c).height*.8,child:ListView.builder(itemCount:contacts.length,itemBuilder:(_,i){final x=contacts[i];return ListTile(leading:const CircleAvatar(child:Icon(Icons.person)),title:Text(x.displayName),subtitle:Text(x.phones.isEmpty?'No phone number':x.phones.first.number),onTap:()=>Navigator.pop(c,x));}));}
class EventForm extends StatefulWidget{final EventData? event;final DateTime date;final List<TeamMember> team;const EventForm({super.key,this.event,required this.date,required this.team});@override State<EventForm> createState()=>_EventFormState();}
class _EventFormState extends State<EventForm>{late DateTime date;late String type;final name=TextEditingController(),client=TextEditingController(),phone=TextEditingController(),venue=TextEditingController(),time=TextEditingController(),notes=TextEditingController();late Map<String,List<String>> assigned;
@override void initState(){super.initState();date=widget.event?.date??widget.date;type=widget.event?.type??'Wedding';assigned={for(final r in roles)r:List<String>.from(widget.event?.assignments[r]??const[])};if(widget.event!=null){name.text=widget.event!.name;client.text=widget.event!.client;phone.text=widget.event!.phone;venue.text=widget.event!.venue;time.text=widget.event!.time;notes.text=widget.event!.notes;}}
@override void dispose(){for(final c in[name,client,phone,venue,time,notes])c.dispose();super.dispose();}Future<void> pickDate()async{final d=await showDatePicker(context:context,initialDate:date,firstDate:DateTime(2020),lastDate:DateTime(2035));if(d!=null)setState(()=>date=d);}void saveEvent(){if(client.text.trim().isEmpty&&name.text.trim().isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Event or client name is required')));return;}Navigator.pop(context,EventData(id:widget.event?.id??DateTime.now().microsecondsSinceEpoch.toString(),name:name.text.trim(),client:client.text.trim(),phone:phone.text.trim(),venue:venue.text.trim(),time:time.text.trim(),notes:notes.text.trim(),type:type,date:date,assignments:assigned));}
@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:Text(widget.event==null?'Add New Event':'Event Details'),actions:[if(widget.event!=null)IconButton(icon:const Icon(Icons.delete_outline),onPressed:deleteEvent)]),body:ListView(padding:const EdgeInsets.all(16),children:[field(name,'Event Name'),field(client,'Client Name'),Row(children:[Expanded(child:DropdownButtonFormField<String>(value:type,decoration:const InputDecoration(labelText:'Event Type',border:OutlineInputBorder()),items:['Wedding','Reception','Engagement','Pre Wedding','Haldi','Sangeet','Other'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(x)=>setState(()=>type=x!))),const SizedBox(width:10),Expanded(child:ListTile(contentPadding:EdgeInsets.zero,title:const Text('Event Date'),subtitle:Text('${date.day}/${date.month}/${date.year}'),trailing:const Icon(Icons.calendar_month),onTap:pickDate))]),field(time,'Event Time'),field(venue,'Venue'),field(notes,'Note (Optional)',max:3),const SizedBox(height:12),const Text('ASSIGN TEAM',style:TextStyle(fontWeight:FontWeight.bold,letterSpacing:1)),...roles.map(roleCard),const SizedBox(height:20),FilledButton.icon(onPressed:saveEvent,icon:const Icon(Icons.check),label:Text(widget.event==null?'Save Event':'Save Changes'))]));
Widget field(TextEditingController c,String label,{int max=1})=>Padding(padding:const EdgeInsets.only(bottom:10),child:TextField(controller:c,maxLines:max,decoration:InputDecoration(labelText:label,border:const OutlineInputBorder())));IconData roleIcon(String r)=>{'Candid':Icons.camera_alt,'Cinematographer':Icons.movie_creation_outlined,'T. Photo':Icons.photo_camera,'T. Video':Icons.videocam,'Drone':Icons.flight,'Helper':Icons.handyman}[r]??Icons.person;
Widget roleCard(String role)=>Card(child:Padding(padding:const EdgeInsets.all(10),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Icon(roleIcon(role)),const SizedBox(width:8),Expanded(child:Text(role,style:const TextStyle(fontWeight:FontWeight.bold))),IconButton(onPressed:()=>pickMember(role),icon:const Icon(Icons.add_circle_outline))]),...assigned[role]!.asMap().entries.map((en){TeamMember? m;for(final x in widget.team){if(x.id==en.value){m=x;break;}}return ListTile(dense:true,contentPadding:EdgeInsets.zero,leading:const Icon(Icons.person_outline),title:Text(m?.name??'Member removed'),subtitle:Text(m?.phone??''),trailing:IconButton(icon:const Icon(Icons.remove_circle_outline),onPressed:()=>setState(()=>assigned[role]!.removeAt(en.key)));}),if(assigned[role]!.isEmpty)const Padding(padding:EdgeInsets.only(left:40,bottom:5),child:Text('No member assigned • tap + to add'))])));
Future<void> pickMember(String role)async{if(widget.team.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Add team members first')));return;}final selected=await showModalBottomSheet<List<TeamMember>>(context:context,isScrollControlled:true,builder:(_)=>MemberMultiPicker(team:widget.team,initial:assigned[role]!));if(selected!=null)setState(()=>assigned[role]=selected.map((x)=>x.id).toList());}
Future<void> deleteEvent()async{final yes=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(title:const Text('Delete event?'),content:Text('Delete ${name.text.isEmpty?client.text:name.text}?'),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Delete'))]));if(yes==true)Navigator.pop(context,EventData(id:'__DELETE__${widget.event!.id}',name:'',client:'',phone:'',venue:'',time:'',notes:'',type:'',date:date,assignments:{}));}}
class MemberMultiPicker extends StatefulWidget{final List<TeamMember> team;final List<String> initial;const MemberMultiPicker({super.key,required this.team,required this.initial});@override State<MemberMultiPicker> createState()=>_MemberMultiPickerState();}
class _MemberMultiPickerState extends State<MemberMultiPicker>{late Set<String> selected;@override void initState(){super.initState();selected=widget.initial.toSet();}@override Widget build(BuildContext c)=>SafeArea(child:Padding(padding:const EdgeInsets.all(16),child:Column(children:[const Text('Assign Team',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),const SizedBox(height:10),Expanded(child:ListView(children:widget.team.map((m)=>CheckboxListTile(value:selected.contains(m.id),onChanged:(v)=>setState(()=>v==true?selected.add(m.id):selected.remove(m.id)),secondary:const CircleAvatar(child:Icon(Icons.person)),title:Text(m.name),subtitle:Text(m.phone))).toList())),SizedBox(width:double.infinity,child:FilledButton(onPressed:()=>Navigator.pop(c,widget.team.where((m)=>selected.contains(m.id)).toList()),child:const Text('Done')))])));
