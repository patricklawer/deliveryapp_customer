import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class DropoffScreen extends StatefulWidget {
  final LatLng pickupLocation;
  final String pickupAddress;

  const DropoffScreen({
    Key? key,
    required this.pickupLocation,
    required this.pickupAddress,
  }) : super(key: key);

  @override
  State<DropoffScreen> createState() => _DropoffScreenState();
}

class _DropoffScreenState extends State<DropoffScreen> {
  late GoogleMapController _mapController;
  final TextEditingController _dropoffController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  LatLng? _dropoffLocation;
  String? _dropoffAddress;
  List<dynamic> _dropoffSuggestions = [];

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  double? _distanceInKm;
  String? _durationText;
  double? _fare;

  bool _isLoading = false;
  String _sessionToken = DateTime.now().millisecondsSinceEpoch.toString();

  final String _googleMapsApiKey = 'AIzaSyCDSXzvZs4MWapFz2Y1WapNeXL8WmMeWis';

  @override
  void initState() {
    super.initState();
    _addMarker(widget.pickupLocation, 'pickup', 'Pickup');
  }

  void _addMarker(LatLng pos, String id, String title) {
    _markers.removeWhere((m) => m.markerId.value == id);
    _markers.add(
      Marker(
        markerId: MarkerId(id),
        position: pos,
        infoWindow: InfoWindow(title: title),
      ),
    );
    setState(() {});
  }

  Future<void> _searchPlace(String input) async {
    if (input.length < 3) return;
    final url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&components=country:gh&sessiontoken=$_sessionToken&key=$_googleMapsApiKey';
    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (data['status'] == 'OK') {
      setState(() => _dropoffSuggestions = data['predictions']);
    } else {
      debugPrint('Autocomplete error: ${data['status']} - ${data['error_message'] ?? ''}');
    }
  }

  Future<void> _selectPlace(String placeId) async {
    setState(() => _isLoading = true);

    final url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&sessiontoken=$_sessionToken&key=$_googleMapsApiKey';
    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (data['status'] == 'OK') {
      final location = data['result']['geometry']['location'];
      final latLng = LatLng(location['lat'], location['lng']);
      final address = data['result']['formatted_address'] ?? data['result']['name'];

      setState(() {
        _dropoffLocation = latLng;
        _dropoffAddress = address;
        _dropoffController.text = address;
        _dropoffSuggestions = [];
        _focusNode.unfocus();
        _addMarker(latLng, 'dropoff', 'Drop-off');
      });

      _mapController.animateCamera(CameraUpdate.newLatLngZoom(latLng, 14));
      await _drawRoute();
      await _calculateFare();
    } else {
      debugPrint('Place details error: ${data['status']} - ${data['error_message'] ?? ''}');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load place details.')));
    }

    setState(() => _isLoading = false);
  }

  Future<void> _drawRoute() async {
    final origin = widget.pickupLocation;
    final destination = _dropoffLocation!;
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$_googleMapsApiKey';

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (data['status'] == 'OK') {
      final points = data['routes'][0]['overview_polyline']['points'];
      final polylinePoints = _decodePolyline(points);

      setState(() {
        _polylines.clear();
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            color: Colors.green,
            width: 5,
            points: polylinePoints,
          ),
        );
      });
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, lat = 0, lng = 0;

    while (index < encoded.length) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return polyline;
  }

  Future<void> _calculateFare() async {
    final origin = widget.pickupLocation;
    final destination = _dropoffLocation!;
    final url =
        'https://maps.googleapis.com/maps/api/distancematrix/json?units=metric&origins=${origin.latitude},${origin.longitude}&destinations=${destination.latitude},${destination.longitude}&key=$_googleMapsApiKey';

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (data['status'] == 'OK') {
      final element = data['rows'][0]['elements'][0];
      final distanceText = element['distance']['text'];
      final durationText = element['duration']['text'];

      final distance = double.tryParse(distanceText.replaceAll(RegExp(r'[^0-9.]'), ''));
      final estimatedFare = (distance ?? 0) * 2 + 3;

      setState(() {
        _distanceInKm = distance;
        _durationText = durationText;
        _fare = estimatedFare;
      });

      _showSummaryBottomSheet();
    }
  }

  void _showSummaryBottomSheet() {
    if (_dropoffLocation == null || _fare == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(16, 24, 16, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 16),
            const Text("Ride Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _summaryRow(Icons.location_on, "Pickup", widget.pickupAddress),
            _summaryRow(Icons.flag, "Drop-off", _dropoffAddress ?? ''),
            _summaryRow(Icons.access_time, "Duration", "$_durationText • ${_distanceInKm?.toStringAsFixed(1)} km"),
            const Divider(),
            Row(
              children: [
                const Icon(Icons.attach_money, color: Colors.green),
                const SizedBox(width: 10),
                Text("Estimated Fare: GHS ${_fare!.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Ride Confirmed!")),
                );
              },
              icon: const Icon(Icons.check_circle),
              label: const Text("Confirm Ride"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[700]),
          const SizedBox(width: 10),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Drop-off"), backgroundColor: Colors.green),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _dropoffController,
              focusNode: _focusNode,
              onChanged: _searchPlace,
              decoration: InputDecoration(
                hintText: "Enter drop-off location",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          if (_dropoffSuggestions.isNotEmpty)
            Container(
              color: Colors.white,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _dropoffSuggestions.length,
                itemBuilder: (_, index) {
                  final suggestion = _dropoffSuggestions[index];
                  return ListTile(
                    title: Text(suggestion['description']),
                    onTap: () => _selectPlace(suggestion['place_id']),
                  );
                },
              ),
            ),
          if (_isLoading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: GoogleMap(
              onMapCreated: (controller) => _mapController = controller,
              initialCameraPosition: CameraPosition(target: widget.pickupLocation, zoom: 14),
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
          ),
        ],
      ),
    );
  }
}
