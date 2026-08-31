import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CrewFlowApp());
}

const eventTypes = <String>[
  'Wedding',
  'Reception',
  'Ganesh Pooja',
  'Haldi',
  'Sangeet',
  'Engagement',
  'Pre Wedding',
  'Baby Shower',
  'House Warming',
  'Corporate Event',
  'Other',
];

const teamRoles = <String>[
  'Photographer',
  'Videographer',
  'Candid',
  'Cinematographer',
  'Drone',
  'Helper',
];

class CrewFlowApp extends StatelessWidget {
  const CrewFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CrewFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1F2937),
        scaffoldBackgroundColor: const Color(0xFFF7F7F8),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool obscure = true;

  void login() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                children: [
                  const Icon(Icons.movie_creation_outlined, size: 58),
                  const SizedBox(height: 18),
                  const Text(
                    'CrewFlow',
                    style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  const Text('Wedding & Event Team Management'),
                  const SizedBox(height: 38),
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: password,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => obscure = !obscure),
                        icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: login,
                      child: const Text('LOGIN'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const TeamAssignPage(),
      const QuotationPage(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(index == 0 ? 'Team Assign' : 'Quotation'),
        centerTitle: false,
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              const DrawerHeader(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.movie_creation_outlined, size: 42),
                      SizedBox(height: 8),
                      Text('CrewFlow', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.groups_outlined),
                title: const Text('Team Assign'),
                selected: index == 0,
                onTap: () {
                  setState(() => index = 0);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.request_quote_outlined),
                title: const Text('Quotation'),
                selected: index == 1,
                onTap: () {
                  setState(() => index = 1);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
      body: pages[index],
    );
  }
}

class TeamAssignPage extends StatefulWidget {
  const TeamAssignPage({super.key});
  @override
  State<TeamAssignPage> createState() => _TeamAssignPageState();
}

class _TeamAssignPageState extends State<TeamAssignPage> {
  final client = TextEditingController();
  final phone = TextEditingController();
  DateTime date = DateTime.now();
  String event = eventTypes.first;
  final Map<String, int> team = {for (final r in teamRoles) r: 0};

  @override
  void dispose() {
    client.dispose();
    phone.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: date,
    );
    if (picked != null) setState(() => date = picked);
  }

  void addRole() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: teamRoles.map((role) {
            return ListTile(
              title: Text(role),
              trailing: IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () {
                  setState(() => team[role] = (team[role] ?? 0) + 1);
                  Navigator.pop(ctx);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
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
            labelText: 'Contact Number',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: event,
          decoration: const InputDecoration(
            labelText: 'Event Type',
            prefixIcon: Icon(Icons.event_outlined),
          ),
          items: eventTypes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => event = v ?? event),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: pickDate,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Date',
              prefixIcon: Icon(Icons.calendar_today_outlined),
            ),
            child: Text('${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Expanded(
              child: Text('Coverage Team', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            OutlinedButton.icon(
              onPressed: addRole,
              icon: const Icon(Icons.add),
              label: const Text('Add Team'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...team.entries.where((e) => e.value > 0).map(
          (e) => Card(
            child: ListTile(
              title: Text(e.key),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => setState(() => team[e.key] = (e.value - 1).clamp(0, 99)),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: () => setState(() => team[e.key] = e.value + 1),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (team.values.every((v) => v == 0))
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(child: Text('No team assigned yet')),
          ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Event saved successfully')),
            );
          },
          icon: const Icon(Icons.save_outlined),
          label: const Text('SAVE EVENT'),
        ),
      ],
    );
  }
}

class QuotationPage extends StatefulWidget {
  const QuotationPage({super.key});
  @override
  State<QuotationPage> createState() => _QuotationPageState();
}

class _QuotationPageState extends State<QuotationPage> {
  final client = TextEditingController();
  final phone = TextEditingController();
  final location = TextEditingController();
  final terms = TextEditingController();
  String event = eventTypes.first;
  DateTime date = DateTime.now();

  final List<_Coverage> coverage = [];
  final List<_Charge> charges = [];
  final List<_Deliverable> deliverables = [];

  @override
  void initState() {
    super.initState();
    _loadTerms();
  }

  Future<void> _loadTerms() async {
    final prefs = await SharedPreferences.getInstance();
    terms.text = prefs.getString('terms_conditions') ?? '';
    if (mounted) setState(() {});
  }

  Future<void> saveTerms() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('terms_conditions', terms.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terms & Conditions saved for future quotations')),
      );
    }
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: date,
    );
    if (picked != null) setState(() => date = picked);
  }

  Future<void> addCoverage() async {
    final result = await showDialog<_Coverage>(
      context: context,
      builder: (_) => const _CoverageDialog(),
    );
    if (result != null) setState(() => coverage.add(result));
  }

  Future<void> addCharge() async {
    final result = await showDialog<_Charge>(
      context: context,
      builder: (_) => const _ChargeDialog(),
    );
    if (result != null) setState(() => charges.add(result));
  }

  Future<void> addDeliverable() async {
    final result = await showDialog<_Deliverable>(
      context: context,
      builder: (_) => const _DeliverableDialog(),
    );
    if (result != null) setState(() => deliverables.add(result));
  }

  double get total => charges.fold(0, (sum, c) => sum + c.amount);

  String money(double n) => '₹${n.toStringAsFixed(0)} /-';

  Future<void> createPdf() async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (_) => [
          pw.Text('PARAG HARIYANI FILMS', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('QUOTATION'),
          pw.SizedBox(height: 18),
          pw.Text('Client: ${client.text}'),
          pw.Text('Contact: ${phone.text}'),
          pw.Text('Location: ${location.text}'),
          pw.Text('Event: $event'),
          pw.Text('Date: ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'),
          pw.SizedBox(height: 18),
          pw.Text('EVENT COVERAGE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          if (coverage.isNotEmpty)
            pw.Table.fromTextArray(
              headers: const ['Date', 'Event', 'Coverage Team'],
              data: coverage.map((c) => [c.date, c.event, c.team]).toList(),
            ),
          pw.SizedBox(height: 16),
          pw.Text('DELIVERABLES', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          if (deliverables.isNotEmpty)
            pw.Table.fromTextArray(
              headers: const ['Deliverable', 'Quantity'],
              data: deliverables.map((d) => [d.name, '${d.quantity}']).toList(),
            ),
          pw.SizedBox(height: 16),
          pw.Text('INVESTMENT', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          if (charges.isNotEmpty)
            pw.Table.fromTextArray(
              headers: const ['Description', 'Amount'],
              data: charges.map((c) => [c.description, money(c.amount)]).toList(),
            ),
          pw.Container(
            alignment: pw.Alignment.centerRight,
            padding: const pw.EdgeInsets.only(top: 8),
            child: pw.Text('TOTAL PACKAGE: ${money(total)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 18),
          pw.Text('TERMS & CONDITIONS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(terms.text.isEmpty ? ' ' : terms.text),
          pw.SizedBox(height: 28),
          pw.Center(child: pw.Text('Thank you for choosing Parag Hariyani Films.')),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  Widget sectionHeader(String title, VoidCallback onAdd) {
    return Row(
      children: [
        Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        TextButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Add')),
      ],
    );
  }

  @override
  void dispose() {
    client.dispose();
    phone.dispose();
    location.dispose();
    terms.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Create Quotation', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        TextField(controller: client, decoration: const InputDecoration(labelText: 'Client Name')),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Contact'))),
          const SizedBox(width: 10),
          Expanded(child: TextField(controller: location, decoration: const InputDecoration(labelText: 'Location'))),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: event,
              decoration: const InputDecoration(labelText: 'Event Type'),
              items: eventTypes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => event = v ?? event),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Date'),
                child: Text('${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 18),
        sectionHeader('Event Coverage', addCoverage),
        ...coverage.asMap().entries.map((entry) => Card(
          child: ListTile(
            title: Text(entry.value.event),
            subtitle: Text('${entry.value.date} • ${entry.value.team}'),
            trailing: IconButton(
              onPressed: () => setState(() => coverage.removeAt(entry.key)),
              icon: const Icon(Icons.delete_outline),
            ),
          ),
        )),
        sectionHeader('Deliverables', addDeliverable),
        ...deliverables.asMap().entries.map((entry) => Card(
          child: ListTile(
            title: Text(entry.value.name),
            subtitle: Text('Quantity: ${entry.value.quantity}'),
            trailing: IconButton(
              onPressed: () => setState(() => deliverables.removeAt(entry.key)),
              icon: const Icon(Icons.delete_outline),
            ),
          ),
        )),
        sectionHeader('Investment', addCharge),
        ...charges.asMap().entries.map((entry) => Card(
          child: ListTile(
            title: Text(entry.value.description),
            trailing: Text(money(entry.value.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        )),
        Card(
          child: ListTile(
            title: const Text('Total Package', style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: Text(money(total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ),
        ),
        const SizedBox(height: 14),
        const Text('Terms & Conditions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: terms,
          minLines: 5,
          maxLines: 10,
          decoration: const InputDecoration(
            hintText: 'Enter Terms & Conditions. Save once and reuse in future quotations.',
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: saveTerms,
          icon: const Icon(Icons.bookmark_outline),
          label: const Text('SAVE T&C FOR FUTURE'),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: createPdf,
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('PREVIEW / CREATE PDF'),
        ),
      ],
    );
  }
}

class _Coverage {
  final String date;
  final String event;
  final String team;
  const _Coverage(this.date, this.event, this.team);
}

class _Charge {
  final String description;
  final double amount;
  const _Charge(this.description, this.amount);
}

class _Deliverable {
  final String name;
  final int quantity;
  const _Deliverable(this.name, this.quantity);
}

class _CoverageDialog extends StatefulWidget {
  const _CoverageDialog();
  @override
  State<_CoverageDialog> createState() => _CoverageDialogState();
}

class _CoverageDialogState extends State<_CoverageDialog> {
  String event = eventTypes.first;
  DateTime date = DateTime.now();
  final Map<String, int> roles = {for (final r in teamRoles) r: 0};

  String get teamText => roles.entries.where((e) => e.value > 0).map((e) => '${e.key} × ${e.value}').join(' + ');

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Event Coverage'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: event,
              decoration: const InputDecoration(labelText: 'Event'),
              items: eventTypes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => event = v ?? event),
            ),
            const SizedBox(height: 10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text('${date.day}/${date.month}/${date.year}'),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: () async {
                final d = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2100), initialDate: date);
                if (d != null) setState(() => date = d);
              },
            ),
            ...roles.entries.map((e) => Row(
              children: [
                Expanded(child: Text(e.key)),
                IconButton(onPressed: () => setState(() => roles[e.key] = (e.value - 1).clamp(0, 99)), icon: const Icon(Icons.remove_circle_outline)),
                Text('${e.value}'),
                IconButton(onPressed: () => setState(() => roles[e.key] = e.value + 1), icon: const Icon(Icons.add_circle_outline)),
              ],
            )),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
        FilledButton(
          onPressed: teamText.isEmpty ? null : () => Navigator.pop(context, _Coverage('${date.day}/${date.month}/${date.year}', event, teamText)),
          child: const Text('ADD'),
        ),
      ],
    );
  }
}

class _ChargeDialog extends StatefulWidget {
  const _ChargeDialog();
  @override
  State<_ChargeDialog> createState() => _ChargeDialogState();
}

class _ChargeDialogState extends State<_ChargeDialog> {
  final description = TextEditingController();
  final amount = TextEditingController();

  @override
  void dispose() {
    description.dispose();
    amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Investment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: description, decoration: const InputDecoration(labelText: 'Description')),
          const SizedBox(height: 10),
          TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
        FilledButton(
          onPressed: () {
            final value = double.tryParse(amount.text.trim());
            if (description.text.trim().isNotEmpty && value != null) {
              Navigator.pop(context, _Charge(description.text.trim(), value));
            }
          },
          child: const Text('ADD'),
        ),
      ],
    );
  }
}

class _DeliverableDialog extends StatefulWidget {
  const _DeliverableDialog();
  @override
  State<_DeliverableDialog> createState() => _DeliverableDialogState();
}

class _DeliverableDialogState extends State<_DeliverableDialog> {
  final name = TextEditingController();
  final quantity = TextEditingController(text: '1');

  @override
  void dispose() {
    name.dispose();
    quantity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Deliverable'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Deliverable')),
          const SizedBox(height: 10),
          TextField(controller: quantity, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
        FilledButton(
          onPressed: () {
            final q = int.tryParse(quantity.text.trim());
            if (name.text.trim().isNotEmpty && q != null && q > 0) {
              Navigator.pop(context, _Deliverable(name.text.trim(), q));
            }
          },
          child: const Text('ADD'),
        ),
      ],
    );
  }
}
