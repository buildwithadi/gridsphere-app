import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'chat_screen.dart';
import 'alerts_screen.dart';
// Import detailed screens to link to them or use their logic if needed
import '../detailed_screens/depth_temperature_details_screen.dart';
import '../detailed_screens/depth_humidity_details_screen.dart';
import '../detailed_screens/surface_temperature_details_screen.dart';
import '../detailed_screens/surface_humidity_details_screen.dart';

class GoogleFonts {
  static TextStyle inter({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontFamily: 'Inter',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }
}

class SoilScreen extends StatefulWidget {
  final String sessionCookie;
  final String deviceId; // To fetch data if needed
  final Map<String, dynamic>? sensorData; // To display current values immediately

  const SoilScreen({
    super.key, 
    required this.sessionCookie,
    this.deviceId = "",
    this.sensorData,
  });

  @override
  State<SoilScreen> createState() => _SoilScreenState();
}

class _SoilScreenState extends State<SoilScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 3; // 3 corresponds to "Soil" in BottomNavBar

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF166534), // Brand Green
      appBar: AppBar(
        backgroundColor: const Color(0xFF166534),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Soil Health",
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: const Color(0xFF166534),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: "Spray Timing"),
                Tab(text: "Soil Parameters"),
              ],
            ),
          ),
        ),
      ),
      
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatScreen()),
          );
        },
        backgroundColor: const Color(0xFF166534),
        elevation: 4.0,
        shape: const CircleBorder(),
        child: const Icon(LucideIcons.bot, color: Colors.white, size: 28),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF166534),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
        onTap: (index) {
          if (index == 2) return; // Dummy item
          
          if (index == 0) {
            Navigator.pop(context); // Go back to Dashboard
          } else if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AlertsScreen()),
            ).then((_) => setState(() => _selectedIndex = 3));
          } else {
             setState(() => _selectedIndex = index);
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(LucideIcons.shieldCheck), label: "Protection"),
          BottomNavigationBarItem(icon: SizedBox(height: 24), label: ""),
          BottomNavigationBarItem(icon: Icon(LucideIcons.layers), label: "Soil"),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: "Alerts"),
        ],
      ),

      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: TabBarView(
            controller: _tabController,
            children: [
              // --- Spray Timing Tab ---
              _buildSprayTimingContent(),
              // --- Soil Parameters Tab ---
              _buildSoilParametersContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSprayTimingContent() {
    // Mock Data for Spray Advice
    final List<Map<String, dynamic>> adviceList = [
      {
        "title": "Fertilizer Application",
        "status": "Optimal",
        "message": "Soil moisture is adequate for nutrient absorption. Apply Nitrogen-based fertilizers in the early morning.",
        "icon": LucideIcons.sprout,
        "color": Colors.green,
      },
      {
        "title": "Pesticide Spray",
        "status": "Wait",
        "message": "Wind speeds are currently too high (>15 km/h). Wait for calm conditions to prevent drift.",
        "icon": LucideIcons.sprayCan,
        "color": Colors.orange,
      },
      {
        "title": "Irrigation Schedule",
        "status": "Recommended",
        "message": "Soil depth moisture is dropping. Consider a light irrigation cycle this evening.",
        "icon": LucideIcons.droplets,
        "color": Colors.blue,
      }
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Text(
            "Spray & Application Advice",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          
          ...adviceList.map((advice) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border(left: BorderSide(color: advice['color'], width: 4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: advice['color'].withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(advice['icon'], color: advice['color'], size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              advice['title'],
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: advice['color'].withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                advice['status'],
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: advice['color'],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          advice['message'],
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          
          // Placeholder for future logic integration
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                "Real-time logic will be integrated here.",
                style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoilParametersContent() {
    // Extract data for display, fallback to 0 if not available
    double depthTemp = widget.sensorData?['depth_temp'] ?? 0.0;
    double depthHum = widget.sensorData?['depth_humidity'] ?? 0.0;
    double surfTemp = widget.sensorData?['surface_temp'] ?? 0.0;
    double surfHum = widget.sensorData?['surface_humidity'] ?? 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Text(
            "Current Conditions",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          
          // Grid for 4 main parameters
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: [
              _buildSoilCard(
                "Depth Temp", 
                "${depthTemp}°C", 
                Icons.device_thermostat, 
                Colors.orange,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DepthTemperatureDetailsScreen(
                    sensorData: widget.sensorData,
                    deviceId: widget.deviceId,
                    sessionCookie: widget.sessionCookie,
                  )),
                ),
              ),
              _buildSoilCard(
                "Depth Humidity", 
                "${depthHum}%", 
                LucideIcons.droplet, 
                Colors.teal,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DepthHumidityDetailsScreen(
                    sensorData: widget.sensorData,
                    deviceId: widget.deviceId,
                    sessionCookie: widget.sessionCookie,
                  )),
                ),
              ),
              _buildSoilCard(
                "Surface Temp", 
                "${surfTemp}°C", 
                Icons.thermostat, 
                Colors.redAccent,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SurfaceTemperatureDetailsScreen(
                    sensorData: widget.sensorData,
                    deviceId: widget.deviceId,
                    sessionCookie: widget.sessionCookie,
                  )),
                ),
              ),
              _buildSoilCard(
                "Surface Humidity", 
                "${surfHum}%", 
                LucideIcons.waves, 
                Colors.brown,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SurfaceHumidityDetailsScreen(
                    sensorData: widget.sensorData,
                    deviceId: widget.deviceId,
                    sessionCookie: widget.sessionCookie,
                  )),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSoilCard(String title, String value, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
          ],
        ),
      ),
    );
  }
}