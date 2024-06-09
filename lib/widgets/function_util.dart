import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

Future<int> getStationId(name) async {
  final String baseUrl = dotenv.env['BASE_URL'] ?? 'https://defaultapi.com/';
  final response = await http.get(
    Uri.parse('${baseUrl}/get_station_id?name=$name'), // URL giả lập
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> responseBody = jsonDecode(response.body);
    int stationId = responseBody['bus_station_id'] ?? 0;
    return stationId;
  } else {
    return 0;
  }
}
