import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pie_chart/pie_chart.dart';

class FirebaseData {
  CollectionReference<Map<String, dynamic>> thoughtCollection;
  String uuid;

  FirebaseData(this.thoughtCollection, this.uuid);
}

class DayThoughts {
  String userId;
  List<String> accomplishments;
  DateTime createdTime;

  DayThoughts(this.userId, this.accomplishments, this.createdTime);

  DayThoughts.fromJson(Map<String, Object?> json)
      : this(
            json['userId']! as String,
            (json['accomplishments']! as List<dynamic>)
                .map((e) => e as String)
                .toList(),
            (json['createdTime']! as Timestamp).toDate());

  Map<String, Object?> toJson() {
    return {
      'userId': userId,
      'accomplishments': accomplishments,
      'createdTime': createdTime
    };
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: const FirebaseOptions(
            apiKey: "AIzaSyCqCZ4hj54UALwigomO-6LKJ4kS8ZxNuAg",
            authDomain: "three-little-things.firebaseapp.com",
            projectId: "three-little-things",
            storageBucket: "three-little-things.appspot.com",
            messagingSenderId: "312349347082",
            appId: "1:312349347082:web:32f6eb7768dc2528ba7ef3",
            measurementId: "G-W5FHGWVEC5"));
  } else {
    await Firebase.initializeApp();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.lightGreen,
      ),
      home: const AppLayout(),
    );
  }
}

enum Page { analytics, addEntry, community, settings }

class AppLayout extends StatefulWidget {
  const AppLayout({Key? key}) : super(key: key);

  @override
  State<AppLayout> createState() => _App();
}

class _App extends State<AppLayout> {
  Page _selectedPage = Page.analytics;

  void _onItemTapped(int index) {
    setState(() {
      _selectedPage = Page.values[index];
    });
  }

  Widget getPage() {
    if (_selectedPage == Page.analytics) {
      return const AnalyticsPage();
    } else if (_selectedPage == Page.addEntry) {
      return const AddEntryPage();
    } else if (_selectedPage == Page.community) {
      return const AddCommunityPage();
    } else if (_selectedPage == Page.settings) {
      return const AddSettingsPage();
    } else {
      return Positioned.fill(child: Stack());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
          padding: const EdgeInsets.only(top: 75, left: 25, right: 25),
          decoration: const BoxDecoration(
              image: DecorationImage(
                  image: AssetImage("assets/background.png"),
                  fit: BoxFit.fill)),
          child: Stack(children: [getPage()])),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: SizedBox(
                  child: Image(image: AssetImage('assets/analytics.png')),
                  width: 100,
                  height: 100),
              label: "",
              activeIcon: SizedBox(
                  child:
                      Image(image: AssetImage('assets/analytics_selected.png')),
                  width: 100,
                  height: 100)),
          BottomNavigationBarItem(
              icon: SizedBox(
                  child: Image(image: AssetImage('assets/add.png')),
                  width: 100,
                  height: 100),
              label: "",
              activeIcon: SizedBox(
                  child: Image(image: AssetImage('assets/add_selected.png')),
                  width: 100,
                  height: 100)),
          BottomNavigationBarItem(
              icon: SizedBox(
                  child: Image(image: AssetImage('assets/community.png')),
                  width: 100,
                  height: 100),
              label: "",
              activeIcon: SizedBox(
                  child:
                      Image(image: AssetImage('assets/community_selected.png')),
                  width: 100,
                  height: 100)),
          BottomNavigationBarItem(
              icon: SizedBox(
                  child: Image(image: AssetImage('assets/settings.png')),
                  width: 100,
                  height: 100),
              label: "",
              activeIcon: SizedBox(
                  child:
                      Image(image: AssetImage('assets/settings_selected.png')),
                  width: 100,
                  height: 100)),
        ],
        currentIndex: _selectedPage.index,
        onTap: _onItemTapped,
        iconSize: 6,
      ),
    );
  }
}

// ANALYTICS PAGE
class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AnalyticsPage();
}

enum ChartDisplayDuration { week, month, year, life }

class _AnalyticsPage extends State<AnalyticsPage> {
  ChartDisplayDuration _displayTime = ChartDisplayDuration.week;
  Map<String, double> _tagsOccurrences = {};

  Future<void> updateTagsOccurrences() async {
    CollectionReference thoughts =
        FirebaseFirestore.instance.collection("thoughts");
    var thoughtsRef = thoughts.withConverter<DayThoughts>(
        fromFirestore: (snapshot, _) => DayThoughts.fromJson(snapshot.data()!),
        toFirestore: (thoughts, _) => thoughts.toJson());
    List<QueryDocumentSnapshot<DayThoughts>> docs = await thoughtsRef
        .where('userId', isEqualTo: 'test')
        .get()
        .then((value) => value.docs);
    for (var doc in docs) {
      DayThoughts dayThoughts = doc.data();
      _tagsOccurrences = {};
      for (var thought in dayThoughts.accomplishments) {
        if (_tagsOccurrences.containsKey(thought)) {
          _tagsOccurrences.update(thought, (value) => value + 1);
        } else {
          _tagsOccurrences[thought] = 1;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: updateTagsOccurrences(),
        builder: (context, snapshot) {
          return Positioned.fill(
              child: Align(
                  alignment: Alignment.topCenter,
                  child: Column(children: [
                    const Text("What have you accomplished in the past",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    DropdownButton(
                        value: _displayTime.name,
                        style:
                            const TextStyle(fontSize: 24, color: Colors.black),
                        items: ChartDisplayDuration.values
                            .map((e) => e.name)
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (Object? val) {
                          setState(() {
                            switch (val) {
                              case "week":
                                _displayTime = ChartDisplayDuration.week;
                                break;
                              case "month":
                                _displayTime = ChartDisplayDuration.month;
                                break;
                              case "year":
                                _displayTime = ChartDisplayDuration.year;
                                break;
                              case "life":
                                _displayTime = ChartDisplayDuration.life;
                                break;
                            }
                          });
                        }),
                    const SizedBox(height: 30),
                    _tagsOccurrences.isEmpty
                        ? const SizedBox()
                        : PieChart(
                            dataMap: _tagsOccurrences,
                            colorList: const [
                              Color(0xff236d5e),
                              Color(0xff8eb699),
                              Color(0xffdfc3a7),
                              Color(0xffe3e6d4),
                              Color(0xffedb8d5),
                              Color(0xfff4b288)
                            ],
                            legendOptions: const LegendOptions(
                                legendPosition: LegendPosition.bottom,
                                showLegendsInRow: true),
                            chartValuesOptions: const ChartValuesOptions(
                              decimalPlaces: 0
                            ),
                          )
                  ])));
        });
  }
}

// ADD ENTRY PAGE
class AddEntryPage extends StatefulWidget {
  const AddEntryPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AddEntryPage();
}

class _AddEntryPage extends State<AddEntryPage> {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
        child: Align(
            alignment: Alignment.topCenter,
            child: Column(children: const [
              Text("What made you happy today?",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              TextField(),
              TextField(),
              TextField(),
              SizedBox(height: 100),
              Text("What did you accomplish today?",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              TextField(),
              TextField(),
              TextField(),
            ])));
  }
}

// COMMUNITY PAGE
class AddCommunityPage extends StatefulWidget {
  const AddCommunityPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AddCommunityPage();
}

class _AddCommunityPage extends State<AddCommunityPage> {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
        child: Align(
            alignment: Alignment.topCenter,
            child: Column(
              children: [
                SizedBox(
                    child: Container(
                      decoration: const BoxDecoration(
                          image: DecorationImage(
                              image: AssetImage("assets/community_page.png"),
                              fit: BoxFit.fill)),
                    ),
                    width: 350,
                    height: 615)
              ],
            )));
  }
}

// SETTINGS PAGE
class AddSettingsPage extends StatefulWidget {
  const AddSettingsPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AddSettingsPage();
}

class _AddSettingsPage extends State<AddSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
        child: Align(
            alignment: Alignment.topCenter,
            child: Column(
              children: [
                const Text("Settings",
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(
                    child: Container(
                      decoration: const BoxDecoration(
                          image: DecorationImage(
                              image: AssetImage("assets/settings_page.png"),
                              fit: BoxFit.fill)),
                    ),
                    width: 350,
                    height: 450)
              ],
            )));
  }
}
