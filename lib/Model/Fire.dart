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
  DateTime acqDateTime;

  Fire(this.countryId, this.location, this.brightTi4, this.brightTi5, this.scan,
      this.track, this.acqDateTime);
  
}