import 'dart:async';
import 'dart:core';
import 'dart:developer';
import 'dart:typed_data';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:flutter_shoestep/main.dart';

class WorkoutSummary {
  Duration duration;
  int steps;

  WorkoutSummary(this.duration, this.steps);
}

class SummaryScreen extends StatelessWidget {

  WorkoutSummary summaryData;

  SummaryScreen(this.summaryData);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Summary'),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(top: 32.0),
              child: Text('Congratulations!',
                style: TextStyle(
                  fontSize: 40.0,
                ),
              ),
            ),
            SizedBox(
              height: 150,
              width: 150,
              child: Stack(
                children: <Widget>[
                  Icon(Icons.fast_forward, size: 150, color: Colors.black12,),
                  Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Text('Steps Taken',
                              style: TextStyle(
                                fontSize: 16.0,
                              ),
                            ),
                            Text(summaryData.steps.toString(),
                              style: TextStyle(
                                fontSize: 24.0,
                              ),
                            ),
                          ],
                        ),
                      )
                  )
                ],
              ),
            ),
            SizedBox(
              height: 150,
              width: 250,
              child: Stack(
                children: <Widget>[
                  Center(
                    child: Icon(Icons.access_time, size: 150, color: Colors.black12,),
                  ),
                  Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Text('Duration',
                              style: TextStyle(
                                fontSize: 16.0,
                              ),
                            ),
                            Text(summaryData.duration.toString().substring(0, 11),
                              style: TextStyle(
                                fontSize: 24.0,
                              ),
                            ),
                          ],
                        ),
                      )
                  )
                ],
              ),
            ),
            SizedBox(
              height: 150,
              width: 250,
              child: Stack(
                children: <Widget>[
                  Center(
                    child: Icon(Icons.directions_walk, size: 150, color: Colors.black12,),
                  ),
                  Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Text('Average steps/minute',
                              style: TextStyle(
                                fontSize: 16.0,
                              ),
                            ),
                            Text((60*1000000*summaryData.steps/summaryData.duration.inMicroseconds).toStringAsPrecision(5),
                              style: TextStyle(
                                fontSize: 24.0,
                              ),
                            ),
                          ],
                        ),
                      )
                  )
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.only(top: 32.0),
              child: RaisedButton(
                child: Text('Done'),
                onPressed: () {
                  Navigator.pop(context);
                },
              )
            )


          ],
        )
      ),
    );
  }
}