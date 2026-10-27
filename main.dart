import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

const columns = [
  'RecordType', 'Name', 'Date', 'Pending', 'Settled', 'Label',
  'SessionsPerWeek', 'Level', 'Term', 'OriginalTerm',
  'PendingSessions', 'Note', 'Labels', 'ClassDays',
];

void main() => runApp(const AttendanceApp());

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});
  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF52796F);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'حضور و غیاب',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: green),
        scaffoldBackgroundColor: const Color(0xFFF4F6F2),
        appBarTheme: const AppBarTheme(backgroundColor: green, foregroundColor: Colors.white),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, String>> records = [];
  bool loading = true;
  String search = '';
  String? activeLabel;
  String language = 'fa';
  String get tAdd => language == 'fa' ? 'افزودن دانش‌آموز' : 'Add student';
  String get tAttendance => language == 'fa' ? 'حضور و غیاب' : 'Attendance';
  String get tReports => language == 'fa' ? 'گزارش‌ها' : 'Reports';
  String get tCalendar => language == 'fa' ? 'تقویم کلاس‌ها' : 'Class calendar';
  String get tSettings => language == 'fa' ? 'تنظیمات' : 'Settings';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> _dataFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/combined_data.csv');
  }

  Future<void> _load() async {
    try {
      final file = await _dataFile();
      String raw;
      if (await file.exists()) {
        raw = await file.readAsString();
      } else {
        raw = await rootBundle.loadString('assets/combined_data.csv');
        await file.writeAsString(raw);
      }
      // Some CSV editors export a UTF-8 BOM, which would corrupt the first header.
      raw = raw.replaceFirst('\uFEFF', '');
      final parsed = const CsvToListConverter(eol: '\n').convert(raw.trimRight());
      if (parsed.isNotEmpty) {
        final header = parsed.first.map((e) => e.toString().replaceFirst('\uFEFF', '').trim()).toList();
        records = parsed.skip(1).where((r) => r.isNotEmpty).map((row) {
          final map = <String, String>{};
          for (var i = 0; i < header.length; i++) {
            map[header[i]] = i < row.length ? row[i].toString() : '';
          }
          for (final c in columns) { map.putIfAbsent(c, () => ''); }
          return map;
        }).toList();
      }
    } catch (e) {
      _message('خطا در خواندن فایل CSV: $e');
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _save() async {
    final ordered = [...records]..sort((a, b) {
      const order = {'student': 0, 'attendance': 1, 'label': 2};
      return (order[a['RecordType']] ?? 99).compareTo(order[b['RecordType']] ?? 99);
    });
    final rows = <List<dynamic>>[columns];
    for (final rec in ordered) {
      rows.add(columns.map((c) => rec[c] ?? '').toList());
    }
    final content = const ListToCsvConverter().convert(rows);
    final file = await _dataFile();
    await file.writeAsString('$content\n');
    if (mounted) setState(() {});
  }

  List<Map<String, String>> get students => records.where((r) => r['RecordType'] == 'student').toList();
  List<Map<String, String>> get attendance => records.where((r) => r['RecordType'] == 'attendance').toList();
  List<Map<String, String>> get labels => records.where((r) => r['RecordType'] == 'label').toList();
  List<String> _split(String? value) => (value ?? '').trim().isEmpty ? [] : value!.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  int _number(String? v, [int fallback = 0]) => int.tryParse((v ?? '').replaceAll('.0', '')) ?? double.tryParse(v ?? '')?.toInt() ?? fallback;
  Map<String, String>? _student(String name) {
    for (final s in students) { if (s['Name'] == name) return s; }
    return null;
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _editStudent([Map<String, String>? existing]) async {
    final name = TextEditingController(text: existing?['Name'] ?? '');
    final sessions = TextEditingController(text: existing?['SessionsPerWeek']?.replaceAll('.0', '') ?? '2');
    final term = TextEditingController(text: existing?['Term']?.replaceAll('.0', '') ?? '10');
    final note = TextEditingController(text: existing?['Note'] ?? '');
    final labelText = TextEditingController(text: _split(existing?['Labels']).join(', '));
    String level = existing?['Level']?.isNotEmpty == true ? existing!['Level']! : 'Beginner';
    final dayOptions = ['Saturday','Sunday','Monday','Tuesday','Wednesday','Thursday','Friday'];
    var selectedDays = _split(existing?['ClassDays']);
    if (selectedDays.isEmpty) selectedDays = ['Sunday'];
    final result = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModal) => AlertDialog(
        title: Text(existing == null ? tAdd : (language == 'fa' ? 'ویرایش دانش‌آموز' : 'Edit student')),
        content: SizedBox(width: 440, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: InputDecoration(labelText: language == 'fa' ? 'نام' : 'Name')),
          const SizedBox(height: 10),
          TextField(controller: sessions, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: language == 'fa' ? 'جلسه در هفته' : 'Sessions per week')),
          const SizedBox(height: 10),
          TextField(controller: term, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: language == 'fa' ? 'جلسات ترم / باقی‌مانده' : 'Term sessions remaining')),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(value: ['Beginner','Intermediate','Advanced'].contains(level) ? level : 'Beginner',
            decoration: InputDecoration(labelText: language == 'fa' ? 'سطح' : 'Level'),
            items: const ['Beginner','Intermediate','Advanced'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setModal(() => level = v ?? 'Beginner')),
          const SizedBox(height: 10),
          TextField(controller: note, decoration: InputDecoration(labelText: language == 'fa' ? 'یادداشت' : 'Note')),
          const SizedBox(height: 10),
          TextField(controller: labelText, decoration: InputDecoration(labelText: language == 'fa' ? 'برچسب‌ها (با کاما جدا کنید)' : 'Labels (comma separated)')),
          const SizedBox(height: 12),
          Align(alignment: Alignment.centerRight, child: Text(language == 'fa' ? 'روزهای کلاس' : 'Class days')),
          Wrap(spacing: 4, children: dayOptions.map((d) => FilterChip(
            label: Text(language == 'fa' ? _dayFa(d) : d),
            selected: selectedDays.contains(d),
            onSelected: (v) => setModal(() { v ? selectedDays.add(d) : selectedDays.remove(d); }),
          )).toList()),
        ]))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(language == 'fa' ? 'انصراف' : 'Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(language == 'fa' ? 'ذخیره' : 'Save')),
        ],
      ),
    ));
    if (result != true) return;
    final n = name.text.trim();
    final perWeek = int.tryParse(sessions.text.trim());
    final termCount = int.tryParse(term.text.trim());
    if (n.isEmpty || perWeek == null || perWeek < 1 || perWeek > 7 || termCount == null || termCount < 0 || selectedDays.isEmpty) {
      _message(language == 'fa' ? 'نام، تعداد جلسات، ترم و حداقل یک روز کلاس را درست وارد کنید.' : 'Enter a name, valid session counts, and at least one class day.');
      return;
    }
    final duplicate = _student(n);
    if (duplicate != null && !identical(duplicate, existing)) {
      _message(language == 'fa' ? 'این دانش‌آموز وجود دارد.' : 'Student already exists.');
      return;
    }
    final data = <String, String>{
      'RecordType': 'student', 'Name': n, 'SessionsPerWeek': '$perWeek',
      'Level': level, 'Term': '$termCount',
      'OriginalTerm': existing?['OriginalTerm']?.isNotEmpty == true ? existing!['OriginalTerm']! : '$termCount',
      'PendingSessions': existing?['PendingSessions'] ?? '0',
      'Note': note.text.trim(), 'Labels': labelText.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).join(','),
      'ClassDays': selectedDays.join(','),
      'Date': '', 'Pending': '', 'Settled': '', 'Label': '',
    };
    setState(() {
      if (existing != null) {
        final oldName = existing['Name'] ?? '';
        final idx = records.indexOf(existing);
        records[idx] = data;
        if (oldName != n) {
          for (final row in records) {
            if (row['RecordType'] == 'attendance' && row['Name'] == oldName) {
              row['Name'] = n;
            }
          }
        }
      } else {
        records.add(data);
      }
      // Keep label definitions in the same combined CSV.
      for (final tag in _split(data['Labels'])) {
        if (!labels.any((r) => r['Label'] == tag)) {
          records.add({...{for (final c in columns) c: ''}, 'RecordType':'label', 'Label':tag});
        }
      }
    });
    await _save();
    _message(language == 'fa' ? 'اطلاعات ذخیره شد.' : 'Student saved.');
  }

  String _dayFa(String day) => const {
    'Saturday':'شنبه','Sunday':'یکشنبه','Monday':'دوشنبه','Tuesday':'سه‌شنبه',
    'Wednesday':'چهارشنبه','Thursday':'پنجشنبه','Friday':'جمعه'
  }[day] ?? day;

  Future<void> _deleteStudent(Map<String, String> student) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(language == 'fa' ? 'حذف دانش‌آموز' : 'Delete student'),
      content: Text(language == 'fa' ? 'دانش‌آموز «${student['Name']}» حذف شود؟ سوابق حضور او نیز حذف خواهد شد.' : 'Delete ${student['Name']} and their attendance records?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(language == 'fa' ? 'انصراف' : 'Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(language == 'fa' ? 'حذف' : 'Delete')),
      ],
    ));
    if (ok != true) return;
    setState(() => records.removeWhere((r) => (r['RecordType'] == 'student' && r['Name'] == student['Name']) || (r['RecordType'] == 'attendance' && r['Name'] == student['Name'])));
    await _save();
  }

  Future<void> _markAttendance(Map<String, String> student) async {
    DateTime date = DateTime.now();
    bool pending = false;
    final result = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModal) => AlertDialog(
        title: Text(language == 'fa' ? 'ثبت حضور: ${student['Name']}' : 'Attendance: ${student['Name']}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.calendar_month), title: Text('${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}'),
            subtitle: Text(language == 'fa' ? 'برای تغییر تاریخ انتخاب کنید' : 'Tap to choose date'),
            onTap: () async { final d = await showDatePicker(context: ctx, initialDate: date, firstDate: DateTime(2000), lastDate: DateTime(2100)); if (d != null) setModal(() => date = d); }),
          SwitchListTile(title: Text(language == 'fa' ? 'جلسه در انتظار تسویه' : 'Pending payment'), value: pending, onChanged: (v) => setModal(() => pending = v)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(language == 'fa' ? 'انصراف' : 'Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(language == 'fa' ? 'ثبت' : 'Register')),
        ],
      ),
    ));
    if (result != true) return;
    final ds = '${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}';
    records.add({...{for (final c in columns) c: ''}, 'RecordType':'attendance', 'Name':student['Name'] ?? '', 'Date':ds, 'Pending':'$pending', 'Settled':'False'});
    final remaining = _number(student['Term']);
    student['Term'] = '${remaining > 0 ? remaining - 1 : 0}';
    if (pending) student['PendingSessions'] = '${_number(student['PendingSessions']) + 1}';
    await _save();
    _message(language == 'fa' ? 'حضور ثبت شد.' : 'Attendance registered.');
  }

  Future<void> _renew(Map<String, String> student) async {
    final original = _number(student['OriginalTerm'], _number(student['Term']));
    student['Term'] = '$original';
    student['PendingSessions'] = '0';
    await _save();
    _message(language == 'fa' ? 'ترم تمدید شد.' : 'Term renewed.');
  }

  void _openReports() {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (ctx) => Directionality(
      textDirection: language == 'fa' ? TextDirection.rtl : TextDirection.ltr,
      child: SizedBox(height: MediaQuery.of(ctx).size.height * .75, child: Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: Text(tReports, style: Theme.of(ctx).textTheme.titleLarge)),
        Expanded(child: ListView(children: students.map((s) {
          final term = _number(s['Term']);
          return ListTile(leading: CircleAvatar(child: Text('$term')), title: Text(s['Name'] ?? ''),
            subtitle: Text('${language == 'fa' ? 'جلسه باقی‌مانده' : 'Sessions left'}: $term • ${s['Level'] ?? ''}'),
            trailing: term <= 0 ? TextButton(onPressed: () { Navigator.pop(ctx); _renew(s); }, child: Text(language == 'fa' ? 'تمدید' : 'Renew')) : null);
        }).toList())),
      ])),
    ));
  }

  void _openCalendar() {
    final dayNames = ['Saturday','Sunday','Monday','Tuesday','Wednesday','Thursday','Friday'];
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (ctx) => Directionality(
      textDirection: language == 'fa' ? TextDirection.rtl : TextDirection.ltr,
      child: SizedBox(height: MediaQuery.of(ctx).size.height * .8, child: Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: Text(tCalendar, style: Theme.of(ctx).textTheme.titleLarge)),
        Expanded(child: ListView(children: dayNames.map((day) {
          final matched = students.where((s) => _split(s['ClassDays']).contains(day)).toList();
          return ExpansionTile(title: Text(language == 'fa' ? _dayFa(day) : day), subtitle: Text('${matched.length} ${language == 'fa' ? 'دانش‌آموز' : 'students'}'),
            children: matched.map((s) => ListTile(title: Text(s['Name'] ?? ''), subtitle: Text('${s['SessionsPerWeek'] ?? ''} / week • ${s['Level'] ?? ''}'))).toList());
        }).toList())),
      ])),
    ));
  }

  void _openSettings() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text(tSettings),
      content: DropdownButtonFormField<String>(value: language, decoration: InputDecoration(labelText: language == 'fa' ? 'زبان' : 'Language'),
        items: const [DropdownMenuItem(value:'fa', child:Text('فارسی')), DropdownMenuItem(value:'en', child:Text('English'))],
        onChanged: (v) { if (v != null) setState(() => language = v); Navigator.pop(ctx); }),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(language == 'fa' ? 'بستن' : 'Close'))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final shown = students.where((s) {
      final matchesSearch = (s['Name'] ?? '').toLowerCase().contains(search.toLowerCase());
      final matchesLabel = activeLabel == null || _split(s['Labels']).contains(activeLabel);
      return matchesSearch && matchesLabel;
    }).toList();
    final today = DateTime.now();
    final todayDay = const ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'][today.weekday - 1];
    final todayClasses = students.where((s) => _split(s['ClassDays']).contains(todayDay)).length;
    return Directionality(
      textDirection: language == 'fa' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(title: Text(language == 'fa' ? 'حضور و غیاب' : 'Attendance'), actions: [
          IconButton(tooltip: tReports, onPressed: _openReports, icon: const Icon(Icons.assessment_outlined)),
          IconButton(tooltip: tCalendar, onPressed: _openCalendar, icon: const Icon(Icons.calendar_month)),
          IconButton(tooltip: tSettings, onPressed: _openSettings, icon: const Icon(Icons.settings_outlined)),
        ]),
        floatingActionButton: FloatingActionButton.extended(onPressed: () => _editStudent(), icon: const Icon(Icons.person_add), label: Text(tAdd)),
        body: loading ? const Center(child: CircularProgressIndicator()) : Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(12,12,12,6), child: TextField(
            onChanged: (v) => setState(() => search = v),
            decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: language == 'fa' ? 'جستجوی دانش‌آموز...' : 'Search students...',),
          )),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), child: Row(children: [
            Expanded(child: _statCard(language == 'fa' ? 'کل دانش‌آموزان' : 'Students', '${students.length}', Icons.people)),
            const SizedBox(width: 8),
            Expanded(child: _statCard(language == 'fa' ? 'کلاس امروز' : 'Classes today', '$todayClasses', Icons.today)),
            const SizedBox(width: 8),
            Expanded(child: _statCard(language == 'fa' ? 'ترم تمام‌شده' : 'Term ended', '${students.where((s) => _number(s['Term']) <= 0).length}', Icons.hourglass_empty)),
          ])),
          SizedBox(height: 48, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 8), children: [
            Padding(padding: const EdgeInsets.all(4), child: ChoiceChip(label: Text(language == 'fa' ? 'همه' : 'All'), selected: activeLabel == null, onSelected: (_) => setState(() => activeLabel = null))),
            ...labels.map((r) => Padding(padding: const EdgeInsets.all(4), child: ChoiceChip(label: Text(r['Label'] ?? ''), selected: activeLabel == r['Label'], onSelected: (_) => setState(() => activeLabel = activeLabel == r['Label'] ? null : r['Label'])))),
          ])),
          Expanded(child: shown.isEmpty ? Center(child: Text(language == 'fa' ? 'دانش‌آموزی پیدا نشد' : 'No students found')) : ListView.builder(
            padding: const EdgeInsets.fromLTRB(10, 2, 10, 90),
            itemCount: shown.length,
            itemBuilder: (ctx, i) {
              final s = shown[i];
              final name = s['Name'] ?? '';
              final term = _number(s['Term']);
              final tags = _split(s['Labels']);
              return Card(margin: const EdgeInsets.symmetric(vertical: 5), child: ExpansionTile(
                leading: CircleAvatar(child: Text(name.isNotEmpty ? name.characters.first : '?')),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${s['Level'] ?? ''} • ${language == 'fa' ? 'باقی‌مانده' : 'Remaining'}: $term'),
                children: [
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Align(alignment: Alignment.centerRight, child: Wrap(spacing: 6, children: tags.map((tag) => Chip(label: Text(tag))).toList()))),
                  ListTile(leading: const Icon(Icons.event_available), title: Text(language == 'fa' ? 'روزهای کلاس' : 'Class days'), subtitle: Text(_split(s['ClassDays']).map((d) => language == 'fa' ? _dayFa(d) : d).join('، '))),
                  if ((s['Note'] ?? '').isNotEmpty) ListTile(leading: const Icon(Icons.notes), title: Text(s['Note']!)),
                  Wrap(alignment: WrapAlignment.center, children: [
                    TextButton.icon(onPressed: () => _markAttendance(s), icon: const Icon(Icons.fact_check), label: Text(tAttendance)),
                    TextButton.icon(onPressed: () => _editStudent(s), icon: const Icon(Icons.edit), label: Text(language == 'fa' ? 'ویرایش' : 'Edit')),
                    TextButton.icon(onPressed: () => _deleteStudent(s), icon: const Icon(Icons.delete_outline), label: Text(language == 'fa' ? 'حذف' : 'Delete')),
                    if (term <= 0) TextButton.icon(onPressed: () => _renew(s), icon: const Icon(Icons.autorenew), label: Text(language == 'fa' ? 'تمدید ترم' : 'Renew')),
                  ]),
                ],
              ));
            },
          )),
        ]),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon) => Card(
    child: Padding(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6), child: Column(children: [
      Icon(icon, size: 20, color: const Color(0xFF52796F)),
      const SizedBox(height: 3),
      Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
    ])),
  );
}
