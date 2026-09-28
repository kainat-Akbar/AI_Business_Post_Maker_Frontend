import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'post_result_screen.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  static const Color primaryColor = Color(0xFF6366F1);
  static const Color scaffoldBg = Color(0xFFF1F5F9);
  static const Color cardColor = Colors.white;
  static const Color textMain = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);

  final TextEditingController _promptController = TextEditingController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = false;
  bool _isTemplateLoading = true;

  XFile? _productImage;
  int? _selectedTemplateId;
  String _selectedTemplateName = '';

  String _selectedFormat = 'Instagram Post';
  String _selectedContentType = 'Promotional';
  String _selectedLanguage = 'Roman Urdu';
  String _selectedTone = 'Professional';

  List<Map<String, dynamic>> _templates = [];

  final List<String> _formats = [
    'Instagram Post',
    'Instagram Story',
    'Facebook Post',
    'WhatsApp Status',
    'Reel Cover',
  ];

  final List<String> _contentTypes = [
    'Promotional',
    'Informational',
    'Seasonal',
    'Product',
    'Service',
    'Announcement',
    'Sale',
    'Special-Event',
  ];

  final List<String> _languages = [
    'English',
    'Roman Urdu',
    'Urdu',
    'Mixed (Urdu-English)',
    'Arabic',
    'Turkish',
    'German',
    'French',
    'Spanish',
  ];

  final List<String> _tones = [
    'Professional',
    'Casual',
    'Exciting',
    'Informative',
    'Urgent',
  ];

  // ============================================================
  // BASE URL
  // ============================================================

  String get baseUrl {
    return 'https://aibusinesspostmaker-production.up.railway.app';
  }

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD TEMPLATES
  // ============================================================

  Future<void> _loadTemplates() async {
    try {
      final token = await _storage.read(key: 'access_token');

      if (token == null || token.isEmpty) {
        throw Exception('Please login again.');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/templates'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode != 200) {
        throw Exception('Unable to load templates.');
      }

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception('Invalid template response.');
      }

      final data = decoded;

      if (data['success'] != true) {
        throw Exception(
          data['message']?.toString() ?? 'Unable to load templates.',
        );
      }

      final List<dynamic> templateList =
          data['templates'] is List ? data['templates'] as List : [];

      setState(() {
        _templates = templateList
            .whereType<Map>()
            .map(
              (item) => Map<String, dynamic>.from(item),
            )
            .toList();

        _isTemplateLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isTemplateLoading = false;
      });

      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // ============================================================
  // SELECT TEMPLATE
  // ============================================================

  Future<void> _selectTemplate(
    Map<String, dynamic> template,
  ) async {
    final dynamic rawId = template['id'];

    int? templateId;

    if (rawId is int) {
      templateId = rawId;
    } else {
      templateId = int.tryParse(
        rawId?.toString() ?? '',
      );
    }

    if (templateId == null) {
      _showMessage('Invalid template selected.');
      return;
    }

    setState(() {
      _selectedTemplateId = templateId;
      _selectedTemplateName =
          template['name']?.toString() ?? 'Template';
    });

    await _pickProductImage();
  }

  // ============================================================
  // PICK PRODUCT IMAGE
  // ============================================================

  Future<void> _pickProductImage() async {
    try {
      final XFile? pickedImage =
          await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (pickedImage == null) {
        return;
      }

      if (!mounted) return;

      setState(() {
        _productImage = pickedImage;
      });
    } catch (e) {
      if (!mounted) return;

      _showMessage('Unable to select image.');
    }
  }

  // ============================================================
  // GENERATE COMPLETE POST
  // ============================================================

  Future<void> _generateContentWithAI() async {
    if (_selectedTemplateId == null) {
      _showMessage('Please select a template first.');
      return;
    }

    if (_productImage == null) {
      _showMessage('Please upload your product image.');
      return;
    }

    final prompt = _promptController.text.trim();

    if (prompt.isEmpty) {
      _showMessage('Please enter product details.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // ----------------------------------------------------------
      // JWT TOKEN
      // ----------------------------------------------------------

      final token = await _storage.read(
        key: 'access_token',
      );

      if (token == null || token.isEmpty) {
        throw Exception('Please login again.');
      }

      // ----------------------------------------------------------
      // MULTIPART REQUEST
      // ----------------------------------------------------------

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
          '$baseUrl/api/ai/generate-complete-post',
        ),
      );

      request.headers['Authorization'] =
          'Bearer $token';

      request.fields['prompt'] =
          prompt;

      request.fields['content_type'] =
          _selectedContentType;

      request.fields['format'] =
          _selectedFormat;

      request.fields['language'] =
          _selectedLanguage;

      request.fields['tone'] =
          _selectedTone;

      request.fields['template_id'] =
          _selectedTemplateId.toString();

      // ----------------------------------------------------------
      // PRODUCT IMAGE
      // ----------------------------------------------------------

      final Uint8List bytes =
          await _productImage!.readAsBytes();

      request.files.add(
        http.MultipartFile.fromBytes(
          'product_image',
          bytes,
          filename: _productImage!.name,
        ),
      );

      // ----------------------------------------------------------
      // SEND REQUEST
      // ----------------------------------------------------------

      final streamedResponse =
          await request.send();

      final response =
          await http.Response.fromStream(
        streamedResponse,
      );

      if (!mounted) return;

      // ----------------------------------------------------------
      // DECODE RESPONSE
      // ----------------------------------------------------------

      Map<String, dynamic> data;

      try {
        final dynamic decoded =
            jsonDecode(response.body);

        if (decoded is! Map) {
          throw Exception();
        }

        data = Map<String, dynamic>.from(
          decoded,
        );
      } catch (_) {
        throw Exception(
          'Invalid response received from server.',
        );
      }

      // ----------------------------------------------------------
      // SUCCESS
      // ----------------------------------------------------------

      if (response.statusCode == 200 &&
          data['success'] == true) {
        final dynamic rawResult =
            data['result'];

        if (rawResult is! Map) {
          throw Exception(
            'Invalid generated post data.',
          );
        }

        final Map<String, dynamic> result =
            Map<String, dynamic>.from(
          rawResult,
        );

        // --------------------------------------------------------
        // IMPORTANT:
        // Backend may return IDs either inside result
        // OR at the top level.
        //
        // We keep both so PostResultScreen never loses them.
        // --------------------------------------------------------

        if (result['project_id'] == null &&
            data['project_id'] != null) {
          result['project_id'] =
              data['project_id'];
        }

        if (result['post_id'] == null &&
            data['post_id'] != null) {
          result['post_id'] =
              data['post_id'];
        }

  // --------------------------------------------------------
        // ALSO KEEP OTHER TOP-LEVEL DATA IF BACKEND RETURNS IT
        // --------------------------------------------------------
// --------------------------------------------------------
// TOP-LEVEL FALLBACKS
// --------------------------------------------------------

if (result['image_url'] == null && data['image_url'] != null) {
  result['image_url'] = data['image_url'];
}

if (result['product_image_url'] == null && data['product_image_url'] != null) {
  result['product_image_url'] = data['product_image_url'];
}

if (result['template_id'] == null && data['template_id'] != null) {
  result['template_id'] = data['template_id'];
}
       

        // --------------------------------------------------------
        // TEMPLATE NAME FALLBACK
        // --------------------------------------------------------

        result['template_name'] =
            result['template_name'] ??
            result['template'] ??
            _selectedTemplateName;

        // --------------------------------------------------------
        // LOCAL IMAGE PATH
        //
        // This is only for local UI reference.
        // Backend's product_image_url remains the real
        // Cloudinary product image URL.
        // --------------------------------------------------------

        result['local_product_image'] =
            _productImage!.path;

        // --------------------------------------------------------
        // DEBUG
        // --------------------------------------------------------

        debugPrint(
          'GENERATE RESPONSE: ${jsonEncode(data)}',
        );

        debugPrint(
          'FINAL RESULT SENT TO POST RESULT: '
          '${jsonEncode(result)}',
        );

        // --------------------------------------------------------
        // OPEN POST RESULT SCREEN
        // --------------------------------------------------------

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PostResultScreen(
              generatedData: result,
            ),
          ),
        );
      }

      // ----------------------------------------------------------
      // ERROR
      // ----------------------------------------------------------

      else {
        String errorMessage =
            data['message']?.toString() ?? '';

        if (response.statusCode == 401 ||
            response.statusCode == 403) {
          errorMessage =
              'Your session has expired. Please log in again.';
        } else if (errorMessage.isEmpty) {
          errorMessage =
              'Failed to generate post. Please try again.';
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Error: ${e.toString().replaceFirst(
          'Exception: ',
          '',
        )}',
      );
  
  } finally {
  if (mounted) {
    setState(() {
      _isLoading = false;
    });
  }
}
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: textMain,
        ),
        title: const Text(
          'Create Post',
          style: TextStyle(
            color: textMain,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTemplateSection(),

            if (_selectedTemplateId != null)
              _buildProductImageSection(),

            _buildSection(
              'Select Format',
              _buildHorizontalList(
                _formats,
                _selectedFormat,
                (value) {
                  setState(() {
                    _selectedFormat = value;
                  });
                },
              ),
            ),

            _buildSection(
              'Content Type',
              _buildHorizontalList(
                _contentTypes,
                _selectedContentType,
                (value) {
                  setState(() {
                    _selectedContentType = value;
                  });
                },
              ),
            ),

            _buildSection(
              'Language Style',
              _buildHorizontalList(
                _languages,
                _selectedLanguage,
                (value) {
                  setState(() {
                    _selectedLanguage = value;
                  });
                },
              ),
            ),

            _buildSection(
              'Tone & Vibe',
              _buildHorizontalList(
                _tones,
                _selectedTone,
                (value) {
                  setState(() {
                    _selectedTone = value;
                  });
                },
              ),
            ),

            _buildPromptSection(),

            const SizedBox(height: 4),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading
                    ? null
                    : _generateContentWithAI,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.auto_awesome_rounded,
                      ),
                label: Text(
                  _isLoading
                      ? 'Creating Your Post...'
                      : 'Generate Final Post',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TEMPLATE SECTION
  // ============================================================

  Widget _buildTemplateSection() {
    return _buildSection(
      'Choose Template',
      _isTemplateLoading
          ? const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: primaryColor,
              ),
            )
          : _templates.isEmpty
              ? const Padding(
                  padding:
                      EdgeInsets.symmetric(
                    vertical: 20,
                  ),
                  child: Center(
                    child: Text(
                      'No templates available.',
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                )
              : SizedBox(
                  height: 155,
                  child: ListView.separated(
                    scrollDirection:
                        Axis.horizontal,
                    itemCount:
                        _templates.length,
                    separatorBuilder:
                        (_, _) =>
                            const SizedBox(
                      width: 12,
                    ),
                    itemBuilder:
                        (context, index) {
                      final template =
                          _templates[index];

                      final dynamic rawId =
                          template['id'];

                      final int? id =
                          rawId is int
                              ? rawId
                              : int.tryParse(
                                  rawId?.toString() ??
                                      '',
                                );

                      final bool selected =
                          id ==
                              _selectedTemplateId;

                      final String preview =
                          (template['preview_url']
                                      ?.toString() ??
                                  '')
                              .replaceAll(
                                ' ',
                                '%20',
                              );

                      final String name =
                          template['name']
                                  ?.toString() ??
                              'Template';

                      return GestureDetector(
                        onTap: id == null
                            ? null
                            : () =>
                                _selectTemplate(
                                  template,
                                ),
                        child: Container(
                          width: 125,
                          decoration:
                              BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              14,
                            ),
                            border:
                                Border.all(
                              color: selected
                                  ? primaryColor
                                  : const Color(
                                      0xFFE2E8F0,
                                    ),
                              width:
                                  selected
                                      ? 2
                                      : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child:
                                    ClipRRect(
                                  borderRadius:
                                      const BorderRadius
                                          .vertical(
                                    top: Radius
                                        .circular(
                                      13,
                                    ),
                                  ),
                                  child: preview
                                          .isNotEmpty
                                      ? Image.network(
                                          preview,
                                          width:
                                              double.infinity,
                                          fit: BoxFit
                                              .cover,
                                          errorBuilder:
                                              (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            return Container(
                                              color:
                                                  scaffoldBg,
                                              child:
                                                  const Center(
                                                child:
                                                    Icon(
                                                  Icons
                                                      .broken_image_outlined,
                                                  size:
                                                      30,
                                                  color:
                                                      textMuted,
                                                ),
                                              ),
                                            );
                                          },
                                        )
                                      : Container(
                                          color:
                                              scaffoldBg,
                                          child:
                                              const Center(
                                            child:
                                                Icon(
                                              Icons
                                                  .image_outlined,
                                              size:
                                                  30,
                                              color:
                                                  textMuted,
                                            ),
                                          ),
                                        ),
                                ),
                              ),

                              Padding(
                                padding:
                                    const EdgeInsets
                                        .all(8),
                                child: Text(
                                  name,
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                  style:
                                      TextStyle(
                                    color: selected
                                        ? primaryColor
                                        : textMain,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  // ============================================================
  // PRODUCT IMAGE SECTION
  // ============================================================

  Widget _buildProductImageSection() {
    return _buildSection(
      'Product Image',
      Column(
        children: [
          if (_productImage != null)
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(14),
              child:
                  FutureBuilder<Uint8List>(
                future:
                    _productImage!.readAsBytes(),
                builder:
                    (context, snapshot) {
                  if (snapshot.connectionState ==
                          ConnectionState.done &&
                      snapshot.hasData) {
                    return Image.memory(
                      snapshot.data!,
                      width:
                          double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                    );
                  }

                  return Container(
                    width:
                        double.infinity,
                    height: 220,
                    color: scaffoldBg,
                    child:
                        const Center(
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color:
                            primaryColor,
                      ),
                    ),
                  );
                },
              ),
            )
          else
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: scaffoldBg,
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),
              child: const Icon(
                Icons
                    .add_photo_alternate_outlined,
                size: 50,
                color: textMuted,
              ),
            ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isLoading
                  ? null
                  : _pickProductImage,
              icon: const Icon(
                Icons
                    .photo_library_outlined,
              ),
              label: Text(
                _productImage == null
                    ? 'Upload Product Image'
                    : 'Change Product Image',
              ),
              style:
                  OutlinedButton.styleFrom(
                foregroundColor:
                    primaryColor,
                side:
                    const BorderSide(
                  color: primaryColor,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRODUCT DETAILS
  // ============================================================

  Widget _buildPromptSection() {
    return _buildSection(
      'Product Details',
      TextField(
        controller: _promptController,
        maxLines: 4,
        style: const TextStyle(
          color: textMain,
          fontSize: 13,
        ),
        decoration: InputDecoration(
          hintText:
              'Describe your product, offer or promotion...\n'
              'Example: New summer collection with 20% discount.',
          hintStyle: const TextStyle(
            color: textMuted,
            fontSize: 12,
          ),
          filled: true,
          fillColor: scaffoldBg,
          contentPadding:
              const EdgeInsets.all(12),
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // COMMON SECTION
  // ============================================================

  Widget _buildSection(
    String title,
    Widget child,
  ) {
    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(bottom: 14),
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: textMain,
              fontWeight:
                  FontWeight.bold,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 12),

          child,
        ],
      ),
    );
  }

  // ============================================================
  // HORIZONTAL OPTIONS
  // ============================================================

  Widget _buildHorizontalList(
    List<String> items,
    String selected,
    Function(String) onTap,
  ) {
    return SingleChildScrollView(
      scrollDirection:
          Axis.horizontal,
      physics:
          const BouncingScrollPhysics(),
      child: Row(
        children:
            items.map((item) {
          final bool isSelected =
              item == selected;

          return Padding(
            padding:
                const EdgeInsets.only(
              right: 8,
            ),
            child: GestureDetector(
              onTap: () =>
                  onTap(item),
              child: Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration:
                    BoxDecoration(
                  color: isSelected
                      ? primaryColor
                      : scaffoldBg,
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
                child: Text(
                  item,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : textMain,
                    fontWeight:
                        FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}