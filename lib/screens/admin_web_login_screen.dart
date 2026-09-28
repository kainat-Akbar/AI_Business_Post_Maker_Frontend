import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'admin_dashboard_screen.dart';

class AdminWebLoginScreen extends StatefulWidget {
  const AdminWebLoginScreen({super.key});

  @override
  State<AdminWebLoginScreen> createState() => _AdminWebLoginScreenState();
}

class _AdminWebLoginScreenState extends State<AdminWebLoginScreen> {
  static const String baseUrl =
      "https://aibusinesspostmaker-production.up.railway.app";

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool isLoading = false;
  bool obscurePassword = true;

  String errorMessage = '';

  // True when Admin Web was opened with ?code=...
  bool hasLoginCode = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAdminWebLoginCode();
    });
  }

  // =========================================================
  // CHECK URL FOR ADMIN WEB LOGIN CODE
  // =========================================================

  Future<void> _checkAdminWebLoginCode() async {
    final uri = Uri.base;

    debugPrint("ADMIN WEB CURRENT URL: $uri");

    final code = uri.queryParameters["code"];

    debugPrint("ADMIN WEB LOGIN CODE: $code");

    if (code == null || code.trim().isEmpty) {
      if (!mounted) return;

      setState(() {
        hasLoginCode = false;
      });

      return;
    }

    if (!mounted) return;

    setState(() {
      hasLoginCode = true;
      isLoading = true;
      errorMessage = '';
    });

    await _loginWithAdminWebCode(code.trim());
  }

  // =========================================================
  // LOGIN ADMIN WEB USING ONE-TIME CODE
  // =========================================================

  Future<void> _loginWithAdminWebCode(String code) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/admin/web-login"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "code": code,
        }),
      );

      debugPrint(
        "ADMIN WEB LOGIN STATUS: ${response.statusCode}",
      );

      debugPrint(
        "ADMIN WEB LOGIN RESPONSE: ${response.body}",
      );

      Map<String, dynamic> data;

      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        if (!mounted) return;

        setState(() {
          errorMessage =
              "Invalid response received from server.";
          isLoading = false;
        });

        return;
      }

      if (response.statusCode == 200 && data["success"] == true) {
        final token = data["token"];
        final user = data["user"];

        if (token == null || user == null) {
          if (!mounted) return;

          setState(() {
            errorMessage =
                "Invalid login response from server.";
            isLoading = false;
          });

          return;
        }

        final role = user["role"]?.toString();

        if (role != "admin") {
          if (!mounted) return;

          setState(() {
            errorMessage =
                "This account is not an admin account.";
            isLoading = false;
          });

          return;
        }

        // Save JWT for Admin Dashboard.
        await _storage.write(
          key: "access_token",
          value: token.toString(),
        );

        if (!mounted) return;

        // Remove ?code=... from browser URL before opening dashboard.
        // This prevents the one-time code from remaining in the URL.
        if (Uri.base.queryParameters.containsKey("code")) {
          final cleanUri = Uri(
            path: Uri.base.path,
            queryParameters: {
              for (final entry in Uri.base.queryParameters.entries)
                if (entry.key != "code") entry.key: entry.value,
            },
          );

          debugPrint(
            "ADMIN WEB CLEAN URL: $cleanUri",
          );
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const AdminDashboardScreen(),
          ),
        );

        return;
      }

      if (!mounted) return;

      setState(() {
        errorMessage =
            data["message"]?.toString() ??
            "Admin web login failed. Please try again.";

        isLoading = false;
      });
    } catch (e) {
      debugPrint(
        "ADMIN WEB LOGIN ERROR: $e",
      );

      if (!mounted) return;

      setState(() {
        errorMessage =
            "Unable to connect to server. Please check your internet connection.";

        isLoading = false;
      });
    }
  }

  // =========================================================
  // NORMAL ADMIN EMAIL/PASSWORD LOGIN
  // =========================================================

  Future<void> adminLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        errorMessage =
            "Please enter email and password.";
      });

      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/login"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          data["success"] == true) {
        final token = data["token"];
        final user = data["user"];

        if (token == null || user == null) {
          if (!mounted) return;

          setState(() {
            errorMessage =
                "Invalid login response from server.";
          });

          return;
        }

        final role = user["role"]?.toString();

        if (role != "admin") {
          if (!mounted) return;

          setState(() {
            errorMessage =
                "This account is not an admin account.";
          });

          return;
        }

        await _storage.write(
          key: "access_token",
          value: token.toString(),
        );

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const AdminDashboardScreen(),
          ),
        );
      } else {
        if (!mounted) return;

        setState(() {
          errorMessage =
              data["message"]?.toString() ??
              "Login failed. Please try again.";
        });
      }
    } catch (e) {
      debugPrint(
        "ADMIN MANUAL LOGIN ERROR: $e",
      );

      if (!mounted) return;

      setState(() {
        errorMessage =
            "Unable to connect to server. Please check your internet connection.";
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // =========================================================
  // AUTO LOGIN SCREEN
  // =========================================================

  Widget _buildAutoLoginScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Center(
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.admin_panel_settings,
                  size: 70,
                  color: Color(0xFF4F46E5),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Admin Login",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  "Signing you in securely...",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 25),

                if (isLoading)
                  const CircularProgressIndicator(),

                if (!isLoading &&
                    errorMessage.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius:
                          BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.red.shade200,
                      ),
                    ),
                    child: Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        hasLoginCode = false;
                        errorMessage = '';
                      });
                    },
                    child: const Text(
                      "Back to Admin Login",
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // NORMAL LOGIN UI
  // =========================================================

  Widget _buildNormalLoginScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 450,
            ),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.admin_panel_settings,
                      size: 70,
                      color: Color(0xFF4F46E5),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "Admin Login",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      "AI Business Post Maker",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 32),

                    TextField(
                      controller: emailController,
                      keyboardType:
                          TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "Email",
                        hintText:
                            "Enter admin email",
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                        ),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      onSubmitted: (_) =>
                          adminLogin(),
                      decoration: InputDecoration(
                        labelText: "Password",
                        hintText:
                            "Enter admin password",
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              obscurePassword =
                                  !obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    if (errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Container(
                        padding:
                            const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius:
                              BorderRadius.circular(10),
                          border: Border.all(
                            color:
                                Colors.red.shade200,
                          ),
                        ),
                        child: Text(
                          errorMessage,
                          style: TextStyle(
                            color:
                                Colors.red.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 25),

                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed:
                            isLoading
                                ? null
                                : adminLogin,
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF4F46E5),
                          foregroundColor:
                              Colors.white,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              12,
                            ),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color:
                                      Colors.white,
                                ),
                              )
                            : const Text(
                                "Login to Admin Dashboard",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    if (hasLoginCode) {
      return _buildAutoLoginScreen();
    }

    return _buildNormalLoginScreen();
  }
}