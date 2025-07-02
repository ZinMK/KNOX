import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'createApptPage.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _controller;
  Set<Marker> _markers = {};
  String? _userId;
  bool _isLoading = true;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      await _loadMarkers().then((value) async {
        _userId = FirebaseAuth.instance.currentUser?.uid;
        _currentPosition = await _determinePosition();
      });
    } catch (e) {
      print('Error initializing map: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Position> _determinePosition() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.high),

        // desiredAccuracy: LocationAccuracy.high,
      );

      return position;
    } catch (e) {
      print('Error getting position: $e');
      throw e;
    }
  }

  void _onLongPress(LatLng latLng) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _MarkerTypeDialog(),
    );
    if (result != null && _userId != null) {
      try {
        // Get current date in YYYYMMDD format
        final now = DateTime.now();
        final dateStr =
            '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

        final namedocref =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .get();

        // throws if 'name' is missing, or returns null if it's explicitly stored as null
        String? ownerName = namedocref.get('name') as String?;

        final doc = await FirebaseFirestore.instance.collection('Markers').add({
          'lat': latLng.latitude,
          'lng': latLng.longitude,
          'type': result['type'],
          'note': result['note'],
          'timestamp': FieldValue.serverTimestamp(),
          'ownerID': _userId,
          'ownerName': ownerName ?? "",
        });

        final icon = await _getCustomMarker(result['type']);
        // Add marker to map
        setState(() {
          _markers.add(
            Marker(
              markerId: MarkerId(doc.id),
              position: latLng,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                _getMarkerColor(result['type']),
              ),
              infoWindow: InfoWindow(
                title:
                    result['type'][0].toUpperCase() +
                    result['type'].substring(1),
                snippet: result['note'],
              ),
            ),
          );
        });
      } catch (e) {
        print('Error adding marker: $e');
      }
    }
  }

  Future<BitmapDescriptor> _getCustomMarker(String type) async {
    String assetName = '';
    switch (type) {
      case 'lead':
        assetName = 'assets/markers/lead_marker.png';
        break;
      case 'sale':
        assetName = 'assets/markers/sale_marker.png';
        break;
      case 'rejection':
        assetName = 'assets/markers/rejection_marker.png';
        break;
      case 'no_response':
        assetName = 'assets/markers/no_response_marker.png';
        break;
      default:
        assetName = 'assets/markers/lead_marker.png';
    }
    return BitmapDescriptor.asset(const ImageConfiguration(), assetName);
  }

  Future<void> _loadMarkers() async {
    if (_userId == null) return;
    try {
      // Get all marker documents in Markers
      final markerDocs =
          await FirebaseFirestore.instance.collection('Markers').get();
      Set<Marker> allMarkers = {};

      allMarkers.addAll(
        await Future.wait(
          markerDocs.docs.map((doc) async {
            final data = doc.data();
            final type = data['type'] ?? 'lead';
            final icon = await _getCustomMarker(type);
            return Marker(
              markerId: MarkerId(doc.id),
              position: LatLng(data['lat'], data['lng']),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                _getMarkerColor(type),
              ),
              infoWindow: InfoWindow(
                title: type[0].toUpperCase() + type.substring(1),
                snippet: data['note'] ?? '',
              ),
              onTap: () => _onMarkerTap(doc.id, doc.id, data),
            );
          }),
        ),
      );

      setState(() {
        _markers = allMarkers;
      });
    } catch (e) {
      print('Error loading markers: $e');
    }
  }

  void _onMarkerTap(
    String dateId,
    String markerId,
    Map<String, dynamic> data,
  ) async {
    bool mymarker = data["ownerID"] == FirebaseAuth.instance.currentUser!.uid;
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final timestamp = data['timestamp'];
        DateTime? dateTime;
        if (timestamp is Timestamp) {
          dateTime = timestamp.toDate();
        } else if (timestamp is DateTime) {
          dateTime = timestamp;
        }
        String dateString =
            dateTime != null
                ? DateFormat("MMM/dd/yyyy h:mm a").format(dateTime)
                : 'No date';

        return ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              isThreeLine: true,
              title: Text('${data['type']}'),
              subtitle: Text(
                '\nknocker: ${data['ownerName']} at $dateString' +
                    "\nnote: ${data['note']}",
              ),
            ),
            if (data['type'] == 'lead' || data['type'] == 'sale' && mymarker)
              ListTile(
                leading: Icon(Icons.open_in_new),
                title: Text('Go to Create Appointment'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateApptPage(data: data),
                    ),
                  );
                },
              ),
            if (mymarker)
              ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit'),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder:
                        (context) => _MarkerTypeDialog(
                          initialType: data['type'],
                          initialNote: data['note'],
                        ),
                  );
                  if (result != null && _userId != null) {
                    await FirebaseFirestore.instance
                        .collection('Markers')
                        .doc(markerId)
                        .update({
                          'type': result['type'],
                          'note': result['note'],
                        });
                    _loadMarkers();
                  }
                },
              ),
            if (mymarker)
              ListTile(
                leading: Icon(Icons.delete),
                title: Text('Delete'),
                onTap: () async {
                  await FirebaseFirestore.instance
                      .collection('Markers')
                      .doc(markerId)
                      .delete();
                  Navigator.pop(context);
                  _loadMarkers();
                },
              ),
          ],
        );
      },
    );
  }

  double _getMarkerColor(String type) {
    switch (type) {
      case 'lead':
        // Bluish – azure is a soft cyan-blue
        return BitmapDescriptor.hueAzure;
      case 'sale':
        // Clear green
        return BitmapDescriptor.hueGreen;
      case 'rejection':
        // Strong red
        return BitmapDescriptor.hueRed;
      case 'no_response':
        // Muted/dull – a pale yellow
        return BitmapDescriptor.hueYellow;
      default:
        // Fallback to a neutral cyan
        return BitmapDescriptor.hueCyan;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_currentPosition == null) {
      return Scaffold(
        body: Center(child: Text('Unable to get current location')),
      );
    }

    return Scaffold(
      // Remove the AppBar for full screen
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
              target: LatLng(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
              ),
              zoom: 15,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: _markers,
            onMapCreated: (controller) async {
              _controller = controller;
              await _loadMarkers();
            },
            onLongPress: _onLongPress,
          ),
          // Floating back arrow and legend pill
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // iOS-style back arrow
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      shape: BoxShape.circle,

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.black87,
                      size: 20,
                    ),
                  ),
                ),
                SizedBox(width: 10),
                // Legend pill
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _LegendDot(color: Colors.lightBlue, label: 'Lead'),
                        SizedBox(width: 12),
                        _LegendDot(color: Colors.green, label: 'Sale'),
                        SizedBox(width: 12),
                        _LegendDot(color: Colors.red, label: 'Rejection'),
                        SizedBox(width: 12),
                        _LegendDot(
                          color: const Color.fromARGB(255, 91, 111, 36),
                          label: 'No Response',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_markers.isEmpty)
            Positioned(
              top: 90,
              left: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'No markers found. Long press on the map to add a marker.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
              target: LatLng(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
              ),
              zoom: 15,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: _markers,
            onMapCreated: (controller) async {
              _controller = controller;
              await _loadMarkers();
            },
            onLongPress: _onLongPress,
          ),
          // Floating legend pill
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // _LegendDot(color: Colors.cyan, label: 'Other'),
                    // SizedBox(width: 12),
                    _LegendDot(color: Colors.lightBlue, label: 'Lead'),
                    SizedBox(width: 12),
                    _LegendDot(color: Colors.green, label: 'Sale'),
                    SizedBox(width: 12),
                    _LegendDot(color: Colors.red, label: 'Rejection'),
                    SizedBox(width: 12),
                    _LegendDot(
                      color: Colors.yellow[700]!,
                      label: 'No Response',
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_markers.isEmpty)
            Positioned(
              top: 70,
              left: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'No markers found. Long press on the map to add a marker.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MarkerTypeDialog extends StatefulWidget {
  final String? initialType;
  final String? initialNote;
  const _MarkerTypeDialog({this.initialType, this.initialNote});
  @override
  State<_MarkerTypeDialog> createState() => _MarkerTypeDialogState();
}

class _MarkerTypeDialogState extends State<_MarkerTypeDialog> {
  String? _selectedType;
  TextEditingController? _noteController;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _noteController = TextEditingController(text: widget.initialNote);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Select Marker Type'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<String>(
            value: _selectedType,
            hint: Text('Select type'),
            items: [
              DropdownMenuItem(value: 'lead', child: Text('Lead')),
              DropdownMenuItem(value: 'sale', child: Text('Sale')),
              DropdownMenuItem(value: 'rejection', child: Text('Rejection')),
              DropdownMenuItem(
                value: 'no_response',
                child: Text('No Response'),
              ),
            ],
            onChanged: (val) => setState(() => _selectedType = val),
          ),
          TextField(
            controller: _noteController,
            decoration: InputDecoration(labelText: 'Note (optional)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed:
              _selectedType == null
                  ? null
                  : () => Navigator.pop(context, {
                    'type': _selectedType,
                    'note': _noteController?.text,
                  }),
          child: Text('Save'),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black12, width: 1),
          ),
        ),
        SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
