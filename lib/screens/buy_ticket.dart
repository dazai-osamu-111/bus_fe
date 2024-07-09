import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class BuyTicketScreen extends StatefulWidget {
  @override
  _BuyTicketScreenState createState() => _BuyTicketScreenState();
}

class _BuyTicketScreenState extends State<BuyTicketScreen> {
  String _selectedTicketCategory = 'day';
  int? _selectedTicketType;
  double _currentBalance = 0.0;
  String _token = '';
  int _userId = 1;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadToken();
    await _fetchCurrentBalance();
  }

  Future<void> _loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('token') ?? '';
    });
  }

  Future<void> _fetchCurrentBalance() async {
    final String baseUrl = dotenv.env['BASE_URL'] ?? 'https://defaultapi.com/';

    final response = await http.get(
      Uri.parse('$baseUrl/user'),
      headers: {
        'Authorization': 'Token $_token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _userId = data['id'];
      });
      final response2 = await http.get(
        Uri.parse('$baseUrl/deposit?user_id=$_userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response2.statusCode == 200) {
        final data2 = jsonDecode(response2.body);
        setState(() {
          _currentBalance = data2['amount'];
        });
      }
    } else {
      // Handle error
    }
  }

  Future<void> _buyTicket() async {
    final String baseUrl = dotenv.env['BASE_URL'] ?? 'https://defaultapi.com/';
    final int price = _selectedTicketType == 0
        ? 100000
        : (_selectedTicketType == 1 ? 7000 : 9000);

    final response = await http.post(
      Uri.parse('$baseUrl/buy_ticket'),
      headers: {
        'Authorization': 'Token $_token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'price': price,
        'ticket_type': _selectedTicketType,
      }),
    );

    if (response.statusCode == 200) {
      _showSuccessDialog();
      _fetchCurrentBalance();
    } else {
      final errorResponse = jsonDecode(response.body);
      _showErrorDialog(errorResponse['message'] ?? 'Mua vé thất bại');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 80),
              SizedBox(height: 10),
              Text('Mua vé thành công!', style: TextStyle(fontSize: 20)),
            ],
          ),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error, color: Colors.red, size: 80),
              SizedBox(height: 10),
              Text(message, style: TextStyle(fontSize: 20)),
            ],
          ),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mua vé xe buýt'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                leading: Icon(Icons.account_balance_wallet,
                    color: Colors.blueAccent, size: 40),
                title: Text('Số dư hiện tại: $_currentBalance Điểm',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),
            SizedBox(height: 20),
            Text('Chọn loại vé', style: TextStyle(fontSize: 18)),
            ListTile(
              title: const Text('Vé ngày'),
              leading: Radio<String>(
                value: 'day',
                groupValue: _selectedTicketCategory,
                onChanged: (String? value) {
                  setState(() {
                    _selectedTicketCategory = value!;
                    _selectedTicketType = null;
                  });
                },
              ),
              trailing: Icon(Icons.calendar_today, color: Colors.blueAccent),
            ),
            ListTile(
              title: const Text('Vé tháng'),
              leading: Radio<String>(
                value: 'monthly',
                groupValue: _selectedTicketCategory,
                onChanged: (String? value) {
                  setState(() {
                    _selectedTicketCategory = value!;
                    _selectedTicketType = 0;
                  });
                },
              ),
              trailing:
                  Icon(Icons.calendar_view_month, color: Colors.blueAccent),
            ),
            if (_selectedTicketCategory == 'day')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Chọn mệnh giá vé ngày', style: TextStyle(fontSize: 18)),
                  ListTile(
                    title: const Text('7000 Điểm'),
                    leading: Radio<int>(
                      value: 1,
                      groupValue: _selectedTicketType,
                      onChanged: (int? value) {
                        setState(() {
                          _selectedTicketType = value!;
                        });
                      },
                    ),
                    trailing: Icon(Icons.monetization_on, color: Colors.green),
                  ),
                  ListTile(
                    title: const Text('9000 Điểm'),
                    leading: Radio<int>(
                      value: 2,
                      groupValue: _selectedTicketType,
                      onChanged: (int? value) {
                        setState(() {
                          _selectedTicketType = value!;
                        });
                      },
                    ),
                    trailing: Icon(Icons.monetization_on, color: Colors.green),
                  ),
                ],
              ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                onPressed: _selectedTicketType == null ? null : _buyTicket,
                icon: Icon(Icons.check, color: Colors.white),
                label: Text('Mua vé'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  textStyle: TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
