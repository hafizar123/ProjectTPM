import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http; 

class LocationPickerPage extends StatefulWidget {
  final Widget nextPage; 
  
  const LocationPickerPage({Key? key, required this.nextPage}) : super(key: key);

  @override
  _LocationPickerPageState createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  final Color toscaDark = const Color(0xFF025955);
  final Color toscaMedium = const Color(0xFF00909E);
  final Color toscaLight = const Color(0xFF48C9B0);

  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  
  LatLng _lastMapPosition = const LatLng(-7.7602, 110.4086);
  String _currentAddress = "Geser map untuk mencari alamat...";
  bool _isLoading = true;

  Timer? _searchDebounce;
  Timer? _mapDebounce; 
  List<dynamic> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _mapDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ==========================================
  // FUNGSI LBS: AMBIL LOKASI HP 
  // ==========================================
  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      LatLng currentLatLng = LatLng(position.latitude, position.longitude);
      _updateLocation(currentLatLng);
    } catch (e) {
      _updateLocation(_lastMapPosition);
      _showNotif("Gagal dapet GPS, pastiin emulator/HP idup lokasi ye pak.");
    }
  }

  // ==========================================
  // FUNGSI AUTOCOMPLETE PAKE PHOTON KOMOOT (ANTI BANNED)
  // ==========================================
  void _onSearchChanged(String query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 700), () {
      _fetchSuggestions(query);
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    if (!mounted) return;
    setState(() => _isSearching = true);
    try {
      // ZHANGG! Pake server Photon, lebih kebal serangan ngetik lu pak
      final url = Uri.parse('https://photon.komoot.io/api/?q=$query&limit=5');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _searchResults = data['features'] ?? [];
            _isSearching = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _selectSuggestion(dynamic place) {
    FocusScope.of(context).unfocus();
    
    // Photon ngebalikin koordinat kebalik [longitude, latitude] ye Mon
    final coords = place['geometry']['coordinates'];
    LatLng pos = LatLng(coords[1], coords[0]); 
    
    final props = place['properties'];
    String namaTempat = props['name'] ?? props['street'] ?? "Lokasi Terpilih";

    setState(() {
      _searchResults = [];
      _searchController.text = namaTempat;
    });
    
    _updateLocation(pos);
  }

  // ==========================================
  // FUNGSI REVERSE GEOCODE: TITIK -> ALAMAT (PAKE PHOTON)
  // ==========================================
  void _onMapEvent(MapCamera camera, bool hasGesture) {
    if (hasGesture) {
      if (_mapDebounce?.isActive ?? false) _mapDebounce!.cancel();
      
      // Kasih jeda 0.8 detik abis map digeser baru nyari alamat biar server kaga meledak
      _mapDebounce = Timer(const Duration(milliseconds: 800), () {
        _lastMapPosition = camera.center;
        _getAddress(camera.center);
      });
    }
  }

  Future<void> _getAddress(LatLng position) async {
    if (!mounted) return;
    
    setState(() => _currentAddress = "Mencari alamat...");
    
    try {
      final url = Uri.parse(
        'https://photon.komoot.io/reverse?lon=${position.longitude}&lat=${position.latitude}'
      );
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['features'] != null && data['features'].isNotEmpty) {
          final props = data['features'][0]['properties'];
          
          // Susun alamat biar rapi jali
          List<String> addressParts = [];
          if (props['name'] != null) addressParts.add(props['name']);
          if (props['street'] != null) addressParts.add(props['street']);
          if (props['city'] != null || props['county'] != null) addressParts.add(props['city'] ?? props['county']);
          if (props['state'] != null) addressParts.add(props['state']);

          if (mounted) {
            setState(() {
              _currentAddress = addressParts.isNotEmpty 
                  ? addressParts.join(', ') 
                  : "Alamat spesifik kaga terdeteksi pak";
            });
          }
        } else {
          if (mounted) setState(() => _currentAddress = "Lokasi tidak diketahui");
        }
      }
    } catch (e) {
      if (mounted) setState(() => _currentAddress = "Gagal sedot alamat ye pak...");
    }
  }

  void _updateLocation(LatLng position) {
    if (!mounted) return;
    setState(() {
      _lastMapPosition = position;
      _isLoading = false;
    });
    _mapController.move(position, 16.0);
    _getAddress(position);
  }

  void _showNotif(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(pesan, style: GoogleFonts.outfit()), backgroundColor: toscaMedium)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: toscaDark, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _lastMapPosition,
              initialZoom: 16.0,
              onPositionChanged: _onMapEvent, 
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.bersihin.app', 
              ),
            ],
          ),

          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 35),
              child: Icon(Icons.location_on_rounded, size: 50, color: toscaDark),
            ),
          ),

          if (_isLoading)
            Container(color: Colors.white.withOpacity(0.5), child: Center(child: CircularProgressIndicator(color: toscaDark))),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // SEARCH BAR
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 5))],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Cari alamat rumah lu pak...',
                        hintStyle: GoogleFonts.outfit(fontSize: 14, color: Colors.grey),
                        prefixIcon: Icon(Icons.search_rounded, color: toscaMedium),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchResults = [];
                                    _isSearching = false;
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                  
                  // DROPDOWN AUTOCOMPLETE
                  if (_searchResults.isNotEmpty || _isSearching)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      constraints: const BoxConstraints(maxHeight: 250),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15, offset: const Offset(0, 5))],
                      ),
                      child: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: _searchResults.length,
                              separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
                              itemBuilder: (context, index) {
                                final place = _searchResults[index];
                                final props = place['properties'];
                                
                                final name = props['name'] ?? props['street'] ?? 'Lokasi';
                                
                                List<String> detailParts = [];
                                if (props['city'] != null) detailParts.add(props['city']);
                                if (props['state'] != null) detailParts.add(props['state']);
                                final detail = detailParts.join(', ');
                                
                                return ListTile(
                                  leading: Icon(Icons.location_on_rounded, color: toscaMedium),
                                  title: Text(name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  subtitle: detail.isNotEmpty ? Text(detail, style: GoogleFonts.outfit(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis) : null,
                                  onTap: () => _selectSuggestion(place),
                                );
                              },
                            ),
                    ),

                  const Spacer(),
                  
                  Align(
                    alignment: Alignment.centerRight,
                    child: FloatingActionButton(
                      backgroundColor: Colors.white,
                      onPressed: () {
                        setState(() => _isLoading = true);
                        _getCurrentLocation();
                      },
                      child: Icon(Icons.my_location_rounded, color: toscaMedium),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // KONFIRMASI ALAMAT
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: const Offset(0, -5))],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Alamat Terpilih:', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: toscaDark, fontSize: 16)),
                        const SizedBox(height: 10),
                        Text(
                          _currentAddress, 
                          maxLines: 2, 
                          overflow: TextOverflow.ellipsis, 
                          style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade700)
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => widget.nextPage),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: toscaDark,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            child: Text('KONFIRMASI LOKASI', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}