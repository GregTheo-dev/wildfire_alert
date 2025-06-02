import 'dart:io';

import 'package:BusTracker/Model/BusStop.dart';
import 'package:BusTracker/Model/BusRoute.dart';
import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import '../Model/Bus.dart';

String hostname = 'https://rest.citybus.gr/api/v1/el/110';

class BusStopController{

  Future<String?> getToken() async {
    final dio = Dio();
    // Set up headers
    final headers = {
      'accept': '*/*',
      'accept-language': 'el-GR,el;q=0.9,en;q=0.8,fr;q=0.7,de;q=0.6',
      'access-control-request-headers': 'authorization,content-type',
      'access-control-request-method': 'GET',
      'origin': 'https://irakleio.citybus.gr',
      'priority': 'u=1, i',
      'referer': 'https://irakleio.citybus.gr/',
      'sec-fetch-dest': 'empty',
      'sec-fetch-mode': 'cors',
      'sec-fetch-site': 'same-site',
      'user-agent':
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
    };

    try {
      // Perform GET request with Dio
      final response = await dio.get(
        "https://irakleio.citybus.gr/el/stops",
        options: Options(
          headers: headers,
        ),
      );

      if (response.statusCode == 200) {
        // Use RegExp to extract the token from the response body
        final tokenRegex = RegExp(r"const\s+token\s+=\s+'(.*?)';");
        final match = tokenRegex.firstMatch(response.data);

        if (match != null) {
          return match.group(1); // Return the extracted token
        } else {
          return null; // No token found
        }
      } else {
        print("Error: ${response.statusCode}");
        print(response.data);
        return null;
      }
    } catch (e) {
      print("An error occurred: $e");
      return null;
    }
  }

  // Method to fetch bus stop data from NGSI-LD broker
  Future<List<BusStop>> fetchBusStops(String token) async {
    final List<BusStop> busStops = [];
    var dio = Dio();
    final response = await dio.request(
      '$hostname/stops',
      options: Options(
        method: 'GET',
        headers: {
          'Authorization': 'Bearer $token', // Add token here
        },
      ),
    );
    if(response.statusCode == 200){
      dynamic data = response.data;
      for(var busStop in data){
        List<String> lineCodes = [];
        List<String> routeCodes = [];
        //Make the line codes list
        for(var lineCode in busStop['lineCodes']){
          lineCodes.add(lineCode);
        }
        //Make the route codes list
        for (var routeCode in busStop['routeCodes']) {
          routeCodes.add(routeCode);
        }
        //Now parse all the arguments from json to class models
        BusStop bs = new BusStop(
            busStop['id'].toString(),
           // [],
            busStop['code'],
            lineCodes,
            busStop['name'],
            routeCodes,
            LatLng(busStop['latitude'],busStop['longitude'])
        );
        busStops.add(bs);
      }
      return busStops;
    }
    else {
      throw Exception("Failed to fetch bus stops: ${response.statusMessage}");
    }
  }

  List<BusStop> getBusStopsByRouteCode(List<BusStop> busStops, String routeCode)  {
    return busStops.where((busStop) {
      return busStop.routeCodes.contains(routeCode);
    }).toList();
  }

  BusStop? getStopByCode(List<BusStop> busStops, String code) {
    try {
      // Use `firstWhere` to find the first BusStop with the matching code
      return busStops.firstWhere((busStop) => busStop.code == code);
    } catch (e) {
      // Return null if no matching BusStop is found
      return null;
    }
  }



  Future<List<Bus>> fetchBusEntities(BusStop stop, String token) async {
    final List<Bus> buses = [];
    String stopCode = stop.code;
    var dio = Dio();
    final response = await dio.request(
      '$hostname/stops/live/$stopCode',
      options: Options(
        method: 'GET',
        headers: {
          'Authorization': 'Bearer $token', // Add token here
        },
      ),
    );
    if(response.statusCode == 200){
      List<dynamic> vehicles = response.data['vehicles'];
      for(var bus in vehicles){
        Bus b = new Bus(bus['lineCode'],
            bus['lineName'],
            bus['routeCode'],
            bus['routeName'],
            bus['latitude'],
            bus['longitude'],
            bus['departureMins'],
            bus['departureSeconds'],
            bus['vehicleCode'],
            bus['lineColor'],
            bus['lineTextColor'],
            bus['borderColor']
        );
        buses.add(b);
      }
      return buses;
    }
    else{
      throw Exception("Failed to fetch buses stops: ${response.statusMessage}");
    }
  }


}

