import 'dart:convert';
import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';

import 'package:bus_management/screens/direction_detail.dart';
import 'package:bus_management/widgets/utils.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

class GetDirectionScreen extends StatefulWidget {
  @override
  _GetDirectionScreen createState() => _GetDirectionScreen();
}

class _GetDirectionScreen extends State<GetDirectionScreen> {
  late GoogleMapController mapController;
  List<Marker> autoCompleteMarker = [];
  TextEditingController _textEditingController1 = TextEditingController();
  TextEditingController _textEditingController2 = TextEditingController();
  FocusNode _focusNode1 = FocusNode();
  FocusNode _focusNode2 = FocusNode();
  bool isShowPlaces = false;
  bool isShowBusSchedule = false;
  List<BusSchedule> schedules = [
    // create a list of BusSchedule
  ];

  @override
  void initState() {
    super.initState();
    _focusNode1.addListener(() {
      if (_focusNode1.hasFocus && _textEditingController1.text.isEmpty) {
        _suggestCurrentLocation();
      }
    });
    _focusNode2.addListener(() {
      if (_focusNode2.hasFocus && _textEditingController2.text.isEmpty) {
        _suggestCurrentLocation();
      }
    });
    _textEditingController1.addListener(() {
      if (_textEditingController1.text.isEmpty) {
        _suggestCurrentLocation();
      }
    });
    _textEditingController2.addListener(() {
      if (_textEditingController2.text.isEmpty) {
        _suggestCurrentLocation();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tìm đường',
            style: TextStyle(
              color: Colors.white,
            )),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            child: Column(
              children: [
                SizedBox(
                  height: 40,
                  child: TextField(
                    focusNode: _focusNode1,
                    controller: _textEditingController1,
                    onChanged: (String placeText) {
                      if (placeText.isEmpty) {
                        _suggestCurrentLocation();
                      } else {
                        isShowPlaces = true;
                        isShowBusSchedule = false;
                        getAutocompletePlaces(placeText);
                      }
                    },
                    // Thay thế bằng controller của bạn
                    decoration: const InputDecoration(
                      labelText: "Điểm đi",
                      fillColor: Colors.white, // Màu nền trắng
                      filled: true, // Kích hoạt nền màu
                      prefixIcon: Icon(Icons.location_on, color: Colors.blue),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 5,
                ),
                SizedBox(
                  height: 40,
                  child: TextField(
                    onChanged: (String placeText) {
                      if (placeText.isEmpty) {
                        _suggestCurrentLocation();
                      } else {
                        isShowPlaces = true;
                        isShowBusSchedule = false;
                        getAutocompletePlaces(placeText);
                      }
                    },
                    focusNode: _focusNode2,
                    controller: _textEditingController2,
                    // Thay thế bằng controller của bạn
                    decoration: const InputDecoration(
                      labelText: "Điểm đến",
                      fillColor: Colors.white, // Màu nền trắng
                      filled: true, // Kích hoạt nền màu
                      prefixIcon: Icon(Icons.location_on, color: Colors.red),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(
            // Đây là đường phân cách
            color: Colors.grey,
            thickness: 1, // Độ dày của đường phân cách
          ),
          Visibility(
            visible: isShowPlaces,
            child: Flexible(
                child: ListView.builder(
              itemCount: autoCompleteMarker.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    autoCompleteMarker[index].markerId.value,
                  ),
                  onTap: () {
                    if (_focusNode1.hasFocus) {
                      _textEditingController1.text =
                          autoCompleteMarker[index].markerId.value;
                      _textEditingController1.selection =
                          TextSelection.fromPosition(TextPosition(
                              offset: _textEditingController1.text.length));
                    } else if (_focusNode2.hasFocus) {
                      _textEditingController2.text =
                          autoCompleteMarker[index].markerId.value;
                      _textEditingController2.selection =
                          TextSelection.fromPosition(TextPosition(
                              offset: _textEditingController2.text.length));
                    }
                    isShowPlaces = false;
                    setState(() {
                      autoCompleteMarker = [];
                    });
                    getDirection(_textEditingController1.text,
                        _textEditingController2.text);
                  },
                );
              },
            )),
          ),
          Visibility(
            visible: isShowBusSchedule,
            child: Flexible(
              child: ListView.builder(
                itemCount: schedules.length,
                itemBuilder: (context, index) {
                  return BusScheduleCard(schedule: schedules[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void getAutocompletePlaces(String placeText) async {
    var url = Uri.https(
        'maps.googleapis.com', '/maps/api/place/autocomplete/json', {
      'input': placeText,
      'key': 'AIzaSyAnI_7dbzhe2FS7kr1lXvqXId2AIBvUXB8'
    }); // Replace 'YOUR_API_KEY_HERE' with your actual API key
    var response = await http.get(url);
    if (response.statusCode == 200) {
      setState(() {
        autoCompleteMarker =
            (jsonDecode(response.body)['predictions'] as List).map((e) {
          var marker = Marker(
            markerId: MarkerId(e['description']),
            // position: LatLng(e)
          );
          return marker;
        }).toList();
      });
    } else {
      throw Exception('Failed to load predictions');
    }
  }

  void getDirection(String place1, String place2) async {
    String startLocationText = place1;
    String endLocationText = place2;
    if (place1.isEmpty || place2.isEmpty) {
      return;
    }
    if (place1 == 'Vị trí hiện tại') {
      var permission = await Permission.location.request();
      if (permission.isGranted) {
        var position = await Geolocator.getCurrentPosition();
        List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          place1 =
              '${placemarks.first.street}, ${placemarks.first.locality}, ${placemarks.first.country}';
        }
      }
    }

    if (place2 == 'Vị trí hiện tại') {
      var permission = await Permission.location.request();
      if (permission.isGranted) {
        var position = await Geolocator.getCurrentPosition();
        List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          place2 =
              '${placemarks.first.street}, ${placemarks.first.locality}, ${placemarks.first.country}';
        }
      }
    }
    try {
      var url =
          Uri.https('routes.googleapis.com', '/directions/v2:computeRoutes');
      var response = await http.post(url,
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': 'AIzaSyAnI_7dbzhe2FS7kr1lXvqXId2AIBvUXB8',
            'X-Goog-FieldMask': 'routes.*',
          },
          body: jsonEncode({
            "origin": {"address": place1},
            "destination": {"address": place2},
            "travelMode": "TRANSIT",
            "computeAlternativeRoutes": true
          }));
      if (response.statusCode == 200) {
        setState(() {
          schedules =
              (jsonDecode(response.body)["routes"] as List).map((route) {
            String encodePolyline = route["polyline"]["encodedPolyline"];
            DateTime currentTime = DateTime.now();
            var durationText = route["localizedValues"]["duration"]["text"];
            var duration = int.parse(durationText.split(" ")[0]);
            var endTime = currentTime.add(Duration(minutes: duration));
            var transitIndex = route["legs"][0]["stepsOverview"]
                    ["multiModalSegments"]
                .where((element) => element["travelMode"] == "TRANSIT")
                .toList();
            var stepStartTransitIndex = transitIndex[0]["stepStartIndex"];
            var busNumber = route["legs"][0]["steps"][stepStartTransitIndex]
                ["transitDetails"]["transitLine"]["nameShort"];
            var startLocation = route["legs"][0]["steps"][stepStartTransitIndex]
                ["transitDetails"]["stopDetails"]["departureStop"]["name"];

            return BusSchedule(
              time:
                  '${currentTime.hour}:${currentTime.minute} - ${endTime.hour}:${endTime.minute}',
              duration: durationText,
              busNumber: busNumber ?? '',
              departure: startLocation,
              fare: route["localizedValues"]["transitFare"]["text"],
              detail: route["legs"],
              startLocation: startLocationText,
              endLocation: endLocationText,
              encodePolyline: encodePolyline,
            );
          }).toList();
        });
        isShowBusSchedule = true;
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void _suggestCurrentLocation() async {
    setState(() {
      autoCompleteMarker = [
        Marker(
          markerId: const MarkerId('Vị trí hiện tại'),
        )
      ];
      isShowPlaces = true;
    });
  }

  @override
  void dispose() {
    _focusNode1.dispose();
    _focusNode2.dispose();
    _textEditingController1.dispose();
    _textEditingController2.dispose();
    super.dispose();
  }
}

class BusSchedule {
  final String time;
  final String duration;
  final String busNumber;
  final String departure;
  final String fare;
  final List<dynamic> detail;
  final String startLocation;
  final String endLocation;
  final String encodePolyline;

  BusSchedule(
      {required this.time,
      required this.duration,
      required this.busNumber,
      required this.departure,
      required this.fare,
      required this.detail,
      required this.startLocation,
      required this.endLocation,
      required this.encodePolyline});
}

class BusScheduleCard extends StatelessWidget {
  final BusSchedule schedule;

  BusScheduleCard({required this.schedule});

  @override
  Widget build(BuildContext context) {
    DateTime currentTime = DateTime.now();
    int duration = int.parse(
        RegExp(r'\d+').stringMatch(schedule.detail[0]["duration"]) ?? "0");
    DateTime arrivalTime = currentTime.add(Duration(seconds: duration));
    String arrivalTimeString =
        '${arrivalTime.hour.toString().padLeft(2, '0')}:${arrivalTime.minute.toString().padLeft(2, '0')}';
    String currentTimeString =
        '${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}';
    String combinedTimeString = '$currentTimeString - $arrivalTimeString ';
    String travelTimeInMinutes = (duration / 60).toStringAsFixed(0);
    travelTimeInMinutes = '(${travelTimeInMinutes} p)';

    List<dynamic> steps = schedule.detail[0]['steps'];

    String startStationInstruction = '';
    String busStopDepartureTime = '';
    List<dynamic> transitSteps = [];
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

    walkDuration = (walkDuration / 60).round();

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
          padding: EdgeInsets.only(
              top: 16.0,
              right: 16.0,
              left: 16.0,
              bottom: 0), // Padding bên trong thẻ
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
              getDirectionSummaryWidget(transitSteps),
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(schedule.fare,
                          style:
                              TextStyle(fontSize: 14, color: Colors.black54)),
                      SizedBox(width: 24),
                      Icon(Icons.directions_walk, size: 16),
                      Text(
                        '${walkDuration} p',
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      textStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => DirectionDetailScreen(
                                  directionDetail: schedule.detail,
                                  startLocation: schedule.startLocation,
                                  endLocation: schedule.endLocation,
                                  fare: schedule.fare,
                                  encodePolyline: schedule.encodePolyline,
                                )),
                      );
                    },
                    child: Text('Chi tiết'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    // return Card(
    //   child: Padding(
    //     padding: const EdgeInsets.all(8.0),
    //     child: Column(
    //       crossAxisAlignment: CrossAxisAlignment.start,
    //       children: [
    //         Text(schedule.time),
    //         Text(schedule.duration),
    //         Text(schedule.busNumber),
    //         Text(schedule.departure),
    //         Text(schedule.fare),
    //         Align(
    //           alignment: Alignment.centerRight,
    //           child: ElevatedButton(
    // onPressed: () {
    //   Navigator.push(
    //     context,
    //     MaterialPageRoute(
    //         builder: (context) => DirectionDetailScreen(
    //               directionDetail: schedule.detail,
    //               startLocation: schedule.startLocation,
    //               endLocation: schedule.endLocation,
    //               fare: schedule.fare,
    //             )),
    //   );
    // },
    //             child: Text('Chi tiết'),
    //           ),
    //         ),
    //       ],
    //     ),
    //   ),
    // );
  }
}
