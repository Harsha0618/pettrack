import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pettrack/models/pet_model.dart';
import 'package:pettrack/services/pet_service.dart';
import 'package:pettrack/screens/pet_detail_screen.dart';

class MapScreen extends StatefulWidget {
  final String? filterStatus; // Optional filter for 'lost' or 'found' pets

  const MapScreen({Key? key, this.filterStatus}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final PetService _petService = PetService();

  List<Marker> _markers = [];
  LatLng _currentPosition = LatLng(37.42796133580664, -122.085749655962); // Default to Google HQ
  bool _isLoading = true;
  String _errorMessage = '';
  double _searchRadius = 10.0; // km

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Location permissions are denied';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'Location permissions are permanently denied';
          _isLoading = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });

      _loadPets(position.latitude, position.longitude);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error getting location: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPets(double latitude, double longitude) async {
    try {
      Stream<List<PetModel>> petsStream;

      if (widget.filterStatus != null) {
        petsStream = _petService.getPetsByStatus(widget.filterStatus!);
      } else {
        petsStream = _petService.getAllPets();
      }

      petsStream.listen((pets) {
        final filteredPets = _filterPetsByDistance(
          pets,
          latitude,
          longitude,
          _searchRadius,
        );

        _updateMarkers(filteredPets);

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading pets: $e';
        _isLoading = false;
      });
    }
  }

  List<PetModel> _filterPetsByDistance(
    List<PetModel> pets,
    double latitude,
    double longitude,
    double radiusKm,
  ) {
    return pets.where((pet) {
      if (pet.latitude == null || pet.longitude == null) return false;
      final distance = Geolocator.distanceBetween(
        latitude,
        longitude,
        pet.latitude,
        pet.longitude,
      );
      return distance / 1000 <= radiusKm;
    }).toList();
  }

  void _updateMarkers(List<PetModel> pets) {
    final markers = pets.map((pet) {
      return Marker(
        width: 80.0,
        height: 80.0,
        point: LatLng(pet.latitude, pet.longitude),
        child: GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PetDetailScreen(petId: pet.id!),
              ),
            );
          },
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: pet.status == 'lost' ? Colors.red : Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pets,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              Text(
                pet.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();

    setState(() {
      _markers = markers;
    });
  }

  void _updateSearchRadius(double radius) {
    setState(() {
      _searchRadius = radius;
    });

    // Reload pets with new radius
    _loadPets(_currentPosition.latitude, _currentPosition.longitude);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _getCurrentLocation,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        FlutterMap(
  mapController: _mapController,
  options: MapOptions(
    initialCenter: _currentPosition,
    initialZoom: 13.0,
    minZoom: 5.0,
    maxZoom: 18.0,
  ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.pettrack',
            ),
            MarkerLayer(
              markers: [
                // Current location marker
                Marker(
                  width: 40.0,
                  height: 40.0,
                  point: _currentPosition,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.blue,
                    ),
                  ),
                ),
                ..._markers,
              ],
            ),
            CircleLayer(
              circles: [
                CircleMarker(
                  point: _currentPosition,
                  color: Colors.blue.withOpacity(0.2),
                  borderColor: Colors.blue.withOpacity(0.7),
                  borderStrokeWidth: 2,
                  radius: _searchRadius * 1000, // Convert km to meters
                ),
              ],
            ),
          ],
        ),

        // Radius control
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      'Search Radius: ${_searchRadius.toStringAsFixed(1)} km',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Slider(
                    value: _searchRadius,
                    min: 1.0,
                    max: 50.0,
                    divisions: 49,
                    label: '${_searchRadius.toStringAsFixed(1)} km',
                    onChanged: (value) {
                      _updateSearchRadius(value);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),

        // Pet count
        Positioned(
          bottom: 16,
          left: 16,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Showing ${_markers.length} pets',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),

        // Center button
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: () {
              _mapController.move(_currentPosition, 13.0);
            },
            child: const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }
}