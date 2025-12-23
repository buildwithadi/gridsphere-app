import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dashboard_screen.dart';
import 'protection_screen.dart';
import 'soil_screen.dart';
import 'chat_screen.dart';

// Fallback GoogleFonts class to maintain consistency across the app
class GoogleFonts {
  static TextStyle inter({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: 'Inter',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }
}

class AlertsScreen extends StatefulWidget {
  final String sessionCookie;
  final String deviceId;

  const AlertsScreen({
    super.key,
    required this.sessionCookie,
    this.deviceId = "",
  });

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  int _selectedIndex = 4; // 4 corresponds to "Alerts" in the BottomNavBar

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF166534), // Brand Dark Green
      appBar: AppBar(
        backgroundColor: const Color(0xFF166534),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Alerts & Notifications",
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),

      // --- Standard Robot FAB ---
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

      // --- Standard Bottom Navigation Bar ---
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF166534),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
        onTap: (index) {
          if (index == 2 || index == _selectedIndex) return;

          if (index == 0) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => DashboardScreen(sessionCookie: widget.sessionCookie),
              ),
              (route) => false,
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProtectionScreen(
                  sessionCookie: widget.sessionCookie,
                  deviceId: widget.deviceId,
                ),
              ),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SoilScreen(
                  sessionCookie: widget.sessionCookie,
                  deviceId: widget.deviceId,
                ),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(LucideIcons.shieldCheck), label: "Protection"),
          BottomNavigationBarItem(icon: SizedBox(height: 24), label: ""), // Dummy for FAB
          BottomNavigationBarItem(icon: Icon(LucideIcons.layers), label: "Soil"),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "Alerts"),
        ],
      ),

      body: Column(
        children: [
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9), // Light grey background
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF166534).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.construction,
                          size: 64,
                          color: Color(0xFF166534),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Coming Soon",
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "We are working hard to bring you real-time alerts and smart notifications for your farm.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 60), // Extra space to account for FAB overlay
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}