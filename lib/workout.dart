import 'dart:async';
import 'dart:core';
import 'dart:developer';
import 'dart:typed_data';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:flutter_shoestep/main.dart';
import 'package:sqflite/sqflite.dart';

class WorkoutScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => WorkoutScreenState();
}

class WorkoutScreenState extends State<WorkoutScreen> with SingleTickerProviderStateMixin {
  int currentSteps = 0;
  int stepsFromBt = 0;
  Timer readTimer;
  bool readFromBluetooth = true;
  bool tryReading = false;
  int stepsDiffButton = 0;
  int stepsDiffBt = 0;
  bool lastReadFinished = true;
  int stepsFromButton = 0;
  Animation<double> bgScroll;
  AnimationController bgScrollController;


  void readSteps(Timer t) {
    if (!this.mounted) {
      return;
    }
    if (!readFromBluetooth) {
      setState(() {
        currentSteps = stepsFromButton + stepsDiffButton;
      });
    }
    else {
      try {
        if (lastReadFinished) {
          setState(() {
            lastReadFinished = false;
            gSelectedDevice.readCharacteristic(gSelectedCharacteristic).then((l) {
              stepsFromBt = Uint8List.fromList(l).buffer.asByteData().getUint32(0);
              currentSteps = stepsFromBt + stepsDiffBt;
              lastReadFinished = true;
            });
          });
        }
      }
      catch(e) {
        setState(() {
          currentSteps = -333;
          lastReadFinished = true;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    bgScrollController = AnimationController(
      duration: Duration(seconds: 10), vsync: this,
    );
    bgScroll = Tween<double>(begin:-1.0, end:1.0).animate(bgScrollController)
    ..addListener(() {
      setState(() {

      });
    })
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        bgScrollController.forward(from: 0.35);
      }
    });
    bgScrollController.forward();
    readTimer = new Timer.periodic(Duration(milliseconds: 50), readSteps);
  }

  @override
  Widget build(BuildContext context) {
    return new WillPopScope(
      onWillPop: () async {
        print(currentSteps);
        int numRows = Sqflite.firstIntValue(await database.rawQuery('SELECT COUNT(*) FROM StepCounts'));
        database.insert('StepCounts', {'id':numRows,'date':new DateTime(2019, 03, numRows).toIso8601String(),'steps':currentSteps});
        readTimer = null;
        return true;
      },
      child: Scaffold(
        backgroundColor: Color.fromARGB(255, 255, 130, 130),

        appBar: AppBar(
          title: Text('Workout'),
        ),
        body: Stack(
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/city.png'),
                  colorFilter: ColorFilter.mode(Color.fromARGB(185, 255, 255, 255), BlendMode.colorDodge),
                  fit: BoxFit.cover,
                  alignment: Alignment(bgScroll.value, 0),
                  repeat: ImageRepeat.repeatX,
                ),
              ),
            ),
            Center(
              child: ListView(
                children: <Widget>[
                  Column(
                    children: <Widget>[
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text('Counter'),
                            Switch(
                              value: readFromBluetooth,
                              materialTapTargetSize: MaterialTapTargetSize.padded,
                              onChanged: (val) {
                                setState(() {
                                  readFromBluetooth = val;
                                });
                              },
                            ),
                            Text('Bluetooth device'),
                          ]
                      ),
                      RaisedButton(
                        child: Text('Step'),
                        onPressed: () {
                          setState(() {
                            stepsFromButton++;
                          });
                        },
                      ),
                      RaisedButton(
                        child: Text('Reset count'),
                        onPressed: () {
                          setState(() {
                            if (readFromBluetooth) {
                              stepsDiffBt -= currentSteps;
                            }
                            else {
                              stepsDiffButton -= currentSteps;
                            }
                            currentSteps = 0;
                          });
                        },
                      ),
                      Text(
                          currentSteps.toString(),
                          style: TextStyle(
                            fontSize: 72,
                          )
                      ),
                      Text('Real steps: ' + (readFromBluetooth ? stepsFromBt : stepsFromButton).toString()),
                      Container(
                        height: 100,
                      ),

                    ],
                  ),

                ],
              )
            ),
            Positioned(
                child: Hero(
                  child: Icon(Icons.directions_walk, size: 100,),
                  tag: 'walkTag',
                ),
                bottom: 80.0
            )
          ]
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.check),
          onPressed: () {
            Navigator.maybePop(context);
          },
        ),
      )
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    bgScrollController.dispose();
    super.dispose();
  }
}