import 'package:WildFireAlert/Model/Fire.dart';
import 'package:dio/dio.dart';
import 'package:csv/csv.dart';
import 'package:latlong2/latlong.dart';

String mapKey = "5fe5c4f4f19f4d995843ddb0b52935f6";

class FireController{

  Future<List<Fire>> getFires() async {
    try {
      final dio = Dio();
      final response = await dio.get<String>(
        'https://firms.modaps.eosdis.nasa.gov/api/country/csv/${mapKey}/VIIRS_SNPP_NRT/GRC/1',
        options: Options(responseType: ResponseType.plain),
      );
      if (response.statusCode == 200) {
        List<Fire> fires = [];
        List<List<dynamic>> csvTable = const CsvToListConverter().convert(response.data!);
        //No fires
        if(csvTable.length == 1){
         return [];
        }
        for(var row in csvTable.sublist(1)){
          //Make a new fire
          LatLng loc = LatLng(row[1], row[2]);
          Fire fire = Fire(row[0], loc, row[3], row[12], row[4], row[5], row[6], row[7]);
          //Add to fires list
          fires.add(fire);
        }
        return fires;
      } else {
        print('Failed to load CSV: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching CSV: $e');
      return [];
    }
  }
}