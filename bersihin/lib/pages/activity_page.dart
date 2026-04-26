import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_page.dart';
import 'profile_page.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({Key? key}) : super(key: key);

  @override
  _ActivityPageState createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  final int _selectedIndex = 1;

  final Color toscaDark = const Color(0xFF025955);
  final Color toscaMedium = const Color(0xFF00909E);
  final Color toscaLight = const Color(0xFF48C9B0);

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => false,
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProfilePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.white,
        
        appBar: AppBar(
          backgroundColor: toscaDark, // "Aktivitas" yang atas tetep ijo gelap
          elevation: 0,
          toolbarHeight: 70,
          titleSpacing: 25, 
          title: Text(
            'Aktivitas', 
            style: GoogleFonts.outfit(
              fontSize: 26, 
              fontWeight: FontWeight.w800, 
              color: Colors.white,
              letterSpacing: -0.5
            )
          ),
          centerTitle: false,
          automaticallyImplyLeading: false, 
          
          // ZHANGG! Ini dia tab lu yang backgroundnya udeh gue bedain
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(55.0),
            child: Container(
              color: Colors.white, // Background tab dibedain jadi putih estetik
              child: TabBar(
                indicatorColor: toscaMedium,
                indicatorWeight: 4,
                labelColor: toscaDark, // Teks yang dipilih jadi tosca
                labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                unselectedLabelColor: Colors.grey.shade400,
                unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 16),
                dividerColor: Colors.transparent, 
                tabs: const [
                  Tab(text: 'Sedang Berjalan'),
                  Tab(text: 'Riwayat Selesai'),
                ],
              ),
            ),
          ),
        ),
        
        // ZHANGG! Background utama udeh disamain persis kaya Home/Profile (ijo tipis)
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, toscaLight.withOpacity(0.04)],
            ),
          ),
          child: TabBarView(
            physics: const BouncingScrollPhysics(),
            children: [
              _buildActivityList(isOngoing: true),
              _buildActivityList(isOngoing: false),
            ],
          ),
        ),
        
        floatingActionButton: SizedBox(
        width: 65, 
        height: 65, // Kita paksa ukurannya dari luar biar kaga error
        child: FloatingActionButton(
          onPressed: () {},
          backgroundColor: Colors.transparent,
          elevation: 12,
          focusElevation: 0,
          hoverElevation: 0,
          highlightElevation: 0, // Matiin efek bawaan biar kaga bentrok
          child: Container(
            width: 62, height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [toscaLight, toscaDark]),
              boxShadow: [
                BoxShadow(color: toscaDark.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))
              ]
            ),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 28),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 10.0,
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: toscaDark,
            unselectedItemColor: Colors.grey.shade400,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Beranda'),
              BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), label: 'Aktivitas'),
              BottomNavigationBarItem(icon: Icon(Icons.rate_review_outlined), label: 'Kesan Pesan'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityList({required bool isOngoing}) {
    List<Map<String, dynamic>> dummyData = isOngoing 
      ? [
          {'title': 'Deep Clean Rumah', 'date': '28 Apr 2026', 'time': '10:00 WIB', 'status': 'Menunggu Pekerja', 'icon': Icons.home_rounded},
          {'title': 'Service AC Kamar', 'date': '29 Apr 2026', 'time': '13:00 WIB', 'status': 'Dijadwalkan', 'icon': Icons.ac_unit_rounded},
        ]
      : [
          {'title': 'Cuci Sofa Ruang Tamu', 'date': '20 Apr 2026', 'time': '14:30 WIB', 'status': 'Selesai', 'icon': Icons.chair_rounded},
          {'title': 'Reguler Cleaning', 'date': '15 Apr 2026', 'time': '09:00 WIB', 'status': 'Selesai', 'icon': Icons.cleaning_services_rounded},
        ];

    if (dummyData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 80, color: toscaMedium.withOpacity(0.3)),
            const SizedBox(height: 15),
            Text('Belum ada aktivitas nih, Mon!', style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 25, bottom: 120, left: 20, right: 20),
      itemCount: dummyData.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        var data = dummyData[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24), 
            boxShadow: [
              BoxShadow(
                color: toscaDark.withOpacity(0.06), 
                blurRadius: 25, 
                offset: const Offset(0, 10)
              )
            ],
            border: Border.all(color: toscaLight.withOpacity(0.15), width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [toscaMedium.withOpacity(0.2), toscaLight.withOpacity(0.1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: toscaLight.withOpacity(0.3)),
                  ),
                  child: Icon(data['icon'], color: toscaDark, size: 32),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['title'],
                        style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: toscaDark, letterSpacing: -0.3),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 5),
                          Text(
                            "${data['date']} • ${data['time']}",
                            style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isOngoing ? Colors.orange.withOpacity(0.1) : toscaLight.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isOngoing ? Colors.orange.withOpacity(0.3) : toscaLight.withOpacity(0.3),
                          )
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isOngoing ? Colors.orange.shade600 : toscaDark,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              data['status'],
                              style: GoogleFonts.outfit(
                                fontSize: 11, 
                                fontWeight: FontWeight.bold, 
                                color: isOngoing ? Colors.orange.shade800 : toscaDark,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}