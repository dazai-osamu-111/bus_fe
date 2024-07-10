import 'dart:async';
import 'dart:convert';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';

class DepositScreen extends StatefulWidget {
  final String? orderId;
  const DepositScreen({Key? key, this.orderId}) : super(key: key);
  @override
  _DepositScreenState createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final TextEditingController _amountController = TextEditingController();
  double _currentBalance = 0.0;
  String _selectedPaymentMethod = 'Momo Wallet';
  String _token = '';
  int _userId = 1;
  static const platform = MethodChannel('com.example.bus_management/momo');

  late AppLinks _appLinks;
  StreamSubscription<Uri>? _sub;

  @override
  void initState() {
    super.initState();
    _initialize();
    _appLinks = AppLinks();
    _handleIncomingLinks();
    platform.setMethodCallHandler(_handleMethodCall);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onPaymentCallback':
        print(
            "Received callback from Momo: ${call.arguments}"); // orderId (String
        final String orderId = call.arguments;
        _checkPaymentStatus(orderId, double.parse(_amountController.text));
        break;
      default:
        print('Unknown method ${call.method}');
    }
  }

  void _handleIncomingLinks() {
    _sub = _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        // Kiểm tra uri.path hoặc uri.queryParameters để xử lý callback từ Momo
        if (uri.host == 'momo_callback') {
          // Xử lý callback ở đây
          final orderId = uri.queryParameters['orderId'];
          if (orderId != null) {
            _checkPaymentStatus(orderId, double.parse(_amountController.text));
          }
        }
      }
    }, onError: (err) {
      // Xử lý lỗi
    });
  }

  Future<void> _requestPayment() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? _token = prefs.getString('token');
    final amount = int.parse(_amountController.text);
    final String baseUrl = dotenv.env['BASE_URL'] ?? 'https://defaultapi.com/';

    final response = await http.get(
      Uri.parse('$baseUrl/momo?amount=${amount}'),
      headers: {
        'Authorization': 'Token ${_token}',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final deeplink = data['deeplink'];
      final orderId = data['orderId'];
      final callbackUrl =
          'example://momo_callback?orderId=$orderId'; // Đảm bảo sử dụng đúng deeplink

      try {
        final result = await platform
            .invokeMethod('requestPayment', {'deeplink': deeplink});

        if (result == 'success') {
          // Chờ đến khi người dùng quay lại ứng dụng và xử lý callback
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Thanh toán thất bại')),
          );
        }
      } on PlatformException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.message}')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi yêu cầu thanh toán Momo')),
      );
    }
  }

  Future<void> _checkPaymentStatus(String orderId, double amount) async {
    final String baseUrl = dotenv.env['BASE_URL'] ?? 'https://defaultapi.com/';

    while (true) {
      final response = await http.get(
        Uri.parse('$baseUrl/momo_status?orderId=$orderId'),
        headers: {
          'Authorization': 'Token $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final resultCode = data['resultCode'];

        if (resultCode == 0) {
          // Giao dịch thành công, gọi API deposit
          await _deposit(amount);
          break;
        } else if (resultCode != 1000) {
          // Giao dịch thất bại
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Giao dịch thất bại')),
          );
          break;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi kiểm tra trạng thái thanh toán')),
        );
        break;
      }

      // Chờ 2 giây trước khi kiểm tra lại
      await Future.delayed(Duration(seconds: 2));
    }
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

  Future<void> _deposit(double amount) async {
    final String baseUrl = dotenv.env['BASE_URL'] ?? 'https://defaultapi.com/';

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
