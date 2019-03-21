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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ShoeStep'),
      ),
      drawer: MyDrawer(),
      floatingActionButton: FloatingActionButton(
        heroTag: 'walkTag',
        backgroundColor: Colors.red,
        child: Icon(Icons.directions_walk),
        onPressed: () {
          Navigator.push(context, PageRouteBuilder(
            transitionDuration: Duration(milliseconds: 500),
              pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
                return WorkoutScreen();
              },
              transitionsBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
                return AnimatedBuilder(
                  child: child,
                  animation: animation,
                  builder: (BuildContext context, Widget child) {
                    return ClipOval(
                      clipper: ScaleClipper(Offset(350, 690), animation.value*1000),
                      child: child,
                    );
                  },
                );
              }
          ));
        },
      ),
      body: Center(

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget> [
            Container(
              decoration: BoxDecoration(
                border: Border.all(width: 2.0, color: Colors.red),
              ),
              child: ButtonBar(

                children: <Widget>[
                  FlatButton(
                    child: Text('one'),
                    color: Colors.red,
                    onPressed: () {
                      print('a');
                    },
                  ),
                  FlatButton(
                    child: Text('two'),
                  ),
                  FlatButton(
                    child: Text('three'),
                  ),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.all(10.0),
              child: SizedBox(
                height: 300.0,
                child: FutureBuilder(
                  future: database.query('StepCounts'),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return charts.LineChart(
                        <charts.Series<dynamic, int>>[
                          new charts.Series<dynamic, int>(
                            id: 'Sales',
                            colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
                            dashPatternFn: (_, __) => [2, 2],
                            domainFn: (row, _) => row['id'],
                            measureFn: (row, _) => row['steps'],
                            data: snapshot.data,
                          )
                        ],
                        animate: true,
                        defaultRenderer: new charts.LineRendererConfig(includePoints: true),
                      );
                    }
                    else {
                      return Text('No Data');
                    }
                  }
                )
              ),
            )
          ],
        ),
      ),
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
}

class SimpleTimeSeriesChart extends StatelessWidget {
  final List<charts.Series> seriesList;
  final bool animate;

  SimpleTimeSeriesChart(this.seriesList, {this.animate});

  /// Creates a [TimeSeriesChart] with sample data and no transition.
  factory SimpleTimeSeriesChart.withSampleData() {
    return new SimpleTimeSeriesChart(
      _createSampleData(),
      // Disable animations for image tests.
      animate: true,
    );
  }


  @override
  Widget build(BuildContext context) {
    return new charts.TimeSeriesChart(
      seriesList,
      animate: animate,
      // Optionally pass in a [DateTimeFactory] used by the chart. The factory
      // should create the same type of [DateTime] as the data provided. If none
      // specified, the default creates local date time.
      dateTimeFactory: const charts.LocalDateTimeFactory(),
      defaultRenderer: new charts.LineRendererConfig(includePoints: true),
    );
  }

  /// Create one series with sample hard coded data.
  static List<charts.Series<TimeSeriesSales, DateTime>> _createSampleData() {
    final data = [
      new TimeSeriesSales(new DateTime(2017, 9, 19), 5),
      new TimeSeriesSales(new DateTime(2017, 9, 26), 25),
      new TimeSeriesSales(new DateTime(2017, 10, 3), 100),
      new TimeSeriesSales(new DateTime(2017, 10, 10), chartCount),
    ];

    return [
      new charts.Series<TimeSeriesSales, DateTime>(
        id: 'Sales',
        colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
        domainFn: (TimeSeriesSales sales, _) => sales.time,
        measureFn: (TimeSeriesSales sales, _) => sales.sales,
        data: data,
      )
    ];
  }
}

/// Sample time series data type.
class TimeSeriesSales {
  final DateTime time;
  final int sales;

  TimeSeriesSales(this.time, this.sales);
}