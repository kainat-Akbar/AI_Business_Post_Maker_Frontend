import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const Color primaryColor = Color(0xFF5B4BDB);
  static const Color backgroundColor = Color(0xFFF8F8FC);
  static const Color textColor = Color(0xFF1F2937);
  static const Color secondaryText = Color(0xFF6B7280);

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _codeSent = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  String get _baseUrl => 'https://aibusinesspostmaker-production.up.railway.app';

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendResetCode() async {
    final email = _emailController.text.trim().toLowerCase();

    if (email.isEmpty) {
      _showMessage('Please enter your email address.');
      return;
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _showMessage('Please enter a valid email address.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data = _decodeResponse(response);

      if (response.statusCode == 200 && data['success'] == true) {
        if (!mounted) return;
        setState(() => _codeSent = true);
        _showMessage('A verification code has been sent to your email.');
      } else {
        throw Exception(data['message']?.toString() ?? 'Unable to send reset code.');
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage('Error: ${e.toString().replaceFirst('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim().toLowerCase();
    final code = _codeController.text.trim();
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (code.isEmpty) {
      _showMessage('Please enter the verification code.');
      return;
    }

    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      _showMessage('Verification code must be 6 digits.');
      return;
    }

    if (newPassword.length < 8) {
      _showMessage('New password must be at least 8 characters.');
      return;
    }

    if (newPassword != confirmPassword) {
      _showMessage('Passwords do not match.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'code': code,
          'new_password': newPassword,
        }),
      );

      final data = _decodeResponse(response);

      if (response.statusCode == 200 && data['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Password reset successfully. Please log in.')),
          );
        Navigator.pop(context);
      } else {
        throw Exception(data['message']?.toString() ?? 'Unable to reset password.');
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage('Error: ${e.toString().replaceFirst('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'success': false, 'message': 'Invalid server response.'};
    } catch (_) {
      return {'success': false, 'message': 'Invalid server response.'};
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
      prefixIcon: Icon(icon, size: 20, color: secondaryText),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: textColor),
        title: const Text(
          'Forgot Password',
          style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 30),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Reset your password',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Enter your email and we will send you a verification code.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, height: 1.4, color: secondaryText),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Email',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
              ),
              const SizedBox(height: 7),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !_codeSent && !_isLoading,
                decoration: _inputDecoration(hint: 'Enter your email', icon: Icons.email_outlined),
              ),
              if (!_codeSent) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendResetCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Send Verification Code',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
              if (_codeSent) ...[
                const SizedBox(height: 22),
                const Text(
                  'Verification Code',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                ),
                const SizedBox(height: 7),
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: _inputDecoration(hint: 'Enter 6-digit code', icon: Icons.verified_user_outlined)
                      .copyWith(counterText: ''),
                ),
                const SizedBox(height: 17),
                const Text(
                  'New Password',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                ),
                const SizedBox(height: 7),
                TextField(
                  controller: _newPasswordController,
                  obscureText: _obscureNewPassword,
                  decoration: _inputDecoration(hint: 'Enter new password', icon: Icons.lock_outline).copyWith(
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                      icon: Icon(
                        _obscureNewPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 20,
                        color: secondaryText,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 17),
                const Text(
                  'Confirm Password',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                ),
                const SizedBox(height: 7),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: _inputDecoration(hint: 'Confirm new password', icon: Icons.lock_outline).copyWith(
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 20,
                        color: secondaryText,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _resetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Reset Password',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: _isLoading ? null : () => setState(() => _codeSent = false),
                    child: const Text(
                      'Change email / Send code again',
                      style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Center(
                child: TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text(
                    'Back to Login',
                    style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
