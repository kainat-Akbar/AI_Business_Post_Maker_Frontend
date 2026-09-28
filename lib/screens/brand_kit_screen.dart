
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class BrandKitScreen extends StatefulWidget {
  const BrandKitScreen({super.key});

  @override
  State<BrandKitScreen> createState() => _BrandKitScreenState();
}

class _BrandKitScreenState extends State<BrandKitScreen> {
  // ==================================================
  // CONTROLLERS
  // ==================================================

  final TextEditingController _businessNameController =
      TextEditingController();

  final TextEditingController _contactInfoController =
      TextEditingController();

  // ==================================================
  // STORAGE
  // ==================================================

  final FlutterSecureStorage _storage =
      const FlutterSecureStorage();

  // ==================================================
  // STATES
  // ==================================================

  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasBrandKit = false;

  String? _logoUrl;
  String? _businessProfileLogo;

  String? _selectedColor;
  String? _selectedFont;

  // ==================================================
  // OPTIONS
  // ==================================================

  final List<String> _brandColors = [
    'Purple',
    'Blue',
    'Red',
    'Green',
    'Black & White',
    'Orange',
    'Pink',
    'Gold',
    'Navy Blue',
    'Custom',
  ];

  final List<String> _fonts = [
    'Poppins',
    'Roboto',
    'Montserrat',
    'Open Sans',
    'Lato',
    'Raleway',
    'Nunito',
    'Inter',
    'Playfair Display',
    'Custom',
  ];

  // ==================================================
  // COLORS
  // ==================================================

  static const Color primaryColor = Color(0xFF5B4BDB);
  static const Color textColor = Color(0xFF1F2937);
  static const Color secondaryText = Color(0xFF6B7280);
  static const Color backgroundColor = Color(0xFFF8F8FC);

  // ==================================================
  // INIT
  // ==================================================

  @override
  void initState() {
    super.initState();
    _loadBrandKit();
  }

  // ==================================================
  // LOAD BRAND KIT
  // ==================================================

  Future<void> _loadBrandKit() async {
    try {
      final token = await _storage.read(
        key: 'access_token',
      );

      if (token == null || token.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // ==================================================
      // LOAD BUSINESS PROFILE
      // ==================================================

      final profileResponse = await http.get(
        Uri.parse(
          'https://aibusinesspostmaker-production.up.railway.app/api/business-profile'
      
        ),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (profileResponse.statusCode == 200) {
        final profileData =
            jsonDecode(profileResponse.body);

        if (profileData['success'] == true &&
            profileData['business_profile'] != null) {
          final profile =
              profileData['business_profile'];

          _businessProfileLogo =
              profile['logo_url'];

          if (profile['business_name'] != null &&
              profile['business_name']
                  .toString()
                  .isNotEmpty) {
            _businessNameController.text =
                profile['business_name'].toString();
          }

          if (profile['phone'] != null &&
              profile['phone']
                  .toString()
                  .isNotEmpty) {
            _contactInfoController.text =
                profile['phone'].toString();
          }
        }
      }

      // ==================================================
      // LOAD BRAND KIT
      // ==================================================

      final response = await http.get(
        Uri.parse(
          'https://aibusinesspostmaker-production.up.railway.app/api/brand-kit',
        ),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint(
        'GET BRAND KIT STATUS: ${response.statusCode}',
      );

      debugPrint(
        'GET BRAND KIT RESPONSE: ${response.body}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          final brandKit = data['brand_kit'];

          if (brandKit != null) {
            _hasBrandKit = true;

            _logoUrl = brandKit['logo_url'];

            final savedColor =
                brandKit['brand_colors']?.toString();

            final savedFont =
                brandKit['preferred_font']?.toString();

            if (savedColor != null &&
                savedColor.isNotEmpty &&
                _brandColors.contains(savedColor)) {
              _selectedColor = savedColor;
            }

            if (savedFont != null &&
                savedFont.isNotEmpty &&
                _fonts.contains(savedFont)) {
              _selectedFont = savedFont;
            }

            if (brandKit['business_name'] != null &&
                brandKit['business_name']
                    .toString()
                    .isNotEmpty) {
              _businessNameController.text =
                  brandKit['business_name'].toString();
            }

            if (brandKit['contact_info'] != null &&
                brandKit['contact_info']
                    .toString()
                    .isNotEmpty) {
              _contactInfoController.text =
                  brandKit['contact_info'].toString();
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint(
        'GET BRAND KIT ERROR: $e',
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      _showMessage(
        'Unable to load brand kit',
      );
    }
  }

  // ==================================================
  // SAVE BRAND KIT
  // ==================================================

  Future<void> _saveBrandKit() async {
    if (_selectedColor == null ||
        _selectedColor!.isEmpty) {
      _showMessage(
        'Please select your brand color',
      );
      return;
    }

    if (_selectedFont == null ||
        _selectedFont!.isEmpty) {
      _showMessage(
        'Please select your preferred font',
      );
      return;
    }

    final businessName =
        _businessNameController.text.trim();

    final contactInfo =
        _contactInfoController.text.trim();

    if (businessName.isEmpty) {
      _showMessage(
        'Business name is required',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final token = await _storage.read(
        key: 'access_token',
      );

      if (token == null || token.isEmpty) {
        _showMessage(
          'Please login again',
        );
        return;
      }

      final uri = Uri.parse(
        'https://aibusinesspostmaker-production.up.railway.app/api/brand-kit',
      );

      final body = jsonEncode({
        'brand_colors': _selectedColor,
        'preferred_font': _selectedFont,
        'business_name': businessName,
        'contact_info': contactInfo,
      });

      final response = _hasBrandKit
          ? await http.put(
              uri,
              headers: {
                'Authorization':
                    'Bearer $token',
                'Content-Type':
                    'application/json',
              },
              body: body,
            )
          : await http.post(
              uri,
              headers: {
                'Authorization':
                    'Bearer $token',
                'Content-Type':
                    'application/json',
              },
              body: body,
            );

      debugPrint(
        'SAVE BRAND KIT STATUS: ${response.statusCode}',
      );

      debugPrint(
        'SAVE BRAND KIT RESPONSE: ${response.body}',
      );

      final data = jsonDecode(response.body);

      if ((response.statusCode == 200 ||
              response.statusCode == 201) &&
          data['success'] == true) {
        if (!mounted) return;

        setState(() {
          _hasBrandKit = true;

          if (data['brand_kit'] != null) {
            _logoUrl =
                data['brand_kit']['logo_url'];
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Brand kit saved successfully',
            ),
          ),
        );

        return;
      }

      _showMessage(
        data['message'] ??
            'Unable to save brand kit',
      );
    } catch (e) {
      debugPrint(
        'SAVE BRAND KIT ERROR: $e',
      );

      _showMessage(
        'Unable to connect to the server',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ==================================================
  // MESSAGE
  // ==================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ==================================================
  // DISPOSE
  // ==================================================

  @override
  void dispose() {
    _businessNameController.dispose();
    _contactInfoController.dispose();
    super.dispose();
  }

  // ==================================================
  // BUILD
  // ==================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ==================================================
            // HEADER
            // ==================================================

            Container(
              padding: const EdgeInsets.fromLTRB(
                18,
                8,
                18,
                14,
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    borderRadius:
                        BorderRadius.circular(10),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(10),
                        border: Border.all(
                          color:
                              const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        size: 20,
                        color: textColor,
                      ),
                    ),
                  ),

                  const SizedBox(width: 11),

                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFFF0EDFF),
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.palette_outlined,
                      size: 20,
                      color: primaryColor,
                    ),
                  ),

                  const SizedBox(width: 11),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Brand Kit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Keep your brand identity consistent',
                          style: TextStyle(
                            fontSize: 10.5,
                            color:
                                secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ==================================================
            // CONTENT
            // ==================================================

            Expanded(
              child: _isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(
                        color: primaryColor,
                      ),
                    )
                  : SingleChildScrollView(
                      padding:
                          const EdgeInsets.fromLTRB(
                        20,
                        4,
                        20,
                        25,
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Brand Identity',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight:
                                  FontWeight.w700,
                              color: textColor,
                            ),
                          ),

                          const SizedBox(height: 5),

                          const Text(
                            'These settings help AI keep your generated '
                            'content consistent with your brand.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color:
                                  secondaryText,
                            ),
                          ),

                          const SizedBox(height: 22),

                          // ==================================================
                          // LOGO
                          // ==================================================

                          _label('Brand Logo'),

                          const SizedBox(height: 8),

                          Container(
                            padding:
                                const EdgeInsets.all(
                              14,
                            ),
                            decoration:
                                BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(
                                13,
                              ),
                              border: Border.all(
                                color:
                                    const Color(
                                  0xFFE5E7EB,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 58,
                                  height: 58,
                                  decoration:
                                      BoxDecoration(
                                    color:
                                        const Color(
                                      0xFFF0EDFF,
                                    ),
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      12,
                                    ),
                                  ),
                                  child: _buildLogo(),
                                ),

                                const SizedBox(
                                  width: 12,
                                ),

                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      Text(
                                        'Business Logo',
                                        style:
                                            TextStyle(
                                          fontSize: 13,
                                          fontWeight:
                                              FontWeight
                                                  .w600,
                                          color:
                                              textColor,
                                        ),
                                      ),
                                      SizedBox(
                                        height: 4,
                                      ),
                                      Text(
                                        'Logo is synchronized with your Business Profile.',
                                        style:
                                            TextStyle(
                                          fontSize:
                                              10.5,
                                          color:
                                              secondaryText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          // ==================================================
                          // BRAND COLORS DROPDOWN
                          // ==================================================

                          _label('Brand Colors'),

                          const SizedBox(height: 7),

                          _buildDropdown(
                            value: _selectedColor,
                            hint: 'Select your brand colors',
                            items: _brandColors,
                            icon:
                                Icons.color_lens_outlined,
                            onChanged: (value) {
                              setState(() {
                                _selectedColor = value;
                              });
                            },
                          ),

                          const SizedBox(height: 16),

                          // ==================================================
                          // FONT DROPDOWN
                          // ==================================================

                          _label('Preferred Font'),

                          const SizedBox(height: 7),

                          _buildDropdown(
                            value: _selectedFont,
                            hint: 'Select your preferred font',
                            items: _fonts,
                            icon:
                                Icons.font_download_outlined,
                            onChanged: (value) {
                              setState(() {
                                _selectedFont = value;
                              });
                            },
                          ),

                          const SizedBox(height: 16),

                          // ==================================================
                          // BUSINESS NAME
                          // ==================================================

                          _label('Business Name'),

                          const SizedBox(height: 7),

                          _textField(
                            controller:
                                _businessNameController,
                            hint: 'Business name',
                            icon:
                                Icons.storefront_outlined,
                          ),

                          const SizedBox(height: 16),

                          // ==================================================
                          // CONTACT INFO
                          // ==================================================

                          _label('Contact Information'),

                          const SizedBox(height: 7),

                          TextField(
                            controller:
                                _contactInfoController,
                            maxLines: 3,
                            decoration:
                                InputDecoration(
                              hintText:
                                  'Phone, WhatsApp, email or other contact information',
                              hintStyle:
                                  const TextStyle(
                                fontSize: 12,
                                color:
                                    Color(0xFF9CA3AF),
                              ),
                              prefixIcon:
                                  const Padding(
                                padding:
                                    EdgeInsets.only(
                                  bottom: 35,
                                ),
                                child: Icon(
                                  Icons
                                      .contact_phone_outlined,
                                  size: 19,
                                  color:
                                      secondaryText,
                                ),
                              ),
                              filled: true,
                              fillColor:
                                  Colors.white,
                              contentPadding:
                                  const EdgeInsets.all(
                                13,
                              ),
                              border:
                                  OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  11,
                                ),
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
                                  11,
                                ),
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
                                  11,
                                ),
                                borderSide:
                                    const BorderSide(
                                  color:
                                      primaryColor,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ==================================================
                          // SAVE
                          // ==================================================

                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isSaving
                                  ? null
                                  : _saveBrandKit,
                              style:
                                  ElevatedButton
                                      .styleFrom(
                                backgroundColor:
                                    primaryColor,
                                foregroundColor:
                                    Colors.white,
                                disabledBackgroundColor:
                                    primaryColor,
                                disabledForegroundColor:
                                    Colors.white,
                                elevation: 0,
                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                    11,
                                  ),
                                ),
                              ),
                              child: _isSaving
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
                                  : Text(
                                      _hasBrandKit
                                          ? 'Update Brand Kit'
                                          : 'Save Brand Kit',
                                      style:
                                          const TextStyle(
                                        fontSize: 14,
                                        fontWeight:
                                            FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================================================
  // LOGO
  // ==================================================

  Widget _buildLogo() {
    final logo = (_logoUrl != null &&
            _logoUrl!.isNotEmpty)
        ? _logoUrl
        : _businessProfileLogo;

    if (logo != null && logo.isNotEmpty) {
      return ClipRRect(
        borderRadius:
            BorderRadius.circular(12),
        child: Image.network(
          logo,
          width: 58,
          height: 58,
          fit: BoxFit.cover,
          errorBuilder:
              (context, error, stackTrace) {
            return const Icon(
              Icons.image_outlined,
              color: primaryColor,
            );
          },
        ),
      );
    }

    return const Icon(
      Icons.image_outlined,
      color: primaryColor,
      size: 25,
    );
  }

  // ==================================================
  // DROPDOWN
  // ==================================================

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: secondaryText,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 12,
          color: Color(0xFF9CA3AF),
        ),
        prefixIcon: Icon(
          icon,
          size: 19,
          color: secondaryText,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(
          vertical: 4,
          horizontal: 12,
        ),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(11),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(11),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(11),
          borderSide: const BorderSide(
            color: primaryColor,
            width: 1.5,
          ),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: const TextStyle(
              fontSize: 12,
              color: textColor,
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  // ==================================================
  // LABEL
  // ==================================================

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }

  // ==================================================
  // TEXT FIELD
  // ==================================================

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 12,
          color: Color(0xFF9CA3AF),
        ),
        prefixIcon: Icon(
          icon,
          size: 19,
          color: secondaryText,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(
          vertical: 13,
          horizontal: 12,
        ),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(11),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(11),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(11),
          borderSide: const BorderSide(
            color: primaryColor,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
