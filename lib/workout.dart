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
  Timer readTimer;
  int steps = 0;
  bool readFromBluetooth = false;
  bool tryReading = false;
  int stepsDiff = 0;
  bool lastReadFinished = true;
  int stepsFromButton = 0;


  void readSteps(Timer t) {
    if (!this.mounted) {
      return;
    }
    if (!readFromBluetooth) {
      setState(() {
        currentSteps = stepsFromButton;
      });
    }
    else {
      try {
        if (lastReadFinished) {
          setState(() {
            lastReadFinished = false;
            gSelectedDevice.readCharacteristic(gSelectedCharacteristic).then((l) {
              currentSteps = Uint8List.fromList(l).buffer.asByteData().getUint32(0) + stepsDiff;
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
          child: Column(
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
              Text('Bluetooth device'),
              RaisedButton(
                child: Text('Step'),
                onPressed: () {
                  setState(() {
                    stepsFromButton++;
                  });
                },
              ),
              Text(currentSteps.toString()),
              Container(
                height: 100,
              ),
              Container(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 20.0,
                ),
                height: 200,
                width: 200,
              )
            ],
          ),
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