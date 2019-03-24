import 'dart:async';
import 'dart:core';
import 'dart:developer';
import 'dart:math';
import 'dart:typed_data';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_shoestep/example.dart';
import 'package:flutter_shoestep/home.dart';
import 'package:flutter_shoestep/workout.dart';

FlutterBlue flutterBlue = FlutterBlue.instance;
StreamSubscription deviceConnection;
BluetoothDevice gSelectedDevice;
BluetoothCharacteristic gSelectedCharacteristic;

Database database;
int stepcount = 0;
Random rng = new Random();

Future<void> initDb() async {
  var databasesPath = await getDatabasesPath();
  String path = [databasesPath, 'demo.db'].join('');
  await deleteDatabase(path);
  database = await openDatabase(path, version: 1,
  onCreate: (Database db, int version) async {
    await db.execute('CREATE TABLE StepCounts (id INTEGER PRIMARY KEY, date TEXT, steps INTEGER)');
    for (int i = 0; i < 360; i++) {
      await db.insert('StepCounts', {'id': i, 'date': DateTime(2019, 3, 23).add(Duration(days: -365+i)).toIso8601String(), 'steps': rng.nextInt(2000)+5000});
    }
  });
}

void main() {
  initDb().then((_) {
    runApp(MyApp());
  });

  //runApp(new FlutterBlueApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShoeStep',
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(),
        '/workout': (context) => WorkoutScreen(),
      },
      theme: new ThemeData(
        primaryColor: Colors.red,
        buttonColor: Colors.red,
      ),
    );
  }
}

class ScaleClipper extends CustomClipper<Rect> {
  Offset origin;
  double value;

  @override
  Rect getClip(Size size) {
    Rect rect = Rect.fromCircle(center: origin, radius: value);
    return rect;
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) {
    return true;
  }

  ScaleClipper(Offset origin, double value) {
    this.origin = origin;
    this.value = value;
  }
}

class MyDrawer extends StatelessWidget {

  Function setHomeState;

  MyDrawer(this.setHomeState);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: <Widget>[
          DrawerHeader(
            child: Text('ShoeStep'),
            decoration: BoxDecoration(
              image: DecorationImage(image: AssetImage('assets/RunningShoes.jpg'), fit: BoxFit.cover)
            ),
          ),
          ListTile(
            title: Text('Delete Saved Data'),
            onTap: () {
              Navigator.of(context).pop();
              return showDialog(
                context: context,
                barrierDismissible: true,
                builder: (context) {
                  return AlertDialog(
                    title: Text('Confirm'),
                    content: Text('Really delete all saved data? This cannot be undone!'),
                    actions: <Widget>[
                      FlatButton(
                        child: Text('Cancel'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      FlatButton(
                        child: Text('Yes'),
                        onPressed: () {
                          database.execute("DELETE FROM StepCounts").then((_) {
                            for (int i = 0; i < 365; i++) {
                              database.insert('StepCounts', {'id': i, 'date': DateTime(2019, 3, 23).add(Duration(days: -365+i)).toIso8601String(), 'steps': 0});
                            }
                            setHomeState();
                            Navigator.of(context).pop();
                          });
                        },
                      )
                    ],
                  );
                }
              );
            },
          ),
          SizedBox(
            height: 450,
          ),
          Center(child: Text('ECE JLLT 2019', style: TextStyle(color: Colors.black38),))
        ],
      ),
    );
  }
}