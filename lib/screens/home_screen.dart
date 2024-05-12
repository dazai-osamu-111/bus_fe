import 'dart:async';
import 'dart:convert';

import 'package:bus_management/screens/get_direction.dart';
import 'package:bus_management/screens/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  static const CameraPosition _kGooglePlex = CameraPosition(
      target: LatLng(21.0054933764515, 105.84567100681808), zoom: 14);
  final List<Marker> _markers = <Marker>[];

  List _searchResults = []; // Khai báo biến _searchResults
  String _selectedOption = "";

  loadData() {
    getUserCurrentLocation().then((value) async {
      _markers.add(Marker(
          markerId: MarkerId('2'),
          position: LatLng(value.latitude, value.longitude),
          infoWindow: InfoWindow(title: 'My current location')));
      CameraPosition cameraPosition = CameraPosition(
          zoom: 14, target: LatLng(value.latitude, value.longitude));

      final GoogleMapController controller = await _controller.future;

      controller.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
      setState(() {
        _selectedOption = "X";
      });
    });
  }

  Future<Position> getUserCurrentLocation() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      // Quyền vị trí đã được cấp
      return await Geolocator.getCurrentPosition();
    } else {
      // Xử lý trường hợp quyền không được cấp
      throw Exception('Location permission denied');
    }
  }

  // Định nghĩa hàm _getDirections trong class _HomeScreenState
  void _getDirections(String from, String to) async {
    if (from.isEmpty || to.isEmpty) {
      // Hiển thị thông báo lỗi nếu địa điểm bắt đầu hoặc kết thúc không được nhập
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Please enter both start and destination points.')),
      );
      return;
    }

    String googleApiKey =
        'AIzaSyAnI_7dbzhe2FS7kr1lXvqXId2AIBvUXB8'; // Thay thế bằng API key hợp lệ của bạn
    String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$from&destination=$to&key=$googleApiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == 'OK') {
          // Lấy ra thông tin cần thiết từ dữ liệu JSON
          final routes = result['routes'][0];
          final legs = routes['legs'][0];
          final steps = legs['steps'] as List;

          // Tạo một danh sách các điểm để vẽ polyline
          final List<LatLng> polylinePoints = [];
          for (var step in steps) {
            final startLatLng = _convertToLatLng(step['start_location']);
            final endLatLng = _convertToLatLng(step['end_location']);
            polylinePoints.add(startLatLng);
            polylinePoints.add(endLatLng);
          }

          // Thêm polyline vào bản đồ
          final String polylineIdVal = 'polyline_${from}_${to}';
          final PolylineId polylineId = PolylineId(polylineIdVal);

          final Polyline polyline = Polyline(
            polylineId: polylineId,
            color: Colors.blue,
            points: polylinePoints,
            width: 5,
          );

          setState(() {
            // Thêm polyline mới vào danh sách các polylines hiện có trên bản đồ
            _polylines[polylineId] = polyline;
          });

          // Zoom bản đồ để hiển thị toàn bộ đường đi
          // Bạn có thể thêm logic để điều chỉnh zoom và vị trí camera tại đây
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Directions not found.')),
          );
        }
      } else {
        throw Exception('Failed to load directions');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  LatLng _convertToLatLng(Map<String, dynamic> json) {
    return LatLng(json['lat'], json['lng']);
  }

  // Trong class _HomeScreenState, thêm một biến để giữ các polylines
  Map<PolylineId, Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Ticket Bus',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.blue,
          centerTitle: true,
        ),
        body: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedOption = "X";
                      });
                      // Xử lý thêm khi chọn Theo dõi xe
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: _selectedOption == "X"
                            ? Border(
                                bottom:
                                    BorderSide(color: Colors.orange, width: 3))
                            : null,
                      ),
                      child: ListTile(
                        leading: Icon(Icons.directions_bus),
                        title: Text('Theo dõi xe'),
                      ),
                    ),
                  ),
                ),
                // Updated divider with a Container for better visibility
                Container(
                  height: 50, // Adjust the height to fit your layout
                  child: VerticalDivider(
                    color: Colors.grey.shade400, // A color that stands out
                    width: 2, // The thickness of the divider
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedOption = "Y";
                      });
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => GetDirectionScreen(
                                // title: "Tìm đường",
                                )),
                      );
                      // Xử lý thêm khi chọn Tìm đường
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: _selectedOption == "Y"
                            ? Border(
                                bottom:
                                    BorderSide(color: Colors.orange, width: 3))
                            : null,
                      ),
                      child: ListTile(
                        leading: Icon(Icons.directions),
                        title: Text('Tìm đường'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: _kGooglePlex,
                    markers: Set<Marker>.of(_markers),
                    onMapCreated: (GoogleMapController controller) {
                      _controller.complete(controller);
                    },
                    zoomControlsEnabled: false,
                  ),
                  Positioned(
                    top: 10, // Điều chỉnh vị trí từ trên xuống
                    left: 20, // Điều chỉnh vị trí từ trái qua
                    right: 20, // Điều chỉnh vị trí từ phải qua
                    child: Visibility(
                      visible: _selectedOption == "X" ? true : false,
                      child: SizedBox(
                          height: 40,
                          child: GestureDetector(
                            onTap: () {
                              // Sử dụng Navigator để chuyển đến màn hình tìm kiếm
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => SearchScreen(
                                          title: "Tìm kiếm điểm dừng",
                                        )),
                              );
                            },
                            child: AbsorbPointer(
                              child: TextField(
                                // Thay thế bằng controller của bạn
                                decoration: InputDecoration(
                                  labelText: 'Tìm kiếm điểm dừng',
                                  fillColor: Colors.white, // Màu nền trắng
                                  filled: true, // Kích hoạt nền màu
                                  prefixIcon:
                                      Icon(Icons.search), // Biểu tượng kính lúp

                                  contentPadding: EdgeInsets.symmetric(
                                      vertical: 4.0, horizontal: 8.0),
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(16)),
                                  ),
                                ),
                                readOnly: true,
                              ),
                            ),
                          )),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            getUserCurrentLocation().then((value) async {
              CameraPosition cameraPosition = CameraPosition(
                  zoom: 14, target: LatLng(value.latitude, value.longitude));

              final GoogleMapController controller = await _controller.future;

              controller.animateCamera(
                  CameraUpdate.newCameraPosition(cameraPosition));
            });
          },
          child: Icon(Icons.location_searching_sharp),
          mini: true,
        ));
  }
}
