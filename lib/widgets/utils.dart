import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Widget getDirectionSummaryWidget(List<dynamic> transitSteps) {
  List<Widget> rowChildren = [];
  for (int i = 0; i < transitSteps.length; i++) {
    var step = transitSteps[i];

    if (step['travelMode'] == 'WALK') {
      rowChildren.add(Icon(Icons.directions_walk, size: 16));
    } else if (step['travelMode'] == 'TRANSIT') {
      Widget combinedIconText = Row(
        mainAxisSize: MainAxisSize
            .min, // Giới hạn kích thước của Row cho phù hợp với nội dung
        children: [
          Icon(Icons.directions_bus, size: 16), // Biểu tượng bus
          SizedBox(width: 5), // Khoảng cách giữa icon và text
          Text(step['name'], style: TextStyle(fontSize: 16)), // Tên
        ],
      );
      rowChildren.add(combinedIconText);
    }

    // Thêm Icon mũi tên và khoảng cách nếu không phải phần tử cuối cùng
    if (i < transitSteps.length - 1) {
      rowChildren.add(SizedBox(width: 5)); // Khoảng cách trước mũi tên
      rowChildren
          .add(Icon(Icons.arrow_forward_ios, size: 8)); // Biểu tượng mũi tên
      rowChildren.add(SizedBox(width: 5)); // Khoảng cách sau mũi tên
    }
  }

  return Row(
    mainAxisAlignment: MainAxisAlignment.start, // Căn nội dung về phía bắt đầu
    children: rowChildren,
  );
}

Widget routeDetailHeader(
    String combinedTimeString,
    String travelTimeInMinutes,
    String busStopDepartureTime,
    String startStationInstruction,
    List<dynamic> transitSteps,
    String fare,
    int walkDuration) {
  // get current time and directionDetail["duration"] to calculate the arrival time, convert to string
  walkDuration = (walkDuration / 60).round();

  return Padding(
    padding: EdgeInsets.all(0),
    child: Card(
      // elevation: 4.0, // Độ cao của shadow
      color: Colors.white, // Màu nền của thẻ
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero, // Bo tròn các góc
      ),
      child: Container(
        width: 400, // max size of the card
        padding: EdgeInsets.only(
            top: 16.0,
            right: 16.0,
            left: 16.0,
            bottom: 0), // Padding bên trong thẻ
        child: Column(
          mainAxisSize:
              MainAxisSize.min, // Đảm bảo column chiếm không gian tối thiểu
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment
                  .spaceBetween, // Căn lề các phần tử ở hai bên
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      combinedTimeString,
                      style: TextStyle(fontSize: 20),
                    ),
                    Text(
                      travelTimeInMinutes,
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w300),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.directions_walk, size: 20), // Biểu tượng xe
                    SizedBox(width: 5), // Khoảng cách giữa các icon
                    Icon(Icons.directions_bus, size: 20), // Biểu tượng bus
                  ],
                ),
              ],
            ),
            getDirectionSummaryWidget(transitSteps),
            Row(
              children: [
                Expanded(
                  child: Text(
                      '${busStopDepartureTime} từ ${startStationInstruction}',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w300)),
                ),
              ],
            ),
            SizedBox(height: 4), // Khoảng cách nhỏ hơn
            Row(
              mainAxisAlignment: MainAxisAlignment
                  .spaceBetween, // Căn chỉnh các phần tử ở hai bên
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(fare,
                        style: TextStyle(fontSize: 14, color: Colors.black54)),
                    SizedBox(width: 24),
                    Icon(Icons.directions_walk, size: 16),
                    Text(
                      '${walkDuration} p',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ],
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    textStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    // Xử lý sự kiện khi nút được nhấn
                    print('Mua vé button pressed');
                  },
                  child: Text('Mua vé'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

Widget timeLineTileStart(String time, String location) {
  String locationHeader = location.split(',')[0];
  int commaIndex = location.indexOf(',');
  String locationDetail = location.substring(commaIndex + 1).trim();

  return Padding(
    // padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    padding: const EdgeInsets.only(right: 16.0, left: 16.0),
    child: Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Column for the timeline dots and icon
            Container(
              width: 50,
              child: Column(
                children: <Widget>[
                  Text(time,
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            ),

            SizedBox(width: 12), // Khoảng cách giữa các phần tử (dùng SizedBox

            Container(
              child: Column(
                mainAxisSize: MainAxisSize
                    .min, // Đảm bảo column chiếm không gian tối thiểu
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 0),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 2,
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 3.0),
                              child: Container(
                                width: 11,
                                height: 11,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border:
                                      Border.all(color: Colors.black, width: 2),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            for (int i = 0; i < 2; i++)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 3.0),
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ), // Khoảng cách giữa các phần tử (dùng SizedBox
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 12), // Khoảng cách giữa các phần tử (dùng SizedBox
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    locationHeader,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    locationDetail,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w300),
                    softWrap: true,
                  ),
                ],
              ),
            ),
          ],
        ), // Khoảng cách giữa các phần tử (dùng SizedBox
      ],
    ),
  );
}

Widget timeLineTileWalk(int time, int distance) {
  String travelModeVN = "Đi bộ";
  int timeMinites = (time / 60).round();

  return Padding(
    // padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    padding: const EdgeInsets.only(right: 16.0, left: 16.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Column for the timeline dots and icon
        Container(
          width: 50,
          child: Column(
            children: <Widget>[
              SizedBox(height: 28),
              Icon(Icons.directions_walk, color: Colors.blue, size: 20),
            ],
          ),
        ),

        SizedBox(width: 14.5), // Khoảng cách giữa các phần tử (dùng SizedBox

        Container(
          child: Column(
            mainAxisSize:
                MainAxisSize.min, // Đảm bảo column chiếm không gian tối thiểu
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 0),
                    child: Column(
                      children: [
                        for (int i = 0; i < 9; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3.0),
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ), // Khoảng cách giữa các phần tử (dùng SizedBox
                ],
              ),
            ],
          ),
        ),
        SizedBox(width: 12), // Khoảng cách giữa các phần tử (dùng SizedBox
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 16,
                // Để thêm một đường viền ở phía dưới Container, chúng ta cần sử dụng decoration
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey,
                      width: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                travelModeVN,
                style: TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Khoảng ${timeMinites} p, ${distance} m',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w300),
                overflow: TextOverflow.ellipsis,
              ),
              Container(
                height: 16,
                // Để thêm một đường viền ở phía dưới Container, chúng ta cần sử dụng decoration
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey,
                      width: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget timeLineTileTransit(
    String departureTime,
    String arrivalTime,
    String departureStop,
    String arrivalStop,
    String busNumber,
    String headsign,
    int timeMinites,
    int stopCount) {
  return Padding(
    // padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    padding: const EdgeInsets.only(right: 16.0, left: 16.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Column for the timeline dots and icon
        Container(
          width: 50,
          child: Column(
            children: <Widget>[
              Text(departureTime,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              SizedBox(height: 28),
              Icon(Icons.directions_bus, color: Colors.blue, size: 20),
              SizedBox(height: 54),
              Text(arrivalTime,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ),

        SizedBox(width: 12), // Khoảng cách giữa các phần tử (dùng SizedBox

        Container(
          child: Column(
            mainAxisSize:
                MainAxisSize.min, // Đảm bảo column chiếm không gian tối thiểu
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 0),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 2,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3.0),
                          child: Container(
                            width: 11,
                            height: 11,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.black, width: 2),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Container(
                          width: 6,
                          height: 110,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3.0),
                          child: Container(
                            width: 11,
                            height: 11,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.black, width: 2),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ), // Khoảng cách giữa các phần tử (dùng SizedBox
                ],
              ),
            ],
          ),
        ),
        SizedBox(width: 12), // Khoảng cách giữa các phần tử (dùng SizedBox
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                departureStop,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
              Container(
                height: 16,
                // Để thêm một đường viền ở phía dưới Container, chúng ta cần sử dụng decoration
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey,
                      width: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 5.0, vertical: 1.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(3.0),
                    ),
                    child: Text(
                      '${busNumber}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      '${headsign}',
                      style: TextStyle(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Text(
                "Khoảng ${timeMinites} p, ${stopCount} điểm dừng",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w300),
                overflow: TextOverflow.ellipsis,
              ),
              Container(
                height: 16,
                // Để thêm một đường viền ở phía dưới Container, chúng ta cần sử dụng decoration
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey,
                      width: 0.5,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 12,
              ),
              Text(
                arrivalStop,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget timeLineTileDestination(String time, String location, String fare) {
  String locationHeader = location.split(',')[0];
  int commaIndex = location.indexOf(',');
  String locationDetail = location.substring(commaIndex + 1).trim();

  return Padding(
    // padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    padding: const EdgeInsets.only(right: 16.0, left: 16.0),
    child: Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Column for the timeline dots and icon
            Container(
              width: 50,
              child: Column(
                children: <Widget>[
                  Text(time,
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            ),

            SizedBox(width: 12), // Khoảng cách giữa các phần tử (dùng SizedBox

            Container(
              child: Column(
                mainAxisSize: MainAxisSize
                    .min, // Đảm bảo column chiếm không gian tối thiểu
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 0),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 2,
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 3.0),
                              child: Container(
                                width: 11,
                                height: 11,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border:
                                      Border.all(color: Colors.black, width: 2),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ), // Khoảng cách giữa các phần tử (dùng SizedBox
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 12), // Khoảng cách giữa các phần tử (dùng SizedBox
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    locationHeader,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    locationDetail,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w300),
                    softWrap: true,
                  ),
                ],
              ),
            ),
          ],
        ), // Khoảng cách giữa các phần tử (dùng SizedBox
        Padding(
          padding: const EdgeInsets.only(
              right: 8.0, left: 8.0, top: 16.0, bottom: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text('Chi phí: ${fare}'),
            ],
          ),
        )
      ],
    ),
  );
}

List<Widget> getRouteTimeLineWidget(List<dynamic> transitStepsDetail) {
  List<Widget> timeLineTiles = [];
  for (int i = 0; i < transitStepsDetail.length; i++) {
    if (i == 0) {
      timeLineTiles.add(timeLineTileStart(
          transitStepsDetail[i]['time'], transitStepsDetail[i]['location']));
    }
    if (transitStepsDetail[i]['travelMode'] == 'WALK') {
      timeLineTiles.add(timeLineTileWalk(transitStepsDetail[i]['walkTime'],
          transitStepsDetail[i]['distance']));
    }
    if (transitStepsDetail[i]['travelMode'] == 'TRANSIT') {
      timeLineTiles.add(timeLineTileTransit(
          transitStepsDetail[i]['departureTime'],
          transitStepsDetail[i]['arrivalTime'],
          transitStepsDetail[i]['departureStop'],
          transitStepsDetail[i]['arrivalStop'],
          transitStepsDetail[i]['busNumber'],
          transitStepsDetail[i]['headsign'],
          transitStepsDetail[i]['timeMinites'],
          transitStepsDetail[i]['stopCount']));
    }
    if (i == transitStepsDetail.length - 1) {
      timeLineTiles.add(timeLineTileDestination(transitStepsDetail[i]['time'],
          transitStepsDetail[i]['location'], transitStepsDetail[i]['fare']));
    }
  }

  return timeLineTiles;
}
