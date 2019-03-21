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
BluetoothDevice gSelectedDevice;
BluetoothCharacteristic gSelectedCharacteristic;

Database database;
int stepcount = 0;
Random rng = new Random();

Future<void> initDb() async {
  var databasesPath = await getDatabasesPath();
  String path = [databasesPath, 'demo.db'].join('');
  //await deleteDatabase(path);
  database = await openDatabase(path, version: 1,
  onCreate: (Database db, int version) async {
    await db.execute('CREATE TABLE StepCounts (id INTEGER PRIMARY KEY, steps INTEGER)');
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
        '/saved': (context) => SavedScreen(),
        '/animationtest': (context) => AnimationTestScreen(),
        '/connect': (context) => BluetoothScreen(),
        '/read': (context) => ReadDataScreen(),
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

class AnimationTestScreen extends StatefulWidget {
  @override
  State<AnimationTestScreen> createState() => AnimationTestScreenState();
}

class AnimationTestScreenState extends State<AnimationTestScreen> with SingleTickerProviderStateMixin {
  Animation<double> animation;
  AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(duration: const Duration(seconds: 2), vsync: this);
    animation = Tween<double>(begin:0, end:300).animate(controller)
    ..addListener(() {
      setState(() {

      });
    })
    ..addStatusListener((status) {
      print(status.toString());
      if (status == AnimationStatus.completed) {
        controller.reverse();
      }
    });
  }

  double sliderVal = 300;
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text('animation test'),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            RaisedButton(
              child: Text('animate'),
              onPressed: () {
                controller.forward();
              },
            ),
            ClipOval(
              clipper: ScaleClipper(Offset(150, 150), animation.value),
              child: Container(
                color: Colors.red,
                width: 300.0,
                height: 300.0,
              ),
            )
          ],
        )
      )
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}


class SavedScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Saved Data'),
      ),
      drawer: MyDrawer(),
      body: Center(
        child: FutureBuilder(
          future: listEntriesFromDb(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return ListView(
                children: snapshot.data,
              );
            }
            else if (snapshot.hasError) {
              return Text('${snapshot.error}');
            }
            return CircularProgressIndicator();
          },
        ),
      ),
    );
  }

  Future<List<Widget>> listEntriesFromDb() async {
    List rows = (await database.query('StepCounts')).toList();
    List<ListTile> list = new List();
    for (int i = 0; i < rows.length; i++) {
      list.add(new ListTile(
        title: Text(rows[i]['id'].toString() + ' ' + rows[i]['steps'].toString())
      ));
    }
    if (list.length > 0) {
      return list;
    }
    else {
      List<Widget> defaultList = new List();
      defaultList.add(ListTile(
        title: Text('No entries in db'),
      ));
      return defaultList;
    }
  }
}

class BluetoothScreen extends StatefulWidget {
  @override
  BluetoothScreenState createState() => BluetoothScreenState();
}

class BluetoothScreenState extends State<BluetoothScreen> {


  bool scanning = false;
  Map<String, ScanResult> devices = new Map();
  var scanSubscription;
  StreamSubscription deviceConnection;
  BluetoothDevice selectedDevice;
  List<BluetoothService> deviceServices;
  BluetoothService selectedService;
  BluetoothCharacteristic selectedCharacteristic;
  BluetoothDescriptor selectedDescriptor;
  List<int> readFromDescriptor;
  List<int> readFromCharacteristic;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Bluetooth connect'),
        ),
        drawer: MyDrawer(),
        body: Builder(
          builder: (context) => 
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(
                child: RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      scanning = true;
                      devices = new Map();
                      scanSubscription?.cancel();
                      deviceConnection?.cancel();
                    });
                    scanSubscription = flutterBlue.scan().listen((scanResult) {
                      if (scanResult.advertisementData.connectable) {
                        setState(() {
                          devices[scanResult.device.id.toString()] = scanResult;
                        });
                      }
                    });
                    await new Future.delayed(new Duration(seconds: 10));
                    scanSubscription?.cancel();
                    scanSubscription = null;
                    Scaffold.of(context).showSnackBar(SnackBar(content: Text('Scan complete'),));
                  } ,
                  child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: <Widget>[
                    RaisedButton(
                      child: Text('Reset'),
                      onPressed: () {
                        setState(() {
                          devices = new Map();
                          scanSubscription?.cancel();
                          scanSubscription = null;
                          deviceConnection?.cancel();
                          deviceConnection = null;
                          deviceServices = null;
                          selectedDevice = null;
                          selectedService = null;
                          selectedCharacteristic = null;
                          gSelectedCharacteristic = null;
                          gSelectedDevice = null;
                          scanning = false;
                        });
                      }),
                    Divider(),
                    Text('Devices'),
                    Column(
                      children: _buildDeviceList(),
                    ),
                    Divider(),
                    Text('Services'),
                    Column(
                      children: _buildServiceList(),
                    ),
                    Divider(),
                    Text('Characteristics (long press to read)'),
                    Column(
                      children: _buildCharacteristicList(),
                    ),
                    Divider(),
                    Text('Descriptors (long press to read)'),
                    Column(
                      children: _buildDescriptorList(context),
                    ),
                    Divider(),
                    Text('Write to Characteristic'),
                    TextField(
                      enabled: selectedCharacteristic != null && (selectedCharacteristic.properties.write || selectedCharacteristic.properties.writeWithoutResponse),
                      onSubmitted: (text) async {
                        try {
                          await selectedDevice.writeCharacteristic(selectedCharacteristic, text.split(',').map((x) => int.parse(x)).toList());
                          Scaffold.of(context).showSnackBar(SnackBar(content: Text('Wrote characteristic'),));
                        }
                        catch (e) {
                          Scaffold.of(context).showSnackBar(SnackBar(content: Text(e.toString()),));
                        }
                      },
                    ),
                    Divider(),
                    Text('Read from Characteristic'),
                    Text(readFromCharacteristic.toString()),
                    Divider(),
                    Text('Write to Descriptor'),
                    TextField(
                      enabled: selectedDescriptor != null,
                      onSubmitted: (text) async {
                        try {
                          await selectedDevice.writeDescriptor(selectedDescriptor, text.split(',').map((x) => int.parse(x)).toList());
                          Scaffold.of(context).showSnackBar(SnackBar(content: Text('Wrote descriptor'),));
                        }
                        catch (e) {
                          Scaffold.of(context).showSnackBar(SnackBar(content: Text(e.toString()),));
                        }
                      },
                    ),
                    Divider(),
                    Text('Read from Descriptor'),
                    Text(readFromDescriptor.toString()),
                    SizedBox(
                      height: 100.0,
                    )
                  ]
                )
                )
              )
          )
        )
    );
  }

  List<ListTile> _buildDeviceList() {
    List<ListTile> _list = new List();
    devices.forEach((k, v) {
      String _title = v.advertisementData.localName;
      _title = _title == '' ? v.device.name : _title;
      _title = _title == '' ? v.device.id.id : _title;
      _title = _title == '' ? v.device.id.toString() : _title;
      _list.add(ListTile(
        title: Text(_title),
        subtitle: (_title == v.device.id.toString() ? null : Text(v.device.id.toString())),
        trailing: (v.device == selectedDevice ?  (deviceServices == null ? CircularProgressIndicator() : Icon(Icons.check)) : null),
        onTap: () {
          setState(() {
            scanSubscription?.cancel();
            scanSubscription = null;
            deviceConnection?.cancel();
            deviceConnection = null;
            selectedDevice = v.device;
            gSelectedDevice = selectedDevice;
            deviceServices = null;
            selectedService = null;
            selectedCharacteristic = null;
            selectedDescriptor = null;
            deviceConnection = flutterBlue.connect(v.device).listen((s) {

              if (s == BluetoothDeviceState.connected) {
                print('connected!');
              }
              selectedDevice.discoverServices().then((list) {
                print('services discovered');
                deviceServices = list;
                setState(() {

                });
              });
            });
          });
        },
      ));
    });
    return _list;
  }

  List<ListTile> _buildServiceList() {
    if (deviceServices == null) {
      return new List();
    }
    List<ListTile> _list = new List();
    for (BluetoothService bs in deviceServices) {
      _list.add(ListTile(
        title: Text('0x${bs.uuid.toString().toUpperCase().substring(4, 8)}'),
        trailing: (bs == selectedService ? Icon(Icons.check) : null),
        onTap: () {
          selectedCharacteristic = null;
          selectedDescriptor = null;
          selectedService = bs;
          setState(() {

          });
        },
      ));
    }
    return _list;
  }

  List<ListTile> _buildCharacteristicList() {
    if (selectedService == null) {
      return new List();
    }
    List<ListTile> _list = new List();
    for (BluetoothCharacteristic bc in selectedService.characteristics) {
      _list.add(ListTile(
        trailing: 
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon((bc == selectedCharacteristic) ? Icons.check : null),
              RaisedButton(
                child: Icon(Icons.arrow_downward),
                onPressed: ((bc.properties.read) ? () async {
                  readFromCharacteristic = await selectedDevice.readCharacteristic(bc);
                  //Scaffold.of(context).showSnackBar(SnackBar(content: Text(('Read from characteristic'))));
                  setState(() {

                  });
                } : null),
              )
            ]
          ),
        title: Text('0x${bc.uuid.toString().toUpperCase().substring(4, 8)}'),
        onTap: () {
          selectedDescriptor = null;
          selectedCharacteristic = bc;
          gSelectedCharacteristic = bc;
          setState(() {

          });
        },
      ));
    }
    return _list;
  }

  List<ListTile> _buildDescriptorList(context) {
    if (selectedCharacteristic == null) {
      return new List();
    }
    List<ListTile> _list = new List();
    for (BluetoothDescriptor bd in selectedCharacteristic.descriptors) {
      _list.add(ListTile(
        title: Text(bd.uuid.toString()),
        trailing: (selectedDescriptor == bd ? Icon(Icons.check) : null),
        onTap: () {
          setState(() {
            selectedDescriptor = bd;
          });
          
          
          //Scaffold.of(context).showSnackBar(SnackBar(content: Text('DESCRIPTOR'),));
        },
        onLongPress: () {
          selectedDevice.readDescriptor(bd).then((list) {
            setState(() {
              readFromDescriptor = list;
            });
            Scaffold.of(context).showSnackBar(SnackBar(content: Text(('Read from descriptor'))));
          });
        },
      ));
    }
    return _list;
  }
}

class ReadDataScreen extends StatefulWidget {
  @override
  ReadDataScreenState createState() => ReadDataScreenState();
}

class ReadDataScreenState extends State<ReadDataScreen> {
  Timer readTimer;
  int steps = 0;
  bool readFromBluetooth = false;
  bool tryReading = false;
  int stepsDiff = 0;
  bool lastReadFinished = true;
  
  
  void readSteps(Timer t) {
    print("timer elapsed");
    if (!readFromBluetooth) {
      setState(() {
        steps = stepcount;
      });
    }
    else {
      try {
        if (lastReadFinished) {
          setState(() {
            lastReadFinished = false;
            gSelectedDevice.readCharacteristic(gSelectedCharacteristic).then((l) {
              steps = Uint8List.fromList(l).buffer.asByteData().getUint32(0) + stepsDiff;
              lastReadFinished = true;
            });
          });
        }
      }
      catch(e) {
        setState(() {
          steps = -333;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Read data"),
      ),
      drawer: MyDrawer(),
      body: Center(
        child: Column(
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
              child: Text(readTimer != null ? "Stop timer" : "Start timer"),
              onPressed: () {
                setState( () {
                  if (readTimer == null) {
                    readTimer = new Timer.periodic(Duration(milliseconds: 50), readSteps);
                    print('timer started');
                  }
                  else if (readTimer != null) {
                    readTimer.cancel();
                    readTimer = null;
                  }
                });
              },
            ),
            Text(
              steps.toString(),
              style: TextStyle(
                fontSize: 72,
              )
            ),
            RaisedButton(
              child: Text('Step'),
              onPressed: () {
                stepcount++;
              },
            ),
            RaisedButton(
              child: Text('Reset count'),
              onPressed: () {
                setState(() {
                  stepsDiff = stepsDiff - steps;
                  steps = 0;
                });
              },
            )
          ],
        )
      ),
    );
  }
}

class MyDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: <Widget>[
          DrawerHeader(
            child: Text('ShoeStep'),
          ),
          ListTile(
            title: Text('Home'),
            onTap: () {
              Navigator.popAndPushNamed(context, '/');
            },
          ),
          ListTile(
            title: Text('Saved'),
            onTap: () {
              Navigator.popAndPushNamed(context, '/saved');
            },
          ),
          ListTile(
            title: Text('Bluetooth'),
            onTap: () {
              Navigator.popAndPushNamed(context, '/connect');
            }
          ),
          ListTile(
            title: Text('Read Data'),
            onTap: () {
              Navigator.popAndPushNamed(context, '/read');
            }
          )
        ],
      ),
    );
  }
}