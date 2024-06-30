import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'route_detail_screen.dart';
import 'bus_map_screen.dart';

class BusStopDetailScreen extends StatefulWidget {
  final String name;
  final String busNumber;
  final int direction;

  BusStopDetailScreen(
      {required this.name, required this.busNumber, required this.direction});

  @override
  _BusStopDetailScreenState createState() => _BusStopDetailScreenState();
}

class _BusStopDetailScreenState extends State<BusStopDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _upcomingBuses = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchUpcomingBuses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchUpcomingBuses() async {
    String baseUrl = dotenv.env['BASE_URL'] ?? 'https://defaultapi.com/';
    final url =
        '$baseUrl/get_upcoming_bus_information?bus_station_name=${widget.name}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 200) {
          setState(() {
            _upcomingBuses = data['upcoming_buses'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Không có xe nào đang đến.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Không có xe nào đang đến.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi kết nối đến server.';
        _isLoading = false;
      });
    }
  }

  void _showRouteDetail(
      BuildContext context, String routeNumber, String routeName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            RouteDetailScreen(routeNumber: routeNumber, routeName: routeName),
      ),
    );
  }

  void _showBusMap(BuildContext context, String busNumber, int direction,
      LatLng currentBusLocation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BusMapScreen(
          busNumber: busNumber,
          direction: direction,
          currentBusLocation: currentBusLocation,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Theo dõi xe',
            style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight:
                    FontWeight.bold)), // Ensure font supports Vietnamese
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Xe sắp đến'),
            Tab(text: 'Tuyến đi qua'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _upcomingBuses.isEmpty
                  ? Center(
                      child: Text(_errorMessage,
                          style: TextStyle(fontFamily: 'Roboto')))
                  : ListView.builder(
                      itemCount: _upcomingBuses.length,
                      itemBuilder: (context, index) {
                        final bus = _upcomingBuses[index];
                        return GestureDetector(
                          onTap: () => _showBusMap(
                            context,
                            bus['bus_number'],
                            bus['direction'],
                            LatLng(bus['current_latitude'],
                                bus['current_longitude']),
                          ),
                          child: BusInfoCard(
                            routeNumber: bus['bus_number'],
                            routeName:
                                'Bắc Ninh - Long Biên', // Placeholder route name
                            direction:
                                bus['direction'] == 0 ? 'Lượt đi' : 'Lượt về',
                            eta: '${bus['time_to_station'].round()} phút',
                            speed: '${bus['speed'].round()} km/h',
                            distance:
                                '${bus['distance_to_station'].toStringAsFixed(1)} km',
                            plateNumber: bus['driver_name'],
                            currentPassengerAmount:
                                bus['current_passenger_amount'],
                            maxPassengerAmount: bus['max_passenger_amount'],
                          ),
                        );
                      },
                    ),
          ListView(
            children: [
              GestureDetector(
                onTap: () => _showRouteDetail(
                    context, '01', 'Bến xe Giáp Bát - Chương Mỹ'),
                child: RouteInfoCard(
                  routeNumber: '37',
                  routeName: 'Bến xe Giáp Bát - Chương Mỹ',
                  direction: 'Lượt về',
                ),
              ),
              GestureDetector(
                onTap: () =>
                    _showRouteDetail(context, '104', 'Mỹ Đình - BX Nước Ngầm'),
                child: RouteInfoCard(
                  routeNumber: '104',
                  routeName: 'Mỹ Đình - BX Nước Ngầm',
                  direction: 'Lượt đi',
                ),
              ),
              GestureDetector(
                onTap: () => _showRouteDetail(
                    context, '106', 'KĐT Mỗ Lao - TTTM Aeon Mall Long Biên'),
                child: RouteInfoCard(
                  routeNumber: '106',
                  routeName: 'KĐT Mỗ Lao - TTTM Aeon Mall Long Biên',
                  direction: 'Lượt đi',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BusInfoCard extends StatelessWidget {
  final String routeNumber;
  final String routeName;
  final String direction;
  final String eta;
  final String speed;
  final String distance;
  final String plateNumber;
  final int currentPassengerAmount;
  final int maxPassengerAmount;

  BusInfoCard({
    required this.routeNumber,
    required this.routeName,
    required this.direction,
    required this.eta,
    required this.speed,
    required this.distance,
    required this.plateNumber,
    required this.currentPassengerAmount,
    required this.maxPassengerAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Column(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.blue,
                  child: Text(
                    routeNumber,
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        fontFamily:
                            'Roboto'), // Ensure font supports Vietnamese
                  ),
                ),
                Text(
                  plateNumber,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black54,
                      fontFamily: 'Roboto'), // Ensure font supports Vietnamese
                ),
              ],
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    routeName,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                        fontFamily:
                            'Roboto'), // Ensure font supports Vietnamese
                  ),
                  SizedBox(height: 4),
                  Text(
                    direction,
                    style: TextStyle(
                        color: direction.contains('đi')
                            ? Colors.green
                            : Colors.orange,
                        fontSize: 14,
                        fontFamily:
                            'Roboto'), // Ensure font supports Vietnamese
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.speed, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(speed,
                          style: TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                              fontFamily: 'Roboto')),
                      SizedBox(width: 8),
                      Icon(Icons.location_on, size: 16, color: Colors.grey),
                      SizedBox(width: 2),
                      Text(distance,
                          style: TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                              fontFamily: 'Roboto')),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text('$currentPassengerAmount/$maxPassengerAmount',
                          style: TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                              fontFamily: 'Roboto')),
                    ],
                  )
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  eta.split(' ')[0],
                  style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: 'Roboto'), // Ensure font supports Vietnamese
                ),
                Text(
                  eta.split(' ')[1],
                  style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontFamily: 'Roboto'), // Ensure font supports Vietnamese
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RouteInfoCard extends StatelessWidget {
  final String routeNumber;
  final String routeName;
  final String direction;

  RouteInfoCard({
    required this.routeNumber,
    required this.routeName,
    required this.direction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: Colors.blue,
              child: Text(
                routeNumber,
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    fontFamily: 'Roboto'), // Ensure font supports Vietnamese
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    routeName,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                        fontFamily:
                            'Roboto'), // Ensure font supports Vietnamese
                  ),
                  Text(direction,
                      style: TextStyle(
                          color: direction == 'Lượt đi'
                              ? Colors.green
                              : Colors.orange,
                          fontSize: 14,
                          fontFamily:
                              'Roboto')), // Ensure font supports Vietnamese
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
