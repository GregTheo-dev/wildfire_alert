import 'dart:async';
import 'package:barcode_scan2/model/scan_result.dart';
import 'package:barcode_scan2/platform_wrapper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'Model/Bus.dart';
import 'Model/BusStop.dart';
import 'View/busSchedule.dart';
import 'View/colorFromHex.dart';
import 'Controller/BusStopController.dart';
import 'package:location/location.dart' as loc;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenStreetMap with Buses',
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
  final loc.Location location = loc.Location();
  final BusStopController _busStopController = BusStopController();
  LatLng? _userLocation = null;
  List<LatLng> busStopsLocations = [];
  Timer? _timer = null;
  List<Marker> busStopMarkers = [];
  List<Bus> busEntitiesList = [];
  bool showBusList = false;
  List<Marker> busMarkers = [];
  bool isLoading = false;
  late BusStop selectedStop;
  List<BusStop> fetchedBusStops = [];
  List<BusStop> filteredBusStops = [];
  late String token;
  late Bus selectedBus;
  String appBarMessage = "Fetch bus stops to start";


  @override
  void initState() {
    super.initState();
    _getUserLocation();
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
      showBusStopsButtonPressed();
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

  // Method to create markers from bus stop data
  void createMarkersFromBusStops(List<BusStop> busStops) {
    List<Marker> markers = [];

    for (var busStop in busStops) {
      markers.add(
        Marker(
          width: 50.0,
          height: 50.0,
          point: busStop.location,
          builder: (ctx) =>
              GestureDetector(
                onTap: () async {
                  await onBusStopTap(busStop);
                },
                child: Image.asset(
                  'assets/bus-station.png',
                  width: 40.0,
                  height: 40.0,
                ),
              ),
        ),
      );
    }
    setState(() {
      busStopMarkers = markers;
      isLoading = false;
    });
  }

//Function to handle bus stop click event
  onBusStopTap(BusStop busStop) async {
    busMarkers = [];
    busEntitiesList = [];
    selectedStop = busStop;
    setState(() {
      isLoading = true; // Start loading when the request is initiated
      //busStopsLocations = [];
      _timer?.cancel();
      // showBusList = false;
    });
    try {
      busEntitiesList = await _busStopController.fetchBusEntities(busStop, token);
    }
    catch(e){
      dialogBox("Could not find buses for stop ${busStop.code}: ${busStop.name}");
      return;
    }
    //busEntitiesList = busStop.buses;
    appBarMessage = "Found total ${busEntitiesList.length} buses";
    if (busEntitiesList.length == 0) {
      setState(() {
        isLoading = false;
      });
    }
    else {
      filteredBusStops = [];
      filteredBusStops.add(busStop);
      createMarkersFromBusStops(filteredBusStops);
      createMarkersFromBusEntities(busEntitiesList);
      setState(() {
        isLoading = false;
        showBusList = true;
      });
    }
    int loopCount  = 0;
    _timer = Timer.periodic(Duration(seconds: 5), (Timer t) async{
      if(kDebugMode)
        print("Loop#$loopCount");
      busEntitiesList = [];
      try {
        busEntitiesList = await _busStopController.fetchBusEntities(busStop, token);
      }
      catch(e){
        dialogBox("Could get buses for this stop: $e");
        _timer?.cancel();
      }
      //busEntitiesList = busStop.buses;
      createMarkersFromBusEntities(busEntitiesList);
      loopCount++;
    });
  }

  // Create markers from bus entities
  void createMarkersFromBusEntities(List<Bus> buses) {
    int count = 0;
    List<Marker> markers = [];
    if(kDebugMode) {
      var len = buses.length;
      print("Found total $len buses");
    }
    for (var bus in buses) {
      try {
        final lat = double.parse(bus.latitude); // Latitude
        final lng = double.parse(bus.longitude); // Longitude
        if(lat == 0  || lng == 0){
          count++;
          continue;
        }
        markers.add(
          Marker(
            width: 50.0,
            height: 50.0,
            point: LatLng(lat, lng),
            builder: (ctx) =>
                GestureDetector(
                  onTap: () async {
                    // Handle the bus stop click event
                    await onBusTapFromMarkers(bus);
                  },
                  child: Icon(Icons.directions_bus_filled,
                    color: HexColor(bus.lineColor),
                    size: 40,),
                ),
          ),
        );
        if (markers.isEmpty) {
          if (kDebugMode) {
            print("No buses for this stop");
          }
          dialogBox("No upcoming buses for this stop");
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing bus entity data: $e');
        }
      }
    }
    if(count == buses.length){
      _timer?.cancel();
    }

    setState(() {
      busMarkers = markers;
    });
  }

  onBusTapFromList(Bus bus) async {
    selectedBus = bus;
    final lat = double.parse(bus.latitude);
    final lng = double.parse(bus.longitude);
    String routeCode = bus.routeCode;
    filteredBusStops = _busStopController.getBusStopsByRouteCode(fetchedBusStops, routeCode);
    createMarkersFromBusStops(filteredBusStops);
    setState(() {
      if(lat != 0 && lng != 0)
        _mapController.move(LatLng(lat, lng), 17.0); // Move to the bus location
      //showBusList = false; // Hide the bus list
    });
  }

  onBusTapFromMarkers(Bus bus) async {
    selectedBus = bus;
    String routeCode = bus.routeCode;
    filteredBusStops = _busStopController.getBusStopsByRouteCode(fetchedBusStops, routeCode);
    createMarkersFromBusStops(filteredBusStops);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Bus Info'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Bus number: ${bus.lineCode}'),
              Text('Route: ${bus.routeName}'),

            ],
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

  showBusStopInfo(BusStop stop){
    String name = stop.name;
    String code = stop.code;
    dynamic lineCodes = stop.lineCodes;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Stop Info'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Stop name: $name'),
              Text('Stop code: $code'),
              Text('Line codes: ${lineCodes}'),
            ],
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
  }

  stopTracking() {
    if (_timer == null) {
      dialogBox("No active tracking");
      return;
    }
    _timer?.cancel();
    _timer = null;
    setState(() {
      showBusList = false;
    });
    dialogBox("Tracking stopped");
  }

  Icon isUserLocatedIcon(){
    if(_userLocation != null){
      return Icon(Icons.my_location, size: 30,);
    }
    return Icon(Icons.location_disabled, size: 30,);
  }

  List<BusStop> findBusStopsWithinBounds(double? southWestLat, double? southWestLong, double? northEastLat, double? northEastLong) {
    if (southWestLat == null ||
        southWestLong == null ||
        northEastLat == null ||
        northEastLong == null) {
      // If any of the bounds are null, return an empty list
      return [];
    }
    return fetchedBusStops.where((busStop) {
      LatLng location = busStop.location;
      // Check if the bus stop's location falls within the bounds
      return location.latitude >= southWestLat &&
          location.latitude <= northEastLat &&
          location.longitude >= southWestLong &&
          location.longitude <= northEastLong;
    }).toList();
  }

  showBusStopsButtonPressed() async {
    if(fetchedBusStops.isEmpty) {
      token = (await _busStopController.getToken())!;
      fetchedBusStops = await _busStopController.fetchBusStops(token);
    }
    double? southWestLat = _mapController.bounds?.southWest.latitude;
    double? southWestLong = _mapController.bounds?.southWest.longitude;
    double? northEastLat = _mapController.bounds?.northEast.latitude;
    double? northEastLong = _mapController.bounds?.northEast.longitude;
    filteredBusStops = findBusStopsWithinBounds(southWestLat, southWestLong, northEastLat, northEastLong);
    createMarkersFromBusStops(filteredBusStops);
  }


  void getStopByQRCode() async {
    var result = await BarcodeScanner.scan();
    String value = result.rawContent;
    //TODO get the code right. Check the QR code result
    String code = value.split('/').last;
    try {
      if(fetchedBusStops.isEmpty){
        token = (await _busStopController.getToken())!;
        fetchedBusStops = await _busStopController.fetchBusStops(token);
      }
      BusStop? bs = await _busStopController.getStopByCode(fetchedBusStops, code);
      if (bs != null) {
        await onBusStopTap(bs);
        _mapController.move(bs.location, 16);
      }
    }
    catch(e){
      dialogBox("Could not find bus stop $value: $e");
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: Text(appBarMessage),
        centerTitle: true,
        backgroundColor: Colors.lightGreenAccent,
      ),
      body: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                //NOTE: Change if we extend this app to another town with similar telematics system
                  center: LatLng(35.3387, 25.1442),
                  // Initial map center (Heraklion)
                  zoom: 13.5,
                  // Initial zoom level
                  minZoom: 3.0,
                  maxZoom: 18
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'], // OSM tile servers
                ),
                MarkerLayer(markers: busStopMarkers),
                MarkerLayer(markers: busMarkers),
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
                if (isLoading)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),

            //Show bus stops button
            Positioned(
              top: 3,
              left: 10,
              child: ElevatedButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.lightGreenAccent,
                    padding: EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    // Padding inside the button
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),),
                  ),
                  onPressed: showBusStopsButtonPressed,
                  child: Text("Show bus stops on this area",
                    textAlign: TextAlign.center,)
              ),
            ),

            //Search bar
            Positioned(
              top: 60,
              left: 10,
              width: 210,
              height: 45,
              child: TextField(
                //controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Find stop by code',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.search),
                    onPressed: () {
                    },
                  ),
                ),
                onSubmitted: (String value) async {
                  //Call getStopByCode when the user presses enter or submits
                  try {
                    if(fetchedBusStops.isEmpty){
                      token = (await _busStopController.getToken())!;
                      fetchedBusStops = await _busStopController.fetchBusStops(token);
                    }
                    BusStop? bs = await _busStopController.getStopByCode(fetchedBusStops, value);
                    if (bs != null) {
                      await onBusStopTap(bs);
                      _mapController.move(bs.location, 16);
                    }
                  }
                  catch(e){
                      dialogBox("Could not find bus stop $value: $e");
                  }
                },
              ),
            ),

            //Stop tracking button
            Positioned(
              top: 3,
              right: 10,
              child: ElevatedButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.lightGreenAccent,
                    padding: EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    // Padding inside the button
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),),
                  ),
                  onPressed: stopTracking,
                  child: Text("Stop Tracking",
                    textAlign: TextAlign.center,)
              ),
            ),

            //QR button
            Positioned(
              top: 120,
              left: 10,
              child: ElevatedButton(
                  style: TextButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: Colors.lightGreenAccent,
                      shape: CircleBorder(),
                      minimumSize: Size(50, 50)
                  ),
                  onPressed: getStopByQRCode,
                  child: Icon(Icons.qr_code_2, size: 30,),
              ),
            ),

            //User location button
            Positioned(
              top: 60,
              right: 10,
              child: ElevatedButton(
                  style: TextButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: Colors.lightGreenAccent,
                      shape: CircleBorder(),
                      minimumSize: Size(50, 50)
                  ),
                  onPressed: _getUserLocation,
                  child: isUserLocatedIcon()
              ),
            ),

            //Show bus list
            if(showBusList)
              Positioned(
                  top: screenHeight / 2,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                      color: Colors.lightGreenAccent,
                      child: BusScheduleWidget(
                        busEntities: busEntitiesList,
                        busTapped: onBusTapFromList,
                        stopInfo: "${selectedStop.code}-${selectedStop.name}")
                  )
              ),

            if(showBusList)
            //Bus stop info button
              Positioned(
                  top: screenHeight / 2.3,
                  left: 10,
                  child: ElevatedButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.lightGreenAccent,
                      shape: CircleBorder(),
                    ),
                    onPressed: () {
                      showBusStopInfo(selectedStop);
                    },
                    child:
                    Icon(Icons.info_outlined,size: 30),
                  )
              ),

            if(showBusList)
            //Close button
              Positioned(
                  top: screenHeight / 2.3,
                  right: 10,
                  child: ElevatedButton(
                    style: TextButton.styleFrom(
                        backgroundColor: Colors.lightGreenAccent,
                        minimumSize: Size(40, 40)
                    ),
                    onPressed: () {
                      setState(() {
                        _timer?.cancel();
                        showBusList = false;
                        busEntitiesList = [];
                      });},
                    child:
                    Text("Close"),
                  )
              ),
          ]
      ),
    );
  }
}
