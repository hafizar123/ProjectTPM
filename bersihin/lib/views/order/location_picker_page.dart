import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http; 
import 'address_detail_page.dart';

class LocationPickerPage extends StatefulWidget {
  final Widget? nextPage; 
  
  const LocationPickerPage({Key? key, this.nextPage}) : super(key: key);

  @override
  _LocationPickerPageState createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  final Color toscaDark = const Color(0xFF025955);
  final Color toscaMedium = const Color(0xFF00909E);
  final Color toscaLight = const Color(0xFF48C9B0);

  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  
  // Titik default UPNYK ye pak
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
    // ZHANGG! Kasih jeda dikit biar Map-nye napas dulu sebelom nyari GPS
    Future.delayed(const Duration(milliseconds: 500), () {
      _getCurrentLocation();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _mapDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ==========================================
  // FUNGSI LBS: AMBIL LOKASI HP (ANTI NGADAT)
  // ==========================================
  Future<void> _getCurrentLocation() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showNotif('Aktifkan GPS pada perangkat Anda');
        _updateLocation(_lastMapPosition);
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showNotif('Izin GPS ditolak');
          _updateLocation(_lastMapPosition);
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        _showNotif('Izin GPS diblokir secara permanen. Buka pengaturan perangkat');
        _updateLocation(_lastMapPosition);
        return;
      }

      // Sedot posisi pake akurasi medium biar cepet dapet
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 8),
      );
      
      LatLng currentLatLng = LatLng(position.latitude, position.longitude);
      _updateLocation(currentLatLng);
      
    } catch (e) {
      // Kalo nyangkut tetep dimatiin loadingnye
      _updateLocation(_lastMapPosition);
      _showNotif("Gagal mendapatkan lokasi GPS. Menggunakan lokasi default");
    }
  }

  // ==========================================
  // FUNGSI AUTOCOMPLETE NOMINATIM (USER-AGENT VIP)
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

    _searchDebounce = Timer(const Duration(milliseconds: 800), () {
      _fetchSuggestions(query);
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    if (!mounted) return;
    setState(() => _isSearching = true);
    
    try {
      // Balik pake Nominatim tapi pake identitas lu biar kaga di-banned!
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=5&countrycodes=id');
      final response = await http.get(url, headers: {
        'User-Agent': 'BersihInApp_SimonPulung_UPNYK/1.0'
      }).timeout(const Duration(seconds: 10)); // Batas waktu 10 detik biar kaga muter selamanya
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _searchResults = data;
            _isSearching = false;
          });
        }
      } else {
        if (mounted) setState(() => _isSearching = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isSearching = false);
      _showNotif("Gagal terhubung ke server. Periksa koneksi internet Anda");
    }
  }

  void _selectSuggestion(dynamic place) {
    FocusScope.of(context).unfocus();
    
    // Nominatim balikin lat/lon di root objectnye
    LatLng pos = LatLng(double.parse(place['lat']), double.parse(place['lon'])); 
    String namaTempat = place['name'] ?? place['display_name'].split(',')[0];

    setState(() {
      _searchResults = [];
      _searchController.text = namaTempat;
    });
    
    _updateLocation(pos);
  }

  // ==========================================
  // FUNGSI REVERSE GEOCODE: TITIK -> ALAMAT 
  // ==========================================
  void _onMapEvent(MapCamera camera, bool hasGesture) {
    if (hasGesture) {
      if (_mapDebounce?.isActive ?? false) _mapDebounce!.cancel();
      
      if (mounted) setState(() => _currentAddress = "Mencari alamat...");

      _mapDebounce = Timer(const Duration(milliseconds: 1000), () {
        _lastMapPosition = camera.center;
        _getAddress(camera.center);
      });
    }
  }

  Future<void> _getAddress(LatLng position) async {
    if (!mounted) return;
    
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=${position.latitude}&lon=${position.longitude}&format=json'
      );
      final response = await http.get(url, headers: {
        'User-Agent': 'BersihInApp_SimonPulung_UPNYK/1.0'
      }).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _currentAddress = data['display_name'] ?? "Alamat spesifik kaga terdeteksi pak";
          });
        }
      } else {
        if (mounted) setState(() => _currentAddress = "Gagal sedot alamat dari server pak.");
      }
    } catch (e) {
      if (mounted) setState(() => _currentAddress = "Koneksi bermasalah ye pak...");
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

          // LOADING DIMATIIN KALO UDEH KELAR
          if (_isLoading)
            Container(color: Colors.white.withOpacity(0.5), child: Center(child: CircularProgressIndicator(color: toscaDark))),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
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
                                final name = place['name'] ?? 'Lokasi';
                                final detail = place['display_name'] ?? '';
                                
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
                              // Langsung lempar koordinat & alamat ke halaman detail hunian Mon!
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddressDetailPage(
                                    locationData: {
                                      'address': _currentAddress,
                                      'lat': _lastMapPosition.latitude,
                                      'lng': _lastMapPosition.longitude,
                                    },
                                  ),
                                ),
                              ).then((value) {
                                // Kalo balik dari simpen detail, Map ikutan nutup Mon!
                                if (value == true) Navigator.pop(context, true);
                              });
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