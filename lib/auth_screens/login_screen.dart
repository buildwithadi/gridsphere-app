import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/dashboard_screen.dart';
import 'register_ui_screen.dart';
import '../session_manager/session_manager.dart';
import 'package:gsense_app/api_constants.dart';

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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Use the global URL from ApiConstants instead of a hardcoded string
  final String _baseUrl = ApiConstants.baseUrl;
  final String _userAgent = "FlutterApp";

  // Updated to use JWT Token in the Authorization header
  Future<void> _fetchDevicesAndIndustry(String token) async {
    try {
      final devicesResponse = await http.get(
        Uri.parse('$_baseUrl/getDevices'),
        headers: {
          'Authorization': 'Bearer $token',
          'User-Agent': _userAgent,
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

        if (deviceList.isNotEmpty) {
          var firstDevice = deviceList[0];
          String deviceId = firstDevice['d_id']?.toString() ?? "";

          if (deviceId.isNotEmpty) {
            SessionManager().setDeviceId(deviceId);
            await _fetchIndustryType(token, deviceId);
          } else {
            await SessionManager().loadRole();
          }
        } else {
          await SessionManager().loadRole();
        }
      } else {
        debugPrint(
            "Error fetching devices on login. Status: ${devicesResponse.statusCode}");
        await SessionManager().loadRole();
      }
    } catch (e) {
      debugPrint("Error fetching devices on login: $e");
      await SessionManager().loadRole();
    }
  }

  String _mapValueToRole(int val) {
    if (val == 1) return 'agriculture';
    if (val == 2) return 'cement';
    return 'chemical';
  }

  // Updated to use JWT Token in the Authorization header
  Future<void> _fetchIndustryType(String token, String deviceId) async {
    try {
      final industryResponse = await http.get(
        Uri.parse('$_baseUrl/devices/$deviceId/industry'),
        headers: {
          'Authorization': 'Bearer $token',
          'User-Agent': _userAgent,
        },
      );

      if (industryResponse.statusCode == 200) {
        final indData = jsonDecode(industryResponse.body);

        if (indData['status'] == true && indData['data'] != null) {
          int indValue = int.tryParse(
                  indData['data']['industry_value']?.toString() ?? '1') ??
              1;
          String fetchedRole = _mapValueToRole(indValue);

          SessionManager().setRole(fetchedRole);
          SessionManager().setIndustryValue(indValue);
          await SessionManager().saveRole(fetchedRole, industryValue: indValue);

          debugPrint(
              "Industry type fetched successfully on login: $fetchedRole (Value: $indValue)");
        } else {
          debugPrint(
              "Failed to extract valid industry type. API Response: ${industryResponse.body}");
          await SessionManager().loadRole();
        }
      } else {
        debugPrint(
            "API Error fetching industry: ${industryResponse.statusCode} - ${industryResponse.body}");
        await SessionManager().loadRole();
      }
    } catch (e) {
      debugPrint("Error fetching industry type on login: $e");
      await SessionManager().loadRole();
    }
  }

  // Re-written to support JWT and application/x-www-form-urlencoded
  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final loginUrl = Uri.parse('$_baseUrl/login');

        final loginResponse = await http.post(
          loginUrl,
          headers: {
            "Content-Type": "application/x-www-form-urlencoded",
            "User-Agent": _userAgent,
          },
          body: {
            "grant_type": "",
            "username": _idController.text.trim(),
            "password": _passwordController.text.trim(),
            "scope": "",
            "client_id": "",
            "client_secret": "",
          },
        );

        if (loginResponse.statusCode == 200) {
          final loginData = jsonDecode(loginResponse.body);

          // Typically OAuth2/JWT endpoints return 'access_token'
          final String token =
              loginData['access_token'] ?? loginData['token'] ?? '';

          if (token.isNotEmpty) {
            debugPrint("✅ Login Success! JWT Token received.");

            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('jwt_token', token);

            // Initialize SessionManager with JWT
            SessionManager().setAccessToken(token);

            // Fetch initial location logic and industry type using the new token
            await _fetchDevicesAndIndustry(token);

            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const DashboardScreen(),
                ),
              );
            }
          } else {
            // Token was missing from the 200 OK response
            _showError(loginData['message'] ??
                'Authentication failed: No token provided');
          }
        } else {
          // Handle non-200 responses (e.g. 401 Unauthorized)
          final errorData = jsonDecode(loginResponse.body);
          _showError(errorData['detail'] ??
              errorData['message'] ??
              'Login Error: ${loginResponse.statusCode}');
        }
      } catch (e) {
        _showError('Connection failed. Check internet.');
        debugPrint("Login Exception: $e");
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFF166534),
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      'assets/logo.png',
                      width: 60,
                      height: 60,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.public,
                          size: 60,
                          color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Welcome Back",
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "Sign in to access your farm data",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            "Login",
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1F2937),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 30),
                          TextFormField(
                            controller: _idController,
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: "User ID",
                              prefixIcon: const Icon(Icons.person),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300)),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF166534), width: 2)),
                            ),
                            validator: (value) => value!.isEmpty
                                ? "Please enter your User ID"
                                : null,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            keyboardType: TextInputType.visiblePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleLogin(),
                            decoration: InputDecoration(
                              labelText: "Password",
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                    _obscurePassword
                                        ? Icons.remove_red_eye
                                        : Icons.remove_red_eye_outlined,
                                    color: Colors.grey),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300)),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF166534), width: 2)),
                            ),
                            validator: (value) => value!.isEmpty
                                ? "Please enter your password"
                                : null,
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF166534),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 2,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : Text("Sign In",
                                      style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: GoogleFonts.inter(
                                    color: Colors.grey[600], fontSize: 14),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const RegisterUIScreen()),
                                  );
                                },
                                child: Text(
                                  "Register",
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF166534),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
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
      ),
    );
  }
}
