import 'dart:async';
import 'dart:core';
import 'dart:developer';
import 'dart:math';
import 'dart:typed_data';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:flutter_shoestep/main.dart';
import 'package:flutter_shoestep/summary.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_blue/flutter_blue.dart';

class WorkoutScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => WorkoutScreenState();
}

class WorkoutScreenState extends State<WorkoutScreen> with TickerProviderStateMixin {
  bool debug = false;
  bool scanning = true;
  Map<String, ScanResult> devices = new Map();
  var scanSubscription;
  BluetoothDevice selectedDevice;
  List<BluetoothService> deviceServices;
  BluetoothService selectedService;
  BluetoothCharacteristic selectedCharacteristic;
  bool isFirstRead = true;
  bool tryingToConnect = false;
  DateTime startTime;

  int tmpBtVal = 0;

  bool discoveringServices = false;

  bool connectedAndReading = false;



  int stepsToShow = 0;
  int valueFromBt = 0;
  Timer readTimer;
  bool readFromBluetooth = false;
  bool tryReading = false;
  int stepsDiffButton = 0;
  int stepsDiffBt = 0;
  bool lastReadFinished = true;
  int stepsFromButton = 0;
  int halfStepCount = 0;
  int checksSinceSignal = 0;
  int lastChecksSinceSignal = 0;
  bool disconnected = true;

  Animation<double> scanText;
  AnimationController scanTextController;
  Animation<double> bgScroll;
  AnimationController bgScrollController;
  Animation<double> runningMan;
  AnimationController runningManController;
  bool bounceyBoy = false;

  void recalculateSteps(int realValue, int diffValue) {
    if (realValue + diffValue > halfStepCount) {
      lastChecksSinceSignal = checksSinceSignal;
      checksSinceSignal = 0;
      print('received signal');
      print(lastChecksSinceSignal);
      stepsToShow++;
    }
    else {
      checksSinceSignal++;
    }
    if (checksSinceSignal == (lastChecksSinceSignal / 2).floor()) {
      stepsToShow++;
    }
    halfStepCount = realValue + diffValue;
    //stepsToShow = 2*halfStepCount;
    stepsToShow = stepsToShow.clamp(2*halfStepCount - 1, 2*halfStepCount);
  }

  void readSteps(Timer t) {
    if (!this.mounted) {
      return;
    }
    if (!readFromBluetooth && debug) {
      setState(() {
        recalculateSteps(stepsFromButton, stepsDiffButton);
      });
    }
    else if (connectedAndReading && !disconnected) {
      try {
        if (lastReadFinished) {
          setState(() {
            lastReadFinished = false;
            selectedDevice.readCharacteristic(selectedCharacteristic).then((l) {
              if(disconnected) {
                valueFromBt = Uint8List.fromList(l).buffer.asByteData().getUint32(0);
                stepsDiffBt += valueFromBt - tmpBtVal;
                tmpBtVal = 0;
                return;
              }
              print("READ CHARACTERISTIC, PARSING $l $checksSinceSignal");
              if (l.length == 1 && l[0] == 0) {
                valueFromBt = 0;
              }
              else if (l.length == 4) {
                valueFromBt = Uint8List.fromList(l).buffer.asByteData().getUint32(0);
              }
              else {
                lastReadFinished = true;
                return;
              }
              if (isFirstRead) {
                stepsDiffBt = -valueFromBt;
                isFirstRead = false;
              }
              recalculateSteps(valueFromBt, stepsDiffBt);
              lastReadFinished = true;
            })
            ..timeout(Duration(seconds: 3), onTimeout: () {
              stepsDiffBt += valueFromBt;
              tmpBtVal = valueFromBt;
              valueFromBt = 0;
              disconnected = true;
              lastReadFinished = true;
            });
          });
        }
      }
      catch(e) {
        setState(() {
          stepsToShow = -333;
          lastReadFinished = true;
        });
      }
    }
  }

  void _startScanning() {
    scanning = true;
    scanSubscription = flutterBlue.scan().listen((scanResult) {
      if (scanResult.advertisementData.connectable) {
        if (this.mounted) {
          setState(() {
            devices[scanResult.device.id.toString()] = scanResult;
          });
        }
      }
    });
    Future.delayed(new Duration(seconds: 10)).then((_) {
      if (this.mounted) {
        setState(() {
          scanning = false;
          scanSubscription?.cancel();
          scanSubscription = null;
        });
      }
    });

  }

  @override
  void initState() {
    _startScanning();
    scanTextController = AnimationController(
      duration: Duration(seconds: 1), vsync: this,
    );
    scanText = Tween<double>(begin: 255, end: 0).animate(scanTextController)
    ..addListener(() {
      setState(() {

      });
    })
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        scanTextController.reverse();
      }
      if (status == AnimationStatus.dismissed) {
        scanTextController.forward();
      }
    });
    scanTextController.forward();
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
    runningManController = AnimationController(
      duration: Duration(seconds: 10), vsync: this,
    );
    runningMan = Tween<double>(begin: -100, end: 400).animate(runningManController)
    ..addListener(() {
      setState(() {

      });
    })
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        runningManController.forward(from: 0);
        bounceyBoy = rng.nextBool();
      }
    });
    readTimer = new Timer.periodic(Duration(milliseconds: 50), readSteps);
    if (debug) {
      startTime = DateTime.now();
      bgScrollController.forward();
      runningManController.forward(from: 0.2);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new WillPopScope(
      onWillPop: () async {
        if (!(connectedAndReading || debug)) {
          return true;
        }
        return showDialog(
            context: context,
            barrierDismissible: true,
            builder: (context) {
              return AlertDialog(
                title: Text('Confirm'),
                content: Text('Really exit without saving step data?'),
                actions: <Widget>[
                  FlatButton(
                    child: Text('Cancel'),
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                  ),
                  FlatButton(
                    child: Text('Yes'),
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                  )
                ],
              );
            }
        );
      },
      child: Scaffold(
        backgroundColor: Colors.black12,
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
              child:
                  Column(
                    children: _buildWorkoutScreen()
                  )

            ),
            Positioned(
              child: Hero(
                child: Icon(Icons.directions_walk, size: 100,),
                tag: 'walkTag',
              ),
              bottom: 80.0 + (bounceyBoy ? 10*sin(runningMan.value/10).abs() : 0),
              left: (runningMan.isDismissed ? 0 : runningMan.value),
            )
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: connectedAndReading || debug ? Colors.green : Colors.black26,
          child: Icon(Icons.check),
            onPressed: () async {
              if (!(connectedAndReading || debug)) {
                return;
              }
              print(stepsToShow);
              DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
              var result = await database.rawQuery('SELECT * FROM StepCounts WHERE date = "' + today.toIso8601String() + '"');
              print(result);

              int numRows = Sqflite.firstIntValue(
                  await database.rawQuery('SELECT COUNT(*) FROM StepCounts'));
              if (result.length == 0) {
                print("INSERTING");
                database.insert('StepCounts', {
                  'id': numRows,
                  'date': today.toIso8601String(),
                  'steps': stepsToShow
                });
              }
              else {
                print("UPDATING");
                int newSteps = result.first['steps'] + stepsToShow;
                await database.update('StepCounts', {'steps': newSteps}, where: 'date = "'+today.toIso8601String()+'"');
              }
              readTimer = null;

              WorkoutSummary summary = WorkoutSummary(DateTime.now().difference(startTime), stepsToShow);

              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => SummaryScreen(summary)));
            },
        ),
      ),
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    deviceConnection?.cancel();
    scanSubscription?.cancel();
    bgScrollController.dispose();
    scanTextController.dispose();
    runningManController.dispose();
    super.dispose();
  }

  List<Widget> _buildWorkoutScreen() {
    if (debug || connectedAndReading) {
      return <Widget>[
        SizedBox(
          height: 150,
        )
      ] + (debug ? <Widget>[
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
        Text('Real value: ' + (readFromBluetooth ? valueFromBt : stepsFromButton).toString()),
        Text('Difference: $stepsDiffBt'),
        Text('Checks since signal: $checksSinceSignal'),
        Text('last Checks since signal: $lastChecksSinceSignal'),
        Text('half step count: $halfStepCount'),
      ] : <Widget>[]) + <Widget>[
        Text(
          stepsToShow.toString(),
          style: TextStyle(
            fontSize: 90,
          )
        ),
        RaisedButton(
          child: Text('Reset'),
          onPressed: () {
            setState(() {
              if (readFromBluetooth) {
                stepsDiffBt -= halfStepCount;
              }
              else {
                stepsDiffBt -= halfStepCount;
              }
              halfStepCount = stepsToShow = 0;
            });
          },
        ),
      ];
    }
    else {
      return <Widget>[
        Padding(
          padding: EdgeInsets.all(32.0),
          child: (scanning ? Text('Scanning for devices...', style: TextStyle(
            color: Color.fromARGB(scanText.value.round(), 0, 0, 0),
            fontSize: 20.0,
            ),) : Text('Scan Complete', style: TextStyle(
            fontSize: 20.0,
          ))),
        ),
        Container(
          height: 300,
          width: 300,
          child: ListView(
              children: <Widget>[
                Column(

                  children: _buildDeviceList(),
                )
              ]
          ),
        )];
    }
  }

  List<Widget> _buildDeviceList() {
    if (devices.isEmpty) {
      if (scanning) {
        return [
          SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator()
          )
        ];
      }
      else {
        return [
          ListTile(
            title: Text('No Devices Found.'),
            subtitle: Text('Tap to retry.'),
            trailing: Icon(Icons.refresh),
            onTap: () {
              _startScanning();
            },
          )
        ];
      }
    }

    List<Widget> _list = new List();


    devices.forEach((k, v) {
      String _title = v.advertisementData.localName;
      _title = _title == '' ? v.device.name : _title;
      _title = _title == '' ? v.device.id.id : _title;
      _title = _title == '' ? v.device.id.toString() : _title;
      _list.add(SizedBox(
        height: 4.0,
        width: double.infinity,
      ));
      _list.add(Container(
        decoration: new BoxDecoration(
          color: Color.fromARGB(50, 0, 0, 0),
          borderRadius: BorderRadius.all(Radius.circular(12.0))
        ),
        child: ListTile(
          title: Text(_title),
          subtitle: (_title == v.device.id.toString() ? null : Text(v.device.id.toString())),
          trailing: (v.device == selectedDevice && tryingToConnect ? CircularProgressIndicator() : null),
          onTap: () {
            setState(() {
              tryingToConnect = true;
              scanSubscription?.cancel();
              scanSubscription = null;
              deviceConnection?.cancel();
              deviceConnection = null;
              selectedDevice = v.device;
              gSelectedDevice = selectedDevice;
              deviceServices = null;
              selectedService = null;
              selectedCharacteristic = null;
              deviceConnection = flutterBlue.connect(v.device).listen((s) {
                if (s ==BluetoothDeviceState.disconnecting) {
                  print("CONNECTION DROPPED");
                  disconnected = true;
                }
                if (s == BluetoothDeviceState.connected) {
                  disconnected = false;
                  print('connected!');
                  if (discoveringServices) {
                    return;
                  }
                  discoveringServices = true;
                  selectedDevice.discoverServices()..then((list) {
                    print('services discovered');
                    deviceServices = list;
                    for (BluetoothService bs in list) {
                      if (bs.uuid.toString().toUpperCase().substring(4, 8) == '180F') {
                        selectedService = bs;
                        break;
                      }
                    }
                    for (BluetoothCharacteristic bc in selectedService.characteristics) {
                      if (bc.uuid.toString().toUpperCase().substring(4, 8) == '2A19') {
                        selectedCharacteristic = bc;
                        break;
                      }
                    }
                    setState(() {
                      startTime = DateTime.now();
                      bgScrollController.forward();
                      runningManController.forward(from: 0.2);
                      connectedAndReading = true;
                      tryingToConnect = false;
                    });
                  })..timeout(Duration(seconds: 10), onTimeout: () {
                    print("Timed out discover services");
                    setState(() {
                      tryingToConnect = false;
                    });
                  });
                }
              });
            });
          },
        )
      ));
      _list.add(SizedBox(
        height: 4.0,
        width: double.infinity,
      ));
    });
    return _list;
  }
}