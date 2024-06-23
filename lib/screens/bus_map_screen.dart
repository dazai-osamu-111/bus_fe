import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:ui' as ui;

class BusMapScreen extends StatefulWidget {
  final String busNumber;
  final int direction;
  final LatLng currentBusLocation;

  BusMapScreen({
    required this.busNumber,
    required this.direction,
    required this.currentBusLocation,
  });

  @override
  _BusMapScreenState createState() => _BusMapScreenState();
}

class _BusMapScreenState extends State<BusMapScreen> {
  late GoogleMapController _mapController;
  List<LatLng> _busStops = [];
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchBusStops();
  }

  Future<void> _fetchBusStops() async {
    String baseUrl = dotenv.env['BASE_URL'] ?? 'https://defaultapi.com/';
    final url =
        '$baseUrl/get_bus_station_by_bus_number?bus_number=${widget.busNumber}&direction=${widget.direction}';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );
      print('Bus stops response: ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['status'] == 200) {
          List<dynamic> stops = data['data'];
          setState(() {
            _busStops = stops
                .map((stop) => LatLng(stop['latitude'], stop['longitude']))
                .toList();
            _setMarkersAndPolyline(stops);
            if (_busStops.isNotEmpty) {
              _fetchPolyline(_busStops.first, _busStops.last);
            }
          });
        } else {
          setState(() {
            _errorMessage = 'Failed to load bus stops';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to load bus stops';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    }
  }

  Future<void> _fetchPolyline(LatLng origin, LatLng destination) async {
    String apiKey =
        dotenv.env['GOOGLE_MAPS_API_KEY'] ?? 'YOUR_GOOGLE_MAPS_API_KEY';
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&mode=transit&transit_mode=bus&key=$apiKey';

    print('Fetching polyline: $url');

    final response = await http.get(Uri.parse(url));
    print('Polyline response: ${response.body}');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['routes'].isNotEmpty) {
        final points = data['routes'][0]['overview_polyline']['points'];
        _addPolyline(_decodePolyline(points));
      } else {
        print('No routes found');
      }
    } else {
      print('Error fetching polyline: ${response.statusCode}');
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return polyline;
  }

  void _addPolyline(List<LatLng> points) {
    setState(() {
      _polylines.add(
        Polyline(
          polylineId: PolylineId('route_${_polylines.length}'),
          points: points,
          color: Colors.orange,
          width: 5,
        ),
      );
    });
  }

  Future<BitmapDescriptor> _getMarkerIcon(
      IconData iconData, Color color, int size) async {
    PictureRecorder pictureRecorder = PictureRecorder();
    Canvas canvas = Canvas(pictureRecorder);
    Paint paint = Paint()..color = color;
    double radius = size / 2;

    canvas.drawCircle(Offset(radius, radius), radius, paint);
    TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
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
        Offset(
            radius - textPainter.width / 2, radius - textPainter.height / 2));

    final img = await pictureRecorder.endRecording().toImage(size, size);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  Future<BitmapDescriptor> _getAssetIcon(
      String path, int width, int height) async {
    final ByteData data = await DefaultAssetBundle.of(context).load(path);
    final ui.Codec codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: width,
        targetHeight: height);
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ByteData? byteData =
        await fi.image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List resizedData = byteData!.buffer.asUint8List();
    return BitmapDescriptor.fromBytes(resizedData);
  }

  void _setMarkersAndPolyline(List<dynamic> stops) async {
    final busStopIcon =
        await _getMarkerIcon(Icons.directions_bus, Colors.red, 40);
    final currentBusIcon =
        await _getAssetIcon('assets/icons/bus_icon.png', 50, 50);

    setState(() {
      _markers = stops.map((stop) {
        int index = stops.indexOf(stop);
        return Marker(
          markerId: MarkerId('$index'),
          position: LatLng(stop['latitude'], stop['longitude']),
          infoWindow: InfoWindow(title: stop['name']),
          icon: busStopIcon, // Icon điểm dừng xe buýt
        );
      }).toSet();

      _markers.add(
        Marker(
          markerId: MarkerId('bus'),
          position: widget.currentBusLocation,
          infoWindow: InfoWindow(title: 'Current Bus Location'),
          icon: currentBusIcon, // Icon vị trí xe buýt
        ),
      );

      if (_busStops.isNotEmpty) {
        _mapController.animateCamera(
            CameraUpdate.newLatLngZoom(widget.currentBusLocation, 14));
      }
    });

    if (_busStops.isNotEmpty) {
      await _fetchPolyline(_busStops.first, _busStops.last);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    // Tập trung và phóng to camera vào vị trí hiện tại của xe buýt
    _mapController.animateCamera(
      CameraUpdate.newLatLngZoom(widget.currentBusLocation, 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bus Route Map', style: TextStyle(fontFamily: 'Roboto')),
      ),
      body: _errorMessage.isNotEmpty
          ? Center(
              child:
                  Text(_errorMessage, style: TextStyle(fontFamily: 'Roboto')),
            )
          : GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: widget.currentBusLocation,
                zoom: 14,
              ),
              markers: _markers,
              polylines: _polylines,
            ),
    );
  }
}
