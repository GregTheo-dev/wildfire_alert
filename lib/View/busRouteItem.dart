import 'package:flutter/material.dart';
import '../Model/BusRoute.dart';
import 'colorFromHex.dart';

class BusRouteItem extends StatelessWidget {
  final BusRoute busRoute;
  //final Function(Route) onTap;  // Callback function to be executed when tapped
  BusRouteItem({required this.busRoute});
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 0.5),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: HexColor(busRoute.color),
          child: Text(busRoute.line, style: TextStyle(color: Colors.white)),
        ),
        title: Text(busRoute.name),
        //onTap: () => onTap(bus),  // Trigger the callback when tapped
      ),
    );
  }
}