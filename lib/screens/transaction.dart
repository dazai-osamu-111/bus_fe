import 'dart:convert';
import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TransactionDetailForm extends StatefulWidget {
  final String fare;
  final String busListString;
  final List ticketStationData;

  TransactionDetailForm({
    Key? key,
    required this.fare,
    required this.busListString,
    required this.ticketStationData,
  }) : super(key: key);

  @override
  _TransactionDetailFormState createState() => _TransactionDetailFormState();
}

class _TransactionDetailFormState extends State<TransactionDetailForm> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: getTicketInfo(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data == null) {
          return Center(
              child: Text('Không thể lấy thông tin vé. Vui lòng thử lại.'));
        }

        final ticketData = snapshot.data!;
        String userEmail = ticketData['email'];
        String userBlance = ticketData['blance'];
        int userId = ticketData['user_id'];
        int numericFare = extractNumericValue(widget.fare);
        // Array ticketStationInfo =

        return Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: Icon(Icons.phone),
                title: Text('Gmail'),
                subtitle: Text(userEmail),
              ),
              ListTile(
                leading: Icon(Icons.wallet),
                title: Text('Điểm hiện tại'),
                subtitle: Text(userBlance),
              ),
              ListTile(
                leading: Icon(Icons.attach_money),
                title: Text('Giá vé'),
                subtitle: Text(widget.fare),
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      int lastTicketId = await purchaseTicket(
                          userId,
                          numericFare,
                          widget.busListString,
                          widget.ticketStationData);
                      Navigator.of(context).pop();
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('QR Code'),
                            content: Container(
                              child: QrImageView(
                                data: 'ticket_id: $lastTicketId',
                                size: 200.0,
                              ),
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: Text('Lưu vé'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Mua vé thành công.'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 3),
                          behavior: SnackBarBehavior.floating,
                          margin: EdgeInsets.all(20.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Mua vé thất bại. Vui lòng thử lại.'),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 3),
                          behavior: SnackBarBehavior.floating,
                          margin: EdgeInsets.all(20.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      );
                    }
                  },
                  icon: Icon(Icons.check),
                  label: Text('Xác nhận mua vé'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> getTicketInfo() async {
    final String baseUrl = dotenv.env['BASE_URL'] ?? 'https://defaultapi.com/';
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    final response = await http.get(
      Uri.parse('${baseUrl}/user'), // URL giả lập
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseBody = jsonDecode(response.body);
      String email = responseBody['email'];
      int userId = responseBody['id'];
      double blance = 0;
      final response2 = await http.get(
        Uri.parse('${baseUrl}/deposit?user_id=$userId'), // URL giả lập
      );
      if (response2.statusCode == 200) {
        final Map<String, dynamic> responseBody2 = jsonDecode(response2.body);
        blance = responseBody2['amount'];
      }
      String blance_string = blance.toString();

      Object ticketData = {
        'email': email,
        'blance': blance_string,
        "user_id": userId,
      };
      return ticketData as Map<String, dynamic>;
    } else {
      throw Exception('Không thể lấy thông tin vé. Vui lòng thử lại.');
    }
  }

  Future<int> purchaseTicket(int userId, int fare, String busListString,
      List ticketStationData) async {
    final String baseUrl = dotenv.env['BASE_URL'] ?? 'https://defaultapi.com/';
     print(ticketStationData);
    final response = await http.post(
      Uri.parse('${baseUrl}/buy_ticket'), // URL giả lập
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
     
      body: jsonEncode(<String, dynamic>{
        'price': fare,
        'bus_number': busListString,
        'user_id': userId,
        'ticket_station_data': ticketStationData
      }),
    );

    if (response.statusCode == 200) {
      // get ticket_id by api
      final response = await http.get(
        Uri.parse('$baseUrl/user_tickets?user_id=$userId'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        int lastTicketId = responseBody['data'].last['ticket_id'];
        return lastTicketId;
      } else {
        throw Exception('Không thể mua vé. Vui lòng thử lại.');
      }
    } else {
      // Xử lý khi mua vé thất bại
      throw Exception('Không thể mua vé. Vui lòng thử lại.');
    }
  }

  int extractNumericValue(String fare) {
    final regex = RegExp(r'\d+'); // Tìm tất cả các chữ số
    final matches = regex.allMatches(fare); // Lấy tất cả các khớp
    final numericString = matches
        .map((match) => match.group(0))
        .join(''); // Nối tất cả các khớp lại với nhau
    return int.parse(numericString); // Chuyển đổi thành số nguyên
  }
}
