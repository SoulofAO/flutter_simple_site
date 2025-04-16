import 'dart:html' as html;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Добавить этот импорт
import 'package:audioplayers/audioplayers.dart';
import 'package:animated_background/animated_background.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'panda.dart';
import 'dart:async';

void main() => runApp(const HabitApp());

class HabitApp extends StatelessWidget {
  const HabitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HabitHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HabitHomePage extends StatefulWidget {
  const HabitHomePage({super.key});

  @override
  State<HabitHomePage> createState() => _HabitHomePageState();
}

class _HabitHomePageState extends State<HabitHomePage> with TickerProviderStateMixin {

  final List<String> defaultHabits = [
    "Выпей стакан воды",
    "Сделай 10 отжиманий",
    "Пройди 1000 шагов",
    "Прочитай 5 страниц книги",
    "Выключи уведомления на час",
    "Не смотри в экран 10 минут",
    "Напиши благодарность за день"
  ];

  late String todayHabit;
  late String lastHabit;
  final GlobalKey<PandaImagePageState> _pandaKey = GlobalKey();
  int combo = 0;
  String today = DateTime.now().toLocal().toString().split(' ')[0];
  String? lastDate;
  bool alreadyDone = false;
  bool allowMultiple = false;
  AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlayFirstReward = false;
  bool isPlaySecondReward = false;
  List<String> customGoals = [];
  final TextEditingController _goalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    todayHabit = defaultHabits[Random().nextInt(defaultHabits.length)];
    _loadProgress();
    _fetchHabits();
  }

  void _setRandomHabit()
  {
    lastHabit = todayHabit;
    List<String> all_habits = [];
    all_habits.addAll(defaultHabits);
    all_habits.addAll(customGoals);

    while(todayHabit == lastHabit)
    {
      todayHabit =  all_habits[Random().nextInt(all_habits.length)];
    }
  }
  void _loadProgress() {
    lastDate = html.window.localStorage['last_done_date'];
    String? nullableTodayHabit = html.window.localStorage['todayHabit'];
    if(nullableTodayHabit!=null)
    {
      todayHabit = nullableTodayHabit;
    }
    String? nullableLastHabit = html.window.localStorage['lastHabit'];
    if(nullableLastHabit!=null)
    {
      lastHabit = nullableLastHabit;
    }
    String? nullablecustomGoalsString = html.window.localStorage['customGoals'];
    if(nullablecustomGoalsString!=null)
    {
      List<dynamic> decoded = jsonDecode(nullablecustomGoalsString);
      customGoals = List<String>.from(decoded);
    }
    combo = int.tryParse(html.window.localStorage['combo'] ?? '0') ?? 0;
    if (lastDate == today && !allowMultiple) {
      alreadyDone = true;
    }
  }

  Future<void> _fetchHabits() async {
  try {
    final response = await http.get(Uri.parse('http://localhost:5000/habits'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        defaultHabits.clear();
        defaultHabits.addAll(data.cast<String>());
        _setRandomHabit();
      });
    } else {
      throw Exception('Ошибка загрузки задач');
    }
  } catch (e) {
    print("Ошибка при подключении к серверу: $e");
  }
}

  void _saveAll()
  {
      html.window.localStorage['combo'] = combo.toString();
      html.window.localStorage['last_done_date'] = today;
      html.window.localStorage['todayHabit'] = todayHabit;
      html.window.localStorage['lastHabit'] = lastHabit;
      html.window.localStorage['customGoals'] = jsonEncode(customGoals);
  }
  void _markDone() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1)).toString().split(' ')[0];
    _playCompleteSound();
    setState(() {
      combo += 1;
      alreadyDone = true;
      _setRandomHabit();
    });
    _saveAll();
    _showDialog("Отлично! Текущая серия: $combo");
  }

  void _showDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Успех"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

void _stopFirstReward() {
    _audioPlayer.stop();
    setState(() {
      isPlayFirstReward = false;
    });
  }

  Future<void> _playFirstReward() async {
    try {
      await _audioPlayer.setSource(UrlSource('http://localhost:5000/assets/HeraldOfDarkness.mp3'));
      await _audioPlayer.play(UrlSource('http://localhost:5000/assets/HeraldOfDarkness.mp3'));
      setState(() {
        isPlayFirstReward = true;
        combo = combo - 3;
      });
      _saveAll();
      Timer(Duration(seconds: 55), _stopFirstReward);
    } catch (e) {
      print("Ошибка воспроизведения: $e");
    }
  }

  void _stopSecondReward() {
    setState(() {
      isPlaySecondReward = false;
    });
  }

    Future<void> _playCompleteSound() async {
    try {
      await _audioPlayer.setSource(UrlSource('http://localhost:5000/assets/Reward.mp3'));
      await _audioPlayer.play(UrlSource('http://localhost:5000/assets/Reward.mp3'));
    } catch (e) {
      print("Ошибка воспроизведения: $e");
    }
  }

  void _playSecondReward() {
    setState(() {
      isPlaySecondReward = true;
      combo = combo - 5;
    });
    _saveAll();
    Timer(Duration(seconds: 20), _stopSecondReward);
    _pandaKey.currentState?.selectRandomImage();
  }


  void _skipHabit() {
  setState(() {
    if (combo > 0) combo -= 1;
    todayHabit = defaultHabits[Random().nextInt(defaultHabits.length)];
    html.window.localStorage['combo'] = combo.toString();
  });
  _showDialog("Задание пропущено. Комбо уменьшено до $combo");
  _saveAll();
}


Widget _buildFireIcon() {
    return combo >= 3 ? const Icon(Icons.local_fire_department, color: Colors.orange, size: 32) : const SizedBox();
}

void _addGoal() {
  final text = _goalController.text.trim();
  if (text.isNotEmpty) {
    setState(() {
      customGoals.add(text);
      _goalController.clear();
    });
  }
}

void _removeGoal(int index) {
  setState(() {
    customGoals.removeAt(index);
  });
}


@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.transparent,
    appBar: AppBar(
      title: const Text("🎯 Привычка дня"),
      centerTitle: true,
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text("Разрешить несколько задач в день"),
          ],
        ),
        Switch(
          value: allowMultiple,
          onChanged: (value) {
            setState(() {
              allowMultiple = value;
            });
          },
        ),
      ],
    ),
    body: Stack(
      children: [
        Opacity(
          opacity: isPlaySecondReward ? 1.0 : 0.0,
          child: PandaImagePage(key: _pandaKey),
        ),
        AnimatedBackground(
            behaviour: RandomParticleBehaviour(
              options: ParticleOptions(
                spawnMinSpeed: 10.0,
                spawnMaxSpeed: 50.0,
                particleCount: isPlayFirstReward ? 100 : 0, // Частицы только при воспроизведении
                baseColor: Colors.redAccent,
                spawnOpacity: 0.1,
                opacityChangeRate: 0.25,
              ),
            ),
            vsync: this,
            child: Container(),
          ),
          // Пульсирующий эффект
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(todayHabit, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Текущая серия: $combo", style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    _buildFireIcon(),
                  ],
                ),
                const SizedBox(height: 50),
                ElevatedButton(
                  onPressed: alreadyDone && !allowMultiple ? null : _skipHabit,
                  style: ElevatedButton.styleFrom(backgroundColor: alreadyDone && !allowMultiple ? Colors.grey : Colors.red),
                  child: const Text("Пропустить (-1 комбо)"),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: alreadyDone && !allowMultiple ? null : _markDone,
                  child: Text(alreadyDone && !allowMultiple ? "Уже выполнено сегодня!" : "Отметить как выполнено"),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.star, color: isPlayFirstReward ? Colors.green : (combo < 3 ? Colors.grey : Colors.yellow), size: 40),
                      onPressed: isPlayFirstReward ? _stopFirstReward : combo >= 3 ? _playFirstReward : null,
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: Icon(Icons.access_alarm, color: isPlaySecondReward ? Colors.green :(combo < 5 ? Colors.grey : Colors.blue), size: 40),
                      onPressed: isPlaySecondReward ? _stopSecondReward : combo >= 5 ? _playSecondReward : null,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _goalController,
                  decoration: InputDecoration(
                    labelText: "Новая цель",
                    suffixIcon: IconButton(
                      icon: Icon(Icons.add),
                      onPressed: _addGoal,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: customGoals.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(customGoals[index]),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeGoal(index),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
}