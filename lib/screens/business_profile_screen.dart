import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'brand_kit_screen.dart';

class BusinessProfileScreen extends StatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  State<BusinessProfileScreen> createState() =>
      _BusinessProfileScreenState();
}

class _BusinessProfileScreenState
    extends State<BusinessProfileScreen> {
  // ==================================================
  // CONTROLLERS
  // ==================================================

  final TextEditingController _businessNameController =
      TextEditingController();

  final TextEditingController _phoneController =
      TextEditingController();

  final TextEditingController _websiteController =
      TextEditingController();

  final TextEditingController _addressController =
      TextEditingController();

  final TextEditingController _socialController =
      TextEditingController();

  final TextEditingController _descriptionController =
      TextEditingController();

  // ==================================================
  // STORAGE
  // ==================================================

  final FlutterSecureStorage _storage =
      const FlutterSecureStorage();

  // ==================================================
  // IMAGE PICKER
  // ==================================================

  final ImagePicker _imagePicker =
      ImagePicker();

  XFile? _selectedLogo;

  Uint8List? _selectedLogoBytes;

  String? _existingLogoUrl;

  // ==================================================
  // STATES
  // ==================================================

  bool _isLoading = true;

  bool _isSaving = false;

  bool _hasBusinessProfile = false;

  String? _selectedCategory;

  // ==================================================
  // CATEGORIES
  // ==================================================

  final List<String> _categories = [
    'Fashion & Clothing',
    'Food & Restaurant',
    'Beauty & Salon',
    'Technology',
    'Education',
    'Health & Fitness',
    'Real Estate',
    'Travel',
    'Other',
  ];

  // ==================================================
  // COLORS
  // ==================================================

  static const Color primaryColor =
      Color(0xFF5B4BDB);

  static const Color textColor =
      Color(0xFF1F2937);

  static const Color secondaryText =
      Color(0xFF6B7280);

  static const Color backgroundColor =
      Color(0xFFF8F8FC);

  // ==================================================
  // INIT
  // ==================================================

  @override
  void initState() {
    super.initState();

    _loadBusinessProfile();
  }

  // ==================================================
  // LOAD BUSINESS PROFILE
  // ==================================================

  Future<void> _loadBusinessProfile() async {
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

      final response = await http.get(
        Uri.parse(
          'https://aibusinesspostmaker-production.up.railway.app/api/business-profile',
        ),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint(
        'GET BUSINESS PROFILE STATUS: '
        '${response.statusCode}',
      );

      debugPrint(
        'GET BUSINESS PROFILE RESPONSE: '
        '${response.body}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true &&
            data['business_profile'] != null) {
          final profile =
              data['business_profile'];

          if (!mounted) return;

          setState(() {
            _hasBusinessProfile = true;

            _businessNameController.text =
                profile['business_name'] ?? '';

            _phoneController.text =
                profile['phone'] ?? '';

            _websiteController.text =
                profile['website'] ?? '';

            _addressController.text =
                profile['address'] ?? '';

            _socialController.text =
                profile['social_media_handles'] ?? '';

            _descriptionController.text =
                profile['description'] ?? '';

            _existingLogoUrl =
                profile['logo_url'];

            final category =
                profile['category'];

            if (_categories.contains(category)) {
              _selectedCategory = category;
            } else {
              _selectedCategory = null;
            }

            _isLoading = false;
          });
        } else {
          if (mounted) {
            setState(() {
              _hasBusinessProfile = false;
              _isLoading = false;
            });
          }
        }
      } else if (response.statusCode == 404) {
        if (mounted) {
          setState(() {
            _hasBusinessProfile = false;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }

        _showMessage(
          'Unable to load business profile',
        );
      }
    } catch (e) {
      debugPrint(
        'GET BUSINESS PROFILE ERROR: $e',
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      _showMessage(
        'Unable to connect to the server',
      );
    }
  }

  // ==================================================
  // PICK LOGO
  // ==================================================

  Future<void> _pickLogo() async {
    try {
      final XFile? pickedImage =
          await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedImage == null) {
        return;
      }

      final bytes =
          await pickedImage.readAsBytes();

      if (!mounted) return;

      setState(() {
        _selectedLogo = pickedImage;
        _selectedLogoBytes = bytes;
      });
    } catch (e) {
      debugPrint(
        'PICK LOGO ERROR: $e',
      );

      _showMessage(
        'Unable to select logo',
      );
    }
  }

  // ==================================================
  // OPEN BRAND KIT
  // ==================================================

  Future<void> _openBrandKit() async {
    if (!_hasBusinessProfile) {
      _showMessage(
        'Please save your business profile first',
      );

      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const BrandKitScreen(),
      ),
    );
  }

  // ==================================================
  // SAVE / UPDATE BUSINESS PROFILE
  // ==================================================

  Future<void> _saveBusinessProfile() async {
    final businessName =
        _businessNameController.text.trim();

    final phone =
        _phoneController.text.trim();

    final website =
        _websiteController.text.trim();

    final address =
        _addressController.text.trim();

    final socialMedia =
        _socialController.text.trim();

    final description =
        _descriptionController.text.trim();

    final category =
        _selectedCategory;

    // ==================================================
    // VALIDATION
    // ==================================================

    if (businessName.isEmpty) {
      _showMessage(
        'Please enter your business name',
      );

      return;
    }

    if (category == null ||
        category.isEmpty) {
      _showMessage(
        'Please select a business category',
      );

      return;
    }

    if (phone.isEmpty) {
      _showMessage(
        'Please enter your phone number',
      );

      return;
    }

    if (address.isEmpty) {
      _showMessage(
        'Please enter your business address',
      );

      return;
    }

    if (!_hasBusinessProfile &&
        _selectedLogoBytes == null) {
      _showMessage(
        'Please upload your business logo',
      );

      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final token =
          await _storage.read(
        key: 'access_token',
      );

      if (token == null ||
          token.isEmpty) {
        _showMessage(
          'Please login again',
        );

        return;
      }

      final uri = Uri.parse(
        'https://aibusinesspostmaker-production.up.railway.app/api/business-profile',
      );

      final request =
          _hasBusinessProfile
              ? http.MultipartRequest(
                  'PUT',
                  uri,
                )
              : http.MultipartRequest(
                  'POST',
                  uri,
                );

      // ==================================================
      // AUTH
      // ==================================================

      request.headers['Authorization'] =
          'Bearer $token';

      // ==================================================
      // BUSINESS DATA
      // ==================================================

      request.fields['business_name'] =
          businessName;

      request.fields['category'] =
          category;

      request.fields['phone'] =
          phone;

      request.fields['address'] =
          address;

      request.fields['website'] =
          website;

      request.fields['social_media_handles'] =
          socialMedia;

      request.fields['description'] =
          description;

      // ==================================================
      // LOGO
      // ==================================================

      if (_selectedLogo != null &&
          _selectedLogoBytes != null) {
        final logoFile =
            http.MultipartFile.fromBytes(
          'logo',
          _selectedLogoBytes!,
          filename: _selectedLogo!.name,
        );

        request.files.add(
          logoFile,
        );
      }

      // ==================================================
      // SEND
      // ==================================================

      final streamedResponse =
          await request.send();

      final response =
          await http.Response.fromStream(
        streamedResponse,
      );

      debugPrint(
        'SAVE BUSINESS PROFILE STATUS: '
        '${response.statusCode}',
      );

      debugPrint(
        'SAVE BUSINESS PROFILE RESPONSE: '
        '${response.body}',
      );

      final data =
          jsonDecode(response.body);

      if ((response.statusCode == 200 ||
              response.statusCode == 201) &&
          data['success'] == true) {
        if (!mounted) return;

        setState(() {
          _hasBusinessProfile = true;

          if (data['business_profile'] != null) {
            _existingLogoUrl =
                data['business_profile']
                    ['logo_url'];
          }
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              _hasBusinessProfile
                  ? 'Business profile saved successfully'
                  : 'Business profile saved successfully',
            ),
          ),
        );

        Navigator.pop(
          context,
          true,
        );

        return;
      }

      _showMessage(
        data['message'] ??
            'Unable to save business profile',
      );
    } catch (e) {
      debugPrint(
        'SAVE BUSINESS PROFILE ERROR: $e',
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

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
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
    _phoneController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _socialController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  // ==================================================
  // BUILD
  // ==================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          backgroundColor,

      body: SafeArea(
        child: Column(
          children: [
            // ==================================================
            // HEADER
            // ==================================================

            Container(
              padding:
                  const EdgeInsets.fromLTRB(
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
                      decoration:
                          BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(
                          10,
                        ),
                        border:
                            Border.all(
                          color:
                              const Color(
                            0xFFE5E7EB,
                          ),
                        ),
                      ),
                      child:
                          const Icon(
                        Icons
                            .arrow_back_rounded,
                        size: 20,
                        color: textColor,
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 11,
                  ),

                  Container(
                    width: 38,
                    height: 38,
                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xFFF0EDFF,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        10,
                      ),
                    ),
                    child:
                        const Icon(
                      Icons
                          .storefront_outlined,
                      size: 19,
                      color:
                          primaryColor,
                    ),
                  ),

                  const SizedBox(
                    width: 11,
                  ),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Business Profile',
                          style:
                              TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w700,
                            color:
                                textColor,
                          ),
                        ),
                        SizedBox(
                          height: 2,
                        ),
                        Text(
                          'Set up your business details',
                          style:
                              TextStyle(
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
                        color:
                            primaryColor,
                      ),
                    )
                  : SingleChildScrollView(
                      padding:
                          const EdgeInsets
                              .fromLTRB(
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
                            'Tell us about your business',
                            style:
                                TextStyle(
                              fontSize: 22,
                              fontWeight:
                                  FontWeight.w700,
                              color:
                                  textColor,
                            ),
                          ),

                          const SizedBox(
                            height: 5,
                          ),

                          const Text(
                            'This information helps AI create content '
                            'that fits your brand.',
                            style:
                                TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color:
                                  secondaryText,
                            ),
                          ),

                          const SizedBox(
                            height: 22,
                          ),

                          // ==================================================
                          // LOGO
                          // ==================================================

                          _fieldLabel(
                            'Business Logo',
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          Container(
                            padding:
                                const EdgeInsets.all(
                              12,
                            ),
                            decoration:
                                BoxDecoration(
                              color:
                                  Colors.white,
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                12,
                              ),
                              border:
                                  Border.all(
                                color:
                                    const Color(
                                  0xFFE5E7EB,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
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
                                  child:
                                      _selectedLogoBytes !=
                                              null
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                12,
                                              ),
                                              child:
                                                  Image.memory(
                                                _selectedLogoBytes!,
                                                width:
                                                    52,
                                                height:
                                                    52,
                                                fit: BoxFit
                                                    .cover,
                                              ),
                                            )
                                          : _existingLogoUrl !=
                                                      null &&
                                                  _existingLogoUrl!
                                                      .isNotEmpty
                                              ? ClipRRect(
                                                  borderRadius:
                                                      BorderRadius
                                                          .circular(
                                                    12,
                                                  ),
                                                  child:
                                                      Image.network(
                                                    _existingLogoUrl!,
                                                    width:
                                                        52,
                                                    height:
                                                        52,
                                                    fit: BoxFit
                                                        .cover,
                                                    errorBuilder:
                                                        (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
                                                      return const Icon(
                                                        Icons
                                                            .add_photo_alternate_outlined,
                                                        color:
                                                            primaryColor,
                                                        size:
                                                            24,
                                                      );
                                                    },
                                                  ),
                                                )
                                              : const Icon(
                                                  Icons
                                                      .add_photo_alternate_outlined,
                                                  color:
                                                      primaryColor,
                                                  size:
                                                      24,
                                                ),
                                ),

                                const SizedBox(
                                  width: 12,
                                ),

                                Expanded(
                                  child:
                                      Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      Text(
                                        _selectedLogoBytes !=
                                                null
                                            ? 'Logo selected'
                                            : _existingLogoUrl !=
                                                        null &&
                                                    _existingLogoUrl!
                                                        .isNotEmpty
                                                ? 'Current logo'
                                                : 'Add your logo',
                                        style:
                                            const TextStyle(
                                          fontSize:
                                              13,
                                          fontWeight:
                                              FontWeight
                                                  .w600,
                                          color:
                                              textColor,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 3,
                                      ),
                                      const Text(
                                        'PNG or JPG',
                                        style:
                                            TextStyle(
                                          fontSize:
                                              11,
                                          color:
                                              secondaryText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                OutlinedButton(
                                  onPressed:
                                      _isSaving
                                          ? null
                                          : _pickLogo,
                                  style:
                                      OutlinedButton
                                          .styleFrom(
                                    foregroundColor:
                                        primaryColor,
                                    side:
                                        const BorderSide(
                                      color:
                                          Color(
                                        0xFFDCD6FF,
                                      ),
                                    ),
                                    padding:
                                        const EdgeInsets
                                            .symmetric(
                                      horizontal:
                                          12,
                                    ),
                                    minimumSize:
                                        const Size(
                                      0,
                                      36,
                                    ),
                                    shape:
                                        RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        9,
                                      ),
                                    ),
                                  ),
                                  child:
                                      const Text(
                                    'Upload',
                                    style:
                                        TextStyle(
                                      fontSize:
                                          11,
                                      fontWeight:
                                          FontWeight
                                              .w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(
                            height: 20,
                          ),

                          // ==================================================
                          // BUSINESS NAME
                          // ==================================================

                          _fieldLabel(
                            'Business Name',
                          ),

                          const SizedBox(
                            height: 7,
                          ),

                          _textField(
                            controller:
                                _businessNameController,
                            hint:
                                'Enter your business name',
                            icon:
                                Icons
                                    .storefront_outlined,
                          ),

                          const SizedBox(
                            height: 16,
                          ),

                          // ==================================================
                          // CATEGORY
                          // ==================================================

                          _fieldLabel(
                            'Business Category',
                          ),

                          const SizedBox(
                            height: 7,
                          ),

                          Container(
                            decoration:
                                BoxDecoration(
                              color:
                                  Colors.white,
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                11,
                              ),
                            ),
                            child:
                                DropdownButtonFormField<
                                    String>(
                              initialValue:
                                  _selectedCategory,
                              isExpanded:
                                  true,
                              hint:
                                  const Text(
                                'Select a category',
                                style:
                                    TextStyle(
                                  fontSize:
                                      12,
                                  color:
                                      Color(
                                    0xFF9CA3AF,
                                  ),
                                ),
                              ),
                              icon:
                                  const Icon(
                                Icons
                                    .keyboard_arrow_down_rounded,
                                color:
                                    secondaryText,
                              ),
                              decoration:
                                  InputDecoration(
                                prefixIcon:
                                    const Icon(
                                  Icons
                                      .category_outlined,
                                  size: 19,
                                  color:
                                      secondaryText,
                                ),
                                contentPadding:
                                    const EdgeInsets
                                        .symmetric(
                                  vertical:
                                      13,
                                  horizontal:
                                      12,
                                ),
                                border:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    11,
                                  ),
                                  borderSide:
                                      const BorderSide(
                                    color:
                                        Color(
                                      0xFFE5E7EB,
                                    ),
                                  ),
                                ),
                                enabledBorder:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    11,
                                  ),
                                  borderSide:
                                      const BorderSide(
                                    color:
                                        Color(
                                      0xFFE5E7EB,
                                    ),
                                  ),
                                ),
                                focusedBorder:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    11,
                                  ),
                                  borderSide:
                                      const BorderSide(
                                    color:
                                        primaryColor,
                                    width:
                                        1.5,
                                  ),
                                ),
                              ),
                              items:
                                  _categories
                                      .map(
                                (
                                  category,
                                ) {
                                  return DropdownMenuItem<
                                      String>(
                                    value:
                                        category,
                                    child:
                                        Text(
                                      category,
                                      style:
                                          const TextStyle(
                                        fontSize:
                                            12,
                                        color:
                                            textColor,
                                      ),
                                    ),
                                  );
                                },
                              ).toList(),
                              onChanged:
                                  (value) {
                                setState(() {
                                  _selectedCategory =
                                      value;
                                });
                              },
                            ),
                          ),

                          const SizedBox(
                            height: 16,
                          ),

                          // ==================================================
                          // PHONE
                          // ==================================================

                          _fieldLabel(
                            'Phone / WhatsApp',
                          ),

                          const SizedBox(
                            height: 7,
                          ),

                          _textField(
                            controller:
                                _phoneController,
                            hint:
                                'Enter phone number',
                            icon:
                                Icons.phone_outlined,
                            keyboardType:
                                TextInputType.phone,
                          ),

                          const SizedBox(
                            height: 16,
                          ),

                          // ==================================================
                          // WEBSITE
                          // ==================================================

                          _fieldLabel(
                            'Website',
                          ),

                          const SizedBox(
                            height: 7,
                          ),

                          _textField(
                            controller:
                                _websiteController,
                            hint:
                                'https://yourwebsite.com',
                            icon:
                                Icons
                                    .language_outlined,
                            keyboardType:
                                TextInputType.url,
                          ),

                          const SizedBox(
                            height: 16,
                          ),

                          // ==================================================
                          // ADDRESS
                          // ==================================================

                          _fieldLabel(
                            'Address',
                          ),

                          const SizedBox(
                            height: 7,
                          ),

                          _textField(
                            controller:
                                _addressController,
                            hint:
                                'Enter your business address',
                            icon:
                                Icons
                                    .location_on_outlined,
                          ),

                          const SizedBox(
                            height: 16,
                          ),

                          // ==================================================
                          // SOCIAL MEDIA
                          // ==================================================

                          _fieldLabel(
                            'Social Media',
                          ),

                          const SizedBox(
                            height: 7,
                          ),

                          _textField(
                            controller:
                                _socialController,
                            hint:
                                'Instagram / Facebook / TikTok',
                            icon:
                                Icons
                                    .share_outlined,
                          ),

                          const SizedBox(
                            height: 16,
                          ),

                          // ==================================================
                          // DESCRIPTION
                          // ==================================================

                          _fieldLabel(
                            'Business Description',
                          ),

                          const SizedBox(
                            height: 7,
                          ),

                          TextField(
                            controller:
                                _descriptionController,
                            maxLines: 4,
                            textCapitalization:
                                TextCapitalization
                                    .sentences,
                            decoration:
                                InputDecoration(
                              hintText:
                                  'Briefly describe what your '
                                  'business offers...',
                              hintStyle:
                                  const TextStyle(
                                fontSize: 12,
                                color:
                                    Color(
                                  0xFF9CA3AF,
                                ),
                              ),
                              alignLabelWithHint:
                                  true,
                              filled:
                                  true,
                              fillColor:
                                  Colors.white,
                              contentPadding:
                                  const EdgeInsets
                                      .all(
                                13,
                              ),
                              border:
                                  OutlineInputBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  11,
                                ),
                                borderSide:
                                    const BorderSide(
                                  color:
                                      Color(
                                    0xFFE5E7EB,
                                  ),
                                ),
                              ),
                              enabledBorder:
                                  OutlineInputBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  11,
                                ),
                                borderSide:
                                    const BorderSide(
                                  color:
                                      Color(
                                    0xFFE5E7EB,
                                  ),
                                ),
                              ),
                              focusedBorder:
                                  OutlineInputBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
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

                          const SizedBox(
                            height: 22,
                          ),

                          // ==================================================
                          // BRAND KIT CARD
                          // ==================================================

                          _fieldLabel(
                            'Brand Kit',
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          InkWell(
                            onTap:
                                _openBrandKit,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              13,
                            ),
                            child:
                                Container(
                              padding:
                                  const EdgeInsets
                                      .all(
                                14,
                              ),
                              decoration:
                                  BoxDecoration(
                                color:
                                    Colors.white,
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  13,
                                ),
                                border:
                                    Border.all(
                                  color:
                                      const Color(
                                    0xFFE5E7EB,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width:
                                        46,
                                    height:
                                        46,
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
                                    child:
                                        const Icon(
                                      Icons
                                          .palette_outlined,
                                      color:
                                          primaryColor,
                                      size:
                                          23,
                                    ),
                                  ),

                                  const SizedBox(
                                    width: 12,
                                  ),

                                  const Expanded(
                                    child:
                                        Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: [
                                        Text(
                                          'Brand Kit',
                                          style:
                                              TextStyle(
                                            fontSize:
                                                13,
                                            fontWeight:
                                                FontWeight
                                                    .w700,
                                            color:
                                                textColor,
                                          ),
                                        ),
                                        SizedBox(
                                          height:
                                              3,
                                        ),
                                        Text(
                                          'Manage logo, colors, font and contact info',
                                          style:
                                              TextStyle(
                                            fontSize:
                                                11,
                                            color:
                                                secondaryText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const Icon(
                                    Icons
                                        .arrow_forward_ios_rounded,
                                    size:
                                        16,
                                    color:
                                        secondaryText,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(
                            height: 22,
                          ),

                          // ==================================================
                          // SAVE BUTTON
                          // ==================================================

                          SizedBox(
                            width:
                                double.infinity,
                            height:
                                48,
                            child:
                                ElevatedButton(
                              onPressed:
                                  _isSaving
                                      ? null
                                      : _saveBusinessProfile,
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
                                elevation:
                                    0,
                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    11,
                                  ),
                                ),
                              ),
                              child:
                                  _isSaving
                                      ? const SizedBox(
                                          width:
                                              22,
                                          height:
                                              22,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth:
                                                2,
                                            color:
                                                Colors.white,
                                          ),
                                        )
                                      : Text(
                                          _hasBusinessProfile
                                              ? 'Update Business Profile'
                                              : 'Save Business Profile',
                                          style:
                                              const TextStyle(
                                            fontSize:
                                                14,
                                            fontWeight:
                                                FontWeight
                                                    .w600,
                                          ),
                                        ),
                            ),
                          ),

                          const SizedBox(
                            height: 5,
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
  // FIELD LABEL
  // ==================================================

  Widget _fieldLabel(
    String text,
  ) {
    return Text(
      text,
      style:
          const TextStyle(
        fontSize: 12,
        fontWeight:
            FontWeight.w600,
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
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller:
          controller,
      keyboardType:
          keyboardType,
      decoration:
          InputDecoration(
        hintText:
            hint,
        hintStyle:
            const TextStyle(
          fontSize: 12,
          color:
              Color(
            0xFF9CA3AF,
          ),
        ),
        prefixIcon:
            Icon(
          icon,
          size: 19,
          color:
              secondaryText,
        ),
        filled:
            true,
        fillColor:
            Colors.white,
        contentPadding:
            const EdgeInsets
                .symmetric(
          vertical: 13,
          horizontal: 12,
        ),
        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius
                  .circular(
            11,
          ),
          borderSide:
              const BorderSide(
            color:
                Color(
              0xFFE5E7EB,
            ),
          ),
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius
                  .circular(
            11,
          ),
          borderSide:
              const BorderSide(
            color:
                Color(
              0xFFE5E7EB,
            ),
          ),
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius
                  .circular(
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
    );
  }
}