import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:bus_management/screens/bus_information.dart';
import 'package:bus_management/screens/deposit_screen.dart';
import 'package:bus_management/screens/get_direction.dart';
import 'package:bus_management/screens/search_screen.dart';
import 'package:bus_management/screens/login_screen.dart'; // Import màn hình đăng nhập
import 'package:bus_management/screens/ticket_screen.dart';
import 'package:bus_management/screens/bus_stop_detail_screen.dart'; // Import màn hình chi tiết
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences

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
  List _busStations = []; // Danh sách các điểm dừng bus
  List _searchResults = []; // Khai báo biến _searchResults
  String _selectedOption = "";
  bool _loggedIn = false;
  String _email = '';
  Map<PolylineId, Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    loadData();
    _fetchBusStations(); // Gọi hàm lấy thông tin các điểm dừng bus
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool loggedIn = prefs.getBool('loggedIn') ?? false;
    String email = prefs.getString('email') ?? '';

    setState(() {
      _loggedIn = loggedIn;
      _email = email;
    });
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('loggedIn');
    await prefs.remove('email');

    setState(() {
      _loggedIn = false;
      _email = '';
    });
  }

  loadData() {
    getUserCurrentLocation().then((value) async {
      _markers.add(Marker(
          markerId: MarkerId('2'),
          position: LatLng(value.latitude, value.longitude),
          infoWindow: InfoWindow(title: 'My current location')));
      CameraPosition cameraPosition = CameraPosition(
          zoom: 14, target: LatLng(value.latitude, value.longitude));
      // zoom: 14,
      // target: LatLng(21.0054933764515, 105.84567100681808));

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

  Future<void> _fetchBusStations() async {
    String base_url = dotenv.env['BASE_URL'] ?? 'https://defaultapi.com/';
    final String apiUrl = '$base_url/get_all_bus_station';
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      if (response.statusCode == 200) {
        final result = json.decode(utf8.decode(response.bodyBytes));
        if (result['status'] == 200) {
          setState(() {
            _busStations = result['data'];
            _addBusStationMarkers();
          });
        } else {
          throw Exception('Failed to load bus stations');
        }
      } else {
        throw Exception('Failed to load bus stations');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<String> _getBusNumberList(String busNumber) async {
    String base_url = dotenv.env['BASE_URL'] ?? 'https://defaultapi.com/';
    final String apiUrl = '$base_url/get_bus_station_by_name?name=$busNumber';
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      if (response.statusCode == 200) {
        final result = json.decode(utf8.decode(response.bodyBytes));
        List<dynamic> busNumberList = [];

        if (result['status'] == 200) {
          for (var station in result['data']) {
            if (!busNumberList.contains(station['bus_number'])) {
              busNumberList.add(station['bus_number']);
            }
          }
          String busNumberListString = busNumberList.join(', ');
          return busNumberListString;
        } else {
          throw Exception('Failed to load bus stations');
        }
      } else {
        throw Exception('Failed to load bus stations');
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  // Hàm thêm các markers của các điểm dừng bus vào bản đồ
  void _addBusStationMarkers() async {
    for (var station in _busStations) {
      final markerIcon =
          await _getMarkerIcon(Icons.directions_bus, Colors.blue, 48);

      // String busNumberListString =
      //     await _getBusNumberList(station['bus_number']);

      _markers.add(Marker(
        markerId: MarkerId(station['bus_station_id'].toString()),
        position: LatLng(station['latitude'], station['longitude']),
        infoWindow: InfoWindow(
          title: station['name'],
          snippet:
              'Lượt đi: ${station["bus_number_list_go"]}; lượt về: ${station["bus_number_list_return"]}',
          onTap: () {
            _showBusStationDetails(station);
          },
        ),
        icon: markerIcon,
      ));
    }
    setState(() {});
  }

  Future<BitmapDescriptor> _getMarkerIcon(
      IconData iconData, Color color, double size) async {
    final PictureRecorder pictureRecorder = PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = color;
    final double radius = size / 2;

    canvas.drawCircle(Offset(radius, radius), radius, paint);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: size * 0.6,
        fontFamily: iconData.fontFamily,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(radius - textPainter.width / 2, radius - textPainter.height / 2),
    );

    final img = await pictureRecorder
        .endRecording()
        .toImage(size.toInt(), size.toInt());
    final ByteData? data = await img.toByteData(format: ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  // Hàm hiển thị thông tin chi tiết của các tuyến bus khi nhấn vào marker
  void _showBusStationDetails(station) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BusStopDetailScreen(
          name: station['name'],
          busNumber: station['bus_number'],
          direction: station['direction'],
        ),
      ),
    );
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
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: _loggedIn
                  ? Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.grey.shade300,
                            child: Icon(Icons.person,
                                size: 40, color: Colors.white),
                          ),
                          SizedBox(height: 10),
                          Text(
                            _email,
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextButton(
                          onPressed: () async {
                            bool? result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => LoginScreen(),
                              ),
                            );
                            if (result == true) {
                              _checkLoginStatus();
                            }
                          },
                          child: Text(
                            'Đăng nhập',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ),
                      ],
                    ),
            ),
            _loggedIn
                ? ListTile(
                    leading: Icon(Icons.logout),
                    title: Text('Đăng xuất'),
                    onTap: _logout,
                  )
                : Container(),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Trang chủ'),
              onTap: () {
                // Xử lý khi chọn Trang chủ
              },
            ),
            ListTile(
              leading: Icon(Icons.search),
              title: Text('Tra cứu'),
              onTap: () {
                // Xử lý khi chọn Tra cứu
              },
            ),
            ListTile(
              leading: Icon(Icons.mail),
              title: Text('Tin buýt'),
              trailing: ClipOval(
                child: Container(
                  color: Colors.red,
                  width: 20,
                  height: 20,
                  child: Center(
                    child: Text(
                      '99+',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ),
              onTap: () {
                // Xử lý khi chọn Tin buýt
              },
            ),
            ListTile(
              leading: Icon(Icons.card_membership),
              title: Text('Vé của tôi'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => TicketScreen(
                        userId: 1), // Thay thế bằng ID người dùng thật
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.local_offer),
              title: Text('Vé tháng'),
              onTap: () {
                // Xử lý khi chọn Mua tem
              },
            ),
            ListTile(
              leading: Icon(Icons.money),
              title: Text('Nạp điểm'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => DepositScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.feedback),
              title: Text('Ý kiến KH'),
              onTap: () {
                // Xử lý khi chọn Ý kiến KH
              },
            ),
            ListTile(
              leading: Icon(Icons.help),
              title: Text('Trợ giúp'),
              onTap: () {
                // Xử lý khi chọn Trợ giúp
              },
            ),
          ],
        ),
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TrackBusScreen(),
                      ),
                    );
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
                  polylines: Set<Polyline>.of(_polylines.values),
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
                // zoom: 14, target: LatLng(value.latitude, value.longitude));
                zoom: 14,
                target: LatLng(21.007416569485482, 105.8426221378807));

            final GoogleMapController controller = await _controller.future;

            controller
                .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
          });
        },
        child: Icon(Icons.location_searching_sharp),
        mini: true,
      ),
    );
  }
}
