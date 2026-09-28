import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:universal_html/html.dart' as html;

class PostResultScreen extends StatefulWidget {
  final Map<String, dynamic> generatedData;

  const PostResultScreen({
    super.key,
    required this.generatedData,
  });

  @override
  State<PostResultScreen> createState() =>
      _PostResultScreenState();
}

class _PostResultScreenState
    extends State<PostResultScreen> {

  static const Color primaryColor =
      Color(0xFF6366F1);

  static const Color scaffoldBg =
      Color(0xFFF1F5F9);

  static const Color textMain =
      Color(0xFF1E293B);

  final FlutterSecureStorage _storage =
      const FlutterSecureStorage();

  bool _isDownloading = false;

  bool _isRegenerating = false;

  bool _isLoadingOriginalIds = false;

  late Map<String, dynamic> _currentData;

  @override
  void initState() {
    super.initState();

    _currentData =
        Map<String, dynamic>.from(
      widget.generatedData,
    );

    _normalizeCurrentData();

    debugPrint(
      'POST RESULT INITIAL DATA: '
      '${jsonEncode(_currentData)}',
    );

    _ensureOriginalIds();
  }

  // =========================================================
  // NORMALIZE DATA
  // =========================================================

  void _normalizeCurrentData() {

    // FINAL GENERATED IMAGE
    _currentData['image_url'] =
        _currentData['image_url'] ??
        _currentData['download_url'] ??
        _currentData['result_image'] ??
        _currentData['url'] ??
        '';

    _currentData['download_url'] =
        _currentData['download_url'] ??
        _currentData['image_url'] ??
        '';

    // IMPORTANT:
    //
    // product_image_url is the ORIGINAL PRODUCT IMAGE.
    //
    // image_url is the FINAL GENERATED POST IMAGE.
    //
    // Never copy image_url into product_image_url.

    _currentData['product_image_url'] =
        _currentData['product_image_url'] ??
        '';

    _currentData['template_url'] =
        _currentData['template_url'] ??
        '';

    _currentData['template_data'] =
        _currentData['template_data'] ??
        {};

    _currentData['logo_url'] =
        _currentData['logo_url'] ??
        '';

    _currentData['business_name'] =
        _currentData['business_name'] ??
        '';

    _currentData['category'] =
        _currentData['category'] ??
        '';

    _currentData['phone'] =
        _currentData['phone'] ??
        _currentData['contact'] ??
        '';

    _currentData['contact'] =
        _currentData['contact'] ??
        _currentData['phone'] ??
        '';

    _currentData['address'] =
        _currentData['address'] ??
        '';

    _currentData['website'] =
        _currentData['website'] ??
        '';

    _currentData['description'] =
        _currentData['description'] ??
        '';

    _currentData['brand_colors'] =
        _currentData['brand_colors'] ??
        [];

    _currentData['preferred_font'] =
        _currentData['preferred_font'] ??
        '';
  }

  // =========================================================
  // ENSURE PROJECT / POST ID
  //
  // Agar CreatePost se IDs lost ho gaye hon,
  // to current final image ke through /api/projects se
  // original project find kar lega.
  // =========================================================

  Future<void> _ensureOriginalIds() async {

    final hasProjectId =
        _currentData['project_id'] != null &&
        _currentData['project_id']
            .toString()
            .trim()
            .isNotEmpty;

    final hasPostId =
        _currentData['post_id'] != null &&
        _currentData['post_id']
            .toString()
            .trim()
            .isNotEmpty;

    if (hasProjectId || hasPostId) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoadingOriginalIds = true;
    });

    try {

      final token =
          await _storage.read(
        key: 'access_token',
      );

      if (token == null ||
          token.trim().isEmpty) {

        return;
      }
       final String baseUrl = 'https://aibusinesspostmaker-production.up.railway.app';
      final response =
          await http.get(
        Uri.parse(
          '$baseUrl/api/projects',
        ),
        headers: {
          'Authorization':
              'Bearer $token',
        },
      );

      debugPrint(
        'PROJECT LOOKUP STATUS: '
        '${response.statusCode}',
      );

      if (response.statusCode != 200) {
        return;
      }

      final Map<String, dynamic> data =
          jsonDecode(response.body);

      if (data['success'] != true) {
        return;
      }

      final List projects =
          data['projects'] is List
              ? data['projects']
              : [];

      final String currentImage =
          _currentData['image_url']
              ?.toString()
              .trim() ??
          '';

      final String currentHeadline =
          _currentData['headline']
              ?.toString()
              .trim() ??
          '';

      final String currentProductImage =
          _currentData[
                  'product_image_url']
              ?.toString()
              .trim() ??
          '';

      Map<String, dynamic>? matchedProject;

      for (final item in projects) {

        if (item is! Map) {
          continue;
        }

        final Map<String, dynamic> project =
            Map<String, dynamic>.from(
          item,
        );

        final String projectImage =
            project['image_url']
                    ?.toString()
                    .trim() ??
                '';

        final String downloadImage =
            project['download_url']
                    ?.toString()
                    .trim() ??
                '';

        final String projectHeadline =
            project['headline']
                    ?.toString()
                    .trim() ??
                '';

        final String projectProductImage =
            project[
                    'product_image_url']
                    ?.toString()
                    .trim() ??
                '';

        // Best match: final image URL.
        if (currentImage.isNotEmpty &&
            (projectImage == currentImage ||
                downloadImage == currentImage)) {

          matchedProject = project;
          break;
        }

        // Second match: headline + product image.
        if (currentHeadline.isNotEmpty &&
            projectHeadline ==
                currentHeadline &&
            currentProductImage
                .isNotEmpty &&
            projectProductImage ==
                currentProductImage) {

          matchedProject = project;
          break;
        }
      }

      if (matchedProject == null) {
        debugPrint(
          'No matching original project found.',
        );
        return;
      }

      if (!mounted) return;

      setState(() {

        _currentData['project_id'] =
            matchedProject![
                'project_id'];

        // Current /api/projects response
        // does not need post_id.
        //
        // Backend can find Post using
        // project_id.

        if (matchedProject[
                'product_image_url'] !=
            null) {

          _currentData[
                  'product_image_url'] =
              matchedProject[
                  'product_image_url'];
        }

        if ((_currentData['headline']
                    ?.toString()
                    .isEmpty ??
                true) &&
            matchedProject[
                    'headline'] !=
                null) {

          _currentData['headline'] =
              matchedProject[
                  'headline'];
        }

        if ((_currentData['caption']
                    ?.toString()
                    .isEmpty ??
                true) &&
            matchedProject[
                    'caption'] !=
                null) {

          _currentData['caption'] =
              matchedProject[
                  'caption'];
        }

        if ((_currentData['hashtags']
                    ?.toString()
                    .isEmpty ??
                true) &&
            matchedProject[
                    'hashtags'] !=
                null) {

          _currentData['hashtags'] =
              matchedProject[
                  'hashtags'];
        }

        if ((_currentData['cta']
                    ?.toString()
                    .isEmpty ??
                true) &&
            matchedProject[
                    'cta'] !=
                null) {

          _currentData['cta'] =
              matchedProject[
                  'cta'];
        }
      });

      debugPrint(
        'RECOVERED PROJECT ID: '
        '${_currentData['project_id']}',
      );

    } catch (e) {

      debugPrint(
        'PROJECT ID LOOKUP ERROR: $e',
      );

    } finally {

      if (mounted) {

        setState(() {
          _isLoadingOriginalIds = false;
        });
      }
    }
  }

  // =========================================================
  // COPY
  // =========================================================

  void _copyToClipboard(
    String text,
    String label,
  ) {

    Clipboard.setData(
      ClipboardData(
        text: text,
      ),
    );

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          '$label copied to clipboard!',
        ),
        backgroundColor:
            Colors.green,
        duration:
            const Duration(
          seconds: 2,
        ),
      ),
    );
  }

  // =========================================================
  // MESSAGE
  // =========================================================

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

  // =========================================================
  // DOWNLOAD IMAGE
  // =========================================================

  Future<void> _downloadImage(
    String imageUrl,
  ) async {

    try {

      setState(() {
        _isDownloading = true;
      });

      if (kIsWeb) {

        html.AnchorElement(
          href: imageUrl,
        )
          ..setAttribute(
            "download",
            "ai_business_post_${DateTime.now().millisecondsSinceEpoch}.png",
          )
          ..click();

        if (!mounted) return;

        _showMessage(
          'Image downloaded successfully!',
        );

        return;
      }

      final response =
          await http.get(
        Uri.parse(imageUrl),
      );

      if (response.statusCode != 200) {

        throw Exception(
          'Image download failed: '
          '${response.statusCode}',
        );
      }

      final bytes =
          response.bodyBytes;

      final output =
          await getTemporaryDirectory();

      final file = File(
        '${output.path}/ai_business_post_${DateTime.now().millisecondsSinceEpoch}.png',
      );

      await file.writeAsBytes(
        bytes,
      );

      await Gal.putImage(
        file.path,
        album:
            'AI Business Post Maker',
      );

      if (!mounted) return;

      _showMessage(
        'Image saved to gallery successfully!',
      );

    } catch (e) {

      if (!mounted) return;

      _showMessage(
        'Failed to save image: $e',
      );

    } finally {

      if (mounted) {

        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  // =========================================================
  // EDIT BOTTOM SHEET
  // =========================================================

  void _openEditBottomSheet() {

    final headlineController =
        TextEditingController(
      text:
          _currentData['headline']
                  ?.toString() ??
              '',
    );

    final captionController =
        TextEditingController(
      text:
          _currentData['caption']
                  ?.toString() ??
              '',
    );

    final descriptionController =
        TextEditingController(
      text:
          _currentData['description']
                  ?.toString() ??
              '',
    );

    final hashtagsController =
        TextEditingController(
      text:
          _currentData['hashtags']
                  ?.toString() ??
              '',
    );

    final ctaController =
        TextEditingController(
      text:
          _currentData['cta']
                  ?.toString() ??
              '',
    );

    final contactController =
        TextEditingController(
      text:
          _currentData['phone']
                  ?.toString() ??
              _currentData['contact']
                  ?.toString() ??
              '',
    );

    XFile? selectedProductImage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.white,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {

        return StatefulBuilder(
          builder:
              (
            context,
            sheetSetState,
          ) {

            return Padding(
              padding:
                  EdgeInsets.only(
                bottom:
                    MediaQuery.of(
                  sheetContext,
                ).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 24,
              ),

              child:
                  SingleChildScrollView(

                child: Column(

                  mainAxisSize:
                      MainAxisSize.min,

                  crossAxisAlignment:
                      CrossAxisAlignment
                          .stretch,

                  children: [

                    // =================================================
                    // HEADER
                    // =================================================

                    Row(

                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,

                      children: [

                        const Text(
                          'Edit & Regenerate Post',

                          style:
                              TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                            color:
                                textMain,
                          ),
                        ),

                        IconButton(
                          icon:
                              const Icon(
                            Icons.close,
                          ),
                          onPressed: () {
                            Navigator.pop(
                              sheetContext,
                            );
                          },
                        ),
                      ],
                    ),

                    const Text(
                      'Change only the information you want. The original template, logo, business details and brand design will remain the same.',
                      style:
                          TextStyle(
                        fontSize: 12,
                        color:
                            Colors.grey,
                      ),
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    // =================================================
                    // NEW PRODUCT IMAGE
                    // =================================================

                    Container(

                      padding:
                          const EdgeInsets.all(
                        14,
                      ),

                      decoration:
                          BoxDecoration(
                        color:
                            scaffoldBg,
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                        border:
                            Border.all(
                          color:
                              const Color(
                            0xFFE2E8F0,
                          ),
                        ),
                      ),

                      child:
                          Column(

                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [

                          const Text(
                            'Product Image',
                            style:
                                TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  FontWeight.bold,
                              color:
                                  textMain,
                            ),
                          ),

                          const SizedBox(
                            height: 6,
                          ),

                          Text(
                            selectedProductImage ==
                                    null
                                ? 'Keep original product image or select a new one.'
                                : 'New product image selected.',
                            style:
                                const TextStyle(
                              fontSize: 12,
                              color:
                                  Colors.grey,
                            ),
                          ),

                          const SizedBox(
                            height: 10,
                          ),

                          OutlinedButton.icon(

                            onPressed: () async {

                              try {

                                final picker =
                                    ImagePicker();

                                final XFile?
                                    picked =
                                    await picker
                                        .pickImage(
                                  source:
                                      ImageSource
                                          .gallery,
                                );

                                if (picked ==
                                    null) {
                                  return;
                                }

                                sheetSetState(() {
                                  selectedProductImage =
                                      picked;
                                });

                              } catch (e) {

                                _showMessage(
                                  'Unable to select image: $e',
                                );
                              }
                            },

                            icon:
                                const Icon(
                              Icons
                                  .photo_library_outlined,
                            ),

                            label:
                                Text(
                              selectedProductImage ==
                                      null
                                  ? 'Choose New Product Image'
                                  : 'Change Selected Image',
                            ),

                            style:
                                OutlinedButton.styleFrom(
                              foregroundColor:
                                  primaryColor,
                              side:
                                  const BorderSide(
                                color:
                                    primaryColor,
                              ),
                            ),
                          ),

                          if (selectedProductImage !=
                              null)
                            Padding(
                              padding:
                                  const EdgeInsets.only(
                                top: 8,
                              ),
                              child:
                                  Text(
                                selectedProductImage!
                                    .name,
                                style:
                                    const TextStyle(
                                  fontSize:
                                      12,
                                  fontWeight:
                                      FontWeight.w600,
                                  color:
                                      primaryColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // =================================================
                    // TEXT FIELDS
                    // =================================================

                    _buildTextField(
                      'Headline',
                      headlineController,
                    ),

                    _buildTextField(
                      'Caption',
                      captionController,
                      maxLines: 3,
                    ),

                    _buildTextField(
                      'Description / Details',
                      descriptionController,
                      maxLines: 3,
                    ),

                    _buildTextField(
                      'Hashtags',
                      hashtagsController,
                      maxLines: 2,
                    ),

                    _buildTextField(
                      'Call to Action (CTA)',
                      ctaController,
                    ),

                    _buildTextField(
                      'Contact Info / Phone',
                      contactController,
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    // =================================================
                    // REGENERATE
                    // =================================================

                    ElevatedButton.icon(

                      onPressed:
                          _isRegenerating
                              ? null
                              : () {

                                  final editedHeadline =
                                      headlineController
                                          .text
                                          .trim();

                                  final editedCaption =
                                      captionController
                                          .text
                                          .trim();

                                  final editedDescription =
                                      descriptionController
                                          .text
                                          .trim();

                                  final editedHashtags =
                                      hashtagsController
                                          .text
                                          .trim();

                                  final editedCta =
                                      ctaController
                                          .text
                                          .trim();

                                  final editedContact =
                                      contactController
                                          .text
                                          .trim();

                                  final XFile?
                                      newImage =
                                      selectedProductImage;

                                  Navigator.pop(
                                    sheetContext,
                                  );

                                  _regeneratePostOnBackend(

                                    headline:
                                        editedHeadline,

                                    caption:
                                        editedCaption,

                                    description:
                                        editedDescription,

                                    hashtags:
                                        editedHashtags,

                                    cta:
                                        editedCta,

                                    contact:
                                        editedContact,

                                    productImage:
                                        newImage,
                                  );
                                },

                      icon:
                          const Icon(
                        Icons.refresh,
                      ),

                      label:
                          const Text(
                        'Regenerate Complete Post',
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            primaryColor,
                        foregroundColor:
                            Colors.white,
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================
  // REGENERATE EXISTING POST
  // =========================================================

  Future<void> _regeneratePostOnBackend({
    required String headline,
    required String caption,
    required String description,
    required String hashtags,
    required String cta,
    required String contact,
    XFile? productImage,
  }) async {

    if (!mounted) return;

    setState(() {
      _isRegenerating = true;
    });

    try {

      // =====================================================
      // TOKEN
      // =====================================================

      final token =
          await _storage.read(
        key: 'access_token',
      );

      if (token == null ||
          token.trim().isEmpty) {

        _showMessage(
          'Login session expired. Please login again.',
        );

        return;
      }

      // =====================================================
      // BASE URL
      // =====================================================
      final String baseUrl = 'https://aibusinesspostmaker-production.up.railway.app';
      

      // =====================================================
      // PROJECT / POST IDS
      // =====================================================

      final dynamic projectIdValue =
          _currentData['project_id'];

      final dynamic postIdValue =
          _currentData['post_id'];

  
      final String? projectId = projectIdValue?.toString().trim();

      final String? postId = postIdValue?.toString().trim();
  
      if ((projectId == null ||
              projectId.isEmpty) &&
          (postId == null ||
              postId.isEmpty)) {

        await _ensureOriginalIds();

        final dynamic recoveredProjectId =
            _currentData['project_id'];

        final dynamic recoveredPostId =
            _currentData['post_id'];

        if (recoveredProjectId == null &&
            recoveredPostId == null) {

          _showMessage(
            'Original post could not be found. Please generate the post again from Create Post.',
          );

          return;
        }
      }

      final dynamic finalProjectId =
          _currentData['project_id'];

      final dynamic finalPostId =
          _currentData['post_id'];

      // =====================================================
      // MULTIPART REQUEST
      //
      // JSON is NOT used here because we may send a new
      // product image.
      // =====================================================

      final request =
          http.MultipartRequest(
        'POST',
        Uri.parse(
          '$baseUrl/regenerate-post',
        ),
      );

      request.headers[
              'Authorization'] =
          'Bearer $token';

      // =====================================================
      // IDS
      // =====================================================

      if (finalProjectId != null &&
          finalProjectId
              .toString()
              .trim()
              .isNotEmpty) {

        request.fields[
                'project_id'] =
            finalProjectId
                .toString();
      }

      if (finalPostId != null &&
          finalPostId
              .toString()
              .trim()
              .isNotEmpty) {

        request.fields[
                'post_id'] =
            finalPostId
                .toString();
      }

      // =====================================================
      // EDITED CONTENT
      // =====================================================

      request.fields[
              'headline'] =
          headline;

      request.fields[
              'caption'] =
          caption;

      request.fields[
              'description'] =
          description;

      request.fields[
              'hashtags'] =
          hashtags;

      request.fields[
              'cta'] =
          cta;

      request.fields[
              'contact'] =
          contact;

      // =====================================================
      // OPTIONAL NEW PRODUCT IMAGE
      // =====================================================

      if (productImage != null) {

        final bytes =
            await productImage
                .readAsBytes();

        request.files.add(
          http.MultipartFile.fromBytes(
            'product_image',
            bytes,
            filename:
                productImage.name,
          ),
        );

        debugPrint(
          'NEW PRODUCT IMAGE ATTACHED: '
          '${productImage.name}',
        );
      }

      debugPrint(
        'REGENERATE PROJECT ID: '
        '${request.fields['project_id']}',
      );

      debugPrint(
        'REGENERATE POST ID: '
        '${request.fields['post_id']}',
      );

      final streamedResponse =
          await request.send();

      final response =
          await http.Response.fromStream(
        streamedResponse,
      );

      debugPrint(
        'REGENERATE STATUS: '
        '${response.statusCode}',
      );

      debugPrint(
        'REGENERATE RESPONSE: '
        '${response.body}',
      );

      Map<String, dynamic>
          responseData;

      try {

        responseData =
            jsonDecode(
          response.body,
        );

      } catch (_) {

        throw Exception(
          'Invalid server response.',
        );
      }

      if (response.statusCode == 200 &&
          responseData['success'] ==
              true) {

        // =================================================
        // COMPLETE UPDATED RESULT
        // =================================================

        final Map<String, dynamic>
            result =
            responseData['result']
                    is Map
                ? Map<String, dynamic>.from(
                    responseData[
                        'result'],
                  )
                : {};

        if (!mounted) return;

        setState(() {

          // =================================================
          // IDS
          // =================================================

          _currentData[
                  'project_id'] =
              result[
                      'project_id'] ??
                  responseData[
                      'project_id'] ??
                  _currentData[
                      'project_id'];

          _currentData[
                  'post_id'] =
              result[
                      'post_id'] ??
                  responseData[
                      'post_id'] ??
                  _currentData[
                      'post_id'];

          // =================================================
          // UPDATED CONTENT
          // =================================================

          _currentData[
                  'headline'] =
              result[
                      'headline'] ??
                  headline;

          _currentData[
                  'caption'] =
              result[
                      'caption'] ??
                  caption;

          _currentData[
                  'description'] =
              result[
                      'description'] ??
                  description;

          _currentData[
                  'hashtags'] =
              result[
                      'hashtags'] ??
                  hashtags;

          _currentData[
                  'cta'] =
              result[
                      'cta'] ??
                  cta;

          // =================================================
          // NEW FINAL IMAGE
          // =================================================

          final String newImageUrl =
              result[
                          'image_url']
                      ?.toString() ??
                  result[
                          'download_url']
                      ?.toString() ??
                  responseData[
                          'image_url']
                      ?.toString() ??
                  responseData[
                          'download_url']
                      ?.toString() ??
                  '';

          if (newImageUrl
              .isNotEmpty) {

            _currentData[
                    'image_url'] =
                newImageUrl;

            _currentData[
                    'download_url'] =
                newImageUrl;

            _currentData[
                    'result_image'] =
                newImageUrl;
          }

          // =================================================
          // PRODUCT IMAGE
          // =================================================

          if (result.containsKey(
              'product_image_url')) {

            _currentData[
                    'product_image_url'] =
                result[
                    'product_image_url'];
          }

          // =================================================
          // TEMPLATE
          // =================================================

          if (result.containsKey(
              'template_id')) {

            _currentData[
                    'template_id'] =
                result[
                    'template_id'];
          }

          if (result.containsKey(
              'template_name')) {

            _currentData[
                    'template_name'] =
                result[
                    'template_name'];
          }

          if (result.containsKey(
              'template_url')) {

            _currentData[
                    'template_url'] =
                result[
                    'template_url'];
          }

          if (result.containsKey(
              'template_data')) {

            _currentData[
                    'template_data'] =
                result[
                    'template_data'];
          }

          // =================================================
          // ORIGINAL BUSINESS DATA
          // =================================================

          if (result.containsKey(
              'logo_url')) {

            _currentData[
                    'logo_url'] =
                result[
                    'logo_url'];
          }

          if (result.containsKey(
              'business_name')) {

            _currentData[
                    'business_name'] =
                result[
                    'business_name'];
          }

          if (result.containsKey(
              'category')) {

            _currentData[
                    'category'] =
                result[
                    'category'];
          }

          if (result.containsKey(
              'phone')) {

            _currentData[
                    'phone'] =
                result[
                    'phone'];
          }

          if (result.containsKey(
              'address')) {

            _currentData[
                    'address'] =
                result[
                    'address'];
          }

          if (result.containsKey(
              'website')) {

            _currentData[
                    'website'] =
                result[
                    'website'];
          }

          if (result.containsKey(
              'brand_colors')) {

            _currentData[
                    'brand_colors'] =
                result[
                    'brand_colors'];
          }

          if (result.containsKey(
              'preferred_font')) {

            _currentData[
                    'preferred_font'] =
                result[
                    'preferred_font'];
          }

          if (result.containsKey(
              'contact')) {

            _currentData[
                    'contact'] =
                result[
                    'contact'];
          }
        });

        _showMessage(
          'Post successfully regenerated!',
        );

      } else {

        final String serverMessage =
            responseData[
                        'message']
                    ?.toString() ??
                'Failed to regenerate post.';

        _showMessage(
          serverMessage,
        );
      }

    } catch (e) {

      if (!mounted) return;

      _showMessage(
        'Regeneration error: $e',
      );

    } finally {

      if (mounted) {

        setState(() {
          _isRegenerating =
              false;
        });
      }
    }
  }

  // =========================================================
  // TEXT FIELD
  // =========================================================

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {

    return Padding(

      padding:
          const EdgeInsets.symmetric(
        vertical: 8,
      ),

      child:
          TextField(

        controller:
            controller,

        maxLines:
            maxLines,

        decoration:
            InputDecoration(

          labelText:
              label,

          labelStyle:
              const TextStyle(
            fontSize: 13,
            color:
                primaryColor,
          ),

          filled:
              true,

          fillColor:
              scaffoldBg,

          border:
              OutlineInputBorder(

            borderRadius:
                BorderRadius.circular(
              12,
            ),

            borderSide:
                BorderSide.none,
          ),

          contentPadding:
              const EdgeInsets.all(
            12,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {

    final String imageUrl =
        _currentData[
                    'image_url']
                ?.toString() ??
            _currentData[
                    'download_url']
                ?.toString() ??
            '';

    final String headline =
        _currentData[
                    'headline']
                ?.toString() ??
            '';

    final String caption =
        _currentData[
                    'caption']
                ?.toString() ??
            '';

    final String description =
        _currentData[
                    'description']
                ?.toString() ??
            '';

    final String hashtags =
        _currentData[
                    'hashtags']
                ?.toString() ??
            '';

    final String cta =
        _currentData[
                    'cta']
                ?.toString() ??
            '';

    final String contact =
        _currentData[
                    'phone']
                ?.toString() ??
            _currentData[
                    'contact']
                ?.toString() ??
            '';

    return Scaffold(

      backgroundColor:
          scaffoldBg,

      appBar:
          AppBar(

        backgroundColor:
            scaffoldBg,

        elevation:
            0,

        centerTitle:
            true,

        iconTheme:
            const IconThemeData(
          color:
              textMain,
        ),

        title:
            const Text(
          'Generated Post Result',

          style:
              TextStyle(
            color:
                textMain,
            fontWeight:
                FontWeight.w800,
            fontSize:
                18,
          ),
        ),

        actions: [

          IconButton(

            icon:
                const Icon(
              Icons.edit_note,
              size:
                  28,
            ),

            color:
                primaryColor,

            tooltip:
                'Edit & Regenerate Post',

            onPressed:
                _isRegenerating
                    ? null
                    : _openEditBottomSheet,
          ),
        ],
      ),

      body:
          SingleChildScrollView(

        physics:
            const BouncingScrollPhysics(),

        padding:
            const EdgeInsets.all(
          16,
        ),

        child:
            Column(

          crossAxisAlignment:
              CrossAxisAlignment
                  .stretch,

          children: [

            // =================================================
            // COMPLETE POST IMAGE
            // =================================================

            ClipRRect(

              borderRadius:
                  BorderRadius.circular(
                14,
              ),

              child:
                  Stack(

                alignment:
                    Alignment.center,

                children: [

                  imageUrl.isNotEmpty

                      ? Image.network(

                          imageUrl,

                          height:
                              320,

                          width:
                              double.infinity,

                          fit:
                              BoxFit.contain,

                          loadingBuilder:
                              (
                            context,
                            child,
                            loadingProgress,
                          ) {

                            if (loadingProgress ==
                                null) {

                              return child;
                            }

                            return Container(

                              height:
                                  320,

                              color:
                                  Colors.white,

                              child:
                                  const Center(

                                child:
                                    CircularProgressIndicator(
                                  color:
                                      primaryColor,
                                  strokeWidth:
                                      2,
                                ),
                              ),
                            );
                          },

                          errorBuilder:
                              (
                            context,
                            error,
                            stackTrace,
                          ) {

                            return Container(

                              height:
                                  320,

                              color:
                                  Colors.white,

                              child:
                                  const Center(

                                child:
                                    Text(
                                  'Failed to load generated post image.',
                                  style:
                                      TextStyle(
                                    color:
                                        Colors.grey,
                                  ),
                                ),
                              ),
                            );
                          },
                        )

                      : Container(

                          height:
                              320,

                          decoration:
                              BoxDecoration(

                            color:
                                Colors.white,

                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),

                            border:
                                Border.all(
                              color:
                                  const Color(
                                0xFFE2E8F0,
                              ),
                            ),
                          ),

                          child:
                              Center(

                            child:
                                Text(
                              _isLoadingOriginalIds
                                  ? 'Loading original post...'
                                  : 'Image not available.',
                              style:
                                  const TextStyle(
                                color:
                                    Colors.grey,
                              ),
                            ),
                          ),
                        ),

                  // =================================================
                  // REGENERATING OVERLAY
                  // =================================================

                  if (_isRegenerating)

                    Container(

                      height:
                          320,

                      width:
                          double.infinity,

                      color:
                          Colors.black
                              .withValues(alpha: 
                        0.55,
                      ),

                      child:
                          const Center(

                        child:
                            Column(

                          mainAxisSize:
                              MainAxisSize.min,

                          children: [

                            CircularProgressIndicator(
                              color:
                                  Colors.white,
                            ),

                            SizedBox(
                              height:
                                  12,
                            ),

                            Text(
                              'Creating Complete New Post...',
                              style:
                                  TextStyle(
                                color:
                                    Colors.white,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            // =================================================
            // DOWNLOAD
            // =================================================

            SizedBox(

              height:
                  52,

              child:
                  ElevatedButton.icon(

                onPressed:
                    _isDownloading ||
                            imageUrl.isEmpty
                        ? null
                        : () =>
                            _downloadImage(
                              imageUrl,
                            ),

                icon:
                    _isDownloading

                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(
                              color:
                                  Colors.white,
                              strokeWidth:
                                  2,
                            ),
                          )

                        : const Icon(
                            Icons.download,
                          ),

                label:
                    Text(

                  _isDownloading
                      ? 'Downloading Image...'
                      : 'Download Image to Gallery',

                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize:
                        15,
                  ),
                ),

                style:
                    ElevatedButton.styleFrom(

                  backgroundColor:
                      primaryColor,

                  foregroundColor:
                      Colors.white,

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            const Divider(
              thickness: 1,
            ),

            const SizedBox(
              height: 10,
            ),

            // =================================================
            // TEXT DETAILS
            // =================================================

            const Text(
              'Generated Post Text & Details',

              style:
                  TextStyle(
                fontSize:
                    16,
                fontWeight:
                    FontWeight.bold,
                color:
                    textMain,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            if (headline.isNotEmpty)
              _buildCopyableCard(
                'Headline',
                headline,
              ),

            if (caption.isNotEmpty)
              _buildCopyableCard(
                'Caption',
                caption,
              ),

            if (description.isNotEmpty)
              _buildCopyableCard(
                'Description',
                description,
              ),

            if (hashtags.isNotEmpty)
              _buildCopyableCard(
                'Hashtags',
                hashtags,
              ),

            if (cta.isNotEmpty)
              _buildCopyableCard(
                'Call to Action (CTA)',
                cta,
              ),

            if (contact.isNotEmpty)
              _buildCopyableCard(
                'Contact Info',
                contact,
              ),

            const SizedBox(
              height: 20,
            ),

            // =================================================
            // COPY EVERYTHING
            // =================================================

            SizedBox(

              height:
                  52,

              child:
                  OutlinedButton.icon(

                onPressed: () {

                  final allText =
                      "Headline:\n$headline"
                      "\n\nCaption:\n$caption"
                      "\n\nDescription:\n$description"
                      "\n\nHashtags:\n$hashtags"
                      "\n\nCTA:\n$cta"
                      "\n\nContact:\n$contact";

                  _copyToClipboard(
                    allText,
                    'All Post Details',
                  );
                },

                icon:
                    const Icon(
                  Icons.copy_all,
                ),

                label:
                    const Text(
                  'Copy Complete Post Text',
                  style:
                      TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                style:
                    OutlinedButton.styleFrom(

                  foregroundColor:
                      primaryColor,

                  side:
                      const BorderSide(
                    color:
                        primaryColor,
                    width:
                        1.5,
                  ),

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 30,
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // COPYABLE CARD
  // =========================================================

  Widget _buildCopyableCard(
    String title,
    String content,
  ) {

    return Container(

      margin:
          const EdgeInsets.symmetric(
        vertical: 8,
      ),

      padding:
          const EdgeInsets.all(
        14,
      ),

      decoration:
          BoxDecoration(

        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          16,
        ),

        border:
            Border.all(
          color:
              const Color(
            0xFFE2E8F0,
          ),
        ),
      ),

      child:
          Column(

        crossAxisAlignment:
            CrossAxisAlignment
                .start,

        children: [

          Row(

            mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,

            children: [

              Text(

                title,

                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                  fontSize:
                      14,
                  color:
                      primaryColor,
                ),
              ),

              IconButton(

                icon:
                    const Icon(
                  Icons.copy,
                  size:
                      18,
                  color:
                      primaryColor,
                ),

                onPressed:
                    () =>
                        _copyToClipboard(
                  content,
                  title,
                ),

                tooltip:
                    'Copy $title',

                constraints:
                    const BoxConstraints(),

                padding:
                    EdgeInsets.zero,
              ),
            ],
          ),

          const SizedBox(
            height: 8,
          ),

          SelectableText(

            content,

            style:
                const TextStyle(
              fontSize:
                  13,
              color:
                  textMain,
            ),
          ),
        ],
      ),
    );
  }
}