import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:io';

class UserLocation {
  final double latitude;
  final double longitude;
  final String address;

  UserLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  UserLocation? _currentLocation;
  UserLocation? get currentLocation => _currentLocation;

  Future<UserLocation?> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    Position position = await Geolocator.getCurrentPosition();
    
    String address = "Unknown Location";
    if (Platform.isWindows) {
        address = "Chennai, TN"; 
    } else {
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );
          if (placemarks.isNotEmpty) {
            Placemark place = placemarks[0];
            address = place.locality ?? place.subAdministrativeArea ?? "Chennai, TN";
          }
        } catch (e) {
          print("LocationService: Reverse geocoding failed: $e");
          address = "Chennai, TN"; // Fallback to a reasonable default for this app
        }
    }

    _currentLocation = UserLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      address: address,
    );
    
    return _currentLocation;
  }

  UserLocation _getManualFallback(String address) {
    String normalized = address.toLowerCase();
    if (normalized.contains("chennai")) {
      return UserLocation(latitude: 13.0827, longitude: 80.2707, address: "Chennai");
    } else if (normalized.contains("nagar")) {
      return UserLocation(latitude: 13.0418, longitude: 80.2341, address: "T. Nagar");
    } else if (normalized.contains("adyar")) {
      return UserLocation(latitude: 13.0033, longitude: 80.2550, address: "Adyar");
    } else if (normalized.contains("velachery")) {
      return UserLocation(latitude: 12.9815, longitude: 80.2184, address: "Velachery");
    } else if (normalized.contains("anna nagar")) {
      return UserLocation(latitude: 13.0850, longitude: 80.2101, address: "Anna Nagar");
    } else {
      // Default to Chennai center
      return UserLocation(latitude: 13.0827, longitude: 80.2707, address: address);
    }
  }

  Future<UserLocation?> getLocationFromAddress(String address) async {
    print("LocationService: Attempting to geocode: $address");
    if (address.isEmpty) return null;

    // Use geocoding service only on supported mobile platforms
    bool isMobile = Platform.isIOS || Platform.isAndroid;
    
    if (isMobile) {
      try {
        List<Location> locations = await locationFromAddress(address);
        if (locations.isNotEmpty) {
          Location loc = locations[0];
          String cleanAddress = address;
          try {
            List<Placemark> placemarks = await placemarkFromCoordinates(loc.latitude, loc.longitude);
            if (placemarks.isNotEmpty) {
              cleanAddress = placemarks[0].locality ?? address;
            }
          } catch (_) {}

          _currentLocation = UserLocation(
            latitude: loc.latitude,
            longitude: loc.longitude,
            address: cleanAddress,
          );
          return _currentLocation;
        }
      } catch (e) {
        print("LocationService: Geocoding package failed: $e. Using fallback.");
      }
    }

    // Fallback for Desktop or if package fails
    _currentLocation = _getManualFallback(address);
    return _currentLocation;
  }

  void setManualLocation(double lat, double lng, String address) {
    _currentLocation = UserLocation(latitude: lat, longitude: lng, address: address);
  }
}
