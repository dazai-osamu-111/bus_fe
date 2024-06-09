import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';

class TicketScreen extends StatefulWidget {
  final int userId;

  TicketScreen({required this.userId});

  @override
  _TicketScreenState createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Ticket>> _futureTickets;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _futureTickets = fetchTickets(widget.userId);
  }

  Future<List<Ticket>> fetchTickets(int userId) async {
    final String baseUrl = dotenv.env['BASE_URL'] ?? 'https://defaultapi.com/';
    final response = await http.get(
      Uri.parse('$baseUrl/user_tickets?user_id=$userId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
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
            Tab(text: 'Đã mua'),
            Tab(text: 'Đã sử dụng'),
            Tab(text: 'Hết hạn'),
          ],
        ),
      ),
      body: FutureBuilder<List<Ticket>>(
        future: _futureTickets,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Không có vé nào.'));
          }

          final tickets = snapshot.data!;
          return TabBarView(
            controller: _tabController,
            children: [
              buildTicketList(
                  tickets.where((ticket) => ticket.status == 0).toList()),
              buildTicketList(
                  tickets.where((ticket) => ticket.status == 1).toList()),
              buildTicketList(
                  tickets.where((ticket) => ticket.status == 2).toList()),
            ],
          );
        },
      ),
    );
  }

  Widget buildTicketList(List<Ticket> tickets) {
    return ListView.builder(
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        return GestureDetector(
          onTap: () => showQrCode(ticket.ticketId.toString()),
          child: TicketCard(ticket: ticket),
        );
      },
    );
  }

  void showQrCode(String data) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('QR Code'),
          content: Center(
            child: QrImageView(
              data: data,
              size: 200.0,
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

  Ticket({
    required this.ticketId,
    required this.busNumber,
    required this.status,
    required this.price,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      ticketId: json['ticket_id'],
      busNumber: json['bus_number'],
      status: json['status'],
      price: json['price'],
    );
  }

  String getStatusText() {
    switch (status) {
      case 0:
        return 'Chưa dùng';
      case 1:
        return 'Đã dùng';
      case 2:
        return 'Hết hạn';
      default:
        return 'Không xác định';
    }
  }

  Color getStatusColor() {
    switch (status) {
      case 0:
        return Colors.blue;
      case 1:
        return Colors.green;
      case 2:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class TicketCard extends StatelessWidget {
  final Ticket ticket;

  TicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(10.0),
      child: Padding(
        padding: EdgeInsets.all(15.0),
        child: Row(
          children: [
            QrImageView(
              data: ticket.ticketId.toString(),
              size: 50.0,
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
                  SizedBox(height: 10.0),
                  Text('Mã xe bus: ${ticket.busNumber}'),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
