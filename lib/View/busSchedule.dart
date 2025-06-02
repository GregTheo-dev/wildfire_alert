import 'package:flutter/material.dart';
import '../Model/Bus.dart';
import 'colorFromHex.dart';



class BusListItem extends StatelessWidget {
  final bus;
  final Function(Bus) onTap;  // Callback function to be executed when tapped

  BusListItem({required this.bus, required this.onTap});

  Icon getLocationIcon() {
    final lat = double.parse(bus.latitude);
    final long = double.parse(bus.longitude);
    if(lat == 0 || long == 0 || lat.abs() > 90 || long.abs() > 180) {
      return Icon(Icons.location_off, color: Colors.red);
    }
    return Icon(Icons.location_on, color: Colors.green);
  }


  Text getBusArrivalTimeText(){
    return Text('Scheduled departure in ${bus.departureMins}\' : ${bus.departureSeconds}\"');
  }


  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: HexColor(bus.lineColor),
          child: Text(bus.lineCode, style: TextStyle(color: Colors.white)),
        ),
        title: Text(bus.routeName),
        subtitle: getBusArrivalTimeText(),
        trailing: getLocationIcon(),
        onTap: () => onTap(bus),  // Trigger the callback when tapped
      ),
    );
  }
}


class BusScheduleWidget extends StatelessWidget {
  final List<Bus> busEntities;
  final String stopInfo;
  final Function(Bus) busTapped;
  BusScheduleWidget({required this.busEntities, required this.busTapped, required this.stopInfo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stopInfo,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: busEntities.length,
              itemBuilder: (context, index) {
                final bus = busEntities[index];
                return BusListItem(
                  bus: bus,
                  onTap: busTapped,  // Pass the busTapped callback to each BusListItem
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

