import 'package:flutter/material.dart';

Widget get_direction_summary_widget(List<dynamic> transitSteps) {
  List<Widget> rowChildren = [];
  for (var step in transitSteps) {
    if (step['travelMode'] == 'WALK') {
      rowChildren.add(Icon(Icons.directions_walk, size: 16));
    } else if (step['travelMode'] == 'TRANSIT') {
      rowChildren.add(Icon(Icons.directions_bus, size: 16));
    }

    rowChildren.add(SizedBox(width: 5)); // Add spacing between icons

    if (step['travelMode'] == 'TRANSIT') {
      rowChildren.add(Text(step['name'], style: TextStyle(fontSize: 16)));
    }
  }

  return Row(
    mainAxisAlignment:
        MainAxisAlignment.start, // Center the content horizontally
    children: rowChildren,
  );
}
