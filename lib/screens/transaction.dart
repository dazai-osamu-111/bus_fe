import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TransactionDetailForm extends StatefulWidget {
  final String fare;
  final String busStopDepartureTime;
  final String busStopArrivalTime;
  final String busNumber;
  final String travelTimeInMinutes;

  TransactionDetailForm({
    required this.fare,
    required this.busStopDepartureTime,
    required this.busStopArrivalTime,
    required this.busNumber,
    required this.travelTimeInMinutes,
  });

  @override
  _TransactionDetailFormState createState() => _TransactionDetailFormState();
}

class _TransactionDetailFormState extends State<TransactionDetailForm> {
  final _formKey = GlobalKey<FormState>();
  final String userName = 'Nguyễn Thế Đức';
  final String userPhone = '0917850867';
  final String curentPoint = '100000 điểm';
  final String price = '16.000 VNĐ';

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Hành khách'),
            subtitle: Text(userName),
          ),
          ListTile(
            leading: Icon(Icons.phone),
            title: Text('Số điện thoại'),
            subtitle: Text(userPhone),
          ),
          ListTile(
            leading: Icon(Icons.wallet),
            title: Text('Điểm hiện tại'),
            subtitle: Text(curentPoint),
          ),
          ListTile(
            leading: Icon(Icons.attach_money),
            title: Text('Giá vé'),
            subtitle: Text(widget.fare),
          ),
          SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('QR Code'),
                      content: Container(
                        child: QrImageView(
                          data:
                              'Tên: $userName\nSĐT: $userPhone\nGiá vé: ${widget.fare}\nSố xe buýt: ${widget.busNumber}\nThời gian: ${widget.busStopDepartureTime} - ${widget.busStopArrivalTime}',
                          version: QrVersions.auto,
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
  }
}
