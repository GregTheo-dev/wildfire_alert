//country_id,
// latitude,
// longitude,
// bright_ti4,
// scan,
// track,
// acq_date,
// acq_time,
// satellite,
// instrument,
// confidence,
// version,
// bright_ti5,frp,
// daynight

import 'package:latlong2/latlong.dart';

class Fire {
  String countryId;
  LatLng location;
  double brightTi4;
  double brightTi5;
  double scan;
  double track;
  String acqDate;
  int time;

  @override
  String toString() {
    String brightTi4 = "BrightTi4: ${this.brightTi4}\n";
    String brightTi5 = "BrightTi5: ${this.brightTi5}\n";
    String scan = "Scan: ${this.scan}\n";
    String track = "Track: ${this.track}\n";
    String acqDate = "Acq Date: ${this.acqDate}\n";
    String time = "Time: ${this.time}\n";

    return brightTi4 + brightTi5 + scan + track + acqDate + time;
  }

  Fire(this.countryId, this.location, this.brightTi4, this.brightTi5, this.scan,
      this.track, this.acqDate, this.time);


  
}