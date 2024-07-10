import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:timelines/timelines.dart';

class RouteDetailScreen extends StatefulWidget {
  final String routeNumber;
  final String routeName;
  final int direction;

  RouteDetailScreen(
      {required this.routeNumber,
      required this.routeName,
      required this.direction});

  @override
  _RouteDetailScreenState createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _stops = [
    'Điểm cuối Chương Mỹ',
    'UBND huyện Chương Mỹ',
    'Công an huyện Chương Mỹ',
    'Trường THCS Biên Giang',
    'Nhà thờ Biên Giang',
    'Trạm Xăng Mai Linh'
  ];

  final List<String> _times = ['05:00', '05:15', '05:30', '05:40', '05:50'];

  final String _info = """
Đơn vị chủ quản:
Trung tâm Tân Đạt - Transerco

Giãn cách chạy xe:
12-15-20 phút/chuyến

Giá vé:
7000 VNĐ/Lượt

Thời gian hoạt động:
T2 - T6: 05:00 - 21:00
T7: 05:00 - 21:00
CN: 05:05 - 21:00

Chiều đi:
Công viên Nghĩa Đô - Nguyễn Văn Huyên - Nguyễn Khánh Toàn - Đào Tấn - Liễu Giai - Nguyễn Chí Thanh - Huỳnh Thúc Kháng - Thái Hà - Chùa Bộc - Tôn Thất Tùng - Lê Trọng Tấn - Trần Điền - Định Công - Giải Phóng - Ngọc Hồi - Quốc lộ 1 - Cầu Ngọc Hồi - Xã Ngọc Hồi - Đường mới xã Đại Áng - Khánh Hà (Thường Tín).
""";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildStopsTimeline() {
    return ListView.builder(
      itemCount: _stops.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Column(
                children: [
                  if (index != 0)
                    Container(
                      width: 2,
                      height: 20,
                      color: Colors.blue,
                    ),
                  Icon(Icons.directions_bus, color: Colors.blue),
                  if (index != _stops.length - 1)
                    Container(
                      width: 2,
                      height: 20,
                      color: Colors.blue,
                    ),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(_stops[index]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimesTimeline() {
    return ListView.builder(
      itemCount: _times.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Column(
                children: [
                  if (index != 0)
                    Container(
                      width: 2,
                      height: 20,
                      color: Colors.blue,
                    ),
                  Icon(Icons.access_time, color: Colors.blue),
                  if (index != _times.length - 1)
                    Container(
                      width: 2,
                      height: 20,
                      color: Colors.blue,
                    ),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(_times[index]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Tuyến: ${widget.routeNumber}'),
      ),
      body: Column(
        children: [
          Container(
            height: 200,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                    20.841933, 106.743362), // Toạ độ ví dụ, bạn có thể thay đổi
                zoom: 14,
              ),
              zoomControlsEnabled: false,
              mapType: MapType.normal,
              myLocationButtonEnabled: false,
            ),
          ),
          Container(
            padding: EdgeInsets.all(8.0),
            color: Colors.white,
            child: Row(
              children: [
                Text(
                  widget.routeName,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: Text(widget.direction == 0 ? 'Chiều đi' : 'Chiều về'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(text: 'Giờ xuất bến'),
                    Tab(text: 'Điểm dừng'),
                    Tab(text: 'Thông tin'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTimesTimeline(),
                      _buildStopsTimeline(),
                      SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(_info),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
