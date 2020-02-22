import 'package:location/location.dart';

/// Location wrapper class. checks location permissions and listens 
/// to location changes.
class LocationWrapper {

  var location = new Location();

  // method to call when location changes. Publishes the location to mqtt server (mosquitto)
  final Function(LocationData) onLocationChanged;

  LocationWrapper(this.onLocationChanged);

  /// Checks whether location permission is granted. If not, 
  /// requests permission.
  /// 
  /// If permission granted, dispatches method to subscribe(listen) to location changes
  void prepareLocationMonitoring() {
    location.hasPermission().then((bool hasPermission) {
      if (!hasPermission) {
        location.requestPermission().then((bool permissionGranted) {
          if (permissionGranted) {
            _subscribeToLocation();
          }
        });
      } else {
        _subscribeToLocation();
      }
    });
  }

  /// Listens to location changes
  ///  
  void _subscribeToLocation() {
    location.onLocationChanged().listen((LocationData newLocation) {
      onLocationChanged(newLocation);
    });
  }

}