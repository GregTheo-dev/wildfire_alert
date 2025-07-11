import 'dart:async';
import 'package:WildFireAlert/Controller/FireController.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart' as loc;

import 'Model/Fire.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenStreetMap with Fires',
      theme: ThemeData(
        primarySwatch: Colors.lightGreen,
      ),
      home:  MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  MapScreen({super.key});
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final FireController _fireController = FireController();
  List<Fire> fires = [];
  final loc.Location location = loc.Location();
  List<Marker> fireMarkers = [];
  LatLng? _userLocation = null;
  bool showBusList = false;
  bool isLoading = false;
  late String token;


  @override
  void initState() {
    super.initState();
    _getUserLocation();
    getFires();
  }

  void onFireTap(Fire fire){
    String fireInfo = "";
    //TODO
  }

  Future<void> getFires() async {
    fires = await _fireController.getFires();
    if(fires.isEmpty){
      dialogBox("No fires detected");
    }
    List<Marker> markers = [];
    for (var fire in fires) {
      markers.add(
        Marker(
          width: 50.0,
          height: 50.0,
          point: fire.location,
          builder: (ctx) =>
              GestureDetector(
                onTap: () {
                  onFireTap(fire);
                },
                child: Icon(Icons.local_fire_department, color: Colors.red,),
              ),
        ),
      );
    }
    fireMarkers = markers;
    setState(() {

    });
  }


  // Function to show dialog prompting user to enable location services
  Future<bool> _showLocationServicesDialog() async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Location Services'),
        content: Text('Enable location services?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false); // User pressed "No"
            },
            child: Text('No'),
          ),
          TextButton(
            onPressed: () async {
              await Geolocator.openLocationSettings(); // Open location settings
              Navigator.of(context).pop(true); // User pressed "Yes"
            },
            child: Text('Yes'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Show a dialog asking the user to enable location services
      bool result = await _showLocationServicesDialog();
      if (!result) {
        return; // User declined to enable location services
      }
    }

    // Check for location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if(kDebugMode)
          print("Location permissions are denied");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if(kDebugMode)
        print("Location permissions are permanently denied");
      return;
    }

    // Get the current position
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    // Update the user location and move the map to the user's location
    setState(() {
      _userLocation = LatLng(position.latitude, position.longitude);
      _mapController.move(_userLocation!, 17.0);
      // Get the coordinates of the bounds
      location.onLocationChanged.listen((loc.LocationData currentLocation)
      {
        setState(()
        {
          LatLng newLocation = LatLng(currentLocation.latitude as double, currentLocation.longitude as double);
          //_mapController.move(newLocation, _mapController.zoom);
          _userLocation = newLocation;
        });
      });
    });
    if(kDebugMode)
      print("User location: ${_userLocation?.latitude}, ${_userLocation?.longitude}");
  }

  dialogBox(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(message),
          content: const Column(
              mainAxisSize: MainAxisSize.min
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
    setState(() {
      isLoading = false;
      if (kDebugMode) {
        print("Loading complete...");
      }
    });
  }

  Icon isUserLocatedIcon(){
    if(_userLocation != null){
      return Icon(Icons.my_location, size: 30,);
    }
    return Icon(Icons.location_disabled, size: 30,);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Wildfire Alert Greece"),
        centerTitle: true,
        backgroundColor: Colors.lightGreenAccent,
      ),
      body: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                  center: LatLng(38, 24.5),
                  zoom: 7,
                  // Initial zoom level
                  minZoom: 3.0,
                  maxZoom: 18
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'], // OSM tile servers
                  userAgentPackageName: 'com.me.wildfire_alert',
                ),
                MarkerLayer(
                    markers: fireMarkers
                ),
                if (_userLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 80.0,
                        height: 80.0,
                        point: _userLocation!,
                        builder: (ctx) => Icon(
                          Icons.location_on_rounded,
                          color: Colors.red,
                          size: 40.0,
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            //User location button
            Positioned(
              bottom: 40,
              right: 10,
              child: ElevatedButton(
                  style: TextButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: Colors.lightGreenAccent,
                      shape: CircleBorder(),
                      minimumSize: Size(60, 60)
                  ),
                  onPressed: _getUserLocation,
                  child: isUserLocatedIcon()
              ),
            ),
          ]
      ),
    );
  }
}
