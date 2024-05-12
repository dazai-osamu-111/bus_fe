import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class SearchScreen extends StatefulWidget {
  final String title;
  const SearchScreen({Key? key, required this.title}) : super(key: key);

  @override
  _SearchScreen createState() => _SearchScreen();
}

class _SearchScreen extends State<SearchScreen> {
  TextEditingController _controller = TextEditingController();
  var uuid = Uuid();
  String _sesssionToken = '1234';
  List<dynamic> _placesList = [];

  String get title => super.widget.title;

  @override
  void initState() {
    super.initState();

    _controller.addListener(() {
      onChange();
    });
  }

  void onChange() {
    if (_sesssionToken == null) {
      setState(() {
        _sesssionToken = uuid.v4();
      });
    }

    getSuggesion(_controller.text);
  }

  void getSuggesion(String input) async {
    String kPLACES_API_KEY = "AIzaSyAnI_7dbzhe2FS7kr1lXvqXId2AIBvUXB8";
    String baseURL =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json';
    String request =
        '$baseURL?input=$input&key=$kPLACES_API_KEY&sessiontoken=$_sesssionToken';

    var response = await http.get(Uri.parse(request));

    if (response.statusCode == 200) {
      setState(() {
        if (response.statusCode == 200) {
          if (mounted) {
            setState(() {
              _placesList = jsonDecode(response.body.toString())['predictions'];
              print(_placesList);
            });
          }
        } else {
          throw Exception('Failed to load data');
        }
        _placesList = jsonDecode(response.body.toString())['predictions'];
        print(_placesList);
      });
    } else {
      throw Exception('Failed to load data');
    }
  }

  void getPlaceDetails(String placeId, String apiKey) async {
    String url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=type&key=$apiKey';
    var response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body.toString());
      if (jsonResponse['status'] == 'OK') {
        var types = jsonResponse['result']['types'];
        if (types.contains('bus_station')) {
          if (mounted) {
            print(jsonResponse['result']);
            setState(() {
              _placesList
                  .add(jsonResponse['result']); // Add the place to _placesList
            });
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          title,
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 0),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              color: Colors.grey.withOpacity(0.3),
              child: TextField(
                // Thay thế bằng controller của bạn
                decoration: InputDecoration(
                  labelText: "Tìm điểm dừng",
                  fillColor: Colors.white, // Màu nền trắng
                  filled: true, // Kích hoạt nền màu
                  prefixIcon: Icon(Icons.search, color: Colors.blue),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                ),
              ),
            ),
            Expanded(
                child: ListView.builder(
                    itemCount: _placesList.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        onTap: () async {
                          List<Location> locations = await locationFromAddress(
                              _placesList[index]['description']);
                          print(locations.last.longitude);
                          print(locations.last.latitude);
                        },
                        title: Text(_placesList[index]['description']),
                      );
                    }))
          ],
        ),
      ),
    );
  }
}
