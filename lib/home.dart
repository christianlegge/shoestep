/// Timeseries chart example
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:flutter_shoestep/main.dart';
import 'package:flutter_shoestep/workout.dart';
import 'package:sqflite/sqflite.dart';

int chartCount = 60;


class HomeScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {

  bool isConnected = true;
  int selectedDomain = 365;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        precacheImage(AssetImage('assets/city.png'), context));
  }

  void _setState() {
    setState(() {

    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('ShoeStep'),
        ),
        drawer: MyDrawer(_setState),
        floatingActionButton: FloatingActionButton(
          heroTag: 'walkTag',
          backgroundColor: Colors.red,
          child: Icon(Icons.directions_walk),
          onPressed: () {
            Navigator.push(context, PageRouteBuilder(
                transitionDuration: Duration(milliseconds: 500),
                pageBuilder: (BuildContext context, Animation<double> animation,
                    Animation<double> secondaryAnimation) {
                  return WorkoutScreen();
                },
                transitionsBuilder: (BuildContext context,
                    Animation<double> animation,
                    Animation<double> secondaryAnimation, Widget child) {
                  return AnimatedBuilder(
                    child: child,
                    animation: animation,
                    builder: (BuildContext context, Widget child) {
                      return ClipOval(
                        clipper: ScaleClipper(
                            Offset(350, 690), animation.value * 1000),
                        child: child,
                      );
                    },
                  );
                }
            ));
          },
        ),
        body: Stack(
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment(0.0, 0.0),
                    colors: [Color.fromARGB(60, 0, 0, 0), Colors.transparent],
                  ),
                ),
              ),
              Center(
                child: Column(
                  children: <Widget>[
                    SizedBox(
                      height: 100.0,
                    ),
                    _ChartDomainSelector(),
                    Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Row(
                          children: <Widget>[
                            RotatedBox(
                              quarterTurns: 3, child: Text('Steps'),
                            ),
                            FutureBuilder(
                              future: database.rawQuery('select * from (select * from StepCounts order by id desc limit '+selectedDomain.toString()+') order by id asc'),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return SizedBox(
                                    height: 400.0,
                                    width: 350.0,
                                    child: charts.TimeSeriesChart(
                                      <charts.Series<dynamic, DateTime>>[
                                        new charts.Series<dynamic, DateTime>(
                                          id: 'Sales',
                                          colorFn: (_, __) =>
                                          charts.MaterialPalette.red.shadeDefault,
                                          dashPatternFn: (_, __) => [2, 2],
                                          domainFn: (row, _) {
                                            DateTime d = DateTime.parse(
                                                row['date']);
                                            return new DateTime(
                                                d.year, d.month, d.day);
                                          },
                                          measureFn: (row, _) => row['steps'],
                                          data: snapshot.data,
                                        )
                                      ],
                                      animate: true,
                                      defaultRenderer: new charts
                                          .LineRendererConfig(
                                          includePoints: true),
                                      domainAxis: new charts.DateTimeAxisSpec(
                                        renderSpec: new charts
                                            .SmallTickRendererSpec(
                                            labelStyle: new charts.TextStyleSpec(
                                              fontSize: 12,
                                            )
                                        ),
                                        tickFormatterSpec: new charts
                                            .AutoDateTimeTickFormatterSpec(
                                          minute: new charts.TimeFormatterSpec(
                                            format: 'MMM dd',
                                            transitionFormat: 'MMM dd',
                                          ),
                                          day: new charts.TimeFormatterSpec(
                                            format: 'MMM dd',
                                            transitionFormat: 'MMM dd',
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                else {
                                  return Text('No Data');
                                }
                              }
                          )
                        ]
                      )
                    ),
                    Text('Date'),
                  ],
                ),
              ),
            ]
        )
    );
  }

  Future<List<Widget>> listEntriesFromDb() async {
    List rows = (await database.query('StepCounts')).toList();
    List<ListTile> list = new List();
    for (int i = 0; i < rows.length; i++) {
      list.add(new ListTile(
          title: Text(
              rows[i]['id'].toString() + ' ' + rows[i]['steps'].toString())
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

  Widget _ChartDomainSelector() {
    return Center(
        child: Container(
          decoration: BoxDecoration(
              border: Border.all(width: 2.0, color: Colors.red),
              borderRadius: BorderRadius.all(Radius.circular(8.0))
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              GestureDetector(
                onTap: () {
                  setState(() {
                    selectedDomain = 7;
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    border: Border(right: BorderSide(style: BorderStyle.solid,
                        width: 2.0,
                        color: Colors.red)),
                    color: selectedDomain == 7 ? Colors.red : Colors
                        .transparent,
                  ),
                  child: Text('Week', style: TextStyle(fontSize: 16.0,
                      color: selectedDomain == 7 ? Colors.white : Colors.red),),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    selectedDomain = 30;
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    border: Border(right: BorderSide(style: BorderStyle.solid,
                        width: 2.0,
                        color: Colors.red)),
                    color: selectedDomain == 30 ? Colors.red : Colors
                        .transparent,
                  ),
                  child: Text('Month', style: TextStyle(fontSize: 16.0,
                      color: selectedDomain == 30 ? Colors.white : Colors.red),),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    selectedDomain = 365;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                      color: selectedDomain == 365 ? Colors.red : Colors
                          .transparent
                  ),
                  padding: EdgeInsets.all(8.0),
                  child: Text('Year', style: TextStyle(fontSize: 16.0,
                      color: selectedDomain == 365 ? Colors.white : Colors.red),),
                ),
              )
            ],
          ),
        )
    );
  }
}