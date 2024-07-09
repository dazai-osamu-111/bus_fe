import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TicketScreen extends StatefulWidget {
  final int userId;

  TicketScreen({required this.userId});

  @override
  _TicketScreenState createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Ticket>> _futureMonthlyTickets;
  late Future<List<Ticket>> _futureDailyTickets;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _futureMonthlyTickets = fetchTickets(widget.userId, 0);
    _futureDailyTickets = fetchTickets(widget.userId, 1);
  }

  Future<List<Ticket>> fetchTickets(int userId, int ticketType) async {
    final String baseUrl = dotenv.env['BASE_URL'] ?? 'https://defaultapi.com/';
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? _token = prefs.getString('token');
    final response = await http.get(
      Uri.parse('$baseUrl/user_tickets?ticket_type=$ticketType&status=0'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Token $_token',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseBody = jsonDecode(response.body);
      final List<dynamic> data = responseBody['data'];
      return data.map((item) => Ticket.fromJson(item)).toList();
    } else {
      throw Exception('Không thể lấy thông tin vé. Vui lòng thử lại.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vé của tôi'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Vé tháng'),
            Tab(text: 'Vé ngày'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildFutureBuilder(_futureMonthlyTickets, true),
          buildFutureBuilder(_futureDailyTickets, false),
        ],
      ),
    );
  }

  Widget buildFutureBuilder(
      Future<List<Ticket>> futureTickets, bool isMonthly) {
    return FutureBuilder<List<Ticket>>(
      future: futureTickets,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('Không có vé nào.'));
        }

        final tickets = snapshot.data!;
        return buildTicketList(tickets, isMonthly);
      },
    );
  }

  Widget buildTicketList(List<Ticket> tickets, bool isMonthly) {
    return ListView.builder(
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        return GestureDetector(
          onTap: () => showQrCode(ticket),
          child: TicketCard(ticket: ticket, isMonthly: isMonthly),
        );
      },
    );
  }

  void showQrCode(Ticket ticket) {
    final data = jsonEncode({
      'ticket_id': ticket.ticketId,
      'type': ticket.ticketType == 0 ? 'monthly' : 'daily',
      'price': ticket.price,
      'valid_to': ticket.validTo,
    });

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('QR Code'),
          content: Center(
            child: QrImageView(
              data: data,
              size: 200.0,
              foregroundColor: Colors.blue, // Tạo QR code với màu xanh
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Đóng'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class Ticket {
  final int ticketId;
  final String busNumber;
  final int status;
  final double price;
  final int ticketType;
  final String validTo;

  Ticket({
    required this.ticketId,
    required this.busNumber,
    required this.status,
    required this.price,
    required this.ticketType,
    required this.validTo,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      ticketId: json['ticket_id'],
      busNumber: json['bus_number'] ?? '',
      status: json['status'],
      price: json['price'],
      ticketType: json['ticket_type'],
      validTo: json['valid_to'],
    );
  }

  String getStatusText() {
    if (ticketType == 0) {
      return 'Vé tháng';
    }
    switch (status) {
      case 0:
        return 'Đã mua';
      case 1:
        return 'Đã dùng';
      default:
        return 'Không xác định';
    }
  }

  Color getStatusColor() {
    if (ticketType == 0) {
      return Colors.blue;
    }
    switch (status) {
      case 0:
        return Colors.blue;
      case 1:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class TicketCard extends StatelessWidget {
  final Ticket ticket;
  final bool isMonthly;

  TicketCard({required this.ticket, required this.isMonthly});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(10.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      elevation: 5,
      child: Padding(
        padding: EdgeInsets.all(15.0),
        child: Row(
          children: [
            QrImageView(
              data: ticket.ticketId.toString(),
              size: 50.0,
              foregroundColor: Colors.blue, // Tạo QR code với màu xanh
            ),
            SizedBox(width: 15.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mã vé: ${ticket.ticketId}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                    ),
                  ),
                  if (!isMonthly) ...[
                    SizedBox(height: 10.0),
                    Text('Mã xe bus: ${ticket.busNumber}'),
                  ],
                  SizedBox(height: 10.0),
                  Text(
                    'Trạng thái: ${ticket.getStatusText()}',
                    style: TextStyle(
                      color: ticket.getStatusColor(),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10.0),
                  Text('Giá: ${ticket.price.toStringAsFixed(0)} Đ'),
                  if (isMonthly) ...[
                    SizedBox(height: 10.0),
                    Text('Hiệu lực tới: ${ticket.validTo}'),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
