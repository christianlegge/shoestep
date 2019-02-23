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
  BluetoothDescriptor selectedDescriptor;
  List<int> readFromDescriptor;


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
                    Text('Characteristics'),
                    Column(
                      children: _buildCharacteristicList(),
                    ),
                    Divider(),
                    Text('Descriptors (long press to read from)'),
                    Column(
                      children: _buildDescriptorList(context),
                    ),
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
        subtitle: Text(v.device == selectedDevice ? 'Selected' : ''),
        onTap: () {
          setState(() {
            scanSubscription?.cancel();
            scanSubscription = null;
            deviceConnection?.cancel();
            deviceConnection = null;
            selectedDevice = v.device;
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
        title: Text(bs.uuid.toString()),
        subtitle: Text(bs == selectedService ? 'Selected' : ''),
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
        subtitle: Text(bc == selectedCharacteristic ? 'Selected' : ''),
        title: Text(bc.uuid.toString()),
        onTap: () {
          selectedDescriptor = null;
          selectedCharacteristic = bc;
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
        subtitle: Text(selectedDescriptor == bd ? 'Selected' : ''),
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