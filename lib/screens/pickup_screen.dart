import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dropoff_screen.dart';

class PickupScreen extends StatefulWidget {
  const PickupScreen({super.key});

  @override
  State<PickupScreen> createState() => _PickupScreenState();
}

class _PickupScreenState extends State<PickupScreen> {
  late GoogleMapController _mapController;
  LatLng? _pickupLocation;
  final TextEditingController _pickupController = TextEditingController();
  final FocusNode _pickupFocus = FocusNode();
  List<dynamic> _pickupSuggestions = [];
  Set<Marker> _markers = {};

  final String _googleMapsApiKey = 'AIzaSyCDSXzvZs4MWapFz2Y1WapNeXL8WmMeWis';

  final List<Map<String, dynamic>> _rideTypes = [
    {'name': 'Bike Express', 'icon': Icons.pedal_bike, 'multiplier': 1.0},
    {'name': 'Car Express', 'icon': Icons.directions_car, 'multiplier': 1.5},
    {'name': 'Cargo Express', 'icon': Icons.local_shipping, 'multiplier': 2.2},
  ];

  @override
  void initState() {
    super.initState();
    _setInitialLocation();
  }

  Future<void> _setInitialLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception("Location services are disabled.");

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception("Location permission denied.");
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception("Location permissions are permanently denied.");
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _pickupLocation = LatLng(position.latitude, position.longitude);
    } catch (e) {
      _pickupLocation = const LatLng(5.6037, -0.1870); // Accra fallback
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Using default location: $e")));
    }

    _addMarker(_pickupLocation!, "pickup", "Pickup Location");
    setState(() {});
  }

  void _addMarker(LatLng pos, String id, String title) {
    _markers.removeWhere((m) => m.markerId.value == id);
    _markers.add(Marker(markerId: MarkerId(id), position: pos, infoWindow: InfoWindow(title: title)));
  }

  Future<void> _searchPlace(String input) async {
    final url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&types=geocode&components=country:gh&key=$_googleMapsApiKey';
    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (data['status'] == 'OK') {
      setState(() {
        _pickupSuggestions = data['predictions'];
      });
    } else {
      debugPrint('Autocomplete error: ${data['status']} - ${data['error_message'] ?? ''}');
    }
  }

  Future<void> _selectPlace(String placeId) async {
    final url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_googleMapsApiKey';
    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (data['status'] == 'OK') {
      final location = data['result']['geometry']['location'];
      final latLng = LatLng(location['lat'], location['lng']);
      final address = data['result']['formatted_address'] ?? data['result']['name'];

      setState(() {
        _pickupLocation = latLng;
        _pickupController.text = address;
        _pickupSuggestions = [];
        _pickupFocus.unfocus();
        _addMarker(latLng, "pickup", "Pickup Location");
      });

      _mapController.animateCamera(CameraUpdate.newLatLngZoom(latLng, 14));
    } else {
      debugPrint('Place details error: ${data['status']} - ${data['error_message'] ?? ''}');
    }
  }

  void _showRideOptions() {
    if (_pickupLocation == null) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Choose Ride Type", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 0.8,
              children: _rideTypes.map((ride) {
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DropoffScreen(
                          pickupLocation: _pickupLocation!,
                          pickupAddress: _pickupController.text,
                        ),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.green.shade100,
                        child: Icon(ride['icon'], size: 30, color: Colors.green),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        ride['name'],
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }).toList(),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInput() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            controller: _pickupController,
            focusNode: _pickupFocus,
            onChanged: _searchPlace,
            decoration: InputDecoration(
              hintText: "Enter pickup location",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
        if (_pickupSuggestions.isNotEmpty)
          Container(
            color: Colors.white,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _pickupSuggestions.length,
              itemBuilder: (_, index) {
                final suggestion = _pickupSuggestions[index];
                return ListTile(
                  title: Text(suggestion['description']),
                  onTap: () => _selectPlace(suggestion['place_id']),
                );
              },
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pickup Location"),
        backgroundColor: Colors.green,
      ),
      body: _pickupLocation == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildLocationInput(),
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  onMapCreated: (controller) => _mapController = controller,
                  initialCameraPosition: CameraPosition(target: _pickupLocation!, zoom: 14),
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                ),
                Positioned(
                  bottom: 30,
                  left: 20,
                  right: 20,
                  child: ElevatedButton(
                    onPressed: _showRideOptions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Select Ride Type", style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
