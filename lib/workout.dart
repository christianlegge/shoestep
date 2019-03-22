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

class WorkoutScreenState extends State<WorkoutScreen> {
  int currentSteps = 0;
  int stepsFromBt = 0;
  Timer readTimer;
  bool readFromBluetooth = false;
  bool tryReading = false;
  int stepsDiffButton = 0;
  int stepsDiffBt = 0;
  bool lastReadFinished = true;
  int stepsFromButton = 0;


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
    // TODO: implement initState
    super.initState();
    readTimer = new Timer.periodic(Duration(milliseconds: 50), readSteps);
  }

  @override
  Widget build(BuildContext context) {
    return new WillPopScope(
      onWillPop: () async {
        print(currentSteps);
        int numRows = Sqflite.firstIntValue(await database.rawQuery('SELECT COUNT(*) FROM StepCounts'));
        database.insert('StepCounts', {'id':numRows,'steps':currentSteps});
        readTimer = null;
        return true;
      },
      child: Scaffold(
        backgroundColor: Color.fromARGB(255, 255, 130, 130),

        appBar: AppBar(
          title: Text('Workout'),
        ),
        body: Center(
          child: ListView(
            children: <Widget>[
              Column(
                children: <Widget>[
                  Row(
                      children: <Widget>[
                        Hero(
                          child: Icon(Icons.directions_walk, size: 100,),
                          tag: 'walkTag',
                        ),
                        Text('Workout'),
                      ]
                  ),

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
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.cancel),
          onPressed: () {
            Navigator.maybePop(context);
          },
        ),
      )
    );
  }
}