import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _otpSent = false;
  final String baseUrl = dotenv.env['BASE_URL'] ?? 'https://defaultapi.com/';
  String _verificationId = '';

  Future<void> _sendOtp() async {
    String email = _emailController.text;

    final response = await http.post(
      Uri.parse('${baseUrl}/request-otp'), // URL giả lập
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': email,
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        _otpSent = true;
        _verificationId = '123456'; // Giả lập mã OTP từ response
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OTP đã được gửi tới $email')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể gửi OTP. Vui lòng thử lại.')),
      );
    }
  }

  Future<void> _verifyOtp() async {
    String otp = _otpController.text;
    String email = _emailController.text;

    final response = await http.post(
      Uri.parse('${baseUrl}/verify-otp'), // URL giả lập
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': email,
        'otp': otp,
      }),
    );

    if (response.statusCode == 200) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('loggedIn', true);
      await prefs.setString('email', email);
      // Phân tích cú pháp response body từ JSON
      final Map<String, dynamic> responseBody = jsonDecode(response.body);

      // Lưu token vào SharedPreferences
      await prefs.setString('token', responseBody['token']);

      Navigator.of(context).pop(true); // Quay lại HomeScreen và báo thành công
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sai mã OTP')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đăng nhập'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chào mừng đến với ứng dụng Bus Management!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            if (!_otpSent)
              Column(
                children: [
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _sendOtp,
                    child: Text('Nhận mã OTP'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blue, // Màu nền nút
                      minimumSize: Size(double.infinity, 50), // Chiều rộng nút
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  Text(
                    'Nhập mã OTP đã được gửi tới email của bạn:',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 20),
                  PinCodeTextField(
                    appContext: context,
                    length: 6,
                    onChanged: (value) {},
                    controller: _otpController,
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(5),
                      fieldHeight: 50,
                      fieldWidth: 40,
                      activeFillColor: Colors.white,
                      selectedFillColor: Colors.white,
                      inactiveFillColor: Colors.white,
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _verifyOtp,
                    child: Text('Xác nhận mã OTP'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blue, // Màu nền nút
                      minimumSize: Size(double.infinity, 50), // Chiều rộng nút
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
