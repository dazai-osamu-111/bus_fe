import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';

class DepositScreen extends StatefulWidget {
  @override
  _DepositScreenState createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final TextEditingController _amountController = TextEditingController();
  double _currentBalance = 0.0;
  String _selectedPaymentMethod = 'Momo Wallet';
  String _token = '';
  int _userId = 1;
  static const platform =
      const MethodChannel('com.example.bus_management/momo');

  Future<void> _requestPayment() async {
    try {
      final response = await platform.invokeMethod('requestPayment', {
        'amount': _amountController.text,
        'merchantName': 'Demo SDK',
        'merchantCode': 'SCB01',
        'description': 'Thanh toán dịch vụ ABC',
        'deeplink':
            'momo://app?action=payWithApp&isScanQR=false&serviceType=app&sid=TU9NT3w0ODVmOWJkOS00NjRmLTRhNDktODM0Mi02YTM5YzMxZDJlZWQ&v=3.0'
      });
      // Handle response here
    } on PlatformException catch (e) {
      // Handle error here
    }
  }

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

  Future<void> _deposit() async {
    final String baseUrl = dotenv.env['BASE_URL'] ?? 'https://defaultapi.com/';
    final amount = double.parse(_amountController.text);

    final response = await http.post(
      Uri.parse('$baseUrl/deposit'),
      headers: {
        'Authorization': 'Token $_token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'user_id': _userId,
        'amount': amount,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nạp tiền thành công')),
      );
      _fetchCurrentBalance();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nạp tiền thất bại')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nạp tiền'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Số dư hiện tại: $_currentBalance Điểm',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Số tiền cần nạp',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedPaymentMethod,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedPaymentMethod = newValue!;
                });
              },
              items: <String>['Momo Wallet', 'Zalo Pay']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Row(
                    children: [
                      Icon(
                        value == 'Momo Wallet'
                            ? FontAwesomeIcons.mobileAlt
                            : FontAwesomeIcons.wallet,
                        color:
                            value == 'Momo Wallet' ? Colors.pink : Colors.blue,
                      ),
                      SizedBox(width: 10),
                      Text(value),
                    ],
                  ),
                );
              }).toList(),
              decoration: InputDecoration(
                labelText: 'Phương thức thanh toán',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _requestPayment,
                child: Text('Nạp tiền'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  textStyle: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
