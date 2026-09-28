
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';

import 'signup_screen.dart';
import 'home_screen.dart';
import 'forget_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  final FlutterSecureStorage _storage =
      const FlutterSecureStorage();

  // =========================================================
  // ADMIN WEB URL
  // =========================================================

  static const String adminWebUrl =
        'https://sage-macaron-844076.netlify.app';

  
  // =========================================================
  // GOOGLE SIGN IN
  // =========================================================

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId:
        '701779998421-p5mmirqeoadkq7rtbc3kjss1jf021rr.apps.googleusercontent.com',
  );

  // =========================================================
  // OPEN ADMIN WEB USING ONE-TIME LOGIN CODE
  // =========================================================

  Future<void> _openAdminWebWithToken(String token) async {
    try {
      final response = await http.post(
        Uri.parse(
          'https://aibusinesspostmaker-production.up.railway.app/api/admin/web-login-code',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode != 200 ||
          data['success'] != true) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message']?.toString() ??
                  'Unable to open Admin Dashboard',
            ),
          ),
        );

        return;
      }

      final code = data['code']?.toString();

      if (code == null || code.isEmpty) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Admin web login code was not received.',
            ),
          ),
        );

        return;
      }

      // -----------------------------------------------------
      // Create Admin Web URL with temporary one-time code
      // -----------------------------------------------------

      final uri = Uri.parse(
        '$adminWebUrl?code=${Uri.encodeComponent(code)}',
      );

      // -----------------------------------------------------
      // Open Admin Web in external browser
      // -----------------------------------------------------

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to open Admin Dashboard in browser.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to open Admin Dashboard. Please try again.',
          ),
        ),
      );
    }
  }

  // =========================================================
  // EMAIL / PASSWORD LOGIN
  // =========================================================

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter email and password',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(
          'https://aibusinesspostmaker-production.up.railway.app/api/login',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          data['success'] == true) {
        final token = data['token'];
        final user = data['user'] ?? {};

        final role = user['role'] ?? 'user';
        final userName = user['name'] ?? 'User';

        if (token == null || token.toString().isEmpty) {
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Invalid login response from server.',
              ),
            ),
          );

          return;
        }

        // Save normal JWT
        await _storage.write(
          key: 'access_token',
          value: token.toString(),
        );

        if (!mounted) return;

        // ===================================================
        // ADMIN
        // ===================================================

        if (role == 'admin') {
          await _openAdminWebWithToken(
            token.toString(),
          );

          return;
        }

        // ===================================================
        // NORMAL USER
        // ===================================================

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              userName: userName,
            ),
          ),
        );
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message'] ?? 'Login failed',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to connect to the server',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // =========================================================
  // GOOGLE SIGN IN
  // =========================================================

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Purana session clear karein taake
      // account selection prompt theek se aaye
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser =
          await _googleSignIn.signIn();

      if (googleUser == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }

        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception(
          'Google ID Token is null',
        );
      }

      // =====================================================
      // SEND GOOGLE ID TOKEN TO BACKEND
      // =====================================================

      final response = await http.post(
        Uri.parse(
          'https://aibusinesspostmaker-production.up.railway.app/api/auth/google',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'id_token': idToken,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          data['success'] == true) {
        final token = data['token'];
        final user = data['user'] ?? {};

        final role = user['role'] ?? 'user';
        final userName =
            user['name'] ?? 'Google User';

        if (token == null || token.toString().isEmpty) {
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Invalid Google login response from server.',
              ),
            ),
          );

          return;
        }

        // Save normal JWT
        await _storage.write(
          key: 'access_token',
          value: token.toString(),
        );

        if (!mounted) return;

        // ===================================================
        // GOOGLE ADMIN
        // ===================================================

        if (role == 'admin') {
          await _openAdminWebWithToken(
            token.toString(),
          );

          return;
        }

        // ===================================================
        // GOOGLE NORMAL USER
        // ===================================================

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              userName: userName,
            ),
          ),
        );
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message'] ??
                  'Google login failed',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Google Sign-In Error: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // =========================================================
  // UI
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B4BDB),
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      'AI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              const Center(
                child: Text(
                  'AI Business Post Maker',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                    color: Color(0xFF4338A8),
                  ),
                ),
              ),

              const SizedBox(height: 34),

              const Text(
                'Welcome Back 👋',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight:
                      FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Sign in to continue creating content for your business.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Color(0xFF6B7280),
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                'Email',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),

              const SizedBox(height: 7),

              TextField(
                controller:
                    _emailController,
                keyboardType:
                    TextInputType.emailAddress,
                decoration:
                    InputDecoration(
                  hintText:
                      'Enter your email',
                  hintStyle:
                      const TextStyle(
                    fontSize: 13,
                    color:
                        Color(0xFF9CA3AF),
                  ),
                  prefixIcon:
                      const Icon(
                    Icons.email_outlined,
                    size: 20,
                    color:
                        Color(0xFF6B7280),
                  ),
                  filled: true,
                  fillColor:
                      Colors.white,
                  contentPadding:
                      const EdgeInsets
                          .symmetric(
                    vertical: 14,
                    horizontal: 14,
                  ),
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                            12),
                    borderSide:
                        const BorderSide(
                      color:
                          Color(0xFFE5E7EB),
                    ),
                  ),
                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                            12),
                    borderSide:
                        const BorderSide(
                      color:
                          Color(0xFFE5E7EB),
                    ),
                  ),
                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                            12),
                    borderSide:
                        const BorderSide(
                      color:
                          Color(0xFF5B4BDB),
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 17),

              const Text(
                'Password',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),

              const SizedBox(height: 7),

              TextField(
                controller:
                    _passwordController,
                obscureText:
                    _obscurePassword,
                decoration:
                    InputDecoration(
                  hintText:
                      'Enter your password',
                  hintStyle:
                      const TextStyle(
                    fontSize: 13,
                    color:
                        Color(0xFF9CA3AF),
                  ),
                  prefixIcon:
                      const Icon(
                    Icons.lock_outline,
                    size: 20,
                    color:
                        Color(0xFF6B7280),
                  ),
                  suffixIcon:
                      IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePassword =
                            !_obscurePassword;
                      });
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons
                              .visibility_outlined
                          : Icons
                              .visibility_off_outlined,
                      size: 20,
                      color:
                          const Color(
                              0xFF6B7280),
                    ),
                  ),
                  filled: true,
                  fillColor:
                      Colors.white,
                  contentPadding:
                      const EdgeInsets
                          .symmetric(
                    vertical: 14,
                    horizontal: 14,
                  ),
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                            12),
                    borderSide:
                        const BorderSide(
                      color:
                          Color(0xFFE5E7EB),
                    ),
                  ),
                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                            12),
                    borderSide:
                        const BorderSide(
                      color:
                          Color(0xFFE5E7EB),
                    ),
                  ),
                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                            12),
                    borderSide:
                        const BorderSide(
                      color:
                          Color(0xFF5B4BDB),
                      width: 2,
                    ),
                  ),
                ),
              ),

              Align(
                alignment:
                    Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      const ForgotPasswordScreen(),
                            ),
                          );
                        },
                  style:
                      TextButton.styleFrom(
                    padding:
                        const EdgeInsets.only(
                      top: 5,
                      left: 6,
                    ),
                  ),
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          Color(0xFF5B4BDB),
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 5),

              SizedBox(
                width:
                    double.infinity,
                height: 50,
                child:
                    ElevatedButton(
                  onPressed:
                      _isLoading
                          ? null
                          : _login,
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(
                            0xFF5B4BDB),
                    foregroundColor:
                        Colors.white,
                    disabledBackgroundColor:
                        const Color(
                            0xFF5B4BDB),
                    disabledForegroundColor:
                        Colors.white,
                    elevation: 0,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                              12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color:
                                Colors.white,
                          ),
                        )
                      : const Text(
                          'Login',
                          style:
                              TextStyle(
                            fontSize: 15,
                            fontWeight:
                                FontWeight
                                    .w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 19),

              Row(
                children: [
                  const Expanded(
                    child: Divider(
                      color:
                          Color(0xFFE5E7EB),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 12,
                    ),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors
                            .grey.shade500,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Divider(
                      color:
                          Color(0xFFE5E7EB),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 17),

              SizedBox(
                width:
                    double.infinity,
                height: 50,
                child:
                    OutlinedButton.icon(
                  onPressed:
                      _isLoading
                          ? null
                          : _handleGoogleSignIn,
                  icon: const Text(
                    'G',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          Color(0xFF4285F4),
                    ),
                  ),
                  label: const Text(
                    'Continue with Google',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w600,
                      color:
                          Color(0xFF374151),
                    ),
                  ),
                  style:
                      OutlinedButton.styleFrom(
                    backgroundColor:
                        Colors.white,
                    side:
                        const BorderSide(
                      color:
                          Color(0xFFE5E7EB),
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                              12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 17),

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          Color(0xFF6B7280),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  const SignupScreen(),
                        ),
                      );
                    },
                    style:
                        TextButton.styleFrom(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 3,
                      ),
                    ),
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            Color(0xFF5B4BDB),
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}
