import 'package:bus_management/widgets/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class DirectionDetailScreen extends StatefulWidget {
  final List<dynamic> directionDetail;
  String startLocation = '';
  String endLocation = '';
  String fare = '';

  DirectionDetailScreen(
      {Key? key,
      required this.directionDetail,
      required this.startLocation,
      required this.endLocation,
      required this.fare})
      : super(key: key);
  @override
  _DirectionDetailScreenState createState() => _DirectionDetailScreenState();
}

class _DirectionDetailScreenState extends State<DirectionDetailScreen> {
  @override
  Widget build(BuildContext context) {
    List directionDetail = widget.directionDetail;
    String startLocation = widget.startLocation;
    String endLocation = widget.endLocation;
    String fare = widget.fare;

    DateTime currentTime = DateTime.now();
    int duration = int.parse(
        RegExp(r'\d+').stringMatch(directionDetail[0]["duration"]) ?? "0");
    DateTime arrivalTime = currentTime.add(Duration(seconds: duration));
    String arrivalTimeString =
        '${arrivalTime.hour.toString().padLeft(2, '0')}:${arrivalTime.minute.toString().padLeft(2, '0')}';
    String currentTimeString =
        '${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}';
    String combinedTimeString = '$currentTimeString - $arrivalTimeString ';
    String travelTimeInMinutes = (duration / 60).toStringAsFixed(0);
    travelTimeInMinutes = '(${travelTimeInMinutes} p)';

    List<dynamic> steps = directionDetail[0]['steps'];

    String startStationInstruction = '';
    String busStopDepartureTime = '';
    List<dynamic> transitSteps = [];
    List<dynamic> transitStepsDetail = [];
    int walkDuration = 0;

    for (var step in steps) {
      if (step['travelMode'] == 'TRANSIT') {
        busStopDepartureTime = step['transitDetails']['localizedValues']
            ['departureTime']['time']["text"];
        startStationInstruction =
            step['transitDetails']['stopDetails']['departureStop']['name'];
        break;
      }
    }

    for (var step in steps) {
      if (step['travelMode'] == 'WALK') {
        int durationInSeconds =
            int.tryParse(step['staticDuration'].replaceAll('s', '')) ?? 0;
        walkDuration += durationInSeconds;
      }
    }

    for (var step in steps) {
      String name = 'WALK';
      if (transitSteps.isEmpty) {
        if (step['travelMode'] == 'TRANSIT') {
          name = step['transitDetails']['transitLine']['nameShort'];
        }
        Object travelInformation = {
          "travelMode": step['travelMode'],
          "name": name
        };
        transitSteps.add(travelInformation);
      } else {
        if (step['travelMode'] != transitSteps.last['travelMode']) {
          name = 'WALK';
          if (step['travelMode'] == 'TRANSIT') {
            name = step['transitDetails']['transitLine']['nameShort'];
          }
          Object travelInformation = {
            "travelMode": step['travelMode'],
            "name": name
          };
          transitSteps.add(travelInformation);
        } else {
          if (step['travelMode'] == 'TRANSIT') {
            name = step['transitDetails']['transitLine']['nameShort'];
            Object travelInformation = {
              "travelMode": step['travelMode'],
              "name": name
            };
            transitSteps.add(travelInformation);
          }
        }
      }
    }

    for (int i = 0; i < steps.length; i++) {
      if (transitStepsDetail.isEmpty) {
        Object data = {"time": currentTimeString, "location": startLocation};
        transitStepsDetail.add(data);
        i--;
      } else {
        if (steps[i]['travelMode'] == 'WALK') {
          int durationInSeconds =
              int.tryParse(steps[i]['staticDuration'].replaceAll('s', '')) ?? 0;

          int distance = steps[i]['distanceMeters'];
          transitStepsDetail.add({
            "walkTime": durationInSeconds,
            "distance": distance,
            "travelMode": steps[i]['travelMode']
          });
        } else if (steps[i]['travelMode'] == 'TRANSIT') {
          String departureTime = steps[i]['transitDetails']['localizedValues']
              ['departureTime']['time']["text"];
          String arrivalTime = steps[i]['transitDetails']['localizedValues']
              ['arrivalTime']['time']["text"];
          String departureStop = steps[i]['transitDetails']['stopDetails']
              ['departureStop']['name'];
          String arrivalStop =
              steps[i]['transitDetails']['stopDetails']['arrivalStop']['name'];
          String busNumber =
              steps[i]['transitDetails']['transitLine']['nameShort'];
          String headsign = steps[i]['transitDetails']['headsign'];
          int durationInSeconds =
              int.tryParse(steps[i]['staticDuration'].replaceAll('s', '')) ?? 0;
          int timeMinites = (durationInSeconds / 60).round();
          int stopCount = steps[i]['transitDetails']['stopCount'];
          String travelMode = steps[i]['travelMode'];

          transitStepsDetail.add({
            "departureTime": departureTime,
            "arrivalTime": arrivalTime,
            "departureStop": departureStop,
            "arrivalStop": arrivalStop,
            "busNumber": busNumber,
            "headsign": headsign,
            "timeMinites": timeMinites,
            "stopCount": stopCount,
            "travelMode": travelMode
          });
        }
      }
    }

    Object destinationData = {
      "time": arrivalTimeString,
      "location": endLocation,
      "fare": fare
    };

    transitStepsDetail.add(destinationData);

    for (int i = 1; i < transitStepsDetail.length - 1; i++) {
      if (transitStepsDetail[i]['travelMode'] == 'WALK') {
        for (int j = i + 1; j < transitStepsDetail.length - 1; j++) {
          if (transitStepsDetail[j]['travelMode'] == 'WALK') {
            transitStepsDetail[i]['walkTime'] +=
                (transitStepsDetail[i]['walkTime'] as int);
            transitStepsDetail[i]['distance'] +=
                (transitStepsDetail[i]['distance'] as int);
          } else {
            i = j - 1;
            break;
          }
        }
      }
    }

    for (int i = 1; i < transitStepsDetail.length - 1; i++) {
      if (transitStepsDetail[i]['travelMode'] == 'WALK') {
        for (int j = i + 1; j < transitStepsDetail.length - 1; j++) {
          if (transitStepsDetail[j]['travelMode'] == 'WALK') {
            transitStepsDetail.removeAt(j);
            j--;
          } else {
            i = j - 1;
            break;
          }
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'từ ',
                    style: TextStyle(fontWeight: FontWeight.w300, fontSize: 14),
                  ),
                  Expanded(
                    child: Text(
                      startLocation,
                      style: TextStyle(fontSize: 14, color: Colors.black),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    'đến ',
                    style: TextStyle(fontWeight: FontWeight.w300, fontSize: 14),
                  ),
                  Expanded(
                    child: Text(
                      endLocation,
                      style: TextStyle(fontSize: 14, color: Colors.black),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          )),
      body:
          // Column for the header and the list of
          // timeline tiles for the direction details
          Column(
        children: <Widget>[
          routeDetailHeader(
              combinedTimeString,
              travelTimeInMinutes,
              busStopDepartureTime,
              startStationInstruction,
              transitSteps,
              fare,
              walkDuration),
          SizedBox(
            height: 16,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  ...getRouteTimeLineWidget(transitStepsDetail)
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}