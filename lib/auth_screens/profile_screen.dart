import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'login_screen.dart';
import '../session_manager/session_manager.dart';
import '../screens/alerts_screen.dart'; // Import Alerts Screen
import 'package:gsense_app/api_constants.dart'; // Import API Constants

// Fallback GoogleFonts class
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

class ProfileScreen extends StatefulWidget {
  final String sessionCookie;

  const ProfileScreen({super.key, required this.sessionCookie});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final String _baseUrl = ApiConstants.baseUrl; // Updated to dynamic base URL
  Map<String, dynamic> userData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    String token = SessionManager().accessToken;

    try {
      // 1. Fetch User Profile from new endpoint
      final profileResponse = await http.get(
        Uri.parse('$_baseUrl/users/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      String username = "User";
      String email = "--";
      String mobile = "--";
      String address = "India";

      if (profileResponse.statusCode == 200) {
        final profileData = jsonDecode(profileResponse.body);
        if (profileData['status'] == 'success' && profileData['data'] != null) {
          final data = profileData['data'];
          username = data['name']?.toString() ?? "User";
          email = data['email']?.toString() ?? "--";
          mobile = data['phone']?.toString() ?? "--";

          if (data['company_name'] != null) {
            address = data['company_name'].toString();
          }
        }
      }

      // 2. Fetch Devices (Used for Address fallback and Active Device Count)
      int deviceCount = 0;
      try {
        final devicesResponse = await http.get(
          Uri.parse('$_baseUrl/devices/'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );

        if (devicesResponse.statusCode == 200) {
          final devicesData = jsonDecode(devicesResponse.body);
          List<dynamic> deviceList = [];

          if (devicesData is List) {
            deviceList = devicesData;
          } else if (devicesData is Map && devicesData.containsKey('data')) {
            if (devicesData['data'] is List) {
              deviceList = devicesData['data'] as List;
            }
          }

          deviceCount = deviceList.length;
          if (deviceList.isNotEmpty) {
            var firstDevice = deviceList[0];

            // Fallback address from device if session address is generic
            if (address == "India" || address.isEmpty) {
              address = firstDevice['location_name']?.toString() ?? "India";
            }
          }
        }
      } catch (e) {
        debugPrint("Error fetching devices: $e");
      }

      if (mounted) {
        setState(() {
          userData = {
            "name": username,
            "email": email,
            "mobile": mobile,
            "address": address,
            "devices": deviceCount,
          };
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
      if (mounted) {
        setState(() {
          userData = {
            "name": "User",
            "email": "--",
            "mobile": "--",
            "address": "Unknown",
            "devices": 0,
          };
          isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    // Clear local cache completely and redirect to Login
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_cookie');
    SessionManager().clearSession();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF166534), // Dark Green Header
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "My Profile",
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              children: [
                const SizedBox(height: 20),
                // Profile Image Section
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD6C0B3), // Beige/Skin tone
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.person,
                            size: 60, color: Color(0xFF5D4037)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        userData["name"] ?? "User",
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "G Sense",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Details Card
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9), // Light grey background
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          _buildInfoTile("User Name",
                              userData["name"] ?? "User", LucideIcons.user),
                          const SizedBox(height: 16),
                          _buildInfoTile("Mobile Number",
                              userData["mobile"] ?? "--", LucideIcons.phone),
                          const SizedBox(height: 16),
                          _buildInfoTile("Email", userData["email"] ?? "--",
                              LucideIcons.mail),
                          const SizedBox(height: 16),
                          _buildInfoTile("Address", userData["address"] ?? "--",
                              LucideIcons.mapPin),
                          const SizedBox(height: 16),
                          _buildInfoTile(
                              "Coordinates",
                              "${SessionManager().latitude.toStringAsFixed(4)}, ${SessionManager().longitude.toStringAsFixed(4)}",
                              LucideIcons.compass),
                          const SizedBox(height: 16),
                          _buildInfoTile(
                              "Active Devices",
                              "${userData["devices"] ?? 0} Sensors",
                              LucideIcons.radio),

                          const SizedBox(height: 16),

                          // Alerts Configuration Button
                          _buildActionTile(
                            title: "Alert Configuration",
                            subtitle:
                                "Manage sensor thresholds & notifications",
                            icon: LucideIcons.bellRing,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AlertsScreen(),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 40),

                          // Logout Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _handleLogout,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade50,
                                foregroundColor: Colors.red.shade700,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: Colors.red.shade100),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(LucideIcons.logOut, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Log Out",
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF166534).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF166534), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF166534).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF166534), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}
