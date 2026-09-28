import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'post_result_screen.dart';

class ProjectHistoryScreen extends StatefulWidget {
  const ProjectHistoryScreen({
    super.key,
  });

  @override
  State<ProjectHistoryScreen> createState() =>
      _ProjectHistoryScreenState();
}

class _ProjectHistoryScreenState
    extends State<ProjectHistoryScreen> {

  static const Color primaryColor =
      Color(0xFF6366F1);

  static const Color scaffoldBg =
      Color(0xFFF8FAFC);

  static const Color textMain =
      Color(0xFF1E293B);

  static const Color textMuted =
      Color(0xFF64748B);

  final FlutterSecureStorage _storage =
      const FlutterSecureStorage();

  List<Map<String, dynamic>> _projects = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  // =====================================================
  // LOAD PROJECTS
  // =====================================================

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token =
          await _storage.read(
        key: 'access_token',
      );

      if (token == null ||
          token.isEmpty) {
        _showMessage(
          'Please login again.',
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final response =
          await http.get(
        Uri.parse(
          'https://aibusinesspostmaker-production.up.railway.app/api/projects',
        ),
        headers: {
          'Authorization':
              'Bearer $token',
        },
      );

      if (!mounted) return;

      final data =
          jsonDecode(response.body);

      if (response.statusCode == 200 &&
          data['success'] == true) {

        final List<dynamic> list =
            data['projects'] ?? [];

        setState(() {
          _projects = list
              .map(
                (item) =>
                    Map<String, dynamic>.from(
                  item,
                ),
              )
              .toList();

          _isLoading = false;
        });

      } else {
        throw Exception(
          data['message'] ??
              'Unable to load projects',
        );
      }

    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage(
        'Unable to load projects',
      );
    }
  }

  // =====================================================
  // FORMAT DATE TIME
  // =====================================================

  String _formatDateTime(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return 'Recent';
    try {
      final parsed = DateTime.parse(rawDate);
      final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      String month = months[parsed.month];
      int hour = parsed.hour > 12 ? parsed.hour - 12 : (parsed.hour == 0 ? 12 : parsed.hour);
      String period = parsed.hour >= 12 ? 'PM' : 'AM';
      String minute = parsed.minute.toString().padLeft(2, '0');
      return '${parsed.day} $month, $hour:$minute $period';
    } catch (e) {
      return rawDate;
    }
  }

  // =====================================================
  // OPEN PROJECT
  // =====================================================

  Future<void> _openProject(
    Map<String, dynamic> project,
  ) async {
    final projectId =
        project['project_id'];

    if (projectId == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PostResultScreen(
          generatedData: project,
        ),
      ),
    );

    _loadProjects();
  }

  // =====================================================
  // DELETE PROJECT
  // =====================================================

  Future<void> _deleteProject(
    Map<String, dynamic> project,
  ) async {
    final projectId =
        project['project_id'];

    final title =
        project['title'] ??
            'this project';

    final confirm =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete Project?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete "$title"?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                context,
                false,
              ),
              child:
                  const Text('Cancel', style: TextStyle(color: textMuted)),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                context,
                true,
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final token =
          await _storage.read(
        key: 'access_token',
      );

      final response =
          await http.delete(
        Uri.parse(
          'https://aibusinesspostmaker-production.up.railway.app/api/projects/$projectId',
        ),
        headers: {
          'Authorization':
              'Bearer $token',
        },
      );

      if (!mounted) return;

      final data =
          jsonDecode(response.body);

      if (response.statusCode == 200 &&
          data['success'] == true) {

        setState(() {
          _projects.removeWhere(
            (item) =>
                item['project_id'] ==
                projectId,
          );
        });

        _showMessage(
          'Project deleted successfully',
        );

      } else {
        _showMessage(
          data['message'] ??
              'Unable to delete project',
        );
      }

    } catch (e) {
      _showMessage(
        'Unable to delete project',
      );
    }
  }

  // =====================================================
  // DOWNLOAD
  // =====================================================

  Future<void> _downloadProject(
    Map<String, dynamic> project,
  ) async {
    final url =
        project['download_url'] ??
            project['image_url'];

    if (url == null ||
        url.toString().isEmpty) {
      _showMessage(
        'Download image not available',
      );
      return;
    }

    try {
      final uri =
          Uri.parse(
        url.toString(),
      );

      final opened =
          await launchUrl(
        uri,
        mode:
            LaunchMode.externalApplication,
      );

      if (!opened) {
        _showMessage(
          'Unable to open download',
        );
      }

    } catch (e) {
      _showMessage(
        'Unable to download image',
      );
    }
  }

  // =====================================================
  // COPY PROJECT
  // =====================================================

  Future<void> _copyProject(
    Map<String, dynamic> project,
  ) async {
    final projectId =
        project['project_id'];

    try {
      final token =
          await _storage.read(
        key: 'access_token',
      );

      final response =
          await http.post(
        Uri.parse(
          'https://aibusinesspostmaker-production.up.railway.app/api/projects/$projectId/copy',
        ),
        headers: {
          'Authorization':
              'Bearer $token',
        },
      );

      if (!mounted) return;

      final data =
          jsonDecode(response.body);

      if (response.statusCode == 201 &&
          data['success'] == true) {

        _showMessage(
          'Project copied successfully',
        );

        _loadProjects();

      } else {
        _showMessage(
          data['message'] ??
              'Unable to copy project',
        );
      }

    } catch (e) {
      _showMessage(
        'Unable to copy project',
      );
    }
  }

  // =====================================================
  // MESSAGE
  // =====================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
            Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          scaffoldBg,
      appBar: AppBar(
        backgroundColor:
            scaffoldBg,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Project History',
          style: TextStyle(
            color: textMain,
            fontWeight:
                FontWeight.w700,
            fontSize: 18,
          ),
        ),
        iconTheme:
            const IconThemeData(
          color: textMain,
        ),
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(color: primaryColor),
            )
          : RefreshIndicator(
              color: primaryColor,
              onRefresh:
                  _loadProjects,
              child:
                  _projects.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          itemCount:
                              _projects.length,
                          itemBuilder:
                              (context, index) {
                            return _buildProjectCard(
                              _projects[index],
                            );
                          },
                        ),
            ),
    );
  }

  // =====================================================
  // EMPTY
  // =====================================================

  Widget _buildEmptyState() {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(
          height: 180,
        ),
        Icon(
          Icons.folder_open_outlined,
          size: 64,
          color: Colors.grey.shade400,
        ),
        const SizedBox(
          height: 16,
        ),
        const Center(
          child: Text(
            'No Projects Yet',
            style: TextStyle(
              color: textMain,
              fontWeight:
                  FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(
          height: 6,
        ),
        const Center(
          child: Text(
            'Your generated posts will appear here.',
            style: TextStyle(
              color: textMuted,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  // =====================================================
  // PROJECT CARD
  // =====================================================

  Widget _buildProjectCard(
    Map<String, dynamic> project,
  ) {
    final imageUrl =
        project['image_url'] ??
            '';

    final title =
        project['title'] ??
            'Untitled Project';

    final platform =
        project['platform'] ??
            '';

    final contentType =
        project['content_type'] ??
            '';

    final createdAt = _formatDateTime(
      project['created_at'] ?? project['date'],
    );

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 16,
      ),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border:
            Border.all(
          color:
              const Color(
            0xFFE2E8F0,
          ),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openProject(project),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // IMAGE THUMBNAIL (Properly placed on top)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(
                  top:
                      Radius.circular(
                    16,
                ),
              ),
              child:
                  imageUrl
                          .toString()
                          .isNotEmpty
                      ? Image.network(
                          imageUrl,
                          height: 160,
                          width:
                              double.infinity,
                          fit:
                              BoxFit.cover,
                          errorBuilder:
                              (_, _, _) =>
                                  _imagePlaceholder(),
                        )
                      : _imagePlaceholder(),
            ),
            
            // CONTENT & BUTTONS CONTAINER
            Padding(
              padding:
                  const EdgeInsets.all(
                12,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      color:
                          textMain,
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Row(
                    children: [
                      if (platform
                          .toString()
                          .isNotEmpty)
                        _smallTag(
                          platform,
                        ),
                      if (platform.toString().isNotEmpty &&
                          contentType.toString().isNotEmpty)
                        const SizedBox(
                          width: 6,
                        ),
                      if (contentType
                          .toString()
                          .isNotEmpty)
                        _smallTag(
                          contentType,
                        ),
                    ],
                  ),
                  const SizedBox(
                    height: 8,
                  ),

                  // DATE & TIME DISPLAY
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 13, color: textMuted),
                      const SizedBox(width: 4),
                      Text(
                        createdAt,
                        style: const TextStyle(
                          color: textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  
                  // ACTION CONTROLS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tap card to view full',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildActionIconButton(
                            icon: Icons.download_outlined,
                            tooltip: 'Download',
                            onPressed: () => _downloadProject(project),
                          ),
                          const SizedBox(width: 4),
                          _buildActionIconButton(
                            icon: Icons.content_copy_outlined,
                            tooltip: 'Copy',
                            onPressed: () => _copyProject(project),
                          ),
                          const SizedBox(width: 4),
                          _buildActionIconButton(
                            icon: Icons.delete_outline,
                            tooltip: 'Delete',
                            color: Colors.red.shade400,
                            onPressed: () => _deleteProject(project),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  // =====================================================
  // COMPACT POP ICON BUTTON
  // =====================================================

  Widget _buildActionIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return SizedBox(
      width: 34,
      height: 34,
      child: IconButton(
        padding: EdgeInsets.zero,
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 17,
          color: color ?? primaryColor,
        ),
      ),
    );
  }

  // =====================================================
  // TAG
  // =====================================================

  Widget _smallTag(
    String text,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
    ),
      decoration:
          BoxDecoration(
        color:
            const Color(
          0xFFEEF2FF,
        ),
        borderRadius:
            BorderRadius.circular(
          6,
        ),
      ),
      child:
          Text(
        text,
        style:
            const TextStyle(
          color:
              primaryColor,
          fontSize: 10,
          fontWeight:
              FontWeight.w700,
        ),
      ),
    );
  }

  // =====================================================
  // IMAGE PLACEHOLDER
  // =====================================================

  Widget _imagePlaceholder() {
    return Container(
      height: 160,
      color:
          const Color(
        0xFFE2E8F0,
      ),
      child:
          const Center(
        child:
            Icon(
          Icons.image_outlined,
          size: 40,
          color: textMuted,
        ),
      ),
    );
  }
}