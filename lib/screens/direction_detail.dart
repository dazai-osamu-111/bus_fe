import 'package:bus_management/widgets/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class DirectionDetailScreen extends StatefulWidget {
  final List<dynamic> directionDetail;
  String startLocation = '';
  String endLocation = '';

  DirectionDetailScreen(
      {Key? key,
      required this.directionDetail,
      required this.startLocation,
      required this.endLocation})
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
    for (var step in steps) {
      if (step['travelMode'] == 'TRANSIT') {
        busStopDepartureTime =
            step['transitDetails']['stopDetails']['arrivalTime'];
        String timePart = busStopDepartureTime.split('T')[1];
        busStopDepartureTime = timePart.substring(0, 5);
        startStationInstruction =
            step['transitDetails']['stopDetails']['departureStop']['name'];
        break;
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
      }
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
      }
    }
    return Scaffold(
      appBar: AppBar(
          title: RichText(
            text: TextSpan(
              style: TextStyle(
                  fontSize: 14,
                  color: Colors
                      .black), // Chỉ định kích thước chung cho toàn bộ text
              children: <TextSpan>[
                TextSpan(
                    text: 'từ ', style: TextStyle(fontWeight: FontWeight.w300)),
                TextSpan(
                  text: startLocation + '\n',
                ),
                TextSpan(
                    text: 'đến ',
                    style: TextStyle(fontWeight: FontWeight.w300)),
                TextSpan(text: endLocation)
              ],
            ),
            overflow: TextOverflow.ellipsis, // Thêm để ngăn chặn overflow
            maxLines: 2, // Giới hạn số dòng hiển thị
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
          routeDetailHeader(combinedTimeString, travelTimeInMinutes,
              busStopDepartureTime, startStationInstruction, transitSteps),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  timeLineTile('16:12', '20.9504306, 105.8407726',
                      Icons.directions_walk, 'Khoảng 10 p, 750 m'),
                  timeLineTile('16:22', '20.9504306, 105.8407726',
                      Icons.directions_bus, 'Khoảng 10 p, 750 m'),
                  timeLineTile('16:32', '20.9504306, 105.8407726',
                      Icons.directions_walk, 'Khoảng 10 p, 750 m'),
                  timeLineTile('16:42', '20.9504306, 105.8407726',
                      Icons.directions_bus, 'Khoảng 10 p, 750 m'),
                  timeLineTile('16:52', '20.9504306, 105.8407726',
                      Icons.directions_walk, 'Khoảng 10 p, 750 m'),
                ],
              ),
            ),
          )

          // directionDetailList(),
        ],
      ),
    );
  }

  Widget routeDetailHeader(
      String combinedTimeString,
      String travelTimeInMinutes,
      String busStopDepartureTime,
      String startStationInstruction,
      List<dynamic> transitSteps) {
    // get current time and directionDetail["duration"] to calculate the arrival time, convert to string

    return Padding(
      padding: EdgeInsets.all(0),
      child: Card(
        // elevation: 4.0, // Độ cao của shadow
        color: Colors.white, // Màu nền của thẻ
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero, // Bo tròn các góc
        ),
        child: Container(
          width: 400, // max size of the card
          padding: EdgeInsets.all(16.0), // Padding bên trong thẻ
          child: Column(
            mainAxisSize:
                MainAxisSize.min, // Đảm bảo column chiếm không gian tối thiểu
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment
                    .spaceBetween, // Căn lề các phần tử ở hai bên
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        combinedTimeString,
                        style: TextStyle(fontSize: 20),
                      ),
                      Text(
                        travelTimeInMinutes,
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w300),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.directions_walk, size: 20), // Biểu tượng xe
                      SizedBox(width: 5), // Khoảng cách giữa các icon
                      Icon(Icons.directions_bus, size: 20), // Biểu tượng bus
                    ],
                  ),
                ],
              ),
              get_direction_summary_widget(transitSteps),
              Row(
                children: [
                  Expanded(
                    child: Text(
                        '${busStopDepartureTime} từ ${startStationInstruction}',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w300)),
                  ),
                ],
              ),
              SizedBox(height: 4), // Khoảng cách nhỏ hơn
              Row(
                mainAxisAlignment: MainAxisAlignment
                    .spaceBetween, // Căn chỉnh các phần tử ở hai bên
                children: [
                  Text('7.000 đ • 13 p',
                      style: TextStyle(fontSize: 14, color: Colors.black54)),
                  Text('mỗi 15 phút',
                      style: TextStyle(fontSize: 14, color: Colors.black54)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget timeLineTile(
      String time, String location, IconData icon, String detail) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Column for the timeline dots
          Column(
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                width: 20,
                height: 20,
              ),
              Container(
                height: 50, // Adjust the height to control space between dots
                width: 2,
                color: Colors.blue,
              ),
              Icon(Icons.directions_walk, color: Colors.blue),
              Container(
                height: 30, // Adjust the height to control space between dots
                width: 2,
                color: Colors.blue,
              ),
              // Container(
              //   decoration: BoxDecoration(
              //     color: Colors.blue,
              //     shape: BoxShape.circle,
              //   ),
              //   width: 20,
              //   height: 20,
              // ),
            ],
          ),
          // Expanded Column for the text next to the timeline
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '16:12   20.9504306, 105.8407726',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Đi bộ',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Khoảng 10 p, 750 m',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
