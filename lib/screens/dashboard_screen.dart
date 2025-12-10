import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:async';
import 'profile_screen.dart';
import 'chat_screen.dart';
import '../detailed_screens/temperature_details_screen.dart';
import '../detailed_screens/humidity_details_screen.dart';
import 'alerts_screen.dart';

// Fallback GoogleFonts class... (same as before)
class GoogleFonts {
  static TextStyle inter({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontFamily: 'Inter',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      height: height,
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String selectedDeviceId = "2";
  Map<String, dynamic>? sensorData;
  bool isLoading = true;
  Timer? _timer;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _timer = Timer.periodic(const Duration(seconds: 60), (timer) => _fetchData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (sensorData == null) {
      setState(() => isLoading = true);
    }
    
    await Future.delayed(const Duration(seconds: 1));
    
    final data = {
      "air_temp": 24.0,
      "humidity": 65.0,
      "leaf_wetness": "Dry",
      "soil_temp": 20.0,
      "soil_moisture": 30,
      "rainfall": 5.2,
      "light_intensity": 850,
      "wind": 12.0,
      "pressure": 1013,
      "depth_temp": 22.5,
      "depth_humidity": 60.0,
      "surface_temp": 26.0,
      "surface_humidity": 55.0,
    };

    setState(() {
      sensorData = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF166534), // Dark Green Background
      
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
        onTap: (index) {
          if (index == 2) return;
          setState(() => _selectedIndex = index);
          if (index == 4) { 
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AlertsScreen()),
            ).then((_) => setState(() => _selectedIndex = 0));
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF166534),
        unselectedItemColor: Colors.grey.shade400,
        showUnselectedLabels: true,
        selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.sensors), label: "Sensors"),
          BottomNavigationBarItem(icon: SizedBox(height: 24), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: "Map"),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: "Alerts"),
        ],
      ),

      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildCustomHeader(context),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  // --- FIX: Changed from white to light grey-blue to reduce "whiteness" ---
                  color: Color(0xFFF1F5F9), 
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF166534)))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 24),
                            // --- Sensor Info Box ---
                            _buildSensorInfoBox(),
                            const SizedBox(height: 24),
                            
                            Text(
                              "Field Conditions",
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildFieldConditionsGrid(),
                            const SizedBox(height: 80), 
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorInfoBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // Softer corners
        // Removed border to make it look cleaner
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03), // Softer shadow
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9), // Light green tint
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.radio, size: 18, color: Color(0xFF166534)),
              ),
              const SizedBox(width: 10),
              Text(
                "Sensor Device Information",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow("Device ID:", "SEN-AGRI-001"),
                    const SizedBox(height: 12),
                    _buildInfoRow("Last Seen:", "1 min ago"),
                    const SizedBox(height: 12),
                    _buildInfoRow("Battery:", "85%"),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusRow("Status:", "Online"),
                    const SizedBox(height: 12),
                    _buildInfoRow("Location:", "Field A, Sec 3"),
                    const SizedBox(height: 12),
                    _buildInfoRow("Signal:", "Excellent"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF374151)),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.circle, size: 8, color: Color(0xFF22C55E)), // Brighter green for status
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                value,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF15803D)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.public, size: 24, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Grid Sphere Pvt. Ltd.",
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "AgriTech",
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 1.5),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 24),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFieldConditionsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 0.9, 
      children: [
        _ConditionCard(
          title: "Air Temp",
          value: "${sensorData?['air_temp']}°C",
          icon: LucideIcons.thermometer,
          iconBg: const Color(0xFFE8F5E9),
          iconColor: const Color(0xFF2E7D32),
          child: _MiniLineChart(color: const Color(0xFF2E7D32)),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TemperatureDetailsScreen(sensorData: sensorData)),
            );
          },
        ),
        _ConditionCard(
          title: "Humidity",
          value: "${sensorData?['humidity']}%",
          icon: LucideIcons.droplets,
          iconBg: const Color(0xFFE3F2FD), // Distinct blue tint
          iconColor: const Color(0xFF0288D1),
          child: _MiniLineChart(color: const Color(0xFF0288D1)),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HumidityDetailsScreen(sensorData: sensorData)),
            );
          },
        ),
        _ConditionCard(
          title: "Leaf",
          customContent: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Leaf Wetness", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF374151))),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text("${sensorData?['leaf_wetness']}", style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
                  const SizedBox(width: 8),
                  const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 24),
                ],
              )
            ],
          ),
          icon: LucideIcons.leaf,
          iconBg: const Color(0xFFDCFCE7),
          iconColor: const Color(0xFF15803D),
        ),
        _ConditionCard(
          title: "Soil Temp\n(10cm)",
          value: "${sensorData?['soil_temp']}°C",
          icon: Icons.device_thermostat, 
          iconBg: const Color(0xFFFEF3C7), // Warm amber tint
          iconColor: const Color(0xFFD97706),
        ),
        _ConditionCard(
          title: "Soil\nMoisture",
          subtitle: "(avg)",
          value: "${sensorData?['soil_moisture']}% VWC",
          icon: LucideIcons.waves,
          iconBg: const Color(0xFFE0E7FF), // Indigo tint
          iconColor: const Color(0xFF4F46E5),
        ),
        _ConditionCard(
          title: "Today's\nRainfall",
          subtitle: "Today",
          value: "${sensorData?['rainfall']} mm",
          icon: LucideIcons.cloudRain,
          iconBg: const Color(0xFFE0F2FE), // Sky blue tint
          iconColor: const Color(0xFF0EA5E9),
        ),
      ],
    );
  }
}

class _ConditionCard extends StatelessWidget {
  final String title;
  final String? value;
  final String? subtitle;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final Widget? child;
  final Widget? customContent;
  final VoidCallback? onTap;

  const _ConditionCard({
    required this.title,
    this.value,
    this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    this.child,
    this.customContent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20), // Softer radius
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          // Subtle shadow for depth
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (customContent != null)
              Expanded(child: customContent!)
            else ...[
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[400]),
                ),
              const SizedBox(height: 4),
              Text(
                value ?? "--",
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF111827), // Near black
                ),
              ),
            ],
            if (child != null) ...[
              const Spacer(),
              child!,
            ]
          ],
        ),
      ),
    );
  }
}

class _MiniLineChart extends StatelessWidget {
  final Color color;
  const _MiniLineChart({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      width: double.infinity,
      child: CustomPaint(
        painter: _ChartPainter(color),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final Color color;
  _ChartPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 // Thicker line
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.7, size.width * 0.5, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.75, size.height * 0.8, size.width, size.height * 0.2);

    // Subtle shadow
    canvas.drawShadow(path, color.withOpacity(0.2), 2.0, true);
    
    canvas.drawPath(path, paint);
    
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
      
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [color.withOpacity(0.15), color.withOpacity(0.0)],
    );
    
    canvas.drawPath(fillPath, Paint()..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height)));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}