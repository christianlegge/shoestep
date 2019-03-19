import 'dart:async';
import 'dart:core';
import 'dart:developer';
import 'dart:typed_data';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';

class WorkoutScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => WorkoutScreenState();
}

class WorkoutScreenState extends State<WorkoutScreen> {
  int currentSteps = 0;
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
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
            RaisedButton(
              child: Text('Step'),
              onPressed: () {
                setState(() {
                  currentSteps++;
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
          Navigator.pop(context);
        },
      ),
    );
  }
}