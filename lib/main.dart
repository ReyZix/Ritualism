import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';


void main() {
  runApp(HabitTrackerApp());
}

class HabitTrackerApp extends StatefulWidget {
  @override
  _HabitTrackerAppState createState() => _HabitTrackerAppState();
}

class _HabitTrackerAppState extends State<HabitTrackerApp> {
  bool _isDarkMode = true;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => HabitProvider()),
        ChangeNotifierProvider(create: (context) => NoteProvider()),
      ],
      child: MaterialApp(
        title: 'Habit Tracker',
        theme: _isDarkMode ? _darkTheme : _lightTheme,
        home: MyScaffold(toggleTheme: _toggleTheme, isDarkMode: _isDarkMode),
      ),
    );
  }

  final ThemeData _darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blueGrey,
    scaffoldBackgroundColor: Color(0xFF121212),
    appBarTheme: AppBarTheme(
      color: Color(0xFF1E1E1E),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF1E88E5),
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white70),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white70),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
      ),
      labelStyle: TextStyle(color: Colors.white70),
    ),
  );

  final ThemeData _lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(
      color: Colors.blue,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.blue,
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.black),
      bodyMedium: TextStyle(color: Colors.black87),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black87),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black87),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black),
      ),
      labelStyle: TextStyle(color: Colors.black87),
    ),
  );
}

class MyScaffold extends StatefulWidget {
  final Function toggleTheme;
  final bool isDarkMode;

  MyScaffold({required this.toggleTheme, required this.isDarkMode});

  @override
  _MyScaffoldState createState() => _MyScaffoldState();
}

class _MyScaffoldState extends State<MyScaffold> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  static final List<Widget> _pages = <Widget>[
    MyHomePage(),
    HeatMapPage(),
    MyNotesPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Habit Tracker'),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.wb_sunny : Icons.nights_stay),
            onPressed: () {
              widget.toggleTheme();
            },
          ),
        ],
      ),
      body: Row(
        children: <Widget>[
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            labelType: NavigationRailLabelType.all,
            backgroundColor: widget.isDarkMode ? Color(0xFF1E1E1E) : Colors.blue,
            selectedLabelTextStyle: TextStyle(color: Colors.white),
            unselectedLabelTextStyle: TextStyle(color: Colors.white70),
            destinations: [
              NavigationRailDestination(
                icon: Icon(Icons.home, color: Colors.white70),
                selectedIcon: Icon(Icons.home_filled, color: Colors.white),
                label: Text('Home'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.map, color: Colors.white70),
                selectedIcon: Icon(Icons.map, color: Colors.white),
                label: Text('Heat Map'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.book, color: Colors.white70),
                selectedIcon: Icon(Icons.book, color: Colors.white),
                label: Text('Notes'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1, color: Colors.white70),
          Expanded(
            child: _pages[_selectedIndex],
          ),
        ],
      ),
    );
  }
}

class Habit {
  String name;
  int timesPerDay;
  int completionsToday;
  Map<DateTime, int> completionMap;

  Habit(this.name, {this.timesPerDay = 1, this.completionsToday = 0})
      : completionMap = {};

  bool get isCompleted => completionsToday >= timesPerDay;

  void completeHabit() {
    completionsToday = completionsToday >= timesPerDay ? 0 : completionsToday + 1;
  }

  void uncompleteHabit() {
    if (completionsToday > 0) {
      completionsToday--;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'timesPerDay': timesPerDay,
      'completionsToday': completionsToday,
      'completionMap': completionMap.map((date, value) => MapEntry(date.toIso8601String(), value)),
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    Habit habit = Habit(
      json['name'],
      timesPerDay: json['timesPerDay'],
      completionsToday: json['completionsToday'],
    );
    habit.completionMap = (json['completionMap'] as Map<String, dynamic>?)
            ?.map((key, value) => MapEntry(DateTime.parse(key), value)) ??
        {};
    return habit;
  }

  void saveCompletionForToday() {
    DateTime today = DateTime.now();
    completionMap[DateTime(today.year, today.month, today.day)] =
        ((completionsToday / timesPerDay) * 10).ceil();
  }
}

class HabitProvider with ChangeNotifier {
  List<Habit> _habits = [];
  DateTime _lastResetDate = DateTime.now();

  HabitProvider() {
    loadHabits();
    resetHabitsIfNeeded();
  }

  List<Habit> get habits => _habits;

  void addHabit(Habit habit) {
    _habits.add(habit);
    saveHabits();
    notifyListeners();
  }

  void removeHabit(int index) {
    _habits.removeAt(index);
    saveHabits();
    notifyListeners();
  }

  void toggleHabitCompletion(int index) {
    Habit habit = _habits[index];
    habit.completeHabit();
    habit.saveCompletionForToday();
    saveHabits();
    notifyListeners();
  }

  void resetHabitsIfNeeded() {
    DateTime today = DateTime.now();
    if (!_isSameDay(today, _lastResetDate)) {
      _habits.forEach((habit) {
        habit.saveCompletionForToday();
        habit.completionsToday = 0;
      });
      _lastResetDate = today;
      saveHabits();
      notifyListeners();
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  Future<void> saveHabits() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> habitStrings = _habits.map((habit) => jsonEncode(habit.toJson())).toList();
    await prefs.setStringList('habits', habitStrings);
    await prefs.setString('lastResetDate', _lastResetDate.toIso8601String());
  }

  Future<void> loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? habitStrings = prefs.getStringList('habits');
    if (habitStrings != null) {
      _habits = habitStrings.map((string) => Habit.fromJson(jsonDecode(string))).toList();
    }
    String? lastResetDateString = prefs.getString('lastResetDate');
    if (lastResetDateString != null) {
      _lastResetDate = DateTime.parse(lastResetDateString);
    }
    resetHabitsIfNeeded();
    notifyListeners();
  }
}

class Note {
  String text;
  String date;

  Note({
    required this.text,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'date': date,
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      text: json['text'],
      date: json['date'],
    );
  }
}

class NoteProvider with ChangeNotifier {
  List<Note> _notes = [];

  NoteProvider() {
    loadNotes();
  }

  List<Note> get notes => _notes;

  void addNote(Note note) {
    _notes.add(note);
    saveNotes();
    notifyListeners();
  }

  void deleteNoteAt(int index) {
    _notes.removeAt(index);
    saveNotes();
    notifyListeners();
  }

  void updateNoteAt(int index, String newText) {
    _notes[index].text = newText;
    saveNotes();
    notifyListeners();
  }

  Future<void> saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> noteStrings = _notes.map((note) => jsonEncode(note.toJson())).toList();
    await prefs.setStringList('notes', noteStrings);
  }

  Future<void> loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? noteStrings = prefs.getStringList('notes');
    if (noteStrings != null) {
      _notes = noteStrings.map((string) => Note.fromJson(jsonDecode(string))).toList();
      notifyListeners();
    }
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _timesController = TextEditingController();

  void _addHabit(String habitName, int timesPerDay) {
    if (habitName.isNotEmpty) {
      Provider.of<HabitProvider>(context, listen: false)
          .addHabit(Habit(habitName, timesPerDay: timesPerDay));
      _textController.clear();
      _timesController.clear();
    }
  }

  void _showAddHabitDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add a new habit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _textController,
                decoration: InputDecoration(labelText: 'Habit name'),
              ),
              TextField(
                controller: _timesController,
                decoration: InputDecoration(labelText: 'Times per day'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                _textController.clear();
                _timesController.clear();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Add'),
              onPressed: () {
                final habitName = _textController.text;
                final timesPerDay = int.tryParse(_timesController.text) ?? 1;
                _addHabit(habitName, timesPerDay);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<HabitProvider>(context).resetHabitsIfNeeded();

    return Scaffold(
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _showAddHabitDialog,
              child: Text('Add a new habit'),
            ),
          ),
          Expanded(
            child: Consumer<HabitProvider>(
              builder: (context, habitProvider, child) {
                return ListView.builder(
                  itemCount: habitProvider.habits.length,
                  itemBuilder: (context, index) {
                    final habit = habitProvider.habits[index];
                    return Card(
                      color: Theme.of(context).cardColor,
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        title: Text(
                          habit.name,
                          style: TextStyle(
                            decoration: habit.isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                        subtitle: Text('Completed: ${habit.completionsToday}/${habit.timesPerDay} times'),
                        leading: Checkbox(
                          value: habit.isCompleted,
                          onChanged: (bool? value) {
                            Provider.of<HabitProvider>(context, listen: false)
                                .toggleHabitCompletion(index);
                          },
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            Provider.of<HabitProvider>(context, listen: false)
                                .removeHabit(index);
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class HeatMapPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<HabitProvider>(
        builder: (context, habitProvider, child) {
          if (habitProvider.habits.isEmpty) {
            return Center(
              child: Text('No habits added.'),
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: habitProvider.habits.map((habit) {
                Map<DateTime, int> completionMap = {};
                habit.completionMap.forEach((date, value) {
                  completionMap[date] = value;
                });

                DateTime now = DateTime.now();
                DateTime sixMonthsAgo = DateTime(now.year, now.month - 5, now.day);

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      HeatMap(
                        datasets: completionMap,
                        colorMode: ColorMode.color,
                        showText: true,
                        scrollable: true,
                        startDate: sixMonthsAgo,
                        endDate: now,
                        colorsets: {
                          1: Colors.green[100]!,
                          2: Colors.green[200]!,
                          3: Colors.green[300]!,
                          4: Colors.green[400]!,
                          5: Colors.green[500]!,
                          6: Colors.green[600]!,
                          7: Colors.green[700]!,
                          8: Colors.green[800]!,
                          9: Colors.green[900]!,
                          10: Colors.green[900]!,
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}

class MyNotesPage extends StatefulWidget {
  @override
  _MyNotesPageState createState() => _MyNotesPageState();
}

class _MyNotesPageState extends State<MyNotesPage> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _editController = TextEditingController();

  void _addNote() {
    if (_notesController.text.isNotEmpty) {
      Provider.of<NoteProvider>(context, listen: false).addNote(Note(
        text: _notesController.text,
        date: DateTime.now().toString().split(' ')[0],
      ));
      _notesController.clear();
    }
  }

  void _editNoteDialog(int index, String currentText) {
    _editController.text = currentText;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Note'),
          content: TextField(
            controller: _editController,
            decoration: InputDecoration(labelText: 'Edit your note'),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                _editController.clear();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () {
                final newText = _editController.text;
                if (newText.isNotEmpty) {
                  Provider.of<NoteProvider>(context, listen: false).updateNoteAt(index, newText);
                  _editController.clear();
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Enter your note',
                suffixIcon: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _addNote,
                ),
              ),
            ),
            Expanded(
              child: Consumer<NoteProvider>(
                builder: (context, noteProvider, child) {
                  return ListView.builder(
                    itemCount: noteProvider.notes.length,
                    itemBuilder: (context, index) {
                      final note = noteProvider.notes[index];
                      return Card(
                        color: Theme.of(context).cardColor,
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ListTile(
                          title: Text(note.text),
                          subtitle: Text('Date: ${note.date}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () {
                                  _editNoteDialog(index, note.text);
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () {
                                  Provider.of<NoteProvider>(context, listen: false).deleteNoteAt(index);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
