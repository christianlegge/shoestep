import 'dart:async';
import 'dart:core';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_blue/flutter_blue.dart';

FlutterBlue flutterBlue = FlutterBlue.instance;

Database database;
String listph = '1';
int dbcount = 0;

Future<void> initDb() async {
  var databasesPath = await getDatabasesPath();
  String path = [databasesPath, '/demo.db'].join('');
  await deleteDatabase(path);
  database = await openDatabase(path, version: 1,
  onCreate: (Database db, int version) async {
    await db.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)');
    listph = '2';
  });
  dbcount = Sqflite.firstIntValue(await database.rawQuery('SELECT COUNT(*) FROM Test'));
}

void main() {
  initDb();
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShoeStep',
      initialRoute: '/',
      routes: {
        '/': (context) => BluetoothScreen(),
        '/saved': (context) => SavedScreen(),
        '/connect': (context) => BluetoothScreen(),
      },
      theme: new ThemeData(
        primaryColor: Colors.red,
        buttonColor: Colors.red,
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ShoeStep'),
      ),
      drawer: MyDrawer(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget> [
            Text(dbcount.toString()),
            TextField(
              decoration: InputDecoration(
                icon: Icon(Icons.accessible_forward),
              ),
              onSubmitted: (text) {
                database.insert('Test', {'id':dbcount, 'name':text});
                dbcount++;

              },
            ),
            Icon(Icons.ac_unit),
          ],
        ),
      ),
    );
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
    List rows = (await database.query('Test')).toList();
    List<ListTile> list = new List();
    for (int i = 0; i < rows.length; i++) {
      list.add(new ListTile(
        title: Text(rows[i]['id'].toString() + ' ' + rows[i]['name'])
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


  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
        appBar: AppBar(
          title: Text('Bluetooth connect'),
        ),
        drawer: MyDrawer(),
        body: Padding(
          padding: EdgeInsets.all(8.0),
          child: Center(
            child: ListView(
              children: <Widget>[
                RaisedButton(
                  child: Text('Scan for devices'),
                  onPressed: scanning ? null : () {
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
                  },
                ),
                RaisedButton(
                  child: Text('Cancel'),
                  onPressed: scanning ? () {
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
                      scanning = false;
                    });
                  } : null),
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
                Text('Characteristics'),
                Column(
                  children: _buildCharacteristicList(),
                ),
                Divider(),
                Text('Descriptors'),
                Column(
                  children: _buildDescriptorList(),
                ),
              ]
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
        subtitle: Text(v.device == selectedDevice ? 'Selected' : ''),
        onTap: () {
          setState(() {
            scanSubscription?.cancel();
            scanSubscription = null;
            deviceConnection?.cancel();
            deviceConnection = null;
            selectedDevice = v.device;
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
        title: Text(bs.uuid.toString()),
        subtitle: Text(bs == selectedService ? 'Selected' : ''),
        onTap: () {
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
        subtitle: Text(bc == selectedCharacteristic ? 'Selected' : ''),
        title: Text(bc.uuid.toString()),
        onTap: () {
          selectedCharacteristic = bc;
          setState(() {

          });
        },
      ));
    }
    return _list;
  }

  List<ListTile> _buildDescriptorList() {
    if (selectedCharacteristic == null) {
      return new List();
    }
    List<ListTile> _list = new List();
    for (BluetoothDescriptor bd in selectedCharacteristic.descriptors) {
      _list.add(ListTile(
        title: Text(bd.uuid.toString()),
      ));
    }
    return _list;
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
          )
        ],
      ),
    );
  }
}