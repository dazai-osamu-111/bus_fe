import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteDetailScreen extends StatelessWidget {
  final String routeNumber;
  final String routeName;
  final int direction;

  RouteDetailScreen(
      {required this.routeNumber,
      required this.routeName,
      required this.direction});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tuyến: $routeNumber'),
      ),
      body: Column(
        children: [
          Container(
            height: 200,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(21.0285, 105.8542),
                zoom: 14,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '$routeName',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(onPressed: () {}, child: Text('Giờ xuất bến')),
                ElevatedButton(onPressed: () {}, child: Text('Điểm dừng')),
                ElevatedButton(onPressed: () {}, child: Text('Thông tin')),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  leading: Icon(Icons.location_on),
                  title: Text('Điểm cuối Chương Mỹ'),
                ),
                ListTile(
                  leading: Icon(Icons.location_on),
                  title: Text('UBND huyện Chương Mỹ'),
                ),
                ListTile(
                  leading: Icon(Icons.location_on),
                  title: Text('Công an huyện Chương Mỹ'),
                ),
                ListTile(
                  leading: Icon(Icons.location_on),
                  title: Text('Trường THCS Biên Giang'),
                ),
                ListTile(
                  leading: Icon(Icons.location_on),
                  title: Text('Nhà thờ Biên Giang'),
                ),
                ListTile(
                  leading: Icon(Icons.location_on),
                  title: Text('Trạm Xăng Mai Linh'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void _showRouteDetail(
    BuildContext context, String routeNumber, String routeName) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => RouteDetailScreen(
        routeNumber: routeNumber,
        routeName: routeName,
        direction: 0,
      ),
    ),
  );
}

class RouteInfoCard extends StatelessWidget {
  final String routeNumber;
  final String routeName;
  final String direction;

  RouteInfoCard(
      {required this.routeNumber,
      required this.routeName,
      required this.direction});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text('$routeNumber: $routeName'),
        subtitle: Text(direction),
      ),
    );
  }
}

class BusRoutesScreen extends StatelessWidget {
  final List<Map<String, dynamic>> _busRoutes = [
    {'bus_number': '37', 'name': 'Bến xe Giáp Bát - Chương Mỹ', 'direction': 0},
    // Add more bus routes here
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bus Routes'),
      ),
      body: ListView.builder(
        itemCount: _busRoutes.length,
        itemBuilder: (context, index) {
          final busRoute = _busRoutes[index];
          return GestureDetector(
            onTap: () => _showRouteDetail(
                context, busRoute['bus_number'], busRoute['name']),
            child: RouteInfoCard(
              routeNumber: busRoute['bus_number'],
              routeName: busRoute['name'],
              direction: busRoute['direction'] == 0 ? 'Lượt đi' : 'Lượt về',
            ),
          );
        },
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: BusRoutesScreen(),
  ));
}
