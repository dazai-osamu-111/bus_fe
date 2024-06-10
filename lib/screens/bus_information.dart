import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TrackBusScreen extends StatefulWidget {
  @override
  _TrackBusScreenState createState() => _TrackBusScreenState();
}

class _TrackBusScreenState extends State<TrackBusScreen> {
  List<Map<String, dynamic>> _busList = [];
  List<Map<String, dynamic>> _busInfo = [];
  final TextEditingController _busNumberController = TextEditingController();
  bool _busSelected = false;

  Future<void> _fetchBusList(String busNumber) async {
    final String baseUrl = dotenv.env['BASE_URL'] ?? 'https://defaultapi.com/';

    final response = await http.get(
      Uri.parse('$baseUrl/get_list_bus_bus_number').replace(queryParameters: {
        'bus_number': busNumber,
      }),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'];
      setState(() {
        _busList = List<Map<String, dynamic>>.from(data);
        _busInfo = [];
        _busSelected = false;
      });
    } else {
      // Handle error
    }
  }

  Future<void> _fetchBusInfo(String busNumber) async {
    final String baseUrl = dotenv.env['BASE_URL'] ?? 'https://defaultapi.com/';

    final response = await http.get(
      Uri.parse('$baseUrl/get_bus_info_by_bus_number')
          .replace(queryParameters: {
        'bus_number': busNumber,
      }),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'];
      setState(() {
        _busInfo = List<Map<String, dynamic>>.from(data);
        _busSelected = true;
      });
    } else {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theo dõi xe buýt'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _busNumberController,
                    decoration: InputDecoration(
                      labelText: 'Nhập mã tuyến xe buýt',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      prefixIcon: Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                  ),
                ),
                SizedBox(width: 8.0),
                ElevatedButton(
                  onPressed: () {
                    _fetchBusList(_busNumberController.text);
                  },
                  child: Text('Tìm kiếm'),
                ),
              ],
            ),
          ),
          if (!_busSelected && _busList.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _busList.length,
                itemBuilder: (context, index) {
                  final bus = _busList[index];
                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: ListTile(
                      leading: Icon(FontAwesomeIcons.bus,
                          size: 30, color: Colors.blue),
                      title: Text(
                        'Tuyến xe buýt: ${bus['bus_number']}',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      onTap: () {
                        _fetchBusInfo(bus['bus_number']);
                      },
                    ),
                  );
                },
              ),
            ),
          if (_busSelected && _busInfo.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _busInfo.length,
                itemBuilder: (context, index) {
                  final bus = _busInfo[index];
                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            leading: Icon(FontAwesomeIcons.bus,
                                size: 30, color: Colors.blue),
                            title: Text('Mã xe buýt: ${bus['bus_number']}'),
                            subtitle: Text('Biển số: ${bus['driver_name']}'),
                          ),
                          ListTile(
                            leading: Icon(Icons.speed,
                                size: 30, color: Colors.green),
                            title: Text('Tốc độ: ${bus['speed']} km/h'),
                          ),
                          ListTile(
                            leading: Icon(Icons.people,
                                size: 30, color: Colors.orange),
                            title: Text(
                                'Số lượng hành khách: ${bus['current_passenger_amount']}/${bus['max_passenger_amount']}'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
