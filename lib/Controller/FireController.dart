import 'package:WildFireAlert/Model/Fire.dart';
import 'package:dio/dio.dart';
import 'package:csv/csv.dart';
import 'package:latlong2/latlong.dart';

String mapKey = "5fe5c4f4f19f4d995843ddb0b52935f6";

class FireController{

  Future<void> getFire() async {
    try {
      final dio = Dio();
      final response = await dio.get<String>(
        'https://firms.modaps.eosdis.nasa.gov/api/country/csv/${mapKey}/VIIRS_SNPP_NRT/GRC/1',
        options: Options(responseType: ResponseType.plain),
      );
      if (response.statusCode == 200) {
        List<List<dynamic>> csvTable = const CsvToListConverter().convert(response.data!);
        //print(csvTable);
        //TODO find a way to transform CSV read file to model
        List<dynamic> csvTablenew = csvTable[0];
        print(csvTablenew);
        //LatLng loc = LatLng(_latitude, _longitude)

      } else {
        print('Failed to load CSV: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching CSV: $e');
    }
  }


}