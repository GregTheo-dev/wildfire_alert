import 'package:latlong2/latlong.dart';
import 'Bus.dart';

class BusStop {
  final String id;
  //late  List<Bus> buses;
  final String code;
  final List<String> lineCodes;
  final String name;
  final List<String> routeCodes;
  final LatLng location;

  BusStop(
    this.id,
    //this.buses,
    this.code,
    this.lineCodes,
    this.name,
    this.routeCodes,
    this.location);
}
